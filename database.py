# database.py
# This file sets up the connection to our local SQLite database.

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# The database will be stored as a file called "prism.db" in this same folder.
# SQLite is a simple file-based database — perfect for getting started.
SQLALCHEMY_DATABASE_URL = "sqlite:///./prism.db"

# check_same_thread=False is needed only for SQLite, so FastAPI can use
# the same database connection across multiple requests.
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

# SessionLocal is what we use to talk to the database in each request.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base is the parent class our database models (tables) will inherit from.
Base = declarative_base()