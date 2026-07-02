/// 课程图文教程测试
import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele/features/course_center/course_data.dart';
import 'package:ukulele/features/course_center/lesson_content.dart';

void main() {
  group('核心内容索引', () {
    test('包含 27 节核心内容（6 门课 × 4-6 节）', () {
      expect(kCoreLessonContent.length, 27);
    });

    test('6 个 lesson id 都对应真实课程节', () {
      for (final id in kCoreLessonContent.keys) {
        bool found = false;
        for (final c in kMockCourses) {
          for (final l in c.lessons) {
            if (l.id == id) {
              found = true;
              break;
            }
          }
          if (found) break;
        }
        expect(found, isTrue, reason: '$id 未在 kMockCourses 中找到');
      }
    });

    test('hasCoreContent 函数正确', () {
      expect(hasCoreContent('intro-uke-1'), isTrue);
      expect(hasCoreContent('intro-uke-2'), isTrue);
      expect(hasCoreContent('not-exist'), isFalse);
    });

    test('getCoreContent 返回非空 list', () {
      final blocks = getCoreContent('intro-uke-1');
      expect(blocks, isNotNull);
      expect(blocks!.length, greaterThan(0));
    });
  });

  group('每节内容结构', () {
    test('每节至少 3 个 block', () {
      for (final entry in kCoreLessonContent.entries) {
        expect(
          entry.value.length,
          greaterThanOrEqualTo(3),
          reason: '${entry.key} block 数量过少',
        );
      }
    });

    test('每节第 1 个 block 是 title 文本', () {
      for (final entry in kCoreLessonContent.entries) {
        final first = entry.value.first;
        expect(first, isA<TextBlock>(),
            reason: '${entry.key} 第 1 个 block 应是 TextBlock');
        expect((first as TextBlock).style, LessonTextStyle.title,
            reason: '${entry.key} 第 1 个 TextBlock 应是 title 样式');
      }
    });

    test('每节包含至少 1 个 ImageBlock 或 SvgBlock', () {
      for (final entry in kCoreLessonContent.entries) {
        final hasImage = entry.value.any((b) => b is ImageBlock || b is SvgBlock);
        expect(hasImage, isTrue, reason: '${entry.key} 应有 ImageBlock 或 SvgBlock');
      }
    });

    test('每节包含至少 1 个 StepListBlock', () {
      for (final entry in kCoreLessonContent.entries) {
        final hasStep = entry.value.any((b) => b is StepListBlock);
        expect(hasStep, isTrue, reason: '${entry.key} 应有 StepListBlock');
      }
    });
  });

  group('block 字段非空', () {
    test('TextBlock text 非空', () {
      for (final entry in kCoreLessonContent.entries) {
        for (final b in entry.value) {
          if (b is TextBlock) {
            expect(b.text.isNotEmpty, isTrue,
                reason: '${entry.key} TextBlock text 为空');
          }
        }
      }
    });

    test('ImageBlock emoji / caption 非空', () {
      for (final entry in kCoreLessonContent.entries) {
        for (final b in entry.value) {
          if (b is ImageBlock) {
            expect(b.emoji.isNotEmpty, isTrue);
            expect(b.caption.isNotEmpty, isTrue);
            expect(b.gradient.length, greaterThanOrEqualTo(2));
          }
        }
      }
    });

    test('StepListBlock 步骤 index 连续从 1 开始', () {
      for (final entry in kCoreLessonContent.entries) {
        for (final b in entry.value) {
          if (b is StepListBlock) {
            expect(b.steps, isNotEmpty);
            for (int i = 0; i < b.steps.length; i++) {
              expect(b.steps[i].index, i + 1,
                  reason: '${entry.key} step 索引应该从 1 开始连续');
              expect(b.steps[i].text.isNotEmpty, isTrue);
            }
          }
        }
      }
    });

    test('SvgBlock caption 非空且 svgType 有效', () {
      for (final entry in kCoreLessonContent.entries) {
        for (final b in entry.value) {
          if (b is SvgBlock) {
            expect(b.caption.isNotEmpty, isTrue);
            expect(SvgType.values.contains(b.svgType), isTrue);
          }
        }
      }
    });
  });

  group('SvgBlock 覆盖', () {
    test('6 门课的关键图至少 7 处用 SvgBlock 替换占位', () {
      int count = 0;
      for (final entry in kCoreLessonContent.entries) {
        for (final b in entry.value) {
          if (b is SvgBlock) count++;
        }
      }
      expect(count, greaterThanOrEqualTo(7),
          reason: '应该至少有 7 处 SvgBlock 替换原占位');
    });

    test('fretboard 模式至少 2 处使用（intro-uke-1 + first-chord-prog-1）', () {
      int fretCount = 0;
      for (final entry in kCoreLessonContent.entries) {
        for (final b in entry.value) {
          if (b is SvgBlock && b.svgType == SvgType.fretboard) {
            fretCount++;
          }
        }
      }
      expect(fretCount, greaterThanOrEqualTo(2));
    });

    test('所有 5 种 SvgType 都至少被使用一次', () {
      final Set<SvgType> used = <SvgType>{};
      for (final entry in kCoreLessonContent.entries) {
        for (final b in entry.value) {
          if (b is SvgBlock) used.add(b.svgType);
        }
      }
      for (final t in SvgType.values) {
        expect(used.contains(t), isTrue,
            reason: '$t 至少应被使用一次');
      }
    });
  });
}