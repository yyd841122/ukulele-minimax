/// 课程图文教程 SVG 自绘示意图
///
/// 5 个 CustomPainter，全部原创，完全矢量绘制
/// 不引入 flutter_svg 等第三方包
library;

import 'package:flutter/material.dart';

// ============== 1. 标准 4 弦指板 ==============

/// 4 弦指板 SVG（高亮品可由 highlight 决定）
///
/// highlight 参数：
/// - dots: List<Map> 每项含 {stringIndex: 0..3, fret: 1..4} 表示按弦
/// - showFrets: 默认 4 品
class UkuleleFretboardPainter extends CustomPainter {
  UkuleleFretboardPainter({
    this.dots = const <Map<String, dynamic>>[],
    this.showFrets = 4,
  });

  final List<Map<String, dynamic>> dots;
  final int showFrets;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double padX = 14;
    final double padTop = 24;
    final double padBottom = 24;
    final double stringAreaWidth = w - padX * 2;
    final double stringAreaHeight = h - padTop - padBottom;
    final double fretGap = stringAreaWidth / (showFrets + 1); // 品间距
    final double nutLeft = padX + fretGap; // 0 品（nut）位置

    // 配色
    final Paint bgPaint = Paint()..color = const Color(0xFFFFF8E7);
    final Paint neckPaint = Paint()..color = const Color(0xFF6D4C41);
    final Paint stringPaint = Paint()
      ..color = const Color(0xFF424242)
      ..strokeWidth = 1.5;
    final Paint fretLinePaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 1.0;
    final Paint nutPaint = Paint()
      ..color = const Color(0xFF212121)
      ..strokeWidth = 3.0;
    final Paint dotPaint = Paint()..color = const Color(0xFFEF6C00);
    final Paint textPaint = Paint()
      ..color = const Color(0xFF212121);

    // 背景 + 琴颈
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padX, padTop, stringAreaWidth, stringAreaHeight),
        const Radius.circular(4),
      ),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padX, padTop, stringAreaWidth, stringAreaHeight),
        const Radius.circular(4),
      ),
      Paint()
        ..color = neckPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 4 根弦（水平方向，间距均匀）
    final double stringSpacing = stringAreaHeight / 3;
    final List<double> stringYs = <double>[
      padTop + stringSpacing * 0.5,
      padTop + stringSpacing * 1.5,
      padTop + stringSpacing * 2.5,
      padTop + stringSpacing * 3.5,
    ];
    for (int i = 0; i < 4; i++) {
      // 上方弦（1弦/最细）画得细一点，下方弦（4弦/最粗）粗一点
      final double strokeW = 0.8 + i * 0.4;
      canvas.drawLine(
        Offset(nutLeft - 4, stringYs[i]),
        Offset(w - padX + 4, stringYs[i]),
        Paint()
          ..color = const Color(0xFF424242)
          ..strokeWidth = strokeW,
      );
    }

    // 品丝竖线
    for (int i = 0; i <= showFrets; i++) {
      final double x = nutLeft + fretGap * i;
      final Paint p = i == 0 ? nutPaint : fretLinePaint;
      canvas.drawLine(
        Offset(x, padTop),
        Offset(x, padTop + stringAreaHeight),
        p,
      );
    }

    // 品号（1-4 在指板下方）
    for (int i = 1; i <= showFrets; i++) {
      final double x = nutLeft + fretGap * (i - 0.5);
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, padTop + stringAreaHeight + 4));
    }

    // 弦标签 G C E A（指板上方）
    final List<String> labels = <String>['G', 'C', 'E', 'A'];
    for (int i = 0; i < 4; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padX - tp.width - 6, stringYs[i] - tp.height / 2));
    }

    // 按弦圆点
    for (final dot in dots) {
      final int s = dot['string'] as int? ?? 0;
      final int f = dot['fret'] as int? ?? 1;
      if (s < 0 || s > 3 || f < 1 || f > showFrets) continue;
      final double cx = nutLeft + fretGap * (f - 0.5);
      final double cy = stringYs[s];
      canvas.drawCircle(Offset(cx, cy), 9, dotPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: '${dot['finger'] ?? f}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }

    // 防止 unused
    textPaint.color = Colors.black;
  }

  @override
  bool shouldRepaint(covariant UkuleleFretboardPainter old) =>
      old.dots != dots || old.showFrets != showFrets;
}

// ============== 2. 右手持琴握法 ==============

