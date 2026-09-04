# schemas.py
# These are "Pydantic" models. They define what data the API expects
# to receive (PatientCreate) and what data it will send back (PatientOut).

from pydantic import BaseModel


class PatientCreate(BaseModel):
    """Shape of the data required to add a new patient."""
    name: str
    age: int
    gender: str
    phone_number: str


class PatientOut(PatientCreate):
    """Shape of the data returned to the client, includes the database id."""
    id: int

    class Config:
        from_attributes = True  # allows conversion from SQLAlchemy model -> Pydantic model