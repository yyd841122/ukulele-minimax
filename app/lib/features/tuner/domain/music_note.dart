import 'dart:math' as math;

/// 标准音 A4 = 440 Hz，用于将频率转换为音名 + 八度 + cents 偏差
/// 参考音乐理论十二平均律：f(n) = A4 * 2^(n/12)
class MusicNote {
  const MusicNote({
    required this.name,
    required this.octave,
    required this.cents,
    required this.frequency,
    required this.expectedFrequency,
  });

  /// 国际音名：C, C#, D, D#, E, F, F#, G, G#, A, A#, B
  final String name;
  final int octave;
  final int cents; // [-50, +50]
  final double frequency;
  final double expectedFrequency;

  /// 是否音准（偏差 < 5 cents）
  bool get isInTune => cents.abs() <= 5;

  /// 是否偏低
  bool get isFlat => cents < -5;

  /// 是否偏高
  bool get isSharp => cents > 5;

  /// 显示用，如 A4
  String get displayName => '$name$octave';

  @override
  String toString() =>
      '$displayName ${frequency.toStringAsFixed(1)}Hz (${cents > 0 ? '+' : ''}$cents ¢)';

  /// 从任意频率推断最近的音名
  factory MusicNote.fromFrequency(
    double frequency, {
    double referenceA4 = 440.0,
  }) {
    if (frequency <= 0 || frequency.isNaN || frequency.isInfinite) {
      return const MusicNote(
        name: '-',
        octave: 0,
        cents: 0,
        frequency: 0,
        expectedFrequency: 0,
      );
    }

    // 计算与 A4 的半音差
    final double semitonesFromA4 =
        12.0 * (math.log(frequency / referenceA4) / math.ln2);

    // 找到最近的半音
    final int nearestSemitone = semitonesFromA4.round();
    final double exactCents =
        (semitonesFromA4 - nearestSemitone) * 100.0;
    final int centsInt = exactCents.round();

    // 半音名（C=0, C#=1, ..., B=11）
    const List<String> noteNames = <String>[
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
    ];

    // A4 的 MIDI 编号是 69；C4 是 60
    final int midiNumber = 69 + nearestSemitone;
    final int octave = (midiNumber ~/ 12) - 1;
    final int noteIndex = midiNumber % 12;

    final double expectedFreq = referenceA4 *
        math.pow(2, nearestSemitone / 12.0).toDouble();

    return MusicNote(
      name: noteNames[noteIndex],
      octave: octave,
      cents: centsInt,
      frequency: frequency,
      expectedFrequency: expectedFreq,
    );
  }
}

/// 尤克里里 4 弦标准调弦法（高到低）：G C E A
class UkuleleStandardTuning {
  UkuleleStandardTuning._();

  static const List<UkuleleString> strings = <UkuleleString>[
    UkuleleString(name: 'A', octave: 4, frequency: 440.00),
    UkuleleString(name: 'E', octave: 4, frequency: 329.63),
    UkuleleString(name: 'C', octave: 4, frequency: 261.63),
    UkuleleString(name: 'G', octave: 4, frequency: 392.00),
  ];

  /// 找到离目标频率最近的目标弦
  static UkuleleString? nearestString(double frequency) {
    if (frequency <= 0) return null;
    UkuleleString? nearest;
    double minDiff = double.infinity;
    for (final str in strings) {
      final diff = (frequency - str.frequency).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = str;
      }
    }
    return nearest;
  }
}

/// 单根琴弦定义
class UkuleleString {
  const UkuleleString({
    required this.name,
    required this.octave,
    required this.frequency,
  });

  final String name;
  final int octave;
  final double frequency;

  String get displayName => '$name$octave';
}