import 'package:flutter/material.dart';

import 'audio_recorder.dart';
import 'new_patient.dart';
import 'patient_profile_screen.dart';
import 'patient_screen.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      // ------------------------------------------------------------
      // BODY
      // ------------------------------------------------------------
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
      // ------------------------------------------------------------
      // BOTTOM NAVIGATION
      // ------------------------------------------------------------
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double titleSize = width < 360 ? 18 : 20;
        final double smallTextSize = width < 360 ? 12 : 13;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          decoration: const BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.menu, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good Morning,",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: smallTextSize,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Dr. Rohan 👋",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.notifications_none, color: Colors.white),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // STATS GRID
  // ============================================================
  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        const double spacing = 12;
        final double cardWidth = (screenWidth - spacing) / 2;
        double cardHeight = cardWidth * 0.72;

        cardHeight = cardHeight.clamp(115.0, 145.0);

        return Transform.translate(
          offset: const Offset(0, -20),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: cardWidth / cardHeight,
            children: [
              _statCard(
                Icons.person,
                "Total Patients",
                "54",
                Colors.indigo,
              ),
              _statCard(
                Icons.calendar_today,
                "Today's Consultations",
                "4",
                Colors.deepPurple,
              ),
              _statCard(
                Icons.description_outlined,
                "Notes Generated",
                "18",
                Colors.indigo,
              ),
              _statCard(
                Icons.access_time,
                "Pending Notes",
                "3",
                Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================
  Widget _statCard(
      IconData icon,
      String label,
      String value,
      Color iconColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: () {
            // TODO: Add View All Consultations screen later.
          },
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
  // CONSULTATION TILE
  // ============================================================
  Widget _consultationTile(
      BuildContext context,
      Map<String, String> consultation,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: const Icon(Icons.person, color: primaryColor),
        ),
        title: Text(
          consultation["name"] ?? "Unknown Patient",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(consultation["time"] ?? "No time"),
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
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================
  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PatientsScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: "Patients",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "Profile",
        ),
      ],
    );
  }
}