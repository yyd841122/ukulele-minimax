import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'data/sheet_api.dart';
import 'data/sheet_model.dart';

/// 曲谱库列表页
class SheetsPage extends StatelessWidget {
  const SheetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('曲谱库'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: BlocProvider<SheetsCubit>(
        create: (_) => SheetsCubit()..load(),
        child: const _SheetsView(),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    final SheetsCubit cubit = context.read<SheetsCubit>();
    showSearch<void>(
      context: context,
      delegate: _SheetSearchDelegate(cubit),
    );
  }
}

class _SheetsView extends StatelessWidget {
  const _SheetsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SheetsCubit, SheetsState>(
      builder: (BuildContext context, SheetsState state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('加载失败：${state.error}'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.read<SheetsCubit>().load(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        if (state.sheets.isEmpty) {
          return const Center(child: Text('暂无曲谱'));
        }

        return RefreshIndicator(
          onRefresh: () => context.read<SheetsCubit>().load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.sheets.length + 1,
            itemBuilder: (BuildContext context, int i) {
              if (i == 0) {
                // 难度筛选
                return _DifficultyFilter(current: state.difficulty, onChange: (d) {
                  context.read<SheetsCubit>().filterByDifficulty(d);
                });
              }
              final Sheet sheet = state.sheets[i - 1];
              return _SheetCard(sheet: sheet);
            },
          ),
        );
      },
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.sheet});
  final Sheet sheet;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            sheet.difficultyEmoji,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          sheet.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (sheet.artist != null) Text(sheet.artist!),
            Row(
              children: <Widget>[
                _Tag(label: sheet.difficultyLabel),
                const SizedBox(width: 4),
                _Tag(label: '${sheet.bpm} BPM'),
                const SizedBox(width: 4),
                _Tag(label: sheet.durationLabel),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/sheets/${sheet.id}'),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _DifficultyFilter extends StatelessWidget {
  const _DifficultyFilter({required this.current, required this.onChange});
  final String? current;
  final ValueChanged<String?> onChange;

  @override
  Widget build(BuildContext context) {
    const List<Map<String, String>> levels = <Map<String, String>>[
      <String, String>{'label': '全部', 'value': ''},
      <String, String>{'label': '入门', 'value': 'beginner'},
      <String, String>{'label': '简单', 'value': 'easy'},
      <String, String>{'label': '中等', 'value': 'medium'},
      <String, String>{'label': '困难', 'value': 'hard'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: levels
            .map((Map<String, String> l) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(l['label']!),
                    selected: current == (l['value']!.isEmpty ? null : l['value']),
                    onSelected: (_) =>
                        onChange(l['value']!.isEmpty ? null : l['value']),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _SheetSearchDelegate extends SearchDelegate<void> {
  _SheetSearchDelegate(this.cubit);
  final SheetsCubit cubit;

  @override
  List<Widget>? buildActions(BuildContext context) => <Widget>[
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    cubit.search(query);
    return const _SheetsView();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) return const SizedBox.shrink();
    cubit.search(query);
    return const _SheetsView();
  }
}

// ============== State + Cubit ==============

class SheetsState {
  const SheetsState({
    required this.sheets,
    required this.isLoading,
    this.error,
    this.difficulty,
  });

  factory SheetsState.initial() => const SheetsState(
        sheets: <Sheet>[],
        isLoading: true,
      );

  final List<Sheet> sheets;
  final bool isLoading;
  final String? error;
  final String? difficulty;

  SheetsState copyWith({
    List<Sheet>? sheets,
    bool? isLoading,
    String? error,
    String? difficulty,
    bool clearError = false,
    bool clearDifficulty = false,
  }) {
    return SheetsState(
      sheets: sheets ?? this.sheets,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
    );
  }
}

class SheetsCubit extends Cubit<SheetsState> {
  SheetsCubit({SheetApiClient? api})
      : _api = api ?? SheetApiClient(),
        super(SheetsState.initial());

  final SheetApiClient _api;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final List<Sheet> sheets = await _api.listSheets(
        instrument: 'ukulele',
        difficulty: state.difficulty,
        limit: 50,
      );
      emit(state.copyWith(sheets: sheets, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> filterByDifficulty(String? d) async {
    emit(state.copyWith(
      difficulty: d,
      clearDifficulty: d == null,
    ));
    await load();
  }

  Future<void> search(String q) async {
    if (q.isEmpty) {
      await load();
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final List<Sheet> sheets = await _api.listSheets(
        instrument: 'ukulele',
        search: q,
        limit: 50,
      );
      emit(state.copyWith(sheets: sheets, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}