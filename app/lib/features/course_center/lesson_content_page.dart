/// 单节正文页（图文教程）
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'course_data.dart';
import 'course_model.dart';
import 'lesson_content.dart';
import 'lesson_content_renderer.dart';

/// 单节正文页
class LessonContentPage extends StatelessWidget {
  const LessonContentPage({
    super.key,
    required this.lessonId,
  });
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final Course? course = _findCourseByLesson(lessonId);
    final CourseLesson? lesson = _findLesson(lessonId);
    if (course == null || lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('课程内容')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text('找不到节：$lessonId'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    final List<LessonBlock> blocks = getCoreContent(lessonId) ?? <LessonBlock>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: <Widget>[
          // 顶部头部
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  course.level.color.withValues(alpha: 0.92),
                  course.level.color.withValues(alpha: 0.65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(course.icon, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${course.level.label} · ${course.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    const Icon(Icons.timer_outlined,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.durationMinutes} 分钟',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.list_alt,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${blocks.length} 步',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 正文内容
          LessonContentRenderer(blocks: blocks),
          const SizedBox(height: 24),
          // 底部导航
          _NavBar(course: course, currentLesson: lesson),
        ],
      ),
    );
  }

  Course? _findCourseByLesson(String lessonId) {
    for (final c in kMockCourses) {
      for (final l in c.lessons) {
        if (l.id == lessonId) return c;
      }
    }
    return null;
  }

  CourseLesson? _findLesson(String lessonId) {
    for (final c in kMockCourses) {
      for (final l in c.lessons) {
        if (l.id == lessonId) return l;
      }
    }
    return null;
  }
}

/// 上一节 / 下一节
class _NavBar extends StatelessWidget {
  const _NavBar({required this.course, required this.currentLesson});
  final Course course;
  final CourseLesson currentLesson;

  @override
  Widget build(BuildContext context) {
    final int idx = course.lessons.indexWhere((l) => l.id == currentLesson.id);
    final CourseLesson? prev = idx > 0 ? course.lessons[idx - 1] : null;
    final CourseLesson? next =
        idx < course.lessons.length - 1 ? course.lessons[idx + 1] : null;

    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: prev == null
                ? null
                : () => _goLesson(context, prev.id),
            icon: const Icon(Icons.chevron_left),
            label: Text(prev == null ? '已是第一节' : '上一节'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: next == null
                ? null
                : () => _goLesson(context, next.id),
            icon: const Icon(Icons.chevron_right),
            label: Text(next == null ? '已是最后一节' : '下一节'),
            style: ElevatedButton.styleFrom(
              backgroundColor: course.level.color,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _goLesson(BuildContext context, String lessonId) {
    if (hasCoreContent(lessonId)) {
      // 跳转到下一节的图文页（重置路由栈）
      context.go('/lessons/$lessonId');
    } else {
      // 下一节暂无内容，回到课程详情页
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下一节内容待接入，回到课程详情')),
      );
      context.pop();
    }
  }
}