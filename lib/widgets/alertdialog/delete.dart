// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';
import '../../widgets/loading.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import 'log_error.dart';
import 'try_again.dart';

class Delete extends StatefulWidget {
  final Function(bool) isUpdate;
  final List payment;
  final String server;

  const Delete({
    super.key,
    required this.isUpdate,
    required this.payment,
    required this.server,
  });

  @override
  State<Delete> createState() => _DeleteState();
}

class _DeleteState extends State<Delete> {
  bool loading = false;

  Future<void> deletePayment() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<DeletePayment xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.payment.last['noIOM']}</NoIOM>' +
          '<Item>${widget.payment.last['item']}</Item>' +
          '<server>${widget.server}</server>' +
          '</DeletePayment>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_DeletePayment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/DeletePayment',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('DeletePaymentResult').isEmpty
                ? 'GAGAL'
                : document.findAllElements('DeletePaymentResult').first.text;

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
            await deleteAtt();
          });
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
                  fail: 'Failed to Delete Payment',
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
                fail: 'Failed to Delete Payment',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> deleteAtt() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<DeleteAttach xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.payment.last['noIOM']}</NoIOM>' +
          '<Item>${widget.payment.last['item']}</Item>' +
          '<server>${widget.server}</server>' +
          '</DeleteAttach>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_DeleteAttach),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/DeleteAttach',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('DeleteAttachResult').isEmpty
                ? 'GAGAL'
                : document.findAllElements('DeleteAttachResult').first.text;

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

            Navigator.of(context).pop();

            widget.isUpdate(true);
          });
        }
      } else {
        //debugPrint('Error: ${response.statusCode}');
        //debugPrint('Desc: ${response.body}');

        Future.delayed(const Duration(seconds: 1), () async {
          if (mounted) {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return TryAgain(
                    submit: (value) async {
                      if (value) {
                        await deleteAtt();
                      }
                    },
                  );
                });

            await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return LogError(
                    statusCode: response.statusCode.toString(),
                    fail: 'Failed to Delete Attachment',
                    error: response.body.toString(),
                  );
                });

            setState(() {
              loading = false;
            });
          }
        });
      }
    } catch (e) {
      //debugPrint('$e');

      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await deleteAtt();
                  }
                },
              );
            });

        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Failed to Delete Attachment',
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
              Icons.info_outline,
              size: size.height * 0.1,
            ),
            iconColor: Colors.amber,
            title: const Text('CONFIRMATION'),
            content: SingleChildScrollView(
              clipBehavior: Clip.antiAlias,
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
                        const TextSpan(
                          text: 'DELETE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        TextSpan(
                          text: " item number ${widget.payment.last['item']}?",
                        ),
                      ],
                    ),
                  ),
                ],
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

                        await deletePayment();
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
            title: 'Loading',
          ),
        ],
      ),
    );
  }
}
