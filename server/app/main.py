"""FastAPI 主入口
使用 lifespan（asynccontextmanager）替代已废弃的 startup/shutdown 事件
参考: FastAPI 0.118+ 推荐做法
"""
from contextlib import asynccontextmanager
from collections.abc import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import auth, sheets, scoring
from app.core.config import get_settings
from app.core.database import get_db, init_db, AsyncSessionLocal
from app.core.logging import setup_logging
from app.core.seed import load_sheets_seed

settings = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    """应用生命周期：启动时初始化 DB 与种子数据"""
    setup_logging(settings.debug)
    await init_db()

    # 加载曲谱种子数据
    async with AsyncSessionLocal() as session:
        await load_sheets_seed(session)

    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="自研版 AI 音乐学园 - 后端 API",
    lifespan=lifespan,
    debug=settings.debug,
)

# CORS（允许 Flutter Web 与本地调试）
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["健康检查"], summary="健康检查")
async def health() -> dict:
    return {
        "status": "ok",
        "app": settings.app_name,
        "version": settings.app_version,
    }


# 注册路由
app.include_router(auth.router, prefix=settings.api_v1_prefix)
app.include_router(sheets.router, prefix=settings.api_v1_prefix)
app.include_router(scoring.router, prefix=settings.api_v1_prefix)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
    )