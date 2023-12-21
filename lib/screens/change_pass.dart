// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../backend/constants.dart';

class ChangePass extends StatefulWidget {
  String nik;
  String email;

  ChangePass({
    Key? key,
    required this.nik,
    required this.email,
  }) : super(key: key);

  @override
  State<ChangePass> createState() => _ChangePassState();
}

class _ChangePassState extends State<ChangePass> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool _viewPass = true;
  bool _viewConPass = true;

  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode1 = FocusNode();

  TextEditingController password = TextEditingController();
  TextEditingController conPassword = TextEditingController();

  Future<void> updatePass(String password) async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ResetPass xmlns="http://tempuri.org/">' +
          '<nik>${widget.nik}</nik>' +
          '<UserEmail>${widget.email}</UserEmail>' +
          '<UserPassNew>$password</UserPassNew>' +
          '</ResetPass>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_ResetPass),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/ResetPass',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final parsedResponse = xml.XmlDocument.parse(responseBody);
        final result =
            parsedResponse.findAllElements('ResetPassResult').single.text;
        debugPrint('Result: $result');
        if (result == "GAGAL") {
          Future.delayed(const Duration(seconds: 1), () {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 1),
              configuration:
                  const IconConfiguration(icon: Icons.error, color: Colors.red),
              title: "Failed Update Password",
              backgroundColor: Colors.grey[300],
            );

            setState(() {
              loading = false;
            });
          });
        } else {
          Future.delayed(const Duration(seconds: 1), () async {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 1),
              configuration: const IconConfiguration(
                  icon: Icons.done, color: Colors.green),
              title: "Password Updated",
              backgroundColor: Colors.grey[300],
            );

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();

            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
              builder: (BuildContext context) {
                return const LoginScreen();
              },
            ), (route) => false);

            setState(() {
              loading = false;
            });
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
          subtitle: "Failed Update Password",
          backgroundColor: Colors.grey[300],
        );
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('$e');
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        configuration:
            const IconConfiguration(icon: Icons.error, color: Colors.red),
        title: "Failed Update Password",
        subtitle: "$e",
        subtitleOptions: StatusAlertTextConfiguration(
          overflow: TextOverflow.visible,
        ),
        backgroundColor: Colors.grey[300],
      );
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    password.dispose();
    conPassword.dispose();
    _focusNode.dispose();
    _focusNode1.dispose();
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
              changePassForm(context),
            ],
          ),
        ),
      ),
    );
  }

  SingleChildScrollView changePassForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            width: double.infinity,
            // height: 350,
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
                Text(
                  'UPDATE',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: MediaQuery.of(context).textScaleFactor * 28,
                  ),
                ),
                Text(
                  'PASSWORD',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: MediaQuery.of(context).textScaleFactor * 28,
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        focusNode: _focusNode,
                        autofocus: true,
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
                          labelText: 'New Password',
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
                      const SizedBox(height: 10),
                      TextFormField(
                        focusNode: _focusNode1,
                        controller: conPassword,
                        autocorrect: false,
                        obscureText: _viewConPass,
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
                          hintText: '******',
                          labelText: 'Confirm New Password',
                          icon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            onPressed: () async {
                              setState(() {
                                _viewConPass = !_viewConPass;
                              });
                            },
                            icon: Icon(_viewConPass
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else if (password.text != conPassword.text) {
                            return "Password don't match, Please check again!!";
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(height: 30),
                      loading
                          ? const CircularProgressIndicator()
                          : Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Back',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                const Spacer(flex: 1),
                                TextButton.icon(
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            _formKey.currentState!.save();

                                            await updatePass(password.text);
                                          }
                                        },
                                  icon: const Icon(
                                    Icons.done,
                                    color: Colors.green,
                                  ),
                                  label: const Text(
                                    'Update',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                              ],
                            )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
