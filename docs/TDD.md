# TDD - 任务定义文档

> **TDD = Task Definition Document**
> 文档版本：v0.1（2026-06-29）
> 用途：把 PRD + SDD + 原型拆解为可执行、可验收、可分发给 Agent 的任务包
> 配套：[PRD.md](../PRD.md) · [SDD.md](SDD.md) · [PROTOTYPE.md](PROTOTYPE.md)

## 0. 阅读说明

每个任务包含：
- **ID**：全局唯一（如 `T01`）
- **优先级**：P0/P1/P2
- **估时**：人工执行 / Agent 执行的预估
- **依赖**：必须先完成的任务 ID
- **交付物**：产出文件或可观测效果
- **验收标准**：可量化的 PASS 条件
- **规则引用**：对应的 yaml 规则（见 SDD.md §2.3.2）

Agent 在收到任务时，会**自动加载**对应的规则 yaml 与上下文。

---

## 1. 任务总览

```
P0（共 12 个任务，估 6 周）
├── T01-T03：环境与基础（已完成 ✅）
├── T04-T05：M07 调音器强化（MPM + 真机测试）
├── T06-T07：M08 节拍器完整化
├── T08：M03 曲谱库 MVP
└── T09-T10：M05 智能陪练 + 评分闭环

P1（共 8 个任务，估 4 周）
├── T11-T13：Agent 平台 MVP
├── T14：M12 发现区
└── T15-T18：横切关注点

P2（共 6 个任务，长期）
└── T19-T24：扩展乐器 + 商业模式
```

## 2. P0 任务（必须完成）

### T01 · 项目脚手架 ✅ 已完成
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 1 天 |
| 依赖 | 无 |
| 交付物 | `app/` + `server/` + `docs/` 全部目录与初始文件 |
| 验收 | `flutter analyze` 0 error + `pytest` 全绿 |
| 规则 | `_base/code-quality` |
| 状态 | ✅ done |

### T02 · 后端 FastAPI 框架 ✅ 已完成
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 0.5 天 |
| 依赖 | T01 |
| 交付物 | `server/app/main.py` + 3 个路由（auth/sheets/score） |
| 验收 | 12 路由可注册 + `/health` 返回 ok + `/docs` 可访问 |
| 规则 | `python-fastapi/lifespan` |
| 状态 | ✅ done |

### T03 · M07 调音器 YIN 版 ✅ 已完成
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 1 天 |
| 依赖 | T01 |
| 交付物 | `lib/features/tuner/*` 完整页面 + Cubit |
| 验收 | UI 显示音名/频率/cents 条 + 8 个单元测试通过 |
| 规则 | `flutter/bloc-pattern` |
| 状态 | ✅ done |

### T04 · 端侧 MPM 算法实现
| 字段 | 值 |
| --- | --- |
| 优先级 | **P0** |
| 估时 | 0.5 天 |
| 依赖 | T03 |
| 交付物 | `lib/core/audio/mpm.dart` + 单元测试 `test/mpm_test.dart` |
| 验收 | (a) 测试：合成 440Hz 输入应识别为 440±2Hz；(b) 八度错误 < 2%；(c) 纯 Dart 零依赖；(d) `flutter analyze` 0 error |
| 规则 | `audio-processing/mpm-algorithm` |
| 测试数据 | `assets/test_audio/a4_440.wav`, `e2_82.wav`, `c4_262.wav`（需提前合成） |
| 风险 | MPM 在噪声下退化 → 验收时用噪声数据测试 |

### T05 · M07 调音器切换到 MPM
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 0.5 天 |
| 依赖 | T04 |
| 交付物 | 替换 `tuner_cubit.dart` 的 `_yinDetect` → `_mpmDetect` |
| 验收 | `flutter analyze` 0 error + `flutter test` 全绿 + 真机 demo 拨弦 1s 内出音名 |
| 规则 | `flutter/bloc-pattern`, `_base/test-coverage` |
| 风险 | 性能不达标 → 优化 buffer 大小；端侧卡顿 → 降级到 YIN 兜底 |

### T06 · M08 节拍器真实节拍音
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 0.5 天 |
| 依赖 | T03 |
| 交付物 | `lib/features/metronome/click_player.dart`（SoundPool 合成 PCM） |
| 验收 | (a) 首拍重音 vs 普通节拍音可区分；(b) BPM 80-200 无卡顿；(c) 后台运行不报错 |
| 规则 | `audio-processing/pcm-synthesis` |
| 风险 | Android/iOS API 差异 → 抽 platform channel |

### T07 · 节拍器变拍 / 复合拍
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 0.5 天 |
| 依赖 | T06 |
| 交付物 | UI 支持 3/4、6/8、5/4 等拍号切换 |
| 验收 | 切换拍号时拍号显示正确 + 重音点正确 |
| 规则 | `audio-processing/beat-pattern` |

