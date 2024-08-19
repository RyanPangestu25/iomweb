// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, non_constant_identifier_names, prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../backend/constants.dart';
import '../../../screens/login.dart';
import 'package:status_alert/status_alert.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../log_error.dart';

class OTPRegist2 extends StatefulWidget {
  final List data;
  final Stream<dynamic> otpStream;

  const OTPRegist2({
    super.key,
    required this.data,
    required this.otpStream,
  });

  @override
  State<OTPRegist2> createState() => _OTPRegist2State();
}

class _OTPRegist2State extends State<OTPRegist2> {
  bool loading = false;
  bool isHide = false;
  late StreamSubscription _twoFASubscription;
  var _currentOtp;

  TextEditingController otp = TextEditingController();

  StreamController<ErrorAnimationType>? errorController;

  final FocusNode _focusNode = FocusNode();

  Future<void> cekOTP() async {
    try {
      if (otp.text == _currentOtp.toString()) {
        setState(() {
          _twoFASubscription.cancel();
        });

        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration: const IconConfiguration(
            icon: Icons.done,
            color: Colors.green,
          ),
          title: "Valid OTP",
          backgroundColor: Colors.grey[300],
        );

        await updateAuth();
      } else {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration: const IconConfiguration(
            icon: Icons.error,
            color: Colors.red,
          ),
          title: "Invalid OTP",
          backgroundColor: Colors.grey[300],
        );

        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        configuration:
            const IconConfiguration(icon: Icons.error, color: Colors.red),
        title: "Error",
        subtitle: '$e',
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

  Future<void> updateAuth() async {
    try {
      setState(() {
        loading = true;
      });

      String objBody = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<UpdateAuth xmlns="http://tempuri.org/">' +
          '<nik>${widget.data.last['nik']}</nik>' +
          '</UpdateAuth>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http
          .post(Uri.parse(url_UpdateAuth),
              headers: {
                "Access-Control-Allow-Origin": "*",
                'SOAPAction': 'http://tempuri.org/UpdateAuth',
                "Access-Control-Allow-Credentials": "true",
                'Content-type': 'text/xml; charset=utf-8',
              },
              body: objBody)
          .timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          // Request Timeout response status code
          return http.Response('Timeout Update Auth', 408);
        },
      );

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('UpdateAuthResult').isEmpty
            ? 'No Data'
            : document.findAllElements('UpdateAuthResult').first.innerText;

        if (statusData == "GAGAL") {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                loading = false;
                otp.clear();
              });
            }

            StatusAlert.show(
              context,
              duration: const Duration(seconds: 3),
              configuration: const IconConfiguration(
                icon: Icons.error,
                color: Colors.red,
              ),
              title: "Failed Update Auth",
              backgroundColor: Colors.grey[300],
            );
          });
        } else {
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 1),
            configuration: const IconConfiguration(
              icon: Icons.done,
              color: Colors.green,
            ),
            title: "Success",
            backgroundColor: Colors.grey[300],
          );

          Future.delayed(const Duration(seconds: 1), () async {
            if (mounted) {
              setState(() {
                loading = false;
              });
            }

            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
              builder: (context) {
                return const LoginScreen();
              },
            ), (route) => false);
          });
        }
      } else {
        // debugPrint('Error Auth: ${response.statusCode}');
        // debugPrint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Failed Update Auth',
                  error: response.body,
                );
              });

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      // debugPrint('$e');

      if (mounted) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Failed Update Auth',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _twoFASubscription = widget.otpStream.listen((event) {
        setState(() {
          _currentOtp = event;
        });

        // debugPrint('OTP: $_currentOtp');
      });
    });

    errorController = StreamController<ErrorAnimationType>();
  }

  @override
  void dispose() {
    super.dispose();
    errorController!.close();
    _twoFASubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: SizedBox(
        height: size.height,
        width: size.width * 0.5,
        child: AlertDialog(
          icon: const Icon(
            Icons.chat,
            size: 50,
          ),
          iconColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'VALIDATE AUTHENTICATOR',
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Please Provide the OTP Code from Your Microsoft Authenticator Apps.',
                  textAlign: TextAlign.justify,
                ),
                SizedBox(height: size.height * 0.01),
                PinCodeTextField(
                  focusNode: _focusNode,
                  appContext: context,
                  length: 6,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.underline,
                    borderRadius: BorderRadius.circular(5),
                    fieldHeight: 50,
                    fieldWidth: size.width < 600 ||
                            (size.width > 600 && size.width < 1000)
                        ? 55
                        : 50,
                    activeFillColor: Colors.white,
                    inactiveFillColor: Colors.white,
                    fieldOuterPadding: const EdgeInsets.all(5),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  animationDuration: const Duration(milliseconds: 300),
                  backgroundColor: Colors.blue.shade50,
                  enableActiveFill: true,
                  errorAnimationController: errorController,
                  controller: otp,
                  onCompleted: (value) async {
                    _focusNode.unfocus();

                    setState(() {
                      loading = true;
                    });

                    await cekOTP();
                  },
                  pastedTextStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  beforeTextPaste: (text) {
                    // debugPrint("Paste $text");
                    //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                    //but you can show anything you want here, like your pop up saying wrong paste format or etc
                    return true;
                  },
                ),
                // Text('$_currentOtp'),
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                      child: const Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: Colors.red,
                          ),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
