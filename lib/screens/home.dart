import 'dart:async';
import 'dart:math';

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
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 20),
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
                            ((width - horizontalPadding * 2 - 8) / 2)
                                .clamp(140, 180);
                        double cardHeight = 150;

                        return SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: buildInfoCard(infoCards[index]['title']!,
                              infoCards[index]['value']!),
                        );
                      },
                    ),
                    if (xCoord != null &&
                        yCoord != null &&
                        locationName != null) ...[
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
                              'Current Duty',
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
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Check In Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.indigo.shade400,
                                      Colors.indigo.shade600
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.indigo.shade200
                                          .withOpacity(0.3),
                                      offset: const Offset(2, 4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 26, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () async {
                                    startSharingLiveLocation();
                                    _handleCheckIn();
                                    await checkIn(currentLatitude!,
                                        currentLongitude!, batchNo);
                                    if (currentLatitude == null ||
                                        currentLongitude == null) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Location Error"),
                                          content: const Text(
                                              "Current location not available."),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text("OK"),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    if (xCoord == null || yCoord == null) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Data Error"),
                                          content: const Text(
                                              "Target coordinates not loaded."),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text("OK"),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    // Get formatted current time
                                    String currentTime =
                                        getFormattedCurrentTime();

                                    // Show the current time in a dialog or you can update a state variable if you want
                                    // showDialog(
                                    //   context: context,
                                    //   builder: (context) => AlertDialog(
                                    //     title: const Text("Check In Time"),
                                    //     content:
                                    //         Text("Checked in at: $currentTime"),
                                    //     actions: [
                                    //       TextButton(
                                    //         onPressed: () =>
                                    //             Navigator.of(context).pop(),
                                    //         child: const Text("OK"),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // );
                                  },
                                  icon: const Icon(Icons.login,
                                      color: Colors.white),
                                  label: const Text(
                                    'Share Live Location',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Hardcoded check-in and check-out times below buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Last click on $_checkInTime',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  double calculateDistanceInMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    double dLat = _degreeToRadian(lat2 - lat1);
    double dLon = _degreeToRadian(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(lat1)) *
            cos(_degreeToRadian(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }

  String getFormattedCurrentTime() {
    final now = DateTime.now();

    int hour = now.hour;
    final minute = now.minute;

    final amPm = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;

    final minuteStr = minute.toString().padLeft(2, '0');
    final hourStr = hour.toString().padLeft(2, '0');

    return "$hourStr:$minuteStr $amPm";
  }

  String? _checkInTime;

  void _handleCheckIn() {
    final now = TimeOfDay.now();
    final formattedTime =
        '${now.hourOfPeriod.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    setState(() {
      _checkInTime = formattedTime;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Checked In'),
          content: Text('Check-in time: $_checkInTime'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
