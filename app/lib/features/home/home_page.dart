import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';

/// App 首页：四大核心功能入口
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text(AppConstants.appName),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: <Widget>[
              _FeatureCard(
                icon: Icons.tune,
                title: '调音器',
                subtitle: 'AI 智能调音',
                color: Colors.teal,
                onTap: () => context.push(AppRoutes.tuner),
              ),
              _FeatureCard(
                icon: Icons.timer,
                title: '节拍器',
                subtitle: '自定义 BPM',
                color: Colors.orange,
                onTap: () => context.push(AppRoutes.metronome),
              ),
              _FeatureCard(
                icon: Icons.queue_music,
                title: '曲谱库',
                subtitle: '110+ 首',
                color: Colors.purple,
                onTap: () => context.push(AppRoutes.sheets),
              ),
              _FeatureCard(
                icon: Icons.school,
                title: '课程中心',
                subtitle: '启蒙→高阶',
                color: Colors.indigo,
                onTap: () => context.push(AppRoutes.courseCenter),
              ),
              _FeatureCard(
                icon: Icons.smart_toy,
                title: 'AI 陪练',
                subtitle: '实时评分',
                color: Colors.pink,
                onTap: () => context.push(AppRoutes.aiCoach),
              ),
              _FeatureCard(
                icon: Icons.public,
                title: '发现区',
                subtitle: '学员成果',
                color: Colors.cyan,
                onTap: () => context.push(AppRoutes.discover),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}