// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, prefer_typing_uninitialized_variables

import 'dart:convert';
import 'package:flutter/material.dart';
import '../screens/forgot_pass.dart';
import '../screens/home.dart';
import 'package:status_alert/status_alert.dart';
import '../backend/constants.dart';
import '../screens/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'change_pass.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool _viewPass = true;

  List hasilResult = [];
  var hasilJson;

  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode1 = FocusNode();

  TextEditingController nik = TextEditingController();
  TextEditingController password = TextEditingController();

  Future<void> _cekUser(String nik, String password) async {
    try {
      final temporaryList = [];

      setState(() {
        loading = true;
      });

      String objBody = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<LoginApp xmlns="http://tempuri.org/">' +
          '<NIK>$nik</NIK>' +
          '<UserPass>$password</UserPass>' +
          '</LoginApp>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_LoginApp),
          headers: {
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/LoginApp',
            "Access-Control-Allow-Credentials": "true",
            'Content-type': 'text/xml; charset=utf-8',
          },
          body: objBody);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final listResultAll = document.findAllElements('Table');

        for (final listResult in listResultAll) {
          final statusData = listResult.findElements('StatusData').isEmpty
              ? 'No Data'
              : listResult.findElements('StatusData').first.text;

          if (statusData == "GAGAL") {
            Future.delayed(const Duration(seconds: 1), () {
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 1),
                configuration: const IconConfiguration(
                    icon: Icons.error, color: Colors.red),
                title: "Error Login, Registration Already?",
                backgroundColor: Colors.grey[300],
              );
              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            });
          } else {
            final userName = listResult.findElements('UserName').isEmpty
                ? 'No Data'
                : listResult.findElements('UserName').first.text;
            final iomCharterLevel =
                listResult.findElements('IOMCharterLevel').isEmpty
                    ? 'No Data'
                    : listResult.findElements('IOMCharterLevel').first.text;
            final userEmail = listResult.findElements('UserEmail').isEmpty
                ? 'No Data'
                : listResult.findElements('UserEmail').first.text;
            final nik = listResult.findElements('NIK').isEmpty
                ? 'No Data'
                : listResult.findElements('NIK').first.text;
            temporaryList.add({
              'userName': userName,
              'userLevel': iomCharterLevel.toUpperCase() == 'VIEW'
                  ? '17'
                  : iomCharterLevel.toUpperCase() == 'CREATOR'
                      ? '19'
                      : iomCharterLevel.toUpperCase() == 'FINANCE'
                          ? '12'
                          : '10',
              'userEmail': userEmail,
              'nik': nik,
            });

            hasilJson = jsonEncode(temporaryList);
            debugPrint(hasilJson);

            Future.delayed(const Duration(seconds: 1), () async {
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 1),
                configuration: const IconConfiguration(
                    icon: Icons.done, color: Colors.green),
                title: "Success Login",
                backgroundColor: Colors.grey[300],
              );

              if (password == '123') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ChangePass(
                      nik: nik,
                      email: userEmail,
                    ),
                  ),
                );
              } else {
                await saveData(
                  userName,
                  temporaryList.last['userLevel'],
                  userEmail,
                  nik,
                );

                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const HomeScreen();
                  },
                ));
              }

              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            });
          }
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
          subtitle: "Error Login",
          backgroundColor: Colors.grey[300],
        );
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      }

      setState(() {
        hasilResult = temporaryList;
      });
    } catch (e) {
      debugPrint('$e');
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        configuration:
            const IconConfiguration(icon: Icons.error, color: Colors.red),
        title: "Error Login",
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

  Future<void> saveData(
    String userName,
    String userLevel,
    String userEmail,
    String nik,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userName1 = prefs.getString('userName') ?? 'No Data';

    if (userName1 != 'No Data') {
      await prefs.clear();

      await prefs.setString('userName', userName);
      await prefs.setString('userLevel', userLevel);
      await prefs.setString('userEmail', userEmail);
      await prefs.setString('userlevel', userLevel);
      await prefs.setString('nik', nik);
      debugPrint('Updated local');
    } else {
      await prefs.setString('userName', userName);
      await prefs.setString('userLevel', userLevel);
      await prefs.setString('userEmail', userEmail);
      await prefs.setString('userlevel', userLevel);
      await prefs.setString('nik', nik);
      debugPrint('New local');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    nik.dispose();
    password.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        _focusNode1.unfocus();
      },
      child: Scaffold(
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: ListView(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                  ),
                ),
                width: double.infinity,
                height: size.height * 0.2,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    "IOM",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                      fontSize: MediaQuery.of(context).textScaleFactor * 30,
                    ),
                  ),
                  Text(
                    "CHARTER",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                      fontSize: MediaQuery.of(context).textScaleFactor * 30,
                    ),
                  ),
                ],
              ),
              loginForm(context),
            ],
          ),
        ),
      ),
    );
  }

  SingleChildScrollView loginForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(10, 5),
                  )
                ]),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        focusNode: _focusNode,
                        autofocus: true,
                        autocorrect: false,
                        controller: nik,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.redAccent, width: 2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.redAccent, width: 2),
                          ),
                          hintText: '1234***',
                          labelText: 'User ID',
                          icon: Icon(Icons.account_circle),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        focusNode: _focusNode1,
                        autocorrect: false,
                        controller: password,
                        obscureText: _viewPass,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          enabledBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.redAccent, width: 2),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.redAccent, width: 2),
                          ),
                          hintText: '*****',
                          labelText: 'Password',
                          icon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            onPressed: () async {
                              setState(() {
                                _viewPass = !_viewPass;
                              });
                            },
                            icon: Icon(_viewPass
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else if (value.length < 3) {
                            return 'Password must be greater than or equal to 3 characters';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                loading
                    ? const CircularProgressIndicator()
                    : MaterialButton(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        disabledColor: Colors.grey,
                        color: Colors.redAccent,
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            setState(() {
                              loading = true;
                            });

                            await _cekUser(nik.text, password.text);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 80,
                            vertical: 15,
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const ForgotPass();
                      },
                    ));
                  },
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('OR'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) {
                      return const RegisterScreen();
                    },
                  ));
                },
                child: const Text('Create a new account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
