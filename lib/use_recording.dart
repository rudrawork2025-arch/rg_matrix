import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Make sure this file exists in your lib folder!
import 'clinical_note_editor.dart';

class UseRecordingScreen extends StatefulWidget {
  final String audioPath;

  const UseRecordingScreen({super.key, required this.audioPath});

  @override
  State<UseRecordingScreen> createState() => _UseRecordingScreenState();
}

class _UseRecordingScreenState extends State<UseRecordingScreen> {
  bool _isLoading = true;
  String _transcribedText = '';
  String _detectedLanguage = '';
  double? _duration;
  String? _errorMessage;

  // ADB Tunnel configuration
  final String _endpointUrl = 'http://127.0.0.1:8000/transcribe';

  @override
  void initState() {
    super.initState();
    _sendAudioToBackend();
  }

  Future<void> _sendAudioToBackend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final file = File(widget.audioPath);
      if (!await file.exists()) {
        throw Exception("Audio recording file not found at ${widget.audioPath}");
      }

      final request = http.MultipartRequest('POST', Uri.parse(_endpointUrl));

      request.files.add(
        await http.MultipartFile.fromPath('file', widget.audioPath),
      );

      // 60-second timeout to give Whisper AI plenty of time to process
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _transcribedText = data['text'] ?? '';
          _detectedLanguage = data['language'] ?? 'Unknown';
          _duration = (data['duration'] as num?)?.toDouble();
          _isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['detail'] ?? 'Failed to transcribe audio';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  // ---- Added Copy to Clipboard Feature ----
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _transcribedText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Clinical note copied to clipboard",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF14B8A6), // Medical Teal
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Premium Dark Theme Colors
    const bgColor = Color(0xFF0F1115);
    const cardColor = Color(0xFF181B21);
    const indigoAccent = Color(0xFF6366F1);
    const tealAccent = Color(0xFF14B8A6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'AI Consultation Note',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------- LOADING STATE ----------------
              if (_isLoading) ...[
                const Spacer(),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: indigoAccent.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: indigoAccent,
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Prism AI is analyzing audio...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Translating & structuring clinical note',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                ),
                const Spacer(),
              ]

              // ---------------- ERROR STATE ----------------
              else if (_errorMessage != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _sendAudioToBackend,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Retry Transcription', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ]

              // ---------------- SUCCESS UI STATE ----------------
              else ...[
                  // Metadata Badges (Language & Duration)
                  Row(
                    children: [
                      _buildBadge(
                        icon: Icons.language,
                        text: _detectedLanguage.toUpperCase(),
                        color: indigoAccent,
                      ),
                      const SizedBox(width: 12),
                      if (_duration != null)
                        _buildBadge(
                          icon: Icons.timer_outlined,
                          text: '${_duration!.toStringAsFixed(1)}s',
                          color: tealAccent,
                        ),
                      const Spacer(),
                      // Status dot
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: tealAccent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text("Ready", style: TextStyle(color: tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Main Transcription Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Card Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: indigoAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Auto-Translated Note",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                // Copy Button
                                InkWell(
                                  onTap: _copyToClipboard,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Icon(Icons.copy_rounded, color: Colors.white.withOpacity(0.5), size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Scrollable Text Area
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: SelectableText(
                                _transcribedText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.7,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Buttons
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the Clinical Note Editor Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClinicalNoteEditorScreen(
                            patientName: "Rahul Sharma",
                            patientId: "P-001",
                            initialText: _transcribedText,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: indigoAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirm & Save to File',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Discard Recording',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the metadata tags
  Widget _buildBadge({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}