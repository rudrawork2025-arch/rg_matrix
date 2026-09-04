# main.py
# This is the entry point of our FastAPI backend.
# It defines two endpoints:
#   POST /patients  -> add a new patient
#   GET  /patients   -> get all patients

from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session

import models
import schemas
from database import engine, SessionLocal, Base

# This line creates the "patients" table in prism.db if it doesn't exist yet.
Base.metadata.create_all(bind=engine)

app = FastAPI(title="PRISM Healthcare API")


# get_db() creates a new database session for each request,
# and makes sure it's closed afterward, even if an error happens.
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.post("/patients", response_model=schemas.PatientOut)
def add_patient(patient: schemas.PatientCreate, db: Session = Depends(get_db)):
    """
    Add a new patient.
    Receives patient details in the request body and saves them to the database.
    """
    new_patient = models.Patient(
        name=patient.name,
        age=patient.age,
        gender=patient.gender,
        phone_number=patient.phone_number,
    )
    db.add(new_patient)
    db.commit()
    db.refresh(new_patient)  # refresh so we get the auto-generated id back
    return new_patient


@app.get("/patients", response_model=list[schemas.PatientOut])
def get_patients(db: Session = Depends(get_db)):
    """
    Return all patients currently saved in the database.
    """
    return db.query(models.Patient).all()