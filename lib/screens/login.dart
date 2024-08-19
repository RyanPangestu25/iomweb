// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/alertdialog/log_error.dart';
import '/screens/forgot_pass.dart';
import 'package:status_alert/status_alert.dart';
import '../backend/constants.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'change_pass.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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

  Future<void> loginApp(String nik, String password) async {
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
              : listResult.findElements('StatusData').first.innerText;

          if (statusData == "GAGAL") {
            Future.delayed(const Duration(seconds: 1), () {
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 1),
                configuration: const IconConfiguration(
                    icon: Icons.error, color: Colors.red),
                title: "Error Login, Registration Already?",
                titleOptions: StatusAlertTextConfiguration(
                  overflow: TextOverflow.visible,
                ),
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
                : listResult.findElements('UserName').first.innerText;
            final iomCharterLevel = listResult
                    .findElements('IOMCharterLevel')
                    .isEmpty
                ? 'No Data'
                : listResult.findElements('IOMCharterLevel').first.innerText;
            final iomOpenAccess =
                listResult.findElements('IOMOpenAccess').isEmpty
                    ? 'No Data'
                    : listResult.findElements('IOMOpenAccess').first.innerText;
            final userEmail = listResult.findElements('UserEmail').isEmpty
                ? 'No Data'
                : listResult.findElements('UserEmail').first.innerText;
            final nik = listResult.findElements('NIK').isEmpty
                ? 'No Data'
                : listResult.findElements('NIK').first.innerText;
            // final isAuth = listResult.findElements('isAuth').isEmpty
            //     ? '0'
            //     : listResult.findElements('isAuth').first.innerText;
            final passRange = listResult.findElements('PassRange').isEmpty
                ? '0'
                : listResult.findElements('PassRange').first.innerText;

            temporaryList.add({
              'userName': userName,
              'userLevel': iomCharterLevel.toUpperCase() == 'VIEW'
                  ? '17'
                  : iomCharterLevel.toUpperCase() == 'CREATOR'
                      ? '19'
                      : iomCharterLevel.toUpperCase() == 'FINANCE'
                          ? '12'
                          : '10',
              'userOpen': iomOpenAccess,
              'userEmail': userEmail,
              'nik': nik,
            });

            // hasilJson = jsonEncode(temporaryList);
            //debugPrint(hasilJson);

            Future.delayed(const Duration(seconds: 1), () async {
              String pattern =
                  r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#$%^&*()_+{}\[\]:;<>,.?~])';
              RegExp regExp = RegExp(pattern);

              if (password == '123' ||
                  (!regExp.hasMatch(password) && password.length < 11)) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChangePass(
                      nik: nik,
                      email: userEmail,
                    ),
                  ),
                );
              } else {
                if (double.parse(passRange) < 4) {
                  await saveData(
                    userName,
                    temporaryList.last['userLevel'],
                    iomOpenAccess,
                    userEmail,
                    nik,
                  );

                  if (mounted) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const HomeScreen();
                      },
                    ));
                  }
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangePass(
                        nik: nik,
                        email: userEmail,
                      ),
                    ),
                  );
                }

                // if (double.parse(isAuth) == 1) {
                //   if (double.parse(passRange) < 4) {
                //     await showDialog(
                //       context: context,
                //       barrierDismissible: false,
                //       builder: (BuildContext context) {
                //         final now =
                //             tz.TZDateTime.now(tz.getLocation('Asia/Jakarta'));

                //         return OTPLogin(
                //           isValid: (value) {
                //             return false;
                //           },
                //           data: [
                //             {
                //               'userName': userName,
                //               'userLevel': temporaryList.last['userLevel'],
                //               'userOpen': iomOpenAccess,
                //               'userEmail': userEmail,
                //               'nik': nik,
                //             },
                //           ],
                //           otpStream: Stream<dynamic>.periodic(
                //               const Duration(seconds: 0),
                //               (val) => OTP.generateTOTPCodeString(
                //                   base32.encodeString(nik + 'IC'),
                //                   now.millisecondsSinceEpoch,
                //                   length: 6,
                //                   interval: 30,
                //                   algorithm: Algorithm.SHA1,
                //                   isGoogle: true)).asBroadcastStream(),
                //           isUpdate: false,
                //         );
                //       },
                //     );
                //   } else {
                //     Navigator.of(context).pushReplacement(
                //       MaterialPageRoute(
                //         builder: (context) => ChangePass(
                //           nik: nik,
                //           email: userEmail,
                //         ),
                //       ),
                //     );
                //   }
                // } else {
                //   await showDialog(
                //     context: context,
                //     barrierDismissible: false,
                //     builder: (BuildContext context) {
                //       final now =
                //           tz.TZDateTime.now(tz.getLocation('Asia/Jakarta'));

                //       return OTPRegist(
                //         data: [
                //           {
                //             'userName': userName,
                //             'userLevel': temporaryList.last['userLevel'],
                //             'userOpen': iomOpenAccess,
                //             'userEmail': userEmail,
                //             'nik': nik,
                //           },
                //         ],
                //         otpStream: Stream<dynamic>.periodic(
                //           const Duration(seconds: 0),
                //           (val) => OTP.generateTOTPCodeString(
                //             base32.encodeString(nik + 'IC'),
                //             now.millisecondsSinceEpoch,
                //             length: 6,
                //             interval: 30,
                //             algorithm: Algorithm.SHA1,
                //             isGoogle: true,
                //           ),
                //         ).asBroadcastStream(),
                //       );
                //     },
                //   );
                // }
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
        //debugPrint('Error: ${response.statusCode}');
        //debugPrint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Error Login',
                  error: response.body.toString(),
                );
              });

          setState(() {
            loading = false;
          });
        }
      }

      setState(() {
        hasilResult = temporaryList;
      });
    } catch (e) {
      //debugPrint('$e');

      if (mounted) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Error Login',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> saveData(
    String userName,
    String userLevel,
    String userOpen,
    String userEmail,
    String nik,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    await prefs.setString('userLevel', userLevel);
    await prefs.setString('userOpen', userOpen);
    await prefs.setString('userEmail', userEmail);
    await prefs.setString('nik', nik);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    nik.dispose();
    password.dispose();
    _focusNode.dispose();
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
                      fontSize: MediaQuery.of(context).textScaler.scale(30),
                    ),
                  ),
                  Text(
                    "CHARTER",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                      fontSize: MediaQuery.of(context).textScaler.scale(30),
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
                        onFieldSubmitted: (value) async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            setState(() {
                              loading = true;
                            });

                            await loginApp(nik.text, value);
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        disabledColor: Colors.grey,
                        color: Colors.redAccent,
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            setState(() {
                              loading = true;
                            });

                            await loginApp(nik.text, password.text);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 100,
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
          // const SizedBox(height: 20),
          // const Text('OR'),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: <Widget>[
          //     TextButton(
          //       style: TextButton.styleFrom(
          //         textStyle: const TextStyle(
          //             fontSize: 17, fontWeight: FontWeight.bold),
          //       ),
          //       onPressed: () async {
          //         Navigator.of(context).push(MaterialPageRoute(
          //           builder: (BuildContext context) {
          //             return const RegisterScreen();
          //           },
          //         ));
          //       },
          //       child: const Text('Create a new account'),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
