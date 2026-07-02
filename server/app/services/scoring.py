"""AI 评分服务
基于 librosa 0.11+ 实现端到端评分：
1. 接收 base64 编码音频
2. 用 librosa.load 解码
3. 用 librosa.pyin / yin 提取基频（替代 onnxcrepe，Phase 2 再换 CREPE）
4. 与曲谱期望音符比对，计算音准/节奏/流畅度
"""
from __future__ import annotations

import base64
import io
import math
from typing import Any

import librosa
import numpy as np

from app.models.schemas import NoteEvent, ScoreDimension

# 全局基频配置（Phase 1 用 librosa.pyin，Phase 2 再换 onnxcrepe）
_DEFAULT_FMIN = librosa.note_to_hz("C2")  # ~65 Hz
_DEFAULT_FMAX = librosa.note_to_hz("C7")  # ~2093 Hz


# 音名 ↔ MIDI 编号
NOTE_NAMES_SHARP = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def freq_to_midi(freq: float) -> int:
    """频率 → MIDI 编号（最近整数）"""
    if freq <= 0 or math.isnan(freq) or math.isinf(freq):
        return -1
    semitones = 12.0 * (math.log2(freq / 440.0))
    if math.isnan(semitones) or math.isinf(semitones):
        return -1
    return int(round(semitones + 69))


