// consultation_screen.dart
// ============================================================================
// Audio Recorder / Consultation screen (FULLY EDITED)
//
// Changes made vs. the original:
//   1. Removed the now-unused `dart:convert` / `http` imports — the file
//      upload + conversion logic lives in `use_recording.dart`.
//   2. Added  import 'use_recording.dart';
//   3. Added `_openUseRecordingScreen()` — opens UseRecordingScreen, which
//      uploads the recorded file to the FastAPI backend (/transcribe),
//      converts it to text, and returns the final text.
//   4. The "Use Recording" button is now wired to _openUseRecordingScreen().
//      When the user taps "Use This Text" on that screen, this screen
//      replaces the live transcription with the final server result.
//
// NOTE: put `use_recording.dart` in the SAME folder as this file.
// If it lives somewhere else, fix the import path, e.g.:
//   import '../screens/use_recording.dart';
// ============================================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'use_recording.dart';

class ConsultationScreen extends StatefulWidget {
  final String patientName;
  final String patientId;

  const ConsultationScreen({
    super.key,
    this.patientName = "Rahul Sharma",
    this.patientId = "P-001",
  });

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

enum RecordingState { idle, recording, paused, stopped }

class _ConsultationScreenState extends State<ConsultationScreen> {
  static const Color primaryColor = Color(0xFF4B3FE4);

  // Base URL of your FastAPI backend:
  //   Android emulator -> http://10.0.2.2:8000
  //   iOS simulator    -> http://localhost:8000
  //   Real phone       -> http://<YOUR_COMPUTER_LAN_IP>:8000
  // Changed to 127.0.0.1 to match your wireless debugging tunnel
  static const String _apiBaseUrl = 'http://127.0.0.1:8000';

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

// Speech to Text
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _speechEnabled = false;
  String _transcription = '';

  RecordingState _state = RecordingState.idle;
  Timer? _timer;
  int _secondsElapsed = 0;
  String? _recordedFilePath;
  bool _isPlaying = false;

  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();

    _initializeSpeech();

    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();

        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      } else if (mounted && _isPlaying != isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });
  }

// ---------------- INITIALIZE SPEECH TO TEXT ----------------
  Future<void> _initializeSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        print('Speech status: $status');
      },
      onError: (error) {
        print('Speech error: $error');
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

// ---------------- START SPEECH TO TEXT ----------------
  Future<void> _startSpeechToText() async {
    if (!_speechEnabled) {
      await _initializeSpeech();
    }

    if (!_speechEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available.'),
          ),
        );
      }
      return;
    }

    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _transcription = result.recognizedWords;
          });
        }
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
    );
  }

// ---------------- STOP SPEECH TO TEXT ----------------
  Future<void> _stopSpeechToText() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerStateSub?.cancel();

    _speechToText.stop();

    _audioRecorder.dispose();
    _audioPlayer.dispose();

    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

// ---------------- START RECORDING ----------------
  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission is required.")),
        );
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = "consultation_${DateTime.now().millisecondsSinceEpoch}.m4a";
    final filePath = p.join(dir.path, fileName);

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: filePath,
    );

    setState(() {
      _state = RecordingState.recording;
      _secondsElapsed = 0;
      _recordedFilePath = filePath;
      _transcription = ''; // We will rely on Whisper for the transcription now
    });

    _startTimer();

    // 🛑 COMMENT OUT THIS LINE TO FIX THE SILENT AUDIO BUG:
    // await _startSpeechToText();
  }

// ---------------- PAUSE / RESUME ----------------
  Future<void> _togglePause() async {
    if (_state == RecordingState.recording) {
      await _audioRecorder.pause();
      await _stopSpeechToText();
      _stopTimer();

      setState(() {
        _state = RecordingState.paused;
      });
    } else if (_state == RecordingState.paused) {
      await _audioRecorder.resume();
      _startTimer();

      setState(() {
        _state = RecordingState.recording;
      });

      // 🛑 COMMENT OUT THIS LINE AS WELL:
      // await _startSpeechToText();
    }
  }

  // ---------------- STOP RECORDING ----------------
  Future<void> _stopRecording() async {
    try {
      await _stopSpeechToText();

      final stoppedPath = await _audioRecorder.stop();

      _stopTimer();

      final finalPath = stoppedPath ?? _recordedFilePath;

      if (finalPath == null) {
        throw Exception("Recording path is empty.");
      }

      final file = File(finalPath);

      // Give the recorder a moment to finish writing the file.
      await Future.delayed(const Duration(milliseconds: 300));

      if (!await file.exists()) {
        throw Exception("Recording file was not created.");
      }

      final fileSize = await file.length();

      debugPrint("Recorded file path: $finalPath");
      debugPrint("Recorded file size: $fileSize bytes");

      if (fileSize == 0) {
        throw Exception("Recording file is empty.");
      }

      await _audioPlayer.stop();

      if (mounted) {
        setState(() {
          _state = RecordingState.stopped;
          _recordedFilePath = finalPath;
          _isPlaying = false;
        });
      }
    } catch (error) {
      debugPrint("Stop recording error: $error");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not save recording: $error"),
          ),
        );
      }
    }
  }

  // ---------------- PLAY / PAUSE PLAYBACK ----------------
  Future<void> _togglePlayback() async {
    final path = _recordedFilePath;

    if (path == null || path.isEmpty) {
      return;
    }

    try {
      // Clean path in case it contains 'file://' prefix which breaks File() and playback on iOS
      final cleanPath = path.startsWith('file://') ? path.replaceFirst('file://', '') : path;
      final file = File(cleanPath);

      if (!await file.exists()) {
        throw Exception("Recording file does not exist.");
      }

      final fileSize = await file.length();

      debugPrint("Playing file: $cleanPath");
      debugPrint("File size: $fileSize bytes");

      if (fileSize == 0) {
        throw Exception("Recording file is empty.");
      }

      if (_isPlaying) {
        await _audioPlayer.pause();
        return;
      }

      // If the player has already loaded the file and is paused or completed, just play/seek
      if (_audioPlayer.processingState == ProcessingState.ready ||
          _audioPlayer.processingState == ProcessingState.completed) {
        if (_audioPlayer.processingState == ProcessingState.completed) {
          await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.play();
        return;
      }

      await _audioPlayer.stop();

      // Use setFilePath instead of AudioSource.file() for reliable local file playback
      await _audioPlayer.setFilePath(cleanPath);

      await _audioPlayer.play();
    } catch (error) {
      debugPrint("Playback error: $error");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Playback failed: $error"),
          ),
        );
      }
    }
  }

