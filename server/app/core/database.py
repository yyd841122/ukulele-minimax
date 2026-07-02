"""数据库会话管理"""
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.core.config import get_settings

settings = get_settings()

# 创建异步引擎（SQLite + aiosqlite）
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    future=True,
)

# 异步 Session 工厂
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """所有 ORM 模型的基类"""


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI 依赖：提供请求级 DB Session"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db() -> None:
    """初始化数据库表（首次启动）"""
    # 导入所有模型以注册 metadata
    from app.models import user, sheet, score_record  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)