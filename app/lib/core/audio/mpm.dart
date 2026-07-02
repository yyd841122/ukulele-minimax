import 'dart:math' as math;
import 'dart:typed_data';

/// MPM = McLeod Pitch Method
///
/// 参考论文：McLeod & Wyvill (2005)
/// "A Smarter Way To Find Pitch" (ICMC)
///
/// 核心思想：
/// 1. 计算归一化平方差函数（NSDF），而非简单的自相关
/// 2. 在 NSDF 上找最大峰（而非 YIN 的最小值）
/// 3. 对峰附近做抛物线插值，提升精度
///
/// 优势（相对 YIN）：
/// - 八度错误率显著降低（< 1% vs YIN 5-10%）
/// - 主峰更锐利，置信度判断更可靠
/// - 特别适合拨弦类乐器（瞬态强 + 谐波丰富）
class MpmDetector {
  MpmDetector._();

  /// 检测 PCM 音频样本中的基频
  ///
  /// [samples] 单声道 PCM 浮点数组，范围 [-1, 1]
  /// [sampleRate] 采样率（Hz）
  /// [minFreqHz] 最低可检测频率（默认 70 Hz）
  /// [maxFreqHz] 最高可检测频率（默认 1200 Hz）
  /// [clarityThreshold] NSDF 主峰锐度阈值（0-1）
  ///
  /// 返回：基频（Hz）；失败返回 0.0
  ///
  /// 算法：McLeod Pitch Method (MPM, 2005)
  /// 关键步骤：
  /// 1. 计算 NSDF 曲线
  /// 2. 找 K 切点：NSDF 第一次降到 0 之后再次降到 0 的位置
  ///    （MPM 论文的 cut-off: "position of the first positive peak after τ=0"）
  /// 3. 在 [minTau, K] 范围内找最大峰
  /// 4. 抛物线插值修正
  static double detectPitch(
    Float32List samples, {
    required int sampleRate,
    int minFreqHz = 70,
    int maxFreqHz = 1200,
    double clarityThreshold = 0.5,
  }) {
    final (double freq, double _) = detectPitchWithClarity(
      samples,
      sampleRate: sampleRate,
      minFreqHz: minFreqHz,
      maxFreqHz: maxFreqHz,
      clarityThreshold: clarityThreshold,
    );
    return freq;
  }

  /// 计算指定 tau 的 NSDF 值
  ///
  /// NSDF(tau) = 2 * sum(x[i] * x[i+tau]) / (sum(x[i]^2) + sum(x[i+tau]^2))
  ///
  /// 范围 [-1, 1]，1 表示完全周期相关，0 表示无关，-1 表示反相
  static double _nsdfAt(Float32List samples, int tau) {
    final int n = samples.length - tau;
    double numerator = 0.0;
    double energyLeft = 0.0;
    double energyRight = 0.0;

    for (int i = 0; i < n; i++) {
      final double left = samples[i];
      final double right = samples[i + tau];
      numerator += left * right;
      energyLeft += left * left;
      energyRight += right * right;
    }

    final double denominator = energyLeft + energyRight;
    if (denominator < 1e-10) return 0.0;

    return 2.0 * numerator / denominator;
  }

  /// 便捷方法：直接从 PCM16 字节流检测音高
  ///
  /// 用于 Flutter record 包（PCM16bits 编码）
  /// 返回 (频率 Hz, 置信度 0-1)。失败时频率 = 0
  static (double, double) detectPitchFromPcm16(
    Uint8List pcm16, {
    required int sampleRate,
    int minFreqHz = 70,
    int maxFreqHz = 1200,
    double clarityThreshold = 0.5,
  }) {
    final Float32List samples = pcm16ToFloat32(pcm16);
    return detectPitchWithClarity(
      samples,
      sampleRate: sampleRate,
      minFreqHz: minFreqHz,
      maxFreqHz: maxFreqHz,
      clarityThreshold: clarityThreshold,
    );
  }

  /// 返回 (频率 Hz, NSDF 主峰锐度 0-1)
  /// 失败时频率 = 0, clarity = 0
  static (double, double) detectPitchWithClarity(
    Float32List samples, {
    required int sampleRate,
    int minFreqHz = 70,
    int maxFreqHz = 1200,
    double clarityThreshold = 0.5,
  }) {
    if (samples.length < 128) return (0, 0);

    final int minTau = (sampleRate / maxFreqHz).floor();
    final int maxTau = (sampleRate / minFreqHz).ceil();
    final int maxTauCapped = maxTau < samples.length
        ? maxTau
        : samples.length - 1;

    if (minTau >= maxTauCapped) return (0, 0);

    // 1. 计算 NSDF 曲线
    final int n = maxTauCapped + 1;
    final Float64List nsdf = Float64List(n);
    for (int tau = 0; tau < n; tau++) {
      nsdf[tau] = _nsdfAt(samples, tau);
    }

    // 2. 找 K 切点：NSDF 第一次从负值回到 0 之后再次下穿 0
    int kCutoff = maxTauCapped;
    int signChanges = 0;
    double prev = nsdf[0];
    for (int tau = 1; tau <= maxTauCapped; tau++) {
      final double curr = nsdf[tau];
      if (prev > 0 && curr <= 0) {
        signChanges++;
        if (signChanges >= 2) {
          kCutoff = tau;
          break;
        }
      }
      prev = curr;
    }

    // 3. 在 [minTau, K] 范围内找 NSDF 最大峰
    final int searchEnd = kCutoff < minTau ? minTau : kCutoff;
    int bestTau = minTau;
    double bestValue = nsdf[minTau];
    for (int tau = minTau + 1; tau <= searchEnd; tau++) {
      if (nsdf[tau] > bestValue) {
        bestValue = nsdf[tau];
        bestTau = tau;
      }
    }

    if (bestValue < clarityThreshold) return (0, bestValue);

    // 4. 抛物线插值
    double refinedTau = bestTau.toDouble();
    if (bestTau > minTau && bestTau < searchEnd) {
      final double y0 = nsdf[bestTau - 1];
      final double y1 = nsdf[bestTau];
      final double y2 = nsdf[bestTau + 1];
      final double denom = y0 - 2 * y1 + y2;
      if (denom.abs() >= 1e-10) {
        final double shift = (0.5 * (y0 - y2) / denom).clamp(-1.0, 1.0);
        refinedTau = bestTau + shift;
      }
    }

    return (sampleRate / refinedTau, bestValue);
  }
}

/// PCM16 (Int16) → Float32 转换
///
/// record 包默认输出 PCM16bits（小端有符号 16-bit）
Float32List pcm16ToFloat32(Uint8List pcm16) {
  final int n = pcm16.length ~/ 2;
  final Float32List result = Float32List(n);
  final ByteData bd = ByteData.sublistView(pcm16);

  for (int i = 0; i < n; i++) {
    final int sample = bd.getInt16(i * 2, Endian.little);
    result[i] = sample / 32768.0;
  }
  return result;
}

/// 计算音频 RMS 能量（用于静音检测）
double rmsEnergy(Float32List samples) {
  if (samples.isEmpty) return 0.0;
  double sum = 0.0;
  for (final double s in samples) {
    sum += s * s;
  }
  return math.sqrt(sum / samples.length);
}