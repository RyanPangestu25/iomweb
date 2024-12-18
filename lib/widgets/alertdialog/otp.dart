// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:status_alert/status_alert.dart';
import '../../backend/constants.dart';
import '../../screens/change_pass.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import 'log_error.dart';

class CekOTP extends StatefulWidget {
  final String nik;
  final String email;
  final String kodeOTP;

  const CekOTP({
    super.key,
    required this.nik,
    required this.email,
    required this.kodeOTP,
  });

  @override
  State<CekOTP> createState() => _CekOTPState();
}

class _CekOTPState extends State<CekOTP> {
  bool loading = false;
  bool isWait = true;
  String kodeOTP = '';
  String currentText = '';

  TextEditingController otpController = TextEditingController();

  StreamController<ErrorAnimationType>? errorController;

  final FocusNode _focusNode = FocusNode();

  Future<void> requestOTP(String nik, String email) async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<LupaPass xmlns="http://tempuri.org/">' +
          '<nik>$nik</nik>' +
          '<UserEmail>$email</UserEmail>' +
          '</LupaPass>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_LupaPass),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/LupaPass',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final parsedResponse = xml.XmlDocument.parse(responseBody);
        final result =
            parsedResponse.findAllElements('LupaPassResult').single.text;
        //debugPrint('Result: $result');
        Future.delayed(const Duration(seconds: 1), () async {
          if (result == "GAGAL") {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 1),
              configuration:
                  const IconConfiguration(icon: Icons.error, color: Colors.red),
              title: "Email/User ID seems don't match",
              backgroundColor: Colors.grey[300],
            );
            setState(() {
              loading = false;
            });
          } else {
            setState(() {
              kodeOTP = result;
            });

            startTimer();

            StatusAlert.show(
              context,
              duration: const Duration(seconds: 1),
              configuration: const IconConfiguration(
                  icon: Icons.done, color: Colors.green),
              title: "OTP has been sent to your Email",
              backgroundColor: Colors.grey[300],
            );
            setState(() {
              loading = false;
            });
          }
        });
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
                  fail: 'Error Request OTP',
                  error: response.body.toString(),
                );
              });

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      //debugPrint('$e');

      if (mounted) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Error Request OTP',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      startTimer();

      setState(() {
        kodeOTP = widget.kodeOTP;
      });
    });

    errorController = StreamController<ErrorAnimationType>();
    currentText = otpController.text;
  }

  @override
  void dispose() {
    timer?.cancel();
    errorController!.close();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: AlertDialog(
        icon: const Icon(
          Icons.chat,
          size: 50,
        ),
        iconColor: Colors.blue,
        title: const Text('VALIDATE OTP'),
        content: SizedBox(
          width: size.width < 600 || (size.width > 600 && size.width < 1000)
              ? size.width * 0.5
              : size.width * 0.4,
          child: SingleChildScrollView(
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PinCodeTextField(
                  focusNode: _focusNode,
                  appContext: context,
                  length: 8,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.underline,
                    borderRadius: BorderRadius.circular(5),
                    fieldHeight: 50,
                    fieldWidth: size.width < 600 ||
                            (size.width > 600 && size.width < 1500)
                        ? size.width * 0.04
                        : 50,
                    activeFillColor: Colors.white,
                    inactiveFillColor: Colors.white,
                    fieldOuterPadding: const EdgeInsets.all(5),
                  ),
                  animationDuration: const Duration(milliseconds: 300),
                  backgroundColor: Colors.blue.shade50,
                  enableActiveFill: true,
                  errorAnimationController: errorController,
                  controller: otpController,
                  onCompleted: (value) async {
                    setState(() {
                      loading = true;
                    });

                    Future.delayed(const Duration(seconds: 1), () async {
                      if (otpController.text == kodeOTP) {
                        StatusAlert.show(
                          context,
                          duration: const Duration(seconds: 1),
                          configuration: const IconConfiguration(
                              icon: Icons.done, color: Colors.green),
                          title: "Valid OTP",
                          backgroundColor: Colors.grey[300],
                        );
                        setState(() {
                          loading = false;
                        });

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => ChangePass(
                              nik: widget.nik,
                              email: widget.email,
                              isFirst: false,
                            ),
                          ),
                        );
                      } else {
                        StatusAlert.show(
                          context,
                          duration: const Duration(seconds: 1),
                          configuration: const IconConfiguration(
                              icon: Icons.error, color: Colors.red),
                          title: "Invalid OTP",
                          backgroundColor: Colors.grey[300],
                        );
                        setState(() {
                          loading = false;
                        });
                      }
                    });
                  },
                  pastedTextStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  beforeTextPaste: (text) {
                    //debugPrint("Paste $text");
                    //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                    //but you can show anything you want here, like your pop up saying wrong paste format or etc
                    return true;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isWait
                ? null
                : loading
                    ? null
                    : () async {
                        setState(() {
                          loading = true;
                          isWait = true;
                        });

                        await requestOTP(widget.nik, widget.email);
                      },
            child: isWait ? Text('$no') : const Text("Resend OTP"),
          ),
          TextButton(
            onPressed: loading
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  )
                : const Text("Close"),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
