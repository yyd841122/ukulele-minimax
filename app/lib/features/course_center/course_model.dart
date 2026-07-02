/// 课程模型（M04 课程中心 MVP）
library;

import 'package:flutter/material.dart';

/// 难度分级（参考 PRD：体系课启蒙→进阶→高阶）
enum CourseLevel {
  beginner('beginner', '启蒙', Icons.accessibility_new, Color(0xFF66BB6A)),
  intermediate('intermediate', '进阶', Icons.bolt, Color(0xFF42A5F5)),
  advanced('advanced', '高阶', Icons.local_fire_department, Color(0xFFEF5350));

  const CourseLevel(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  static CourseLevel fromId(String id) {
    return values.firstWhere(
      (e) => e.id == id,
      orElse: () => CourseLevel.beginner,
    );
  }
}

/// 单节课程
class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.title,
    required this.durationMinutes,
    this.description = '',
  });

  final String id;
  final String title;
  final int durationMinutes;
  final String description;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'durationMinutes': durationMinutes,
        'description': description,
      };
}

/// 一门课程
class Course {
  const Course({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.lessonCount,
    required this.totalMinutes,
    required this.tags,
    required this.lessons,
    this.icon = Icons.school,
  });

  final String id;
  final String title;
  final String subtitle;
  final CourseLevel level;
  final int lessonCount;
  final int totalMinutes;
  final List<String> tags;
  final List<CourseLesson> lessons;
  final IconData icon;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'level': level.id,
        'lessonCount': lessonCount,
        'totalMinutes': totalMinutes,
        'tags': tags,
        'lessons': lessons.map((e) => e.toJson()).toList(),
      };
}