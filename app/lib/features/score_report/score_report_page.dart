import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../ai_coach/ai_suggestion.dart';
import '../sheets/data/sheet_model.dart';
import 'score_report_cubit.dart';
/// 评分报告页面
class ScoreReportPage extends StatelessWidget {
  const ScoreReportPage({
    super.key,
    required this.sheet,
    required this.audioBytes,
    this.localSuggestions = const <AiSuggestion>[],
  });

  final Sheet sheet;
  final Uint8List audioBytes;
  final List<AiSuggestion> localSuggestions; // 本地 AI 智能建议（M05）

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${sheet.title} - 评分报告')),
      body: BlocProvider<ScoreReportCubit>(
        create: (_) => ScoreReportCubit(sheet: sheet)
          ..submit(wavBytes: audioBytes, sheetId: sheet.id),
        child: _ScoreReportView(localSuggestions: localSuggestions),
      ),
    );
  }
}

class _ScoreReportView extends StatelessWidget {
  const _ScoreReportView({this.localSuggestions = const <AiSuggestion>[]});
  final List<AiSuggestion> localSuggestions;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScoreReportCubit, ScoreReportState>(
      builder: (BuildContext context, ScoreReportState state) {
        if (state.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('AI 评分中…（5-20 秒）'),
              ],
            ),
          );
        }
        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('评分失败：${state.error}'),
              ],
            ),
          );
        }
        if (state.result == null) {
          return const Center(child: Text('暂无评分数据'));
        }
        return _ReportBody(
          result: state.result!,
          localSuggestions: localSuggestions,
        );
      },
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.result, this.localSuggestions = const <AiSuggestion>[]});
  final ScoreResult result;
  final List<AiSuggestion> localSuggestions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 综合分大字
          _OverallScore(overall: result.dimensions.overall),
          const SizedBox(height: 16),

          // AI 智能建议（M05 本地）
          if (localSuggestions.isNotEmpty) ...<Widget>[
            _AiSuggestionsCard(suggestions: localSuggestions),
            const SizedBox(height: 16),
          ],

          // 雷达图
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Text('能力雷达', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: _RadarChartPainter(result.dimensions),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 维度分
          _DimensionsList(dim: result.dimensions),
          const SizedBox(height: 16),

          // 弱项诊断
          if (result.weakPoints.isNotEmpty) ...<Widget>[
            _SectionCard(
              title: '💡 AI 弱项诊断',
              items: result.weakPoints,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
          ],

          // 改进建议
          if (result.suggestions.isNotEmpty) ...<Widget>[
            _SectionCard(
              title: '📚 改进建议',
              items: result.suggestions,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
          ],

          // 错音详情
          if (result.notes.isNotEmpty) ...<Widget>[
            _NotesList(notes: result.notes),
            const SizedBox(height: 16),
          ],

          // 操作按钮
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.replay),
                  label: const Text('重练此曲'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/sheets'),
                  icon: const Icon(Icons.list),
                  label: const Text('选下一首'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverallScore extends StatelessWidget {
  const _OverallScore({required this.overall});
  final double overall;

  @override
  Widget build(BuildContext context) {
    final Color color = _scoreColor(overall);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: <Widget>[
            Text('综合分', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              overall.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _scoreLabel(overall),
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 90) return Colors.green;
    if (s >= 75) return Colors.lightGreen;
    if (s >= 60) return Colors.orange;
    return Colors.red;
  }

  String _scoreLabel(double s) {
    if (s >= 90) return '🎉 优秀';
    if (s >= 75) return '👍 良好';
    if (s >= 60) return '😐 继续努力';
    return '💪 加油';
  }
}

class _DimensionsList extends StatelessWidget {
  const _DimensionsList({required this.dim});
  final ScoreDimension dim;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _DimBar(label: '音准', value: dim.pitch),
            const SizedBox(height: 8),
            _DimBar(label: '节奏', value: dim.rhythm),
            const SizedBox(height: 8),
            _DimBar(label: '流畅度', value: dim.fluency),
          ],
        ),
      ),
    );
  }
}

