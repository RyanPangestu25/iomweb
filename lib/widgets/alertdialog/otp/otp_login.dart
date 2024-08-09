// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:async';
import '/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../log_error.dart';

class OTPLogin extends StatefulWidget {
  final Function(bool) isValid;
  final List data;
  final Stream<dynamic> otpStream;
  final bool isUpdate;

  const OTPLogin({
    super.key,
    required this.isValid,
    required this.data,
    required this.otpStream,
    required this.isUpdate,
  });

  @override
  State<OTPLogin> createState() => _OTPLoginState();
}

class _OTPLoginState extends State<OTPLogin> {
  bool loading = false;
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

        if (widget.isUpdate) {
          StatusAlert.show(
            context,
            dismissOnBackgroundTap: true,
            duration: const Duration(seconds: 2),
            configuration: const IconConfiguration(
              icon: Icons.done,
              color: Colors.green,
            ),
            title: "Valid OTP",
            backgroundColor: Colors.grey[300],
          );

          widget.isValid(true);
          Navigator.of(context).pop();
        } else {
          if (!widget.isUpdate) {
            await saveData(
              widget.data.last['userName'],
              widget.data.last['userLevel'],
              widget.data.last['userOpen'],
              widget.data.last['userEmail'],
              widget.data.last['nik'],
            );
          }

          if (mounted) {
            StatusAlert.show(
              context,
              dismissOnBackgroundTap: true,
              duration: const Duration(seconds: 2),
              configuration: const IconConfiguration(
                icon: Icons.done,
                color: Colors.green,
              ),
              title: "Welcome,",
              subtitle: widget.data.last['userName'],
              subtitleOptions: StatusAlertTextConfiguration(
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.grey[300],
            );

            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (BuildContext context) {
                return const HomeScreen();
              },
            ));
          }
        }
      } else {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
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
      if (mounted) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Failed Check OTP',
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
                        ? size.width * 0.07
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
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: loading
                  ? null
                  : () {
                      if (widget.isUpdate) {
                        widget.isValid(false);
                      }

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
        ),
      ),
    );
  }
}
