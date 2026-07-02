import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:record/record.dart';

import '../../core/audio/mpm.dart';
import '../ai_coach/ai_suggestion.dart';
import '../sheets/data/sheet_model.dart';

/// 练习模式（M05 AI 陪练）
/// - guide: 跟弹模式，按曲谱 BPM 自动推进
/// - sing: 唱弹模式，不按 sheet 推进，目标是主旋律
/// - free: 自由练习，录音 + 实时音高，无目标
enum PracticeMode { guide, sing, free }

/// 智能陪练状态
enum PracticeStatus {
  idle,
  loading,
  countdown,
  playing,
  paused,
  finished,
  failed,
}

class PracticeState {
  const PracticeState({
    required this.status,
    required this.mode,
    required this.sheet,
    required this.expectedIndex,
    required this.expectedChord,
    required this.detectedNote,
    required this.detectedFrequency,
    required this.centsOffset,
    required this.errorMessage,
    required this.recordedBytes,
    required this.hitCount,
    required this.missCount,
    required this.centsHistory,
    required this.suggestions,
    required this.elapsedSeconds,
    required this.expectedChordCount,
  });

  factory PracticeState.initial() => const PracticeState(
        status: PracticeStatus.idle,
        mode: PracticeMode.guide,
        sheet: null,
        expectedIndex: 0,
        expectedChord: '-',
        detectedNote: '-',
        detectedFrequency: 0,
        centsOffset: 0,
        errorMessage: null,
        recordedBytes: <int>[],
        hitCount: 0,
        missCount: 0,
        centsHistory: <int>[],
        suggestions: <AiSuggestion>[],
        elapsedSeconds: 0,
        expectedChordCount: 0,
      );

  final PracticeStatus status;
  final PracticeMode mode;
  final Sheet? sheet;
  final int expectedIndex;
  final String expectedChord;
  final String detectedNote;
  final double detectedFrequency;
  final int centsOffset;
  final String? errorMessage;
  final List<int> recordedBytes; // 累计录音字节（用于上传云端）
  final int hitCount;
  final int missCount;
  final List<int> centsHistory; // cents 偏差绝对值序列
  final List<AiSuggestion> suggestions; // AI 智能建议（stop 时填充）
  final int elapsedSeconds; // 已练习时长（秒）
  final int expectedChordCount; // 期望总拍数（用于节奏分析）

  bool get isRunning =>
      status == PracticeStatus.playing || status == PracticeStatus.paused;

  bool get isLastBeat =>
      sheet != null && expectedIndex >= (sheet!.chords.length - 1);

  /// 错音判定（cents 偏差绝对值 > 30 算错）
  bool get isMistake => centsOffset.abs() > 30;

  /// 命中判定（cents 偏差绝对值 <= 20 算命中）
  bool get isHit => centsOffset.abs() <= 20 && detectedFrequency > 0;

  PracticeState copyWith({
    PracticeStatus? status,
    PracticeMode? mode,
    Sheet? sheet,
    int? expectedIndex,
    String? expectedChord,
    String? detectedNote,
    double? detectedFrequency,
    int? centsOffset,
    String? errorMessage,
    List<int>? recordedBytes,
    int? hitCount,
    int? missCount,
    List<int>? centsHistory,
    List<AiSuggestion>? suggestions,
    int? elapsedSeconds,
    int? expectedChordCount,
    bool clearError = false,
    bool setSheet = false,
  }) {
    return PracticeState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      sheet: setSheet ? sheet : (sheet ?? this.sheet),
      expectedIndex: expectedIndex ?? this.expectedIndex,
      expectedChord: expectedChord ?? this.expectedChord,
      detectedNote: detectedNote ?? this.detectedNote,
      detectedFrequency: detectedFrequency ?? this.detectedFrequency,
      centsOffset: centsOffset ?? this.centsOffset,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      recordedBytes: recordedBytes ?? this.recordedBytes,
      hitCount: hitCount ?? this.hitCount,
      missCount: missCount ?? this.missCount,
      centsHistory: centsHistory ?? this.centsHistory,
      suggestions: suggestions ?? this.suggestions,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      expectedChordCount: expectedChordCount ?? this.expectedChordCount,
    );
  }
}

