import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'patient_profile_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  static const Color primaryColor = Color(0xFF4B3FE4);

  final TextEditingController _searchController = TextEditingController();
  int _currentNavIndex = 1; // "Patients" tab selected by default

  // Sample patient data
  final List<Map<String, String>> _allPatients = const [
    {
      "name": "Rahul Sharma",
      "id": "P-001",
      "lastSession": "14 Sep 2026",
      "age": "28",
      "gender": "Male",
      "phone": "9876543210",
      "notes": "Patient experiencing work related stress and sleep disturbances."
    },
    {
      "name": "Priya Mehta",
      "id": "P-002",
      "lastSession": "13 Sep 2026",
      "age": "31",
      "gender": "Female",
      "phone": "9876543211",
      "notes": "Patient reports anxiety related to work and personal responsibilities."
    },
    {
      "name": "Amit Patel",
      "id": "P-003",
      "lastSession": "12 Sep 2026",
      "age": "25",
      "gender": "Male",
      "phone": "9876543212",
      "notes": "Patient experiencing difficulty concentrating and maintaining routines."
    },
    {
      "name": "Sneha Joshi",
      "id": "P-004",
      "lastSession": "10 Sep 2026",
      "age": "29",
      "gender": "Female",
      "phone": "9876543213",
      "notes": "Patient reports sleep difficulties and occasional anxiety."
    },
    {
      "name": "Vikram Kapoor",
      "id": "P-005",
      "lastSession": "09 Sep 2026",
      "age": "35",
      "gender": "Male",
      "phone": "9876543214",
      "notes": "Patient experiencing stress related to workplace responsibilities."
    },
    {
      "name": "Anjali Nair",
      "id": "P-006",
      "lastSession": "08 Sep 2026",
      "age": "27",
      "gender": "Female",
      "phone": "9876543215",
      "notes": "Patient reports difficulty sleeping and managing daily stress."
    },
  ];
  List<Map<String, String>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _filteredPatients = _allPatients;
    _searchController.addListener(_filterPatients);
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients
          .where((p) => p["name"]!.toLowerCase().contains(query))
          .toList();
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredPatients.length,
                itemBuilder: (context, index) {
                  return _patientTile(context, _filteredPatients[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ---------------- APP BAR ----------------
  Widget _buildAppBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      color: primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // TODO: Handle back button tap here
              // Example: Navigator.pop(context);
            },
          ),
          const Text(
            "Patients",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            onPressed: () {
              // TODO: Handle add-patient icon tap here
              // Example: Navigator.push(context, MaterialPageRoute(builder: (_) => AddPatientScreen()));
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
        onTap: () {
          // TODO: Handle search bar tap here (e.g. show recent searches)
        },
        onSubmitted: (value) {
          // TODO: Handle search submit here
        },
        decoration: const InputDecoration(
          hintText: "Search patients...",
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  // ---------------- PATIENT TILE ----------------
  Widget _patientTile(BuildContext context, Map<String, String> patient) {
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
          radius: 22,
          backgroundColor: primaryColor.withOpacity(0.15),
          child: Text(
            _getInitials(patient["name"]!),
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient["name"]!,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "${patient["id"]}\nLast session: ${patient["lastSession"]}",
          style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientProfileScreen(
                patientName: patient["name"]!,
                patientId: patient["id"]!,
                age: patient["age"]!,
                gender: patient["gender"]!,
                phone: patient["phone"]!,
                notes: patient["notes"]!,
                sessions: [
                  patient["lastSession"]!,
                  "07 Sep 2026",
                  "31 Aug 2026",
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

        // History and Profile will be connected later.
        if (index == 2) {
          // History screen later
        }

        if (index == 3) {
          // Profile screen later
        }
      },

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: "Patients",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: "History",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "Profile",
        ),
      ],
    );
  }
}