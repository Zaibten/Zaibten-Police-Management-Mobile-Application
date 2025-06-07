import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:location/location.dart';
import 'package:pictureai/screens/home.dart';
import 'package:pictureai/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// Aliases to avoid PermissionStatus conflict
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;

import 'profile.dart';

class DutyPage extends StatefulWidget {
  const DutyPage({super.key});

  @override
  State<DutyPage> createState() => _DutyPageState();
}

class _DutyPageState extends State<DutyPage> {
  List<dynamic> duties = [];
  List<dynamic> filteredDuties = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';
  bool showOnlyActive = false;
  String batchNo = '';
  String? xCoord;
  String? yCoord;
  String? locationName;
  String? checkInTime;
  

  // Current device location (latitude, longitude)
  double? currentLatitude;
  double? currentLongitude;
  Stream<loc.LocationData>? locationStream;
  StreamSubscription<loc.LocationData>? locationSubscription;
  bool isSharingLocation = false;

  final loc.Location location = loc.Location();

  final List<Map<String, String>> infoCards = [
    {'title': 'Total Present', 'value': '3'},
    {'title': 'Total Absents', 'value': '4'},
    {'title': 'Name', 'value': 'John Doe'},
    {'title': 'Batch No', 'value': 'A12345'},
  ];
  
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadBatchNo();
    _requestLocationPermissionAndFetch();
  }

  void startSharingLiveLocation() async {
    if (isSharingLocation) return; // Already sharing, ignore button tap

    // Request permission & service again just to be safe
    var status = await perm.Permission.location.status;
    if (!status.isGranted) {
      status = await perm.Permission.location.request();
      if (!status.isGranted) {
        print('Location permission denied');
        return;
      }
    }
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        print('Location service disabled');
        return;
      }
    }

    // Start listening to location changes continuously
    location.changeSettings(
        interval: 10000, distanceFilter: 10); // every 10 sec or 10 meters
    locationStream = location.onLocationChanged;

    locationSubscription =
        locationStream!.listen((loc.LocationData currentLocation) {
      currentLatitude = currentLocation.latitude;
      currentLongitude = currentLocation.longitude;

      print('Live Location update: $currentLatitude, $currentLongitude');

      // Call your API to send the current live location
      if (currentLatitude != null &&
          currentLongitude != null &&
          batchNo.isNotEmpty) {
        checkIn(currentLatitude!, currentLongitude!, batchNo);
      }

      setState(() {}); // update UI if needed
    });

    isSharingLocation = true;
    print('Started live location sharing');
  }

  // Example function to call check-in API
  Future<void> checkIn(
      double currentLat, double currentLng, String badgeNumber) async {
    final url = Uri.parse('http://192.168.0.111:5000/api/checkin');
    final now = DateTime.now().toIso8601String();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'badgeNumber': batchNo,
        'currentX': currentLat,
        'currentY': currentLng,
        'currentTime': now,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle success - update UI or show dialog
      print(
          'Check-in successful: Present: ${data['totalpresent']}, Absent: ${data['totalabsent']}');
    } else {
      final data = jsonDecode(response.body);
      // Handle error
      print('Check-in failed: ${data['message']}');
    }
  }

  Future<void> _requestLocationPermissionAndFetch() async {
    // Check permission using permission_handler package
    var status = await perm.Permission.location.status;
    if (!status.isGranted) {
      status = await perm.Permission.location.request();
      if (!status.isGranted) {
        print('Location permission denied');
        return;
      }
    }

    // Also enable location service if disabled (using location package)
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        print('Location service disabled');
        return;
      }
    }

    try {
      final loc.LocationData locationData = await location.getLocation();

      setState(() {
        currentLatitude = locationData.latitude;
        currentLongitude = locationData.longitude;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadBatchNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedBatchNo = prefs.getString('batchNo');

    if (storedBatchNo != null) {
      setState(() {
        batchNo = storedBatchNo;
      });
      await _fetchDashboardData(batchNo);
    }
  }

  Future<void> _fetchDashboardData(String batchNo) async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.0.111:5000/api/dashboard/$batchNo'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          infoCards[0]['value'] = data['totalPresent'].toString();
          infoCards[1]['value'] = data['totalAbsent'].toString();
          infoCards[2]['value'] = data['name'].toString();
          infoCards[3]['value'] = data['batchNo'].toString();

          xCoord = data['xCoord']?.toString();
          yCoord = data['yCoord']?.toString();
          locationName = data['location']?.toString();
        });
      } else {
        print('Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
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

  Future<void> fetchDuties() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? batchNo = prefs.getString('batchNo');

      if (batchNo == null || batchNo.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No batch number found in local storage.';
        });
        return;
      }

      final url = Uri.parse('http://192.168.0.111:5000/api/myduties/$batchNo');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          duties = data['duties'];
          filteredDuties = duties;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              json.decode(response.body)['message'] ?? 'Failed to fetch duties';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void filterDuties(String query) {
    setState(() {
      searchQuery = query;
      filteredDuties = duties.where((duty) {
        final locationMatch = (duty['location'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase());
        final statusMatch = !showOnlyActive ||
            (duty['status']?.toString().toLowerCase() == 'active');
        return locationMatch && statusMatch;
      }).toList();
    });
  }

  Widget buildDutyCard(dynamic duty) {
    Color statusColor;
    switch ((duty['status'] ?? '').toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'inactive':
      case 'absent':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {},
      child: Card(
        elevation: 8,
        shadowColor: Colors.blueGrey.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      duty['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.blueGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      duty['status'] ?? 'Unknown',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.badge, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(
                    'Badge: ${duty['badgeNumber'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Rank: ${duty['rank'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.blueGrey.shade100, thickness: 1),
              const SizedBox(height: 12),
              Expanded(
                child: GridView(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 20,
                    childAspectRatio: 4,
                  ),
                  children: [
                    _infoItem(Icons.location_city, 'Police Station',
                        duty['policeStation']),
                    _infoItem(Icons.schedule, 'Shift', duty['shift']),
                    _infoItem(Icons.place, 'Location', duty['location']),
                    _infoItem(Icons.workspace_premium, 'Duty Type', duty['dutyType']),
                    _infoItem(
                        Icons.date_range,
                        'Duty Date',
                        duty['dutyDate'] != null
                            ? duty['dutyDate'].split('T')[0]
                            : ''),
                    _infoItem(Icons.category, 'Category', duty['dutyCategory']),
                    _infoItem(Icons.check_circle, 'Total Present',
                        '${duty['totalpresent'] ?? 0}'),
                    _infoItem(Icons.cancel, 'Total Absent',
                        '${duty['totalabsent'] ?? 0}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Flexible(
          child: RichText(
            text: TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87),
              children: [
                TextSpan(
                  text: value ?? 'N/A',
                  style: const TextStyle(
                      fontWeight: FontWeight.normal, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width * 0.05;

    String coordsDisplay = '';
    if (currentLatitude != null && currentLongitude != null) {
      coordsDisplay =
          'Lat: ${currentLatitude!.toStringAsFixed(4)}, Lon: ${currentLongitude!.toStringAsFixed(4)}';
    }
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (screenWidth > 1400) {
      crossAxisCount = 3;
    } else if (screenWidth > 900) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
            onPressed: () async {
              await _fetchDashboardData(batchNo);
              await fetchDuties();
            },
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.redAccent)))
              : duties.isEmpty
                  ? const Center(
                      child: Text('No duties found for this batch.',
                          style: TextStyle(fontSize: 16)))
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search by location...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: filterDuties,
                          ),
                          const SizedBox(height: 1),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Show Only Active Duties'),
                            value: showOnlyActive,
                            onChanged: (bool? value) {
                              setState(() {
                                showOnlyActive = value ?? false;
                                filterDuties(
                                    searchQuery); // reapply the filter when toggled
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: GridView.builder(
                              itemCount: filteredDuties.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 1.2,
                              ),
                              itemBuilder: (context, index) {
                                return buildDutyCard(filteredDuties[index]);
                              },
                            ),
                          ),
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
