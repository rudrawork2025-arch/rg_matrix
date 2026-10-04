import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemUiOverlayStyle
import 'package:http/http.dart' as http;

import 'dashboard.dart';
import 'patient_profile_screen.dart';
import 'new_patient.dart';
import 'notes_screen.dart';
import 'profile_screen.dart'; // Added import for Profile Screen routing

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  static const Color primaryColor = Color(0xFF4B3FE4);
  static const Color backgroundColor = Color(0xFF161921); // Dark background
  static const Color cardColor = Color(0xFF222631); // Dark card background

  // Use the SAME IP address as new_patient.dart
  // Change the IP to 127.0.0.1 to route through your wireless debugging connection
  static const String baseUrl = 'http://127.0.0.1:8000';
  final TextEditingController _searchController = TextEditingController();

  int _currentNavIndex = 1;

  List<Map<String, String>> _allPatients = [];
  List<Map<String, String>> _filteredPatients = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPatients);
    _loadPatients();
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
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

// ---------------- LOAD PATIENTS FROM BACKEND ----------------
  Future<void> _loadPatients() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/patients'),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final patients = data.map<Map<String, String>>((patient) {
          return {
            'name': patient['name']?.toString() ?? 'Unknown Patient',
            'id': 'P-${patient['id']}',
            'age': patient['age']?.toString() ?? '',
            'gender': patient['gender']?.toString() ?? '',
            'phone': patient['phone_number']?.toString() ?? '',
            'lastSession': 'No consultation yet',
            'notes': 'No clinical notes available yet.',
          };
        }).toList();

        if (!mounted) return;

        setState(() {
          _allPatients = patients;
          _filteredPatients = patients;
          _isLoading = false;
        });

        _filterPatients();
      } else {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
          'Failed to load patients. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('PATIENT API ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not connect to the backend: $e';
      });
    }
  }

// ---------------- SEARCH PATIENTS ----------------
  void _filterPatients() {
    final query = _searchController.text.trim().toLowerCase();

    if (!mounted) return;

    setState(() {
      _filteredPatients = _allPatients.where((patient) {
        final name = patient['name']?.toLowerCase() ?? '';
        final id = patient['id']?.toLowerCase() ?? '';

        return name.contains(query) || id.contains(query);
      }).toList();
    });
  }

// ---------------- GET INITIALS ----------------
  String _getInitials(String name) {
    final parts =
    name.trim().split(' ').where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return '?';

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    if (parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrapped to fix invisible status bar icons in dark mode
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor, // Applied deep dark background
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSearchBar(),
              ),
              Expanded(
                child: _buildPatientsContent(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

// ---------------- PATIENT CONTENT ----------------
  Widget _buildPatientsContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 50,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPatients,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredPatients.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPatients,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.people_outline,
              size: 60,
              color: Colors.grey.shade600, // Slightly darker grey for dark theme
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No patients found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) {
          return _patientTile(
            context,
            _filteredPatients[index],
          );
        },
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
      color: Colors.transparent, // Blends seamlessly into the dark background
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white, // Icons remain white
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const Text(
            'Patients',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.person_add_alt_1,
              color: Colors.white,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NewPatientScreen(),
                ),
              );

              // Reload patients when returning from Add New Patient
              _loadPatients();
            },
          ),
        ],
      ),
    );
  }

// ---------------- SEARCH BAR ----------------
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor, // Dark card background
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Darker shadow
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white), // White text when typing
        decoration: InputDecoration(
          hintText: 'Search patients...',
          hintStyle: TextStyle(color: Colors.grey[400]), // Lighter hint text
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

// ---------------- PATIENT TILE ----------------
  Widget _patientTile(
      BuildContext context,
      Map<String, String> patient,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor, // Dark card background
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: primaryColor.withOpacity(0.15),
          child: Text(
            _getInitials(patient['name']!),
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient['name']!,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white, // White text for patient name
          ),
        ),
        subtitle: Text(
          '${patient['id']}\nLast session: ${patient['lastSession']}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400], // Lighter grey for subtitle
            height: 1.4,
          ),
        ),
        isThreeLine: true,
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[500],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientProfileScreen(
                patientName: patient['name']!,
                patientId: patient['id']!,
                age: patient['age']!,
                gender: patient['gender']!,
                phone: patient['phone']!,
                notes: patient['notes']!,
                sessions: [
                  patient['lastSession']!,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// ---------------- SLEEK BOTTOM NAV BAR (ANIMATED) ----------------
  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor, // Match dark background
        border: Border(top: BorderSide(color: cardColor, width: 1)), // Subtle dark border line
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        elevation: 0,
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _currentNavIndex) return; // Prevent routing to the same screen

          if (index == 0) _navigateWithFade(context, const DoctorHomeScreen());
          // if (index == 1) do nothing, we are already on PatientsScreen
          if (index == 2) _navigateWithFade(context, const NotesScreen());
          if (index == 3) _navigateWithFade(context, const ProfileScreen());
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'), // Solid icon when active
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}