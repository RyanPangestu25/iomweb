import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void main() {
  html.window.onBeforeUnload.listen((_) {
    // Hapus semua cookies
    html.document.cookie!.split(';').forEach((cookie) {
      final eqIndex = cookie.indexOf('=');
      final name = eqIndex == -1 ? cookie : cookie.substring(0, eqIndex);
      html.document.cookie = '$name=;expires=Thu, 01 Jan 1970 00:00:00 GMT';
    });
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IOMCharter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      color: Colors.white,
      home: const SplashScreen(),
    );
  }
}
