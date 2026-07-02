/// 课程中心模型与数据测试
import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele/features/course_center/course_data.dart';
import 'package:ukulele/features/course_center/course_model.dart';

void main() {
  group('CourseModel', () {
    test('CourseLevel.fromId 三档映射正确', () {
      expect(CourseLevel.fromId('beginner'), CourseLevel.beginner);
      expect(CourseLevel.fromId('intermediate'), CourseLevel.intermediate);
      expect(CourseLevel.fromId('advanced'), CourseLevel.advanced);
      // 未知 id 兜底为 beginner
      expect(CourseLevel.fromId('xxx'), CourseLevel.beginner);
    });

    test('Course.toJson 包含所有字段', () {
      final c = kMockCourses.first;
      final json = c.toJson();
      expect(json['id'], c.id);
      expect(json['title'], c.title);
      expect(json['lessonCount'], c.lessonCount);
      expect(json['totalMinutes'], c.totalMinutes);
      expect(json['level'], c.level.id);
      expect((json['lessons'] as List).length, c.lessonCount);
    });
  });

  group('MockData', () {
    test('至少 6 门课程', () {
      expect(kMockCourses.length, greaterThanOrEqualTo(6));
    });

    test('每个 level 都有课程', () {
      for (final lv in CourseLevel.values) {
        expect(coursesByLevel(lv).length, greaterThan(0),
            reason: '$lv 至少要有 1 门课');
      }
    });

    test('每门课程 lessonCount == lessons.length', () {
      for (final c in kMockCourses) {
        expect(c.lessons.length, c.lessonCount,
            reason: '${c.id} lessonCount 不一致');
      }
    });

    test('每门课 totalMinutes == lessons.durationMinutes 之和', () {
      for (final c in kMockCourses) {
        final sum = c.lessons
            .fold<int>(0, (s, l) => s + l.durationMinutes);
        expect(sum, c.totalMinutes,
            reason: '${c.id} totalMinutes 不等于 durationMinutes 之和');
      }
    });

    test('每门课 id 唯一', () {
      final ids = kMockCourses.map((c) => c.id).toSet();
      expect(ids.length, kMockCourses.length);
    });

    test('findCourseById 能找到所有课', () {
      for (final c in kMockCourses) {
        expect(findCourseById(c.id)?.id, c.id);
      }
      expect(findCourseById('not-exist'), isNull);
    });
  });
}