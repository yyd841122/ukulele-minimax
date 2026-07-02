/// 发现区 Mock 数据
library;

import 'package:flutter/material.dart';

/// 热门曲目排行（按 playCount 降序）
/// sheetId 对应 assets/sheets/ukulele_30.json 中的曲谱 id（小星星=1, 欢乐颂=2...）
class HotSheet {
  const HotSheet({
    required this.sheetId,
    required this.title,
    required this.playCount,
    required this.color,
  });
  final int sheetId;
  final String title;
  final int playCount;
  final Color color;
}

const List<HotSheet> kMockHotSheets = <HotSheet>[
  HotSheet(sheetId: 1, title: '小星星', playCount: 12893, color: Color(0xFFFFB74D)),
  HotSheet(sheetId: 2, title: '欢乐颂', playCount: 9874, color: Color(0xFF7986CB)),
  HotSheet(sheetId: 3, title: '小毛驴', playCount: 8543, color: Color(0xFF4DB6AC)),
  HotSheet(sheetId: 4, title: '两只老虎', playCount: 7612, color: Color(0xFFE57373)),
  HotSheet(sheetId: 5, title: '新年好', playCount: 6534, color: Color(0xFF81C784)),
];

/// 学员动态（瀑布流卡片）
class UserWork {
  const UserWork({
    required this.id,
    required this.username,
    required this.sheetId,
    required this.sheetTitle,
    required this.score,
    required this.minutesAgo,
    required this.gradient,
    this.likes = 0,
    this.comments = 0,
  });
  final String id;
  final String username;
  final int sheetId;
  final String sheetTitle;
  final int score; // 0-100
  final int minutesAgo;
  final List<Color> gradient;
  final int likes;
  final int comments;
}

const List<UserWork> kMockUserWorks = <UserWork>[
  UserWork(
    id: 'work-1',
    username: '桃花岛主',
    sheetId: 1,
    sheetTitle: '小星星',
    score: 92,
    minutesAgo: 8,
    gradient: <Color>[Color(0xFFFF8A65), Color(0xFFFFB74D)],
    likes: 24,
    comments: 5,
  ),
  UserWork(
    id: 'work-2',
    username: '吉他小白',
    sheetId: 2,
    sheetTitle: '欢乐颂',
    score: 87,
    minutesAgo: 23,
    gradient: <Color>[Color(0xFF7986CB), Color(0xFF64B5F6)],
    likes: 18,
    comments: 3,
  ),
  UserWork(
    id: 'work-3',
    username: 'ukulele_bob',
    sheetId: 7,
    sheetTitle: '粉刷匠',
    score: 95,
    minutesAgo: 41,
    gradient: <Color>[Color(0xFF66BB6A), Color(0xFFA5D6A7)],
    likes: 56,
    comments: 12,
  ),
  UserWork(
    id: 'work-4',
    username: '尤克里里女孩',
    sheetId: 4,
    sheetTitle: '两只老虎',
    score: 78,
    minutesAgo: 95,
    gradient: <Color>[Color(0xFFEF5350), Color(0xFFFF8A80)],
    likes: 9,
    comments: 2,
  ),
  UserWork(
    id: 'work-5',
    username: '音乐爱好者_A',
    sheetId: 6,
    sheetTitle: '新年好',
    score: 89,
    minutesAgo: 130,
    gradient: <Color>[Color(0xFFAB47BC), Color(0xFFCE93D8)],
    likes: 32,
    comments: 7,
  ),
  UserWork(
    id: 'work-6',
    username: '夏威夷的风',
    sheetId: 3,
    sheetTitle: '小毛驴',
    score: 84,
    minutesAgo: 180,
    gradient: <Color>[Color(0xFF26A69A), Color(0xFF80CBC4)],
    likes: 21,
    comments: 4,
  ),
  UserWork(
    id: 'work-7',
    username: '四弦小子',
    sheetId: 1,
    sheetTitle: '小星星',
    score: 96,
    minutesAgo: 240,
    gradient: <Color>[Color(0xFFFFCA28), Color(0xFFFFE082)],
    likes: 88,
    comments: 16,
  ),
  UserWork(
    id: 'work-8',
    username: '练琴日记',
    sheetId: 5,
    sheetTitle: '伦敦桥垮下来',
    score: 81,
    minutesAgo: 320,
    gradient: <Color>[Color(0xFF5C6BC0), Color(0xFF9FA8DA)],
    likes: 14,
    comments: 3,
  ),
  UserWork(
    id: 'work-9',
    username: 'Ukulele_Lover',
    sheetId: 9,
    sheetTitle: '送别',
    score: 90,
    minutesAgo: 500,
    gradient: <Color>[Color(0xFFEC407A), Color(0xFFF48FB1)],
    likes: 41,
    comments: 9,
  ),
  UserWork(
    id: 'work-10',
    username: '黎明',
    sheetId: 11,
    sheetTitle: '茉莉花',
    score: 86,
    minutesAgo: 720,
    gradient: <Color>[Color(0xFF7E57C2), Color(0xFFB39DDB)],
    likes: 27,
    comments: 6,
  ),
];

/// 最近学习（mock，未来接 SharedPreferences）
class RecentPractice {
  const RecentPractice({
    required this.sheetId,
    required this.sheetTitle,
    required this.lastPlayedMinutesAgo,
    required this.score,
  });
  final int sheetId;
  final String sheetTitle;
  final int lastPlayedMinutesAgo;
  final int score;
}

const List<RecentPractice> kMockRecentPractices = <RecentPractice>[
  RecentPractice(sheetId: 1, sheetTitle: '小星星', lastPlayedMinutesAgo: 60, score: 88),
  RecentPractice(sheetId: 3, sheetTitle: '小毛驴', lastPlayedMinutesAgo: 240, score: 76),
  RecentPractice(sheetId: 4, sheetTitle: '两只老虎', lastPlayedMinutesAgo: 1440, score: 92),
];

/// 格式化"几分钟前"
String timeAgo(int minutes) {
  if (minutes < 60) return '$minutes 分钟前';
  if (minutes < 1440) return '${(minutes / 60).floor()} 小时前';
  return '${(minutes / 1440).floor()} 天前';
}