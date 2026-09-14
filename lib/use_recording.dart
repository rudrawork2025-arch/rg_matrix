// use_recording.dart
//
// Screen shown when the user taps "Use Recording" in the consultation
// (audio recorder) screen.
//
// What it does:
//   1. Receives the recorded audio file path (plus patient info).
//   2. Automatically uploads the file to the FastAPI backend:
//        POST {baseUrl}/transcribe   (multipart/form-data, field name = "file")
//   3. Shows a loading state while the backend (Whisper) converts it.
//   4. Shows the returned text in an editable box.
//   5. When the user taps "Use This Text", pops back and returns the
//      (possibly edited) text via Navigator.pop(context, text).
//
// The caller screen decides what to do with the returned text
// (e.g. create a note / open the note editor).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

const Color _kPrimary = Color(0xFF4B3FE4);

class UseRecordingScreen extends StatefulWidget {
  /// Absolute path of the recorded audio file on the device.
  final String filePath;

  /// Patient details (optional, shown only as context).
  final String patientName;
  final String patientId;

  /// Base URL of your FastAPI backend.
  ///
  ///   Android emulator  -> http://10.0.2.2:8000
  ///   iOS simulator     -> http://localhost:8000
  ///   Real phone        -> http://<YOUR_COMPUTER_LAN_IP>:8000
  final String baseUrl;

  const UseRecordingScreen({
    super.key,
    required this.filePath,
    this.patientName = 'Patient',
    this.patientId = '',
    this.baseUrl = 'http://10.0.2.2:8000',
  });

  @override
  State<UseRecordingScreen> createState() => _UseRecordingScreenState();
}

class _UseRecordingScreenState extends State<UseRecordingScreen> {
  final TextEditingController _textController = TextEditingController();

  bool _isConverting = false;
  bool _gotResult = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Start uploading + converting as soon as this screen opens.
    _convertToText();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Upload the audio file and convert it to text (Whisper on the backend).
  // ---------------------------------------------------------------------
  Future<void> _convertToText() async {
    setState(() {
      _isConverting = true;
      _gotResult = false;
      _errorMessage = null;
    });

    final file = File(widget.filePath);
    if (!await file.exists()) {
      _setError('Recording file not found:\n${widget.filePath}');
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.baseUrl}/transcribe'),
      );

      // The field name MUST be "file" — that is what the FastAPI
      // endpoint expects (UploadFile = File(...)).
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          widget.filePath,
          filename: p.basename(widget.filePath),
        ),
      );

      // Whisper can take a while (especially the very first request,
      // while the backend loads the model), so allow up to 3 minutes.
      final streamed = await request.send().timeout(
        const Duration(minutes: 3),
      );
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200) {
        String text = '';
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
          text = (data['text'] as String? ?? '').trim();
        } catch (_) {
          // Not JSON for some reason — fall back to plain text body.
          text = utf8.decode(response.bodyBytes).trim();
        }

        setState(() {
          _isConverting = false;
          _gotResult = true;
          _textController.text = text;
        });

        if (text.isEmpty) {
          _showSnack('No speech detected. Please record again.');
        }
      } else {
        // Try to show the backend's "detail" message if it exists.
        String detail = 'Server error (${response.statusCode})';
        try {
          final err = jsonDecode(utf8.decode(response.bodyBytes));
          if (err is Map<String, dynamic> && err['detail'] != null) {
            detail = err['detail'].toString();
          }
        } catch (_) {}
        _setError(detail);
      }
    } on TimeoutException {
      _setError(
        'Request timed out. The backend may still be loading the '
            'Whisper model on the very first call. Please try again.',
      );
    } catch (e) {
      _setError(
        'Could not reach the server.\n'
            'Check that the backend is running and the base URL is correct.\n\n'
            '$e',
      );
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _isConverting = false;
      _gotResult = false;
      _errorMessage = message;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Called by the "Use This Text" button. Returns the text to the
  // previous screen (the consultation screen).
  void _confirmText() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showSnack('The text is empty. Record again or type something.');
      return;
    }
    Navigator.pop(context, text);
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        title: const Text('Use Recording'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPatientCard(),
              const SizedBox(height: 20),
              if (_isConverting)
                _buildConvertingCard()
              else if (_errorMessage != null)
                _buildErrorCard()
              else if (_gotResult)
                  _buildResultCard()
                else
                  _buildErrorCard(
                    message: 'Unexpected state — please tap Try Again.',
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------- PATIENT + FILE CARD -------------------------
  Widget _buildPatientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: _kPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.patientName.isEmpty
                      ? 'Patient'
                      : '${widget.patientName}'
                      '${widget.patientId.isNotEmpty ? ' (${widget.patientId})' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.audio_file_outlined,
                  color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.basename(widget.filePath),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------- CONVERTING -----------------------------
  Widget _buildConvertingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: _kPrimary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Converting audio to text…',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait. The first conversion can take longer because the '
                'backend loads the speech model once.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------- ERROR --------------------------------
  Widget _buildErrorCard({String? message}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message ?? _errorMessage ?? 'Unexpected error.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _convertToText,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
          ),
        ],
      ),
    );
  }

  // ------------------------------ RESULT --------------------------------
  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.text_snippet_outlined, color: _kPrimary),
              SizedBox(width: 8),
              Text(
                'Transcribed text',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You can edit the text below before using it.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _textController,
            minLines: 6,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Transcribed text will appear here…',
              filled: true,
              fillColor: const Color(0xFFF7F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _textController,
            builder: (context, value, _) => Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${value.text.length} characters',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _convertToText,
                  icon: const Icon(Icons.refresh, color: _kPrimary),
                  label: const Text(
                    'Reconvert',
                    style: TextStyle(color: _kPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kPrimary),
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
                  onPressed: _confirmText,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Use This Text',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
