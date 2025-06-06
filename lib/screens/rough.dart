// // // // void showPMSDialog({
// // // //   required String title,
// // // //   required String message,
// // // //   required IconData icon,
// // // //   required Color iconColor,
// // // // }) {
// // // //   showDialog(
// // // //     context: context,
// // // //     builder: (_) => AlertDialog(
// // // //       title: Row(
// // // //         children: [
// // // //           Icon(icon, color: iconColor),
// // // //           const SizedBox(width: 8),
// // // //           Text("PMS System - $title"),
// // // //         ],
// // // //       ),
// // // //       content: Text(message, style: const TextStyle(fontSize: 16)),
// // // //       actions: [
// // // //         TextButton(
// // // //           onPressed: () => Navigator.pop(context),
// // // //           child: const Text("OK"),
// // // //         ),
// // // //       ],
// // // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
// // // //     ),
// // // //   );
// // // // }



// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class DutyPage extends StatefulWidget {
//   const DutyPage({super.key});

//   @override
//   State<DutyPage> createState() => _DutyPageState();
// }

// class _DutyPageState extends State<DutyPage> {
//   List<dynamic> duties = [];
//   bool isLoading = true;
//   String errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     fetchDuties();
//   }

//   Future<void> fetchDuties() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? batchNo = prefs.getString('batchNo');

//       if (batchNo == null || batchNo.isEmpty) {
//         setState(() {
//           isLoading = false;
//           errorMessage = 'No batch number found in local storage.';
//         });
//         return;
//       }

//       final url = Uri.parse('http://192.168.0.111:5000/api/myduties/$batchNo');
//       final response = await http.get(url);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           duties = data['duties'];
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           errorMessage = json.decode(response.body)['message'] ?? 'Failed to fetch duties';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Error: $e';
//         isLoading = false;
//       });
//     }
//   }

//   Widget buildDutyCard(dynamic duty) {
//     // Color coding status for clarity
//     Color statusColor;
//     switch ((duty['status'] ?? '').toLowerCase()) {
//       case 'active':
//         statusColor = Colors.green;
//         break;
//       case 'pending':
//         statusColor = Colors.orange;
//         break;
//       case 'inactive':
//       case 'absent':
//         statusColor = Colors.red;
//         break;
//       default:
//         statusColor = Colors.grey;
//     }

//     return InkWell(
//       borderRadius: BorderRadius.circular(20),
//       onTap: () {
//         // You could add navigation or details popup here
//       },
//       child: Card(
//         elevation: 8,
//         shadowColor: Colors.blueGrey.withOpacity(0.4),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         margin: const EdgeInsets.all(8),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header row with name and badge
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       duty['name'] ?? 'Unknown',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.blueGrey,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       duty['status'] ?? 'Unknown',
//                       style: TextStyle(
//                         color: statusColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),

//               // Badge and Rank info
//               Row(
//                 children: [
//                   const Icon(Icons.badge, size: 18, color: Colors.blueGrey),
//                   const SizedBox(width: 6),
//                   Text(
//                     'Badge: ${duty['badgeNumber'] ?? 'N/A'}',
//                     style: const TextStyle(fontSize: 14, color: Colors.black87),
//                   ),
//                   const SizedBox(width: 20),
//                   Text(
//                     'Rank: ${duty['rank'] ?? 'N/A'}',
//                     style: const TextStyle(fontSize: 14, color: Colors.black87),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               // Divider
//               Divider(color: Colors.blueGrey.shade100, thickness: 1),
//               const SizedBox(height: 12),

//               // Duty details in 2 columns for neatness
//               Expanded(
//                 child: GridView(
//                   physics: const NeverScrollableScrollPhysics(),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     mainAxisSpacing: 8,
//                     crossAxisSpacing: 20,
//                     childAspectRatio: 4,
//                   ),
//                   children: [
//                     _infoItem(Icons.location_city, 'Police Station', duty['policeStation']),
//                     _infoItem(Icons.schedule, 'Shift', duty['shift']),
//                     _infoItem(Icons.place, 'Location', duty['location']),
//                     _infoItem(Icons.work, 'Duty Type', duty['dutyType']),
//                     _infoItem(Icons.date_range, 'Duty Date', duty['dutyDate'] != null ? duty['dutyDate'].split('T')[0] : ''),
//                     _infoItem(Icons.category, 'Category', duty['dutyCategory']),
//                     _infoItem(Icons.check_circle, 'Total Present', '${duty['totalpresent'] ?? 0}'),
//                     _infoItem(Icons.cancel, 'Total Absent', '${duty['totalabsent'] ?? 0}'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _infoItem(IconData icon, String label, String? value) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: Colors.blueGrey),
//         const SizedBox(width: 6),
//         Flexible(
//           child: RichText(
//             text: TextSpan(
//               text: '$label: ',
//               style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
//               children: [
//                 TextSpan(
//                   text: value ?? 'N/A',
//                   style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black54),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     int crossAxisCount = 1;
//     if (screenWidth > 1400) {
//       crossAxisCount = 3;
//     } else if (screenWidth > 900) {
//       crossAxisCount = 2;
//     }

//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         title: const Text('My Duties', style: TextStyle(fontWeight: FontWeight.w700)),
//         centerTitle: true,
//         elevation: 4,
//         backgroundColor: Colors.blueGrey.shade800,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : errorMessage.isNotEmpty
//               ? Center(child: Text(errorMessage, style: const TextStyle(fontSize: 16, color: Colors.redAccent)))
//               : duties.isEmpty
//                   ? const Center(child: Text('No duties found for this batch.', style: TextStyle(fontSize: 16)))
//                   : Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       child: GridView.builder(
//                         itemCount: duties.length,
//                         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: crossAxisCount,
//                           crossAxisSpacing: 20,
//                           mainAxisSpacing: 20,
//                           childAspectRatio: 1.2,
//                         ),
//                         itemBuilder: (context, index) {
//                           return buildDutyCard(duties[index]);
//                         },
//                       ),
//                     ),
//     );
//   }
// }
