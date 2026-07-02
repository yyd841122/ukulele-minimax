/// AI 陪练主页（M05）
///
/// 内容：
/// - 顶部：模式说明 + 开始练习按钮（默认跟弹模式）
/// - 3 个模式卡片：跟弹 / 唱弹 / 自由
/// - 推荐曲谱列表（按难度分组）
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../practice/practice_cubit.dart';
import '../practice/practice_page.dart';
import '../sheets/data/local_sheet_source.dart';
import '../sheets/data/sheet_model.dart';
import '../sheets/sheet_detail_page.dart';

class AiCoachPage extends StatefulWidget {
  const AiCoachPage({super.key});

  @override
  State<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends State<AiCoachPage> {
  Future<List<Sheet>>? _sheetsFuture;

  @override
  void initState() {
    super.initState();
    _sheetsFuture = LocalSheetSource.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 陪练'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<Sheet>>(
        future: _sheetsFuture,
        builder: (BuildContext context,
            AsyncSnapshot<List<Sheet>> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('加载失败：${snapshot.error}'),
                  ],
                ),
              ),
            );
          }
          final List<Sheet> sheets = snapshot.data ?? <Sheet>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: <Widget>[
              _Header(),
              const SizedBox(height: 16),
              _ModeIntro(),
              const SizedBox(height: 16),
              for (final mode in PracticeMode.values) ...<Widget>[
                _ModeCard(
                  mode: mode,
                  onTap: mode == PracticeMode.free
                      ? () => _goFree()
                      : () => _goWithSheet(mode),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              _RecommendSheets(sheets: sheets),
            ],
          );
        },
      ),
    );
  }

  /// 自由模式：需要先选一张曲谱确定 sheet（用于记录结果）
  void _goFree() {
    context.push(AppRoutes.sheets);
  }

  /// 跟弹 / 唱弹：跳曲谱库选歌
  void _goWithSheet(PracticeMode mode) {
    context.push(AppRoutes.sheets);
    // 模式参数在 SheetDetailPage 的"开始练习"里暂时不支持切换，先统一走默认（guide）
    // 后续可扩展：sheet_detail_page 加 mode 参数
    debugPrint('AI 陪练：选择了 $mode 模式');
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFEF5350), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.smart_toy, color: Colors.white, size: 24),
              SizedBox(width: 6),
              Text(
                'AI 陪练',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '3 种练习模式 · 实时音高检测 · AI 智能建议',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          SizedBox(height: 12),
          Row(
            children: <Widget>[
              _HeaderTag('🎯 错音标红'),
              SizedBox(width: 8),
              _HeaderTag('📊 命中率'),
              SizedBox(width: 8),
              _HeaderTag('🤖 AI 建议'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderTag extends StatelessWidget {
  const _HeaderTag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _ModeIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Icon(Icons.tips_and_updates,
              size: 18, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '点击任一模式卡进入曲谱库选歌；曲谱详情页可切换跟弹 / 唱弹 / 自由模式',
              style: TextStyle(fontSize: 12, color: Colors.brown),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onTap});
  final PracticeMode mode;
  final VoidCallback onTap;

  String get _title {
    switch (mode) {
      case PracticeMode.guide:
        return '跟弹模式';
      case PracticeMode.sing:
        return '唱弹模式';
      case PracticeMode.free:
        return '自由练习';
    }
  }

  String get _subtitle {
    switch (mode) {
      case PracticeMode.guide:
        return '按谱弹和弦，AI 实时评分';
      case PracticeMode.sing:
        return '唱出旋律音，AI 判定命中';
      case PracticeMode.free:
        return '无目标自由弹，AI 统计时长';
    }
  }

  IconData get _icon {
    switch (mode) {
      case PracticeMode.guide:
        return Icons.queue_music;
      case PracticeMode.sing:
        return Icons.mic;
      case PracticeMode.free:
        return Icons.music_off;
    }
  }

  Color get _color {
    switch (mode) {
      case PracticeMode.guide:
        return Colors.teal;
      case PracticeMode.sing:
        return Colors.deepPurple;
      case PracticeMode.free:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(_icon, size: 28, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendSheets extends StatelessWidget {
  const _RecommendSheets({required this.sheets});
  final List<Sheet> sheets;

  @override
  Widget build(BuildContext context) {
    if (sheets.isEmpty) return const SizedBox.shrink();

    // 按难度分组
    final Map<String, List<Sheet>> byDiff = <String, List<Sheet>>{};
    for (final s in sheets) {
      byDiff.putIfAbsent(s.difficulty, () => <Sheet>[]).add(s);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '推荐曲谱 · 按难度',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.indigo.shade400,
            ),
          ),
        ),
        for (final entry in byDiff.entries) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.value.length} 首',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entry.value.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int i) {
                final s = entry.value[i];
                return _SheetMiniCard(sheet: s);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SheetMiniCard extends StatelessWidget {
  const _SheetMiniCard({required this.sheet});
  final Sheet sheet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SheetDetailPage(sheetId: sheet.id),
            ),
          );
        },
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.music_note,
                    size: 18, color: Colors.teal),
              ),
              Text(
                sheet.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${sheet.bpm} BPM · ${sheet.durationLabel}',
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}