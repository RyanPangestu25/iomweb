// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:status_alert/status_alert.dart';
import '../backend/constants.dart';
import '../screens/change_pass.dart';
import '../screens/home.dart';
import '../screens/view_iom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/about.dart';
import '../screens/login.dart';
import 'alertdialog/pick_date.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool loading = false;

  String randomID = '';
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

  Future<void> genRandom() async {
    int random = Random().nextInt(4294967296);

    setState(() {
      randomID = 'FC' + random.toString();
    });

    debugPrint(randomID);

    await addTranKey();
  }

  Future<void> addTranKey() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<AddTranKey xmlns="http://tempuri.org/">' +
          '<nik>${data.last['nik']}</nik>' +
          '<TranKey>$randomID</TranKey>' +
          '</AddTranKey>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_AddTranKey),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/AddTranKey',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('AddTranKeyResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('AddTranKeyResult').first.text;

        if (statusData == "GAGAL") {
          Future.delayed(const Duration(seconds: 1), () {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 1),
              configuration:
                  const IconConfiguration(icon: Icons.error, color: Colors.red),
              title: "Failed",
              backgroundColor: Colors.grey[300],
            );
            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          });
        } else {
          Future.delayed(const Duration(seconds: 1), () async {
            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          });
        }
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          title: "${response.statusCode}",
          subtitle: "Failed Add TranKey",
          backgroundColor: Colors.grey[300],
        );
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('$e');
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        configuration:
            const IconConfiguration(icon: Icons.error, color: Colors.red),
        title: "Failed Add TranKey",
        subtitle: "$e",
        subtitleOptions: StatusAlertTextConfiguration(
          overflow: TextOverflow.visible,
        ),
        backgroundColor: Colors.grey[300],
      );
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

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
    } else if (data.last['level'] == '19') {
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
              title: const Text("IOM Agreement"),
              onTap: () async {
                await genRandom();

                Future.delayed(const Duration(seconds: 1), () async {
                  String baseUrl =
                      'https://lgapvfncacc.com/IOMCharterWeb/AgreementCharter/';
                  String nik = data.last['nik'];
                  String tranKey = randomID;

                  String urlWithParameters = baseUrl +
                      '?NIK=' +
                      Uri.encodeComponent(nik) +
                      '&TranKey=' +
                      Uri.encodeComponent(tranKey);

                  if (await canLaunch(urlWithParameters)) {
                    await launch(urlWithParameters, webOnlyWindowName: '_self');
                  } else {
                    StatusAlert.show(
                      context,
                      duration: const Duration(seconds: 1),
                      configuration: const IconConfiguration(
                        icon: Icons.error,
                        color: Colors.red,
                      ),
                      title: "Error while opening URL",
                      backgroundColor: Colors.grey[300],
                    );

                    throw 'Error while opening $urlWithParameters';
                  }
                });
              },
            ),
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("Internal Memo Office IOM"),
              onTap: () async {
                await genRandom();

                Future.delayed(const Duration(seconds: 1), () async {
                  String baseUrl =
                      'https://lgapvfncacc.com/IOMCharterWeb/CreateIOM/';
                  String nik = data.last['nik'];
                  String tranKey = randomID;

                  String urlWithParameters = baseUrl +
                      '?NIK=' +
                      Uri.encodeComponent(nik) +
                      '&TranKey=' +
                      Uri.encodeComponent(tranKey);

                  if (await canLaunch(urlWithParameters)) {
                    await launch(urlWithParameters, webOnlyWindowName: '_self');
                  } else {
                    StatusAlert.show(
                      context,
                      duration: const Duration(seconds: 1),
                      configuration: const IconConfiguration(
                        icon: Icons.error,
                        color: Colors.red,
                      ),
                      title: "Error while opening URL",
                      backgroundColor: Colors.grey[300],
                    );

                    throw 'Error while opening $urlWithParameters';
                  }
                });
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
