import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import 'click_player.dart';

/// 节拍器状态
class MetronomeState {
  const MetronomeState({
    required this.bpm,
    required this.beatsPerMeasure,
    required this.isRunning,
    required this.currentBeat,
  });

  factory MetronomeState.initial() => const MetronomeState(
    bpm: 80,
    beatsPerMeasure: 4,
    isRunning: false,
    currentBeat: 0,
  );

  final int bpm; // 40-240
  final int beatsPerMeasure; // 1-12
  final bool isRunning;
  final int currentBeat; // 0..beatsPerMeasure-1，第几拍

  MetronomeState copyWith({
    int? bpm,
    int? beatsPerMeasure,
    bool? isRunning,
    int? currentBeat,
  }) {
    return MetronomeState(
      bpm: bpm ?? this.bpm,
      beatsPerMeasure: beatsPerMeasure ?? this.beatsPerMeasure,
      isRunning: isRunning ?? this.isRunning,
      currentBeat: currentBeat ?? this.currentBeat,
    );
  }
}

/// 节拍器 Cubit
class MetronomeCubit extends Cubit<MetronomeState> {
  MetronomeCubit({MetronomeClickPlayer? clickPlayer})
      : _clickPlayer = clickPlayer ?? MetronomeClickPlayer(),
        super(MetronomeState.initial());

  final MetronomeClickPlayer _clickPlayer;
  Timer? _timer;

  /// 播放节拍音
  /// accent=true: 首拍重音；accent=false: 普通拍
  Future<void> _playClick({required bool accent}) async {
    if (accent) {
      await _clickPlayer.playAccent();
    } else {
      await _clickPlayer.playNormal();
    }
  }

  /// 设置 BPM
  void setBpm(int bpm) {
    final int clamped = bpm.clamp(40, 240);
    emit(state.copyWith(bpm: clamped));
    if (state.isRunning) {
      _restart();
    }
  }

  /// 设置每节拍数
  void setBeatsPerMeasure(int n) {
    final int clamped = n.clamp(1, 12);
    emit(state.copyWith(beatsPerMeasure: clamped));
    if (state.isRunning) {
      _restart();
    }
  }

  /// 启动节拍器
  Future<void> start() async {
    if (state.isRunning) return;
    await _clickPlayer.preload();
    emit(state.copyWith(isRunning: true, currentBeat: 0));
    // 立即播放首拍重音（不等第一个 tick）
    await _playClick(accent: true);
    _scheduleNext();
  }

  /// 停止
  void stop() {
    _timer?.cancel();
    _timer = null;
    emit(state.copyWith(isRunning: false, currentBeat: 0));
  }

  void _restart() {
    _timer?.cancel();
    if (state.isRunning) _scheduleNext();
  }

  void _scheduleNext() {
    final int intervalMs = (60000 / state.bpm).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (Timer t) async {
      final next = state.currentBeat + 1;
      final wrapped = next >= state.beatsPerMeasure ? 0 : next;
      emit(state.copyWith(currentBeat: wrapped));
      await _playClick(accent: wrapped == 0);
    });
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _clickPlayer.dispose();
    return super.close();
  }
}

/// 节拍器页面
class MetronomePage extends StatelessWidget {
  const MetronomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('节拍器')),
      body: BlocProvider<MetronomeCubit>(
        create: (_) => MetronomeCubit(),
        child: const _MetronomeView(),
      ),
    );
  }
}

class _MetronomeView extends StatelessWidget {
  const _MetronomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetronomeCubit, MetronomeState>(
      builder: (BuildContext context, MetronomeState state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Expanded(child: _BpmDisplay(state: state)),
                _BpmSlider(
                  bpm: state.bpm,
                  onChanged: (v) => context.read<MetronomeCubit>().setBpm(v),
                ),
                _BeatPicker(
                  n: state.beatsPerMeasure,
                  onChanged: (v) =>
                      context.read<MetronomeCubit>().setBeatsPerMeasure(v),
                ),
                const SizedBox(height: 16),
                _ControlRow(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BpmDisplay extends StatelessWidget {
  const _BpmDisplay({required this.state});
  final MetronomeState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '${state.bpm}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'BPM  (${state.beatsPerMeasure}/4 拍)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _BeatLights(
              total: state.beatsPerMeasure,
              current: state.currentBeat,
              running: state.isRunning,
            ),
          ],
        ),
      ),
    );
  }
}

