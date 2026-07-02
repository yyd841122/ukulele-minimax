/// 课程节内容块（图文教程 MVP）
///
/// 全部原创内容，基于通用尤克里里通识知识 + 公共领域曲谱
/// 不引用任何外部资源
library;

import 'package:flutter/material.dart';

import 'svg_illustrations.dart';

/// 文本样式类型
enum LessonTextStyle { title, body, tip, warn }

/// SVG 示意图类型（参考 svg_illustrations.dart）
enum SvgType { fretboard, handGrip, pima, barre, tuner }

/// 图文块基类（sealed：text/image/stepList）
sealed class LessonBlock {
  const LessonBlock();
}

/// 文本块
class TextBlock extends LessonBlock {
  const TextBlock(this.text, {this.style = LessonTextStyle.body});
  final String text;
  final LessonTextStyle style;
}

/// 图片块（icon + 渐变 + emoji 占位图）
class ImageBlock extends LessonBlock {
  const ImageBlock({
    required this.emoji,
    required this.gradient,
    required this.caption,
    this.icon = Icons.music_note,
  });
  final String emoji;
  final IconData icon;
  final List<Color> gradient;
  final String caption;
}

/// 步骤列表块
class StepListBlock extends LessonBlock {
  const StepListBlock({required this.steps, this.title = '操作步骤'});
  final String title;
  final List<LessonStep> steps;
}

/// SVG 自绘示意图块
class SvgBlock extends LessonBlock {
  const SvgBlock({
    required this.svgType,
    required this.caption,
    this.dots = const <Map<String, dynamic>>[],
    this.barreStrings = const <int>[2, 3],
    this.otherFingers = const <Map<String, dynamic>>[],
    this.noteName = 'A',
    this.cents = 0,
    this.showFrets = 4,
  });
  final SvgType svgType;

  /// 4 弦指板高亮圆点（仅 fretboard 模式）
  final List<Map<String, dynamic>> dots;

  /// 横按弦号（仅 barre 模式）
  final List<int> barreStrings;

  /// 其他手指（仅 barre 模式）
  final List<Map<String, dynamic>> otherFingers;

  /// 调音器当前音名（仅 tuner 模式）
  final String noteName;

  /// 调音器 cents 偏移（仅 tuner 模式，-50~+50）
  final int cents;

  /// 指板显示几品（仅 fretboard 模式）
  final int showFrets;

  /// 图说文字
  final String caption;
}

class LessonStep {
  const LessonStep(this.index, this.text);
  final int index;
  final String text;
}

// ============== 6 节核心图文内容 ==============
// 仅覆盖每门课的第 1 节（其他节保持 title + description 简介）

/// 课程：尤克里里入门 → 第 1 节 "认识尤克里里"
final List<LessonBlock> kIntroUke1 = <LessonBlock>[
  const TextBlock(
    '认识尤克里里',
    style: LessonTextStyle.title,
  ),
  const TextBlock(
    '尤克里里（ukulele）是来自夏威夷的小型四弦琴，音色清脆活泼，入门门槛低，是很多人接触音乐的第一件乐器。',
  ),
  const SvgBlock(
    svgType: SvgType.fretboard,
    caption: '标准 21 品 soprano 尤克里里（约 53 cm）',
    showFrets: 4,
  ),
  const TextBlock('4 根弦的音名（从左到右）'),
  const StepListBlock(steps: <LessonStep>[
    LessonStep(1, '第 4 弦（最粗）：G（标准音 G4 = 392 Hz）'),
    LessonStep(2, '第 3 弦：C'),
    LessonStep(3, '第 2 弦：E'),
    LessonStep(4, '第 1 弦（最细）：A（标准音 A4 = 440 Hz）'),
  ]),
  const TextBlock('常见 4 种尺寸'),
  const StepListBlock(
    title: '尺寸对比',
    steps: <LessonStep>[
      LessonStep(1, 'Soprano（21 寸）：最常见，音色最亮，适合儿童和初学者'),
      LessonStep(2, 'Concert（23 寸）：音色稍丰满，指板空间略大'),
      LessonStep(3, 'Tenor（26 寸）：更宽指板，适合进阶演奏'),
      LessonStep(4, 'Baritone（30 寸）：最低沉，调弦不同（DGBE）'),
    ],
  ),
  const TextBlock(
    '提示：刚入门推荐 Soprano 或 Concert 尺寸，京东/淘宝价格 200-500 元的合板琴就够用。',
    style: LessonTextStyle.tip,
  ),
];

/// 课程：节奏基础 → 第 1 节 "什么是 BPM"
final List<LessonBlock> kRhythmBasic1 = <LessonBlock>[
  const TextBlock('什么是 BPM？', style: LessonTextStyle.title),
  const TextBlock(
    'BPM = Beats Per Minute（每分钟节拍数），是衡量音乐速度的标准单位。BPM 数字越大，节奏越快。',
  ),
  const ImageBlock(
    emoji: '⏱️',
    gradient: <Color>[Color(0xFF7986CB), Color(0xFF64B5F6)],
    caption: 'BPM 120 = 每分钟 120 拍 = 每拍 0.5 秒',
  ),
  const TextBlock('常见 BPM 区间速查'),
  const StepListBlock(
    title: '速度分类',
    steps: <LessonStep>[
      LessonStep(1, '慢速（60-80 BPM）：摇篮曲、民谣抒情'),
      LessonStep(2, '中速（80-120 BPM）：流行歌曲、儿歌（多数尤克里里曲目）'),
      LessonStep(3, '快速（120-160 BPM）：摇滚、欢快舞曲'),
      LessonStep(4, '极快（160+ BPM）：技术性曲目、摇滚 solo'),
    ],
  ),
  const TextBlock(
    '小星星、欢乐颂的 BPM 通常在 80-100 之间，属于"慢中速"，非常适合入门练习。',
    style: LessonTextStyle.tip,
  ),
  const TextBlock(
    '注意：BPM 数值仅作参考，实际感受还跟拍号（4/4、3/4）和节奏型相关。',
    style: LessonTextStyle.warn,
  ),
];

/// 课程：初识和弦进行 → 第 1 节 "认识 C/Am/F/G"
final List<LessonBlock> kFirstChord1 = <LessonBlock>[
  const TextBlock('认识 C / Am / F / G 四大和弦', style: LessonTextStyle.title),
  const TextBlock(
    '这 4 个和弦可以演奏超过 70% 的流行歌曲，号称"万能四和弦"。掌握它们就能弹唱大量入门曲目。',
  ),
  const SvgBlock(
    svgType: SvgType.fretboard,
    caption: 'C → Am → F → G 是流行乐的经典进行',
    dots: <Map<String, dynamic>>[
      // C: 无名指 1 弦 3 品
      <String, dynamic>{'string': 3, 'fret': 3, 'finger': 3},
      // Am: 全空
      // F: 食指 4 弦 1 品 + 中指 2 弦 1 品（简化版）
      <String, dynamic>{'string': 0, 'fret': 1, 'finger': 1},
      <String, dynamic>{'string': 2, 'fret': 1, 'finger': 2},
      // G: 4 弦开弦 + 食指 3 弦 2 品 + 中指 2 弦 3 品 + 无名指 1 弦 2 品
      <String, dynamic>{'string': 1, 'fret': 2, 'finger': 1},
      <String, dynamic>{'string': 2, 'fret': 3, 'finger': 2},
      <String, dynamic>{'string': 3, 'fret': 2, 'finger': 3},
    ],
  ),
  const TextBlock('4 个和弦的音名组成'),
  const StepListBlock(
    title: '和弦构成',
    steps: <LessonStep>[
      LessonStep(1, 'C 大三和弦：C - E - G（do mi sol）'),
      LessonStep(2, 'Am 小三和弦：A - C - E（la do mi）'),
      LessonStep(3, 'F 大三和弦：F - A - C（fa la do）'),
      LessonStep(4, 'G 大三和弦：G - B - D（sol si re）'),
    ],
  ),
  const TextBlock('每个和弦的根音位置（弹哪根弦）'),
  const StepListBlock(
    title: '根音弦',
    steps: <LessonStep>[
      LessonStep(1, 'C → 根音在第 3 弦（开弦音 C）'),
      LessonStep(2, 'Am → 根音在第 4 弦（开弦音 A）'),
      LessonStep(3, 'F → 根音在第 4 弦（1 品）'),
      LessonStep(4, 'G → 根音在第 4 弦（开弦音 G）'),
    ],
  ),
  const TextBlock(
    '提示：这 4 个和弦都可以在 4 弦 3 品以内完成，对左手按弦压力要求最低。',
    style: LessonTextStyle.tip,
  ),
];

