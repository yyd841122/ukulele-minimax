# AI 音乐学园（自研版）- Flutter 客户端

> 第一阶段 MVP：调音器 + 节拍器 + 基础骨架。
> 完整产品规划见 [../PRD.md](../PRD.md)。

## 技术栈

| 能力 | 包 | 用途 |
| --- | --- | --- |
| 状态管理 | flutter_bloc 9.x | BLoC/Cubit 模式 |
| 路由 | go_router 16.x | 声明式路由 |
| 录音 | record 6.x | PCM16 音频流 |
| 音高识别 | pitch_detector_dart | 端侧 YIN 算法 |
| 音频播放 | just_audio 0.10.x | 示范曲、节拍器 |
| 网络 | dio 5.x | 后端 API |
| 持久化 | shared_preferences + sqflite | 用户设置、学习记录 |

## 快速启动

```bash
# 1. 进入目录
cd app

# 2. 安装依赖
flutter pub get

# 3. 检查环境
flutter doctor

# 4. 运行（需要连接真机或模拟器）
flutter run

# 5. 构建 APK（Release）
flutter build apk --release
```

## 目录结构

```
lib/
├── main.dart                  # 入口、路由配置
├── core/
│   ├── theme.dart             # 主题（薄荷绿 + 木色）
│   ├── router.dart            # go_router 配置
│   └── constants.dart         # 全局常量
├── features/
│   ├── home/                  # 首页
│   ├── tuner/                 # M07 调音器
│   └── metronome/             # M08 节拍器
└── shared/
    └── utils/                 # 工具函数
```

## 平台权限

### Android（`android/app/src/main/AndroidManifest.xml`）
- `RECORD_AUDIO` - 麦克风录音
- `MODIFY_AUDIO_SETTINGS` - 调音器需要

### iOS（`ios/Runner/Info.plist`）
- `NSMicrophoneUsageDescription` - 麦克风使用说明

## 后续 TODO

- [ ] M01 用户系统（手机号 + 微信登录）
- [ ] M03 曲谱库
- [ ] M05 智能陪练（跟弹）
- [ ] M06 AI 评分