def midi_to_note(midi: int) -> str:
    """MIDI 编号 → 音名"""
    if midi < 0:
        return "-"
    octave = (midi // 12) - 1
    name = NOTE_NAMES_SHARP[midi % 12]
    return f"{name}{octave}"


def note_to_freq(note: str) -> float:
    """音名 → 频率（Hz）"""
    if not note or note == "-":
        return 0.0
    # 拆分音名 + 八度
    if len(note) >= 3 and note[1] == "#":
        name, octave = note[:2], int(note[2:])
    else:
        name, octave = note[:1], int(note[1:])
    idx = NOTE_NAMES_SHARP.index(name)
    midi = (octave + 1) * 12 + idx
    return 440.0 * math.pow(2.0, (midi - 69) / 12.0)


def decode_audio(audio_base64: str, expected_sr: int = 44100) -> tuple[np.ndarray, int]:
    """base64 编码音频 → (audio_array, sample_rate)"""
    raw = base64.b64decode(audio_base64)
    audio, sr = librosa.load(io.BytesIO(raw), sr=expected_sr, mono=True)
    return audio, sr


def extract_pitch_contour(
    audio: np.ndarray,
    sr: int,
    model: str = "pyin",
    fmin: float = _DEFAULT_FMIN,
    fmax: float = _DEFAULT_FMAX,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """提取基频轮廓（Hz）+ 置信度

    Args:
        audio: 1D float32 音频数组
        sr: 采样率
        model: "pyin"（默认，推荐）/ "yin"
        fmin/fmax: 频率范围

    Returns:
        times: 时间数组（秒）
        pitches: 频率数组（Hz），无效帧为 nan
        confidences: 置信度数组（0-1）

    参考：librosa 0.11+ API（context7 实时查询）
    """
    if audio.dtype != np.float32:
        audio = audio.astype(np.float32)

    if model == "yin":
        # librosa.yin 返回确定性基频
        pitches = librosa.yin(audio, fmin=fmin, fmax=fmax, sr=sr)
        confidences = np.ones_like(pitches)
        # yin 返回非 nan 表示有声
    else:
        # librosa.pyin 返回 (f0, voiced_flag, voiced_probs)
        pitches, voiced_flag, voiced_probs = librosa.pyin(
            audio, fmin=fmin, fmax=fmax, sr=sr
        )
        confidences = voiced_probs.astype(np.float32)

    # 静音帧：pitches 为 nan（pyin 默认）
    # yin 没 nan 概念，这里统一：置信度 < 0.1 视为 nan
    pitches = np.where(confidences < 0.1, np.nan, pitches)

    # 时间轴
    times = librosa.times_like(pitches, sr=sr)

    return times, pitches, confidences


def align_notes_to_score(
    detected_pitches: np.ndarray,
    confidences: np.ndarray,
    times: np.ndarray,
    expected_notes: list[dict[str, Any]],
    confidence_threshold: float = 0.5,
) -> list[NoteEvent]:
    """将检测到的基频与曲谱期望音符对齐

    expected_notes 格式: [{"time_ms": 0, "note": "C4"}, ...]
    """
    events: list[NoteEvent] = []

    for exp in expected_notes:
        target_time = exp["time_ms"] / 1000.0
        expected_note = exp["note"]
        expected_freq = note_to_freq(expected_note)

        # 找最接近的检测帧
        idx = int(np.argmin(np.abs(times - target_time)))
        detected_freq = float(detected_pitches[idx])
        conf = float(confidences[idx])

        detected_note = midi_to_note(freq_to_midi(detected_freq)) if conf >= confidence_threshold else "-"

        # 计算 cents 偏差
        if expected_freq > 0 and detected_freq > 0 and not math.isnan(detected_freq):
            cents = int(round(1200.0 * math.log2(detected_freq / expected_freq)))
        else:
            cents = 0

        is_correct = (
            conf >= confidence_threshold
            and detected_note == expected_note
            and abs(cents) <= 15
        )

        events.append(
            NoteEvent(
                time_ms=exp["time_ms"],
                expected_note=expected_note,
                detected_note=detected_note,
                cents_offset=cents,
                is_correct=is_correct,
            )
        )

    return events


def calculate_dimensions(events: list[NoteEvent]) -> ScoreDimension:
    """从 NoteEvent 列表计算音准/节奏/流畅度/综合分"""
    if not events:
        return ScoreDimension(pitch=0, rhythm=0, fluency=0, overall=0)

    # 音准分：cents 偏差在 ±15 内算正确
    correct_pitch = sum(1 for e in events if e.is_correct)
    pitch_score = 100.0 * correct_pitch / len(events)

    # 节奏分：基于前后音符时间间隔（占位实现，后续接入 DTW）
    # 这里简单用"检测到有效音符"占比作为近似
    detected = sum(1 for e in events if e.detected_note != "-")
    rhythm_score = 100.0 * detected / len(events)

    # 流畅度分：连续正确率
    max_streak = 0
    cur_streak = 0
    for e in events:
        if e.is_correct:
            cur_streak += 1
            max_streak = max(max_streak, cur_streak)
        else:
            cur_streak = 0
    fluency_score = 100.0 * max_streak / len(events) if events else 0

    # 综合分：加权平均
    overall = 0.5 * pitch_score + 0.3 * rhythm_score + 0.2 * fluency_score

    return ScoreDimension(
        pitch=round(pitch_score, 1),
        rhythm=round(rhythm_score, 1),
        fluency=round(fluency_score, 1),
        overall=round(overall, 1),
    )


def diagnose_weak_points(
    events: list[NoteEvent],
    dimensions: ScoreDimension,
) -> tuple[list[str], list[str]]:
    """AI 弱项诊断与建议"""
    weak_points: list[str] = []
    suggestions: list[str] = []

    if dimensions.pitch < 80:
        wrong_notes = [e.expected_note for e in events if not e.is_correct]
        weak_points.append(f"音准欠佳：{len(wrong_notes)} 个音未命中")
        suggestions.append("建议：开启节拍器慢速练习，重点听标准音与目标音差异")
    if dimensions.rhythm < 80:
        weak_points.append("节奏不稳：部分节拍未及时演奏")
        suggestions.append("建议：先用 0.5x 速度跟弹，再逐步加速")
    if dimensions.fluency < 70:
        weak_points.append("连贯性不足：存在停顿或中断")
        suggestions.append("建议：先分段练习每句，再连贯整曲")

    # 出现频率最高的错误音
    from collections import Counter
    wrong_counter = Counter(
        e.expected_note for e in events if not e.is_correct
    )
    if wrong_counter:
        most_wrong = wrong_counter.most_common(1)[0]
        weak_points.append(f"频繁失误音：{most_wrong[0]}（出现 {most_wrong[1]} 次）")
        suggestions.append(f"建议：专项练习 {most_wrong[0]} 及其相邻音的指法")

    if not weak_points:
        weak_points.append("表现优秀！")
        suggestions.append("可以挑战下一难度级别")

    return weak_points, suggestions


async def score_audio(
    audio_base64: str,
    expected_notes: list[dict[str, Any]],
    sample_rate: int = 44100,
    crepe_model: str = "pyin",
) -> dict:
    """端到端评分入口"""
    # 1. 解码
    audio, sr = decode_audio(audio_base64, sample_rate)

    # 2. 提取基频
    times, pitches, confidences = extract_pitch_contour(
        audio, sr, model=crepe_model if crepe_model in ("pyin", "yin") else "pyin",
    )

    # 3. 对齐
    events = align_notes_to_score(pitches, confidences, times, expected_notes)

    # 4. 计算分数
    dimensions = calculate_dimensions(events)

    # 5. 弱项诊断
    weak_points, suggestions = diagnose_weak_points(events, dimensions)

    return {
        "dimensions": dimensions,
        "notes": events,
        "weak_points": weak_points,
        "suggestions": suggestions,
    }