/// 课程：常用扫弦节奏型 → 第 1 节 "下扫与上扫"
final List<LessonBlock> kStrumming1 = <LessonBlock>[
  const TextBlock('下扫（Down）与上扫（Up）', style: LessonTextStyle.title),
  const TextBlock(
    '右手扫弦最基础的两个动作：向下扫（Down）和向上扫（Up）。所有复杂节奏型都是这两个动作的组合。',
  ),
  const SvgBlock(
    svgType: SvgType.handGrip,
    caption: '右手拇指与食指轻握拨片，腕部发力',
  ),
  const TextBlock('拨片握法'),
  const StepListBlock(
    title: '握拨片 3 步',
    steps: <LessonStep>[
      LessonStep(1, '用拇指和食指夹住拨片，露出尖端约 5mm'),
      LessonStep(2, '拨片平面与弦垂直，不要倾斜'),
      LessonStep(3, '手腕放松，靠腕部转动带动扫弦'),
    ],
  ),
  const TextBlock('下扫动作分解'),
  const StepListBlock(
    title: '4 分音符下扫',
    steps: <LessonStep>[
      LessonStep(1, '手腕抬起约 30°，准备向下'),
      LessonStep(2, '腕部向下发力，拨片依次划过 4 根弦'),
      LessonStep(3, '扫完手腕回到初始位置（一上一下算 1 拍）'),
      LessonStep(4, '下扫时食指可以轻微触碰弦根过滤杂音'),
    ],
  ),
  const TextBlock(
    '警告：不要用整条手臂扫弦！初学者最常见的错误是用力过大，导致音色僵硬、手腕酸痛。',
    style: LessonTextStyle.warn,
  ),
];

/// 课程：横按和弦进阶 → 第 1 节 "横按手感练习"
final List<LessonBlock> kBarre1 = <LessonBlock>[
  const TextBlock('横按手感练习', style: LessonTextStyle.title),
  const TextBlock(
    '横按（Barre Chords）是尤克里里进阶的"门槛"——食指同时按住多根弦。掌握后可以弹出几乎所有和弦。',
  ),
  const SvgBlock(
    svgType: SvgType.barre,
    caption: '食指侧边（不是指腹）压在品丝正后方',
    barreStrings: <int>[2, 3],
    otherFingers: <Map<String, dynamic>>[
      <String, dynamic>{'string': 3, 'fret': 2, 'finger': '中'},
      <String, dynamic>{'string': 4, 'fret': 2, 'finger': '无'},
    ],
  ),
  const TextBlock('横按的 3 个核心要点'),
  const StepListBlock(
    title: '要点 1：食指侧边',
    steps: <LessonStep>[
      LessonStep(1, '用食指靠近拇指那一侧的"骨节边缘"按弦'),
      LessonStep(2, '不是用指腹（指肚肉多的部分）'),
      LessonStep(3, '骨节边缘的骨头可以提供更稳定的支撑'),
    ],
  ),
  const StepListBlock(
    title: '要点 2：拇指支撑',
    steps: <LessonStep>[
      LessonStep(1, '左手拇指放在琴颈背面正中央，对应食指位置'),
      LessonStep(2, '拇指与食指形成"夹子"，提供反向压力'),
      LessonStep(3, '不要用拇指单独发力，按压力度来自虎口'),
    ],
  ),
  const StepListBlock(
    title: '要点 3：手腕位置',
    steps: <LessonStep>[
      LessonStep(1, '手腕略向外（朝琴头方向）弯曲'),
      LessonStep(2, '不要过度弯曲，否则食指会因角度问题按不实'),
      LessonStep(3, '可以对着镜子检查手腕姿态'),
    ],
  ),
  const TextBlock(
    '提示：初学横按手指酸痛是正常的，每次练习 5-10 分钟休息，逐步增加时长。',
    style: LessonTextStyle.tip,
  ),
];

/// 课程：指弹独奏入门 → 第 1 节 "指弹拨弦指法"
final List<LessonBlock> kFingerstyle1 = <LessonBlock>[
  const TextBlock('指弹拨弦指法（PIMA）', style: LessonTextStyle.title),
  const TextBlock(
    '指弹（Fingerstyle）是不用拨片，用手指直接拨弦。右手 4 个手指各有分工，国际通用名称是 PIMA。',
  ),
  const SvgBlock(
    svgType: SvgType.pima,
    caption: '右手 4 指分工：P=拇指 I=食指 M=中指 A=无名指',
  ),
  const TextBlock('4 指分工'),
  const StepListBlock(
    title: 'PIMA 对照表',
    steps: <LessonStep>[
      LessonStep(1, 'P（Pulgar/拇指）：负责 4 弦、3 弦根音'),
      LessonStep(2, 'I（Indice/食指）：负责 2 弦'),
      LessonStep(3, 'M（Medio/中指）：负责 1 弦'),
      LessonStep(4, 'A（Anular/无名指）：备用，偶尔弹高音'),
    ],
  ),
  const TextBlock('4 指独立性练习（每天 5 分钟）'),
  const StepListBlock(
    title: '独立练习 4 步',
    steps: <LessonStep>[
      LessonStep(1, 'P 单独拨 4 弦 → 重复 10 次，注意音量和音色'),
      LessonStep(2, 'I 单独拨 2 弦 → 重复 10 次'),
      LessonStep(3, 'M 单独拨 1 弦 → 重复 10 次'),
      LessonStep(4, 'A 单独拨 1 弦（轻拨）→ 重复 10 次'),
    ],
  ),
  const TextBlock('常见错误'),
  const StepListBlock(
    title: '避免这 4 个坑',
    steps: <LessonStep>[
      LessonStep(1, '指甲太长：拨弦时指甲会卡弦，影响音色，建议剪短'),
      LessonStep(2, '手指入弦太深：力度过大导致音色僵硬'),
      LessonStep(3, '手腕僵硬：所有动作要靠指关节，不是手腕'),
      LessonStep(4, '4 指同时发力：注意时序，每指独立起落'),
    ],
  ),
  const TextBlock(
    '提示：指弹初期会有"四指打架"的感觉，正常！坚持每天 10 分钟独立练习，2 周后会有明显改善。',
    style: LessonTextStyle.tip,
  ),
];

