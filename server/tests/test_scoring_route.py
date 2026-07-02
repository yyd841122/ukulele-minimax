"""评分路由测试"""
import base64
import io

import numpy as np
import pytest
import soundfile as sf

from app.api.v1.scoring import _chords_to_expected_notes, _decode_audio_bytes


def test_chords_to_expected_notes_basic():
    """标准 4 个和弦 → 4 个 expected_notes"""
    chords = [
        {"chord": "C", "time_ms": 0, "beats": 2},
        {"chord": "F", "time_ms": 2000, "beats": 2},
        {"chord": "G", "time_ms": 4000, "beats": 2},
        {"chord": "Am", "time_ms": 6000, "beats": 2},
    ]
    notes = _chords_to_expected_notes(chords)
    assert len(notes) == 4
    assert notes[0] == {"time_ms": 0, "note": "C4"}
    assert notes[1] == {"time_ms": 2000, "note": "F4"}
    assert notes[3] == {"time_ms": 6000, "note": "A4"}  # Am 取根音 A


def test_chords_to_expected_notes_empty():
    """空列表 → 空 notes"""
    assert _chords_to_expected_notes([]) == []


def test_chords_to_expected_notes_skip_empty_chord():
    """跳过空 chord"""
    chords = [
        {"chord": "", "time_ms": 0, "beats": 2},
        {"chord": "C", "time_ms": 2000, "beats": 2},
    ]
    notes = _chords_to_expected_notes(chords)
    assert len(notes) == 1
    assert notes[0]["note"] == "C4"


def test_decode_audio_bytes_wav():
    """WAV 解码"""
    sr = 44100
    t = np.linspace(0, 0.1, int(sr * 0.1), endpoint=False)
    sig = np.sin(2 * np.pi * 440 * t).astype(np.float32)
    buf = io.BytesIO()
    sf.write(buf, sig, sr, format='WAV')
    b64 = base64.b64encode(buf.getvalue()).decode('ascii')

    audio, decoded_sr = _decode_audio_bytes(b64)
    assert decoded_sr == sr
    assert len(audio) == len(sig)
    assert abs(audio[100] - sig[100]) < 0.01


def test_decode_audio_bytes_raw_pcm_fallback():
    """裸 PCM16 → 默认 44100Hz"""
    pcm = np.array([100, -100, 200, -200], dtype=np.int16)
    b64 = base64.b64encode(pcm.tobytes()).decode('ascii')

    audio, sr = _decode_audio_bytes(b64)
    assert sr == 44100
    assert len(audio) == 4
    assert abs(audio[0] - 100 / 32768.0) < 0.001