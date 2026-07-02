"""种子数据加载：服务启动时把 JSON 曲谱导入数据库"""
import json
import logging
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.sheet import Sheet

logger = logging.getLogger(__name__)

# 种子文件路径：server/data/seeds/
SEEDS_DIR = Path(__file__).resolve().parent.parent.parent / "data" / "seeds"


async def load_sheets_seed(db: AsyncSession) -> int:
    """加载曲谱种子数据

    Returns:
        新增的曲谱数量
    """
    seed_file = SEEDS_DIR / "ukulele_30.json"
    if not seed_file.exists():
        logger.warning(f"Seed file not found: {seed_file}")
        return 0

    try:
        data = json.loads(seed_file.read_text(encoding="utf-8"))
    except Exception as e:
        logger.error(f"Failed to parse seed file: {e}")
        return 0

    sheets_data = data.get("sheets", [])
    added = 0
    skipped = 0

    for sheet_dict in sheets_data:
        # 幂等：title 已存在则跳过
        stmt = select(Sheet).where(Sheet.title == sheet_dict["title"])
        existing = (await db.execute(stmt)).scalar_one_or_none()
        if existing:
            skipped += 1
            continue

        sheet = Sheet(
            title=sheet_dict["title"],
            title_en=sheet_dict.get("title_en"),
            artist=sheet_dict.get("artist"),
            instrument="ukulele",
            difficulty=sheet_dict.get("difficulty", "beginner"),
            bpm=sheet_dict.get("bpm", 80),
            duration_seconds=sheet_dict.get("duration_seconds", 0),
            key_signature=sheet_dict.get("key_signature", "C"),
            chords=sheet_dict.get("chords", []),
            notes_simplified=sheet_dict.get("notes_simplified"),
            tags=sheet_dict.get("tags", []),
            source=sheet_dict.get("source", "original"),
            copyright_holder=sheet_dict.get("copyright_holder"),
        )
        db.add(sheet)
        added += 1

    await db.commit()
    logger.info(f"Sheet seed: {added} added, {skipped} skipped (already exists)")
    return added