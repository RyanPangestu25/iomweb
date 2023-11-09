// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:status_alert/status_alert.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool _viewPass = true;
  bool _viewConPass = true;
  bool isWait = false;
  String kodeOTP = '';
  var hasilJson = '';

  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();
  final FocusNode _focusNode5 = FocusNode();
  final FocusNode _focusNode6 = FocusNode();
  final FocusNode _focusNode7 = FocusNode();
  final FocusNode _focusNode8 = FocusNode();
  final FocusNode _focusNode9 = FocusNode();
  final FocusNode _focusNode10 = FocusNode();

  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController conPassword = TextEditingController();
  TextEditingController company = TextEditingController();
  TextEditingController npwp = TextEditingController();
  TextEditingController contact = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController otp = TextEditingController();
  TextEditingController country = TextEditingController();
  TextEditingController address = TextEditingController();

  // Future<void> regist() async {
  //   try {
  //     setState(() {
  //       loading = true;
  //     });

  //     String objBody = '<?xml version="1.0" encoding="utf-8"?>' +
  //         '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
  //         '<soap:Body>' +
  //         '<CreateAccount xmlns="http://tempuri.org/">' +
  //         '<KodeLoginSupplier>${username.text.toUpperCase()}</KodeLoginSupplier>' +
  //         '<supplierName>${company.text.toUpperCase()}</supplierName>' +
  //         '<password>${password.text}</password>' +
  //         '<CountryOrigin>${country.text.toUpperCase()}</CountryOrigin>' +
  //         '<telephoneNo>${phone.text}</telephoneNo>' +
  //         '<contactPerson>${contact.text.toUpperCase()}</contactPerson>' +
  //         '<email>${email.text}</email>' +
  //         '<Address>${address.text.toUpperCase()}</Address>' +
  //         '<NPWP>${npwp.text}</NPWP>' +
  //         '</CreateAccount>' +
  //         '</soap:Body>' +
  //         '</soap:Envelope>';

  //     final response = await http.post(Uri.parse(url_CreateAccount),
  //         headers: {
  //           "Access-Control-Allow-Origin": "*",
  //           'SOAPAction': 'http://tempuri.org/CreateAccount',
  //           "Access-Control-Allow-Credentials": "true",
  //           'Content-type': 'text/xml; charset=utf-8',
  //         },
  //         body: objBody);

  //     if (response.statusCode == 200) {
  //       final document = xml.XmlDocument.parse(response.body);

  //       final statusData =
  //           document.findAllElements('CreateAccountResult').isEmpty
  //               ? 'No Data'
  //               : document.findAllElements('CreateAccountResult').first.text;

  //       if (statusData == "GAGAL") {
  //         Future.delayed(const Duration(seconds: 1), () {
  //           StatusAlert.show(
  //             context,
  //             duration: const Duration(seconds: 1),
  //             configuration:
  //                 const IconConfiguration(icon: Icons.error, color: Colors.red),
  //             title: "Failed",
  //             backgroundColor: Colors.grey[300],
  //           );
  //           if (mounted) {
  //             setState(() {
  //               loading = false;
  //             });
  //           }
  //         });
  //       } else {
  //         Future.delayed(const Duration(seconds: 1), () async {
  //           StatusAlert.show(
  //             context,
  //             duration: const Duration(seconds: 1),
  //             configuration: const IconConfiguration(
  //                 icon: Icons.done, color: Colors.green),
  //             title: "Success",
  //             backgroundColor: Colors.grey[300],
  //           );

  //           Navigator.pushReplacementNamed(context, 'login');

  //           if (mounted) {
  //             setState(() {
  //               loading = false;
  //             });
  //           }
  //         });
  //       }
  //     } else {
  //       debugPrint('Error: ${response.statusCode}');
  //       debugPrint('Desc: ${response.body}');
  //       debugPrint(response.body);
  //       StatusAlert.show(
  //         context,
  //         duration: const Duration(seconds: 1),
  //         configuration:
  //             const IconConfiguration(icon: Icons.error, color: Colors.red),
  //         title: "${response.statusCode}",
  //         subtitle: "Failed Registration",
  //         backgroundColor: Colors.grey[300],
  //       );

  //       Future.delayed(const Duration(seconds: 1), () async {
  //         if (mounted) {
  //           setState(() {
  //             loading = false;
  //           });
  //         }

  //         await showDialog(
  //             context: context,
  //             barrierDismissible: false,
  //             builder: (context) {
  //               return TryAgain(
  //                 submit: (value) async {
  //                   if (value) {
  //                     await regist();
  //                   }
  //                 },
  //               );
  //             });
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('$e');
  //     StatusAlert.show(
  //       context,
  //       duration: const Duration(seconds: 2),
  //       configuration:
  //           const IconConfiguration(icon: Icons.error, color: Colors.red),
  //       title: "Failed Registration",
  //       subtitle: "$e",
  //       subtitleOptions: StatusAlertTextConfiguration(
  //         overflow: TextOverflow.visible,
  //       ),
  //       backgroundColor: Colors.grey[300],
  //     );

  //     Future.delayed(const Duration(seconds: 1), () async {
  //       if (mounted) {
  //         setState(() {
  //           loading = false;
  //         });
  //       }

  //       await showDialog(
  //           context: context,
  //           barrierDismissible: false,
  //           builder: (context) {
  //             return TryAgain(
  //               submit: (value) async {
  //                 if (value) {
  //                   await regist();
  //                 }
  //               },
  //             );
  //           });
  //     });
  //   }
  // }

  // Future<void> requestOTP(String email) async {
  //   try {
  //     setState(() {
  //       loading = true;
  //     });

  //     final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
  //         '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
  //         '<soap:Body>' +
  //         '<SendOTP xmlns="http://tempuri.org/">' +
  //         '<Email>$email</Email>' +
  //         '</SendOTP>' +
  //         '</soap:Body>' +
  //         '</soap:Envelope>';

  //     final response = await http.post(Uri.parse(url_SendOTP),
  //         headers: <String, String>{
  //           "Access-Control-Allow-Origin": "*",
  //           'SOAPAction': 'http://tempuri.org/SendOTP',
  //           'Access-Control-Allow-Credentials': 'true',
  //           'Content-type': 'text/xml; charset=utf-8'
  //         },
  //         body: soapEnvelope);

  //     if (response.statusCode == 200) {
  //       final responseBody = response.body;
  //       final parsedResponse = xml.XmlDocument.parse(responseBody);
  //       final result =
  //           parsedResponse.findAllElements('SendOTPResult').single.text;
  //       debugPrint('Result: $result');
  //       Future.delayed(const Duration(seconds: 1), () async {
  //         if (result == "GAGAL") {
  //           Future.delayed(const Duration(seconds: 1), () {
  //             StatusAlert.show(
  //               context,
  //               duration: const Duration(seconds: 1),
  //               configuration: const IconConfiguration(
  //                   icon: Icons.error, color: Colors.red),
  //               title: "Failed",
  //               backgroundColor: Colors.grey[300],
  //             );
  //             if (mounted) {
  //               setState(() {
  //                 loading = false;
  //               });
  //             }
  //           });
  //         } else {
  //           startTimer();

  //           StatusAlert.show(
  //             context,
  //             duration: const Duration(seconds: 1),
  //             configuration: const IconConfiguration(
  //                 icon: Icons.done, color: Colors.green),
  //             title: "OTP has been sent to your Email",
  //             backgroundColor: Colors.grey[300],
  //           );
  //           setState(() {
  //             kodeOTP = result;
  //             loading = false;
  //           });
  //         }
  //       });
  //     } else {
  //       debugPrint('Error: ${response.statusCode}');
  //       debugPrint('Desc: ${response.body}');
  //       StatusAlert.show(
  //         context,
  //         duration: const Duration(seconds: 1),
  //         configuration:
  //             const IconConfiguration(icon: Icons.error, color: Colors.red),
  //         title: "${response.statusCode}",
  //         subtitle: "Error Request OTP",
  //         backgroundColor: Colors.grey[300],
  //       );
  //       setState(() {
  //         loading = false;
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('$e');
  //     StatusAlert.show(
  //       context,
  //       duration: const Duration(seconds: 2),
  //       configuration:
  //           const IconConfiguration(icon: Icons.error, color: Colors.red),
  //       title: "Error Request OTP",
  //       subtitle: "$e",
  //       subtitleOptions: StatusAlertTextConfiguration(
  //         overflow: TextOverflow.visible,
  //       ),
  //       backgroundColor: Colors.grey[300],
  //     );
  //     setState(() {
  //       loading = false;
  //     });
  //   }
  // }

  Timer? timer;
  int no = 30;

  void startTimer() {
    const duration = Duration(seconds: 1);
    timer = Timer.periodic(duration, (Timer t) {
      setState(() {
        no = no - 1;
      });

      if (no == 0) {
        setState(() {
          isWait = false;
          no = 30;
        });
        timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    username.dispose();
    password.dispose();
    conPassword.dispose();
    company.dispose();
    npwp.dispose();
    contact.dispose();
    phone.dispose();
    email.dispose();
    country.dispose();
    address.dispose();
    _focusNode.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    _focusNode4.dispose();
    _focusNode5.dispose();
    _focusNode6.dispose();
    _focusNode7.dispose();
    _focusNode8.dispose();
    _focusNode9.dispose();
    _focusNode10.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        _focusNode1.unfocus();
        _focusNode2.unfocus();
        _focusNode3.unfocus();
        _focusNode4.unfocus();
        _focusNode5.unfocus();
        _focusNode6.unfocus();
        _focusNode7.unfocus();
        _focusNode8.unfocus();
        _focusNode9.unfocus();
        _focusNode10.unfocus();
      },
      child: Scaffold(
        body: ListView(
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
            registerForm(context),
          ],
        ),
      ),
    );
  }

  SingleChildScrollView registerForm(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          SizedBox(height: size.height * 0.01),
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
                SizedBox(height: size.height * 0.01),
                Text('Register',
                    style: Theme.of(context).textTheme.headlineMedium),
                SizedBox(height: size.height * 0.02),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        focusNode: _focusNode,
                        readOnly: loading,
                        controller: username,
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
                          labelText: 'Username',
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
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        focusNode: _focusNode1,
                        readOnly: loading,
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
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        focusNode: _focusNode2,
                        readOnly: loading,
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
                          labelText: 'Confirm Password',
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
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        focusNode: _focusNode3,
                        readOnly: loading,
                        controller: company,
                        autocorrect: false,
                        enableSuggestions: true,
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
                          hintText: 'PT Lion Air',
                          labelText: 'Company Name',
                          icon: Icon(Icons.business_rounded),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else {
                            return null;
                          }
                        },
                      ),
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        focusNode: _focusNode4,
                        readOnly: loading,
                        controller: npwp,
                        autocorrect: false,
                        enableSuggestions: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(signed: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
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
                          hintText: '01.234***',
                          labelText: 'NPWP',
                          icon: Icon(Icons.credit_card),
                        ),
                        validator: (value) {
                          String pattern = r"[0-9]";
                          RegExp regExp = RegExp(pattern);
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else if (!regExp.hasMatch(value)) {
                            return "Invalid input type";
                          } else if (value.length < 15) {
                            return 'NPWP must be equal to 15 characters';
                          } else {
                            return null;
                          }
                        },
                      ),
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        focusNode: _focusNode5,
                        readOnly: loading,
                        controller: contact,
                        autocorrect: false,
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
                          hintText: 'User',
                          labelText: 'Contact Person',
                          icon: Icon(Icons.contacts),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else {
                            return null;
                          }
                        },
                      ),
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        focusNode: _focusNode6,
                        readOnly: loading,
                        controller: phone,
                        autocorrect: false,
                        keyboardType: TextInputType.phone,
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
                          hintText: '01234***',
                          labelText: 'Phone Number',
                          icon: Icon(Icons.phone),
                        ),
                        validator: (value) {
                          String pattern = r"[0-9]";
                          RegExp regExp = RegExp(pattern);
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else if (!regExp.hasMatch(value)) {
                            return "Invalid input type";
                          } else {
                            return null;
                          }
                        },
                      ),
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        focusNode: _focusNode7,
                        readOnly: loading,
                        controller: email,
                        autocorrect: false,
                        enableSuggestions: true,
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
                      ),
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        focusNode: _focusNode8,
                        readOnly: loading,
                        controller: otp,
                        autocorrect: false,
                        enableSuggestions: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                        ),
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
                          suffixIcon: TextButton(
                            onPressed: isWait
                                ? null
                                : loading
                                    ? null
                                    : () async {
                                        if (email.text.isEmpty) {
                                          StatusAlert.show(
                                            context,
                                            duration:
                                                const Duration(seconds: 3),
                                            configuration:
                                                const IconConfiguration(
                                                    icon: Icons.error,
                                                    color: Colors.red),
                                            title:
                                                "Please Fills Out Your Email!!",
                                            backgroundColor: Colors.grey[300],
                                          );
                                        } else {
                                          setState(() {
                                            loading = true;
                                            isWait = true;
                                          });
                                          // await requestOTP(email.text.trim());
                                        }
                                      },
                            child:
                                isWait ? Text('$no') : const Text('Send OTP'),
                          ),
                          hintText: '123***',
                          labelText: 'OTP',
                          icon: const Icon(Icons.chat),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else if (value != kodeOTP) {
                            return "OTP doesn't match";
                          } else {
                            return null;
                          }
                        },
                      ),
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        focusNode: _focusNode9,
                        readOnly: loading,
                        controller: country,
                        autocorrect: false,
                        enableSuggestions: true,
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
                          hintText: 'Indonesia',
                          labelText: 'Country Origin',
                          icon: Icon(Icons.flag_rounded),
                        ),
                        validator: (value) {
                          String pattern = r"[a-z]";
                          RegExp regExp = RegExp(pattern);
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else if (!regExp.hasMatch(value)) {
                            return "Invalid input type";
                          } else {
                            return null;
                          }
                        },
                      ),
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        focusNode: _focusNode10,
                        readOnly: loading,
                        controller: address,
                        autocorrect: false,
                        keyboardType: TextInputType.streetAddress,
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
                          hintText: 'Jl. Suka-suka',
                          labelText: 'Address',
                          icon: Icon(Icons.map_outlined),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Text can't be empty";
                          } else {
                            return null;
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.03),
                loading
                    ? const CircularProgressIndicator()
                    : Row(
                        children: [
                          TextButton.icon(
                            onPressed: loading
                                ? null
                                : () async {
                                    Navigator.of(context).pop();
                                  },
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: loading ? null : Colors.red,
                            ),
                            label: Text(
                              'Back',
                              style: TextStyle(
                                color: loading ? null : Colors.red,
                              ),
                            ),
                          ),
                          const Spacer(flex: 1),
                          TextButton.icon(
                            onPressed: loading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      setState(() {
                                        loading = true;
                                      });

                                      Future.delayed(const Duration(seconds: 1),
                                          () async {
                                        setState(() {
                                          loading = false;
                                        });
                                      });

                                      // await regist();
                                    }
                                  },
                            icon: Icon(
                              Icons.done,
                              color: loading ? null : Colors.green,
                            ),
                            label: Text(
                              'Validate',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: loading ? null : Colors.green),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.05),
        ],
      ),
    );
  }
}
