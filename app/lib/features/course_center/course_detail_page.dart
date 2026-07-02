/// 课程详情页（M04）
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'course_data.dart';
import 'course_model.dart';
import 'lesson_content.dart';

class CourseDetailPage extends StatelessWidget {
  const CourseDetailPage({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context) {
    final Course? course = findCourseById(courseId);
    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('课程详情')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('找不到该课程'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: <Widget>[
          // 顶部课程卡片
          _CourseHeader(course: course),
          const SizedBox(height: 16),
          // 课节列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              '课程目录',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: course.level.color,
              ),
            ),
          ),
          for (int i = 0; i < course.lessons.length; i++) ...<Widget>[
            _LessonTile(
              lesson: course.lessons[i],
              index: i + 1,
              courseColor: course.level.color,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          // 提示条
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.amber.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MVP 阶段暂无视频/音频内容，课程详情后续接入',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            course.level.color.withValues(alpha: 0.92),
            course.level.color.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.school, color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(
                course.level.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            course.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            course.subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(Icons.list_alt, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                '${course.lessonCount} 节',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                '${course.totalMinutes} 分钟',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.index,
    required this.courseColor,
  });
  final CourseLesson lesson;
  final int index;
  final Color courseColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 0.5,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: courseColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: courseColor,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (lesson.description.isNotEmpty)
                Text(
                  lesson.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.timer_outlined,
                    size: 10,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${lesson.durationMinutes} 分钟',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.play_circle_outline,
          color: courseColor,
          size: 26,
        ),
        onTap: () {
          if (hasCoreContent(lesson.id)) {
            context.push('/lessons/${lesson.id}');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('MVP：${lesson.title} 内容待接入'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }
}