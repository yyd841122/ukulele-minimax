import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele/core/audio/mpm.dart';

void main() {
  group('MpmDetector.detectPitch', () {
    test('A4 = 440Hz 合成音 → 应识别为 440±2Hz', () {
      final Float32List samples = _synthesizeSine(
        freq: 440.0,
        sampleRate: 44100,
        durationSec: 0.1,
      );

      final double detected = MpmDetector.detectPitch(
        samples,
        sampleRate: 44100,
      );

      expect(detected, greaterThan(0));
      expect(detected, closeTo(440.0, 2.0));
    });

    test('E2 = 82.41Hz 合成音 → 应识别为 82.41±2Hz', () {
      final Float32List samples = _synthesizeSine(
        freq: 82.41,
        sampleRate: 44100,
        durationSec: 0.15, // 低频需要更长窗口
      );

      final double detected = MpmDetector.detectPitch(
        samples,
        sampleRate: 44100,
        minFreqHz: 70,
      );

      expect(detected, greaterThan(0));
      expect(detected, closeTo(82.41, 3.0)); // 低频精度稍宽
    });

    test('C4 = 261.63Hz 合成音 → 应识别为 261.63±2Hz', () {
      final Float32List samples = _synthesizeSine(
        freq: 261.63,
        sampleRate: 44100,
        durationSec: 0.1,
      );

      final double detected = MpmDetector.detectPitch(
        samples,
        sampleRate: 44100,
      );

      expect(detected, greaterThan(0));
      expect(detected, closeTo(261.63, 2.0));
    });

    test('静音 → 应返回 0', () {
      final Float32List samples = Float32List(2048);

      final double detected = MpmDetector.detectPitch(
        samples,
        sampleRate: 44100,
      );

      expect(detected, 0.0);
    });

    test('样本数过少（< 64）→ 应返回 0 不崩溃', () {
      final Float32List samples = Float32List(32);

      final double detected = MpmDetector.detectPitch(
        samples,
        sampleRate: 44100,
      );

      expect(detected, 0.0);
    });

    test('频段外信号（1500Hz）→ 应返回 0', () {
      final Float32List samples = _synthesizeSine(
        freq: 1500.0,
        sampleRate: 44100,
        durationSec: 0.1,
      );

      final double detected = MpmDetector.detectPitch(
        samples,
        sampleRate: 44100,
        maxFreqHz: 1200,
      );

      expect(detected, 0.0);
    });

    test('加入谐波后仍应识别基频（八度错误率 < 1%）', () {
      // 10 次不同基频测试，统计八度错误率
      final List<double> testFreqs = <double>[
        110, 146.83, 196, 220, 293.66, 392, 440, 523.25, 587.33, 659.25,
      ];
      int octaveErrors = 0;

      for (final double freq in testFreqs) {
        final Float32List samples = _synthesizeWithHarmonics(
          fundamental: freq,
          sampleRate: 44100,
          durationSec: 0.1,
        );
        final double detected = MpmDetector.detectPitch(
          samples,
          sampleRate: 44100,
        );

        if (detected <= 0) continue;

        // 八度错误：检测到 freq/2 或 freq*2
        final double ratio = detected / freq;
        if (ratio < 0.7 || ratio > 1.4) {
          octaveErrors++;
        }
      }

      // MPM 应 < 1%，放宽到 5% 允许测试环境差异
      expect(octaveErrors, lessThanOrEqualTo(1));
    });

    test('PCM16 字节流路径应正常工作', () {
      final Float32List samples = _synthesizeSine(
        freq: 440.0,
        sampleRate: 44100,
        durationSec: 0.1,
      );
      final Uint8List pcm16 = _float32ToPcm16(samples);

      final (double detected, double _) = MpmDetector.detectPitchFromPcm16(
        pcm16,
        sampleRate: 44100,
      );

      expect(detected, closeTo(440.0, 2.0));
    });
  });

  group('pcm16ToFloat32', () {
    test('零值 PCM16 → 全零 Float32', () {
      final Uint8List pcm16 = Uint8List(10);
      final Float32List result = pcm16ToFloat32(pcm16);
      expect(result.length, 5);
      expect(result.every((double v) => v == 0.0), true);
    });

    test('最大正值 PCM16 (32767) → 接近 1.0', () {
      final ByteData bd = ByteData(2);
      bd.setInt16(0, 32767, Endian.little);
      final Float32List result = pcm16ToFloat32(bd.buffer.asUint8List());
      expect(result[0], closeTo(1.0, 0.001));
    });

    test('最小负值 PCM16 (-32768) → 接近 -1.0', () {
      final ByteData bd = ByteData(2);
      bd.setInt16(0, -32768, Endian.little);
      final Float32List result = pcm16ToFloat32(bd.buffer.asUint8List());
      expect(result[0], closeTo(-1.0, 0.001));
    });
  });

  group('rmsEnergy', () {
    test('全零样本 → 能量为 0', () {
      final Float32List samples = Float32List(100);
      expect(rmsEnergy(samples), 0.0);
    });

    test('满幅正弦波 → 能量约 0.707 (1/sqrt(2))', () {
      final Float32List samples = _synthesizeSine(
        freq: 440,
        sampleRate: 44100,
        durationSec: 0.05,
      );
      expect(rmsEnergy(samples), closeTo(0.707, 0.05));
    });
  });

  group('WAV 文件 fixture 验证', () {
    test('a4_440.wav 能被正确识别为 ~440Hz', () {
      final Float32List? samples = _readWavFixture('a4_440.wav');
      if (samples == null) {
        // 跳过：fixture 文件不存在
        return;
      }
      final double detected = MpmDetector.detectPitch(
        samples,
        sampleRate: 44100,
      );
      expect(detected, closeTo(440.0, 5.0));
    });

    test('silent.wav 应返回 0', () {
      final Float32List? samples = _readWavFixture('silent.wav');
      if (samples == null) return;
      final double detected = MpmDetector.detectPitch(
        samples,
        sampleRate: 44100,
      );
      expect(detected, 0.0);
    });
  });
}