/// 6 节核心内容索引（按 lessonId 查）
final Map<String, List<LessonBlock>> kCoreLessonContent =
    <String, List<LessonBlock>>{
  'intro-uke-1': kIntroUke1,
  'intro-uke-2': kIntroUke2,
  'intro-uke-3': kIntroUke3,
  'intro-uke-4': kIntroUke4,
  'intro-uke-5': kIntroUke5,
  'intro-uke-6': kIntroUke6,
  'rhythm-basic-1': kRhythmBasic1,
  'rhythm-basic-2': kRhythmBasic2,
  'rhythm-basic-3': kRhythmBasic3,
  'rhythm-basic-4': kRhythmBasic4,
  'first-chord-prog-1': kFirstChord1,
  'first-chord-prog-2': kFirstChord2,
  'first-chord-prog-3': kFirstChord3,
  'strumming-1': kStrumming1,
  'strumming-2': kStrumming2,
  'strumming-3': kStrumming3,
  'strumming-4': kStrumming4,
  'strumming-5': kStrumming5,
  'barre-1': kBarre1,
  'barre-2': kBarre2,
  'barre-3': kBarre3,
  'barre-4': kBarre4,
  'fingerstyle-1': kFingerstyle1,
  'fingerstyle-2': kFingerstyle2,
  'fingerstyle-3': kFingerstyle3,
  'fingerstyle-4': kFingerstyle4,
  'fingerstyle-5': kFingerstyle5,
};

/// 是否是核心内容节
bool hasCoreContent(String lessonId) =>
    kCoreLessonContent.containsKey(lessonId);

/// 获取核心内容
List<LessonBlock>? getCoreContent(String lessonId) =>
    kCoreLessonContent[lessonId];

// ============== 启蒙：尤克里里入门 第 2-6 节 ==============

/// intro-uke-2: 标准调弦 GCEA
final List<LessonBlock> kIntroUke2 = <LessonBlock>[
  const TextBlock('标准调弦 GCEA', style: LessonTextStyle.title),
  const TextBlock(
    '新琴买回来，第一件事就是调弦。音不准，弹什么都会难听。标准调弦下，从第 4 弦到第 1 弦依次是 G-C-E-A，所以叫"四弦 GCEA"。',
  ),
  const SvgBlock(
    svgType: SvgType.tuner,
    caption: '从左到右（从粗到细）：G - C - E - A',
    noteName: 'G',
    cents: -15,
  ),
  const TextBlock('调弦前的准备'),
  const StepListBlock(
    title: '调弦 4 步',
    steps: <LessonStep>[
      LessonStep(1, '下载一个手机调音 APP（如 GuitarTuna），或用我们 App 自带的"调音器"功能'),
      LessonStep(2, '把琴头朝左、琴身朝右放置，调弦旋钮（peg）在你正前方'),
      LessonStep(3, '每根弦拨一下，对照 APP 显示的目标音名（G/C/E/A）'),
      LessonStep(4, '拧旋钮：低了往紧（顺时针），高了往松（逆时针），慢慢调'),
    ],
  ),
  const TextBlock('常见调弦错误'),
  const StepListBlock(
    title: '避免 3 个坑',
    steps: <LessonStep>[
      LessonStep(1, '一次拧太急：弦断裂或音跑得太远，应该慢慢拧'),
      LessonStep(2, '只调一根：换新弦后所有弦都会跑音，需要反复调几遍'),
      LessonStep(3, '不检查张力：调好后用拨片轻弹，确认弦不会被按弯'),
    ],
  ),
  const TextBlock(
    '提示：每天弹琴前先调一次，金属弦会因温度、湿度变化跑音，特别是冬天。',
    style: LessonTextStyle.tip,
  ),
];

/// intro-uke-3: 正确持琴姿势
final List<LessonBlock> kIntroUke3 = <LessonBlock>[
  const TextBlock('正确持琴姿势', style: LessonTextStyle.title),
  const TextBlock(
    '持琴姿势直接影响弹奏手感和长时间练习的舒适度。错误姿势会导致手腕酸痛、按弦无力。',
  ),
  const SvgBlock(
    svgType: SvgType.handGrip,
    caption: '右手前臂搭在琴身上方约 1/3 处',
  ),
  const TextBlock('右手持琴'),
  const StepListBlock(
    title: '3 个要点',
    steps: <LessonStep>[
      LessonStep(1, '前臂（手腕到肘）放松搭在琴身上侧边缘'),
      LessonStep(2, '手掌轻贴琴身下方，仅作稳定用，不要用力压'),
      LessonStep(3, '手腕可以自由上下摆动（不卡死）'),
    ],
  ),
  const TextBlock('左手持琴'),
  const StepListBlock(
    title: '3 个要点',
    steps: <LessonStep>[
      LessonStep(1, '琴颈用虎口（拇指和食指之间）轻握，不要捏紧'),
      LessonStep(2, '琴颈与水平方向约成 15-30° 仰角（不是平躺）'),
      LessonStep(3, '手腕略向外弯（朝琴头方向），与前臂略成角度'),
    ],
  ),
  const TextBlock(
    '提示：坐姿也要注意——椅子高度让大腿与地面平行，双脚平放地面。',
    style: LessonTextStyle.tip,
  ),
  const TextBlock(
    '警告：千万不要"夹琴"——用下巴或肩膀夹住琴头再压肚子。这会让长时间练习极度疲劳。',
    style: LessonTextStyle.warn,
  ),
];

/// intro-uke-4: 单音练习：C / A / F
final List<LessonBlock> kIntroUke4 = <LessonBlock>[
  const TextBlock('单音练习：C / A / F', style: LessonTextStyle.title),
  const TextBlock(
    '单音是最基础的练习——只弹一根弦上的一个位置，不按和弦。这能让你熟悉指板布局和按弦力度。',
  ),
  const ImageBlock(
    emoji: '🎯',
    gradient: <Color>[Color(0xFFFFB74D), Color(0xFFFFCC80)],
    caption: '3 个音：C4（do）、A4（la）、F4（fa）',
  ),
  const TextBlock('3 个入门音的位置'),
  const StepListBlock(
    title: '单音指法',
    steps: <LessonStep>[
      LessonStep(1, 'C4（do）：1 弦 3 品，无名指按'),
      LessonStep(2, 'A4（la）：1 弦开弦（不按），右手拨 1 弦'),
      LessonStep(3, 'F4（fa）：4 弦 1 品，食指按'),
    ],
  ),
  const TextBlock('单音练习步骤'),
  const StepListBlock(
    title: 'C / A / F 循环 4 步',
    steps: <LessonStep>[
      LessonStep(1, '找音：左手准确按到指定品，靠近品丝但不越过'),
      LessonStep(2, '拨弦：右手食指或拇指拨对应的弦'),
      LessonStep(3, '听音：确认清晰饱满，没有"嗡嗡"的杂音'),
      LessonStep(4, '循环：C-A-F-A，每个音弹 2 拍，重复 5 分钟'),
    ],
  ),
  const TextBlock(
    '提示："找不到音"或"按不实"是正常的，多练几周指尖会长茧，按弦会更准。',
    style: LessonTextStyle.tip,
  ),
];

