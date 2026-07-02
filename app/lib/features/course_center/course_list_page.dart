/// 课程中心列表页（M04）
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import 'course_data.dart';
import 'course_model.dart';

/// 课程中心列表页
class CourseCenterPage extends StatelessWidget {
  const CourseCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程中心'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: <Widget>[
          // 页头
          _Header(),
          const SizedBox(height: 16),

          for (final CourseLevel level in CourseLevel.values) ...<Widget>[
            _LevelSection(level: level),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF5C6BC0), Color(0xFF7986CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text(
            '体系化学习',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '从启蒙到高阶，跟随课程一步步成长',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LevelSection extends StatelessWidget {
  const _LevelSection({required this.level});
  final CourseLevel level;

  @override
  Widget build(BuildContext context) {
    final List<Course> list = coursesByLevel(level);
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 章节标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: <Widget>[
              Icon(level.icon, size: 20, color: level.color),
              const SizedBox(width: 6),
              Text(
                level.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: level.color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: level.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${list.length} 门',
                  style: TextStyle(
                    fontSize: 11,
                    color: level.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 课程卡片列表
        for (final c in list) ...<Widget>[
          _CourseCard(course: c),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '${AppRoutes.courseCenterDetail.replaceAll(':id', course.id)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              // 左侧图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: course.level.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  course.icon,
                  size: 28,
                  color: course.level.color,
                ),
              ),
              const SizedBox(width: 12),
              // 右侧内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.list_alt,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${course.lessonCount} 节',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${course.totalMinutes} 分钟',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 标签
                    Wrap(
                      spacing: 4,
                      children: <Widget>[
                        for (final t in course.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}