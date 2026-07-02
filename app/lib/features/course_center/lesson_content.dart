/// 课程节内容块（图文教程 MVP）
///
/// 全部原创内容，基于通用尤克里里通识知识 + 公共领域曲谱
/// 不引用任何外部资源
library;

import 'package:flutter/material.dart';

/// 文本样式类型
enum LessonTextStyle { title, body, tip, warn }

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
  const ImageBlock(
    emoji: '🎸',
    gradient: <Color>[Color(0xFFFFB74D), Color(0xFFFF8A65)],
    caption: '标准 21 品 soprano 尤克里里（约 53 cm）',
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
  const ImageBlock(
    emoji: '🎵',
    gradient: <Color>[Color(0xFF66BB6A), Color(0xFFA5D6A7)],
    caption: 'C → Am → F → G 是流行乐的经典进行',
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
  const ImageBlock(
    emoji: '🎯',
    gradient: <Color>[Color(0xFF42A5F5), Color(0xFF64B5F6)],
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
  const ImageBlock(
    emoji: '💪',
    gradient: <Color>[Color(0xFFEF5350), Color(0xFFFF8A80)],
    caption: '食指侧边（不是指腹）压在品丝正后方',
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
  const ImageBlock(
    emoji: '🖐️',
    gradient: <Color>[Color(0xFF7E57C2), Color(0xFFB39DDB)],
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
  'rhythm-basic-1': kRhythmBasic1,
  'first-chord-prog-1': kFirstChord1,
  'strumming-1': kStrumming1,
  'barre-1': kBarre1,
  'fingerstyle-1': kFingerstyle1,
};

/// 是否是核心内容节
bool hasCoreContent(String lessonId) =>
    kCoreLessonContent.containsKey(lessonId);

/// 获取核心内容
List<LessonBlock>? getCoreContent(String lessonId) =>
    kCoreLessonContent[lessonId];