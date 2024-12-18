// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';
import '../../widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import '../../screens/iom/view_iom.dart';
import 'log_error.dart';
import 'try_again.dart';

class Confirmation extends StatefulWidget {
  final String text;
  final List iom;
  final List iomItem;
  final List flightDate;

  const Confirmation({
    super.key,
    required this.text,
    required this.iom,
    required this.iomItem,
    required this.flightDate,
  });

  @override
  State<Confirmation> createState() => _ConfirmationState();
}

class _ConfirmationState extends State<Confirmation> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  String userName = '';
  String level = '';
  String status = 'Loading';
  List<int> noAPBEmbark = [];
  List<int> noAPBIOM = [];

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
            ? 'GAGAL'
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
          await sendLog();

          Future.delayed(const Duration(seconds: 1), () async {
            if (status == 'APPROVED') {
              await cekAPBEmbark();
            } else {
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 2),
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
          });
        }
      } else {
        //debugprint('Error: ${response.statusCode}');
        //debugprint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Failed to ${widget.text}',
                  error: response.body.toString(),
                );
              });

          setState(() {
            loading = false;
          });

          await resetApproval();
        }
      }
    } catch (e) {
      //debugprint('$e');

      if (mounted) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Failed to ${widget.text}',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });

        await resetApproval();
      }
    }
  }

  Future<void> sendLog() async {
    try {
      setState(() {
        loading = true;
      });

      String status = widget.text == 'APPROVE' ? 'APPROVED' : 'REJECTED';

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<SendLog xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<UserInsert>$userName</UserInsert>' +
          '<Status>$status</Status>' +
          '<server>${widget.iom.last['server']}</server>' +
          '<Device>WEB</Device>' +
          '</SendLog>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_SendLog),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/SendLog',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('SendLogResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('SendLogResult').first.text;

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

            await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return TryAgain(
                    submit: (value) async {
                      if (value) {
                        await sendLog();
                      }
                    },
                  );
                });
          });
        } else {
          //debugprint('Success Send Log');
        }
      } else {
        //debugprint('Error: ${response.statusCode}');
        //debugprint('Desc: ${response.body}');

        if (mounted) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return TryAgain(
                  submit: (value) async {
                    if (value) {
                      await sendLog();
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
                  fail: 'Failed Send Log',
                  error: response.body.toString(),
                );
              });

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      //debugprint('$e');

      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await sendLog();
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
                fail: 'Failed Send Log',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> cekAPBEmbark() async {
    try {
      setState(() {
        loading = true;
        status = 'Checking APB Embark';
      });

      for (int index = 0; index < widget.iomItem.length; index++) {
        final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
            '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soap:Body>' +
            '<CekAPBEmbark xmlns="http://tempuri.org/">' +
            '<FlightNumber>${widget.iomItem[index]['flightNumber']}</FlightNumber>' +
            '<FlightDate>${DateTime.parse(widget.iomItem[index]['tanggal']).toLocal().toIso8601String()}</FlightDate>' +
            '<Airlines>${widget.iomItem[index]['airlineCode']}</Airlines>' +
            '<Routes>${widget.iomItem[index]['rute']}</Routes>' +
            '</CekAPBEmbark>' +
            '</soap:Body>' +
            '</soap:Envelope>';

        final response = await http.post(Uri.parse(url_CekAPBEmbark),
            headers: <String, String>{
              "Access-Control-Allow-Origin": "*",
              'SOAPAction': 'http://tempuri.org/CekAPBEmbark',
              'Access-Control-Allow-Credentials': 'true',
              'Content-type': 'text/xml; charset=utf-8'
            },
            body: soapEnvelope);

        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);

          final listResultAll = document.findAllElements('Table');

          for (final listResult in listResultAll) {
            final statusData = listResult.findAllElements('StatusData').isEmpty
                ? 'No Data'
                : listResult.findAllElements('StatusData').first.text;

            if (statusData == "GAGAL") {
              if (!noAPBEmbark.contains(index)) {
                noAPBEmbark.add(index);
              }
            }
          }
        } else {
          //debugprint('Error: ${response.statusCode}');
          //debugprint('Desc: ${response.body}');

          if (mounted) {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return TryAgain(
                    submit: (value) async {
                      if (value) {
                        await cekAPBEmbark();
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
                    fail: 'Failed Check APB Embark',
                    error: response.body.toString(),
                  );
                });

            setState(() {
              loading = false;
            });
          }

          break;
        }
      }

      Future.delayed(const Duration(seconds: 1), () async {
        if (noAPBEmbark.isEmpty) {
          // await updateAPB();
          await cekAPBIOM();
        } else {
          await createAPB();
        }
      });
    } catch (e) {
      //debugprint('$e');

      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await cekAPBEmbark();
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
                fail: 'Failed Check APB Embark',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> cekAPBIOM() async {
    try {
      setState(() {
        loading = true;
        status = 'Checking APB IOM';
      });

      for (int index = 0; index < widget.iomItem.length; index++) {
        final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
            '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soap:Body>' +
            '<CekAPBIOM xmlns="http://tempuri.org/">' +
            '<FlightNumber>${widget.iomItem[index]['flightNumber']}</FlightNumber>' +
            '<FlightDate>${DateTime.parse(widget.iomItem[index]['tanggal']).toLocal().toIso8601String()}</FlightDate>' +
            '<Airlines>${widget.iomItem[index]['airlineCode']}</Airlines>' +
            '<Routes>${widget.iomItem[index]['rute']}</Routes>' +
            '</CekAPBIOM>' +
            '</soap:Body>' +
            '</soap:Envelope>';

        final response = await http.post(Uri.parse(url_CekAPBIOM),
            headers: <String, String>{
              "Access-Control-Allow-Origin": "*",
              'SOAPAction': 'http://tempuri.org/CekAPBIOM',
              'Access-Control-Allow-Credentials': 'true',
              'Content-type': 'text/xml; charset=utf-8'
            },
            body: soapEnvelope);

        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);
          final listResultAll = document.findAllElements('Table');

          for (final listResult in listResultAll) {
            final statusData = listResult.findAllElements('StatusData').isEmpty
                ? 'No Data'
                : listResult.findAllElements('StatusData').first.text;

            if (statusData == "GAGAL") {
              if (!noAPBIOM.contains(index)) {
                noAPBIOM.add(index);
              }
            }
          }
        } else {
          //debugprint('Error: ${response.statusCode}');
          //debugprint('Desc: ${response.body}');

          if (mounted) {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return TryAgain(
                    submit: (value) async {
                      if (value) {
                        await cekAPBIOM();
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
                    fail: 'Failed Check APB IOM',
                    error: response.body.toString(),
                  );
                });

            setState(() {
              loading = false;
            });
          }

          break;
        }
      }

      Future.delayed(const Duration(seconds: 1), () async {
        if (noAPBIOM.isEmpty) {
          await updateAPB();
        } else {
          await createAPBIOM();
        }
      });
    } catch (e) {
      //debugprint('$e');

      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await cekAPBIOM();
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
                fail: 'Failed Check APB IOM',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> createAPB() async {
    bool isLoop = false;
    List<int> noAPBFailed = [];
    int loop = 0;

    try {
      setState(() {
        loading = true;
        status = 'Creating APB';
      });

      for (int index = 0; index < noAPBEmbark.length; index++) {
        final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
            '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soap:Body>' +
            '<CreateAPB xmlns="http://tempuri.org/">' +
            '<Airlines>${widget.iomItem[noAPBEmbark[index]]['airlineCode']}</Airlines>' +
            '<FlightDate>${DateTime.parse(widget.iomItem[noAPBEmbark[index]]['tanggal']).toLocal().toIso8601String()}</FlightDate>' +
            '<FlightNumber>${widget.iomItem[noAPBEmbark[index]]['flightNumber']}</FlightNumber>' +
            '<Routes>${widget.iomItem[noAPBEmbark[index]]['rute']}</Routes>' +
            '<District>${widget.iomItem[noAPBEmbark[index]]['rute'].toString().substring(0, 3)}</District>' +
            '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
            '<server>${widget.iom.last['server']}</server>' +
            '</CreateAPB>' +
            '</soap:Body>' +
            '</soap:Envelope>';

        final response = await http.post(Uri.parse(url_CreateAPB),
            headers: <String, String>{
              "Access-Control-Allow-Origin": "*",
              'SOAPAction': 'http://tempuri.org/CreateAPB',
              'Access-Control-Allow-Credentials': 'true',
              'Content-type': 'text/xml; charset=utf-8'
            },
            body: soapEnvelope);

        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);

          final statusData = document.findAllElements('CreateAPBResult').isEmpty
              ? 'No Data'
              : document.findAllElements('CreateAPBResult').first.text;

          if (statusData == "GAGAL") {
            if (!noAPBFailed.contains(index)) {
              noAPBFailed.add(index);
            }
          }
        } else {
          //debugprint('Error: ${response.statusCode}');
          //debugprint('Desc: ${response.body}');

          if (loop == 0 && !isLoop) {
            setState(() {
              isLoop = true;
            });

            StatusAlert.show(
              context,
              dismissOnBackgroundTap: true,
              duration: const Duration(seconds: 3),
              configuration:
                  const IconConfiguration(icon: Icons.error, color: Colors.red),
              title: "${response.statusCode}",
              subtitle:
                  "Failed Create APB, Please wait while we are trying again",
              subtitleOptions:
                  StatusAlertTextConfiguration(overflow: TextOverflow.visible),
              backgroundColor: Colors.grey[300],
            );
          } else if (loop == 2 && isLoop) {
            setState(() {
              isLoop = false;
            });

            await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return LogError(
                    statusCode: response.statusCode.toString(),
                    fail: 'Failed Create APB',
                    error: response.body.toString(),
                  );
                });
          }

          Future.delayed(const Duration(seconds: 1), () async {
            if (!noAPBFailed.contains(index)) {
              noAPBFailed.add(index);
            }
          });
        }
      }

      Future.delayed(const Duration(seconds: 1), () async {
        setState(() {
          noAPBEmbark.clear();
          loop += 1;
        });

        if (noAPBFailed.isEmpty) {
          // await updateAPB();
          await cekAPBIOM();
        } else {
          if (loop < 2) {
            setState(() {
              noAPBEmbark = noAPBFailed;
            });

            await createAPB();
          } else {
            await resetApproval();
          }
        }
      });
    } catch (e) {
      //debugprint('$e');

      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await createAPB();
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
                fail: 'Failed Create APB',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> createAPBIOM() async {
    bool isLoop = false;
    List<int> noAPBFailed = [];
    int loop = 0;

    try {
      setState(() {
        loading = true;
        status = 'Creating APB IOM';
      });

      for (int index = 0; index < noAPBIOM.length; index++) {
        final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
            '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soap:Body>' +
            '<CreateAPBIOM xmlns="http://tempuri.org/">' +
            '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
            '<FlightNumber>${widget.iomItem[noAPBIOM[index]]['flightNumber']}</FlightNumber>' +
            '<FlightDate>${DateTime.parse(widget.iomItem[noAPBIOM[index]]['tanggal']).toLocal().toIso8601String()}</FlightDate>' +
            '<Airlines>${widget.iomItem[noAPBIOM[index]]['airlineCode']}</Airlines>' +
            '<Routes>${widget.iomItem[noAPBIOM[index]]['rute']}</Routes>' +
            '<server>${widget.iom.last['server']}</server>' +
            '</CreateAPBIOM>' +
            '</soap:Body>' +
            '</soap:Envelope>';

        final response = await http.post(Uri.parse(url_CreateAPBIOM),
            headers: <String, String>{
              "Access-Control-Allow-Origin": "*",
              'SOAPAction': 'http://tempuri.org/CreateAPBIOM',
              'Access-Control-Allow-Credentials': 'true',
              'Content-type': 'text/xml; charset=utf-8'
            },
            body: soapEnvelope);

        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);
          final statusData =
              document.findAllElements('CreateAPBIOMResult').isEmpty
                  ? 'No Data'
                  : document.findAllElements('CreateAPBIOMResult').first.text;

          if (statusData == "GAGAL") {
            if (!noAPBFailed.contains(index)) {
              noAPBFailed.add(index);
            }
          }
        } else {
          //debugprint('Error: ${response.statusCode}');
          //debugprint('Desc: ${response.body}');

          if (loop == 0 && !isLoop) {
            setState(() {
              isLoop = true;
            });

            StatusAlert.show(
              context,
              dismissOnBackgroundTap: true,
              duration: const Duration(seconds: 3),
              configuration:
                  const IconConfiguration(icon: Icons.error, color: Colors.red),
              title: "${response.statusCode}",
              subtitle:
                  "Failed Create APB IOM, Please wait while we are trying again",
              subtitleOptions:
                  StatusAlertTextConfiguration(overflow: TextOverflow.visible),
              backgroundColor: Colors.grey[300],
            );
          } else if (loop == 2 && isLoop) {
            setState(() {
              isLoop = false;
            });

            await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return LogError(
                    statusCode: response.statusCode.toString(),
                    fail: 'Failed Create APB IOM',
                    error: response.body.toString(),
                  );
                });
          }

          Future.delayed(const Duration(seconds: 1), () async {
            if (!noAPBFailed.contains(index)) {
              noAPBFailed.add(index);
            }
          });
        }
      }

      Future.delayed(const Duration(seconds: 1), () async {
        setState(() {
          noAPBIOM.clear();
          loop += 1;
        });

        if (noAPBFailed.isEmpty) {
          await updateAPB();
        } else {
          if (loop < 2) {
            setState(() {
              noAPBIOM = noAPBFailed;
            });

            await createAPBIOM();
          } else {
            await resetApproval();
          }
        }
      });
    } catch (e) {
      //debugprint('$e');

      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await createAPBIOM();
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
                fail: 'Failed Create APB IOM',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> updateAPB() async {
    try {
      setState(() {
        loading = true;
        status = 'Updating APB IOM';
      });

      // double amount =
      //     (double.parse(widget.iom.last['biaya'].replaceAll(',', '.')) /
      //             widget.iomItem.length)
      //         .roundToDouble();

      //debugprint('$amount');

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<UpdateAPBIOM xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          // '<Amount>$amount</Amount>' +
          '<server>${widget.iom.last['server']}</server>' +
          '</UpdateAPBIOM>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_UpdateAPBIOM),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/UpdateAPBIOM',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('UpdateAPBIOMResult').isEmpty
                ? 'No Data'
                : document.findAllElements('UpdateAPBIOMResult').first.text;

        if (statusData == 'GAGAL') {
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 1),
            configuration:
                const IconConfiguration(icon: Icons.error, color: Colors.red),
            title: 'Failed Update Charter',
            backgroundColor: Colors.grey[300],
          );

          Future.delayed(const Duration(seconds: 1), () async {
            await resetApproval();
          });
        } else {
          Future.delayed(const Duration(seconds: 1), () async {
            await sendtoIssued();
          });
        }
      } else {
        //debugprint('Error: ${response.statusCode}');
        //debugprint('Desc: ${response.body}');

        if (mounted) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return TryAgain(
                  submit: (value) async {
                    if (value) {
                      await updateAPB();
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
                  fail: 'Failed Update Charter',
                  error: response.body.toString(),
                );
              });

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      //debugprint('$e');
      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await updateAPB();
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
                fail: 'Failed Update Charter',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> sendtoIssued() async {
    try {
      setState(() {
        loading = true;
        status = 'SendToIssued';
      });

      for (int index = 0; index < widget.flightDate.length; index++) {
        final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
            '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soap:Body>' +
            '<SendToIssued xmlns="http://tempuri.org/">' +
            '<PASSEKEY>9B364012-2B8D-4522-92C6-AB1B172084EC</PASSEKEY>' +
            '<IOMNUMBER>${widget.iom.last['noIOM']}</IOMNUMBER>' +
            '<AIRLINES>${widget.iomItem.last['airlineCode']}</AIRLINES>' +
            '<FLIGHTDATE>${DateTime.parse(widget.flightDate[index].toString()).toLocal().toIso8601String()}</FLIGHTDATE>' +
            '</SendToIssued>' +
            '</soap:Body>' +
            '</soap:Envelope>';

        final response = await http.post(Uri.parse(url_SendToIssued),
            headers: <String, String>{
              "Access-Control-Allow-Origin": "*",
              'SOAPAction': 'http://tempuri.org/SendToIssued',
              'Access-Control-Allow-Credentials': 'true',
              'Content-type': 'text/xml; charset=utf-8'
            },
            body: soapEnvelope);

        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);

          final statusData = document.findAllElements('_x002D_').isEmpty
              ? 'GAGAL'
              : document.findAllElements('_x002D_').first.text;

          //debugprint(statusData);

          if (statusData == "ERROR:IOM_NOT_FOUND" || statusData == 'GAGAL') {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 1),
              configuration:
                  const IconConfiguration(icon: Icons.error, color: Colors.red),
              title: 'Failed SendToIssued',
              subtitle: 'IOM NOT FOUND',
              backgroundColor: Colors.grey[300],
            );

            Future.delayed(const Duration(seconds: 1), () {
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
          } else {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 2),
              configuration: const IconConfiguration(
                icon: Icons.done,
                color: Colors.green,
              ),
              title: "Success SendToIssued",
              backgroundColor: Colors.grey[300],
            );

            Future.delayed(const Duration(seconds: 1), () async {
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
          //debugprint('Error: ${response.statusCode}');
          //debugprint('Desc: ${response.body}');

          if (mounted) {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return TryAgain(
                    submit: (value) async {
                      if (value) {
                        await sendtoIssued();
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
                    fail: 'Failed SendToIssued',
                    error: response.body.toString(),
                  );
                });

            setState(() {
              loading = false;
            });
          }
        }
      }
    } catch (e) {
      //debugprint('$e');

      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await sendtoIssued();
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
                fail: 'Failed SendToIssued',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
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
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<server>${widget.iom.last['server']}</server>' +
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
                ? 'No Data'
                : document.findAllElements('ResetApprovalResult').first.text;

        if (statusData == 'GAGAL') {
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 1),
            configuration:
                const IconConfiguration(icon: Icons.error, color: Colors.red),
            title: 'Failed Reset Approval',
            backgroundColor: Colors.grey[300],
          );

          Future.delayed(const Duration(seconds: 1), () async {
            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          });
        } else {
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 3),
            configuration: const IconConfiguration(
              icon: Icons.done,
              color: Colors.green,
            ),
            title: 'Success Reset Approval',
            backgroundColor: Colors.grey[300],
          );

          Future.delayed(const Duration(seconds: 1), () async {
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
        //debugprint('Error: ${response.statusCode}');
        //debugprint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Failed Reset Approval',
                  error: response.body.toString(),
                );
              });

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      //debugprint('$e');

      if (mounted) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Failed Reset Approval',
                error: e.toString(),
              );
            });

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
      //debugprint(userName);

      level = userLevel ?? 'No Data';
      //debugprint(level);
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