### T08 · 曲谱库 MVP（30 首尤克里里）
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 2 天 |
| 依赖 | T02 |
| 交付物 | (a) `data/sheets/ukulele_30.json` 含 30 首歌的简谱；(b) 后端曲谱 CRUD；(c) 前端曲谱列表页 + 详情页 |
| 验收 | (a) 30 首曲目可查询；(b) 按乐器/难度/搜索筛选可用；(c) 详情页显示简谱 |
| 规则 | `mobile-app/list-page`, `python-fastapi/pagination` |
| 数据来源 | 优先：公共领域童谣 + CC-BY-NC 协议；不直接复制原版曲库 |
| 风险 | 30 首版权 → 选曲时严格审查 |

### T09 · 智能陪练端侧状态机
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 1.5 天 |
| 依赖 | T05, T08 |
| 交付物 | `lib/features/practice/practice_page.dart` + `practice_cubit.dart` |
| 验收 | (a) 跟弹模式可播放示范音 + 实时录音；(b) 错音标红；(c) 完成后跳转评分页 |
| 规则 | `flutter/bloc-pattern`, `audio-processing/recording` |

### T10 · 云端 CREPE ONNX 评分
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 1 天 |
| 依赖 | T02, T08 |
| 交付物 | (a) `server/app/services/scoring.py` 接入 ONNX；(b) `data/models/crepe-tiny.onnx`（80KB）；(c) `/score` 接口返回 < 200ms |
| 验收 | (a) 5s 音频评分耗时 < 200ms；(b) 准确率与 librosa.pyin 持平或更高；(c) 失败回退到 pyin |
| 规则 | `audio-processing/crepe-model` |
| 前置 | 用户授权从 GitHub 安装 onnxruntime + 下载模型权重 |
| 风险 | onnxruntime 安装失败 → 暂用 librosa.pyin |

### T11 · 评分报告页面
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 1 天 |
| 依赖 | T09, T10 |
| 交付物 | `lib/features/score_report/score_report_page.dart` |
| 验收 | (a) 显示综合分 + 4 维度雷达图；(b) 错音列表 + 弱项诊断 + 改进建议；(c) 支持重练 |
| 规则 | `mobile-app/data-viz` |

### T12 · 端到端冒烟测试
| 字段 | 值 |
| --- | --- |
| 优先级 | P0 |
| 估时 | 1 天 |
| 依赖 | T11 |
| 交付物 | `integration_test/full_flow_test.dart` |
| 验收 | (a) 注册 → 选曲 → 跟弹 → 评分 完整链路可走通；(b) CI 可运行 |
| 规则 | `_base/e2e-test` |

## 3. P1 任务

### T13 · Agent 平台 MVP（核心）
| 字段 | 值 |
| --- | --- |
| 优先级 | **P1** |
| 估时 | 5 天 |
| 依赖 | T12 |
| 交付物 | (a) `agent/` 目录（FastAPI + Web）；(b) Plan Engine + Rule Engine + Orchestrator 三个核心模块；(c) 简单的 Web Dashboard |
| 验收 | (a) 输入目标 → 输出 DAG；(b) 单任务可由 Claude Code CLI 执行；(c) 实时日志可见 |
| 规则 | `agent-platform/core`, `python-fastapi/celery` |
| 风险 | Claude API 成本 → 加 token 用量监控；可靠性 → 多 LLM adapter |

### T14 · Agent 平台 GitHub 集成
| 字段 | 值 |
| --- | --- |
| 优先级 | P1 |
| 估时 | 1 天 |
| 依赖 | T13 |
| 交付物 | (a) GitHub OAuth 流程；(b) 每 task 创建分支 + PR；(c) PR merged 后自动标记完成 |
| 验收 | (a) 一次 plan 跑完生成 5 个 PR；(b) merge 一个 PR 后平台 task 状态自动更新 |
| 规则 | `agent-platform/github-integration` |

### T15 · 规则库编辑器
| 字段 | 值 |
| --- | --- |
| 优先级 | P1 |
| 估时 | 1 天 |
| 依赖 | T13 |
| 交付物 | Web 端 YAML 编辑器 + 校验器 |
| 验收 | (a) 规则可在线编辑 + 保存；(b) 格式错误时高亮；(c) 支持导入/导出 |
| 规则 | `agent-platform/rule-editor` |

### T16 · 发现区 / UGC
| 字段 | 值 |
| --- | --- |
| 优先级 | P1 |
| 估时 | 2 天 |
| 依赖 | T11 |
| 交付物 | 录屏 → 上传 → 列表 → 点赞 |
| 验收 | (a) 录 30s 视频能上传；(b) 列表显示头像/标题/点赞数 |
| 规则 | `mobile-app/video` |

### T17 · 离线模式
| 字段 | 值 |
| --- | --- |
| 优先级 | P1 |
| 估时 | 1 天 |
| 依赖 | T12 |
| 交付物 | 已学曲目 + 评分算法本地缓存 |
| 验收 | 飞行模式下完整跟弹 + 评分可工作 |
| 规则 | `mobile-app/offline` |

