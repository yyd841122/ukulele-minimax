import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele/features/score_report/score_report_cubit.dart';

void main() {
  group('ScoreDimension.fromJson', () {
    test('应正确解析所有维度', () {
      final ScoreDimension dim = ScoreDimension.fromJson(<String, dynamic>{
        'pitch': 85.0,
        'rhythm': 90.0,
        'fluency': 75.0,
        'overall': 83.5,
      });
      expect(dim.pitch, 85.0);
      expect(dim.rhythm, 90.0);
      expect(dim.fluency, 75.0);
      expect(dim.overall, 83.5);
    });

    test('应支持 int 值', () {
      final ScoreDimension dim = ScoreDimension.fromJson(<String, dynamic>{
        'pitch': 100,
        'rhythm': 100,
        'fluency': 100,
        'overall': 100,
      });
      expect(dim.overall, 100.0);
    });
  });

  group('NoteEvent.fromJson', () {
    test('应正确解析命中事件', () {
      final NoteEvent e = NoteEvent.fromJson(<String, dynamic>{
        'time_ms': 1000,
        'expected_note': 'C4',
        'detected_note': 'C4',
        'cents_offset': 3,
        'is_correct': true,
      });
      expect(e.timeMs, 1000);
      expect(e.expectedNote, 'C4');
      expect(e.detectedNote, 'C4');
      expect(e.centsOffset, 3);
      expect(e.isCorrect, true);
    });

    test('应正确解析未检测事件', () {
      final NoteEvent e = NoteEvent.fromJson(<String, dynamic>{
        'time_ms': 2000,
        'expected_note': 'E4',
        'detected_note': '-',
        'cents_offset': 0,
        'is_correct': false,
      });
      expect(e.detectedNote, '-');
      expect(e.isCorrect, false);
    });
  });

  group('ScoreResult.fromJson', () {
    test('完整 JSON 应正确解析', () {
      final ScoreResult r = ScoreResult.fromJson(<String, dynamic>{
        'score_id': 42,
        'dimensions': <String, dynamic>{
          'pitch': 80.0,
          'rhythm': 75.0,
          'fluency': 70.0,
          'overall': 75.0,
        },
        'notes': <Map<String, dynamic>>[
          <String, dynamic>{
            'time_ms': 0,
            'expected_note': 'C4',
            'detected_note': 'C4',
            'cents_offset': 0,
            'is_correct': true,
          },
        ],
        'weak_points': <String>['节奏不稳'],
        'suggestions': <String>['用 0.5x 速度练'],
      });
      expect(r.scoreId, 42);
      expect(r.notes.length, 1);
      expect(r.weakPoints.length, 1);
      expect(r.suggestions.length, 1);
    });
  });
}