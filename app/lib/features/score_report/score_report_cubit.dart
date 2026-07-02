import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants.dart';
import '../sheets/data/sheet_model.dart';

/// 评分维度
class ScoreDimension {
  const ScoreDimension({
    required this.pitch,
    required this.rhythm,
    required this.fluency,
    required this.overall,
  });

  factory ScoreDimension.fromJson(Map<String, dynamic> json) {
    return ScoreDimension(
      pitch: (json['pitch'] as num).toDouble(),
      rhythm: (json['rhythm'] as num).toDouble(),
      fluency: (json['fluency'] as num).toDouble(),
      overall: (json['overall'] as num).toDouble(),
    );
  }

  final double pitch;
  final double rhythm;
  final double fluency;
  final double overall;
}

/// 单个音符事件
class NoteEvent {
  const NoteEvent({
    required this.timeMs,
    required this.expectedNote,
    required this.detectedNote,
    required this.centsOffset,
    required this.isCorrect,
  });

  factory NoteEvent.fromJson(Map<String, dynamic> json) {
    return NoteEvent(
      timeMs: json['time_ms'] as int,
      expectedNote: json['expected_note'] as String,
      detectedNote: json['detected_note'] as String,
      centsOffset: json['cents_offset'] as int,
      isCorrect: json['is_correct'] as bool,
    );
  }

  final int timeMs;
  final String expectedNote;
  final String detectedNote;
  final int centsOffset;
  final bool isCorrect;
}

/// 评分结果
class ScoreResult {
  const ScoreResult({
    required this.scoreId,
    required this.dimensions,
    required this.notes,
    required this.weakPoints,
    required this.suggestions,
  });

  factory ScoreResult.fromJson(Map<String, dynamic> json) {
    return ScoreResult(
      scoreId: json['score_id'] as int,
      dimensions: ScoreDimension.fromJson(
        json['dimensions'] as Map<String, dynamic>,
      ),
      notes: (json['notes'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(NoteEvent.fromJson)
          .toList(),
      weakPoints:
          (json['weak_points'] as List<dynamic>).cast<String>(),
      suggestions:
          (json['suggestions'] as List<dynamic>).cast<String>(),
    );
  }

  final int scoreId;
  final ScoreDimension dimensions;
  final List<NoteEvent> notes;
  final List<String> weakPoints;
  final List<String> suggestions;
}

class ScoreReportState {
  const ScoreReportState({
    required this.isLoading,
    required this.result,
    this.error,
  });

  factory ScoreReportState.initial() => const ScoreReportState(
        isLoading: true,
        result: null,
      );

  final bool isLoading;
  final ScoreResult? result;
  final String? error;

  ScoreReportState copyWith({
    bool? isLoading,
    ScoreResult? result,
    String? error,
    bool clearError = false,
  }) {
    return ScoreReportState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 评分 Cubit
class ScoreReportCubit extends Cubit<ScoreReportState> {
  ScoreReportCubit({Dio? dio, Sheet? sheet})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.apiBaseUrl,
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 30),
                headers: <String, String>{
                  'Content-Type': 'application/json',
                },
              ),
            ),
        _sheet = sheet,
        super(ScoreReportState.initial());

  final Dio _dio;
  final Sheet? _sheet;

  /// 上传音频并获取评分（云端）
  Future<void> submit({required Uint8List wavBytes, required int sheetId}) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final String b64 = base64Encode(wavBytes);
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/score',
        data: <String, dynamic>{
          'sheet_id': sheetId,
          'audio_base64': b64,
          'sample_rate': 44100,
        },
      );
      final ScoreResult result =
          ScoreResult.fromJson(response.data as Map<String, dynamic>);
      emit(state.copyWith(isLoading: false, result: result));
    } catch (e) {
      // 云端不可用时，回退到本地评分
      _fallbackToLocal(wavBytes);
    }
  }

  /// 本地评分（无网络时）
  void _fallbackToLocal(Uint8List wavBytes) {
    // MVP 简化：基于录音时长 + 期望 chord 数计算一个"占位分"
    // 真实实现需要本地 librosa/pyin 算法（复杂度高）
    final int seconds = (wavBytes.length - 44) ~/ 44100 ~/ 2;
    final int totalBeats = _sheet?.chords.length ?? 4;
    final double overall = seconds > 0 ? (60 + (seconds % 40)).toDouble() : 60.0;
    emit(state.copyWith(
      isLoading: false,
      result: ScoreResult(
        scoreId: 0,
        dimensions: ScoreDimension(
          pitch: overall - 5,
          rhythm: overall + 3,
          fluency: overall - 10,
          overall: overall,
        ),
        notes: <NoteEvent>[],
        weakPoints: const <String>['云端评分服务不可用，当前为本地估算'],
        suggestions: const <String>[
          '请连接网络后重新评分获得精确结果',
          '建议 30 秒以上的录音可获得更准确的报告',
        ],
      ),
    ));
  }
}