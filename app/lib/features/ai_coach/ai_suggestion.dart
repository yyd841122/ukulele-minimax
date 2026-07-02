/// AI 智能建议（M05 MVP）
///
/// 输入：本次练习的 cents 偏差序列 + 命中率 + 时长
/// 输出：3 条建议文本（音准/节奏/速度/指法）
///
/// 纯本地 mock，不调用后端、不联网
library;

import 'dart:math' as math;

/// 单条 AI 建议
class AiSuggestion {
  const AiSuggestion({
    required this.category,
    required this.title,
    required this.detail,
    required this.severity,
  });

  /// 类别：音准 / 节奏 / 速度 / 指法 / 鼓励
  final String category;

  /// 标题（粗体）
  final String title;

  /// 详情（说明）
  final String detail;

  /// 严重度：0=鼓励 / 1=提示 / 2=警告
  final int severity;
}

/// 输入数据
class AiAnalysisInput {
  const AiAnalysisInput({
    required this.centsHistory,
    required this.hitCount,
    required this.missCount,
    required this.durationSeconds,
    required this.expectedChordCount,
  });

  /// cents 偏差序列（绝对值）
  final List<int> centsHistory;

  /// 命中次数（cents.abs() ≤ 20）
  final int hitCount;

  /// 未命中次数
  final int missCount;

  /// 录音时长（秒）
  final int durationSeconds;

  /// 期望总拍数（hitCount + missCount + skipped）
  final int expectedChordCount;

  double get hitRate {
    final total = hitCount + missCount;
    if (total == 0) return 0;
    return hitCount / total;
  }

  /// cents 大偏差占比（>30 cents）
  double get bigCentsRatio {
    if (centsHistory.isEmpty) return 0;
    final big = centsHistory.where((c) => c.abs() > 30).length;
    return big / centsHistory.length;
  }

  /// cents 平均偏差
  double get avgCents {
    if (centsHistory.isEmpty) return 0;
    final sum = centsHistory.fold<int>(0, (s, c) => s + c.abs());
    return sum / centsHistory.length;
  }
}

/// AI 建议生成器（基于规则的 mock）
class AiSuggestionEngine {
  static List<AiSuggestion> generate(AiAnalysisInput input) {
    final List<AiSuggestion> result = <AiSuggestion>[];

    // 1. 鼓励 / 总结（始终第 1 条）
    result.add(_summary(input));

    // 2. 音准分析
    if (input.centsHistory.isNotEmpty) {
      if (input.bigCentsRatio > 0.4) {
        result.add(const AiSuggestion(
          category: '音准',
          title: '音准波动较大',
          detail: '超过 40% 的音 cents 偏差 > 30，建议先练单音校准',
          severity: 2,
        ));
      } else if (input.avgCents > 15) {
        result.add(const AiSuggestion(
          category: '音准',
          title: '音准基本稳定',
          detail: '平均 cents 偏差在 15 左右，可以尝试复杂和弦',
          severity: 1,
        ));
      } else {
        result.add(const AiSuggestion(
          category: '音准',
          title: '音准优秀',
          detail: '平均 cents < 15，继续保持',
          severity: 0,
        ));
      }
    }

    // 3. 命中率分析
    if (input.hitCount + input.missCount > 0) {
      if (input.hitRate < 0.5) {
        result.add(const AiSuggestion(
          category: '指法',
          title: '命中率偏低',
          detail: '命中率不足 50%，检查指法图，重按和弦再试',
          severity: 2,
        ));
      } else if (input.hitRate < 0.75) {
        result.add(const AiSuggestion(
          category: '指法',
          title: '指法尚可',
          detail: '命中率 50%-75%，可加强换和弦的速度练习',
          severity: 1,
        ));
      }
    }

    // 4. 节奏分析（基于时长 vs 期望时长）
    if (input.durationSeconds > 0 && input.expectedChordCount > 0) {
      final double secPerBeat = input.durationSeconds / input.expectedChordCount;
      if (secPerBeat > 3.0) {
        result.add(const AiSuggestion(
          category: '节奏',
          title: '节奏偏慢',
          detail: '平均每拍超过 3 秒，试试用节拍器辅助',
          severity: 1,
        ));
      } else if (secPerBeat < 0.5) {
        result.add(const AiSuggestion(
          category: '节奏',
          title: '节奏偏快',
          detail: '平均每拍不足 0.5 秒，可能漏拍，建议放慢',
          severity: 2,
        ));
      }
    }

    // 5. 时长分析
    if (input.durationSeconds < 5 && input.expectedChordCount > 0) {
      result.add(const AiSuggestion(
        category: '建议',
        title: '练习时长太短',
        detail: '录音不足 5 秒，建议至少练满 30 秒再评分',
        severity: 1,
      ));
    }

    // 6. 乐观鼓励（命中率高 + 音准好 时追加）
    if (input.hitRate >= 0.85 && input.avgCents < 15) {
      result.add(const AiSuggestion(
        category: '鼓励',
        title: '表现出色',
        detail: '可以挑战更高难度的曲目了',
        severity: 0,
      ));
    }

    return result;
  }

  static AiSuggestion _summary(AiAnalysisInput input) {
    final double hitRate = input.hitRate * 100;
    final double avgC = input.avgCents;
    final String text = hitRate == 0
        ? '本次练习暂无有效数据'
        : '命中 ${hitRate.toStringAsFixed(0)}% · 平均偏差 ${avgC.toStringAsFixed(1)} cents · 时长 ${input.durationSeconds}s';

    return AiSuggestion(
      category: '总结',
      title: '本次练习',
      detail: text,
      severity: 0,
    );
  }

  /// 选 1 条最重要建议作为"快速建议"（用于实时显示）
  static AiSuggestion? pickPrimary(List<AiSuggestion> all) {
    if (all.isEmpty) return null;
    // 优先 severity=2，其次=1，最后=0
    final List<AiSuggestion> sorted = List<AiSuggestion>.from(all)
      ..sort((a, b) => b.severity.compareTo(a.severity));
    // 跳过总结类
    for (final s in sorted) {
      if (s.category != '总结') return s;
    }
    return sorted.first;
  }

  // 保留 math 导入备用（暂时不用，但方便后续扩展）
  // ignore: unused_field
  static final math.Random _rnd = math.Random();
}