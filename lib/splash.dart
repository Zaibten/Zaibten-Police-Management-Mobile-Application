import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

import 'screens/home.dart';
import 'screens/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Widget nextScreen = const Login(); // Default to Login

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final batchNo = prefs.getString('batchNo');

    if (batchNo != null && batchNo.isNotEmpty) {
      setState(() {
        nextScreen = HomePage();
      });
    } else {
      setState(() {
        nextScreen = const Login();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Image.asset('assets/images/logo.png', height: 2500, width: 2500),
      splashIconSize: 150,
      duration: 300,
      splashTransition: SplashTransition.scaleTransition,
      backgroundColor: Colors.white,
      // backgroundColor: Colors.deepPurple,
      nextScreen: nextScreen,
    );
  }
}
