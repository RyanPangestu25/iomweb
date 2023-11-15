// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';
import '../../widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import '../../screens/view_iom.dart';

class Confirmation extends StatefulWidget {
  final String text;
  final List iom;

  const Confirmation({
    super.key,
    required this.iom,
    required this.text,
  });

  @override
  State<Confirmation> createState() => _ConfirmationState();
}

class _ConfirmationState extends State<Confirmation> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  String userName = '';
  String level = '';

  Future<void> approval() async {
    try {
      setState(() {
        loading = true;
      });

      String status = widget.text == 'APPROVE' ? 'APPROVED' : 'REJECTED';

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<Approval xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<Status_konfirmasi_direksi>$status</Status_konfirmasi_direksi>' +
          '<server>${widget.iom.last['server']}</server>' +
          '<ConfirmedBy>$userName</ConfirmedBy>' +
          '</Approval>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_Approval),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/Approval',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('ApprovalResult').isEmpty
            ? 'Error'
            : document.findAllElements('ApprovalResult').first.text;

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
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 2),
              configuration: const IconConfiguration(
                  icon: Icons.done, color: Colors.green),
              title: "Success",
              backgroundColor: Colors.grey[300],
            );

            if (mounted) {
              setState(() {
                loading = false;
              });
            }

            if (level == '12') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) {
                  return const ViewIOM(
                    title: 'IOM Verification',
                  );
                },
              ));
            } else if (level == '10') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) {
                  return const ViewIOM(
                    title: 'IOM Approval',
                  );
                },
              ));
            } else {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) {
                  return const ViewIOM(
                    title: 'View IOM',
                  );
                },
              ));
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
          subtitle: "Failed to ${widget.text}",
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
        title: "Failed to ${widget.text}",
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

  Future<void> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('userName');
    String? userLevel = prefs.getString('userLevel');

    setState(() {
      this.userName = userName ?? 'No Data';
      debugPrint(userName);

      level = userLevel ?? 'No Data';
      debugPrint(level);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getUser();
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
      child: Stack(
        children: [
          AlertDialog(
            icon: Icon(
              Icons.done,
              size: size.height * 0.1,
            ),
            iconColor: Colors.green,
            title: const Text('CONFIRMATION'),
            content: SingleChildScrollView(
              clipBehavior: Clip.antiAlias,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RichText(
                      text: TextSpan(
                        text: 'Do you really want to ',
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: widget.text.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.text.toUpperCase() == 'APPROVE'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const TextSpan(text: ' this?'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading
                    ? null
                    : () async {
                        setState(() {
                          loading = true;
                        });

                        await approval();
                      },
                child: Text(
                  "Yes",
                  style: TextStyle(
                    color: loading ? null : Colors.green,
                  ),
                ),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: Text(
                  "No",
                  style: TextStyle(
                    color: loading ? null : Colors.red,
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
          ),
          LoadingWidget(isLoading: loading),
        ],
      ),
    );
  }
}
