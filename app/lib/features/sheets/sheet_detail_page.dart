import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'data/sheet_api.dart';
import 'data/sheet_model.dart';
import '../practice/practice_page.dart';

/// 曲谱详情页
class SheetDetailPage extends StatelessWidget {
  const SheetDetailPage({super.key, required this.sheetId});
  final int sheetId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('曲谱详情')),
      body: FutureBuilder<Sheet>(
        future: SheetApiClient().getSheet(sheetId),
        builder: (BuildContext context, AsyncSnapshot<Sheet> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('加载失败：${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: Text('曲谱不存在'));
          }
          return _SheetDetailView(sheet: snap.data!);
        },
      ),
    );
  }
}

class _SheetDetailView extends StatelessWidget {
  const _SheetDetailView({required this.sheet});
  final Sheet sheet;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 标题 + 副标题
          Text(
            sheet.title,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
          ),
          if (sheet.titleEn != null)
            Text(
              sheet.titleEn!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          if (sheet.artist != null)
            Text(
              '艺人：${sheet.artist}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 16),

          // 元信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  _MetaItem(label: '调号', value: sheet.keySignature),
                  _MetaItem(label: 'BPM', value: '${sheet.bpm}'),
                  _MetaItem(label: '时长', value: sheet.durationLabel),
                  _MetaItem(label: '难度', value: sheet.difficultyLabel),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 简谱区
          if (sheet.notesSimplified != null) ...<Widget>[
            Text('简谱', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  sheet.notesSimplified!,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.8,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 和弦进行
          if (sheet.chords.isNotEmpty) ...<Widget>[
            Text('和弦进行', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sheet.chords
                      .map<Widget>((Map<String, dynamic> c) =>
                          _ChordChip(label: c['chord'] as String? ?? '?'))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 标签
          if (sheet.tags.isNotEmpty) ...<Widget>[
            Wrap(
              spacing: 6,
              children: sheet.tags
                  .map<Widget>((String t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 操作按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => PracticePage(sheet: sheet),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始跟弹练习'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}

class _ChordChip extends StatelessWidget {
  const _ChordChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}