"""曲谱 ORM 模型"""
from datetime import datetime
from sqlalchemy import String, Integer, DateTime, JSON, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Sheet(Base):
    __tablename__ = "sheets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(128), index=True)
    title_en: Mapped[str | None] = mapped_column(String(128))
    artist: Mapped[str | None] = mapped_column(String(64))
    instrument: Mapped[str] = mapped_column(String(16), index=True)
    difficulty: Mapped[str] = mapped_column(String(16), default="beginner")
    bpm: Mapped[int] = mapped_column(Integer, default=80)
    duration_seconds: Mapped[int] = mapped_column(Integer, default=0)
    key_signature: Mapped[str] = mapped_column(String(8), default="C")
    cover_url: Mapped[str | None] = mapped_column(String(256))
    sheet_data_url: Mapped[str | None] = mapped_column(String(256))
    audio_demo_url: Mapped[str | None] = mapped_column(String(256))

    # 曲谱内容（和弦进行 + 简谱）
    chords: Mapped[list] = mapped_column(JSON, default=list)
    notes_simplified: Mapped[str | None] = mapped_column(String(2048))
    tags: Mapped[list] = mapped_column(JSON, default=list)

    view_count: Mapped[int] = mapped_column(Integer, default=0)
    favorite_count: Mapped[int] = mapped_column(Integer, default=0)

    # 版权 / 来源
    source: Mapped[str] = mapped_column(String(32), default="original")
    copyright_holder: Mapped[str | None] = mapped_column(String(128))

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())