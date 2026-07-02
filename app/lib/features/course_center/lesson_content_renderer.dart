/// 课程节内容渲染器
library;

import 'package:flutter/material.dart';

import 'lesson_content.dart';

/// 渲染 LessonBlock 列表
class LessonContentRenderer extends StatelessWidget {
  const LessonContentRenderer({super.key, required this.blocks});
  final List<LessonBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < blocks.length; i++) ...<Widget>[
          _BlockView(block: blocks[i]),
          if (i < blocks.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block});
  final LessonBlock block;

  @override
  Widget build(BuildContext context) {
    if (block is TextBlock) {
      return _TextBlockView(block: block as TextBlock);
    }
    if (block is ImageBlock) {
      return _ImageBlockView(block: block as ImageBlock);
    }
    if (block is StepListBlock) {
      return _StepListBlockView(block: block as StepListBlock);
    }
    return const SizedBox.shrink();
  }
}

// ============== TextBlock 渲染 ==============
class _TextBlockView extends StatelessWidget {
  const _TextBlockView({required this.block});
  final TextBlock block;

  @override
  Widget build(BuildContext context) {
    switch (block.style) {
      case LessonTextStyle.title:
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text(
            block.text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        );
      case LessonTextStyle.body:
        return Text(
          block.text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.black87,
          ),
        );
      case LessonTextStyle.tip:
        return _TipBox(
          icon: Icons.lightbulb_outline,
          iconColor: Colors.amber.shade700,
          bgColor: Colors.amber.shade50,
          borderColor: Colors.amber.shade200,
          text: block.text,
        );
      case LessonTextStyle.warn:
        return _TipBox(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red.shade700,
          bgColor: Colors.red.shade50,
          borderColor: Colors.red.shade200,
          text: block.text,
        );
    }
  }
}

class _TipBox extends StatelessWidget {
  const _TipBox({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.text,
  });
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: iconColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== ImageBlock 渲染 ==============
class _ImageBlockView extends StatelessWidget {
  const _ImageBlockView({required this.block});
  final ImageBlock block;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: block.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 18),
          // 大 emoji
          Text(
            block.emoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 8),
          // 装饰 icon
          Icon(block.icon, size: 28, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(height: 14),
          // 图说（白色半透明背景）
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              block.caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ============== StepListBlock 渲染 ==============
class _StepListBlockView extends StatelessWidget {
  const _StepListBlockView({required this.block});
  final StepListBlock block;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              block.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          for (int i = 0; i < block.steps.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${block.steps[i].index}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.steps[i].text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}