/// 发现区模块测试
import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele/features/discover/mock_community.dart';

void main() {
  group('Mock 数据完整性', () {
    test('热门曲目至少 5 条', () {
      expect(kMockHotSheets.length, greaterThanOrEqualTo(5));
    });

    test('热门曲目按 playCount 降序排列', () {
      for (int i = 1; i < kMockHotSheets.length; i++) {
        expect(
          kMockHotSheets[i].playCount,
          lessThanOrEqualTo(kMockHotSheets[i - 1].playCount),
          reason: '第 $i 条 playCount 应该 ≤ 第 ${i - 1} 条',
        );
      }
    });

    test('热门曲目 sheetId 唯一', () {
      final ids = kMockHotSheets.map((h) => h.sheetId).toSet();
      expect(ids.length, kMockHotSheets.length);
    });

    test('学员动态至少 8 条', () {
      expect(kMockUserWorks.length, greaterThanOrEqualTo(8));
    });

    test('学员动态 id 唯一', () {
      final ids = kMockUserWorks.map((w) => w.id).toSet();
      expect(ids.length, kMockUserWorks.length);
    });

    test('学员评分在 0-100 范围内', () {
      for (final w in kMockUserWorks) {
        expect(w.score, inInclusiveRange(0, 100));
      }
    });

    test('学员动态渐变至少 2 色', () {
      for (final w in kMockUserWorks) {
        expect(w.gradient.length, greaterThanOrEqualTo(2));
      }
    });

    test('最近学习至少 3 条', () {
      expect(kMockRecentPractices.length, greaterThanOrEqualTo(3));
    });
  });

  group('timeAgo 格式化', () {
    test('< 60 分钟 → "X 分钟前"', () {
      expect(timeAgo(5), '5 分钟前');
      expect(timeAgo(59), '59 分钟前');
    });

    test('60-1440 分钟 → "X 小时前"', () {
      expect(timeAgo(60), '1 小时前');
      expect(timeAgo(120), '2 小时前');
    });

    test('>= 1440 分钟 → "X 天前"', () {
      expect(timeAgo(1440), '1 天前');
      expect(timeAgo(2880), '2 天前');
    });
  });
}