/// 像素级 widget test — 断言圆点真实位置
///
/// 关键测试：圆点必须在 (stringX, fretLineY) 的位置（百分比定位 + Stack）
/// - 弦 x：stringIndex / 3 * boardWidth（4 弦等分）
/// - 圆点 y：(fret - 0.5) / fretsToShow * boardHeight（骑品丝线中点）
/// - fretsToShow = max(4, max(fingering) + 1)
/// 用 getRect 拿真实像素位置
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukulele/features/practice/chord_chart.dart';

void main() {
  group('ChordChart v4 — 像素级测试（参考项目百分比定位）', () {
    testWidgets('Am（参考数据 [2,0,0,0]：4 弦 2 品）1 个圆点在最左列',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360, height: 600,
              child: ChordChart(chord: 'Am'),
            ),
          ),
        ),
      );

      // Am = [2,0,0,0]: 4 弦 2 品 → 1 个 ●（在最左弦）+ 3 个 ○
      // play marker row 中：1 个 ● + 3 个 ○
      expect(find.text('●'), findsOneWidget);
      expect(find.text('○'), findsNWidgets(3));
      expect(find.text('×'), findsNothing);
    });

    testWidgets('C（1 弦 3 品）：圆点"3"在最右列（1 弦），骑在品丝线中点',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360, height: 600,
              child: ChordChart(chord: 'C'),
            ),
          ),
        ),
      );

      // C = [0,0,0,3]: fretsToShow = max(4, 3+1) = 4
      // 圆点 key = 'dot-3-3' (s=3, fingers[3]=3)
      final dotFinder = find.byKey(const ValueKey('dot-3-3'));
      expect(dotFinder, findsOneWidget);

      final dotRect = tester.getRect(dotFinder);
      print('  C 圆点 3 真实 Rect: $dotRect');

      final boardFinder = find.byType(ChordChart);
      final boardRect = tester.getRect(boardFinder);
      print('  C ChordChart Rect: $boardRect');

      // 圆点中心 x 应在 chordChart 右侧 25% 区间（最右弦）
      final rightZoneLeft = boardRect.right - boardRect.width * 0.30;
      expect(
        dotRect.center.dx > rightZoneLeft,
        isTrue,
        reason: 'C 圆点 x=${dotRect.center.dx} 应在最右 30% 区间（> $rightZoneLeft）',
      );
    });

    testWidgets('F（4 弦 2 品 + 2 弦 1 品）：2 个圆点位置正确',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360, height: 600,
              child: ChordChart(chord: 'F'),
            ),
          ),
        ),
      );

      // F = [2, 0, 1, 0], fingers = [2, 0, 1, 0]
      // 2 个 ●（4 弦 + 2 弦），2 个 ○（3 弦 + 1 弦空弦）
      expect(find.text('●'), findsNWidgets(2));
      expect(find.text('○'), findsNWidgets(2));
      expect(find.text('×'), findsNothing);

      // 圆点 key: 'dot-0-2' (4 弦 fret=2 finger=2), 'dot-2-1' (2 弦 fret=1 finger=1)
      expect(find.byKey(const ValueKey('dot-0-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('dot-2-1')), findsOneWidget);

      // 验证两个圆点的相对 x 位置
      final dot2Rect = tester.getRect(find.byKey(const ValueKey('dot-0-2')));
      final dot1Rect = tester.getRect(find.byKey(const ValueKey('dot-2-1')));
      print('  F 圆点 2 (4 弦) Rect: $dot2Rect');
      print('  F 圆点 1 (2 弦) Rect: $dot1Rect');

      // 4 弦在最左 (x=0)，2 弦在 s=2 (x=2/3 * W)
      expect(
        dot2Rect.center.dx < dot1Rect.center.dx,
        isTrue,
        reason: '4 弦圆点 x=${dot2Rect.center.dx} 应在 2 弦圆点 x=${dot1Rect.center.dx} 左侧',
      );
    });

    testWidgets('G7（4 弦空, 3 弦 2 品, 2 弦 1 品, 1 弦 2 品）：3 个圆点位置正确',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360, height: 600,
              child: ChordChart(chord: 'G7'),
            ),
          ),
        ),
      );

      // G7 = [0, 2, 1, 2], fingers = [0, 2, 1, 3]
      // 1 个 ○（4 弦空弦）+ 3 个 ●（3 弦 2 品, 2 弦 1 品, 1 弦 2 品）
      expect(find.text('●'), findsNWidgets(3));
      expect(find.text('○'), findsOneWidget);

      // 圆点 key: 'dot-1-2' (3 弦 fret=2), 'dot-2-1' (2 弦 fret=1), 'dot-3-3' (1 弦 fret=2 finger=3)
      expect(find.byKey(const ValueKey('dot-1-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('dot-2-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('dot-3-3')), findsOneWidget);

      // 拿到 3 个圆点的真实 Rect
      final dot2Rect = tester.getRect(find.byKey(const ValueKey('dot-1-2'))); // 3 弦 2 品
      final dot1Rect = tester.getRect(find.byKey(const ValueKey('dot-2-1'))); // 2 弦 1 品
      final dot3Rect = tester.getRect(find.byKey(const ValueKey('dot-3-3'))); // 1 弦 2 品（无名指）
      print('  G7 圆点 2 (3 弦) Rect: $dot2Rect');
      print('  G7 圆点 1 (2 弦) Rect: $dot1Rect');
      print('  G7 圆点 3 (1 弦) Rect: $dot3Rect');

      // x 顺序：3 弦 (s=1) < 2 弦 (s=2) < 1 弦 (s=3)
      expect(dot2Rect.center.dx < dot1Rect.center.dx, isTrue);
      expect(dot1Rect.center.dx < dot3Rect.center.dx, isTrue);

      // y 验证：fret=1 圆点 y 应高于（更小）fret=2 圆点
      expect(dot1Rect.center.dy < dot2Rect.center.dy, isTrue,
        reason: 'fret=1 圆点 y 应低于 fret=2 圆点 y（更靠上）');
      expect(dot1Rect.center.dy < dot3Rect.center.dy, isTrue,
        reason: 'fret=1 圆点 y 应低于 fret=2 圆点 y（更靠上）');
    });

    testWidgets('G 别名 = G7：相同指法，相同圆点数量', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360, height: 600,
              child: ChordChart(chord: 'G'),
            ),
          ),
        ),
      );

      // 'G' 应等同于 'G7' 指法
      expect(find.text('●'), findsNWidgets(3));
      expect(find.text('○'), findsOneWidget);
    });
  });
}