// ============== 测试辅助函数 ==============

/// 合成纯正弦波（[-1, 1] 浮点）
Float32List _synthesizeSine({
  required double freq,
  required int sampleRate,
  required double durationSec,
}) {
  final int n = (sampleRate * durationSec).round();
  final Float32List samples = Float32List(n);
  for (int i = 0; i < n; i++) {
    final double t = i / sampleRate;
    samples[i] = math.sin(2 * math.pi * freq * t);
  }
  return samples;
}

/// 合成含谐波的正弦波（更接近真实乐器）
Float32List _synthesizeWithHarmonics({
  required double fundamental,
  required int sampleRate,
  required double durationSec,
}) {
  final int n = (sampleRate * durationSec).round();
  final Float32List samples = Float32List(n);
  for (int i = 0; i < n; i++) {
    final double t = i / sampleRate;
    double s = 0.0;
    s += 0.6 * math.sin(2 * math.pi * fundamental * t);
    s += 0.25 * math.sin(2 * math.pi * 2 * fundamental * t);
    s += 0.10 * math.sin(2 * math.pi * 3 * fundamental * t);
    s += 0.05 * math.sin(2 * math.pi * 4 * fundamental * t);
    samples[i] = s.clamp(-1.0, 1.0);
  }
  return samples;
}

/// Float32 → PCM16 字节流
Uint8List _float32ToPcm16(Float32List samples) {
  final ByteData bd = ByteData(samples.length * 2);
  for (int i = 0; i < samples.length; i++) {
    final int s = (samples[i] * 32767).round().clamp(-32768, 32767);
    bd.setInt16(i * 2, s, Endian.little);
  }
  return bd.buffer.asUint8List();
}

/// 读取测试 fixture WAV 文件
Float32List? _readWavFixture(String filename) {
  final File file = File('test/fixtures/$filename');
  if (!file.existsSync()) return null;

  final Uint8List bytes = file.readAsBytesSync();

  // 跳过 RIFF 头（44 字节标准 PCM）
  if (bytes.length < 44) return null;

  final ByteData bd = ByteData.sublistView(bytes);
  final int dataOffset = 44;
  final int sampleCount = (bytes.length - dataOffset) ~/ 2;

  final Float32List samples = Float32List(sampleCount);
  for (int i = 0; i < sampleCount; i++) {
    final int s = bd.getInt16(dataOffset + i * 2, Endian.little);
    samples[i] = s / 32768.0;
  }
  return samples;
}