/// intro-uke-5: 第一个和弦：C / Am
final List<LessonBlock> kIntroUke5 = <LessonBlock>[
  const TextBlock('第一个和弦：C / Am', style: LessonTextStyle.title),
  const TextBlock(
    'C 和 Am 是两个最容易按的和弦——只用一根手指，其他 3 根弦全部开弦。这两个和弦可以弹很多入门曲目。',
  ),
  const ImageBlock(
    emoji: '🎹',
    gradient: <Color>[Color(0xFF66BB6A), Color(0xFFA5D6A7)],
    caption: 'C = 无名指 1 弦 3 品；Am = 全空弦',
  ),
  const TextBlock('C 和弦指法'),
  const StepListBlock(
    title: 'C 按法 3 步',
    steps: <LessonStep>[
      LessonStep(1, '无名指按第 1 弦（最细）3 品，其他弦不碰'),
      LessonStep(2, '右手依次拨 4 弦、3 弦、2 弦、1 弦，听音色清晰'),
      LessonStep(3, '如果某根弦没声音，是手指误碰到其他弦'),
    ],
  ),
  const TextBlock('Am 和弦指法'),
  const StepListBlock(
    title: 'Am 按法 2 步',
    steps: <LessonStep>[
      LessonStep(1, '所有弦都开弦（左手完全不碰琴颈）'),
      LessonStep(2, '右手拨 4 弦：发出 A 音（这就是 Am 的根音）'),
    ],
  ),
  const TextBlock('C 和 Am 切换练习'),
  const StepListBlock(
    title: '切换 5 步',
    steps: <LessonStep>[
      LessonStep(1, '先熟练按 C（无名指就位）'),
      LessonStep(2, '再熟练按 Am（无名指抬起来离开琴颈）'),
      LessonStep(3, 'C-Am 慢速切换，每拍切一次'),
      LessonStep(4, '目标：用 1 秒完成切换'),
      LessonStep(5, '熟练后扫 4 根弦听和弦音'),
    ],
  ),
  const TextBlock(
    '提示：切换和弦时，左手肩膀要放松——紧张会让手指僵硬，速度上不去。',
    style: LessonTextStyle.tip,
  ),
];

/// intro-uke-6: 简单曲目：小星星
final List<LessonBlock> kIntroUke6 = <LessonBlock>[
  const TextBlock('简单曲目：小星星', style: LessonTextStyle.title),
  const TextBlock(
    '用刚学的 C 和 Am 两个和弦，弹一首完整的《小星星》！这是绝大多数尤克里里学习者的第一首完整曲目。',
  ),
  const ImageBlock(
    emoji: '⭐',
    gradient: <Color>[Color(0xFFFFD54F), Color(0xFFFFF176)],
    caption: 'Twinkle Twinkle Little Star',
  ),
  const TextBlock('原版简谱：1 1 5 5 6 6 5 -'),
  const StepListBlock(
    title: '旋律对和弦',
    steps: <LessonStep>[
      LessonStep(1, '"1" = do（C 大调里 = C 和弦）'),
      LessonStep(2, '"5" = sol（C 大调里 = C 和弦）'),
      LessonStep(3, '"6" = la（用 F 和弦效果最好，但本课只用 C/Am，la 用 C 也行）'),
      LessonStep(4, '"-" = 休止符（一拍不发声）'),
    ],
  ),
  const TextBlock('C 和 Am 分配'),
  const StepListBlock(
    title: '4-2-2 节拍配和弦',
    steps: <LessonStep>[
      LessonStep(1, '前 4 拍：1 1 5 5 → 全部 C 和弦'),
      LessonStep(2, '5-6 拍：6 6 → 切到 Am 和弦'),
      LessonStep(3, '7 拍：5 - → 回到 C 和弦（"5" 配 C，"-" 仍是 C）'),
      LessonStep(4, '整曲反复 2 次，第二次可以加 F 和弦'),
    ],
  ),
  const TextBlock(
    '提示：弹《小星星》时，嘴里可以跟着唱旋律——这是"弹唱"练习的起点。',
    style: LessonTextStyle.tip,
  ),
  const TextBlock('下一步：'),
  const StepListBlock(
    title: '完成本课后',
    steps: <LessonStep>[
      LessonStep(1, '进入"曲谱库"找更多公开曲目实战'),
      LessonStep(2, '进入"AI 陪练"用我们的实时评分功能巩固'),
      LessonStep(3, '进入"节奏基础"课程学习 BPM 和节拍'),
    ],
  ),
];

// ============== 节奏基础 第 2-4 节 ==============

/// rhythm-basic-2: 4/4 拍号怎么数
final List<LessonBlock> kRhythmBasic2 = <LessonBlock>[
  const TextBlock('4/4 拍号怎么数', style: LessonTextStyle.title),
  const TextBlock(
    '拍号是乐谱开头的"分数"，告诉你"每小节几拍、以几分音符为 1 拍"。4/4 是流行乐、儿歌最常见的拍号。',
  ),
  const ImageBlock(
    emoji: '🕓',
    gradient: <Color>[Color(0xFF7986CB), Color(0xFF64B5F6)],
    caption: '4/4 拍：每小节 4 拍，以 4 分音符为 1 拍',
  ),
  const TextBlock('怎么读 4/4'),
  const StepListBlock(
    title: '4/4 解读',
    steps: <LessonStep>[
      LessonStep(1, '上面 4 = "每小节 4 拍"'),
      LessonStep(2, '下面 4 = "以 4 分音符为 1 拍"'),
      LessonStep(3, '通俗讲：每小节打 4 下，每下 = 1 个 4 分音符'),
    ],
  ),
  const TextBlock('强拍与弱拍'),
  const StepListBlock(
    title: '口诀：强 弱 次强 弱',
    steps: <LessonStep>[
      LessonStep(1, '第 1 拍强（重音）'),
      LessonStep(2, '第 2 拍弱（轻音）'),
      LessonStep(3, '第 3 拍次强（中等）'),
      LessonStep(4, '第 4 拍弱（轻音）'),
    ],
  ),
  const TextBlock('数拍练习'),
  const StepListBlock(
    title: '小星星开头数拍',
    steps: <LessonStep>[
      LessonStep(1, '"1 1 5 5" = 强-弱-次强-弱-强-弱-次强-弱（每音 1 拍）'),
      LessonStep(2, '"6 6" = 强-弱（后两个 6，前两拍配 Am）'),
      LessonStep(3, '"5 -" = 强-弱（5 占 1 拍，"-" 占 1 拍休止）'),
      LessonStep(4, '打开节拍器 BPM 80，每拍 = 0.75 秒'),
    ],
  ),
];

/// rhythm-basic-3: 3/4 与 6/8 拍号
final List<LessonBlock> kRhythmBasic3 = <LessonBlock>[
  const TextBlock('3/4 与 6/8 拍号', style: LessonTextStyle.title),
  const TextBlock(
    '除了 4/4，还有两种常见拍号：3/4 是华尔兹、6/8 是摇滚抒情。本节帮你识别它们的"感觉"差异。',
  ),
  const ImageBlock(
    emoji: '💃',
    gradient: <Color>[Color(0xFFBA68C8), Color(0xFFCE93D8)],
    caption: '3/4：强-弱-弱循环；6/8：强-弱-弱-次强-弱-弱循环',
  ),
  const TextBlock('3/4 拍：华尔兹感'),
  const StepListBlock(
    title: '3/4 拍特征',
    steps: <LessonStep>[
      LessonStep(1, '每小节 3 拍，每拍 = 1 个 4 分音符'),
      LessonStep(2, '口诀：强-弱-弱（"嘭-嚓-嚓"）'),
      LessonStep(3, '常见曲目：《蓝色多瑙河》《拉德斯基进行曲》'),
      LessonStep(4, '弹 3 拍时身体可以左右左摇摆'),
    ],
  ),
  const TextBlock('6/8 拍：摇荡感'),
  const StepListBlock(
    title: '6/8 拍特征',
    steps: <LessonStep>[
      LessonStep(1, '每小节 6 拍，但合起来是 2 个大拍（强-弱-弱-次强-弱-弱）'),
      LessonStep(2, '基础单位是 8 分音符'),
      LessonStep(3, '常见曲目：《You Are My Sunshine》、大量摇滚抒情'),
      LessonStep(4, '听感是"摇晃"而不是"一二三"'),
    ],
  ),
  const TextBlock('怎么识别拍号'),
  const StepListBlock(
    title: '听感辨拍号',
    steps: <LessonStep>[
      LessonStep(1, '数首拍：如果首拍是 1 强音，看首小节共几拍'),
      LessonStep(2, '跟着拍手：4 拍每小节拍 4 下，3 拍拍 3 下'),
      LessonStep(3, '听重音位置：3/4 在第 1 拍，6/8 在第 1 和第 4 拍'),
    ],
  ),
];

