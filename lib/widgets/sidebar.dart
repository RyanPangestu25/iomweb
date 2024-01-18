// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import '../screens/change_pass.dart';
import '../screens/home.dart';
import '../screens/view_iom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/about.dart';
import '../screens/login.dart';
import 'alertdialog/pick_date.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  List data = [];
  Widget expan = const ExpansionTile(
    collapsedIconColor: Colors.white,
    collapsedTextColor: Colors.white,
    title: Text(
      "Menu",
    ),
    leading: Icon(Icons.receipt),
    textColor: Color.fromARGB(255, 5, 98, 173),
    children: [],
  );

  Future<Widget> cekLevel() async {
    if (data.last['level'] == '12') {
      setState(() {
        expan = ExpansionTile(
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          title: const Text(
            "Menu",
          ),
          leading: const Icon(Icons.receipt),
          textColor: const Color.fromARGB(255, 5, 98, 173),
          children: [
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("IOM Verification"),
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) {
                    return const ViewIOM(
                      title: 'IOM Verification',
                    );
                  }),
                );
              },
            ),
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("Download Report"),
              onTap: () async {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const PickDate();
                  },
                );
              },
            ),
          ],
        );
      });
    } else if (data.last['level'] == '10') {
      setState(() {
        expan = ExpansionTile(
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          title: const Text(
            "Menu",
          ),
          leading: const Icon(Icons.receipt),
          textColor: const Color.fromARGB(255, 5, 98, 173),
          children: [
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("IOM Approval"),
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) {
                    return const ViewIOM(
                      title: 'IOM Approval',
                    );
                  }),
                );
              },
            ),
          ],
        );
      });
    } else {
      setState(() {
        expan = ExpansionTile(
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          title: const Text(
            "Menu",
          ),
          leading: const Icon(Icons.receipt),
          textColor: const Color.fromARGB(255, 5, 98, 173),
          children: [
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("View IOM"),
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) {
                    return const ViewIOM(
                      title: 'View IOM',
                    );
                  }),
                );
              },
            ),
          ],
        );
      });
    }

    return expan;
  }

  Future<void> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? nik = prefs.getString('nik');
    String? userEmail = prefs.getString('userEmail');
    String? userLevel = prefs.getString('userLevel');

    setState(() {
      data = [
        {
          'nik': nik,
          'email': userEmail,
          'level': userLevel,
        }
      ];
      debugPrint(jsonEncode(data));
    });

    await cekLevel();
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
      builder: (BuildContext context) {
        return const LoginScreen();
      },
    ), (route) => false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.6,
      child: Drawer(
        backgroundColor: const Color(0xFF2E2E48),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: size.height * 0.18,
              child: DrawerHeader(
                child: InkWell(
                  onTap: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (BuildContext context) {
                        return const HomeScreen();
                      }),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.red,
                          boxShadow: const [
                            BoxShadow(
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: Offset(2, 1),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 2,
                            ),
                            SizedBox(
                              width: 45,
                              height: 45,
                              child: Image.asset(
                                'assets/images/logo.png',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        'IOMCharter',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).textScaleFactor * 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            expan,
            ListTile(
              onTap: () async {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) {
                    return ChangePass(
                      nik: data.last['nik'],
                      email: data.last['email'],
                    );
                  },
                ));
              },
              leading: const Icon(
                Icons.lock_person,
                color: Colors.white,
              ),
              title: const Text(
                'Change Password',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            ListTile(
              onTap: () async {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const About();
                  },
                ));
              },
              leading: const Icon(
                Icons.info,
                color: Colors.white,
              ),
              title: const Text(
                'About',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            ListTile(
              onTap: () async {
                await logout();
              },
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
