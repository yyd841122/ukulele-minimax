"""评分路由
T10：评分接口升级
- 从 Sheet DB 读取期望和弦序列
- 支持 WAV 字节流解码（含 header 解析）
- 落库 ScoreRecord
- 返回 score_id
"""
import base64
import io
import logging
import time

import soundfile as sf
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.database import get_db
from app.models.schemas import ScoreRequest, ScoreResponse
from app.models.score_record import ScoreRecord
from app.models.sheet import Sheet
from app.services.scoring import score_audio

router = APIRouter(prefix="/score", tags=["AI 评分"])
logger = logging.getLogger(__name__)

settings = get_settings()


def decode_audio_bytes(audio_b64_or_hex: str) -> tuple:
    """解码音频字节流

    支持：
    1. 标准 WAV/MP3 文件（base64 编码）
    2. 裸 PCM16 流（base64 编码 + 默认 44100Hz / mono / 16-bit）

    Returns: (audio_array, sample_rate)
    """
    try:
        raw = base64.b64decode(audio_b64_or_hex)
    except Exception:
        raise HTTPException(status_code=400, detail="音频 base64 解码失败")

    # 尝试用 soundfile 解码（含 header 解析）
    try:
        audio, sr = sf.read(io.BytesIO(raw), dtype='float32')
        if audio.ndim > 1:
            audio = audio.mean(axis=1)
        return audio, int(sr)
    except Exception:
        pass

    # 兜底：当作裸 PCM16 处理
    import numpy as np
    audio = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    return audio, 44100


@router.post("", response_model=ScoreResponse, summary="上传演奏音频，返回评分报告")
async def submit_score(
    payload: ScoreRequest,
    db: AsyncSession = Depends(get_db),
) -> ScoreResponse:
    """端到端评分：客户端上传录音 + sheet_id，服务端返回 4 维分数 + 弱项诊断

    T10 升级：
    - 真正从 DB 读曲谱（不再用占位音符）
    - 记录 ScoreRecord（含完整维度分）
    - 返回 score_id 供客户端关联
    """
    t0 = time.time()

    # 1. 加载曲谱
    stmt = select(Sheet).where(Sheet.id == payload.sheet_id)
    sheet = (await db.execute(stmt)).scalar_one_or_none()
    if sheet is None:
        raise HTTPException(status_code=404, detail="曲谱不存在")

    # 2. 构造期望音符序列
    expected_notes = _chords_to_expected_notes(sheet.chords or [])

    if not expected_notes:
        raise HTTPException(status_code=400, detail="曲谱无和弦数据")

    # 3. 调用评分服务
    result = await score_audio(
        audio_base64=payload.audio_base64,
        expected_notes=expected_notes,
        sample_rate=payload.sample_rate,
        crepe_model=settings.crepe_model,
    )

    # 4. 落库
    score_record = ScoreRecord(
        user_id=0,  # MVP: 无鉴权，固定 0
        sheet_id=payload.sheet_id,
        pitch_score=result["dimensions"].pitch,
        rhythm_score=result["dimensions"].rhythm,
        fluency_score=result["dimensions"].fluency,
        overall_score=result["dimensions"].overall,
        details={
            "expected_notes": expected_notes,
            "detected_notes": [n.model_dump() for n in result["notes"]],
        },
        weak_points=result["weak_points"],
        suggestions=result["suggestions"],
        duration_seconds=0,  # TODO: 解析 audio 时长
    )
    db.add(score_record)
    await db.commit()
    await db.refresh(score_record)

    elapsed = time.time() - t0
    logger.info(
        f"Score #{score_record.id}: sheet={sheet.id}, "
        f"overall={result['dimensions'].overall:.1f}, "
        f"elapsed={elapsed:.2f}s"
    )

    return ScoreResponse(
        score_id=score_record.id,
        dimensions=result["dimensions"],
        notes=result["notes"],
        weak_points=result["weak_points"],
        suggestions=result["suggestions"],
    )


def _chords_to_expected_notes(chords: list) -> list[dict]:
    """将曲谱的 chords 序列转换为评分用的 expected_notes

    chords 格式: [{"chord": "C", "time_ms": 0, "beats": 2}, ...]
    expected_notes 格式: [{"time_ms": 0, "note": "C4"}, ...]
    """
    notes = []
    for c in chords:
        chord = c.get("chord", "")
        time_ms = c.get("time_ms", 0)
        # 取和弦根音 + 4 八度（MVP 简化）
        if not chord:
            continue
        root = chord[0]  # C, D, E, F, G, A, B
        notes.append({"time_ms": time_ms, "note": f"{root}4"})
    return notes


# 暴露给测试
_decode_audio_bytes = decode_audio_bytes