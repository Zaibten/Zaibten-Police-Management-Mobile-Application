import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;

import 'duty.dart';
import 'home.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? constable;
  bool isLoading = true;
  String? errorMessage;
  double? currentLatitude;
  double? currentLongitude;
  Stream<loc.LocationData>? locationStream;
  StreamSubscription<loc.LocationData>? locationSubscription;
  bool isSharingLocation = false;

  final loc.Location location = loc.Location();
  int _selectedIndex = 2;


  @override
  void initState() {
    super.initState();
    loadBatchAndFetchData();
  }

  Future<void> loadBatchAndFetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? batchNo = prefs.getString('batchNo');

    if (batchNo == null || batchNo.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Batch number not found in local storage.';
      });
      return;
    }

    await fetchConstableData(batchNo);
  }

  Future<void> fetchConstableData(String batchNo) async {
    final url = Uri.parse('https://zaibtenpoliceserver.vercel.app/api/constables/$batchNo');
    // Replace https://yourserver.com with your real backend URL

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        if (jsonList.isEmpty) {
          setState(() {
            errorMessage = 'No constable found for this batch number.';
            isLoading = false;
          });
          return;
        }

        // Assume the first constable is the one we want
        setState(() {
          constable = Map<String, dynamic>.from(jsonList[0]);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data from server.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green.shade600;
      case 'inactive':
        return Colors.red.shade600;
      case 'on leave':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.indigo.shade900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget infoRow(IconData icon, String label, String? value) {
    return value == null || value.isEmpty
        ? SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, color: Colors.indigo.shade400, size: 22),
                SizedBox(width: 14),
                Text(
                  '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.indigo.shade700,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style:
                        TextStyle(fontSize: 16, color: Colors.indigo.shade900),
                  ),
                )
              ],
            ),
          );
  }

  Widget chipList(List<dynamic>? items, String label) {
    if (items == null || items.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.indigo.shade700,
          ),
        ),
        SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items
              .map(
                (item) => Chip(
                  backgroundColor: Colors.indigo.shade100,
                  label: Text(
                    item.toString(),
                    style: TextStyle(
                        color: Colors.indigo.shade900,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('batchNo');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  void showPMSDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 15),
            Text(title),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String coordsDisplay = '';
    if (currentLatitude != null && currentLongitude != null) {
      coordsDisplay =
          'Lat: ${currentLatitude!.toStringAsFixed(4)}, Lon: ${currentLongitude!.toStringAsFixed(4)}';
    }
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.indigo.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Text(
            'PMS PROFILE',
            style: TextStyle(
              color: Colors.indigo.shade900,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1.4,
            ),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.indigo.shade900),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () async {},
            ),
            IconButton(
              icon: Icon(Icons.logout_sharp, color: Colors.red.shade600),
              tooltip: 'Logout',
              onPressed: () {
                showPMSDialog(
                  title: "PMS SYSTEM",
                  message: "Are you sure you want to logout?",
                  icon: Icons.logout_sharp,
                  iconColor: Colors.red.shade700,
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: coordsDisplay.isNotEmpty
                  ? Text(
                      coordsDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.indigo.shade700,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final imageWidget = (constable!['image'] != null &&
            constable!['image'].toString().isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(80),
            child: Image.network(
              constable!['image'],
              width: 160,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: 80,
                backgroundColor: Colors.indigo.shade100,
                child:
                    Icon(Icons.person, size: 80, color: Colors.indigo.shade400),
              ),
            ),
          )
        : CircleAvatar(
            radius: 80,
            backgroundColor: Colors.indigo.shade100,
            child: Icon(Icons.person, size: 80, color: Colors.indigo.shade400),
          );

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'PMS DUTY',
          style: TextStyle(
            color: Colors.indigo.shade900,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.4,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.indigo.shade900),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {},
          ),
          IconButton(
            icon: Icon(Icons.logout_sharp, color: Colors.red.shade600),
            tooltip: 'Logout',
            onPressed: () {
              showPMSDialog(
                title: "PMS SYSTEM",
                message: "Are you sure you want to logout?",
                icon: Icons.logout_sharp,
                iconColor: Colors.red.shade700,
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: coordsDisplay.isNotEmpty
                ? Text(
                    coordsDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo.shade700,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: imageWidget),
            SizedBox(height: 16),
            Text(
              constable!['fullName'] ?? 'No Name',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              '${constable!['rank'] ?? ''} | Badge No: ${constable!['badgeNumber'] ?? ''}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color:
                    getStatusColor(constable!['status'] ?? '').withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                (constable!['status'] ?? 'UNKNOWN').toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: getStatusColor(constable!['status'] ?? ''),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(height: 30),
            sectionTitle('Personal Information'),
            infoRow(Icons.cake, 'Date of Birth', constable!['dob']),
            infoRow(Icons.wc, 'Gender', constable!['gender']),
            infoRow(Icons.home, 'Address', constable!['address']),
            infoRow(Icons.school, 'Qualification', constable!['qualification']),
            SizedBox(height: 24),
            sectionTitle('Contact Information'),
            infoRow(Icons.phone, 'Contact Number', constable!['contactNumber']),
            infoRow(Icons.email, 'Email', constable!['email']),
            SizedBox(height: 24),
            sectionTitle('Service Information'),
            infoRow(Icons.location_city, 'Police Station',
                constable!['policeStation']),
            infoRow(Icons.calendar_today, 'Joining Date',
                constable!['joiningDate']),
            SizedBox(height: 24),
            if ((constable!['weapons']?.isNotEmpty ?? false) ||
                (constable!['vehicles']?.isNotEmpty ?? false))
              sectionTitle('Equipment'),
            chipList(constable!['weapons'], 'Weapons'),
            SizedBox(height: 16),
            chipList(constable!['vehicles'], 'Vehicles'),
            SizedBox(height: 24),
            if (constable!['remarks'] != null &&
                constable!['remarks'].toString().isNotEmpty) ...[
              sectionTitle('Remarks'),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  constable!['remarks'],
                  style: TextStyle(fontSize: 16, color: Colors.indigo.shade900),
                ),
              ),
            ],
          ],
        ),
      ),
         bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: GNav(
            gap: 10,
            activeColor: Colors.white,
            color: Colors.grey[700],
            iconSize: 26,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
            duration: const Duration(milliseconds: 500),
            tabBackgroundColor: const Color.fromARGB(255, 94, 131, 233),
            curve: Curves.easeOutExpo,
            tabs: [
              GButton(
                icon: Icons.home,
                text: 'Home',
                iconSize: 28,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              GButton(
                icon: Icons.workspace_premium,
                text: 'Duties',
                iconSize: 28,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              GButton(
                icon: Icons.person, // changed Icons.profile to Icons.person (valid icon)
                text: 'Profile',
                iconSize: 28,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
            selectedIndex: _selectedIndex,
           onTabChange: (index) {
  setState(() {
    _selectedIndex = index;
  });
if (index == 0) { // Duties tab index
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }
  if (index == 1) { // Duties tab index
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DutyPage()),
    );
  }
    if (index == 2) { // Duties tab index
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }
},

          ),
        ),
      ),
   
    );
  }
}
