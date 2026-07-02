# 架构设计

> 客户端-服务端-模型三层架构 + 智能规划 Agent 平台（v0.3 新增）。
> 端侧优先，云端协同，平台可移植。
> 配套：[SDD.md](SDD.md) · [PROTOTYPE.md](PROTOTYPE.md) · [TDD.md](TDD.md)

## 1. 总体架构

```
┌──────────────────────────┐
│   Flutter App (iOS/Android/Web)   │
│   ┌──────────────────────┐  │
│   │ UI / BLoC / Routing   │  │
│   ├──────────────────────┤  │
│   │ 端侧音频引擎         │  │
│   │  - record (PCM16)    │  │
│   │  - YIN 音高识别      │  │
│   │  - just_audio 播放   │  │
│   └──────────────────────┘  │
└──────────────────────────┘
        │ HTTPS / JSON
        ▼
┌──────────────────────────┐
│   FastAPI Server        │
│   ┌──────────────────┐  │
│   │ API v1 路由       │  │
│   │  /auth /sheets /score │
│   ├──────────────────┤  │
│   │ 业务服务层       │  │
│   │  - Auth (JWT)    │  │
│   │  - Sheet 仓库    │  │
│   │  - Scoring 调度  │  │
│   └──────────────────┘  │
└──────────────────────────┘
        │
        ├──→ PostgreSQL / SQLite (用户/曲谱/记录)
        │
        └──→ AI 模型层
              ├── librosa（音频解码、节拍、onset）
              ├── onnxcrepe / CREPE ONNX（pitch）
              └──（未来）Basic Pitch / Whisper
```

## 2. 客户端分层

```
lib/
├── main.dart                # 入口
├── core/                    # 全局
│   ├── constants.dart       # 路径常量
│   ├── theme.dart           # 视觉规范
│   └── router.dart          # go_router
├── features/                # 业务模块（每个模块独立）
│   ├── home/
│   ├── tuner/               # M07 调音器
│   │   ├── tuner_cubit.dart # 状态机
│   │   ├── tuner_page.dart  # UI
│   │   └── domain/          # 纯 Dart 业务模型
│   │       └── music_note.dart  # 频率↔音名↔cents
│   └── metronome/
└── shared/utils/
    └── service_locator.dart #（预留 GetIt）
```

## 3. 音频管线（调音器）

```
record.startStream(PCM16, 44.1kHz)
         ↓
      累积 buffer 到 2048 样本
         ↓
      YIN 算法（pure Dart fallback）
         ↓
      freq (Hz)
         ↓
    MusicNote.fromFrequency
         ↓
    Cubit.emit 更新 UI
         ↓
    Widget rebuild（Cents 偏差条 + 音名大字）
```

**性能预算**：
- 单帧：~46 ms (2048 / 44100)
- 单次 YIN：~2-5 ms（modern device）
- 总延迟：~50 ms（接近实时）

## 4. 评分管线（云端）

```
Client: 录音 (5-30s) + sheet_id → POST /score
  ↓
Server: 
  1. base64 → bytes → librosa.load → (audio, sr)
  2. onnxcrepe.predict → (pitches, confidences)
  3. 与曲谱期望音符对齐（时间窗 ±50ms）
  4. 计算 pitch/rhythm/fluency/overall
  5. AI 弱项诊断 + 建议
  ↓
Response: ScoreResponse JSON
  ↓
Client: 评分报告 + 高亮错音
```

## 5. 数据模型（SQLAlchemy 2.0 async）

- **User** - 用户基础信息 + 学习画像
- **Sheet** - 曲谱元数据 + 期望音符 JSON 字段
- **ScoreRecord** - 单次评分历史（聚合分析）

## 6. 鉴权

MVP 阶段 JWT + 手机号（验证码简化）：
- 签发：HS256，1440 min 过期
- 传输：`Authorization: Bearer <token>`（下一版本启用 Header）
- 当前：`?token=<token>` Query 简版（避免改客户端）

## 7. 依赖注入