class _DimBar extends StatelessWidget {
  const _DimBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 60,
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100.0,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                value >= 80
                    ? Colors.green
                    : value >= 60
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.items,
    required this.color,
  });
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            ...items.map((String item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 4,
                        height: 18,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({required this.notes});
  final List<NoteEvent> notes;

  @override
  Widget build(BuildContext context) {
    final int correctCount = notes.where((n) => n.isCorrect).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('音符详情', style: Theme.of(context).textTheme.headlineMedium),
                Text('$correctCount / ${notes.length} 命中'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: notes.map((n) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: n.isCorrect
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: n.isCorrect ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        n.expectedNote,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: n.isCorrect
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                        ),
                      ),
                      Text(
                        n.detectedNote == '-'
                            ? '未检测'
                            : '→ ${n.detectedNote} '
                                '${n.centsOffset > 0 ? '+' : ''}${n.centsOffset}¢',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 雷达图 CustomPainter
class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter(this.dim);
  final ScoreDimension dim;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * 0.4;

    // 3 个轴：音准、节奏、流畅度
    final List<double> values = <double>[dim.pitch, dim.rhythm, dim.fluency];
    final List<String> labels = <String>['音准', '节奏', '流畅度'];

    // 画背景圆（五边形或多边形）
    final Paint bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    final List<Offset> points = <Offset>[];
    for (int i = 0; i < 3; i++) {
      final double angle = -math.pi / 2 + i * 2 * math.pi / 3;
      points.add(Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ));
    }

    // 画分层网格
    for (double r = 0.25; r <= 1.0; r += 0.25) {
      final List<Offset> gridPoints = <Offset>[];
      for (int i = 0; i < 3; i++) {
        final double angle = -math.pi / 2 + i * 2 * math.pi / 3;
        gridPoints.add(Offset(
          center.dx + radius * r * math.cos(angle),
          center.dy + radius * r * math.sin(angle),
        ));
      }
      final Path path = Path()..moveTo(gridPoints[0].dx, gridPoints[0].dy);
      for (int i = 1; i < gridPoints.length; i++) {
        path.lineTo(gridPoints[i].dx, gridPoints[i].dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = r == 1.0 ? Colors.grey : Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // 画数据多边形
    final List<Offset> dataPoints = <Offset>[];
    for (int i = 0; i < 3; i++) {
      final double angle = -math.pi / 2 + i * 2 * math.pi / 3;
      final double r = (values[i] / 100.0).clamp(0.0, 1.0) * radius;
      dataPoints.add(Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      ));
    }

    final Path dataPath = Path()..moveTo(dataPoints[0].dx, dataPoints[0].dy);
    for (int i = 1; i < dataPoints.length; i++) {
      dataPath.lineTo(dataPoints[i].dx, dataPoints[i].dy);
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = Colors.teal.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = Colors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 画数据点
    for (final Offset p in dataPoints) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.teal);
    }

    // 画标签
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < 3; i++) {
      final double angle = -math.pi / 2 + i * 2 * math.pi / 3;
      final Offset labelPos = Offset(
        center.dx + (radius + 20) * math.cos(angle),
        center.dy + (radius + 20) * math.sin(angle),
      );
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelPos.dx - textPainter.width / 2, labelPos.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ============== AI 智能建议卡片（M05 本地规则生成）==============
class _AiSuggestionsCard extends StatelessWidget {
  const _AiSuggestionsCard({required this.suggestions});
  final List<AiSuggestion> suggestions;

  IconData _iconFor(AiSuggestion s) {
    switch (s.severity) {
      case 2:
        return Icons.warning_amber_rounded;
      case 1:
        return Icons.lightbulb_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  Color _colorFor(AiSuggestion s) {
    switch (s.severity) {
      case 2:
        return Colors.red.shade400;
      case 1:
        return Colors.orange.shade400;
      default:
        return Colors.green.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.smart_toy, color: Colors.indigo.shade400, size: 20),
                const SizedBox(width: 6),
                Text(
                  '🤖 AI 智能建议',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.indigo.shade400,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            for (int i = 0; i < suggestions.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(_iconFor(suggestions[i]),
                      size: 18, color: _colorFor(suggestions[i])),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          suggestions[i].title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          suggestions[i].detail,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}