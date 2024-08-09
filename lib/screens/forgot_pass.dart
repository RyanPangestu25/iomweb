// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:status_alert/status_alert.dart';
import '../backend/constants.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'change_pass.dart';

class ForgotPass extends StatefulWidget {
  const ForgotPass({Key? key}) : super(key: key);

  @override
  State<ForgotPass> createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  String kodeOTP = '';

  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode1 = FocusNode();

  TextEditingController nik = TextEditingController();
  TextEditingController email = TextEditingController();

  Future<void> cekNIK(String nik, String email) async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<CekNIK xmlns="http://tempuri.org/">' +
          '<nik>$nik</nik>' +
          '<UserEmail>$email</UserEmail>' +
          '</CekNIK>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http
          .post(Uri.parse(url_CekNIK),
              headers: <String, String>{
                "Access-Control-Allow-Origin": "*",
                'SOAPAction': 'http://tempuri.org/CekNIK',
                'Access-Control-Allow-Credentials': 'true',
                'Content-type': 'text/xml; charset=utf-8'
              },
              body: soapEnvelope)
          .timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          // Request Timeout response status code
          return http.Response('Timeout Check NIK', 408);
        },
      );

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final listResultAll = document.findAllElements('Table');

        for (final listResult in listResultAll) {
          final statusData = listResult.findElements('StatusData').isEmpty
              ? 'No Data'
              : listResult.findElements('StatusData').first.innerText;

          if (statusData == "GAGAL") {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                StatusAlert.show(
                  context,
                  duration: const Duration(seconds: 1),
                  configuration: const IconConfiguration(
                      icon: Icons.error, color: Colors.red),
                  title: "Email/User ID seems don't match",
                  backgroundColor: Colors.grey[300],
                );

                setState(() {
                  loading = false;
                });
              }
            });
          } else {
            if (mounted) {
              setState(() {
                loading = false;
              });

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChangePass(
                    nik: nik,
                    email: email,
                  ),
                ),
              );
            }
          }
        }
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');

        if (mounted) {
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 1),
            configuration:
                const IconConfiguration(icon: Icons.error, color: Colors.red),
            title: "${response.statusCode}",
            subtitle: "Error Request OTP",
            backgroundColor: Colors.grey[300],
          );

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('$e');

      if (mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          title: "Error Request OTP",
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
  }

  @override
  void dispose() {
    nik.dispose();
    email.dispose();
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
              forgotPassForm(context),
            ],
          ),
        ),
      ),
    );
  }

  SingleChildScrollView forgotPassForm(BuildContext context) {
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
                Text(
                  'FORGOT',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: MediaQuery.of(context).textScaler.scale(28),
                  ),
                ),
                Text(
                  'PASSWORD',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: MediaQuery.of(context).textScaler.scale(28),
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        focusNode: _focusNode,
                        controller: nik,
                        autocorrect: false,
                        autofocus: true,
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
                          hintText: 'user***',
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
                        onEditingComplete: () async {},
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        focusNode: _focusNode1,
                        controller: email,
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
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
                          hintText: 'user@example.com',
                          labelText: 'Email',
                          icon: Icon(Icons.mail),
                        ),
                        validator: (value) {
                          String pattern =
                              r'^[\w-]+(\.[\w-]+)*@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,7}$';
                          RegExp regExp = RegExp(pattern);
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else if (!regExp.hasMatch(value)) {
                            return "Invalid input type";
                          } else {
                            return null;
                          }
                        },
                        onFieldSubmitted: (value) async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            setState(() {
                              loading = true;
                            });

                            await cekNIK(nik.text, value);
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
                                const Spacer(
                                  flex: 1,
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      setState(() {
                                        loading = true;
                                      });

                                      await cekNIK(nik.text, email.text);
                                    }
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Next',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.green,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
