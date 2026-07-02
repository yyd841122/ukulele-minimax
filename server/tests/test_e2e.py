"""T12 端到端冒烟测试
模拟客户端完整流程：register -> 选曲 -> 上传录音 -> 评分
"""
import base64
import io
import json
import time

import numpy as np
import pytest
import soundfile as sf
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


@pytest.fixture(autouse=True)
def _reset_db():
    """每个测试前重置数据库（保留 seed 数据）"""
    from app.core.database import engine, Base
    from app.models import user, sheet, score_record  # noqa
    import asyncio

    async def reset():
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)

    asyncio.run(reset())
    yield


def _make_test_audio(duration=5.0, sr=44100, freq=440.0):
    """合成一段测试音频（440Hz + 谐波）"""
    t = np.linspace(0, duration, int(sr * duration), endpoint=False)
    signal = 0.4 * np.sin(2 * np.pi * freq * t)
    signal += 0.15 * np.sin(2 * np.pi * 2 * freq * t)
    buf = io.BytesIO()
    sf.write(buf, signal.astype('float32'), sr, format='WAV')
    buf.seek(0)
    return base64.b64encode(buf.read()).decode('ascii')


def test_e2e_full_flow(client):
    """端到端完整流程"""
    # Step 1: 注册
    print("\n--- Step 1: Register ---")
    reg_resp = client.post(
        '/api/v1/auth/register',
        json={
            'phone': '13933031581',
            'nickname': 'E2E Test User',
            'instrument': 'ukulele',
        },
    )
    assert reg_resp.status_code == 200, f"register failed: {reg_resp.text}"
    reg_data = reg_resp.json()
    assert 'access_token' in reg_data
    assert reg_data['user']['phone'] == '13933031581'
    print(f"  [OK] User registered, id={reg_data['user']['id']}")

    # Step 2: 选曲（已有 seed 数据 sheet_id=1）
    print("\n--- Step 2: List sheets ---")
    list_resp = client.get('/api/v1/sheets?instrument=ukulele&limit=5')
    assert list_resp.status_code == 200
    sheets = list_resp.json()
    assert len(sheets) > 0, "No sheets available"
    target_sheet = sheets[0]
    print(f"  [OK] Selected sheet: '{target_sheet['title']}' (id={target_sheet['id']})")

    # Step 3: 获取详情
    print("\n--- Step 3: Get sheet detail ---")
    detail_resp = client.get(f"/api/v1/sheets/{target_sheet['id']}")
    assert detail_resp.status_code == 200
    sheet_detail = detail_resp.json()
    assert 'chords' in sheet_detail
    print(f"  [OK] Sheet has {len(sheet_detail['chords'])} chord entries")

    # Step 4: 合成音频 + 上传评分
    print("\n--- Step 4: Upload audio for scoring ---")
    audio_b64 = _make_test_audio(duration=8.0, freq=440.0)
    print(f"  Audio size: {len(audio_b64)} chars base64")

    t0 = time.time()
    score_resp = client.post(
        '/api/v1/score',
        json={
            'sheet_id': target_sheet['id'],
            'audio_base64': audio_b64,
            'sample_rate': 44100,
        },
    )
    elapsed = time.time() - t0
    assert score_resp.status_code == 200, f"score failed: {score_resp.text}"
    score_data = score_resp.json()
    assert 'dimensions' in score_data
    assert 'weak_points' in score_data
    assert 'suggestions' in score_data
    assert 'notes' in score_data
    assert score_data['score_id'] > 0
    print(f"  [OK] Score received: id={score_data['score_id']}, overall={score_data['dimensions']['overall']:.1f}")
    print(f"  [OK] Server elapsed: {elapsed:.2f}s")

    # 验收：弱项诊断非空
    assert len(score_data['weak_points']) > 0 or len(score_data['suggestions']) > 0
    print(f"  [OK] Weak points: {len(score_data['weak_points'])}, suggestions: {len(score_data['suggestions'])}")


def test_e2e_filter_sheets(client):
    """筛选曲谱：按乐器+难度"""
    # 全部尤克里里
    resp = client.get('/api/v1/sheets?instrument=ukulele&limit=50')
    assert resp.status_code == 200
    all_sheets = resp.json()
    assert len(all_sheets) > 0

    # 入门
    resp2 = client.get('/api/v1/sheets?instrument=ukulele&difficulty=beginner&limit=50')
    assert resp2.status_code == 200
    beginner = resp2.json()
    assert all(s['difficulty'] == 'beginner' for s in beginner)
    assert len(beginner) < len(all_sheets) or len(all_sheets) == 0
    print(f"\n--- Filter test ---")
    print(f"  All: {len(all_sheets)}, Beginner: {len(beginner)}")


def test_e2e_health_and_docs(client):
    """健康检查 + 文档可访问"""
    h = client.get('/health')
    assert h.status_code == 200
    assert h.json()['status'] == 'ok'

    d = client.get('/docs')
    assert d.status_code == 200
    print("\n--- Health/Docs test ---")
    print(f"  /health: {h.json()}")
    print(f"  /docs: 200 OK")


def test_e2e_score_validation(client):
    """评分入参校验"""
    # 缺 audio_base64
    r = client.post('/api/v1/score', json={'sheet_id': 1})
    assert r.status_code == 422  # Pydantic validation error

    # sheet_id 不存在
    audio_b64 = _make_test_audio(duration=2.0)
    r = client.post(
        '/api/v1/score',
        json={
            'sheet_id': 99999,
            'audio_base64': audio_b64,
            'sample_rate': 44100,
        },
    )
    assert r.status_code == 404
    print("\n--- Validation test ---")
    print(f"  Missing audio: 422 [OK]")
    print(f"  Non-existent sheet: 404 [OK]")