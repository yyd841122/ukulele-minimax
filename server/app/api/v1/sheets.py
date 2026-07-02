"""曲谱路由"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.schemas import SheetCreate, SheetOut
from app.models.sheet import Sheet

router = APIRouter(prefix="/sheets", tags=["曲谱"])


@router.get("", response_model=list[SheetOut], summary="曲谱列表")
async def list_sheets(
    instrument: str | None = Query(None, description="乐器筛选"),
    difficulty: str | None = Query(None, description="难度筛选"),
    search: str | None = Query(None, description="搜索关键词"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> list[SheetOut]:
    """获取曲谱列表，支持乐器/难度/关键词筛选"""
    stmt = select(Sheet)
    if instrument:
        stmt = stmt.where(Sheet.instrument == instrument)
    if difficulty:
        stmt = stmt.where(Sheet.difficulty == difficulty)
    if search:
        stmt = stmt.where(Sheet.title.contains(search))

    stmt = stmt.order_by(Sheet.view_count.desc()).limit(limit).offset(offset)
    result = (await db.execute(stmt)).scalars().all()
    return [SheetOut.model_validate(s) for s in result]


@router.get("/{sheet_id}", response_model=SheetOut, summary="获取单个曲谱")
async def get_sheet(
    sheet_id: int,
    db: AsyncSession = Depends(get_db),
) -> SheetOut:
    sheet = await db.get(Sheet, sheet_id)
    if not sheet:
        raise HTTPException(status_code=404, detail="曲谱不存在")

    # 增加浏览数
    sheet.view_count += 1
    await db.commit()
    await db.refresh(sheet)
    return SheetOut.model_validate(sheet)


@router.post("", response_model=SheetOut, summary="创建曲谱（管理后台）")
async def create_sheet(
    payload: SheetCreate,
    db: AsyncSession = Depends(get_db),
) -> SheetOut:
    """MVP 阶段直接通过 API 创建，生产应放在管理后台"""
    sheet = Sheet(**payload.model_dump())
    db.add(sheet)
    await db.commit()
    await db.refresh(sheet)
    return SheetOut.model_validate(sheet)