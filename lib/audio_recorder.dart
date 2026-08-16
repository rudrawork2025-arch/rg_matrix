import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  RecordingState _state = RecordingState.idle;
  Timer? _timer;
  int _secondsElapsed = 0;
  String? _recordedFilePath;
  bool _isPlaying = false;

  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _timer?.cancel();
    _playerStateSub?.cancel();
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
      setState(() {
        _secondsElapsed++;
      });
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
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

    setState(() {
      _state = RecordingState.recording;
      _secondsElapsed = 0;
      _recordedFilePath = filePath;
    });
    _startTimer();
  }

  // ---------------- PAUSE / RESUME ----------------
  Future<void> _togglePause() async {
    if (_state == RecordingState.recording) {
      await _audioRecorder.pause();
      _stopTimer();
      setState(() => _state = RecordingState.paused);
    } else if (_state == RecordingState.paused) {
      await _audioRecorder.resume();
      _startTimer();
      setState(() => _state = RecordingState.recording);
    }
  }

  // ---------------- STOP ----------------
  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    _stopTimer();
    setState(() {
      _state = RecordingState.stopped;
      _recordedFilePath = path ?? _recordedFilePath;
    });
  }

  // ---------------- PLAY / PAUSE PLAYBACK (just_audio) ----------------
  Future<void> _togglePlayback() async {
    if (_recordedFilePath == null) return;

    final file = File(_recordedFilePath!);

    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Recording file not found."),
          ),
        );
      }
      return;
    }

    if (_isPlaying) {
      // Currently playing -> pause
      await _audioPlayer.pause();
    } else {
      // Always load the CURRENT recording.
      await _audioPlayer.stop();

      await _audioPlayer.setFilePath(
        _recordedFilePath!,
      );

      await _audioPlayer.play();
    }
  }

  // ---------------- RESTART / NEW RECORDING ----------------
  Future<void> _resetRecording() async {
    // Stop the old playback completely.
    await _audioPlayer.stop();

    // Reset the recorder state.
    setState(() {
      _state = RecordingState.idle;
      _secondsElapsed = 0;
      _recordedFilePath = null;
      _isPlaying = false;
    });

    // Start a completely new recording.
    await _startRecording();
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      color: primaryColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
          const SizedBox(width: 48), // balances the back button
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
          style: TextStyle(color: Colors.grey, fontSize: 13),
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

  // ---------------- MIC CIRCLE (tap to start if idle) ----------------
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
            child: const Icon(Icons.mic, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }

  String _statusLabel() {
    switch (_state) {
      case RecordingState.idle:
        return "Tap mic to start";
      case RecordingState.recording:
        return "Recording...";
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
      // Nothing recording yet, or already stopped -> no pause/stop row
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
              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _stopRecording,
            icon: const Icon(Icons.stop_circle, color: Colors.white),
            label: const Text(
              "Stop",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- HINT CARD (before/while recording) ----------------
  Widget _buildHintCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Speak now...",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            "AI will convert your conversation into clinical notes.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ---------------- PLAYBACK CARD (after stop) ----------------
  Widget _buildPlaybackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recording ready",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Duration: $_formattedTime",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (_recordedFilePath != null) ...[
            const SizedBox(height: 4),
            Text(
              "File: ${p.basename(_recordedFilePath!)}",
              style: const TextStyle(color: Colors.grey, fontSize: 11),
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
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Handle "Use this recording" / send to AI tap here
                    // "_recordedFilePath" holds the local file path of the recording
                    // Example: uploadRecordingForNotes(_recordedFilePath!);
                  },
                  icon: const Icon(Icons.check_circle_outline, color: primaryColor),
                  label: const Text(
                    "Use Recording",
                    style: TextStyle(color: primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}