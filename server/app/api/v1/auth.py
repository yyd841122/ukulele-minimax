"""用户认证路由（MVP 阶段简化为手机号 + 验证码）"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.database import get_db
from app.models.schemas import TokenOut, UserCreate, UserLogin, UserOut
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["用户认证"])

settings = get_settings()


def create_access_token(user_id: int) -> str:
    """生成 JWT Token"""
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.jwt_access_token_expire_minutes
    )
    payload = {"sub": str(user_id), "exp": expire}
    return jwt.encode(
        payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm
    )


@router.post("/register", response_model=TokenOut, summary="注册新用户")
async def register(
    payload: UserCreate,
    db: AsyncSession = Depends(get_db),
) -> TokenOut:
    """手机号注册（MVP 简化版，不接短信验证码）"""
    # 检查手机号是否已注册
    stmt = select(User).where(User.phone == payload.phone)
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="手机号已注册")

    user = User(
        phone=payload.phone,
        nickname=payload.nickname,
        instrument=payload.instrument,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(user.id)
    return TokenOut(access_token=token, user=UserOut.model_validate(user))


@router.post("/login", response_model=TokenOut, summary="手机号登录")
async def login(
    payload: UserLogin,
    db: AsyncSession = Depends(get_db),
) -> TokenOut:
    """MVP：任何 4-6 位验证码都通过，生产环境接短信服务"""
    stmt = select(User).where(User.phone == payload.phone)
    user = (await db.execute(stmt)).scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    token = create_access_token(user.id)
    return TokenOut(access_token=token, user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut, summary="获取当前用户")
async def get_me(
    token: str,
    db: AsyncSession = Depends(get_db),
) -> UserOut:
    """通过 query 参数传递 token（MVP 简化版）"""
    try:
        payload = jwt.decode(
            token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm]
        )
        user_id = int(payload["sub"])
    except (JWTError, KeyError, ValueError):
        raise HTTPException(status_code=401, detail="无效的 Token")

    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return UserOut.model_validate(user)