/// rhythm-basic-4: 节拍器跟拍练习
final List<LessonBlock> kRhythmBasic4 = <LessonBlock>[
  const TextBlock('节拍器跟拍练习', style: LessonTextStyle.title),
  const TextBlock(
    '节拍器是节奏训练的"教练"——它发出稳定的"嘀嗒"声，帮你校准自己的速度。本课教你把它用到极致。',
  ),
  const ImageBlock(
    emoji: '⏲️',
    gradient: <Color>[Color(0xFF42A5F5), Color(0xFF64B5F6)],
    caption: '节拍器响声 = 每一拍 = 一个时间锚点',
  ),
  const TextBlock('节拍器跟拍 4 步'),
  const StepListBlock(
    title: '起步训练',
    steps: <LessonStep>[
      LessonStep(1, '打开 App 内的"节拍器"功能，设 BPM 60（最慢）'),
      LessonStep(2, '每响一声拍一下手（或用拨片敲琴身）'),
      LessonStep(3, '连续 1 分钟，误差控制在 ±50ms 内'),
      LessonStep(4, '逐步提速：BPM 60 → 80 → 100 → 120'),
    ],
  ),
  const TextBlock('分拍练习（4 分音符 + 8 分音符）'),
  const StepListBlock(
    title: '8 分音符',
    steps: <LessonStep>[
      LessonStep(1, '每拍 2 个 8 分音符，每响一声"嘀嗒"分两下（嘀-嗒）'),
      LessonStep(2, 'BPM 60 时，每个 8 分音符 = 0.5 秒'),
      LessonStep(3, '先分拍打：1-2-3-4（每拍打 2 下 = 8 拍/小节）'),
      LessonStep(4, '熟练后正常打，每拍里默数"1-and"'),
    ],
  ),
  const TextBlock(
    '提示：节拍器 App 中有"加重第 1 拍"或"3 拍子"选项，可以练 4/4 和 3/4 不同拍号的节奏。',
    style: LessonTextStyle.tip,
  ),
  const TextBlock(
    '警告：不要在没有节拍器的情况下练节奏！速度忽快忽慢会让你的"内在节拍感"永远练不出来。',
    style: LessonTextStyle.warn,
  ),
];

// ============== 初识和弦进行 第 2-3 节 ==============

/// first-chord-prog-2: 四和弦循环
final List<LessonBlock> kFirstChord2 = <LessonBlock>[
  const TextBlock('四和弦循环', style: LessonTextStyle.title),
  const TextBlock(
    '把 C-Am-F-G 按固定顺序循环弹奏，就是"万能四和弦进行"。它可以套在 70% 以上流行歌的副歌部分。',
  ),
  const ImageBlock(
    emoji: '🔄',
    gradient: <Color>[Color(0xFF66BB6A), Color(0xFFA5D6A7)],
    caption: 'C → Am → F → G → C（回到 C 起头）',
  ),
  const TextBlock('四和弦切换速度训练'),
  const StepListBlock(
    title: '从 1 拍一切到 4 拍一切',
    steps: <LessonStep>[
      LessonStep(1, '第 1 阶段：每和弦弹 4 拍，慢速切换（C-Am-F-G 各 4 拍）'),
      LessonStep(2, '第 2 阶段：每和弦 2 拍（中速，重点在切换）'),
      LessonStep(3, '第 3 阶段：每和弦 1 拍（快速，左手必须稳）'),
      LessonStep(4, '目标：用节拍器 BPM 100，每和弦 1 拍不卡顿'),
    ],
  ),
  const TextBlock('常见变体'),
  const StepListBlock(
    title: '5 种常用循环',
    steps: <LessonStep>[
      LessonStep(1, '顺时针：C - Am - F - G'),
      LessonStep(2, '逆时针：C - G - F - Am（更明亮）'),
      LessonStep(3, '简化版：C - Am - F - F（用 F 拖长）'),
      LessonStep(4, '插入版：C - C - Am - F - G（C 多 1 拍强化主和弦）'),
      LessonStep(5, '爵士版：Cmaj7 - Am7 - Fmaj7 - G7（用七和弦）'),
    ],
  ),
  const TextBlock(
    '提示：练到不卡后，开启"AI 陪练"跟弹功能，让 AI 实时反馈你的音准。',
    style: LessonTextStyle.tip,
  ),
];

/// first-chord-prog-3: 欢乐颂实战
final List<LessonBlock> kFirstChord3 = <LessonBlock>[
  const TextBlock('欢乐颂实战', style: LessonTextStyle.title),
  const TextBlock(
    '贝多芬《欢乐颂》是入门尤克里里最经典的曲目——只用 C/F/G 三个和弦，旋律简单，是检验入门成果的"毕业曲目"。',
  ),
  const ImageBlock(
    emoji: '🎼',
    gradient: <Color>[Color(0xFFFF8A65), Color(0xFFFFAB91)],
    caption: 'Ode to Joy - 公共领域曲目，1808 年贝多芬',
  ),
  const TextBlock('欢乐颂和弦进行'),
  const StepListBlock(
    title: '4-3-3-2 节拍',
    steps: <LessonStep>[
      LessonStep(1, '前 4 拍：C（搭配旋律"3 3 4 5"）'),
      LessonStep(2, '5-7 拍：F（搭配"5 4 3"）'),
      LessonStep(3, '8-10 拍：C（搭配"2 1 2"）'),
      LessonStep(4, '11-12 拍：G - G（搭配"3 - 3 -"，强化属和弦）'),
    ],
  ),
  const TextBlock('完整旋律-和弦对位'),
  const StepListBlock(
    title: '4 行旋律配 3 和弦',
    steps: <LessonStep>[
      LessonStep(1, '第 1 行：3 3 4 5 → C 和弦'),
      LessonStep(2, '第 2 行：5 4 3 2 → F 和弦'),
      LessonStep(3, '第 3 行：1 2 3 - → 回到 C 和弦'),
      LessonStep(4, '副歌: 5 - 4 3 2 1 → C - F - C - G - C'),
    ],
  ),
  const TextBlock(
    '提示：弹这首时务必用 App 内的"AI 陪练"功能——它会告诉你哪一拍音准不准、节奏稳不稳。',
    style: LessonTextStyle.tip,
  ),
];

// ============== 常用扫弦节奏型 第 2-5 节 ==============

