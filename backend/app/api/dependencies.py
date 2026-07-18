from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.core.security import decode_token
from app.core.exceptions import CredentialsException
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/token")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    payload = decode_token(token)
    email: str = payload.get("sub")
    if email is None:
        raise CredentialsException()
    
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise CredentialsException()
        
    return user
