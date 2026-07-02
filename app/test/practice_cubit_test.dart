import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele/features/practice/practice_cubit.dart';

void main() {
  group('PracticeState', () {
    test('初始状态应为 idle', () {
      final PracticeState state = PracticeState.initial();
      expect(state.status, PracticeStatus.idle);
      expect(state.sheet, isNull);
      expect(state.expectedIndex, 0);
      expect(state.recordedBytes, isEmpty);
    });

    test('copyWith 应正确更新字段', () {
      final PracticeState state = PracticeState.initial();
      final PracticeState updated = state.copyWith(
        status: PracticeStatus.playing,
        expectedChord: 'C',
        expectedIndex: 1,
      );
      expect(updated.status, PracticeStatus.playing);
      expect(updated.expectedChord, 'C');
      expect(updated.expectedIndex, 1);
    });

    test('copyWith(clearError:true) 应清除错误', () {
      final PracticeState state = PracticeState.initial()
          .copyWith(errorMessage: 'X');
      final PracticeState cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });
  });

  group('PracticeCubit 业务逻辑（用纯函数验证）', () {
    test('C4 根音频率应约 261.63Hz', () {
      // 测试内部 _noteRootFreq 的纯函数等价
      const double expected = 261.63;
      final double computed = 440.0 * math.pow(2.0, (60 - 69) / 12.0);
      expect(computed, closeTo(expected, 0.05));
    });

    test('A4 频率应精确等于 440Hz', () {
      final double computed = 440.0 * math.pow(2.0, (69 - 69) / 12.0);
      expect(computed, 440.0);
    });

    test('cents 偏差公式：频率翻倍 = 1200 cents', () {
      // 任何频率翻倍应偏差 +1200 cents
      final int cents = (1200.0 * (math.log(880.0 / 440.0) / math.ln2)).round();
      expect(cents, 1200);
    });

    test('cents 偏差公式：A4 vs A#4 约 +100 cents', () {
      final double a4 = 440.0;
      final double asharp4 = a4 * math.pow(2.0, 1 / 12.0);
      final int cents =
          (1200.0 * (math.log(asharp4 / a4) / math.ln2)).round();
      expect(cents, 100);
    });
  });
}