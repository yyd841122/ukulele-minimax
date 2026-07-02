"""AI 评分服务测试"""
import pytest

from app.services.scoring import (
    freq_to_midi,
    midi_to_note,
    note_to_freq,
    align_notes_to_score,
    calculate_dimensions,
)
import numpy as np


def test_freq_to_midi_a4():
    """A4 = 440Hz → MIDI 69"""
    assert freq_to_midi(440.0) == 69


def test_freq_to_midi_a3():
    """A3 = 220Hz → MIDI 57"""
    assert freq_to_midi(220.0) == 57


def test_freq_to_midi_invalid():
    """无效频率返回 -1"""
    assert freq_to_midi(0) == -1
    assert freq_to_midi(float("nan")) == -1
    assert freq_to_midi(float("inf")) == -1


def test_midi_to_note_a4():
    assert midi_to_note(69) == "A4"


def test_midi_to_note_c4():
    """C4 = MIDI 60"""
    assert midi_to_note(60) == "C4"


def test_note_to_freq_roundtrip():
    """A4 转换往返一致"""
    f = note_to_freq("A4")
    assert abs(f - 440.0) < 0.01
    assert freq_to_midi(f) == 69


def test_calculate_dimensions_empty():
    """空列表应返回全 0"""
    dim = calculate_dimensions([])
    assert dim.overall == 0


def test_calculate_dimensions_all_correct():
    """全部正确应接近满分"""
    from app.models.schemas import NoteEvent
    events = [
        NoteEvent(
            time_ms=i * 500, expected_note="A4",
            detected_note="A4", cents_offset=0, is_correct=True,
        )
        for i in range(10)
    ]
    dim = calculate_dimensions(events)
    assert dim.pitch == 100.0
    assert dim.overall > 90


@pytest.mark.asyncio
async def test_score_audio_integration():
    """集成测试：合成音频 → 评分（暂跳过，需要真实录音文件）"""
    pytest.skip("需要真实录音文件，集成到 E2E 测试时再启用")