/// strumming-2: 4 拍节奏型 D-D-U-U-D-U
final List<LessonBlock> kStrumming2 = <LessonBlock>[
  const TextBlock('4 拍节奏型 D-D-U-U-D-U', style: LessonTextStyle.title),
  const TextBlock(
    '这是流行乐最常用的分解节奏型。6 个动作覆盖 4 拍，看似复杂，拆解后就 4 个核心动作的组合。',
  ),
  const ImageBlock(
    emoji: '🎵',
    gradient: <Color>[Color(0xFF42A5F5), Color(0xFF64B5F6)],
    caption: 'D = Down（下扫），U = Up（上扫），"|" = 重拍',
  ),
  const TextBlock('动作分解'),
  const StepListBlock(
    title: '6 个动作',
    steps: <LessonStep>[
      LessonStep(1, '第 1 拍：D（下扫 4 弦，落到第 1 弦）'),
      LessonStep(2, '第 2 拍：D（下扫，弹 4 弦根音）'),
      LessonStep(3, '第 2 拍半：U（上扫 1 弦和 2 弦）'),
      LessonStep(4, '第 3 拍半：U（上扫 1 弦和 2 弦）'),
      LessonStep(5, '第 4 拍：D（下扫，强音）'),
      LessonStep(6, '第 4 拍半：U（上扫，过渡到下一小节）'),
    ],
  ),
  const TextBlock('慢速练习'),
  const StepListBlock(
    title: '4 步上手',
    steps: <LessonStep>[
      LessonStep(1, '先不拨琴，只做手腕动作：D-D-U-U-D-U（默数每拍）'),
      LessonStep(2, 'BPM 60 慢速拨弦，每动作之间停 1 秒确认'),
      LessonStep(3, '提速到 BPM 80，连续流畅'),
      LessonStep(4, '配上 C 和弦，循环 1 分钟'),
    ],
  ),
  const TextBlock(
    '提示：这个节奏型看着难，练熟后比想象中更省力——核心是手腕"上下上下"的小幅度动作。',
    style: LessonTextStyle.tip,
  ),
];

/// strumming-3: 切音技巧
final List<LessonBlock> kStrumming3 = <LessonBlock>[
  const TextBlock('切音技巧', style: LessonTextStyle.title),
  const TextBlock(
    '切音（Chucking/Muting）= 让某根弦提前停止振动，发出"咔"的短促音。流行乐/摇滚大量使用，能让节奏更"硬朗"。',
  ),
  const ImageBlock(
    emoji: '✋',
    gradient: <Color>[Color(0xFFEF5350), Color(0xFFFF8A80)],
    caption: '右手掌根（小鱼际）轻触弦根，切断振动',
  ),
  const TextBlock('两种切音'),
  const StepListBlock(
    title: '下切音 + 上切音',
    steps: <LessonStep>[
      LessonStep(1, '下切音：右手掌根在下扫后立即轻压 3-4 弦弦根（不拨响）'),
      LessonStep(2, '上切音：左手在扫上时松开按弦 + 右手拇指轻拂 1 弦外侧'),
      LessonStep(3, '两者目的相同：让弦停止振动'),
      LessonStep(4, '常见节奏型 D-D-U-D-U，其中 "-" = 切音'),
    ],
  ),
  const TextBlock('切音手感练习'),
  const StepListBlock(
    title: '3 步上手',
    steps: <LessonStep>[
      LessonStep(1, '先压 C 和弦，右手扫 4 弦（确认每根都响）'),
      LessonStep(2, '扫后立即把掌根压在 3-4 弦上（听"咔"声）'),
      LessonStep(3, '配合 BPM 80 节拍器：扫-压、扫-压、扫-压-扫-压'),
    ],
  ),
  const TextBlock(
    '警告：切音时不要用整只手压在琴身上（闷音），那样会把 4 根弦全切。要"只切当前扫的弦"。',
    style: LessonTextStyle.warn,
  ),
];

/// strumming-4: 附点与连音线
final List<LessonBlock> kStrumming4 = <LessonBlock>[
  const TextBlock('附点与连音线', style: LessonTextStyle.title),
  const TextBlock(
    '附点 = 把音符时长延长半拍；连音线 = 把两个音连成一个。这是让节奏"流动"的关键，不再是"哒哒哒"的机械感。',
  ),
  const ImageBlock(
    emoji: '➕',
    gradient: <Color>[Color(0xFFAB47BC), Color(0xFFCE93D8)],
    caption: '附点 4 分音符 = 1.5 拍；连音线 = 把两个音加起来',
  ),
  const TextBlock('附点音符 3 步'),
  const StepListBlock(
    title: '附点怎么打',
    steps: <LessonStep>[
      LessonStep(1, '4 分音符 = 1 拍'),
      LessonStep(2, '4 分音符 + 附点 = 1 + 0.5 = 1.5 拍'),
      LessonStep(3, '实际数拍：1-and-a（"and"和"a"是 8 分音符的位置）'),
    ],
  ),
  const TextBlock('连音线 3 步'),
  const StepListBlock(
    title: '连音怎么弹',
    steps: <LessonStep>[
      LessonStep(1, '看到两个相同音高的音被弧线连起来，只弹第一个，第二个不发声'),
      LessonStep(2, '时值 = 两个音加起来（如 4 分 + 8 分 = 1.5 拍）'),
      LessonStep(3, '常见表现：拖长某个音，营造"哼一句还没完"的感觉'),
    ],
  ),
  const TextBlock('实战：节奏型 D-D-U-D-U-中的"切音"'),
  const StepListBlock(
    title: '4 小节示范',
    steps: <LessonStep>[
      LessonStep(1, '第 1 拍：D（强，长度 1 拍）'),
      LessonStep(2, '第 2 拍：D（弱，长度 1 拍）'),
      LessonStep(3, '第 3 拍：U（上扫，无附点）'),
      LessonStep(4, '第 4 拍：D + U（连扫，无缝切换）'),
    ],
  ),
];

/// strumming-5: 流行曲实战：小毛驴变奏
final List<LessonBlock> kStrumming5 = <LessonBlock>[
  const TextBlock('流行曲实战：小毛驴变奏', style: LessonTextStyle.title),
  const TextBlock(
    '《小毛驴》是经典儿歌，本课我们给它加一个 4 拍分解节奏型。原本只用 2 个和弦就能弹，加了分解后立刻"高级"。',
  ),
  const ImageBlock(
    emoji: '🐴',
    gradient: <Color>[Color(0xFFFFCA28), Color(0xFFFFE082)],
    caption: '公共领域传统童谣《小毛驴》',
  ),
  const TextBlock('原版 vs 变奏'),
  const StepListBlock(
    title: '难度递进',
    steps: <LessonStep>[
      LessonStep(1, '原版：C - Am - F - G（每和弦 2 拍，2 拍分解为下-下-下-下）'),
      LessonStep(2, '变奏 1：每和弦 4 拍，前两拍 8 分音符 D-D-U-U，后两拍加切音'),
      LessonStep(3, '变奏 2：F 和弦用半拍下扫 + 切音（小毛驴最经典"哒-咔"节奏）'),
      LessonStep(4, '变奏 3：副歌用 D-D-U-D-U-U，主歌用 D-D-D-D（动静结合）'),
    ],
  ),
  const TextBlock('4 小节循环（变奏 2）'),
  const StepListBlock(
    title: '4 小节',
    steps: <LessonStep>[
      LessonStep(1, '第 1 小节：C - D-D-U-U（扫 4 拍）'),
      LessonStep(2, '第 2 小节：Am - D-D-U-U'),
      LessonStep(3, '第 3 小节：F - D-切-D-U-U（"哒-咔-哒-哒-哒"）'),
      LessonStep(4, '第 4 小节：G - D-D-U-U（强调属和弦回 C）'),
    ],
  ),
  const TextBlock(
    '提示：弹熟后试着用"AI 陪练"功能——AI 会告诉你哪一拍节奏不稳，比自己听更准确。',
    style: LessonTextStyle.tip,
  ),
];

