// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iomweb/backend/constants.dart';
import 'package:iomweb/screens/agreementdetail.dart/view_agreementdetail.dart';
import 'package:iomweb/widgets/alertdialog/log_error.dart';
import 'package:iomweb/widgets/alertdialog/try_again.dart';
import 'package:iomweb/widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;

class ApprovalAgreementDetail extends StatefulWidget {
  final String text;
  final List agreementDetail;
  final List dataItem;
  final List flightDate;

  const ApprovalAgreementDetail({
    super.key,
    required this.text,
    required this.agreementDetail,
    required this.dataItem,
    required this.flightDate,
  });

  @override
  State<ApprovalAgreementDetail> createState() =>
      _ApprovalAgreementDetailState();
}

class _ApprovalAgreementDetailState extends State<ApprovalAgreementDetail> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  String status = 'Loading';
  String userName = '';
  String level = '';
  List<int> noAPBEmbark = [];
  List<int> noAPBAgreement = [];

Future<void> approvalAgreementDetail() async {
    try{
      setState(() {
        loading = true;
      });

    
    String status = widget.text == 'APPROVE' ? 'APPROVED' : 'REJECTED';
    final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
        '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
        '<soap:Body>' +
        '<ApprovalAgreement xmlns="http://tempuri.org/">' +
        '<NoAgreementDetail>${widget.agreementDetail.last['noAgreementDetail']}</NoAgreementDetail>' +
        '<Status_konfirmasi_direksi>$status</Status_konfirmasi_direksi>' +
        '<server>${widget.agreementDetail.last['server']}</server>' +
        '<ConfirmedBy>$userName</ConfirmedBy>' +
        '</ApprovalAgreement>' +
        '</soap:Body>' +
        '</soap:Envelope>';

    final response = await http.post(Uri.parse(url_ApprovalAgreement),
        headers: <String, String>{
          "Access-Control-Allow-Origin": "*",
          'SOAPAction': 'http://tempuri.org/ApprovalAgreement',
          'Access-Control-Allow-Credentials': 'true',
          'Content-type': 'text/xml; charset=utf-8'
        },
        body: soapEnvelope);

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final statusData = document.findAllElements('ApprovalAgreementResult').isEmpty
          ? 'GAGAL'
          : document.findAllElements('ApprovalAgreementResult');
      if (statusData == 'GAGAL') {
        if (mounted) {
          Future.delayed(const Duration(seconds: 1), () async {
            StatusAlert.show(context,
                duration: const Duration(seconds: 1),
                configuration:
                   const IconConfiguration(icon: Icons.error, color: Colors.red),
                title: "Failed");

            setState(() {
              loading = false;
            });
          });
        }
      } else {
        await sendLogAgreement();
        Future.delayed(const Duration(seconds: 1), () async {
          if (status == 'APPROVED') {
            await cekAPBEmbarkAgreement();
          } else {
            if (mounted) {
              StatusAlert.show(context,
                  duration: const Duration(seconds: 1),
                  configuration:
                      const IconConfiguration(icon: Icons.done, color: Colors.green),
                  title: 'Success',
                  backgroundColor: Colors.green[300]);

              setState(() {
                loading = false;
              });
            }

            if (level== '12') {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return const ViewAgreementDetail(title: 'Agreement Verification');
              }));
            } else if (level == '10') {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return const ViewAgreementDetail(title: 'Agreement Approval');
              }));
            } else {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return const ViewAgreementDetail(title: 'View Agreement Detail');
              }));
            }
          }
        });
      }
    } else {
      if(mounted){
        await showDialog(
          context: context, 
          builder: (BuildContext context){
            return LogError(
              statusCode: response.statusCode.toString(), 
              fail: 'Failed to ${widget.text}', 
              error: response.body.toString()
              );
          }
          );
          setState(() {
            loading = false;
          });

          await resetApproval();

      }

    }
    }catch (e){
      if(mounted){
        await showDialog(
          context: context, 
          builder: (BuildContext context){
            return LogError(
              statusCode: '', 
              fail: 'failed to ${widget.text}', 
              error: e.toString()
              );
          }
          );

          await resetApproval();
      }


    }
  }

