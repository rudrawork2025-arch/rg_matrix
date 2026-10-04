import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemUiOverlayStyle
import 'package:http/http.dart' as http; // Added for API calls

import 'dashboard.dart';
import 'patient_screen.dart';
import 'profile_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const Color primaryColor = Color(0xFF4B3FE4);
  static const Color backgroundColor = Color(0xFF161921); // Dark background
  static const Color cardColor = Color(0xFF222631); // Dark card background

  static const String baseUrl = 'http://127.0.0.1:8000';

  List<Map<String, dynamic>> _allNotes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // ---------------- LOAD NOTES FROM BACKEND ----------------
  Future<void> _loadNotes() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/notes'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final notes = data.map<Map<String, dynamic>>((note) {
          // Adjust these keys based on your FastAPI backend schema
          final bool isApproved = note['is_approved'] ?? false;
          return {
            "id": note['id']?.toString() ?? '',
            "patientName": note['patient_name']?.toString() ?? 'Unknown Patient',
            "date": note['date']?.toString() ?? 'Today',
            "time": note['time']?.toString() ?? '',
            "status": isApproved ? "PDF Saved" : "Pending Review",
            "isApproved": isApproved,
          };
        }).toList();

        if (!mounted) return;

        setState(() {
          _allNotes = notes;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load notes. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('NOTES API ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not connect to the backend: $e';
      });
    }
  }

  // ============================================================
  // CUSTOM FADE ANIMATION NAVIGATOR
  // ============================================================
  void _navigateWithFade(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Clinical Notes",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: _buildNotesContent(),
        ),
        // ============================================================
        // SLEEK BOTTOM NAVIGATION (ANIMATED)
        // ============================================================
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: backgroundColor,
            border: Border(top: BorderSide(color: cardColor, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: 2,
            elevation: 0,
            backgroundColor: backgroundColor,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade600,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              if (index == 2) return;

              if (index == 0) _navigateWithFade(context, const DoctorHomeScreen());
              if (index == 1) _navigateWithFade(context, const PatientsScreen());
              if (index == 3) _navigateWithFade(context, const ProfileScreen());
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "Patients"),
              BottomNavigationBarItem(icon: Icon(Icons.description), label: "Notes"),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT BUILDER (HANDLES LOADING, ERROR, & EMPTY STATES)
  // ============================================================
  Widget _buildNotesContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 50, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNotes,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_allNotes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotes,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Icon(Icons.description_outlined, size: 60, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No clinical notes found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allNotes.length,
        itemBuilder: (context, index) {
          final note = _allNotes[index];
          final bool isApproved = note["isApproved"] ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note["patientName"],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? Colors.greenAccent.withOpacity(0.15)
                              : Colors.orangeAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          note["status"],
                          style: TextStyle(
                            color: isApproved ? Colors.greenAccent[400] : Colors.orangeAccent[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(
                        "${note["date"]} • ${note["time"]}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement View/Edit API Logic
                          },
                          icon: Icon(
                            isApproved ? Icons.visibility_outlined : Icons.edit_note,
                            size: 18,
                          ),
                          label: Text(isApproved ? "View Note" : "Edit Note"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isApproved
                              ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Downloading PDF for ${note["patientName"]}..."),
                              ),
                            );
                          }
                              : null,
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text("Save PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[800],
                            disabledForegroundColor: Colors.grey[500],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}