### T18 · i18n（中英双语）
| 字段 | 值 |
| --- | --- |
| 优先级 | P1 |
| 估时 | 1 天 |
| 依赖 | T11 |
| 交付物 | 全文案抽 `lib/l10n/*.arb` |
| 验收 | 切换语言后所有页面文字更新 |
| 规则 | `flutter/i18n` |

## 4. P2 任务（长期）

| ID | 描述 | 估时 | 依赖 |
| --- | --- | --- | --- |
| T19 | 接入 Basic Pitch 多音识别（和弦/钢琴） | 3 天 | T10 |
| T20 | 支持吉他（曲库 + 算法适配） | 5 天 | T19 |
| T21 | 支持钢琴（MIDI 设备输入） | 5 天 | T20 |
| T22 | 拇指琴/口琴/古筝/非洲鼓 曲库 | 7 天 | T08 |
| T23 | 1v1 老师直播课 | 10 天 | T16 |
| T24 | 商业模式（会员/广告） | 3 天 | T17 |

## 5. 任务分发样例（如何用 Agent 平台）

### 5.1 命令式分发（用户在 Claude Code 输入）

```bash
# 通过 Agent 平台 CLI
ukulele-agent create-plan \
  --goal "实现端侧 MPM 算法" \
  --project ukulele \
  --rules "audio-processing/mpm-algorithm,flutter/bloc-pattern" \
  --priority P0 \
  --target-task T04
```

### 5.2 输出示例（DAG 自动生成）

```json
{
  "plan_id": "plan-20260629-001",
  "goal": "实现端侧 MPM 算法",
  "rules_applied": ["audio-processing/mpm-algorithm", "flutter/bloc-pattern"],
  "tasks": [
    {
      "id": "t1",
      "title": "创建 mpm.dart 框架（NSDF 函数）",
      "agent": "code-writer (Claude Opus)",
      "depends_on": [],
      "acceptance": "可计算 1024 样本的 NSDF，analyze 0 error"
    },
    {
      "id": "t2",
      "title": "实现峰值检测 + 抛物线插值",
      "agent": "code-writer (Claude Opus)",
      "depends_on": ["t1"],
      "acceptance": "440Hz 合成输入输出 440±2Hz"
    },
    {
      "id": "t3",
      "title": "PCM16 解码 + 静音门限",
      "agent": "code-writer (Claude Opus)",
      "depends_on": ["t2"],
      "acceptance": "静音段返回 0 Hz"
    },
    {
      "id": "t4",
      "title": "单元测试 + 性能基准",
      "agent": "code-writer (Claude Opus)",
      "depends_on": ["t3"],
      "acceptance": "test/mpm_test.dart 全绿 + 单帧 < 10ms"
    }
  ]
}
```

### 5.3 验收检查（Agent 自检 + 人工 review）

```
✓ flutter analyze  0 error
✓ flutter test     8/8 passed
✓ 真机 demo       拨弦识别符合预期
✗ GitHub Actions  待配置

Reviewer: [开发者]
Status: 待 review
```

## 6. 进度跟踪表

| ID | 任务 | 优先级 | 状态 | 估时 | 实际 | 负责人 |
| --- | --- | --- | --- | --- | --- | --- |
| T01 | 脚手架 | P0 | ✅ | 1d | 1d | Claude |
| T02 | FastAPI 框架 | P0 | ✅ | 0.5d | 0.5d | Claude |
| T03 | 调音器 YIN | P0 | ✅ | 1d | 1d | Claude |
| T04 | MPM 算法 | P0 | ✅ | 0.5d | 0.7d | Claude |
| T05 | 切换到 MPM | P0 | ✅ | 0.5d | 0.3d | Claude |
| T06 | 节拍器真实音 | P0 | ✅ | 0.5d | 0.4d | Claude |
| T07 | 变拍支持 | P0 | ✅ | 0.5d | 0.3d | Claude |
| T08 | 曲谱库 MVP | P0 | ✅ | 2d | 1.5d | Claude |
| T09 | 陪练状态机 | P0 | ✅ | 1.5d | 1d | Claude |
| T10 | CREPE ONNX 评分 | P0 | ✅ | 1d | 0.8d | Claude |
| T11 | 评分报告 | P0 | ✅ | 1d | 0.7d | Claude |
| T12 | E2E 测试 | P0 | ✅ | 1d | 0.5d | Claude |

## 7. 风险登记表

| 风险 | 影响任务 | 缓解策略 | Owner |
| --- | --- | --- | --- |
| MPM 精度不达标 | T04, T05 | 备选 CREPE-tiny ONNX 端侧版 | Claude |
| onnxruntime 装不上 | T10 | 暂用 librosa.pyin 兜底 | Claude |
| 曲谱版权 | T08 | 仅用公共领域 + CC 协议 | 用户 |
| Agent 平台 LLM 成本 | T13-T15 | 任务分级：小任务 Haiku | 用户 |
| iOS 真机调试 | T05, T11 | 优先 Android 验证 | Claude |

---

> **下一步**：把 T04「端侧 MPM 算法实现」分发给 Agent 平台（详见 [PROTOTYPE.md §2.3](PROTOTYPE.md)）。