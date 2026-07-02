# SDD - 软件设计文档

> **SDD = Software Design Document**
> 文档版本：v0.1（2026-06-29）
> 项目代号：`ukulele`（App）+ `ukulele-agent`（智能规划平台）
> 上游：见 [PRD.md](../PRD.md) 与 [ARCHITECTURE.md](ARCHITECTURE.md)

## 0. 读者对象与范围

本文档面向**技术决策者与实现者**。回答三个问题：
1. **乐音识别怎么选型**（详细对比与选型结论）
2. **智能规划 Agent 平台怎么搭**（架构、协议、可移植性）
3. **App 与 Agent 平台如何协作**（边界、数据流、API）

## 1. 乐音识别技术选型

### 1.1 候选方案对比表

| 方案 | 类型 | 原理 | 准确率 | 速度 | 包大小/依赖 | 多音支持 | 抗噪性 | 端侧可用 | 许可 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **YIN** | 时域算法 | 自相关 + 累积均值归一化差分 | 中（~80% 干净音） | 极快（<5ms/帧） | 0（纯 Dart 即可） | ❌ 单音 | 中 | ✅ | MIT |
| **PYIN** | YIN 概率版 | YIN + 隐马尔可夫平滑 + Viterbi | 中高（~85%） | 慢（~20-50ms/帧） | 中（librosa） | ❌ 单音 | 较好 | ⚠️ 仅服务端 | ISC |
| **MPM** | 时域算法 | 自相关 + NSDF 最大峰 + 抛物线插值 | **高**（~90% 干净音，**八度错误最少**） | 快（~3-8ms/帧） | 0（纯算法） | ❌ 单音 | 中好 | ✅ | GPL（Praat 原始） |
| **CREPE**（tiny） | 深度学习 CNN | 单帧 6 层卷积，~80KB ONNX | **高**（~92%） | 快（CPU 10-20ms/帧） | **~80KB ONNX** | ❌ 单音 | 好（噪声数据训练） | ✅ | Apache 2.0 |
| **CREPE**（full） | 深度学习 CNN | 单帧 6 层卷积，~22MB ONNX | 极高（~95%） | 慢（CPU 30-50ms/帧） | ~22MB ONNX | ❌ 单音 | 极好 | ⚠️ 体积大 | Apache 2.0 |
| **Spotify Basic Pitch** | 深度学习 CNN+CRF | 音高 + onset/offset 联合学习，ICASSP 2022 | 极高（多音，钢琴 89.5%） | 较慢（10x 实时） | ~20MB ONNX/TF | ✅ **多音** | 好 | ❌ 太大，端侧需量化 | Apache 2.0 |

### 1.2 关键指标解读

**准确率**（基于 MIR-1K / MDB-stem-synth 等公开数据集，参考值）：
- 干净单音（无谐波失真）：MPM ≈ CREPE-tiny > PYIN > YIN
- 噪声/泛音环境：CREPE > MPM > PYIN > YIN
- **多音（和弦）**：只有 Basic Pitch 能做，其他全部失效

**八度错误（Octave Error）** —— 吉他/尤克里里拨弦常见问题：
- YIN：高发（约 5-10% 帧）
- PYIN：中（~3-5%）
- **MPM：极低**（<1%，因 NSDF 主峰更锐利）
- CREPE：低（<2%，CNN 学到全局特征）

**对尤克里里/吉他拨弦的真实场景**：
- 拨弦瞬间有强瞬态 + 衰减
- 同时有横按/和弦（一根弦主导，其他振幅小）
- 麦克风 + 手机端有环境噪声

### 1.3 🎯 选型结论：**分场景双轨**

```
┌────────────────────────────────────────────────────┐
│ 端侧 (Flutter App) — 实时低延迟                     │
│   → MPM 算法（纯 Dart 自实现）                       │
│   - 调音器（M07）：10ms 级反馈，必须本地              │
│   - 跟弹模式（M05）：50ms 内识别当前音               │
└────────────────────────────────────────────────────┘
                     ↕ 上传
┌────────────────────────────────────────────────────┐
│ 云端 (Python Server) — 精度优先                     │
│   → CREPE-tiny（ONNX 80KB，端侧也能用）              │
│   - 评分（M06）：可批处理，精度 > 速度                │
│   - 和弦识别：CREPE-tiny + chroma 后处理            │
│   - 扒谱：Basic Pitch（多音）                        │
└────────────────────────────────────────────────────┘
```

### 1.4 选型理由

**为什么端侧不上 CREPE？**
- ONNX Runtime mobile 包大（~15MB），与端侧"零依赖"原则冲突
- 调音器、跟弹场景**不要求 95% 精度**，85% 足够
- MPM 在干净单音上几乎不输 CREPE，**且零依赖**

