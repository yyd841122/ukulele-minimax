import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';

/// 节拍器音频播放器
///
/// 职责：
/// 1. 预加载"首拍重音"和"普通拍"两个 WAV 资源
/// 2. 提供 playAccent() / playNormal() 两个接口
/// 3. 适配 BPM 60-240 的精确计时
///
/// 设计选择：用 just_audio 播放 AssetSource
/// 优点：包已装、跨平台一致、低延迟
/// 缺点：每个 click 创建一个新 Player（毫秒级开销，可接受）
class MetronomeClickPlayer {
  MetronomeClickPlayer();

  final AudioPlayer _accentPlayer = AudioPlayer();
  final AudioPlayer _normalPlayer = AudioPlayer();

  bool _preloaded = false;

  /// 预加载音频资源（必须在第一次播放前调用）
  Future<void> preload() async {
    if (_preloaded) return;
    try {
      await Future.wait<void>(<Future<void>>[
        _accentPlayer.setAsset('assets/audio/click_accent.wav'),
        _normalPlayer.setAsset('assets/audio/click_normal.wav'),
      ]);
      _preloaded = true;
    } catch (e) {
      // 静默失败：资源加载失败时退化为无音模式
      _preloaded = false;
    }
  }

  /// 播放首拍重音
  Future<void> playAccent() async {
    if (!_preloaded) await preload();
    if (!_preloaded) return;
    try {
      await _accentPlayer.seek(Duration.zero);
      await _accentPlayer.play();
    } catch (_) {
      // 单次播放失败不影响节拍器继续运行
    }
  }

  /// 播放普通节拍音
  Future<void> playNormal() async {
    if (!_preloaded) await preload();
    if (!_preloaded) return;
    try {
      await _normalPlayer.seek(Duration.zero);
      await _normalPlayer.play();
    } catch (_) {
      // 同上
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await _accentPlayer.dispose();
    await _normalPlayer.dispose();
  }
}

/// 预加载入口（可在 App 启动时调用）
Future<void> preloadMetronomeClicks() async {
  // 触发 lazy 初始化：首次访问 MetronomeClickPlayer 不会自动 preload
  // 这里显式调用以确保启动期资源就绪
  final MetronomeClickPlayer player = MetronomeClickPlayer();
  await player.preload();
  await player.dispose();
  // 验证资源存在
  await rootBundle.load('assets/audio/click_accent.wav');
  await rootBundle.load('assets/audio/click_normal.wav');
}