客户端：BlocProvider + Repository Pattern
服务端：FastAPI Depends + Singleton Engines

## 8. 后续扩展点

- **音频缓冲**：环形缓冲 → 处理网络抖动
- **协作文谱**：WebSocket → 实时多人合奏
- **AI 扒谱**：Basic Pitch 模型接入
- **i18n**：Flutter intl
- **CI/CD**：GitHub Actions → Android APK + FastAPI Docker

---

## 9. v0.3 新增：Agent 平台架构

### 9.1 平台与 App 的关系

```
┌─────────────────────────────────────────────────────────────┐
│                     Agent 平台（开发侧）                    │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│   │ Plan Engine  │  │ Rule Engine  │  │ Orchestrator │    │
│   └──────────────┘  └──────────────┘  └──────────────┘    │
│         ↓                  ↓                 ↓             │
│   ┌──────────────────────────────────────────────────┐     │
│   │         Web Dashboard (React + Vite)              │     │
│   └──────────────────────────────────────────────────┘     │
│                            ↕ GitHub API                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      App 项目（用户侧）                     │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐               │
│   │  App端   │ ←→ │ App后端  │ ←→ │ 乐音识别  │              │
│   └──────────┘   └──────────┘   └──────────┘               │
└─────────────────────────────────────────────────────────────┘
```

**核心原则**：平台**不直接依赖** App 的代码。平台只通过 GitHub API 与任何项目交互 → 实现"可移植"。

### 9.2 平台技术栈

| 模块 | 选型 | 理由 |
| --- | --- | --- |
| 后端 | FastAPI（与 App 共栈） | 复用团队知识、共享 ORM |
| 数据库 | PostgreSQL + JSONB | 规则与上下文存 JSONB，灵活 |
| 队列 | Celery + Redis | 任务调度 + 失败重试 |
| Web 前端 | React + Vite + TanStack Query | 现代、轻量、实时性好 |
| LLM 抽象 | 自研 Adapter（不绑 LangChain） | 避免大框架锁定 |
| 实时 | WebSocket | 任务状态推送 |
| 部署 | Docker Compose | 一次命令启动 |

### 9.3 数据流（典型 Plan 生命周期）

```
1. 用户在 Web 输入："实现 T04 端侧 MPM 算法"
   ↓
2. Plan Engine 调 Claude Opus 拆解为 DAG
   输出: plan-001.json (4 tasks)
   ↓
3. Orchestrator 写入 PostgreSQL
   ↓
4. Celery Worker 拉取第一个 task
   ↓
5. 调 Claude Code CLI 执行代码生成
   ↓
6. 完成后创建 GitHub Branch + PR
   ↓
7. Orchestrator 监控 PR 状态
   ↓
8. PR merged → 标记 task done → 触发下一个
   ↓
9. 所有 task done → 关闭 plan → 发通知
```

### 9.4 可移植性的具体实现

| 维度 | 措施 |
| --- | --- |
| **规则格式** | YAML/JSON，无平台特定 schema |
| **协议** | REST + WebSocket（行业标准） |
| **数据库** | PostgreSQL（任何云都支持） |
| **LLM 抽象** | 任意 LLM 可替换（Anthropic/OpenAI/本地） |
| **项目接入** | 只需 GitHub 仓库 + 写一个 `ukulele-agent.yaml` 配置文件 |
| **部署** | Docker Compose 一次启动；K8s 兼容 |

**接入新项目只需 3 步**：
1. 在新项目根目录加 `ukulele-agent.yaml`
2. 在平台 UI 输入仓库地址
3. 创建第一个 Plan

### 9.5 与现有 App 的最小集成

Phase 1 阶段平台对 App 几乎**零侵入**：
- App 端：继续独立开发
- 平台端：只读 App 的 GitHub 仓库
- 通信：完全通过 GitHub PR 流转

未来扩展：
- App 端加入"开发者模式"开关 → 把"匿名练习数据"反哺回平台（用户授权后）
- 平台为 App 提供"AI 老师"后端能力（复用 LLM adapter）

---

文档版本：v0.3 / 2026-06-29