// ============== 横按和弦进阶 第 2-4 节 ==============

/// barre-2: F 和弦简化版
final List<LessonBlock> kBarre2 = <LessonBlock>[
  const TextBlock('F 和弦简化版', style: LessonTextStyle.title),
  const TextBlock(
    '完整的 F 大三和弦需要食指横按 1-2 弦 + 中指按 3 弦，对初学者太难。简化版用 Fmaj7 或 2-1-0 三音解决，听感接近 90%。',
  ),
  const ImageBlock(
    emoji: '🤝',
    gradient: <Color>[Color(0xFFEF5350), Color(0xFFFF8A80)],
    caption: '简化 F：2-1-0（4 弦 + 3 弦 + 开 1 弦）',
  ),
  const TextBlock('Fmaj7 替代 Fmaj'),
  const StepListBlock(
    title: 'Fmaj7 按法',
    steps: <LessonStep>[
      LessonStep(1, '中指按 4 弦 2 品'),
      LessonStep(2, '食指按 3 弦 1 品'),
      LessonStep(3, '2 弦和 1 弦开弦'),
      LessonStep(4, '听感：少一个"中音 do"，听上去偏 funk 但能替代 F'),
    ],
  ),
  const TextBlock('F 完整版 vs 简化版'),
  const StepListBlock(
    title: '何时用哪个',
    steps: <LessonStep>[
      LessonStep(1, '初学 1-3 个月：用 Fmaj7（食指 + 中指 2 根搞定）'),
      LessonStep(2, '横按熟练后：用完整 Fmaj（含食指横按）'),
      LessonStep(3, '演奏儿歌/民谣：用 Fmaj7 够用'),
      LessonStep(4, '演奏流行乐副歌：用完整 Fmaj 更饱满'),
    ],
  ),
  const TextBlock(
    '提示：进阶过程中交替使用两种 F，每周用完整版的次数逐渐增加，直到完全掌握横按。',
    style: LessonTextStyle.tip,
  ),
];

/// barre-3: Bm 和弦
final List<LessonBlock> kBarre3 = <LessonBlock>[
  const TextBlock('Bm 和弦', style: LessonTextStyle.title),
  const TextBlock(
    'Bm（Si 小调）是横按和弦的代表——食指横按 1-2 弦 + 无名指按 3 弦 + 中指按 4 弦。掌握 Bm 后能弹大量流行抒情歌。',
  ),
  const ImageBlock(
    emoji: '🎼',
    gradient: <Color>[Color(0xFFEF5350), Color(0xFFFF8A80)],
    caption: 'Bm: 食指横按 1-2 弦 + 3 弦中指 2 品 + 4 弦无名指 2 品',
  ),
  const TextBlock('Bm 完整按法（4 步）'),
  const StepListBlock(
    title: 'Bm 4 步上手',
    steps: <LessonStep>[
      LessonStep(1, '食指横按 2 弦 2 品（骨节边缘压在品丝正后方 0.5cm）'),
      LessonStep(2, '中指按 3 弦 2 品（紧贴食指旁边）'),
      LessonStep(3, '无名指按 4 弦 2 品（保证横按 + 中指 + 无名指 3 指都在 2 品）'),
      LessonStep(4, '拇指放在琴颈背面正中央，虎口夹紧'),
    ],
  ),
  const TextBlock('常见错误 4 个'),
  const StepListBlock(
    title: '避免这些',
    steps: <LessonStep>[
      LessonStep(1, '食指按偏：太靠近品丝中央 → 闷音；刚好在品丝旁 0.5cm → 清晰'),
      LessonStep(2, '拇指没夹紧：仅靠食指自己力气按不住，需要虎口辅助'),
      LessonStep(3, '手腕太直：略微朝琴头弯，让食指能垂直按下去'),
      LessonStep(4, '按的时间太久：练 30 秒就休息，避免手指僵硬'),
    ],
  ),
];

/// barre-4: 横按转换练习
final List<LessonBlock> kBarre4 = <LessonBlock>[
  const TextBlock('横按转换练习', style: LessonTextStyle.title),
  const TextBlock(
    '横按单点按住还不够，要把横按作为"切换根音"的能力。本课教你 F → C → G → Am 的横按快速转换。',
  ),
  const ImageBlock(
    emoji: '⚡',
    gradient: <Color>[Color(0xFFFF7043), Color(0xFFFFAB91)],
    caption: 'F → C → G → Am 是横按金标准循环',
  ),
  const TextBlock('为什么这个循环'),
  const StepListBlock(
    title: '3 个原因',
    steps: <LessonStep>[
      LessonStep(1, 'F 需要食指横按，C/G/Am 都不需要——形成"有横按"和"无横按"的切换'),
      LessonStep(2, '4 个和弦刚好覆盖流行乐 70% 和弦'),
      LessonStep(3, '食指要在 F 时横按、C/G/Am 时离开，是手感恢复训练'),
    ],
  ),
  const TextBlock('分阶段训练'),
  const StepListBlock(
    title: '3 阶段',
    steps: <LessonStep>[
      LessonStep(1, '阶段 1（BPM 60）：每和弦 2 拍，确保 F 时横按清晰'),
      LessonStep(2, '阶段 2（BPM 90）：每和弦 1 拍，练习食指"快速恢复"'),
      LessonStep(3, '阶段 3（BPM 120）：循环 2 分钟不卡顿'),
    ],
  ),
  const TextBlock(
    '提示：F 时食指横按离开琴颈需要"手指颤动"，可以练"食指 5 秒按下 - 抬起 - 按下"循环。',
    style: LessonTextStyle.tip,
  ),
  const TextBlock('BPM 切换练习流程'),
  const StepListBlock(
    title: '具体步骤',
    steps: <LessonStep>[
      LessonStep(1, '打开节拍器 BPM 60，每响一声切一个和弦'),
      LessonStep(2, '右手只扫 4 弦根音（不要弹太多音），减少噪音干扰'),
      LessonStep(3, '关注每一次 F：食指能否 1 秒内完成横按到位'),
      LessonStep(4, 'BPM 提 10 重复，直到 BPM 100'),
    ],
  ),
];

// ============== 指弹独奏入门 第 2-5 节 ==============

