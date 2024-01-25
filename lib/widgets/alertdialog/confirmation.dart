// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';
import '../../widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import '../../screens/view_iom.dart';
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
          debugPrint('Success Send Log');
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
          subtitle: "Failed Send Log",
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
                      await sendLog();
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
        title: "Failed Send Log",
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
                    await sendLog();
                  }
                },
              );
            });
      });
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
          debugPrint('Error: ${response.statusCode}');
          debugPrint('Desc: ${response.body}');
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 1),
            configuration:
                const IconConfiguration(icon: Icons.error, color: Colors.red),
            title: "${response.statusCode}",
            subtitle: "Failed Check APB Embark",
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
                        await cekAPBEmbark();
                      }
                    },
                  );
                });
          });

          break;
        }
      }

      Future.delayed(const Duration(seconds: 1), () async {
        if (noAPBEmbark.isEmpty) {
          await updateAPB();
        } else {
          await createAPB();
        }
      });
    } catch (e) {
      debugPrint('$e');
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        configuration:
            const IconConfiguration(icon: Icons.error, color: Colors.red),
        title: "Failed Check APB Embark",
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
                    await cekAPBEmbark();
                  }
                },
              );
            });
      });
    }
  }

  Future<void> createAPB() async {
    List<int> noAPBFailed = [];

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
          debugPrint('Error: ${response.statusCode}');
          debugPrint('Desc: ${response.body}');
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 1),
            configuration:
                const IconConfiguration(icon: Icons.error, color: Colors.red),
            title: "${response.statusCode}",
            subtitle: "Failed Create APB",
            backgroundColor: Colors.grey[300],
          );

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
        });

        if (noAPBFailed.isEmpty) {
          await updateAPB();
        } else {
          setState(() {
            noAPBEmbark = noAPBFailed;
          });
          await createAPB();
        }
      });
    } catch (e) {
      debugPrint('$e');
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        configuration:
            const IconConfiguration(icon: Icons.error, color: Colors.red),
        title: "Failed Create APB",
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
                    await createAPB();
                  }
                },
              );
            });
      });
    }
  }

  Future<void> updateAPB() async {
    try {
      setState(() {
        loading = true;
        status = 'Updating APB IOM';
      });

      double amount =
          (double.parse(widget.iom.last['biaya'].replaceAll(',', '.')) /
                  widget.iomItem.length)
              .roundToDouble();

      debugPrint('$amount');

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
                        await updateAPB();
                      }
                    },
                  );
                });
          });
        } else {
          Future.delayed(const Duration(seconds: 1), () async {
            await sendtoIssued();
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
          subtitle: "Failed Update Charter",
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
                      await updateAPB();
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
        title: "Failed Update Charter",
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
                    await updateAPB();
                  }
                },
              );
            });
      });
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

          debugPrint(statusData);

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
          debugPrint('Error: ${response.statusCode}');
          debugPrint('Desc: ${response.body}');
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 1),
            configuration:
                const IconConfiguration(icon: Icons.error, color: Colors.red),
            title: "${response.statusCode}",
            subtitle: "Failed SendToIssued",
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
                        await sendtoIssued();
                      }
                    },
                  );
                });
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
        title: "Failed SendToIssued",
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
                    await sendtoIssued();
                  }
                },
              );
            });
      });
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
          LoadingWidget(
            isLoading: loading,
            title: status,
          ),
        ],
      ),
    );
  }
}
