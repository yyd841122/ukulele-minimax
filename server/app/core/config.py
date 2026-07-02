"""应用配置模块 - 使用 Pydantic Settings"""
from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """全局配置"""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # 应用
    app_name: str = "AI 音乐学园"
    app_version: str = "0.1.0"
    debug: bool = False

    # API
    api_v1_prefix: str = "/api/v1"

    # 数据库
    database_url: str = "sqlite+aiosqlite:///./data/ukulele.db"

    # Redis（可选）
    redis_url: str | None = None

    # JWT
    jwt_secret_key: str = "change-me"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 1440

    # AI
    crepe_model: str = "full"
    crepe_fmin: float = 50.0
    crepe_fmax: float = 2006.0

    # CORS
    cors_origins: list[str] = Field(default_factory=lambda: ["*"])

    # 路径
    base_dir: Path = Path(__file__).resolve().parent.parent.parent
    data_dir: Path = Field(default_factory=lambda: Path("./data"))
    audio_dir: Path = Field(default_factory=lambda: Path("./data/audio"))
    sheet_dir: Path = Field(default_factory=lambda: Path("./data/sheets"))


@lru_cache
def get_settings() -> Settings:
    """获取单例配置"""
    settings = Settings()
    # 确保目录存在
    settings.data_dir.mkdir(parents=True, exist_ok=True)
    settings.audio_dir.mkdir(parents=True, exist_ok=True)
    settings.sheet_dir.mkdir(parents=True, exist_ok=True)
    return settings