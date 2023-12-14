// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  bool loading = false;

  int curYear = DateTime.now().year;

  var appsVersion;
  var appsBuild;

  Future<void> getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String appVersion = packageInfo.version;
    final String appBuild = packageInfo.buildNumber;
    setState(() {
      appsVersion = appVersion;
      appsBuild = appBuild;
    });
  }

  @override
  void initState() {
    super.initState();
    curYear = DateTime.now().year;
    getAppVersion();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaler;

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: size.height * 0.2,
            ),
            Image.asset(
              'assets/images/logo.png',
              scale: 2.5,
              filterQuality: FilterQuality.high,
            ),
            SizedBox(
              height: size.height * 0.023,
            ),
            Text(
              "IOMCharter",
              style: TextStyle(
                fontSize: textScaleFactor.scale(30),
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 255, 17, 0),
              ),
            ),
            SizedBox(
              height: size.height * 0.023,
            ),
            Text(
              "Version:",
              style: TextStyle(fontSize: textScaleFactor.scale(20)),
            ),
            SizedBox(
              height: size.height * 0.008,
            ),
            Text(
              "$appsVersion build $appsBuild",
              style: TextStyle(fontSize: textScaleFactor.scale(20)),
            ),
            SizedBox(
              height: size.height * 0.023,
            ),
            curYear == 2023
                ? Text(
                    "\u00A9 Copyright 2023",
                    style: TextStyle(fontSize: textScaleFactor.scale(15)),
                  )
                : Text(
                    "\u00A9 Copyright 2023 - $curYear",
                    style: TextStyle(fontSize: textScaleFactor.scale(15)),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Back',
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 10,
        onPressed: () async {
          Navigator.of(context).pop();
        },
        child: const Icon(Icons.arrow_back_ios_new),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
