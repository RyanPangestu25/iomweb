// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, non_constant_identifier_names, prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:base32/base32.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'otp_regist2.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class OTPRegist extends StatefulWidget {
  final List data;
  final Stream<dynamic> otpStream;

  const OTPRegist({
    super.key,
    required this.data,
    required this.otpStream,
  });

  @override
  State<OTPRegist> createState() => _OTPRegistState();
}

class _OTPRegistState extends State<OTPRegist> {
  bool loading = false;
  bool isHide = false;
  String status = '';
  String qrData = '';
  String appName = 'Unknown';

  Future<void> initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      appName = info.appName;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initPackageInfo();

      qrData =
          'otpauth://totp/${widget.data.last['nik']}?Algorithm=SHA1&digits=6&secret=${base32.encodeString(widget.data.last['nik'].toString() + 'IC')}&issuer=IOMWeb&period=30';
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
      height: size.height,
      child: AlertDialog(
        icon: const Icon(
          Icons.chat,
          size: 50,
        ),
        iconColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'REGISTER MICROSOFT AUTHENTICATOR',
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    setState(() {
                      isHide = !isHide;
                    });
                  },
                  icon: Icon(isHide ? Icons.visibility : Icons.visibility_off),
                ),
                IconButton(
                  onPressed: () async {
                    FlutterClipboard.copy(
                      base32.encodeString(
                          widget.data.last['nik'].toString() + 'IC'),
                    );

                    // debugPrint(base32.encodeString(widget.data.last['nik'].toString()+'IC'));

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        showCloseIcon: false,
                        duration: Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        padding: EdgeInsets.all(20),
                        elevation: 10,
                        content: Center(
                          child: Text(
                            'Secret Code copied!!',
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          height: size.height * 0.8,
          width: size.width * 0.5,
          child: SingleChildScrollView(
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                isHide
                    ? Center(
                        child: SizedBox(
                          height: 250,
                          width: 250,
                          child: PrettyQrView.data(
                            data: qrData,
                            decoration: const PrettyQrDecoration(
                              image: PrettyQrDecorationImage(
                                image: AssetImage('assets/images/logo.png'),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                Text.rich(
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaler.scale(17),
                  ),
                  const TextSpan(
                    text:
                        'Aplikasi ini membutuhkan aplikasi pihak ketiga yaitu ',
                    children: [
                      TextSpan(
                        text: 'Microsoft Authenticator',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                const Divider(thickness: 3),
                SizedBox(height: size.height * 0.01),
                Text.rich(
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaler.scale(17),
                  ),
                  const TextSpan(
                    text: 'Aplikasi ',
                    children: [
                      TextSpan(
                        text: 'Microsoft Authenticator',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' dapat dicari di ',
                      ),
                      TextSpan(
                        text: 'Play Store',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' ataupun ',
                      ),
                      TextSpan(
                        text: 'App Store.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                const Divider(thickness: 3),
                SizedBox(height: size.height * 0.01),
                Text.rich(
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaler.scale(17),
                  ),
                  const TextSpan(
                    text: 'Klik ',
                    children: [
                      WidgetSpan(
                        child: Icon(Icons.copy),
                      ),
                      TextSpan(
                        text: ' untuk menyalin kode rahasia anda atau klik ',
                      ),
                      WidgetSpan(
                        child: Icon(Icons.visibility_off),
                      ),
                      TextSpan(
                        text: ' untuk mendapatkan kode QR.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                const Divider(thickness: 3),
                SizedBox(height: size.height * 0.01),
                Text.rich(
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaler.scale(17),
                  ),
                  const TextSpan(
                    text: 'Buka aplikasi ',
                    children: [
                      TextSpan(
                        text: 'Microsoft Authenticator',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' anda.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                const Divider(thickness: 3),
                SizedBox(height: size.height * 0.01),
                Text.rich(
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaler.scale(17),
                  ),
                  const TextSpan(
                    text: 'Klik ',
                    children: [
                      WidgetSpan(
                        child: Icon(Icons.add),
                      ),
                      TextSpan(
                        text: ' dan pilih Other atau lainnya.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                const Divider(thickness: 3),
                SizedBox(height: size.height * 0.01),
                Text.rich(
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaler.scale(17),
                  ),
                  TextSpan(
                    text: 'Scan kode QR pada website di aplikasi ',
                    children: [
                      const TextSpan(
                        text: 'Microsoft Authenticator',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' atau Pilih tambah manual atau Enter Code Manually pada aplikasi ',
                      ),
                      const TextSpan(
                        text: 'Microsoft Authenticator',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text: ' dan masukkan nama berupa ',
                      ),
                      TextSpan(
                        text: appName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' beserta kode rahasia yang sudah disalin sebelumnya.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                const Divider(thickness: 3),
                SizedBox(height: size.height * 0.01),
                Text.rich(
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaler.scale(17),
                  ),
                  const TextSpan(
                    text:
                        'Setelah anda mendapatkan kode OTP berupa 6 digit angka dari aplikasi ',
                    children: [
                      TextSpan(
                        text: 'Microsoft Authenticator',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' anda, salin kode tersebut dan masukkan kode tersebut pada halaman selanjutnya dengan klik ',
                      ),
                      TextSpan(
                        text: 'Next',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            'Close',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return OTPRegist2(
                              data: widget.data,
                              otpStream: widget.otpStream,
                            );
                          },
                        );
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Next',
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
        ),
      ),
    );
  }
}