// ---------------- RESTART / NEW RECORDING ----------------
  Future<void> _resetRecording() async {
    await _audioPlayer.stop();

    await _stopSpeechToText();

    setState(() {
      _state = RecordingState.idle;
      _secondsElapsed = 0;
      _recordedFilePath = null;
      _isPlaying = false;
      _transcription = '';
    });

    await _startRecording();
  }

// ---------------- USE RECORDING (open screen that uploads + converts) ----------------
  Future<void> _openUseRecordingScreen() async {
    final path = _recordedFilePath;
    if (path == null) return;

    // Open the dedicated "Use Recording" screen. It automatically uploads
    // the audio file to the backend (/transcribe), shows a spinner while
    // Whisper converts it, and pops back with the final text when the user
    // taps "Use This Text".
    final text = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        // FIXED: Only passing audioPath to match the UseRecordingScreen constructor
        builder: (_) => UseRecordingScreen(
          audioPath: path,
        ),
      ),
    );

    if (!mounted || text == null || text.isEmpty) return;

    setState(() {
      // Replace the live (on-device) transcription with the final,
      // more accurate server-side Whisper result.
      _transcription = text;
    });

    // TODO (next step): open your note-creation screen with this text, e.g.
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (_) => YourNoteScreen(
    //         patientName: widget.patientName,
    //         patientId: widget.patientId,
    //         initialText: text,
    //       ),
    //     ),
    //   );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    _buildPatientInfo(),
                    const SizedBox(height: 40),
                    _buildMicCircle(),
                    const SizedBox(height: 24),
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _statusLabel(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildControlButtons(),
                    const SizedBox(height: 24),
                    // LIVE TRANSCRIPTION
                    _buildTranscriptionCard(),
                    const SizedBox(height: 16),
                    if (_state == RecordingState.stopped)
                      _buildPlaybackCard()
                    else
                      _buildHintCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ---------------- APP BAR ----------------
  Widget _buildAppBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 14,
      ),
      color: primaryColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Text(
              "Consultation",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

// ---------------- PATIENT INFO ----------------
  Widget _buildPatientInfo() {
    return Column(
      children: [
        const Text(
          "Patient",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${widget.patientName} (${widget.patientId})",
          style: const TextStyle(
            color: primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

// ---------------- MIC CIRCLE ----------------
  Widget _buildMicCircle() {
    return GestureDetector(
      onTap: () {
        if (_state == RecordingState.idle) {
          _startRecording();
        }
      },
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor.withOpacity(0.08),
        ),
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
            ),
            child: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

// ---------------- STATUS ----------------
  String _statusLabel() {
    switch (_state) {
      case RecordingState.idle:
        return "Tap mic to start";

      case RecordingState.recording:
        return "Recording and transcribing...";

      case RecordingState.paused:
        return "Paused";

      case RecordingState.stopped:
        return "Recording stopped";
    }
  }

  Color _statusColor() {
    switch (_state) {
      case RecordingState.recording:
        return primaryColor;

      case RecordingState.paused:
        return Colors.orange;

      case RecordingState.stopped:
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

// ---------------- PAUSE / STOP BUTTONS ----------------
  Widget _buildControlButtons() {
    final bool isActive =
        _state == RecordingState.recording || _state == RecordingState.paused;

    if (!isActive) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _togglePause,
            icon: Icon(
              _state == RecordingState.recording
                  ? Icons.pause
                  : Icons.play_arrow,
              color: primaryColor,
            ),
            label: Text(
              _state == RecordingState.recording ? "Pause" : "Resume",
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _stopRecording,
            icon: const Icon(
              Icons.stop_circle,
              color: Colors.white,
            ),
            label: const Text(
              "Stop",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

// ---------------- LIVE TRANSCRIPTION CARD ----------------
  Widget _buildTranscriptionCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 140,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.text_snippet_outlined,
                color: primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                "Live Transcription",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _transcription.isEmpty
                ? "Start speaking and your words will appear here..."
                : _transcription,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: _transcription.isEmpty ? Colors.grey : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

// ---------------- HINT CARD ----------------
  Widget _buildHintCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Speak now...",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Your conversation will be converted into text.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

// ---------------- PLAYBACK CARD ----------------
  Widget _buildPlaybackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recording ready",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Duration: $_formattedTime",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          if (_recordedFilePath != null) ...[
            const SizedBox(height: 4),
            Text(
              "File: ${p.basename(_recordedFilePath!)}",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _togglePlayback,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isPlaying ? "Pause" : "Play Recording",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  // ---- EDITED: "Use Recording" now opens UseRecordingScreen ----
                  onPressed: _recordedFilePath == null
                      ? null
                      : _openUseRecordingScreen,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: primaryColor,
                  ),
                  label: const Text(
                    "Use Recording",
                    style: TextStyle(
                      color: primaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: primaryColor,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _resetRecording,
              child: const Text(
                "Record Again",
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}