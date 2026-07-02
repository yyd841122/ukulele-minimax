import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';

import '../sheets/data/sheet_model.dart';
import '../score_report/score_report_page.dart';
import 'practice_cubit.dart';
import 'chord_chart.dart';

/// 智能陪练页面
class PracticePage extends StatelessWidget {
  const PracticePage({
    super.key,
    required this.sheet,
    this.mode = PracticeMode.guide,
  });
  final Sheet sheet;
  final PracticeMode mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('练习 - ${sheet.title}')),
      body: BlocProvider<PracticeCubit>(
        create: (_) =>
            PracticeCubit(initialSheet: sheet, initialMode: mode),
        child: const _PracticeView(),
      ),
    );
  }
}

class _PracticeView extends StatelessWidget {
  const _PracticeView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PracticeCubit, PracticeState>(
      listener: (BuildContext context, PracticeState state) {
        if (state.status == PracticeStatus.failed && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.status == PracticeStatus.finished &&
            state.sheet != null &&
            state.recordedBytes.isNotEmpty) {
          final Uint8List wav = context.read<PracticeCubit>().getRecordedWav();
          final suggestions = state.suggestions;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ScoreReportPage(
                sheet: state.sheet!,
                audioBytes: wav,
                localSuggestions: suggestions,
              ),
            ),
          );
        }
      },
      builder: (BuildContext context, PracticeState state) {
        final bool isFree = state.mode == PracticeMode.free;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 4),
                // 状态条（极紧凑）
                _StatusBar(state: state),

                // 模式 chip + 曲谱条
                _ModeChipRow(state: state),
                if (!isFree)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _SheetChordStrip(state: state),
                  ),

                // 主区：当前期望 + 指板（自然高度，不撑爆，留白给屏幕背景）
                _CurrentChordBig(state: state),

                // 检测反馈条（极紧凑）
                _DetectionStrip(state: state),

                // 控制按钮（固定底部）
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _ControlButtons(state: state),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============== 模式 chip 行 ==============
class _ModeChipRow extends StatelessWidget {
  const _ModeChipRow({required this.state});
  final PracticeState state;

  String _label(PracticeMode m) {
    switch (m) {
      case PracticeMode.guide:
        return '跟弹';
      case PracticeMode.sing:
        return '唱弹';
      case PracticeMode.free:
        return '自由';
    }
  }

