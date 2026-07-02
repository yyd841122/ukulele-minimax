import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele/features/tuner/domain/music_note.dart';

void main() {
  group('MusicNote.fromFrequency', () {
    test('A4 440Hz 应该识别为 A4 且 cents=0', () {
      final note = MusicNote.fromFrequency(440.0);
      expect(note.displayName, 'A4');
      expect(note.cents, 0);
      expect(note.isInTune, true);
    });

    test('比 A4 高 50 cents 应为 A#4', () {
      // A#4 = 440 * 2^(1/12) ≈ 466.16Hz
      // 距 A4 +50 cents 应该是 440 * 2^(0.5/12) ≈ 452.89Hz，仍在 A4 范围内但接近 A#4
      // 改为精确测试 A#4：466.16Hz 应识别为 A#4，cents 接近 0
      final note = MusicNote.fromFrequency(466.16);
      expect(note.name, 'A#');
      expect(note.octave, 4);
      expect(note.cents.abs() <= 5, true);
    });

    test('比 A4 低一个八度应识别为 A3', () {
      final note = MusicNote.fromFrequency(220.0);
      expect(note.displayName, 'A3');
      expect(note.cents, 0);
    });

    test('无效频率应返回占位 note', () {
      final note = MusicNote.fromFrequency(0);
      expect(note.frequency, 0);
      expect(note.displayName, '-0');
    });

    test('偏高 10 cents 应标识为 sharp', () {
      // A4 + 10 cents = 440 * 2^(10/1200) ≈ 442.54
      final note = MusicNote.fromFrequency(442.54);
      expect(note.isSharp, true);
      expect(note.cents, greaterThan(5));
    });
  });

  group('UkuleleStandardTuning.nearestString', () {
    test('440Hz 应是 A 弦', () {
      final s = UkuleleStandardTuning.nearestString(440);
      expect(s?.displayName, 'A4');
    });

    test('329Hz 应是 E 弦', () {
      final s = UkuleleStandardTuning.nearestString(329.63);
      expect(s?.displayName, 'E4');
    });

    test('0Hz 应返回 null', () {
      final s = UkuleleStandardTuning.nearestString(0);
      expect(s, isNull);
    });
  });
}