/// 右手持琴示意（前臂搭琴身 + 手型）
class HandGripPainter extends CustomPainter {
  const HandGripPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 琴身（左侧大块）
    final Paint bodyPaint = Paint()..color = const Color(0xFFD7A86E);
    final Paint bodyBorder = Paint()
      ..color = const Color(0xFF6D4C41)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final Rect bodyRect = Rect.fromLTWH(w * 0.05, h * 0.30, w * 0.55, h * 0.45);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(30)),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(30)),
      bodyBorder,
    );

    // 琴颈（右上斜出）
    final Paint neckPaint = Paint()..color = const Color(0xFF8D6E63);
    final Path neckPath = Path()
      ..moveTo(w * 0.60, h * 0.40)
      ..lineTo(w * 0.95, h * 0.20)
      ..lineTo(w * 0.95, h * 0.10)
      ..lineTo(w * 0.55, h * 0.30)
      ..close();
    canvas.drawPath(neckPath, neckPaint);
    canvas.drawPath(neckPath, bodyBorder);

    // 4 根弦（沿琴颈方向）
    final Paint stringPaint = Paint()
      ..color = const Color(0xFF424242)
      ..strokeWidth = 1.5;
    final List<double> stringOffsets = <double>[0.0, 0.025, 0.05, 0.075];
    for (final off in stringOffsets) {
      canvas.drawLine(
        Offset(w * (0.55 + off), h * (0.30 - off)),
        Offset(w * (0.95), h * (0.20 - off)),
        stringPaint,
      );
    }

    // 右前臂（搭在琴身上方）
    final Paint armPaint = Paint()..color = const Color(0xFFFFCCBC);
    final Rect armRect = Rect.fromLTWH(w * 0.10, h * 0.55, w * 0.35, h * 0.20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(armRect, const Radius.circular(15)),
      armPaint,
    );

    // 右手（搭在琴身上）
    final Paint handPaint = Paint()..color = const Color(0xFFFFAB91);
    final Rect handRect = Rect.fromLTWH(w * 0.40, h * 0.55, w * 0.18, h * 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(handRect, const Radius.circular(20)),
      handPaint,
    );

    // 拨片（蓝色小三角，握在拇指食指间）
    final Paint pickPaint = Paint()..color = const Color(0xFF1976D2);
    final Path pickPath = Path()
      ..moveTo(w * 0.55, h * 0.65)
      ..lineTo(w * 0.62, h * 0.62)
      ..lineTo(w * 0.62, h * 0.68)
      ..close();
    canvas.drawPath(pickPath, pickPaint);
    canvas.drawPath(
      pickPath,
      Paint()
        ..color = const Color(0xFF0D47A1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 标签"拨片"
    final tp = TextPainter(
      text: const TextSpan(
        text: '拨片',
        style: TextStyle(
          color: Color(0xFF0D47A1),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.55, h * 0.74));
  }

  @override
  bool shouldRepaint(covariant HandGripPainter old) => false;
}

// ============== 3. PIMA 4 指分工 ==============

/// PIMA 4 指分工示意（右手 4 指 + 弦号）
class PimaFingersPainter extends CustomPainter {
  const PimaFingersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 4 个手指（从下到上：拇指 P → 食指 I → 中指 M → 无名指 A）
    // 每个手指 + 标注的弦号
    final List<Map<String, dynamic>> fingers = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'P', 'full': '拇指', 'string': '4弦根音', 'y': 0.78, 'color': const Color(0xFFFFAB91)},
      <String, dynamic>{'name': 'I', 'full': '食指', 'string': '3弦', 'y': 0.55, 'color': const Color(0xFFFFCC80)},
      <String, dynamic>{'name': 'M', 'full': '中指', 'string': '2弦', 'y': 0.32, 'color': const Color(0xFFA5D6A7)},
      <String, dynamic>{'name': 'A', 'full': '无名指', 'string': '1弦(备用)', 'y': 0.10, 'color': const Color(0xFF90CAF9)},
    ];

    for (final f in fingers) {
      final double y = h * f['y'] as double;
      // 手指（细长矩形）
      final Paint fingerPaint = Paint()..color = f['color'] as Color;
      final Rect fingerRect = Rect.fromCenter(
        center: Offset(w * 0.40, y + h * 0.06),
        width: w * 0.18,
        height: h * 0.10,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(fingerRect, const Radius.circular(8)),
        fingerPaint,
      );

      // 字母 P/I/M/A 大圆
      canvas.drawCircle(
        Offset(w * 0.20, y + h * 0.06),
        h * 0.06,
        Paint()..color = const Color(0xFF37474F),
      );
      final tpLetter = TextPainter(
        text: TextSpan(
          text: f['name'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpLetter.paint(
        canvas,
        Offset(w * 0.20 - tpLetter.width / 2, y + h * 0.06 - tpLetter.height / 2),
      );

      // 弦号说明
      final tpLabel = TextPainter(
        text: TextSpan(
          text: '${f['full']} → ${f['string']}',
          style: const TextStyle(
            color: Color(0xFF263238),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpLabel.paint(canvas, Offset(w * 0.55, y + h * 0.02));
    }

    // 顶部标题
    final tpTitle = TextPainter(
      text: const TextSpan(
        text: 'PIMA 4 指分工',
        style: TextStyle(
          color: Color(0xFF37474F),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpTitle.paint(canvas, Offset(w * 0.10, 2));
  }

  @override
  bool shouldRepaint(covariant PimaFingersPainter old) => false;
}

// ============== 4. 横按和弦 ==============

/// 横按和弦示意（食指侧边按压 + 中指/无名指）
///
/// highlight 参数：
/// - strings: List<int> 表示食指横按的弦（默认 [2, 3] 表示 2-3 弦）
/// - otherFingers: List<Map> {stringIndex, fret, finger}
class BarreChordPainter extends CustomPainter {
  BarreChordPainter({
    this.barreStrings = const <int>[2, 3],
    this.otherFingers = const <Map<String, dynamic>>[
      <String, dynamic>{'string': 3, 'fret': 2, 'finger': '中'},
      <String, dynamic>{'string': 4, 'fret': 2, 'finger': '无'},
    ],
  });

  final List<int> barreStrings;
  final List<Map<String, dynamic>> otherFingers;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 琴颈（顶部斜面）
    final Paint neckPaint = Paint()..color = const Color(0xFF8D6E63);
    final Rect neckRect = Rect.fromLTWH(w * 0.20, h * 0.10, w * 0.60, h * 0.30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(neckRect, const Radius.circular(8)),
      neckPaint,
    );

    // 4 根弦（横跨琴颈）
    final Paint stringPaint = Paint()
      ..color = const Color(0xFF424242)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 4; i++) {
      final double y = h * (0.15 + i * 0.07);
      canvas.drawLine(
        Offset(w * 0.20, y),
        Offset(w * 0.80, y),
        stringPaint,
      );
    }

    // 食指横按（红色长条）
    final Paint barrePaint = Paint()..color = const Color(0xFFEF5350);
    final double barreY = h * 0.22;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.20, barreY - h * 0.025, w * 0.80, barreY + h * 0.025),
        const Radius.circular(12),
      ),
      barrePaint,
    );
    // 食指标注
    final tpIndex = TextPainter(
      text: const TextSpan(
        text: '食指',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpIndex.paint(
      canvas,
      Offset(w * 0.45, barreY - tpIndex.height / 2),
    );

    // 中指/无名指（圆点）
    final Paint otherPaint = Paint()..color = const Color(0xFF1976D2);
    for (final f in otherFingers) {
      final int s = f['string'] as int;
      final int fr = f['fret'] as int;
      final double x = w * (0.40 + fr * 0.10);
      final double y = h * (0.15 + s * 0.07);
      canvas.drawCircle(Offset(x, y), h * 0.03, otherPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: f['finger'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // 拇指（背面，从下方伸上来）
    final Paint thumbPaint = Paint()..color = const Color(0xFFFFCCBC);
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.55),
      h * 0.07,
      thumbPaint,
    );
    final tpThumb = TextPainter(
      text: const TextSpan(
        text: '拇指\n(背面)',
        style: TextStyle(
          color: Color(0xFF6D4C41),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpThumb.paint(canvas, Offset(w * 0.55, h * 0.52));

    // 标签：2 品线
    final tpFret = TextPainter(
      text: const TextSpan(
        text: '2 品',
        style: TextStyle(
          color: Color(0xFF455A64),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpFret.paint(canvas, Offset(w * 0.05, h * 0.50));

    // 侧视图提示文字
    final tpHint = TextPainter(
      text: const TextSpan(
        text: '食指侧边（非指腹）压在品丝后方',
        style: TextStyle(
          color: Color(0xFFD32F2F),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpHint.paint(canvas, Offset((w - tpHint.width) / 2, h * 0.78));
  }

  @override
  bool shouldRepaint(covariant BarreChordPainter old) =>
      old.barreStrings != barreStrings || old.otherFingers != otherFingers;
}

// ============== 5. 调音器屏幕 ==============

/// 调音器屏幕示意（指针 + 音名 + cents 数字）
class TunerScreenPainter extends CustomPainter {
  /// 当前 cents（-50 ~ +50，0 = 准）
  TunerScreenPainter({
    required this.noteName,
    this.cents = 0,
  });

  final String noteName;
  final int cents;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 表盘背景
    final Paint dialPaint = Paint()..color = const Color(0xFF1A237E);
    final Rect dialRect = Rect.fromLTWH(w * 0.10, h * 0.10, w * 0.80, h * 0.70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(dialRect, const Radius.circular(8)),
      dialPaint,
    );

    // 刻度弧（半圆）
    final double centerX = w * 0.50;
    final double centerY = h * 0.55;
    final double radius = h * 0.30;
    final Paint tickPaint = Paint()
      ..color = const Color(0xFFB2DFDB)
      ..strokeWidth = 1.5;
    for (int i = -5; i <= 5; i++) {
      final double angle = -1.5708 + (i / 5.0) * 1.5708; // -90° 到 0°（左半弧）
      final double innerR = radius * 0.75;
      canvas.drawLine(
        Offset(centerX + innerR * (i == 0 ? -1 : 1) * (i / 5.0).abs(),
            centerY - radius * 0.4),
        Offset(centerX + innerR * (i == 0 ? -1 : 1) * (i / 5.0).abs() + (i == 0 ? 0 : 0),
            centerY - radius * 0.55),
        tickPaint,
      );
    }

    // 弧线（用 canvas 简化画）
    final paintArc = Paint()
      ..color = const Color(0xFFB2DFDB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(centerX, centerY - radius * 0.2), width: radius * 1.5, height: radius * 1.5),
      -3.14159,
      3.14159,
      false,
      paintArc,
    );

    // 刻度数字 -50, 0, +50
    final labels = <String>['-50', '0', '+50'];
    for (int i = 0; i < 3; i++) {
      final double x = centerX + (i - 1) * radius * 0.5;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Color(0xFFB2DFDB),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, h * 0.70));
    }

    // 指针（绿色）
    final double clampedCents = cents.clamp(-50, 50).toDouble();
    final Paint needlePaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final double direction = clampedCents >= 0 ? 1.0 : -1.0;
    canvas.drawLine(
      Offset(centerX, centerY - radius * 0.2),
      Offset(
        centerX + radius * 0.7 * (clampedCents / 50.0),
        centerY - radius * 0.2 + radius * 0.4 * (1 - (clampedCents.abs() / 50.0)),
      ),
      needlePaint,
    );

    // 音名显示（大字）
    final tpNote = TextPainter(
      text: TextSpan(
        text: noteName,
        style: const TextStyle(
          color: Color(0xFF69F0AE),
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpNote.paint(
      canvas,
      Offset(centerX - tpNote.width / 2, h * 0.18),
    );

    // cents 数字
    final tpCents = TextPainter(
      text: TextSpan(
        text: '${cents > 0 ? '+' : ''}${cents}¢',
        style: const TextStyle(
          color: Color(0xFFB2DFDB),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpCents.paint(
      canvas,
      Offset(centerX - tpCents.width / 2, h * 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant TunerScreenPainter old) =>
      old.noteName != noteName || old.cents != cents;
}

// ============== 便捷入口 Widget ==============

/// 4 弦指板 Widget
class UkuleleFretboardSvg extends StatelessWidget {
  const UkuleleFretboardSvg({
    super.key,
    this.dots = const <Map<String, dynamic>>[],
    this.showFrets = 4,
    this.caption,
  });
  final List<Map<String, dynamic>> dots;
  final int showFrets;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            child: CustomPaint(
              painter: UkuleleFretboardPainter(
                dots: dots,
                showFrets: showFrets,
              ),
            ),
          ),
          if (caption != null && caption!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HandGripSvg extends StatelessWidget {
  const HandGripSvg({super.key, this.caption});
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.6,
          child: const CustomPaint(painter: HandGripPainter()),
        ),
        if (caption != null && caption!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class PimaFingersSvg extends StatelessWidget {
  const PimaFingersSvg({super.key, this.caption});
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.6,
          child: const CustomPaint(painter: PimaFingersPainter()),
        ),
        if (caption != null && caption!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class BarreChordSvg extends StatelessWidget {
  const BarreChordSvg({
    super.key,
    this.barreStrings = const <int>[2, 3],
    this.otherFingers = const <Map<String, dynamic>>[],
    this.caption,
  });
  final List<int> barreStrings;
  final List<Map<String, dynamic>> otherFingers;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.6,
          child: CustomPaint(
            painter: BarreChordPainter(
              barreStrings: barreStrings,
              otherFingers: otherFingers,
            ),
          ),
        ),
        if (caption != null && caption!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class TunerScreenSvg extends StatelessWidget {
  const TunerScreenSvg({
    super.key,
    required this.noteName,
    this.cents = 0,
    this.caption,
  });
  final String noteName;
  final int cents;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.6,
          child: CustomPaint(
            painter: TunerScreenPainter(noteName: noteName, cents: cents),
          ),
        ),
        if (caption != null && caption!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}