/// fingerstyle-2: 分解和弦练习
final List<LessonBlock> kFingerstyle2 = <LessonBlock>[
  const TextBlock('分解和弦练习', style: LessonTextStyle.title),
  const TextBlock(
    '分解和弦 = 把和弦的 4 个音"按顺序"逐个弹出，而不是同时响。最常用节奏型是 1-3-2-4(T-3-2-1)，适合所有 4 和弦。',
  ),
  const ImageBlock(
    emoji: '🎶',
    gradient: <Color>[Color(0xFF7E57C2), Color(0xFFB39DDB)],
    caption: '1-3-2-4：拇指(1)→食指(3)→中指(2)→无名指(4)',
  ),
  const TextBlock('4 指分工详解'),
  const StepListBlock(
    title: 'T-3-2-1 国际标准',
    steps: <LessonStep>[
      LessonStep(1, 'T(Thumb/拇指)：弹 4 弦根音，控制节奏'),
      LessonStep(2, '3(Index/食指)：弹 3 弦，提供和声'),
      LessonStep(3, '2(Middle/中指)：弹 2 弦，进一步丰富'),
      LessonStep(4, '1(Ring/无名指)：弹 1 弦高音，最亮'),
    ],
  ),
  const TextBlock('4 步上手 1-3-2-4 节奏型'),
  const StepListBlock(
    title: 'C 和弦分解',
    steps: <LessonStep>[
      LessonStep(1, '按好 C 和弦（无名指 1 弦 3 品，其他开弦）'),
      LessonStep(2, 'T 拨 4 弦，发出 C 根音'),
      LessonStep(3, '3 拨 3 弦，发出 E'),
      LessonStep(4, '2 拨 2 弦，发出 G；1 拨 1 弦（按的 C 音）'),
    ],
  ),
  const TextBlock(
    '提示：T-3-2-1 是国际通用，左手按和弦不变，只动右手。练熟后再换 G、Am、F 等和弦。',
    style: LessonTextStyle.tip,
  ),
];

/// fingerstyle-3: 旋律与和弦混合
final List<LessonBlock> kFingerstyle3 = <LessonBlock>[
  const TextBlock('旋律与和弦混合', style: LessonTextStyle.title),
  const TextBlock(
    '指弹的精髓——拇指弹根音（保持节奏），其他 3 指弹旋律音（走主旋律）。这样一把琴就能同时"伴奏+主唱"两个角色。',
  ),
  const ImageBlock(
    emoji: '🎼',
    gradient: <Color>[Color(0xFF7E57C2), Color(0xFFB39DDB)],
    caption: '根音（T）+ 主旋律（3-2-1）= 伴奏+旋律',
  ),
  const TextBlock('混合指弹 3 步'),
  const StepListBlock(
    title: '指弹核心',
    steps: <LessonStep>[
      LessonStep(1, '拇指（T）只管 4 弦，每拍弹 1 次，建立节奏骨架'),
      LessonStep(2, '3-2-1 弹主旋律音（不是和弦音！是旋律里该出现的音）'),
      LessonStep(3, '旋律音可以是和弦的组成音，也可以不是——听感对了就行'),
    ],
  ),
  const TextBlock('小星星指弹示范'),
  const StepListBlock(
    title: '前 4 拍',
    steps: <LessonStep>[
      LessonStep(1, '第 1 拍：T 弹 4 弦 C 根音 + 3 弹 3 弦（C 音）'),
      LessonStep(2, '第 2 拍：T 弹 4 弦 C 根音 + 3 弹 3 弦（再次 C）'),
      LessonStep(3, '第 3 拍：T 弹 4 弦 C 根音 + 2 弹 2 弦（G 音 - 旋律"5"）'),
      LessonStep(4, '第 4 拍：T 弹 4 弦 C 根音 + 2 弹 2 弦（再次 G）'),
    ],
  ),
  const TextBlock(
    '提示：刚开始听起来和弦"只有根音+旋律"，会觉得怪。练熟后你会爱上这种"一架琴独奏"的感觉。',
    style: LessonTextStyle.tip,
  ),
];

/// fingerstyle-4: 勾击弦 (Hammer-on / Pull-off)
final List<LessonBlock> kFingerstyle4 = <LessonBlock>[
  const TextBlock('勾击弦 (Hammer-on / Pull-off)', style: LessonTextStyle.title),
  const TextBlock(
    '勾击弦是左手在琴颈上的"独立动作"——不拨弦也能发出声音，让旋律更连贯流畅。是区分"会弹琴"和"会演奏"的关键技巧。',
  ),
  const ImageBlock(
    emoji: '⚒️',
    gradient: <Color>[Color(0xFF7E57C2), Color(0xFFB39DDB)],
    caption: 'H = Hammer-on（击弦）；P = Pull-off（勾弦）',
  ),
  const TextBlock('Hammer-on 击弦'),
  const StepListBlock(
    title: 'H 怎么弹',
    steps: <LessonStep>[
      LessonStep(1, '拨片/手指拨响低品位音（如 1 弦开弦）'),
      LessonStep(2, '紧接着左手另一手指快速"砸"到高品位音（如 1 弦 2 品）'),
      LessonStep(3, '听到从低到高"滑上去"的连贯音'),
      LessonStep(4, '力度要求：击弦指要"砸下去"，不是轻轻放'),
    ],
  ),
  const TextBlock('Pull-off 勾弦'),
  const StepListBlock(
    title: 'P 怎么弹',
    steps: <LessonStep>[
      LessonStep(1, '先按好两个音（如 1 弦 3 品 + 1 弦 1 品）'),
      LessonStep(2, '拨片拨响高品位（3 品）'),
      LessonStep(3, '左手按高品位的指"勾开" → 1 弦 1 品的音自动响起'),
      LessonStep(4, '关键动作：左指向斜下方拨弦（不是单纯抬起）'),
    ],
  ),
  const TextBlock('勾击常用于哪'),
  const StepListBlock(
    title: '适用场景',
    steps: <LessonStep>[
      LessonStep(1, '连续相同弦上的音（如 1 弦 1 品 → 1 弦 3 品）'),
      LessonStep(2, '拖长某个音，营造"流水感"'),
      LessonStep(3, '指弹独奏里大量使用，弹拨结合节省右手动作'),
    ],
  ),
];

/// fingerstyle-5: 指弹曲目：《River Flows in You》
final List<LessonBlock> kFingerstyle5 = <LessonBlock>[
  const TextBlock('指弹曲目：《River Flows in You》', style: LessonTextStyle.title),
  const TextBlock(
    'Yiruma 的《River Flows in You》是尤克里里指弹的"毕业曲目"——旋律优美，且指法相对简单（只用 C/Am/F/G 四个和弦）。',
  ),
  const ImageBlock(
    emoji: '🌊',
    gradient: <Color>[Color(0xFF7E57C2), Color(0xFFB39DDB)],
    caption: 'River Flows in You - Yiruma (Korean composer)',
  ),
  const TextBlock('曲目结构'),
  const StepListBlock(
    title: '5 段',
    steps: <LessonStep>[
      LessonStep(1, '前奏：4 小节分解 C（每拍只弹 4 弦，建立氛围）'),
      LessonStep(2, 'A 段（主旋律进）：用 T-3-2-1 节奏型，C 和 Am 切换'),
      LessonStep(3, 'B 段：F 和 G 进入，旋律升高'),
      LessonStep(4, 'A 段重复：用同样的 4 和弦循环'),
      LessonStep(5, '尾声：慢下来，每拍 2 秒，只用 T 拨 4 弦'),
    ],
  ),
  const TextBlock('完整指弹示范（头 2 小节）'),
  const StepListBlock(
    title: '具体指法',
    steps: <LessonStep>[
      LessonStep(1, '第 1 小节：C 和弦，T 拨 4 弦（每拍 1 次，共 4 次）'),
      LessonStep(2, '第 1 小节附加：3-2-1 在第 4 拍快速拨 3-2-1（高音旋律）'),
      LessonStep(3, '第 2 小节：换 Am，T 拨 4 弦开弦（空根音）'),
      LessonStep(4, '第 2 小节附加：同样 3-2-1 拨高音旋律'),
    ],
  ),
  const TextBlock(
    '提示：完整版在指弹教材里有。这里只展示框架——重点是体会"单独一架琴演奏整首曲子"的感觉。',
    style: LessonTextStyle.tip,
  ),
];