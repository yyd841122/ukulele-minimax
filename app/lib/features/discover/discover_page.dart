/// 发现区主页面（综合广场）
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../course_center/course_data.dart';
import '../course_center/course_model.dart';
import '../sheets/data/local_sheet_source.dart';
import '../sheets/data/sheet_model.dart';
import '../sheets/sheet_detail_page.dart';
import 'mock_community.dart';

/// 发现区页面
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  Future<List<Sheet>>? _sheetsFuture;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _sheetsFuture = LocalSheetSource.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现区'),
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
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          final List<Sheet> sheets = snapshot.data ?? <Sheet>[];
          // 按 mock 播放数构造 Top 5 排序（保持 hotSheets 顺序）
          final List<Sheet> hotSheets = kMockHotSheets
              .map((h) {
                for (final s in sheets) {
                  if (s.id == h.sheetId) return s;
                }
                return null;
              })
              .whereType<Sheet>()
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _sheetsFuture = LocalSheetSource.loadAll();
              });
              await _sheetsFuture;
            },
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(child: _Banner(tabIndex: _tabIndex)),
                SliverToBoxAdapter(child: _TabBar(
                  current: _tabIndex,
                  onTap: (int i) => setState(() => _tabIndex = i),
                )),
                if (_tabIndex == 0) ...<Widget>[
                  SliverToBoxAdapter(child: _SectionHeader(
                    icon: Icons.local_fire_department,
                    iconColor: Colors.deepOrange,
                    title: '热门曲目 Top 5',
                    actionText: '查看全部',
                    onAction: () => context.push(AppRoutes.sheets),
                  )),
                  SliverToBoxAdapter(child: _HotSheetsList(sheets: hotSheets)),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(child: _SectionHeader(
                    icon: Icons.people,
                    iconColor: Colors.pink,
                    title: '学员动态',
                    actionText: '更多',
                    onAction: () {},
                  )),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int i) => _UserWorkCard(work: kMockUserWorks[i]),
                      childCount: kMockUserWorks.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(child: _SectionHeader(
                    icon: Icons.school,
                    iconColor: Colors.indigo,
                    title: '推荐课程',
                    actionText: '更多课程',
                    onAction: () => context.push(AppRoutes.courseCenter),
                  )),
                  SliverToBoxAdapter(child: _RecommendCourses()),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(child: _SectionHeader(
                    icon: Icons.history,
                    iconColor: Colors.teal,
                    title: '最近学习',
                    actionText: '全部',
                    onAction: () => context.push(AppRoutes.sheets),
                  )),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int i) => _RecentCard(p: kMockRecentPractices[i]),
                      childCount: kMockRecentPractices.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ] else ...<Widget>[
                  const SliverToBoxAdapter(child: SizedBox(height: 200)),
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: <Widget>[
                            Icon(Icons.construction,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('${_tabTitle(_tabIndex)}：MVP 后续版本上线',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _tabTitle(int i) {
    switch (i) {
      case 1:
        return '热门';
      case 2:
        return '关注';
      case 3:
        return '同城';
      default:
        return '广场';
    }
  }
}

// ============== 区块 Header ==============
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.actionText,
    required this.onAction,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onAction,
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== 顶部 Banner ==============
class _Banner extends StatelessWidget {
  const _Banner({required this.tabIndex});
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF26C6DA), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.public, color: Colors.white, size: 24),
              const SizedBox(width: 6),
              const Text(
                '发现区',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '今日推荐',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '热门曲目 · 学员动态 · 推荐课程 · 最近学习',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: const <Widget>[
              _BannerTag('🔥 12 首热门'),
              SizedBox(width: 8),
              _BannerTag('🎸 6 门课'),
              SizedBox(width: 8),
              _BannerTag('💬 学员 1.2w'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerTag extends StatelessWidget {
  const _BannerTag(this.text);
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

// ============== Tab Bar ==============
class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = const <String>['广场', '热门', '关注', '同城'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < tabs.length; i++) ...<Widget>[
            InkWell(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: i == current ? Colors.teal.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: i == current ? Colors.teal.shade700 : Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============== 热门曲目列表 ==============
class _HotSheetsList extends StatelessWidget {
  const _HotSheetsList({required this.sheets});
  final List<Sheet> sheets;

  @override
  Widget build(BuildContext context) {
    if (sheets.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sheets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          final s = sheets[i];
          final rank = i + 1;
          return InkWell(
            onTap: () => _goSheet(context, s.id),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rank <= 3 ? Colors.red.shade400 : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.local_fire_department,
                          size: 14, color: Colors.deepOrange),
                      const SizedBox(width: 2),
                      Text(
                        '${(kMockHotSheets[i].playCount / 1000).toStringAsFixed(1)}k',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${s.bpm} BPM',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============== 学员动态卡片 ==============
class _UserWorkCard extends StatelessWidget {
  const _UserWorkCard({required this.work});
  final UserWork work;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _goSheet(context, work.sheetId),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 缩略图（彩色渐变占位）
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: work.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.music_note,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            work.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: work.score >= 90
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '${work.score} 分',
                              style: TextStyle(
                                color: work.score >= 90
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '完成了《${work.sheetTitle}》',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Text(
                            timeAgo(work.minutesAgo),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade500),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.favorite,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text('${work.likes}',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chat_bubble,
                              size: 11, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text('${work.comments}',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============== 推荐课程（横滑）==============
class _RecommendCourses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Course> rec = kMockCourses.take(4).toList();
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: rec.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          final c = rec[i];
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.push(
              '/courses/${c.id}',
            ),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    c.level.color.withValues(alpha: 0.92),
                    c.level.color.withValues(alpha: 0.65),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(c.icon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        c.level.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    c.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============== 最近学习 ==============
class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.p});
  final RecentPractice p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _goSheet(context, p.sheetId),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.replay, color: Colors.teal.shade700, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '《${p.sheetTitle}》',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${timeAgo(p.lastPlayedMinutesAgo)}练习 · ${p.score} 分',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_arrow,
                  color: Colors.teal.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _goSheet(BuildContext context, int id) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SheetDetailPage(sheetId: id),
    ),
  );
}