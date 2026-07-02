/// 尤克里里指法图（v4 — 借鉴参考项目 E:/codex-projects/ukulele/apps/mobile/App.tsx:594-657）
///
/// 设计原则：
/// - 用百分比定位 + Stack + Positioned，圆点中心 = 琴弦 x 位置
/// - 圆点 y 骑在品丝线中点：top = (fret - 0.5) / fretsToShow * 100%
/// - 弦线 x 等分：left = stringIndex / (n - 1) * 100%
/// - 动态品数：max(4, max(fingering) + 1)
/// - 顶部 ○/×/● 提示行（参考项目 styles.playMarker）
/// - 弦标签 G C E A，4 弦在最左
///
/// 数据来源：参考项目 packages/shared/src/index.js:27-64 (beginnerChords)
///
/// 弦索引约定：
///   s=0: 4 弦 (G) — 最左
///   s=1: 3 弦 (C)
///   s=2: 2 弦 (E)
///   s=3: 1 弦 (A) — 最右
library;

import 'package:flutter/material.dart';

// ============== 数据层（参考 packages/shared/src/index.js:27-64）==============

class _ChordFingering {
  const _ChordFingering({required this.fingering, required this.fingers});
  /// 每根弦按的品数（0 = 空弦，-1 = 不弹）
  final List<int> fingering;
  /// 每根弦用哪根手指（0 = 空弦或不用手指，1=食指 2=中指 3=无名指）
  final List<int> fingers;
}

const Map<String, _ChordFingering> _chordData = {
  'C':  _ChordFingering(fingering: [0, 0, 0, 3], fingers: [0, 0, 0, 3]),
  'Am': _ChordFingering(fingering: [2, 0, 0, 0], fingers: [2, 0, 0, 0]),
  'F':  _ChordFingering(fingering: [2, 0, 1, 0], fingers: [2, 0, 1, 0]),
  'G7': _ChordFingering(fingering: [0, 2, 1, 2], fingers: [0, 2, 1, 3]),
  // 兼容旧测试 / 用户口语习惯：'G' 等同 'G7'
  'G':  _ChordFingering(fingering: [0, 2, 1, 2], fingers: [0, 2, 1, 3]),
};

/// 单音模式：仅在 isSingle=true 时使用，只在某根弦上画一个圆点
const Map<String, _ChordFingering> _singleNotes = {
  'C':  _ChordFingering(fingering: [-1, -1, -1, 3], fingers: [0, 0, 0, 3]),
  'D':  _ChordFingering(fingering: [-1, -1, 2, -1], fingers: [0, 0, 2, 0]),
  'E':  _ChordFingering(fingering: [-1, -1, 0, -1], fingers: [0, 0, 0, 0]),
  'F':  _ChordFingering(fingering: [1, -1, -1, -1], fingers: [1, 0, 0, 0]),
  'G':  _ChordFingering(fingering: [0, -1, -1, -1], fingers: [0, 0, 0, 0]),
  'A':  _ChordFingering(fingering: [-1, -1, -1, 0], fingers: [0, 0, 0, 0]),
  'B':  _ChordFingering(fingering: [2, -1, -1, -1], fingers: [2, 0, 0, 0]),
};

_ChordFingering _resolve(String chord, bool isSingle) {
  if (isSingle && chord.isNotEmpty) {
    final root = chord[0];
    final data = _singleNotes[root];
    if (data != null) return data;
  }
  final data = _chordData[chord];
  if (data != null) return data;
  // 找不到：全空
  return const _ChordFingering(fingering: [0, 0, 0, 0], fingers: [0, 0, 0, 0]);
}

// ============== 视觉常量（参考 App.tsx styles 段）==============

const List<String> _stringLabels = ['G', 'C', 'E', 'A'];
const int _stringCount = 4;

const double _dotSize = 30;       // 缩到 30 适配小屏（参考 38）
const int _dotColor = 0xFFFF8A3D;
const double _stringLineWidth = 2;
const double _fretLineHeight = 2;
const double _nutHeight = 5;
const int _lineColor = 0xFF697078;
const int _nutColor = 0xFF1F2937;
const int _boardBg = 0xFFFFFFFF;
const int _boardBorder = 0xFFE5DFD3;
const int _fretNumberColor = 0xFFA19A91;
const int _markerInkColor = 0xFF1F2937;

// ============== 公共组件 ==============

class ChordChart extends StatelessWidget {
  const ChordChart({
    super.key,
    required this.chord,
    this.isSingle = false,
  });

  final String chord;
  final bool isSingle;

