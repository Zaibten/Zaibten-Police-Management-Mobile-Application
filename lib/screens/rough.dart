// GestureDetector(
//   onTap: () async {
//     final _formKey = GlobalKey<FormState>();
//     String batchInput = '';

//     // 1. Batch Number Input Modal
//     String? enteredBatchNo = await showDialog<String>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Text('Enter Batch Number', style: TextStyle(fontWeight: FontWeight.bold)),
//           content: Form(
//             key: _formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'Please enter your batch number to proceed.',
//                   style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                 ),
//                 SizedBox(height: 16),
//                 TextFormField(
//                   autofocus: true,
//                   decoration: InputDecoration(
//                     labelText: 'Batch Number',
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                     prefixIcon: Icon(Icons.numbers),
//                     hintText: 'e.g., BATCH12345',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Batch number cannot be empty';
//                     }
//                     return null;
//                   },
//                   onChanged: (value) => batchInput = value,
//                   textInputAction: TextInputAction.done,
//                 ),
//               ],
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
//               onPressed: () => Navigator.pop(context, null),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: Text('Submit'),
//               onPressed: () {
//                 if (_formKey.currentState!.validate()) {
//                   Navigator.pop(context, batchInput.trim());
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );

//     if (enteredBatchNo == null || enteredBatchNo.isEmpty) {
//       return; // Cancelled or empty input
//     }

//     // Save batchNo locally
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('batchNo', enteredBatchNo);

//     // Send request to backend and get result
//     String messageToShow = '';
//     try {
//       final response = await http.post(
//         Uri.parse("http://192.168.0.111:5000/send-simple-email"),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'batchNo': enteredBatchNo}),
//       );

//       if (response.statusCode == 200) {
//         messageToShow = 'Your request has been sent to the admin.\nYou will receive a response shortly.';
//       } else {
//         messageToShow = 'Failed to send the request. Please try again later.';
//       }
//     } catch (e) {
//       messageToShow = 'An error occurred: $e';
//     }

//     // 2. Show Result Modal with message
//     await showDialog<void>(
//       context: context,
//       barrierDismissible: true,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
//           content: Text(
//             messageToShow,
//             style: TextStyle(fontSize: 15, color: Colors.grey[800]),
//           ),
//           actions: [
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               onPressed: () => Navigator.pop(context),
//               child: Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   },
//   child: Text(
//     'Forgot Password?',
//     style: TextStyle(
//       color: Colors.white.withOpacity(0.7),
//       fontSize: 14,
//       decoration: TextDecoration.underline,
//     ),
//   ),
// );
