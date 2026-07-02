/// 课程中心 Mock 数据
library;

import 'package:flutter/material.dart';

import 'course_model.dart';

/// 6 门课程：启蒙（3）+ 进阶（2）+ 高阶（1）
/// 全部 mock 数据，无后端、无视频音频
const List<Course> kMockCourses = <Course>[
  // ========== 启蒙 ==========
  Course(
    id: 'intro-uke',
    title: '尤克里里入门',
    subtitle: '从零开始认识四弦琴',
    level: CourseLevel.beginner,
    lessonCount: 6,
    totalMinutes: 45,
    tags: <String>['零基础', '必学', '入门'],
    icon: Icons.queue_music,
    lessons: <CourseLesson>[
      CourseLesson(
        id: 'intro-uke-1',
        title: '认识尤克里里',
        durationMinutes: 5,
        description: '了解四弦琴的结构、调弦方式、常见尺寸',
      ),
      CourseLesson(
        id: 'intro-uke-2',
        title: '标准调弦 GCEA',
        durationMinutes: 8,
        description: '用调音器把 4 根弦调到标准音',
      ),
      CourseLesson(
        id: 'intro-uke-3',
        title: '正确持琴姿势',
        durationMinutes: 6,
        description: '右手拨弦、左手按弦的基本手型',
      ),
      CourseLesson(
        id: 'intro-uke-4',
        title: '单音练习：C / A / F',
        durationMinutes: 8,
        description: '从中央 C 开始，弹 3 个最简单的音',
      ),
      CourseLesson(
        id: 'intro-uke-5',
        title: '第一个和弦：C / Am',
        durationMinutes: 10,
        description: '学会按 C 和 Am 两个最基础和弦',
      ),
      CourseLesson(
        id: 'intro-uke-6',
        title: '简单曲目：小星星',
        durationMinutes: 8,
        description: '用 C 和 Am 完成《小星星》',
      ),
    ],
  ),
  Course(
    id: 'rhythm-basic',
    title: '节奏基础',
    subtitle: '节拍、拍号、节奏型',
    level: CourseLevel.beginner,
    lessonCount: 4,
    totalMinutes: 30,
    tags: <String>['节奏', '节拍', '基础'],
    icon: Icons.timer,
    lessons: <CourseLesson>[
      CourseLesson(
        id: 'rhythm-basic-1',
        title: '什么是 BPM？',
        durationMinutes: 6,
        description: '速度的衡量单位',
      ),
      CourseLesson(
        id: 'rhythm-basic-2',
        title: '4/4 拍号怎么数',
        durationMinutes: 8,
        description: '强拍、弱拍、4 分音符',
      ),
      CourseLesson(
        id: 'rhythm-basic-3',
        title: '3/4 与 6/8 拍号',
        durationMinutes: 8,
        description: '华尔兹与摇滚节奏',
      ),
      CourseLesson(
        id: 'rhythm-basic-4',
        title: '节拍器跟拍练习',
        durationMinutes: 8,
        description: '用节拍器训练稳定节奏',
      ),
    ],
  ),
  Course(
    id: 'first-chord-prog',
    title: '初识和弦进行',
    subtitle: 'C-Am-F-G 最常用 4 和弦',
    level: CourseLevel.beginner,
    lessonCount: 3,
    totalMinutes: 25,
    tags: <String>['和弦', '练习', '流行'],
    icon: Icons.queue_music,
    lessons: <CourseLesson>[
      CourseLesson(
        id: 'first-chord-prog-1',
        title: '认识 C / Am / F / G',
        durationMinutes: 8,
        description: '4 个最常用和弦的指法',
      ),
      CourseLesson(
        id: 'first-chord-prog-2',
        title: '四和弦循环',
        durationMinutes: 10,
        description: 'C-Am-F-G 循环练习',
      ),
      CourseLesson(
        id: 'first-chord-prog-3',
        title: '欢乐颂实战',
        durationMinutes: 7,
        description: '用 4 个和弦弹《欢乐颂》',
      ),
    ],
  ),

  // ========== 进阶 ==========
  Course(
    id: 'strumming-patterns',
    title: '常用扫弦节奏型',
    subtitle: 'Down / Up / 切音 综合应用',
    level: CourseLevel.intermediate,
    lessonCount: 5,
    totalMinutes: 50,
    tags: <String>['扫弦', '节奏型', '进阶'],
    icon: Icons.graphic_eq,
    lessons: <CourseLesson>[
      CourseLesson(
        id: 'strumming-1',
        title: '下扫 (Down) 与上扫 (Up)',
        durationMinutes: 8,
        description: '右手基本动作',
      ),
      CourseLesson(
        id: 'strumming-2',
        title: '4 拍节奏型 D-D-U-U-D-U',
        durationMinutes: 10,
        description: '最常用的分解节奏',
      ),
      CourseLesson(
        id: 'strumming-3',
        title: '切音技巧',
        durationMinutes: 10,
        description: '用大鱼际/手掌制造切音',
      ),
      CourseLesson(
        id: 'strumming-4',
        title: '附点与连音线',
        durationMinutes: 12,
        description: '让节奏更动感',
      ),
      CourseLesson(
        id: 'strumming-5',
        title: '流行曲实战：小毛驴变奏',
        durationMinutes: 10,
        description: '应用节奏型到曲目',
      ),
    ],
  ),
  Course(
    id: 'barre-chords',
    title: '横按和弦进阶',
    subtitle: 'F / Bm / Cmaj7 大横按',
    level: CourseLevel.intermediate,
    lessonCount: 4,
    totalMinutes: 40,
    tags: <String>['横按', 'F 和弦', '高阶和弦'],
    icon: Icons.back_hand,
    lessons: <CourseLesson>[
      CourseLesson(
        id: 'barre-1',
        title: '横按手感练习',
        durationMinutes: 10,
        description: '食指侧边按弦',
      ),
      CourseLesson(
        id: 'barre-2',
        title: 'F 和弦简化版',
        durationMinutes: 10,
        description: 'Fmaj7 / F（简）',
      ),
      CourseLesson(
        id: 'barre-3',
        title: 'Bm 和弦',
        durationMinutes: 10,
        description: '2 弦横按 + 3 4 弦 2 3 品',
      ),
      CourseLesson(
        id: 'barre-4',
        title: '横按转换练习',
        durationMinutes: 10,
        description: 'F → C → G → Am 切换',
      ),
    ],
  ),

  // ========== 高阶 ==========
  Course(
    id: 'fingerstyle',
    title: '指弹独奏入门',
    subtitle: '分解和弦 / 旋律 / 混合',
    level: CourseLevel.advanced,
    lessonCount: 5,
    totalMinutes: 70,
    tags: <String>['指弹', '独奏', '高级'],
    icon: Icons.music_note,
    lessons: <CourseLesson>[
      CourseLesson(
        id: 'fingerstyle-1',
        title: '指弹拨弦指法',
        durationMinutes: 12,
        description: 'PIMA 4 指独立',
      ),
      CourseLesson(
        id: 'fingerstyle-2',
        title: '分解和弦练习',
        durationMinutes: 14,
        description: '1-3-2-4-3 通用节奏型',
      ),
      CourseLesson(
        id: 'fingerstyle-3',
        title: '旋律与和弦混合',
        durationMinutes: 15,
        description: '拇指根音 + 食指中指旋律',
      ),
      CourseLesson(
        id: 'fingerstyle-4',
        title: '勾击弦 (Hammer-on / Pull-off)',
        durationMinutes: 14,
        description: '左手装饰技巧',
      ),
      CourseLesson(
        id: 'fingerstyle-5',
        title: '指弹曲目：《River Flows in You》',
        durationMinutes: 15,
        description: '完整曲目实战',
      ),
    ],
  ),
];

/// 按 id 查找课程
Course? findCourseById(String id) {
  for (final c in kMockCourses) {
    if (c.id == id) return c;
  }
  return null;
}

/// 按 level 过滤
List<Course> coursesByLevel(CourseLevel level) {
  return kMockCourses.where((c) => c.level == level).toList();
}