Future<void> sendLogAgreement() async {
    try {
      setState(() {
        loading = true;
      });

      String status = widget.text == 'APPROVE' ? 'APPROVED' : 'REJECTED';

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<SendLogAgreement xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.agreementDetail.last['noAgreementDetail']}</NoAgreementDetail>' +
          '<UserInsert>$userName</UserInsert>' +
          '<Status>$status</Status>' +
          '<Device>Android</Device>' +
          '<server>${widget.agreementDetail.last['server']}</server>' +
          '</SendLogAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_SendLogAgreement),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/SendLogAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('SendLogAgreementResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('SendLogAgreementResult').first.text;

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
                        await sendLogAgreement();
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
                      await sendLogAgreement();
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
                    await sendLogAgreement();
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

Future<void> cekAPBEmbarkAgreement() async {
    try {
      setState(() {
        loading = true;
        status = 'Checking APB Embark';
      });

      for (int index = 0; index < widget.dataItem.length; index++) {
        final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
            '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soap:Body>' +
            '<CekAPBEmbarkAgreement xmlns="http://tempuri.org/">  ' +
            '<FlightNumber>${widget.dataItem[index]['flightNumber']}</FlightNumber>' +
            '<FlightDate>${DateTime.parse(widget.dataItem[index]['tanggal']).toLocal().toIso8601String()}</FlightDate>' +
            '<Airlines>${widget.dataItem[index]['airlineCode']}</Airlines>' +
            '<Routes>${widget.dataItem[index]['rute']}</Routes>' +
            '</CekAPBEmbarkAgreement>' +
            '</soap:Body>' +
            '</soap:Envelope>';

        final response = await http.post(Uri.parse(url_CekAPBEmbarkAgreement),
            headers: <String, String>{
              "Access-Control-Allow-Origin": "*",
              'SOAPAction': 'http://tempuri.org/CekAPBEmbarkAgreement',
              'Access-Control-Allow-Credentials': 'true',
              'Content-type': 'text/xml; charset=utf-8'
            },
            body: soapEnvelope);

        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);

          final listResultAll = document.findAllElements('Table');

          for (final listResult in listResultAll) {
            final statusData = listResult.findAllElements('CekAPBEmbarkAgreementResult').isEmpty
                ? 'No Data'
                : listResult.findAllElements('CekAPBEmbarkAgreementResult').first.text;

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
                        await cekAPBEmbarkAgreement();
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
          await cekAPBAgreement();
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
                    await cekAPBEmbarkAgreement();
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
            '<CreateAPB2 xmlns="http://tempuri.org/"> ' +
            '<Airlines>${widget.dataItem[noAPBEmbark[index]]['airlineCode']}</Airlines>' +
            '<FlightDate>${DateTime.parse(widget.dataItem[noAPBEmbark[index]]['tanggal']).toLocal().toIso8601String()}</FlightDate>' +
            '<FlightNumber>${widget.dataItem[noAPBEmbark[index]]['flightNumber']}</FlightNumber>' +
            '<Routes>${widget.dataItem[noAPBEmbark[index]]['rute']}</Routes>' +
            '<District>${widget.dataItem[noAPBEmbark[index]]['rute'].toString().substring(0, 3)}</District>' +
            '</CreateAPB2>' +
            '</soap:Body>' +
            '</soap:Envelope>';

        final response = await http.post(Uri.parse(url_CreateAPB2),
            headers: <String, String>{
              "Access-Control-Allow-Origin": "*",
              'SOAPAction': 'http://tempuri.org/CreateAPB2',
              'Access-Control-Allow-Credentials': 'true',
              'Content-type': 'text/xml; charset=utf-8'
            },
            body: soapEnvelope);

        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);

          final statusData = document.findAllElements('CreateAPB2Result').isEmpty
              ? 'No Data'
              : document.findAllElements('CreateAPB2Result').first.innerText;

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
          await cekAPBAgreement();
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

 Future<void> createAPBAgreement() async {
    bool isLoop = false;
    List<int> noAPBFailed = [];
    int loop = 0;

    try {
      setState(() {
        loading = true;
        status = 'Creating APB Agrreement';
      });

      for (int index = 0; index < noAPBAgreement.length; index++) {
        final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
            '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soap:Body>' +
            '<CreateAPBAgreement xmlns="http://tempuri.org/">' +
            '<NoAgreementDetail>${widget.agreementDetail.last['noAgreementDetail']}<NoAgreementDetail>' +
            '<FlightNumber>${widget.dataItem[noAPBAgreement[index]]['flightNumber']}</FlightNumber>' +
            '<FlightDate>${DateTime.parse(widget.dataItem[noAPBAgreement[index]]['tanggal']).toLocal().toIso8601String()}</FlightDate>' +
            '<Airlines>${widget.dataItem[noAPBAgreement[index]]['airlineCode']}</Airlines>' +
            '<Routes>${widget.dataItem[noAPBAgreement[index]]['rute']}</Routes>' +
            '<server>${widget.agreementDetail.last['server']}</server>' +
            '</CreateAPBAgreement>' +
            '</soap:Body>' +
            '</soap:Envelope>';

        final response = await http.post(Uri.parse(url_CreateAPBAgreement),
            headers: <String, String>{
              "Access-Control-Allow-Origin": "*",
              'SOAPAction': 'http://tempuri.org/CreateAPBAgreement',
              'Access-Control-Allow-Credentials': 'true',
              'Content-type': 'text/xml; charset=utf-8'
            },
            body: soapEnvelope);

        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);
          final statusData =
              document.findAllElements('CreateAPBAgreementResult').isEmpty
                  ? 'No Data'
                  : document.findAllElements('CreateAPBAgreementResult').first.innerText;

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
              duration: const Duration(seconds: 1),
              configuration:
                  const IconConfiguration(icon: Icons.error, color: Colors.red),
              title: "${response.statusCode}",
              subtitle:
                  "Failed Create APB Agreement, Please wait while we are trying again",
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
                    fail: 'Failed Create APB Agreement',
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
          noAPBAgreement.clear();
          loop += 1;
        });

        if (noAPBFailed.isEmpty) {
          await updateApBAgreement();
        } else {
          if (loop < 2) {
            setState(() {
              noAPBAgreement = noAPBFailed;
            });

            await createAPBAgreement();
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
                    await createAPBAgreement();
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
                fail: 'Failed Create APB Agreement',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

Future<void> updateApBAgreement() async {
    try {
      setState(() {
        loading = true;
        status = 'Updating APB Agreement';
      });

      // double amount =
      //     (double.parse(widget.iom.last['biaya'].replaceAll(',', '.')) /
      //             widget.iomItem.length)
      //         .roundToDouble();

      //debugprint('$amount');

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<UpdateAPBAgreement xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.agreementDetail.last['noAgreementDetail']}</NoAgreement>' +
          // '<Amount>$amount</Amount>' +
          '<server>${widget.agreementDetail.last['server']}</server>' +
          '</UpdateAPBAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_UpdateAPBAgreement),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/UpdateAPBAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('UpdateAPBAgreementResult').isEmpty
                ? 'No Data'
                : document.findAllElements('UpdateAPBAgreementResult').first.text;

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
                      await updateApBAgreement();
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
                    await updateApBAgreement();
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
            '<NoAgreementDetail>${widget.agreementDetail.last['noAgreementDetail']}</NoAgreementDetail>' +
            '<AIRLINES>${widget.dataItem.last['airlineCode']}</AIRLINES>' +
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
              : document.findAllElements('_x002D_').first.innerText;

          //debugprint(statusData);

          if (statusData == "ERROR:IOM_NOT_FOUND" || statusData == 'GAGAL') {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 1),
              configuration:
                  const IconConfiguration(icon: Icons.error, color: Colors.red),
              title: 'Failed SendToIssued',
              subtitle: 'AGREEMENT NOT FOUND',
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
                    return const ViewAgreementDetail(
                      title: 'Agreement Verification',
                    );
                  },
                ));
              } else if (level == '10') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const ViewAgreementDetail(
                      title: 'Agreement Approval',
                    );
                  },
                ));
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const ViewAgreementDetail(
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
                    return const ViewAgreementDetail(
                      title: 'Agreement Verification',
                    );
                  },
                ));
              } else if (level == '10') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const ViewAgreementDetail(
                      title: 'Agreement Approval',
                    );
                  },
                ));
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const ViewAgreementDetail(
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

Future<void> cekAPBAgreement() async {
    try {
      setState(() {
        loading = true;
        status = 'Checking APB Agreement';
      });

      for (int index = 0; index < widget.dataItem.length; index++) {
        final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
            '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soap:Body>' +
            '<CekAPBAgreement xmlns="http://tempuri.org/">' +
            '<FlightNumber>${widget.dataItem[index]['flightNumber']}</FlightNumber>' +
            '<FlightDate>${DateTime.parse(widget.dataItem[index]['tanggal']).toLocal().toIso8601String()}</FlightDate>' +
            '<Airlines>${widget.dataItem[index]['airlineCode']}</Airlines>' +
            '<Routes>${widget.dataItem[index]['rute']}</Routes>' +
            '</CekAPBAgreement>' +
            '</soap:Body>' +
            '</soap:Envelope>';

        final response = await http.post(Uri.parse(url_CekAPBAgreement),
            headers: <String, String>{
              "Access-Control-Allow-Origin": "*",
              'SOAPAction': 'http://tempuri.org/CekAPBAgreement',
              'Access-Control-Allow-Credentials': 'true',
              'Content-type': 'text/xml; charset=utf-8'
            },
            body: soapEnvelope);

        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);
          final listResultAll = document.findAllElements('Table');

          for (final listResult in listResultAll) {
            final statusData = listResult.findAllElements('CekAPBAgreementResult').isEmpty
                ? 'No Data'
                : listResult.findAllElements('CekAPBAgreementResult').first.text;

            if (statusData == "GAGAL") {
              if (!noAPBAgreement.contains(index)) {
                noAPBAgreement.add(index);
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
                        await cekAPBAgreement();
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
                    fail: 'Failed Check APB Agreement',
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
        if (noAPBAgreement.isEmpty) {
          await updateApBAgreement();
        } else {
          await createAPBAgreement();
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
                    await cekAPBAgreement();
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
                fail: 'Failed Check APB Agreement',
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
          '<ResetApprovalAgreement xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.agreementDetail.last['noAgreementDetail']}</NoAgreementDetail>' +
          '<server>${widget.agreementDetail.last['server']}</server>' +
          '</ResetApprovalAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_ResetApprovalAgreement),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/ResetApprovalAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('ResetApprovalAgreementResult').isEmpty
                ? 'No Data'
                : document.findAllElements('ResetApprovalAgreementResult').first.text;

        if (statusData == 'GAGAL') {
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 1),
            configuration:
                const IconConfiguration(icon: Icons.error, color: Colors.red),
            title: 'Failed Reset Approval Agreement',
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
            title: 'Success Reset Approval Agreement',
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
                  return const ViewAgreementDetail(
                    title: 'Agreement Verification',
                  );
                },
              ));
            } else if (level == '10') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) {
                  return const ViewAgreementDetail(
                    title: 'Agreement Approval',
                  );
                },
              ));
            } else {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) {
                  return const ViewAgreementDetail(
                    title: 'View Agreement',
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
                children: [
                  RichText(
                    text: TextSpan(
                        text: 'Do you want to',
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                              text: widget.text.toUpperCase(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.text.toUpperCase() == 'APPROVE'
                                      ? Colors.green
                                      : Colors.red)),
                          const TextSpan(text: 'this?')
                        ]),
                  )
                ],
              )),
            ),
            actions: [
              TextButton(
                  onPressed: () async{
                    loading ? null : 
                    setState(() {
                      loading = false;
                    });

                    await approvalAgreementDetail();

                  },
                  child: Text(
                    'Yes',
                    style: TextStyle(
                      color: loading ? null : Colors.green,
                    ),
                  )),
              TextButton(
                  onPressed: () {},
                  child: Text(
                    'No',
                    style: TextStyle(color: loading ? null : Colors.red),
                  ))
            ],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          LoadingWidget(isLoading: loading, title: status)
        ],
      ),
    );
  }
}