class _BeatLights extends StatelessWidget {
  const _BeatLights({
    required this.total,
    required this.current,
    required this.running,
  });

  final int total;
  final int current;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(total, (i) {
        final bool isOn = running && i == current;
        final bool isFirst = i == 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn
                  ? (isFirst ? Colors.red : Colors.green)
                  : Colors.grey.shade300,
              boxShadow: isOn
                  ? <BoxShadow>[
                      BoxShadow(
                        color: (isFirst ? Colors.red : Colors.green)
                            .withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _BpmSlider extends StatelessWidget {
  const _BpmSlider({required this.bpm, required this.onChanged});
  final int bpm;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.speed),
            const SizedBox(width: 8),
            Text('BPM: $bpm', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        Slider(
          value: bpm.toDouble(),
          min: 40,
          max: 240,
          divisions: 200,
          label: '$bpm',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

class _BeatPicker extends StatelessWidget {
  const _BeatPicker({required this.n, required this.onChanged});
  final int n;
  final ValueChanged<int> onChanged;

  /// 常用拍号预设
  static const List<Map<String, dynamic>> presets = <Map<String, dynamic>>[
    <String, dynamic>{'label': '2/4', 'beats': 2, 'accents': <int>[0]},
    <String, dynamic>{'label': '3/4', 'beats': 3, 'accents': <int>[0]},
    <String, dynamic>{'label': '4/4', 'beats': 4, 'accents': <int>[0]},
    <String, dynamic>{'label': '6/8', 'beats': 6, 'accents': <int>[0, 3]},
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.repeat),
                const SizedBox(width: 8),
                Text(
                  '拍号：$n 拍',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 拍号预设
            Wrap(
              spacing: 8,
              children: presets
                  .map((Map<String, dynamic> p) => ChoiceChip(
                        label: Text(p['label'] as String),
                        selected: n == p['beats'],
                        onSelected: (_) => onChanged(p['beats'] as int),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // slider 自定义
            Slider(
              value: n.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '$n',
              onChanged: (v) => onChanged(v.round()),
            ),
            // 重音位置提示
            _AccentHint(beats: n),
          ],
        ),
      ),
    );
  }
}

/// 显示"哪几拍是主重音"的可视化提示
/// 4/4: ●○○○  ●○○○
/// 6/8: ●○○●○○
class _AccentHint extends StatelessWidget {
  const _AccentHint({required this.beats});
  final int beats;

  @override
  Widget build(BuildContext context) {
    // 找匹配的预设，找不到用"第一拍是主重音"默认
    Map<String, dynamic>? preset;
    for (final Map<String, dynamic> p in _BeatPicker.presets) {
      if (p['beats'] == beats) {
        preset = p;
        break;
      }
    }
    final List<int> accents =
        (preset?['accents'] as List<int>?) ?? <int>[0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(beats, (int i) {
        final bool isAccent = accents.contains(i);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                isAccent ? Icons.circle : Icons.circle_outlined,
                size: 16,
                color: isAccent
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(height: 2),
              Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 10,
                  color: isAccent
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.state});
  final MetronomeState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: () => context.read<MetronomeCubit>().setBpm(state.bpm - 5),
          icon: const Icon(Icons.remove),
          label: const Text('-5'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final cubit = context.read<MetronomeCubit>();
            state.isRunning ? cubit.stop() : cubit.start();
          },
          icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
          label: Text(state.isRunning ? '暂停' : '开始'),
          style: ElevatedButton.styleFrom(
            backgroundColor: state.isRunning ? Colors.red : null,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => context.read<MetronomeCubit>().setBpm(state.bpm + 5),
          icon: const Icon(Icons.add),
          label: const Text('+5'),
        ),
      ],
    );
  }
}