/// 智能陪练 Cubit
class PracticeCubit extends Cubit<PracticeState> {
  PracticeCubit({
    AudioRecorder? recorder,
    Sheet? initialSheet,
    PracticeMode initialMode = PracticeMode.guide,
  })  : _recorder = recorder ?? AudioRecorder(),
        super(_resolveInitial(initialSheet, initialMode));

  static PracticeState _resolveInitial(Sheet? sheet, PracticeMode mode) {
    final base = PracticeState.initial().copyWith(
      mode: mode,
      sheet: sheet,
      setSheet: true,
    );
    if (sheet != null && sheet.chords.isNotEmpty) {
      return base.copyWith(
        expectedChord: sheet.chords[0]['chord'] as String? ?? '-',
        expectedChordCount: sheet.chords.length,
      );
    }
    return base;
  }

  final AudioRecorder _recorder;
  StreamSubscription<Uint8List>? _subscription;
  Timer? _advanceTimer;
  Timer? _elapsedTimer;
  int _startEpochMs = 0;

  // 音频参数
  static const int _sampleRate = 44100;
  static const int _bufferSize = 2048;
  final List<int> _byteBuffer = <int>[];

  /// 加载曲谱并开始练习
  Future<void> startPractice(Sheet sheet, {PracticeMode? mode}) async {
    if (sheet.chords.isEmpty) {
      emit(state.copyWith(
        status: PracticeStatus.failed,
        errorMessage: '曲谱无和弦数据',
      ));
      return;
    }

    final PracticeMode m = mode ?? state.mode;

    emit(state.copyWith(
      status: PracticeStatus.loading,
      mode: m,
      sheet: sheet,
      expectedIndex: 0,
      expectedChord: sheet.chords[0]['chord'] as String? ?? '-',
      detectedNote: '-',
      detectedFrequency: 0,
      centsOffset: 0,
      recordedBytes: <int>[],
      hitCount: 0,
      missCount: 0,
      centsHistory: <int>[],
      suggestions: const <AiSuggestion>[],
      elapsedSeconds: 0,
      expectedChordCount: sheet.chords.length,
      clearError: true,
    ));

    try {
      final bool hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        emit(state.copyWith(
          status: PracticeStatus.failed,
          errorMessage: '需要麦克风权限',
        ));
        return;
      }

      // 3 秒倒计时
      emit(state.copyWith(status: PracticeStatus.countdown));
      await Future<void>.delayed(const Duration(seconds: 3));

      // 开始录音
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          numChannels: 1,
          bitRate: 128000,
          sampleRate: _sampleRate,
        ),
      );

      _byteBuffer.clear();
      _startEpochMs = DateTime.now().millisecondsSinceEpoch;

      _subscription = stream.listen(
        _onAudioData,
        onError: (Object err) {
          emit(state.copyWith(
            status: PracticeStatus.failed,
            errorMessage: '录音错误：$err',
          ));
        },
        cancelOnError: true,
      );

      // 自动推进 timer
      if (m == PracticeMode.guide) {
        _scheduleAdvance(sheet);
      } else if (m == PracticeMode.sing) {
        _scheduleSingAdvance(sheet);
      }

      // 录音时长计时器（每 1 秒）
      _elapsedTimer?.cancel();
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.status != PracticeStatus.playing) return;
        final int elapsed =
            ((DateTime.now().millisecondsSinceEpoch - _startEpochMs) / 1000)
                .round();
        emit(state.copyWith(elapsedSeconds: elapsed));
      });

      emit(state.copyWith(status: PracticeStatus.playing));
    } catch (e) {
      emit(state.copyWith(
        status: PracticeStatus.failed,
        errorMessage: '启动失败：$e',
      ));
    }
  }

  /// 暂停
  void pause() {
    if (state.status != PracticeStatus.playing) return;
    _advanceTimer?.cancel();
    _elapsedTimer?.cancel();
    _subscription?.pause();
    emit(state.copyWith(status: PracticeStatus.paused));
  }

  /// 恢复
  void resume() {
    if (state.status != PracticeStatus.paused) return;
    _subscription?.resume();
    final sheet = state.sheet;
    if (sheet != null) {
      if (state.mode == PracticeMode.guide) {
        _scheduleAdvance(sheet);
      } else if (state.mode == PracticeMode.sing) {
        _scheduleSingAdvance(sheet);
      }
    }
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != PracticeStatus.playing) return;
      final int elapsed =
          ((DateTime.now().millisecondsSinceEpoch - _startEpochMs) / 1000)
              .round();
      emit(state.copyWith(elapsedSeconds: elapsed));
    });
    emit(state.copyWith(status: PracticeStatus.playing));
  }

  /// 停止并完成
  Future<void> stop() async {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _byteBuffer.clear();

    // 生成 AI 建议
    final List<AiSuggestion> suggestions = AiSuggestionEngine.generate(
      AiAnalysisInput(
        centsHistory: state.centsHistory,
        hitCount: state.hitCount,
        missCount: state.missCount,
        durationSeconds: state.elapsedSeconds,
        expectedChordCount: state.expectedChordCount,
      ),
    );

    emit(state.copyWith(
      status: PracticeStatus.finished,
      suggestions: suggestions,
    ));
  }

  /// 手动跳到下一小节
  void nextBeat() {
    final Sheet? sheet = state.sheet;
    if (sheet == null || sheet.chords.isEmpty) return;
    final int next = state.expectedIndex + 1;
    if (next >= sheet.chords.length) {
      stop();
      return;
    }
    emit(state.copyWith(
      expectedIndex: next,
      expectedChord: sheet.chords[next]['chord'] as String? ?? '-',
      detectedNote: '-',
      detectedFrequency: 0,
      centsOffset: 0,
    ));
  }

  /// 获取累计录音的 WAV 字节（带 header）
  Uint8List getRecordedWav() {
    // PCM16 mono 44100Hz
    final int dataLen = state.recordedBytes.length;
    final int fileLen = 36 + dataLen;
    final ByteData header = ByteData(44);
    // RIFF
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileLen, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // fmt chunk size
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, _sampleRate * 2, Endian.little); // byte rate
    header.setUint16(32, 2, Endian.little); // block align
    header.setUint16(34, 16, Endian.little); // bits
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataLen, Endian.little);

    final Uint8List result = Uint8List(44 + dataLen);
    result.setRange(0, 44, header.buffer.asUint8List());
    final Uint8List dataBytes = Uint8List.fromList(state.recordedBytes);
    result.setRange(44, 44 + dataLen, dataBytes);
    return result;
  }

  void _scheduleAdvance(Sheet sheet) {
    _advanceTimer?.cancel();
    final double beatSec = 60.0 / sheet.bpm;
    final Duration chordDuration = Duration(
      milliseconds: (beatSec * 2 * 1000).round(),
    );

    _advanceTimer = Timer.periodic(chordDuration, (Timer t) {
      if (state.status != PracticeStatus.playing) return;
      final int next = state.expectedIndex + 1;
      if (next >= sheet.chords.length) {
        stop();
        return;
      }
      emit(state.copyWith(
        expectedIndex: next,
        expectedChord: sheet.chords[next]['chord'] as String? ?? '-',
        detectedNote: '-',
        detectedFrequency: 0,
        centsOffset: 0,
      ));
    });
  }

  /// 唱弹模式：每 4 秒切换一次目标旋律音（用户需要唱/哼到目标音）
  void _scheduleSingAdvance(Sheet sheet) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer.periodic(const Duration(seconds: 4), (Timer t) {
      if (state.status != PracticeStatus.playing) return;
      final int next = state.expectedIndex + 1;
      if (next >= sheet.chords.length) {
        stop();
        return;
      }
      emit(state.copyWith(
        expectedIndex: next,
        expectedChord: sheet.chords[next]['chord'] as String? ?? '-',
        detectedNote: '-',
        detectedFrequency: 0,
        centsOffset: 0,
      ));
    });
  }

  void _onAudioData(Uint8List data) {
    // 1. 累计录音 buffer（用于上传）
    final List<int> updatedRecorded =
        List<int>.from(state.recordedBytes)..addAll(data);

    // 2. 实时音高检测
    _byteBuffer.addAll(data);
    final int targetBytes = _bufferSize * 2;
    while (_byteBuffer.length >= targetBytes) {
      final Uint8List frame = Uint8List.fromList(
        _byteBuffer.sublist(0, targetBytes),
      );
      final int keepBytes = (targetBytes * 0.5).round();
      _byteBuffer.removeRange(0, targetBytes - keepBytes);

      final (double freq, double _) = MpmDetector.detectPitchFromPcm16(
        frame,
        sampleRate: _sampleRate,
        minFreqHz: 70,
        maxFreqHz: 1200,
        clarityThreshold: 0.6,
      );

      // RMS 门限：环境噪声不显示
      final double rms = _rmsOfFrame(frame);
      if (freq > 0 && rms >= 0.01) {
        final String note = _freqToNoteName(freq);
        final int cents = _estimateCents(freq, state.expectedChord);
        // 累加 hit/miss/centsHistory
        final int centsAbs = cents.abs();
        final List<int> newHistory = List<int>.from(state.centsHistory)
          ..add(centsAbs);
        // 命中：偏差 ≤ 20 cents（自由模式不算命中）
        final bool hit = centsAbs <= 20 && state.mode != PracticeMode.free;
        emit(state.copyWith(
          detectedNote: note,
          detectedFrequency: freq,
          centsOffset: cents,
          hitCount: hit ? state.hitCount + 1 : state.hitCount,
          missCount: hit ? state.missCount : state.missCount + 1,
          centsHistory: newHistory,
          recordedBytes: updatedRecorded,
        ));
      } else {
        emit(state.copyWith(recordedBytes: updatedRecorded));
      }
    }
  }

  /// 计算单帧 RMS
  double _rmsOfFrame(Uint8List pcm) {
    final int n = pcm.length ~/ 2;
    if (n == 0) return 0;
    double sum = 0;
    for (int i = 0; i < n; i++) {
      final int s = (pcm[i * 2 + 1] << 8) | pcm[i * 2];
      final int signed = s >= 0x8000 ? s - 0x10000 : s;
      final double f = signed / 32768.0;
      sum += f * f;
    }
    return _sqrt(sum / n);
  }

  double _sqrt(double x) => math.sqrt(x <= 0 ? 0 : x);

  /// 频率 → 音名
  String _freqToNoteName(double freq) {
    if (freq <= 0) return '-';
    const List<String> names = <String>[
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
    ];
    final double semitones = 12.0 * (math.log(freq / 440.0) / math.ln2);
    final int midi = semitones.round() + 69;
    final int idx = ((midi % 12) + 12) % 12;
    final int octave = (midi ~/ 12) - 1;
    return '${names[idx]}$octave';
  }

  /// 估算当前检测音 vs 期望和弦根音的偏差
  int _estimateCents(double detectedFreq, String expectedChord) {
    if (expectedChord.isEmpty || expectedChord == '-') return 0;
    final String root = expectedChord[0];
    final double expectedFreq = _noteRootFreq(root, 4);
    if (expectedFreq <= 0) return 0;
    return (1200.0 * (math.log(detectedFreq / expectedFreq) / math.ln2))
        .round();
  }

  double _noteRootFreq(String root, int octave) {
    const Map<String, int> semitones = <String, int>{
      'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11,
    };
    final int semi = semitones[root] ?? 0;
    final double midi = ((octave + 1) * 12 + semi).toDouble();
    return 440.0 * math.pow(2.0, (midi - 69) / 12.0);
  }

  @override
  Future<void> close() async {
    _advanceTimer?.cancel();
    _elapsedTimer?.cancel();
    await _subscription?.cancel();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await _recorder.dispose();
    return super.close();
  }
}