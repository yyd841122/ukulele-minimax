// 曲谱客户端模型

class Sheet {
  const Sheet({
    required this.id,
    required this.title,
    this.titleEn,
    this.artist,
    required this.instrument,
    required this.difficulty,
    required this.bpm,
    required this.durationSeconds,
    required this.keySignature,
    this.coverUrl,
    this.sheetDataUrl,
    this.audioDemoUrl,
    this.chords = const <Map<String, dynamic>>[],
    this.notesSimplified,
    this.tags = const <String>[],
    this.source = 'original',
    this.copyrightHolder,
    required this.viewCount,
    required this.favoriteCount,
  });

  final int id;
  final String title;
  final String? titleEn;
  final String? artist;
  final String instrument;
  final String difficulty;
  final int bpm;
  final int durationSeconds;
  final String keySignature;
  final String? coverUrl;
  final String? sheetDataUrl;
  final String? audioDemoUrl;
  final List<Map<String, dynamic>> chords;
  final String? notesSimplified;
  final List<String> tags;
  final String source;
  final String? copyrightHolder;
  final int viewCount;
  final int favoriteCount;

  factory Sheet.fromJson(Map<String, dynamic> json) {
    return Sheet(
      id: (json['id'] as int?) ?? 0,
      title: (json['title'] as String?) ?? '未知',
      titleEn: json['title_en'] as String?,
      artist: json['artist'] as String?,
      instrument: (json['instrument'] as String?) ?? 'ukulele',
      difficulty: (json['difficulty'] as String?) ?? 'beginner',
      bpm: (json['bpm'] as int?) ?? 80,
      durationSeconds: (json['duration_seconds'] as int?) ?? 0,
      keySignature: (json['key_signature'] as String?) ?? 'C',
      coverUrl: json['cover_url'] as String?,
      sheetDataUrl: json['sheet_data_url'] as String?,
      audioDemoUrl: json['audio_demo_url'] as String?,
      chords: (json['chords'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[],
      notesSimplified: json['notes_simplified'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      source: (json['source'] as String?) ?? 'original',
      copyrightHolder: json['copyright_holder'] as String?,
      viewCount: (json['view_count'] as int?) ?? 0,
      favoriteCount: (json['favorite_count'] as int?) ?? 0,
    );
  }

  /// 难度中文标签
  String get difficultyLabel {
    switch (difficulty) {
      case 'beginner':
        return '入门';
      case 'easy':
        return '简单';
      case 'medium':
        return '中等';
      case 'hard':
        return '困难';
      case 'expert':
        return '专家';
      default:
        return difficulty;
    }
  }

  /// 难度颜色
  String get difficultyEmoji {
    switch (difficulty) {
      case 'beginner':
        return '⭐';
      case 'easy':
        return '⭐⭐';
      case 'medium':
        return '⭐⭐⭐';
      case 'hard':
        return '⭐⭐⭐⭐';
      case 'expert':
        return '⭐⭐⭐⭐⭐';
      default:
        return '⭐';
    }
  }

  /// 时长格式化（mm:ss）
  String get durationLabel {
    final int m = durationSeconds ~/ 60;
    final int s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}