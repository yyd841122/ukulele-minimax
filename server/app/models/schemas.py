"""Pydantic Schema - API 入参出参 DTO"""
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, EmailStr, Field

# ============== 用户 ==============

InstrumentType = Literal["ukulele", "guitar", "piano", "kalimba", "harmonica", "guzheng", "djembe"]


class UserCreate(BaseModel):
    phone: str = Field(..., min_length=11, max_length=11, description="手机号")
    nickname: str = Field(..., min_length=1, max_length=32)
    instrument: InstrumentType = "ukulele"


class UserLogin(BaseModel):
    phone: str = Field(..., min_length=11, max_length=11)
    code: str = Field(..., min_length=4, max_length=6, description="验证码")


class UserOut(BaseModel):
    id: int
    phone: str
    nickname: str
    instrument: InstrumentType
    level: int
    total_practice_seconds: int
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


# ============== 曲谱 ==============

DifficultyLevel = Literal["beginner", "easy", "medium", "hard", "expert"]


class SheetCreate(BaseModel):
    title: str
    title_en: str | None = None
    artist: str | None = None
    instrument: InstrumentType
    difficulty: DifficultyLevel = "beginner"
    bpm: int = Field(80, ge=40, le=240)
    duration_seconds: int = 0
    key_signature: str = "C"
    cover_url: str | None = None
    sheet_data_url: str | None = None
    audio_demo_url: str | None = None
    chords: list[dict] = Field(default_factory=list)
    notes_simplified: str | None = None
    tags: list[str] = Field(default_factory=list)
    source: str = "original"
    copyright_holder: str | None = None


class SheetOut(BaseModel):
    id: int
    title: str
    title_en: str | None = None
    artist: str | None = None
    instrument: InstrumentType
    difficulty: DifficultyLevel
    bpm: int
    duration_seconds: int
    key_signature: str
    cover_url: str | None = None
    sheet_data_url: str | None = None
    audio_demo_url: str | None = None
    chords: list[dict] = Field(default_factory=list)
    notes_simplified: str | None = None
    tags: list[str] = Field(default_factory=list)
    source: str = "original"
    copyright_holder: str | None = None
    view_count: int
    favorite_count: int
    created_at: datetime

    model_config = {"from_attributes": True}


# ============== 评分 ==============

class ScoreRequest(BaseModel):
    """评分请求：上传录音 + 曲谱 ID"""
    sheet_id: int
    audio_base64: str = Field(..., description="WAV/MP3 音频 base64")
    sample_rate: int = 44100


class ScoreDimension(BaseModel):
    pitch: float = Field(..., ge=0, le=100, description="音准分")
    rhythm: float = Field(..., ge=0, le=100, description="节奏分")
    fluency: float = Field(..., ge=0, le=100, description="流畅度分")
    overall: float = Field(..., ge=0, le=100, description="综合分")


class NoteEvent(BaseModel):
    time_ms: int
    expected_note: str
    detected_note: str
    cents_offset: int
    is_correct: bool


class ScoreResponse(BaseModel):
    score_id: int
    dimensions: ScoreDimension
    notes: list[NoteEvent]
    weak_points: list[str] = Field(default_factory=list, description="AI 诊断的弱项")
    suggestions: list[str] = Field(default_factory=list, description="改进建议")