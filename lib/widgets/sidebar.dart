// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../screens/home.dart';
import '../screens/view_iom.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  int level = 0;
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
    if (level == 12) {
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
          ],
        );
      });
    } else if (level == 10) {
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

  Future<void> getLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userLevel = prefs.getString('userLevel');

    setState(() {
      level = int.parse(userLevel ?? '0');
      debugPrint(level.toString());
    });

    await cekLevel();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getLevel();
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
          ],
        ),
      ),
    );
  }
}
