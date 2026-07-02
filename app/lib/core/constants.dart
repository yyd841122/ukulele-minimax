/// 全局常量配置
library;

/// 应用基础信息
class AppConstants {
  AppConstants._();

  static const String appName = 'AI 音乐学园';
  static const String appVersion = '0.1.0';

  /// 后端 API 地址（按平台区分）
  /// - Android Emulator: 10.0.2.2
  /// - Android 真机 + adb reverse: http://localhost:8000/api/v1（推荐）
  /// - iOS 模拟器: localhost
  /// - 真机（无 adb reverse）: 替换为电脑局域网 IP
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// 音频采样配置
  static const int sampleRate = 44100;
  static const int bufferSize = 2048; // ~46ms @44.1kHz，适合实时调音

  /// 调音器配置
  static const double a4Frequency = 440.0; // 标准音
  static const double tunerToleranceCents = 5.0; // 误差容忍度
}

/// 路由路径集中管理
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String tuner = '/tuner';
  static const String metronome = '/metronome';
  static const String sheets = '/sheets';
  static const String sheetDetail = '/sheets/:id';
  static const String courseCenter = '/courses';
  static const String courseCenterDetail = '/courses/:id';
  static const String lessonContent = '/lessons/:id';
  static const String aiCoach = '/ai-coach';
  static const String discover = '/discover';
}