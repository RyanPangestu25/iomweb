// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/login.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(milliseconds: 2300),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) {
          return const LoginScreen();
        }),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      color: Colors.red,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: size.height * 0.05),
            Image.asset(
              'assets/images/logo.png',
              scale: 2,
              color: Colors.white,
            ),
            SizedBox(height: size.height * 0.05),
            Text(
              "IOMCharter",
              style: TextStyle(
                inherit: false,
                fontSize: MediaQuery.of(context).textScaleFactor * 40,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(4, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: SimpleCircularProgressBar(
                mergeMode: true,
                animationDuration: 2,
                progressStrokeWidth: 10,
                onGetText: (double value) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      inherit: false,
                      fontSize: MediaQuery.of(context).textScaleFactor * 25,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
