"""用户 ORM 模型"""
from datetime import datetime
from sqlalchemy import String, Integer, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    phone: Mapped[str] = mapped_column(String(11), unique=True, index=True)
    nickname: Mapped[str] = mapped_column(String(32))
    instrument: Mapped[str] = mapped_column(String(16), default="ukulele")

    # 学习画像
    level: Mapped[int] = mapped_column(Integer, default=1)
    total_practice_seconds: Mapped[int] = mapped_column(Integer, default=0)
    consecutive_days: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )