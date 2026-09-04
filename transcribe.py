# transcribe.py
# This file adds the Speech-to-Text feature as its own separate router.
# It does not touch models.py, schemas.py, or the /patients endpoints at all.

import os
import shutil
import tempfile

import whisper
from fastapi import APIRouter, UploadFile, File, HTTPException

router = APIRouter()

# Which audio file types we accept.
ALLOWED_EXTENSIONS = {".m4a", ".mp3", ".wav"}

# Whisper model size. "base" is a good balance of speed vs accuracy for a
# beginner project. Other options: "tiny", "small", "medium", "large".
WHISPER_MODEL_SIZE = "base"

# We load the model once and reuse it for every request, instead of
# reloading it every time (that would be slow). This happens the first
# time /transcribe is called, then stays cached in memory.
_model = None


def get_model():
    global _model
    if _model is None:
        _model = whisper.load_model(WHISPER_MODEL_SIZE)
    return _model


@router.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    """
    Accepts an uploaded audio file (.m4a, .mp3, or .wav), saves it
    temporarily, runs it through a locally-loaded Whisper model, and
    returns the transcribed text.
    """
    # --- 1. Validate the file extension ---
    original_name = file.filename or ""
    ext = os.path.splitext(original_name)[1].lower()

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type '{ext}'. Allowed types: .m4a, .mp3, .wav",
        )

    # --- 2. Save the uploaded file to a temporary location on disk ---
    # Whisper needs an actual file path to read from, so we write the
    # uploaded bytes to a temp file with the same extension.
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as tmp_file:
            shutil.copyfileobj(file.file, tmp_file)
            tmp_path = tmp_file.name

        # --- 3. Run local Whisper transcription ---
        model = get_model()
        result = model.transcribe(tmp_path)
        transcribed_text = result.get("text", "").strip()

        # --- 4. Return the transcribed text as JSON ---
        return {"text": transcribed_text}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")
    finally:
        # Always clean up the temporary file, even if something went wrong.
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)
        await file.close()