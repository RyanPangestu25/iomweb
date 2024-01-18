// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';
import '../loading.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import 'try_again.dart';

class ResetConfirmation extends StatefulWidget {
  final Function(bool) isSuccess;
  final String noIOM;
  final String server;
  final String status;

  const ResetConfirmation({
    super.key,
    required this.isSuccess,
    required this.noIOM,
    required this.server,
    required this.status,
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
            if (widget.status.toUpperCase().contains('VERIFIED')) {
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
            } else {
              await delAPB();
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

  Future<void> delAPB() async {
    try {
      setState(() {
        loading = true;
        status = 'Deletting APB';
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<DelAPB xmlns="http://tempuri.org/">' +
          '<IOMNumber>${widget.noIOM}</IOMNumber>' +
          '</DelAPB>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_DelAPB),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/DelAPB',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('DelAPBResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('DelAPBResult').first.text;

        if (statusData == "GAGAL") {
          Future.delayed(const Duration(seconds: 1), () async {
            await resetCharter();
          });
        } else {
          Future.delayed(const Duration(seconds: 1), () async {
            await delCharter();
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
          subtitle: "Failed Delete APB",
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
                      await delAPB();
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
        title: "Failed Delete APB",
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
                    await delAPB();
                  }
                },
              );
            });
      });
    }
  }

  Future<void> delCharter() async {
    try {
      setState(() {
        loading = true;
        status = 'Deletting Charter';
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<DelCharter xmlns="http://tempuri.org/">' +
          '<IOMNumber>${widget.noIOM}</IOMNumber>' +
          '</DelCharter>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_DelCharter),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/DelCharter',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('DelCharterResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('DelCharterResult').first.text;

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
          subtitle: "Failed Delete Charter",
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
                      await delCharter();
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
        title: "Failed Delete Charter",
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
                    await delCharter();
                  }
                },
              );
            });
      });
    }
  }

  Future<void> resetCharter() async {
    try {
      setState(() {
        loading = true;
        status = 'Resetting Charter';
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ResetCharter xmlns="http://tempuri.org/">' +
          '<IOMNumber>${widget.noIOM}</IOMNumber>' +
          '</ResetCharter>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_ResetCharter),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/ResetCharter',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('ResetCharterResult').isEmpty
                ? 'GAGAL'
                : document.findAllElements('ResetCharterResult').first.text;

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
          subtitle: "Failed Reset Charter",
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
                      await resetCharter();
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
        title: "Failed Reset Charter",
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
                    await resetCharter();
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
                    const Text('Do you really want to reset this IOM Number?'),
                    const Text('IOM Number:'),
                    Text(widget.noIOM),
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

                        await delAPB();
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
          LoadingWidget(
            isLoading: loading,
            title: status,
          ),
        ],
      ),
    );
  }
}
