import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tuner_cubit.dart';
import 'domain/music_note.dart';

/// 调音器页面
class TunerPage extends StatelessWidget {
  const TunerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调音器'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: '使用说明',
          ),
        ],
      ),
      body: BlocProvider<TunerCubit>(
        create: (_) => TunerCubit(),
        child: const _TunerView(),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('调音器使用说明'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('1. 点击开始按钮，授予麦克风权限'),
              SizedBox(height: 8),
              Text('2. 将手机/麦克风靠近琴弦'),
              SizedBox(height: 8),
              Text('3. 拨动单根琴弦，观察音名与偏差'),
              SizedBox(height: 8),
              Text('4. 偏差 < 5¢ 为音准合格'),
              SizedBox(height: 8),
              Text('5. 偏高（#）放松弦，偏低（b）拧紧'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

class _TunerView extends StatelessWidget {
  const _TunerView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TunerCubit, TunerState>(
      listener: (BuildContext context, TunerState state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (BuildContext context, TunerState state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Expanded(child: _NoteDisplay(state: state)),
                const SizedBox(height: 16),
                _StringPicker(
                  current: state.targetString,
                  onSelect: (str) =>
                      context.read<TunerCubit>().selectTargetString(str),
                ),
                const SizedBox(height: 16),
                _ControlButton(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NoteDisplay extends StatelessWidget {
  const _NoteDisplay({required this.state});
  final TunerState state;

  @override
  Widget build(BuildContext context) {
    final MusicNote? note = state.detectedNote;
    final Color color = _tunerColor(context, note);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              note?.displayName ?? '—',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (note != null && note.frequency > 0)
              Text(
                '${note.frequency.toStringAsFixed(1)} Hz',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            const SizedBox(height: 24),
            _CentsBar(cents: note?.cents ?? 0),
            const SizedBox(height: 12),
            Text(
              _statusText(note),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tunerColor(BuildContext context, MusicNote? note) {
    final scheme = Theme.of(context).colorScheme;
    if (note == null || note.frequency <= 0) return scheme.outline;
    if (note.isInTune) return Colors.green;
    if (note.isFlat) return Colors.blue;
    return Colors.orange;
  }

  String _statusText(MusicNote? note) {
    if (note == null || note.frequency <= 0) {
      return '请拨动琴弦开始调音';
    }
    if (note.isInTune) return '✓ 音准合格';
    if (note.isFlat) return 'b 偏低 ${note.cents.abs()} cents';
    return '# 偏高 ${note.cents.abs()} cents';
  }
}

/// Cents 偏差条：[-50, +50]，0 为中心
class _CentsBar extends StatelessWidget {
  const _CentsBar({required this.cents});
  final int cents;

  @override
  Widget build(BuildContext context) {
    const double maxCents = 50.0;
    final double ratio = (cents.clamp(-50, 50) / maxCents + 1) / 2;

    return Column(
      children: <Widget>[
        SizedBox(
          height: 24,
          child: Stack(
            children: <Widget>[
              // 背景
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // 渐变指示：左侧蓝（偏低），右侧红（偏高）
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.blue.shade300,
                      Colors.green.shade300,
                      Colors.orange.shade300,
                    ],
                    stops: const <double>[0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // 指针
              Align(
                alignment: Alignment(-1 + 2 * ratio, 0),
                child: Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // 中心标线
              const Center(
                child: SizedBox(
                  width: 2,
                  child: VerticalDivider(color: Colors.black54, width: 2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const <Widget>[
            Text('-50', style: TextStyle(fontSize: 12)),
            Text('0', style: TextStyle(fontSize: 12)),
            Text('+50', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _StringPicker extends StatelessWidget {
  const _StringPicker({required this.current, required this.onSelect});
  final UkuleleString? current;
  final ValueChanged<UkuleleString?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: UkuleleStandardTuning.strings.map((str) {
            final bool selected = current?.displayName == str.displayName;
            return ChoiceChip(
              label: Text(str.displayName),
              selected: selected,
              onSelected: (_) => onSelect(str),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.state});
  final TunerState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          final cubit = context.read<TunerCubit>();
          if (state.isRecording) {
            await cubit.stop();
          } else {
            await cubit.start();
          }
        },
        icon: Icon(
          state.isRecording ? Icons.stop : Icons.mic,
        ),
        label: Text(state.isRecording ? '停止' : '开始'),
      ),
    );
  }
}