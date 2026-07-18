from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, JSON, Text
from sqlalchemy.sql import func
from app.database.connection import Base

class Conversation(Base):
    __tablename__ = "conversations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Conversation metadata
    status = Column(String, default="active")  # active, completed, abandoned
    intent = Column(String)  # buy_car_insurance, get_quote, etc.
    
    # Context
    context_data = Column(JSON)  # Current conversation context
    current_step = Column(String)
    
    # Analytics
    messages_count = Column(Integer, default=0)
    user_satisfaction = Column(Integer)  # 1-5
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    ended_at = Column(DateTime(timezone=True))

class Message(Base):
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"), nullable=False)
    
    role = Column(String, nullable=False)  # user, assistant, system
    content = Column(Text, nullable=False)
    
    # Additional data (renamed to meta_data to avoid conflict with SQLAlchemy metadata)
    meta_data = Column(JSON)  # Intent, entities, etc.
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