  Color _color(PracticeMode m, BuildContext context) {
    final bool active = m == state.mode;
    if (!active) return Colors.grey.shade200;
    switch (m) {
      case PracticeMode.guide:
        return Theme.of(context).colorScheme.primary;
      case PracticeMode.sing:
        return Colors.teal.shade600;
      case PracticeMode.free:
        return Colors.deepPurple.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final m in PracticeMode.values) ...<Widget>[
            ChoiceChip(
              label: Text(_label(m)),
              selected: m == state.mode,
              selectedColor: _color(m, context),
              backgroundColor: _color(m, context),
              labelStyle: TextStyle(
                color: m == state.mode ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              onSelected: state.status == PracticeStatus.playing
                  ? null
                  : (bool sel) {
                      if (sel && state.sheet != null) {
                        context
                            .read<PracticeCubit>()
                            .startPractice(state.sheet!, mode: m);
                      }
                    },
            ),
            if (m != PracticeMode.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ============== 顶部状态条 ==============
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state});
  final PracticeState state;

  @override
  Widget build(BuildContext context) {
    final String statusText = switch (state.status) {
      PracticeStatus.idle => '准备开始',
      PracticeStatus.loading => '加载中...',
      PracticeStatus.countdown => '3 秒倒计时...',
      PracticeStatus.playing => '● 录制中',
      PracticeStatus.paused => '⏸ 已暂停',
      PracticeStatus.finished => '✓ 已完成',
      PracticeStatus.failed => '✗ 出错了',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(statusText, style: Theme.of(context).textTheme.bodyMedium),
              if (state.sheet != null)
                Text(
                  'BPM ${state.sheet!.bpm} · ${state.sheet!.durationLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          // 单音提示行（如果有单音指法）
          if (_isSingleNote(state.expectedChord) &&
              _singleNoteHint(state.expectedChord) != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: <Widget>[
                  Icon(Icons.music_note, size: 12, color: Colors.teal.shade700),
                  const SizedBox(width: 4),
                  Text(
                    _singleNoteHint(state.expectedChord)!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.teal.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isSingleNote(String chord) {
    if (chord.isEmpty) return false;
    final String root = chord[0];
    if (!RegExp(r'^[A-G]$').hasMatch(root)) return false;
    if (chord.length == 1) return true;
    return false;
  }

  /// 单音的简短提示（"1弦 A 弦 3 品"）
  String? _singleNoteHint(String chord) {
    const Map<String, String> hints = <String, String>{
      'C': '弹 C4（1弦 A 弦 3 品，无名指）',
      'D': '弹 D4（2弦 E 弦 2 品，中指）',
      'E': '弹 E4（2弦 E 弦空弦）',
      'F': '弹 F4（4弦 G 弦 1 品，食指）',
      'G': '弹 G4（4弦 G 弦空弦）',
      'A': '弹 A4（1弦 A 弦空弦）',
      'B': '弹 B4（4弦 G 弦 2 品，中指）',
    };
    return hints[chord];
  }
}

// ============== 完整曲谱条（水平滚动，当前高亮）==============
class _SheetChordStrip extends StatelessWidget {
  const _SheetChordStrip({required this.state});
  final PracticeState state;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> chords =
        state.sheet?.chords ?? <Map<String, dynamic>>[];
    if (chords.isEmpty) {
      return const SizedBox.shrink();
    }

    // 当和弦数 ≤ 8 时整体居中显示；超过 8 才左右滚动
    if (chords.length <= 8) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < chords.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 6),
                _chordChip(context, i, chords[i]),
              ],
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chords.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int i) {
          return _chordChip(context, i, chords[i]);
        },
      ),
    );
  }

  Widget _chordChip(BuildContext context, int i, Map<String, dynamic> chordData) {
    final bool isCurrent = i == state.expectedIndex;
    final bool isPast = i < state.expectedIndex;
    final String chord = chordData['chord'] as String? ?? '-';
    final int beats = chordData['beats'] as int? ?? 2;
    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: isCurrent
            ? Theme.of(context).colorScheme.primary
            : isPast
                ? Colors.grey.shade300
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: isCurrent
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            chord,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isCurrent ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            '${beats}拍',
            style: TextStyle(
              fontSize: 10,
              color: isCurrent
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============== 主区：当前期望（区分单音/和弦 + 按键图）==============

/// 判断 expectedChord 是单音还是和弦（仅用于 UI 颜色差异）
/// - 跟弹页的 chord 字段全部是和弦（C / F / G7 / Am）
/// - UI 上"单音/和弦"标签按命名风格展示：
///   长度 1（裸音名 C/D/E/F/G/A/B）显示"单音"，长度 ≥ 2（Am/G7/Cmaj7）显示"和弦"
/// - 但 ChordChart 内部永远按和弦渲染（4 根弦都参与）
bool _isSingleNoteStyle(String chord) {
  if (chord.isEmpty) return false;
  final String root = chord[0];
  if (!RegExp(r'^[A-G]$').hasMatch(root)) return false;
  return chord.length == 1;
}

class _CurrentChordBig extends StatelessWidget {
  const _CurrentChordBig({required this.state});
  final PracticeState state;

  @override
  Widget build(BuildContext context) {
    final String chord = state.expectedChord;

    // 自由模式：只显示大字"自由练习" + 实时时长
    if (state.mode == PracticeMode.free) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF7E57C2), Color(0xFF9575CD)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: <Widget>[
                  Icon(Icons.mic, size: 56, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    '自由练习',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '跟着感觉弹，无目标',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '已练习 ${state.elapsedSeconds}s',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final bool isSingleStyle = _isSingleNoteStyle(chord);
    final Color color = isSingleStyle
        ? Colors.teal.shade600
        : Theme.of(context).colorScheme.primary;
    final String modeLabel = state.mode == PracticeMode.sing ? '唱弹' : '和弦';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 顶部：和弦名 + 单音/和弦 label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                state.mode == PracticeMode.sing
                    ? Icons.mic
                    : (isSingleStyle ? Icons.music_note : Icons.queue_music),
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                chord,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                state.mode == PracticeMode.sing
                    ? modeLabel
                    : (isSingleStyle ? '单音' : '和弦'),
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // 简谱（如果有）
          if (state.sheet != null && state.sheet!.notesSimplified != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: _SimplifiedNotationPreview(
                state: state,
                isSingle: isSingleStyle,
              ),
            ),
          // 唱弹模式不显示指板
          if (state.mode != PracticeMode.sing)
            ChordChart(chord: chord, isSingle: false)
          else
            _SingHint(state: state),
        ],
      ),
    );
  }
}

/// 唱弹模式：显示目标音名 + 命中提示
class _SingHint extends StatelessWidget {
  const _SingHint({required this.state});
  final PracticeState state;

  @override
  Widget build(BuildContext context) {
    final bool isHit = state.isHit;
    final bool hasSignal = state.detectedFrequency > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHit ? Colors.green.shade50 : Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHit ? Colors.green.shade300 : Colors.teal.shade200,
              ),
            ),
            child: Column(
              children: <Widget>[
                const Icon(Icons.mic_external_on, size: 36, color: Colors.teal),
                const SizedBox(height: 6),
                Text(
                  hasSignal
                      ? (isHit ? '✓ 命中目标' : '↻ 继续找音准')
                      : '请唱或哼出当前旋律音',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isHit ? Colors.green.shade700 : Colors.teal.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '目标: ${state.expectedChord} · 实际: ${state.detectedNote}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============== 简谱预览（高亮当前位置）==============
class _SimplifiedNotationPreview extends StatelessWidget {
  const _SimplifiedNotationPreview({
    required this.state,
    required this.isSingle,
  });
  final PracticeState state;
  final bool isSingle;

  @override
  Widget build(BuildContext context) {
    final String notes = state.sheet!.notesSimplified!;
    // 解析所有"音"（非空格字符），算总音符数
    final List<String> tokens = notes.split(RegExp(r'\s+'));
    // 简化：当前 expectedIndex 模 tokens.length
    final int currentTokenIndex = state.expectedIndex % tokens.length;
    final int contextBefore = 4;
    final int contextAfter = 4;
    final int start =
        (currentTokenIndex - contextBefore).clamp(0, tokens.length - 1);
    final int end =
        (currentTokenIndex + contextAfter).clamp(0, tokens.length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        children: <Widget>[
          for (int i = start; i < end; i++) ...<Widget>[
            if (i > start)
              const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: i == currentTokenIndex
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tokens[i],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                  fontWeight: i == currentTokenIndex
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: i == currentTokenIndex
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============== 实时检测条（紧凑单行 + 进度）==============
class _DetectionStrip extends StatelessWidget {
  const _DetectionStrip({required this.state});
  final PracticeState state;

  @override
  Widget build(BuildContext context) {
    final int total = state.sheet?.chords.length ?? 1;
    final int current = state.expectedIndex + 1;
    final double progress = current / total;

    // 错音标红（detectedNote 列）
    final bool isMistake = state.isMistake && state.detectedFrequency > 0;
    final bool isHit = state.isHit;

    // 命中率文本
    final int hitTotal = state.hitCount + state.missCount;
    final String hitRateText = hitTotal == 0
        ? '-'
        : '${(state.hitCount / hitTotal * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _DetectionItem(
                  label: '音',
                  value: state.detectedNote,
                  isMistake: isMistake,
                  isHit: isHit,
                ),
              ),
              Expanded(
                child: _DetectionItem(
                  label: '频率',
                  value: state.detectedFrequency > 0
                      ? '${state.detectedFrequency.toStringAsFixed(0)}Hz'
                      : '-',
                ),
              ),
              Expanded(
                child: _DetectionItem(
                  label: '偏差',
                  value: state.detectedFrequency > 0
                      ? '${state.centsOffset > 0 ? '+' : ''}${state.centsOffset}¢'
                      : '-',
                  color: _centsColor(state.centsOffset),
                ),
              ),
              Expanded(
                child: _DetectionItem(
                  label: '命中',
                  value: hitRateText,
                  color: hitTotal > 0 && state.hitCount / hitTotal >= 0.75
                      ? Colors.green
                      : (hitTotal > 0 ? Colors.orange : null),
                ),
              ),
              Expanded(
                child: _DetectionItem(
                  label: '进度',
                  value: '$current/$total',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 3),
        ],
      ),
    );
  }

  Color _centsColor(int cents) {
    if (cents.abs() <= 10) return Colors.green;
    if (cents < 0) return Colors.blue;
    return Colors.orange;
  }
}

class _DetectionItem extends StatelessWidget {
  const _DetectionItem({
    required this.label,
    required this.value,
    this.color,
    this.isMistake = false,
    this.isHit = false,
  });
  final String label;
  final String value;
  final Color? color;
  final bool isMistake;
  final bool isHit;

  @override
  Widget build(BuildContext context) {
    Color effective = color ?? Colors.black87;
    if (isMistake) effective = Colors.red.shade700;
    if (isHit) effective = Colors.green.shade700;

    return Column(
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 2),
        Container(
          padding: isMistake
              ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
              : EdgeInsets.zero,
          decoration: isMistake
              ? BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade300, width: 1),
                )
              : null,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: effective,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============== 控制按钮 ==============
class _ControlButtons extends StatelessWidget {
  const _ControlButtons({required this.state});
  final PracticeState state;

  @override
  Widget build(BuildContext context) {
    final PracticeCubit cubit = context.read<PracticeCubit>();
    final Sheet? sheet = state.sheet;

    switch (state.status) {
      case PracticeStatus.idle:
      case PracticeStatus.failed:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: sheet == null
                ? null
                : () => cubit.startPractice(sheet),
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始练习'),
          ),
        );
      case PracticeStatus.loading:
      case PracticeStatus.countdown:
        return const SizedBox(
          width: double.infinity,
          height: 56,
          child: Center(child: CircularProgressIndicator()),
        );
      case PracticeStatus.playing:
      case PracticeStatus.paused:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.status == PracticeStatus.playing
                    ? cubit.pause
                    : cubit.resume,
                icon: Icon(
                  state.status == PracticeStatus.paused
                      ? Icons.play_arrow
                      : Icons.pause,
                ),
                label: Text(
                  state.status == PracticeStatus.paused ? '继续' : '暂停',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: cubit.nextBeat,
                icon: const Icon(Icons.skip_next),
                label: const Text('下一拍'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: cubit.stop,
                icon: const Icon(Icons.stop),
                label: const Text('结束'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        );
      case PracticeStatus.finished:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('返回'),
          ),
        );
    }
  }
}