  @override
  Widget build(BuildContext context) {
    final data = _resolve(chord, isSingle);

    // fretsToShow：max(4, max(fret)+1)
    final maxFret = data.fingering.fold<int>(0, (m, v) => v > m ? v : m);
    final fretsToShow = (maxFret + 1).clamp(4, 99);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(_boardBg),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(_boardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 顶部 play marker row（○ / ● / ×）
          _PlayMarkerRow(fingering: data.fingering),
          const SizedBox(height: 2),
          // 主指板：固定宽高比 1.4（宽 240 / 高 170），用 ConstrainedBox 限定
          SizedBox(
            width: 256,
            height: 184, // 256 / 1.4 ≈ 183
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 22,
                  child: _FretNumberRail(fretsToShow: fretsToShow),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _Fretboard(
                    fingering: data.fingering,
                    fingers: data.fingers,
                    fretsToShow: fretsToShow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 底部弦标签 G C E A
          _StringLabelsRow(),
        ],
      ),
    );
  }
}

// ============== 顶部 play marker row（○ / ● / ×）==============

class _PlayMarkerRow extends StatelessWidget {
  const _PlayMarkerRow({required this.fingering});
  final List<int> fingering;

  @override
  Widget build(BuildContext context) {
    // 参考 App.tsx: {fret < 0 ? "×" : fret === 0 ? "○" : "●"}
    // 对尤克里里：fret==0 = ○（空弦弹），fret>0 = ●（按弦弹），fret<0 = ×（不弹）
    return Row(
      children: <Widget>[
        for (int s = 0; s < _stringCount; s++)
          Expanded(
            child: Center(
              child: Text(
                _markerChar(fingering[s]),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(_markerInkColor),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _markerChar(int fret) {
    if (fret < 0) return '×';
    if (fret == 0) return '○';
    return '●';
  }
}

// ============== 左侧品号 1/2/3/...（用百分比对齐品丝线 y 位置）==============

class _FretNumberRail extends StatelessWidget {
  const _FretNumberRail({required this.fretsToShow});
  final int fretsToShow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: LayoutBuilder(
        builder: (BuildContext ctx, BoxConstraints c) {
          final double h = c.maxHeight;
          // 品号 y 位置（每条品丝线的位置 = (i / fretsToShow) * h）
          double y(int i) => (i / fretsToShow) * h;
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (int i = 1; i <= fretsToShow; i++)
                Positioned(
                  top: y(i) - 7, // 字号 12 的半高，居中对齐品丝线
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '$i',
                      style: const TextStyle(
                        color: Color(_fretNumberColor),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ============== 主指板：百分比定位 + Stack ==============

class _Fretboard extends StatelessWidget {
  const _Fretboard({
    required this.fingering,
    required this.fingers,
    required this.fretsToShow,
  });
  final List<int> fingering;
  final List<int> fingers;
  final int fretsToShow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints c) {
        final double w = c.maxWidth;
        final double h = c.maxHeight; // 由 AspectRatio 提供
        // 4 根弦的 x 位置（等分）：0%, 33.3%, 66.7%, 100%
        double stringX(int s) => s * (w / (_stringCount - 1));
        // 品丝线 y 位置（0% 是 0 品粗线 / nut）：(i / fretsToShow) * 100%
        double fretLineY(int i) => (i / fretsToShow) * h;
        // 圆点 y 位置（骑品丝中点）：(fret - 0.5) / fretsToShow * 100%
        double dotY(int fret) => ((fret - 0.5) / fretsToShow) * h;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // ① 弦线（4 条纵向，x 等分）
              for (int s = 0; s < _stringCount; s++)
                Positioned(
                  left: stringX(s) - _stringLineWidth / 2,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: _stringLineWidth,
                    color: const Color(_lineColor),
                  ),
                ),
              // ② 品丝线（fretsToShow + 1 条横向，含 0 品粗线）
              for (int i = 0; i <= fretsToShow; i++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: fretLineY(i) - (i == 0 ? _nutHeight / 2 : _fretLineHeight / 2),
                  child: Container(
                    height: i == 0 ? _nutHeight : _fretLineHeight,
                    color: Color(i == 0 ? _nutColor : _lineColor),
                  ),
                ),
              // ③ 圆点（仅在 fret > 0 的弦上画）
              for (int s = 0; s < _stringCount; s++)
                if (fingering[s] > 0)
                  Positioned(
                    left: stringX(s) - _dotSize / 2,
                    top: dotY(fingering[s]) - _dotSize / 2,
                    child: _FingerDot(
                      key: ValueKey('dot-$s-${fingers[s]}'),
                      finger: fingers[s],
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _FingerDot extends StatelessWidget {
  const _FingerDot({super.key, required this.finger});
  final int finger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dotSize,
      height: _dotSize,
      decoration: const BoxDecoration(
        color: Color(_dotColor),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$finger',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ============== 底部弦标签 G C E A ==============

class _StringLabelsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24), // 与指板左侧品号对齐
      child: Row(
        children: <Widget>[
          for (final label in _stringLabels)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(_fretNumberColor),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}