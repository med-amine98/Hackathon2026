from app.database.connection import Base
from app.models.user import User
from app.models.profile import UserProfile
from app.models.product import InsuranceProduct
from app.models.conversation import Conversation, Message
from app.models.recommendation import Recommendation
from app.models.declaration import Declaration
from app.models.conseil import Conseil
from app.models.prevention import Prevention

__all__ = [
    "Base",
    "User",
    "UserProfile",
    "InsuranceProduct",
    "Conversation",
    "Message",
    "Recommendation",
    "Declaration",      
    "Conseil",          
    "Prevention",       
]