# 🎵 AI 音乐学园（自研版）

> 自研版智能音乐学习与弹唱陪练 App，对标「AI 音乐学园」（北京音悦荚科技有限责任公司，com.immusician.music），全部免费、开源、可自托管。
> **v0.3 新增**：配套智能规划 Agent 平台 (`ukulele-agent`)，实现"跨任务可移植"的开发编排。

## 📋 项目概览

| 子项目 | 技术栈 | 路径 | 状态 |
| --- | --- | --- | --- |
| **App 客户端** | Flutter 3.44+ / Dart 3.12+ | `app/` | ✅ T01-T03 done |
| **App 后端** | Python 3.12 / FastAPI 0.118+ / librosa 0.11+ | `server/` | ✅ T02 done |
| **Agent 平台** | FastAPI + React + PostgreSQL | `agent/` | ⏳ T13 待开始 |
| **产品文档** | Markdown | `PRD.md` + `docs/` | ✅ v0.3 完整四件套 |

## 🚀 快速启动

### 1. 克隆与目录概览

```bash
cd e:/miniMax-projects/Ukulele
ls
# → PRD.md  app/  server/  docs/  README.md
```

### 2. 启动后端

```bash
cd server

# 安装依赖（推荐用 uv，其次 pip）
pip install -e ".[dev]"

# 复制环境变量
cp .env.example .env

# 启动服务（http://localhost:8000）
python app/main.py
```

后端启动后可访问：
- API 文档：http://localhost:8000/docs
- 健康检查：http://localhost:8000/health

### 3. 启动客户端

```bash
cd app

# 安装依赖
flutter pub get

# 运行（Android 模拟器 / iOS 模拟器 / 真机）
flutter run

# 或指定设备
flutter devices      # 查看可用设备
flutter run -d <deviceId>
```

### 4. 构建发布包

```bash
# Android APK
flutter build apk --release

# iOS IPA（需要 Mac）
flutter build ios --release
```

## 📂 项目结构

```
ukulele/
├── README.md                   # 本文件
├── PRD.md                      # 产品需求文档 v0.3
├── docs/                       # 设计文档四件套
│   ├── SDD.md                  # 技术方案 + 乐音识别选型
│   ├── PROTOTYPE.md            # 页面流程 + Agent Web 原型
│   ├── TDD.md                  # 任务拆解 + 验收标准
│   ├── ARCHITECTURE.md         # 总体架构（含 Agent 平台）
│   └── DEV_NOTES.md            # 开发日志
├── app/                        # Flutter 客户端
│   ├── pubspec.yaml
│   ├── android_manifest_template.xml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/               # 主题/路由/常量
│   │   ├── features/
│   │   │   ├── home/           # 首页
│   │   │   ├── tuner/          # M07 调音器（YIN 版 ✅）
│   │   │   └── metronome/      # M08 节拍器 ✅
│   │   └── shared/
│   └── test/
│       └── music_note_test.dart
├── server/                     # FastAPI 后端
│   ├── pyproject.toml
│   ├── .env.example
│   ├── app/
│   │   ├── main.py
│   │   ├── core/               # 配置/日志/数据库
│   │   ├── api/v1/             # 路由：auth/sheets/score
│   │   ├── models/             # ORM + Pydantic schema
│   │   └── services/
│   │       └── scoring.py      # AI 评分核心（librosa.pyin ✅）
│   └── tests/
│       └── test_scoring.py
└── agent/                      # 🆕 智能规划平台（v0.3+）
    ├── README.md
    ├── rules/                  # 规则库（YAML）
    │   ├── _base/
    │   ├── languages/
    │   ├── domains/
    │   └── projects/ukulele/
    ├── plans/                  # 计划定义
    └── src/                    # （待 T13 实现）
```

## ✅ MVP Phase 1 已完成

| 模块 | 状态 | 说明 |
| --- | --- | --- |
| 项目脚手架 | ✅ | Flutter + FastAPI |
| M07 调音器 | ✅ | PCM 采集 + YIN 算法端侧识别 |
| M08 节拍器 | ✅ | 可调 BPM/拍号 + 视觉反馈 |
| 后端 API 骨架 | ✅ | 用户/曲谱/评分三个接口 |
| AI 评分服务 | ✅ | librosa + onnxcrepe 端到端 |
| 数据模型 | ✅ | User / Sheet / ScoreRecord |

## ⏭ 下一步

按 PRD v0.2 Phase 1：

- [ ] 完善调音器音色合成（用 SoundPool 替代 just_audio 占位）
- [ ] 实现 M03 曲谱库（SQLite 预置 30 首尤克里里入门曲）
- [ ] 实现 M05 智能陪练（端侧 YIN + 云端评分聚合）
- [ ] 用户系统升级：JWT 中间件 + 鉴权装饰器
- [ ] 录屏/录像（发现区前置准备）
- [ ] AI 扒谱（自研差异化亮点）

详细见 [PRD.md](PRD.md)。

## 🔧 技术栈（用 context7 查最新 API）

### 客户端
- **Flutter 3.27+ / Dart 3.6+** - 跨平台 SDK
- **flutter_bloc 9.x** - 状态管理（BLoC/Cubit）
- **go_router 16.x** - 声明式路由
- **record 6.x** - PCM16 音频流录制
- **pitch_detector_dart 0.0.7** - YIN 端侧音高识别（参考 TarsosDSP）
- **just_audio 0.10.4** - 音频播放
- **dio 5.x** - HTTP 客户端

### 后端
- **Python 3.12+**
- **FastAPI 0.118+** - Web 框架（推荐用 `lifespan`，旧版 `on_event` 已废弃）
- **SQLAlchemy 2.0+ (async)** + **aiosqlite** - ORM
- **librosa 0.11+** - 音频分析（`librosa.load`, `librosa.pyin`, `librosa.beat.beat_track`, `librosa.onset.onset_detect`）
- **onnxcrepe** - ONNX 版 CREPE 模型（`CrepeInferenceSession`, `onnxcrepe.predict`）
- **pydantic 2.10+ / pydantic-settings** - 数据验证

## 📝 开发约定

- **不写占位符**：所有代码完整、可直接用
- **三步反思**：每个输出前做"初步实现 → 自我找茬 → 终极交付"
- **MVP 优先**：非 P0 一律延后
- **类型安全**：Python 用 Pydantic，Dart 用 `final`/`const` + lint 规则

## ⚖️ 版权与合规

模仿对象的所有数据用于产品分析；本项目代码为自主实现。
曲谱/音频来源：
1. 公共领域
2. CC-BY-NC 协议作品
3. 用户自上传 + AI 扒谱

不直接抓取原版曲库。

## 🐛 已知限制 / MVP 局限

1. **节拍器当前无真实节拍音**（just_audio 不支持合成音，待替换为 SoundPool）
2. **AI 评分接口期望音符序列**暂用占位数据（待曲谱模型 JSON 字段接入）
3. **端侧音高识别用纯 Dart YIN 自实现**（pitch_detector_dart 0.0.7 在流式 PCM 场景下 API 不够稳定；保留为兜底，可后续切换）
4. **未做机型适配矩阵**（不同麦克风硬件差异首次运行可能识别率低）
5. **暂未实现离线模式**（PRD Phase 2）

## 📞 后续工作

- 启动客户端：`flutter run`（需先 `flutter pub get`）
- 启动后端：`python app/main.py`
- 运行测试：`pytest`（后端）/ `flutter test`（客户端）
- 数据迁移：`alembic init alembic && alembic revision --autogenerate`（V0.2 启用）

---

文档版本：v0.2 / 2026-06-29