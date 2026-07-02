import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele/features/sheets/data/sheet_model.dart';

void main() {
  group('Sheet.fromJson', () {
    test('完整 JSON 应正确解析', () {
      final Sheet sheet = Sheet.fromJson(<String, dynamic>{
        'id': 1,
        'title': '小星星',
        'title_en': 'Twinkle Twinkle',
        'artist': '传统童谣',
        'instrument': 'ukulele',
        'difficulty': 'beginner',
        'bpm': 80,
        'duration_seconds': 45,
        'key_signature': 'C',
        'cover_url': null,
        'sheet_data_url': null,
        'audio_demo_url': null,
        'chords': <Map<String, dynamic>>[
          <String, dynamic>{'chord': 'C', 'time_ms': 0, 'beats': 2},
          <String, dynamic>{'chord': 'F', 'time_ms': 2000, 'beats': 2},
        ],
        'notes_simplified': '1 1 5 5 6 6 5 -',
        'tags': <String>['童谣', '入门'],
        'source': 'public-domain',
        'copyright_holder': null,
        'view_count': 100,
        'favorite_count': 10,
      });

      expect(sheet.id, 1);
      expect(sheet.title, '小星星');
      expect(sheet.titleEn, 'Twinkle Twinkle');
      expect(sheet.chords.length, 2);
      expect(sheet.tags.length, 2);
      expect(sheet.difficultyLabel, '入门');
      expect(sheet.durationLabel, '00:45');
    });

    test('缺省字段应有合理默认值', () {
      final Sheet sheet = Sheet.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'Test',
        'instrument': 'ukulele',
        'difficulty': 'beginner',
        'bpm': 80,
        'duration_seconds': 60,
        'key_signature': 'C',
        'view_count': 0,
        'favorite_count': 0,
      });

      expect(sheet.titleEn, isNull);
      expect(sheet.chords, isEmpty);
      expect(sheet.tags, isEmpty);
      expect(sheet.notesSimplified, isNull);
      expect(sheet.source, 'original');
    });

    test('难度标签映射', () {
      Sheet make(String d) => Sheet.fromJson(<String, dynamic>{
            'id': 1,
            'title': 'X',
            'instrument': 'ukulele',
            'difficulty': d,
            'bpm': 80,
            'duration_seconds': 60,
            'key_signature': 'C',
            'view_count': 0,
            'favorite_count': 0,
          });

      expect(make('beginner').difficultyLabel, '入门');
      expect(make('easy').difficultyLabel, '简单');
      expect(make('medium').difficultyLabel, '中等');
      expect(make('hard').difficultyLabel, '困难');
      expect(make('expert').difficultyLabel, '专家');
      expect(make('xx').difficultyLabel, 'xx');
    });

    test('时长标签 mm:ss 格式', () {
      Sheet make(int s) => Sheet.fromJson(<String, dynamic>{
            'id': 1,
            'title': 'X',
            'instrument': 'ukulele',
            'difficulty': 'beginner',
            'bpm': 80,
            'duration_seconds': s,
            'key_signature': 'C',
            'view_count': 0,
            'favorite_count': 0,
          });

      expect(make(45).durationLabel, '00:45');
      expect(make(60).durationLabel, '01:00');
      expect(make(125).durationLabel, '02:05');
    });
  });
}