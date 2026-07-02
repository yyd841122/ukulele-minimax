/// AI 陪练模块测试
import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele/features/ai_coach/ai_suggestion.dart';
import 'package:ukulele/features/practice/practice_cubit.dart';

void main() {
  group('AiSuggestionEngine', () {
    test('空数据返回空 suggestions（仅总结）', () {
      final result = AiSuggestionEngine.generate(
        const AiAnalysisInput(
          centsHistory: <int>[],
          hitCount: 0,
          missCount: 0,
          durationSeconds: 0,
          expectedChordCount: 0,
        ),
      );
      // 至少返回 1 条总结
      expect(result, isNotEmpty);
      expect(result.first.category, '总结');
    });

    test('音准差 → 给出"音准波动较大"建议', () {
      final List<int> cents = List<int>.filled(100, 50); // 全部 50 cents
      final result = AiSuggestionEngine.generate(
        AiAnalysisInput(
          centsHistory: cents,
          hitCount: 10,
          missCount: 90,
          durationSeconds: 30,
          expectedChordCount: 100,
        ),
      );
      expect(
        result.any((s) => s.title.contains('音准波动')),
        isTrue,
        reason: '应有音准波动建议',
      );
    });

    test('音准好 + 命中率高 → 给出鼓励', () {
      final List<int> cents = List<int>.filled(100, 5); // 平均 5 cents
      final result = AiSuggestionEngine.generate(
        AiAnalysisInput(
          centsHistory: cents,
          hitCount: 90,
          missCount: 10,
          durationSeconds: 60,
          expectedChordCount: 100,
        ),
      );
      expect(
        result.any((s) => s.title.contains('表现出色') || s.title.contains('优秀')),
        isTrue,
      );
    });

    test('命中率低 → 给出指法警告', () {
      final result = AiSuggestionEngine.generate(
        const AiAnalysisInput(
          centsHistory: <int>[10, 20, 15, 30, 25],
          hitCount: 5,
          missCount: 10,
          durationSeconds: 30,
          expectedChordCount: 15,
        ),
      );
      expect(
        result.any((s) => s.title.contains('命中率')),
        isTrue,
      );
    });

    test('练习时长太短 → 给出提示', () {
      final result = AiSuggestionEngine.generate(
        const AiAnalysisInput(
          centsHistory: <int>[10],
          hitCount: 1,
          missCount: 0,
          durationSeconds: 2,
          expectedChordCount: 10,
        ),
      );
      expect(
        result.any((s) => s.title.contains('时长太短')),
        isTrue,
      );
    });

    test('pickPrimary 返回 severity 最高的非总结建议', () {
      const list = <AiSuggestion>[
        AiSuggestion(
            category: '总结', title: 's', detail: 'd', severity: 0),
        AiSuggestion(
            category: '音准', title: 't1', detail: 'd', severity: 1),
        AiSuggestion(
            category: '指法', title: 't2', detail: 'd', severity: 2),
      ];
      final primary = AiSuggestionEngine.pickPrimary(list);
      expect(primary?.category, '指法');
    });
  });

  group('PracticeMode', () {
    test('三种模式存在', () {
      expect(PracticeMode.values, hasLength(3));
      expect(PracticeMode.guide.name, 'guide');
      expect(PracticeMode.sing.name, 'sing');
      expect(PracticeMode.free.name, 'free');
    });
  });

  group('PracticeState 新字段', () {
    test('initial state 字段默认值', () {
      final s = PracticeState.initial();
      expect(s.mode, PracticeMode.guide);
      expect(s.hitCount, 0);
      expect(s.missCount, 0);
      expect(s.centsHistory, isEmpty);
      expect(s.suggestions, isEmpty);
      expect(s.elapsedSeconds, 0);
      expect(s.expectedChordCount, 0);
      expect(s.isMistake, isFalse);
      expect(s.isHit, isFalse);
    });

    test('cents.abs() > 30 → isMistake', () {
      final s = PracticeState.initial().copyWith(
        detectedFrequency: 440,
        centsOffset: 50,
      );
      expect(s.isMistake, isTrue);
    });

    test('cents.abs() <= 20 + 有频率 → isHit', () {
      final s = PracticeState.initial().copyWith(
        detectedFrequency: 440,
        centsOffset: 10,
      );
      expect(s.isHit, isTrue);
    });

    test('hitRate 计算正确（通过 PracticeState 转 AiAnalysisInput）', () {
      final s = PracticeState.initial().copyWith(
        hitCount: 75,
        missCount: 25,
      );
      final input = AiAnalysisInput(
        centsHistory: s.centsHistory,
        hitCount: s.hitCount,
        missCount: s.missCount,
        durationSeconds: s.elapsedSeconds,
        expectedChordCount: s.expectedChordCount,
      );
      expect(input.hitRate, 0.75);
    });
  });

  group('AiAnalysisInput', () {
    test('centsHistory 空时 bigCentsRatio = 0', () {
      const input = AiAnalysisInput(
        centsHistory: <int>[],
        hitCount: 0,
        missCount: 0,
        durationSeconds: 0,
        expectedChordCount: 0,
      );
      expect(input.bigCentsRatio, 0);
      expect(input.avgCents, 0);
      expect(input.hitRate, 0);
    });

    test('centsHistory 不空时正确统计', () {
      const input = AiAnalysisInput(
        centsHistory: <int>[10, 50, 20, 40],
        hitCount: 2,
        missCount: 2,
        durationSeconds: 30,
        expectedChordCount: 4,
      );
      expect(input.bigCentsRatio, 0.5); // 50, 40 超过 30
      expect(input.avgCents, 30); // (10+50+20+40)/4
      expect(input.hitRate, 0.5);
    });
  });
}