**为什么端侧不上 YIN？**
- 八度错误高发，拨弦场景会频繁"翻八度"
- 复杂度与 MPM 相当，**没有理由选更差的**

**为什么云端不上 PYIN？**
- 22s 处理 2s 音频（实测，见 DEV_NOTES.md）
- CREPE-tiny ONNX 推理 < 100ms/帧

**为什么和弦识别走 chroma + HMM 而非 Basic Pitch？**
- 主流弹唱（单音+扫弦）90% 是单音主导
- 简化和弦识别（4 个标准和弦）的精度已够 MVP
- 高级和弦（7和弦/挂留）留给 Phase 2 接 Basic Pitch

### 1.5 MPM 算法实现要点（端侧）

> **MPM = McLeod Pitch Method**（McLeod & Wyvill, 2005）

核心步骤：
1. 计算音频归一化自相关函数（NSDF）
2. 找最大峰所在的 lag（τ）
3. 抛物线插值修正 τ
4. f₀ = sampleRate / τ

关键参数（尤克里里场景）：
```dart
class MpmConfig {
  static const int minFreqHz = 70;      // 低 E2 弦
  static const int maxFreqHz = 1200;    // 高 E5
  static const int sampleRate = 44100;
  static const int bufferSize = 2048;   // ~46ms 帧
  static const double silenceThresholdDb = -45;  // 静音门限
  static const double clarityThreshold = 0.5;   // NSDF 峰值锐度
}
```

### 1.6 端侧实现计划

| 文件 | 作用 | 行数估 |
| --- | --- | --- |
| `lib/core/audio/mpm.dart` | MPM 纯 Dart 实现 | ~150 |
| `lib/core/audio/pcm_decoder.dart` | 字节流 → Float 数组 | ~50 |
| `lib/core/audio/ring_buffer.dart` | 环形缓冲 | ~60 |
| `lib/features/tuner/tuner_cubit.dart` | 替换 YIN → MPM | -20 |

**切换成本**：当前 `tuner_cubit.dart` 的 `_yinDetect` 方法直接替换为 `_mpmDetect`，接口不变。

### 1.7 云端实现计划

| 文件 | 作用 | 依赖 |
| --- | --- | --- |
| `app/services/scoring.py` | 已有，换 ONNX CREPE | `onnxruntime` |
| `app/services/chord.py` | 新增：chroma + HMM 和弦识别 | `librosa` |
| `models/crepe-tiny.onnx` | 模型权重（~80KB） | 下载到 `data/models/` |

