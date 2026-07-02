"""评分记录 ORM 模型"""
from datetime import datetime
from sqlalchemy import String, Integer, Float, DateTime, ForeignKey, JSON, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class ScoreRecord(Base):
    __tablename__ = "score_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), index=True)
    sheet_id: Mapped[int] = mapped_column(Integer, ForeignKey("sheets.id"), index=True)

    # 综合分
    pitch_score: Mapped[float] = mapped_column(Float)
    rhythm_score: Mapped[float] = mapped_column(Float)
    fluency_score: Mapped[float] = mapped_column(Float)
    overall_score: Mapped[float] = mapped_column(Float)

    # 详细数据（每拍/每音的命中情况）
    details: Mapped[dict] = mapped_column(JSON, default=dict)
    weak_points: Mapped[list] = mapped_column(JSON, default=list)
    suggestions: Mapped[list] = mapped_column(JSON, default=list)

    duration_seconds: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())