import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dashboard.dart';
import 'patient_profile_screen.dart';
import 'new_patient.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  static const Color primaryColor = Color(0xFF4B3FE4);

// Use the SAME IP address as new_patient.dart
  static const String baseUrl = 'http://192.168.0.12:8000';
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
          .timeout(const Duration(seconds: 10));

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
      print('PATIENT API ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    } catch (e) {
      print('PATIENT API ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
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
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.people_outline,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(
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
      color: primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search patients...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
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
          ),
        ),
        subtitle: Text(
          '${patient['id']}\nLast session: ${patient['lastSession']}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            height: 1.4,
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
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

// ---------------- BOTTOM NAV BAR ----------------
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        setState(() {
          _currentNavIndex = index;
        });

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DoctorHomeScreen(),
            ),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Patients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}