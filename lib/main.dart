import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/duty.dart';
import 'screens/global.dart';
import 'screens/home.dart';
import 'screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  globalBatchNo = prefs.getString('batchNo');

  runApp(MyApp(isLoggedIn: globalBatchNo != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'poppins',
        colorScheme: const ColorScheme.light(),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        useMaterial3: true,
      ),
      home: DutyPage(),
      // home: isLoggedIn ? HomePage() : const Login(),
    );
  }
}
