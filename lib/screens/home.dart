import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Aliases to avoid PermissionStatus conflict
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;

import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String batchNo = '';
  String? xCoord;
  String? yCoord;
  String? locationName;

  // Current device location (latitude, longitude)
  double? currentLatitude;
  double? currentLongitude;

  final loc.Location location = loc.Location();

  final List<Map<String, String>> infoCards = [
    {'title': 'Total Present', 'value': '3'},
    {'title': 'Total Absents', 'value': '4'},
    {'title': 'Name', 'value': 'John Doe'},
    {'title': 'Batch No', 'value': 'A12345'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBatchNo();
    _requestLocationPermissionAndFetch();
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

  Widget buildInfoCard(String title, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallWidth = constraints.maxWidth < 150;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.indigo.shade50,
                Colors.indigo.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.shade200.withOpacity(0.4),
                offset: const Offset(3, 3),
                blurRadius: 8,
                spreadRadius: 0.8,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(-3, -3),
                blurRadius: 8,
                spreadRadius: 0.8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: isSmallWidth ? 9 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.indigo.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallWidth ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        );
      },
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

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'PMS DASHBAORD',
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
              if (batchNo.isNotEmpty) {
                await _fetchDashboardData(batchNo);
              }
              await _requestLocationPermissionAndFetch();
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red.shade600),
            tooltip: 'Logout',
            onPressed: () {
              showPMSDialog(
                title: "PMS SYSTEM",
                message: "Are you sure you want to logout?",
                icon: Icons.logout,
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
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  // child: Text(
                  //   'Welcome to the Dashboard!',
                  //   style: TextStyle(
                  //     fontSize: 26,
                  //     fontWeight: FontWeight.w900,
                  //     letterSpacing: 1.4,
                  //     color: Colors.indigo.shade900,
                  //   ),
                  // ),
                ),
                // const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  alignment: WrapAlignment.start,
                  children: [
                    ...List.generate(
                      infoCards.length,
                      (index) {
                        double cardWidth =
                            ((width - horizontalPadding * 2 - 8) / 2).clamp(140, 180);
                        double cardHeight = 150;

                        return SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: buildInfoCard(
                              infoCards[index]['title']!, infoCards[index]['value']!),
                        );
                      },
                    ),
                    if (xCoord != null && yCoord != null && locationName != null) ...[
                      const SizedBox(height: 0),
                      Container(
                        width: 350,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.shade200.withOpacity(0.4),
                              offset: const Offset(3, 3),
                              blurRadius: 8,
                              spreadRadius: 0.8,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              offset: const Offset(-3, -3),
                              blurRadius: 8,
                              spreadRadius: 0.8,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coordinates Data',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'X Coordinate: $xCoord',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                            Text(
                              'Y Coordinate: $yCoord',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                            Text(
                              'Location: $locationName',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
