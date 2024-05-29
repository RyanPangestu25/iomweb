// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';
import '../../widgets/loading.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import 'try_again.dart';

class ResetConfirmation extends StatefulWidget {
  final Function(bool) isSuccess;
  final String noIOM;
  final String server;
  final bool isIOM;

  const ResetConfirmation({
    super.key,
    required this.isSuccess,
    required this.noIOM,
    required this.server,
    required this.isIOM,
  });

  @override
  State<ResetConfirmation> createState() => _ResetConfirmationState();
}

class _ResetConfirmationState extends State<ResetConfirmation> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  String status = 'Loading';

  Future<void> resetIOM() async {
    try {
      setState(() {
        loading = true;
        status = 'Resetting IOM';
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ResetIOM xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.noIOM}</NoIOM>' +
          '<server>${widget.server}</server>' +
          '</ResetIOM>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_ResetIOM),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/ResetIOM',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('ResetIOMResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('ResetIOMResult').first.text;

        if (statusData == "GAGAL") {
          Future.delayed(const Duration(seconds: 1), () async {
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
              duration: const Duration(seconds: 1),
              configuration: const IconConfiguration(
                icon: Icons.done,
                color: Colors.green,
              ),
              title: "Success Reset IOM",
              backgroundColor: Colors.grey[300],
            );

            widget.isSuccess(true);
            Navigator.of(context).pop();
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
          subtitle: "Failed Reset IOM",
          backgroundColor: Colors.grey[300],
        );

        Future.delayed(const Duration(seconds: 1), () async {
          if (mounted) {
            setState(() {
              loading = false;
            });
          }

          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return TryAgain(
                  submit: (value) async {
                    if (value) {
                      await resetIOM();
                    }
                  },
                );
              });
        });
      }
    } catch (e) {
      debugPrint('$e');
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        configuration:
            const IconConfiguration(icon: Icons.error, color: Colors.red),
        title: "Failed Reset IOM",
        subtitle: "$e",
        subtitleOptions: StatusAlertTextConfiguration(
          overflow: TextOverflow.visible,
        ),
        backgroundColor: Colors.grey[300],
      );

      Future.delayed(const Duration(seconds: 1), () async {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }

        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await resetIOM();
                  }
                },
              );
            });
      });
    }
  }

  Future<void> resetApproval() async {
    try {
      setState(() {
        loading = true;
        status = 'Resetting Approval';
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ResetApproval xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.noIOM}</NoIOM>' +
          '<server>${widget.server}</server>' +
          '</ResetApproval>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_ResetApproval),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/ResetApproval',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('ResetApprovalResult').isEmpty
                ? 'GAGAL'
                : document.findAllElements('ResetApprovalResult').first.text;

        if (statusData == "GAGAL") {
          Future.delayed(const Duration(seconds: 1), () async {
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
              duration: const Duration(seconds: 1),
              configuration: const IconConfiguration(
                icon: Icons.done,
                color: Colors.green,
              ),
              title: "Success Reset Approval",
              backgroundColor: Colors.grey[300],
            );

            widget.isSuccess(true);
            Navigator.of(context).pop();
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
          subtitle: "Failed Reset Approval",
          backgroundColor: Colors.grey[300],
        );

        Future.delayed(const Duration(seconds: 1), () async {
          if (mounted) {
            setState(() {
              loading = false;
            });
          }

          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return TryAgain(
                  submit: (value) async {
                    if (value) {
                      await resetApproval();
                    }
                  },
                );
              });
        });
      }
    } catch (e) {
      debugPrint('$e');
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        configuration:
            const IconConfiguration(icon: Icons.error, color: Colors.red),
        title: "Failed Reset Approval",
        subtitle: "$e",
        subtitleOptions: StatusAlertTextConfiguration(
          overflow: TextOverflow.visible,
        ),
        backgroundColor: Colors.grey[300],
      );

      Future.delayed(const Duration(seconds: 1), () async {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }

        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await resetApproval();
                  }
                },
              );
            });
      });
    }
  }

  @override
  void initState() {
    super.initState();
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
                    Text(widget.isIOM
                        ? 'Do you want to reset this IOM Number?'
                        : 'Do you want to undo the approval of this IOM Number?'),
                    SizedBox(height: size.height * 0.01),
                    const Text('IOM Number:'),
                    Text(
                      widget.noIOM,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).textScaler.scale(15),
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

                        if (widget.isIOM) {
                          await resetIOM();
                        } else {
                          await resetApproval();
                        }
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
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          LoadingWidget(
            isLoading: loading,
            title: status,
          ),
        ],
      ),
    );
  }
}
