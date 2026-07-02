import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';

import '../../core/audio/mpm.dart';
import 'domain/music_note.dart';

/// 实时调音状态
class TunerState {
  const TunerState({
    required this.isRecording,
    required this.detectedNote,
    required this.targetString,
    required this.errorMessage,
  });

  factory TunerState.initial() => const TunerState(
    isRecording: false,
    detectedNote: null,
    targetString: null,
    errorMessage: null,
  );

  final bool isRecording;
  final MusicNote? detectedNote;
  final UkuleleString? targetString;
  final String? errorMessage;

  TunerState copyWith({
    bool? isRecording,
    MusicNote? detectedNote,
    UkuleleString? targetString,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TunerState(
      isRecording: isRecording ?? this.isRecording,
      detectedNote: detectedNote ?? this.detectedNote,
      targetString: targetString ?? this.targetString,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// 显式清空检测结果（用于环境噪声门限触发时）
  TunerState copyWithClearNote() {
    return TunerState(
      isRecording: this.isRecording,
      detectedNote: const MusicNote(
        name: '-',
        octave: 0,
        cents: 0,
        frequency: 0,
        expectedFrequency: 0,
      ),
      targetString: null,
      errorMessage: this.errorMessage,
    );
  }
}

/// 实时调音 Cubit
///
/// 职责：
/// 1. 启动/停止录音（PCM16 单声道流）
/// 2. 累积音频 buffer（达到 2048 样本后送入检测）
/// 3. 调用 YIN 算法识别基频
/// 4. 转为 MusicNote 并推送状态
class TunerCubit extends Cubit<TunerState> {
  TunerCubit({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder(),
        super(TunerState.initial());

  final AudioRecorder _recorder;
  StreamSubscription<Uint8List>? _subscription;
  final List<int> _byteBuffer = <int>[];

  // 调音参数：44.1 kHz / 2048 样本 = ~46ms 单帧
  static const int _sampleRate = 44100;
  static const int _bufferSize = 2048;

  /// 开始调音，自动请求麦克风权限
  Future<void> start() async {
    try {
      final bool hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        emit(state.copyWith(errorMessage: '需要麦克风权限才能调音'));
        return;
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          numChannels: 1,
          bitRate: 128000,
          sampleRate: _sampleRate,
        ),
      );

      _byteBuffer.clear();

      _subscription = stream.listen(
        _onAudioData,
        onError: (Object err) {
          emit(state.copyWith(
            isRecording: false,
            errorMessage: '录音错误：$err',
          ));
        },
        cancelOnError: true,
      );

      emit(state.copyWith(
        isRecording: true,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isRecording: false,
        errorMessage: '启动失败：$e',
      ));
    }
  }

  /// 停止调音
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _recorder.stop();
    _byteBuffer.clear();
    emit(state.copyWith(
      isRecording: false,
      detectedNote: null,
    ));
  }

  /// 选择目标弦（用于辅助调音）
  void selectTargetString(UkuleleString? str) {
    emit(state.copyWith(targetString: str));
  }

  /// 处理音频数据流
  void _onAudioData(Uint8List data) {
    _byteBuffer.addAll(data);

    // 累计到目标 buffer 大小后做一次检测
    // PCM16: 每样本 2 字节
    final int targetBytes = _bufferSize * 2;
    while (_byteBuffer.length >= targetBytes) {
      final Uint8List frame = Uint8List.fromList(
        _byteBuffer.sublist(0, targetBytes),
      );
      // 移除已处理的字节（保留尾部一小段做平滑）
      final int keepBytes = (targetBytes * 0.5).round();
      _byteBuffer.removeRange(0, targetBytes - keepBytes);

      _detectPitch(frame);
    }
  }

  /// 使用 MPM 算法检测音高（McLeod Pitch Method）
  /// 纯 Dart 实现，端侧零依赖；八度错误率 < 1%
  /// 详见 lib/core/audio/mpm.dart
  ///
  /// 抗环境噪声三道门：
  /// 1. RMS 能量门限：环境太安静（< 0.005）→ 视为无输入
  /// 2. clarity 阈值 0.85：低于此视为噪声而非乐音（远比默认 0.5 严格）
  /// 3. 频率稳定性检查（最近 3 帧至少 2 帧一致）→ 减少跳变
  void _detectPitch(Uint8List pcm16Buffer) {
    // 1. 能量门限
    final Float32List samples = pcm16ToFloat32(pcm16Buffer);
    final double rms = rmsEnergy(samples);
    if (rms < _rmsThreshold) {
      // 安静：清空检测（不显示任何音符）
      emit(state.copyWith(
        detectedNote: const MusicNote(
          name: '-',
          octave: 0,
          cents: 0,
          frequency: 0,
          expectedFrequency: 0,
        ),
        targetString: null,
      ).copyWithClearNote());
      return;
    }

    // 2. MPM 检测（提高 clarity 阈值）
    final (double frequency, double clarity) = MpmDetector
        .detectPitchFromPcm16(
      pcm16Buffer,
      sampleRate: _sampleRate,
      minFreqHz: 70,
      maxFreqHz: 1200,
      clarityThreshold: _clarityThreshold,
    );

    if (frequency <= 0) {
      // 检测失败（噪声）
      emit(state.copyWith(
        detectedNote: const MusicNote(
          name: '-',
          octave: 0,
          cents: 0,
          frequency: 0,
          expectedFrequency: 0,
        ),
        targetString: null,
      ).copyWithClearNote());
      return;
    }

    // 3. 频率稳定性检查：最近 3 帧至少 2 帧在 ±15% 内
    _history.add(frequency);
    if (_history.length > _historySize) {
      _history.removeAt(0);
    }
    if (_history.length >= _historySize) {
      final double median = _median(_history);
      final int closeCount = _history
          .where((double f) => (f - median).abs() / median < 0.15)
          .length;
      if (closeCount < 2) {
        // 不稳定，跳过这一帧
        return;
      }
    }

    final MusicNote note = MusicNote.fromFrequency(frequency);
    final UkuleleString? nearestStr =
        UkuleleStandardTuning.nearestString(frequency);

    emit(state.copyWith(
      detectedNote: note,
      targetString: nearestStr,
    ));
  }

  // 抗噪声参数
  static const double _rmsThreshold = 0.005; // 环境噪声基线
  static const double _clarityThreshold = 0.85; // 远高于默认 0.5
  static const int _historySize = 3;
  final List<double> _history = <double>[];

  double _median(List<double> values) {
    final List<double> sorted = List<double>.from(values)..sort();
    return sorted[sorted.length ~/ 2];
  }

  @override
  Future<void> close() async {
    await stop();
    await _recorder.dispose();
    return super.close();
  }
}