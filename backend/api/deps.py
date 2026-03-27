import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.db.session import get_db
from backend.models.user import User
from backend.services.auth_service import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/v1/auth/token")

_credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Token non valido o scaduto.",
    headers={"WWW-Authenticate": "Bearer"},
)


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    try:
        payload = decode_token(token)
    except jwt.InvalidTokenError as exc:
        raise _credentials_exception from exc

    if payload.get("type") != "access":
        raise _credentials_exception
    email: str | None = payload.get("sub")
    if not email:
        raise _credentials_exception

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise _credentials_exception
    return user
