// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iomweb/backend/constants.dart';
import 'package:iomweb/screens/mstagreement/view_mstagreement.dart';
import 'package:iomweb/widgets/alertdialog/log_error.dart';
import 'package:iomweb/widgets/alertdialog/try_again.dart';
import 'package:iomweb/widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;

class ApprovalMaste extends StatefulWidget {
  final String text;
  final List data;
  const ApprovalMaste({
    super.key,
    required this.text,
    required this.data
    });

  @override
  State<ApprovalMaste> createState() => _ApprovalMasteState();
}

class _ApprovalMasteState extends State<ApprovalMaste> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  String status = 'Loading';
  String userName = '';
  String level = '';
  List<int> noAPBEmbark = [];
  List<int> noAPBAMaster = [];


Future<void> approvalMaster() async {
    try{
      setState(() {
        loading = true;
      });

    
    String status = widget.text == 'APPROVE' ? 'APPROVED' : 'REJECTED';
    final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
        '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
        '<soap:Body>' +
        '<ApprovalMstAgreement xmlns="http://tempuri.org/">' +
        '<NoAgreement>${widget.data.last['noAgreement']}</NoAgreement>' +
        '<Status_konfirmasi_direksi>$status</Status_konfirmasi_direksi>' +
        '<server>${widget.data.last['server']}</server>' +
        '<ConfirmedBy>$userName</ConfirmedBy>' +
        '</ApprovalMstAgreement>' +
        '</soap:Body>' +
        '</soap:Envelope>';

    final response = await http.post(Uri.parse(url_ApprovalMaster),
        headers: <String, String>{
          "Access-Control-Allow-Origin": "*",
          'SOAPAction': 'http://tempuri.org/ApprovalAgreement',
          'Access-Control-Allow-Credentials': 'true',
          'Content-type': 'text/xml; charset=utf-8'
        },
        body: soapEnvelope);

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final statusData = document.findAllElements('ApprovalMstAgreementResult').isEmpty
          ? 'GAGAL'
          : document.findAllElements('ApprovalMstAgreementResult');
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
        await sendLogMaster();
        Future.delayed(const Duration(seconds: 1), () async {
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
                return const ViewMstagreement(title: 'Master Verification');
              }));
            } else if (level == '10') {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return const ViewMstagreement(title: 'Master Approval');
              }));
            } else {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return const ViewMstagreement(title: 'View Master Agreement');
              }));
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

Future<void> sendLogMaster() async {
    try {
      setState(() {
        loading = true;
      });

      String status = widget.text == 'APPROVE' ? 'APPROVED' : 'REJECTED';

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<SendLogMstAgreement xmlns="http://tempuri.org/">' +
          '<NoAgreement>${widget.data.last['noAgreement']}</NoAgreement>' +
          '<UserInsert>$userName</UserInsert>' +
          '<Status>$status</Status>' +
          '<Device>Android</Device>' +
          '<server>${widget.data.last['server']}</server>' +
          '</SendLogMstAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_SendlogMaster),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/SendLogMstAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('SendLogMstAgreementResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('SendLogMstAgreementResult').first.innerText;

        if (statusData == "GAGAL") {
          Future.delayed(const Duration(seconds: 1), () async {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 1),
              configuration:
                  const IconConfiguration(icon: Icons.error, color: Colors.red),
              title: "Failed SendLog",
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
                        await sendLogMaster();
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
                      await sendLogMaster();
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
                    await sendLogMaster();
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

Future<void> resetApproval() async {
    try {
      setState(() {
        loading = true;
        status = 'Resetting Approval';
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ResetApprovalMstAgreement xmlns="http://tempuri.org/">' +
          '<NoAgreement>${widget.data.last['noAgreement']}</NoAgreement>' +
          '<server>${widget.data.last['server']}</server>' +
          '</ResetApprovalMstAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_ResetApprovalMstAgreement),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/ResetApprovalMstAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('ResetApprovalMstAgreementResult').isEmpty
                ? 'No Data'
                : document.findAllElements('ResetApprovalMstAgreementResult').first.innerText;

        if (statusData == 'GAGAL') {
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 1),
            configuration:
                const IconConfiguration(icon: Icons.error, color: Colors.red),
            title: 'Failed Reset Approval Master',
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
            title: 'Success Reset Approval Master',
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
                  return const ViewMstagreement(
                    title: 'Master Verification',
                  );
                },
              ));
            } else if (level == '10') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) {
                  return const ViewMstagreement(
                    title: 'Master Approval',
                  );
                },
              ));
            } else {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) {
                  return const ViewMstagreement(
                    title: 'View Master Agreement',
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
                  fail: 'Failed Reset Master Approval',
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

                    await approvalMaster();

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