import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemUiOverlayStyle
import 'package:shared_preferences/shared_preferences.dart'; // Added to load the saved name

import 'audio_recorder.dart';
import 'new_patient.dart';
import 'patient_profile_screen.dart';
import 'patient_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final String? doctorName;

  const DoctorHomeScreen({super.key, this.doctorName});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  String _displayName = 'Doctor'; // Default fallback

  @override
  void initState() {
    super.initState();
    if (widget.doctorName != null) {
      _displayName = widget.doctorName!;
    }
    _loadDoctorName(); // Dynamically load name whenever the screen opens
  }

  // Automatically fetches the name from local storage to prevent it from resetting
  Future<void> _loadDoctorName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('saved_name');

    if (savedName != null && savedName.trim().isNotEmpty) {
      final cleanName = savedName.trim().split(' ')[0]; // Extract just the first name
      if (mounted) {
        setState(() {
          _displayName = cleanName[0].toUpperCase() + cleanName.substring(1);
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning,";
    } else if (hour < 17) {
      return "Good Afternoon,";
    } else {
      return "Good Evening,";
    }
  }

  // ------------------------------------------------------------
  // SAMPLE CONSULTATION DATA
  // ------------------------------------------------------------
  final List<Map<String, String>> consultations = const [
    {
      "name": "Rahul Sharma",
      "id": "P-001",
      "time": "10:00 AM",
      "age": "28",
      "gender": "Male",
      "phone": "9876543210",
      "notes": "Patient experiencing work related stress and sleep disturbances.",
    },
    {
      "name": "Priya Mehta",
      "id": "P-002",
      "time": "11:30 AM",
      "age": "31",
      "gender": "Female",
      "phone": "9876543211",
      "notes": "Patient reports anxiety related to work and personal responsibilities.",
    },
    {
      "name": "Amit Patel",
      "id": "P-003",
      "time": "02:00 PM",
      "age": "25",
      "gender": "Male",
      "phone": "9876543212",
      "notes": "Patient experiencing difficulty concentrating and maintaining routines.",
    },
    {
      "name": "Sneha Joshi",
      "id": "P-004",
      "time": "04:00 PM",
      "age": "29",
      "gender": "Female",
      "phone": "9876543213",
      "notes": "Patient reports sleep difficulties and occasional anxiety.",
    },
  ];

  static const Color primaryColor = Color(0xFF4B3FE4);
  static const Color backgroundColor = Color(0xFF161921);
  static const Color cardColor = Color(0xFF222631);

  // ============================================================
  // CUSTOM FADE ANIMATION NAVIGATOR
  // ============================================================
  void _navigateWithFade(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
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
        body: SafeArea(
          child: Column(
            children: [
              _buildSimplifiedHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      _buildTodaysConsultationsHeader(context),
                      const SizedBox(height: 12),
                      _buildConsultationsList(context),
                      const SizedBox(height: 24),
                      _buildStartConsultationButton(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(context),
      ),
    );
  }

  // ============================================================
  // SIMPLIFIED FLAT HEADER (DARK MODE)
  // ============================================================
  Widget _buildSimplifiedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$_displayName 👋", // Displays the dynamically loaded name (e.g. "Rudra 👋")
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS GRID (DARK MODE)
  // ============================================================
  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        const double spacing = 12;
        final double cardWidth = (screenWidth - spacing) / 2;
        double cardHeight = cardWidth * 0.72;

        cardHeight = cardHeight.clamp(115.0, 145.0);

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: cardWidth / cardHeight,
          children: [
            _statCard(Icons.person, "Total Patients", "54", Colors.indigoAccent),
            _statCard(Icons.calendar_today, "Today's Consultations", "4", Colors.deepPurpleAccent),
            _statCard(Icons.description_outlined, "Notes Generated", "18", Colors.indigoAccent),
            _statCard(Icons.access_time, "Pending Notes", "3", Colors.orangeAccent),
          ],
        );
      },
    );
  }

  // ============================================================
  // STAT CARD (DARK MODE)
  // ============================================================
  Widget _statCard(IconData icon, String label, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY'S CONSULTATIONS HEADER
  // ============================================================
  Widget _buildTodaysConsultationsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Today's Consultations",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            "View All",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONSULTATIONS LIST
  // ============================================================
  Widget _buildConsultationsList(BuildContext context) {
    return Column(
      children: consultations.map((consultation) {
        return _consultationTile(context, consultation);
      }).toList(),
    );
  }

  // ============================================================
  // CONSULTATION TILE (DARK MODE)
  // ============================================================
  Widget _consultationTile(BuildContext context, Map<String, String> consultation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.15),
          child: const Icon(Icons.person, color: primaryColor),
        ),
        title: Text(
          consultation["name"] ?? "Unknown Patient",
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        subtitle: Text(
          consultation["time"] ?? "No time",
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: Text(
          consultation["status"] ?? "",
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientProfileScreen(
                patientName: consultation["name"]!,
                patientId: consultation["id"]!,
                age: consultation["age"]!,
                gender: consultation["gender"]!,
                phone: consultation["phone"]!,
                notes: consultation["notes"]!,
                sessions: const ["14 Sep 2026", "07 Sep 2026", "31 Aug 2026"],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // START CONSULTATION BUTTON
  // ============================================================
  Widget _buildStartConsultationButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewPatientScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Start Consultation",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
      ),
    );
  }

  // ============================================================
  // SLEEK BOTTOM NAVIGATION (DARK MODE)
  // ============================================================
  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: cardColor, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        elevation: 0,
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) _navigateWithFade(context, const PatientsScreen());
          if (index == 2) _navigateWithFade(context, const NotesScreen());
          if (index == 3) _navigateWithFade(context, const ProfileScreen());
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "Patients"),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: "Notes"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}