**模型来源**：[yqzhishen/onnxcrepe](https://github.com/yqzhishen/onnxcrepe) GitHub 仓库提供预导出 ONNX（需用户授权安装）。

## 2. 智能规划 Agent 平台架构

### 2.1 平台定位

**`ukulele-agent` 是一个"项目无关的规则与编排层"**。

核心抽象：
- **Task（任务）**：可独立执行的最小工作单元
- **Plan（计划）**：一组 Task 的依赖图（DAG）
- **Agent（执行者）**：执行 Task 的实体（Claude/Codex/本地脚本）
- **Rule（规则）**：拆分、路由、验收的可移植逻辑

**可移植性来源**：
- 规则用 **JSON Schema + Jinja2 模板**定义（不绑 Python）
- 协议用 **REST + WebSocket**（语言无关）
- 状态用 **PostgreSQL**（业界标准）
- 任何能调 HTTP 的项目都能接入

### 2.2 整体架构图

```
┌──────────────────────────────────────────────────────────┐
│                  ukulele-agent 平台                       │
│                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Plan Engine │  │ Rule Engine  │  │ Orchestrator │    │
│  │ (拆分任务)   │  │ (规则库)     │  │ (执行调度)   │    │
│  └─────────────┘  └──────────────┘  └──────────────┘    │
│         ↑                 ↑                ↓             │
│         └────── LLM Adapter ──────────→ Agent Workers  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Persistence: PostgreSQL  +  Redis (cache/queue)  │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Integrations: GitHub API  /  Webhook  /  CLI     │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
                ↑                            ↑
        REST + WebSocket              GitHub Issue/PR
                ↓                            ↓
┌─────────────────────────┐      ┌──────────────────────┐
│ Web Dashboard (React)   │      │ 外部项目 (任何)       │
│ - 看任务进度            │      │ - GitHub PR 接收     │
│ - 触发 Plan             │      │ - 规则引用           │
│ - 审计日志              │      │                      │
└─────────────────────────┘      └──────────────────────┘
```

### 2.3 核心模块详解

#### 2.3.1 Plan Engine（计划引擎）

**职责**：接收"高阶目标" → 输出"DAG 任务图"。

**输入**（自然语言 + 上下文）：
```json
{
  "goal": "实现调音器 M07",
  "context": {
    "project": "ukulele",
    "stage": "MVP",
    "tech_stack": ["Flutter", "FastAPI"],
    "existing_code": ["lib/features/tuner/"]
  }
}
```

**输出**（DAG 计划）：
```json
{
  "plan_id": "plan-20260629-001",
  "tasks": [
    {
      "id": "t1",
      "title": "MPM 算法纯 Dart 实现",
      "depends_on": [],
      "agent_type": "code-writer",
      "estimated_minutes": 120,
      "acceptance": "tests/mpm_test.dart 全绿，准确率 > 85%"
    },
    {
      "id": "t2",
      "title": "替换 TunerCubit 中的 YIN 调用",
      "depends_on": ["t1"],
      "agent_type": "code-modifier",
      "estimated_minutes": 30,
      "acceptance": "flutter analyze 0 error，tuner 演示正常"
    }
  ]
}
```

**实现路径**：
- LLM 拆任务（Claude/GPT）
- 用 [Pydantic](https://docs.pydantic.dev/) 约束输出结构
- 失败回退：内置模板（按 tech_stack 选规则）

#### 2.3.2 Rule Engine（规则引擎）

**职责**：定义"如何拆"、"如何测"、"如何验收"的可移植规则。

**规则格式**（YAML/JSON）：
```yaml
# rules/ukulele/m07-tuner.yaml
id: m07-tuner
name: 调音器 M07
inputs: [tech_stack, project_state]
outputs: [plan_template]
plan_template:
  - task: 算法选型与实现
    tech_stack: [flutter, mpm]
    duration_min: 120
  - task: Cubit 集成
    duration_min: 30
  - task: 单元测试
    duration_min: 30
  - task: UI 验证
    duration_min: 30
acceptance:
  - flutter test 0 fail
  - flutter analyze 0 error
  - 调音器在模拟器能识别 A4
```

**规则库组织**：
```
rules/
├── _base/                  # 通用规则
│   ├── code-quality.yaml
│   └── test-coverage.yaml
├── languages/
│   ├── flutter/
│   ├── python-fastapi/
│   └── typescript-react/
├── domains/
│   ├── audio-processing.yaml
│   ├── mobile-app.yaml
│   └── ml-model.yaml
└── projects/               # 项目级规则（可选）
    └── ukulele/
        ├── m07-tuner.yaml
        └── m08-metronome.yaml
```

**可移植性核心**：规则语言是数据，不绑平台语言；任何 IDE/CI/Agent 都能解析。

#### 2.3.3 Orchestrator（编排器）

**职责**：把 DAG 计划执行起来。

**核心能力**：
- **并行调度**：无依赖任务并发执行
- **状态机**：`pending → running → review → done | failed`
- **超时重试**：每个任务最多 3 次自动重试
- **并发限制**：默认 4 个 Agent 同时跑
- **审计日志**：每步记录 prompt、输出、diff、token 用量

**实现**：
- 后端：FastAPI + Celery（或 RQ）+ Redis
- 前端：React + Vite + TanStack Query
- 实时：WebSocket 推送任务状态

#### 2.3.4 LLM Adapter

**支持**：
- Anthropic Claude（推荐 Opus 4.8 / Sonnet 4.6）
- OpenAI GPT
- 本地 Ollama（隐私场景）

**抽象**：
```python
class LLMAdapter(Protocol):
    async def complete(self, prompt: str, **kwargs) -> str: ...
    async def stream(self, prompt: str, **kwargs) -> AsyncIterator[str]: ...
    def count_tokens(self, text: str) -> int: ...
```

**实现策略**：
- 简单任务用小模型（Haiku 4.5）
- 复杂任务用大模型（Opus 4.8）
- 默认走 Claude Code CLI（用户已在用）

### 2.4 数据模型

```sql
-- 计划表
CREATE TABLE plans (
    id UUID PRIMARY KEY,
    goal TEXT NOT NULL,
    context JSONB,
    status VARCHAR(20),  -- pending/running/done/failed
    created_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- 任务表
CREATE TABLE tasks (
    id UUID PRIMARY KEY,
    plan_id UUID REFERENCES plans(id),
    title TEXT,
    prompt TEXT,
    agent_type VARCHAR(50),
    depends_on UUID[],
    status VARCHAR(20),
    output JSONB,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    retry_count INT DEFAULT 0
);

-- 规则表（用户自定义规则）
CREATE TABLE rules (
    id VARCHAR(100) PRIMARY KEY,  -- e.g. "m07-tuner"
    content JSONB,
    version INT,
    updated_at TIMESTAMPTZ
);

-- 审计日志
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    plan_id UUID,
    task_id UUID,
    event VARCHAR(50),
    payload JSONB,
    created_at TIMESTAMPTZ
);
```

### 2.5 GitHub 集成

**流程**：
```
用户触发 Plan "实现 M07"
  ↓
Plan Engine 输出 DAG（4 个 task）
  ↓
Orchestrator 为每个 task 创建 GitHub Issue
  ↓
分配给不同 Agent（或人工）
  ↓
Agent 完成 → 创建 PR
  ↓
Orchestrator 检测到 PR merged → 标记 task done
  ↓
所有 task done → 关闭 Plan
```

**好处**：
- 任何 GitHub 仓库都能"接入"平台
- 复用 GitHub 的 PR review / CI
- 平台独立，不污染主项目

## 3. App ↔ Agent 平台协作

### 3.1 边界

| 边界 | App 端 | Agent 平台 |
| --- | --- | --- |
| 用户面向 | 音乐学习者 | 开发者/产品经理 |
| 数据 | 学习记录、演奏音频 | 任务、规则、审计 |
| AI 能力 | 乐音识别（实时） | 任务编排（异步） |
| 鉴权 | 终端用户 | GitHub OAuth + 平台账号 |

### 3.2 数据流

```
[音乐学习者]
  ↓ 弹琴
[App：MPM 识别音高] 
  ↓ 上传录音
[App 后端：CREPE 评分]
  ↓ 评分结果
[App 推送给用户]
        ↓ 开发者观察
[开发者提需求："加 AI 评分图表"]
  ↓
[Agent 平台：拆任务]
  ↓
[子 Agent 并行实现]
  ↓ 创建 PR
[开发者 review → merge]
  ↓
[App 后端拉取新代码部署]
  ↓
[用户看到新功能]
```

### 3.3 平台部署

```
┌──────────────────────────┐
│ Agent Platform            │
│ - Web (React, 独立部署)   │
│ - API (FastAPI, 同后端)   │
│ - DB (PostgreSQL)         │
│ - Cache (Redis)           │
│ - LLM Proxy (Claude API)  │
└──────────────────────────┘
            ↕ GitHub API
┌──────────────────────────┐
│ ukulele Project (GitHub) │
│ - app/    (Flutter)       │
│ - server/ (FastAPI)       │
│ - docs/   (Markdown)      │
└──────────────────────────┘
```

## 4. 关键技术风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
| --- | --- | --- | --- |
| MPM 端侧精度不够 | 中 | 调音不准 | 与 CREPE 端侧作 A/B 测试；不达标时切换 |
| 平台 LLM 成本 | 高 | 月费高 | 任务分级：小任务用 Haiku，复杂用 Opus |
| 规则太死板 | 中 | 移植后不适用 | 规则版本化 + 用户反馈通道 |
| GitHub API 限流 | 低 | 调度失败 | 缓存 + 退避重试 |
| Claude API 不可用 | 中 | 平台停摆 | 多 LLM adapter + 本地 Ollama 兜底 |

## 5. 选型总结（一页纸）

| 决策点 | 选项 | 结论 | 理由 |
| --- | --- | --- | --- |
| 端侧音高识别 | YIN / PYIN / MPM / CREPE | **MPM** | 精度高、八度错误少、零依赖、纯 Dart |
| 云端音高识别 | librosa / CREPE / Basic Pitch | **CREPE-tiny (ONNX)** | 80KB 高精度，< 100ms/帧 |
| 多音（和弦） | chroma / Basic Pitch | **chroma + HMM** | MVP 阶段够用；Phase 2 接 Basic Pitch |
| Agent 驱动 | LLM / 规则 / 混合 | **LLM 驱动** | 用户决策 |
| 平台可移植性 | 项目内 / 抽象层 | **抽象规则层** | 用户决策 |
| 平台 UI | GitHub / Web / 都要 | **GitHub 主 + Web 辅** | 用户决策 |
| 平台技术栈 | 复用后端 / 独立 / 开源框架 | **独立后端 + 复用 DB** | 复用规则层，最少绑死 |
| LLM | Claude / OpenAI / 本地 | **Claude（用户在用）** | 零迁移成本 |
| 持久化 | SQLite / PostgreSQL | **PostgreSQL** | 多用户 + JSONB 适配规则 |

---

> **下游文档**：
> - 原型设计：[PROTOTYPE.md](PROTOTYPE.md)
> - 任务拆解：[TDD.md](TDD.md)
> - 架构总览：[ARCHITECTURE.md](ARCHITECTURE.md)
> - 开发日志：[DEV_NOTES.md](DEV_NOTES.md)