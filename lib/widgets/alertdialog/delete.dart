// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iomweb/backend/constants.dart';
import 'package:iomweb/widgets/alertdialog/log_error.dart';
import 'package:iomweb/widgets/alertdialog/try_again.dart';
import 'package:iomweb/widgets/loading.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;

class Delete extends StatefulWidget {
  final Function(bool) isUpdate;
  final List data;
  final int menu;
  final String server;

  const Delete({
    super.key,
    required this.isUpdate,
    required this.data,
    required this.menu,
    required this.server,
  });

  @override
  State<Delete> createState() => _DeleteState();
}

class _DeleteState extends State<Delete> {
  bool loading = false;

  Future<void> deletePaymentMstAgreement() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<DeletePaymentMstAgreement xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.data.last['noAgreement']}</NoIOM>' +
          '<Item>${widget.data.last['item']}</Item>' +
          '<server>${widget.server}</server>' +
          '</DeletePaymentMstAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_DeletePayment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/DeletePaymentMstAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final statusData = document.findElements('DeletePaymentResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('DeletePaymentResult').first.innerText;

        if (statusData == 'GAGAL') {
          Future.delayed(const Duration(seconds: 1), () async {
            if (mounted) {
              return StatusAlert.show(context,
                  duration: const Duration(seconds: 1),
                  configuration: const IconConfiguration(
                      icon: Icons.error, color: Colors.red),
                  title: 'Failed',
                  backgroundColor: Colors.grey[300]);
            }
          });
        } else {
          //   Future.delayed(const Duration(seconds: 1), () async {
          //   await deleteAtt();
          // });
        }
      } else {
        if (mounted) {
          await showDialog(
              context: context,
              builder: (BuildContext context) {
                return LogError(
                    statusCode: response.statusCode.toString(),
                    fail: 'Failed to Delete Data',
                    error: response.body.toString());
              });

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return LogError(
                  statusCode: '',
                  fail: 'Failed To Delete Payment',
                  error: e.toString());
            });
      }
    }
  }

  Future<void> deletePaymentIom() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<DeletePayment xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.data.last['noIOM']}</NoIOM>' +
          '<Item>${widget.data.last['item']}</Item>' +
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
        final statusData = document.findElements('DeletePaymentResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('DeletePaymentResult').first.innerText;

        if (statusData == 'GAGAL') {
          Future.delayed(const Duration(seconds: 1), () async {
            if (mounted) {
              return StatusAlert.show(context,
                  duration: const Duration(seconds: 1),
                  configuration: const IconConfiguration(
                      icon: Icons.error, color: Colors.red),
                  title: 'Failed',
                  backgroundColor: Colors.grey[300]);
            }
          });
        } else {
            Future.delayed(const Duration(seconds: 1), () async {
            await deleteAttachmentIom();
          });
        }
      } else {
        if (mounted) {
          await showDialog(
              context: context,
              builder: (BuildContext context) {
                return LogError(
                    statusCode: response.statusCode.toString(),
                    fail: 'Failed to Delete Data',
                    error: response.body.toString());
              });

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return LogError(
                  statusCode: '',
                  fail: 'Failed To Delete Payment',
                  error: e.toString());
            });
      }
    }
  }

  Future<void> deleteAttachmentIom() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<DeleteAttach xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.data.last['noIOM']}</NoIOM>' +
          '<Item>${widget.data.last['item']}</Item>' +
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
        final statusData = document.findAllElements('DeletePaymentResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('DeletePaymentResult');
        if (statusData == 'GAGAL') {
          Future.delayed( const Duration(seconds: 1), () async {
            StatusAlert.show(context,
                title: 'Failed',
                configuration: const
                    IconConfiguration(icon: Icons.done, color: Colors.green),
                backgroundColor: Colors.grey[200]);
            setState(() {
              loading = false;
            });
          });
        } else {
          Future.delayed(const Duration(seconds: 1), () async {
            StatusAlert.show(
              context,
              title: 'Success',
              configuration:const
                  IconConfiguration(icon: Icons.done, color: Colors.green),
              backgroundColor: Colors.grey[200],
            );

            setState(() {
              loading = false;
            });

            Navigator.of(context).pop();

            widget.isUpdate(true);
          });
        }
      } else {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          title: '${response.statusCode}',
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          subtitle: 'Failed to delete attachment',
        );

        Future.delayed(const Duration(seconds: 1), () async {
          setState(() {
            loading = false;
          });
        });

        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return TryAgain(submit: (value) async {
                await deleteAttachmentIom();
              });
            });
      }
    } catch (e) {
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 1),
        title: '',
        configuration: const IconConfiguration(icon: Icons.error, color: Colors.red),
        subtitle: '$e',
      );

      Future.delayed(const Duration(seconds: 1), () async {
        setState(() {
          loading = false;
        });
      });

      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return TryAgain(submit: (value) async {
              await deleteAttachmentIom();
            });
          });
    }
  }

  Future<void> deleteAttachmentMstAgreement() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<DeleteAttachMstAgreement xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.data.last['noAgreement']}</NoIOM>' +
          '<Item>${widget.data.last['item']}</Item>' +
          '<server>${widget.server}</server>' +
          '</DeleteAttach>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_DeleteAttach),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/DeleteAttachMstAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final statusData = document.findAllElements('DeletePaymentResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('DeletePaymentResult');
        if (statusData == 'GAGAL') {
          Future.delayed( const Duration(seconds: 1), () async {
            StatusAlert.show(context,
                title: 'Failed',
                configuration: const
                    IconConfiguration(icon: Icons.done, color: Colors.green),
                backgroundColor: Colors.grey[200]);
            setState(() {
              loading = false;
            });
          });
        } else {
          Future.delayed(const Duration(seconds: 1), () async {
            StatusAlert.show(
              context,
              title: 'Success',
              configuration:const
                  IconConfiguration(icon: Icons.done, color: Colors.green),
              backgroundColor: Colors.grey[200],
            );

            setState(() {
              loading = false;
            });

            Navigator.of(context).pop();

            widget.isUpdate(true);
          });
        }
      } else {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          title: '${response.statusCode}',
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          subtitle: 'Failed to delete attachment',
        );

        Future.delayed(const Duration(seconds: 1), () async {
          setState(() {
            loading = false;
          });
        });

        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return TryAgain(submit: (value) async {
                await deleteAttachmentMstAgreement();
              });
            });
      }
    } catch (e) {
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 1),
        title: '',
        configuration: const IconConfiguration(icon: Icons.error, color: Colors.red),
        subtitle: '$e',
      );

      Future.delayed(const Duration(seconds: 1), () async {
        setState(() {
          loading = false;
        });
      });

      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return TryAgain(submit: (value) async {
              await deleteAttachmentIom();
            });
          });
    }
  }

  Future<void> deletePaymentAgreement() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<DeletePaymentAgreement xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.data.last['noAgreementDetail']}</NoAgreementDetail>' +
          '<Item>${widget.data.last['item']}</Item>' +
          '<server>${widget.server}</server>' +
          '</DeletePaymentAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_DeletePayment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/DeletePaymentAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final statusData = document.findElements('DeletePaymentResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('DeletePaymentResult').first.innerText;

        if (statusData == 'GAGAL') {
          Future.delayed(const Duration(seconds: 1), () async {
            if (mounted) {
              return StatusAlert.show(context,
                  duration: const Duration(seconds: 1),
                  configuration: const IconConfiguration(
                      icon: Icons.error, color: Colors.red),
                  title: 'Failed',
                  backgroundColor: Colors.grey[300]);
            }
          });
        } else {
            Future.delayed(const Duration(seconds: 1), () async {
            await deleteAttachmentIom();
          });
        }
      } else {
        if (mounted) {
          await showDialog(
              context: context,
              builder: (BuildContext context) {
                return LogError(
                    statusCode: response.statusCode.toString(),
                    fail: 'Failed to Delete Data',
                    error: response.body.toString());
              });

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return LogError(
                  statusCode: '',
                  fail: 'Failed To Delete Payment',
                  error: e.toString());
            });
      }
    }
  }

 Future<void> deleteAttachmentAgreement() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<DeleteAttachAgreement xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.data.last['noAgreementDetail']}</NoAgreementDetail>' +
          '<Item>${widget.data.last['item']}</Item>' +
          '<server>${widget.server}</server>' +
          '</DeleteAttachAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_DeleteAttach),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/DeleteAttachAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final statusData = document.findAllElements('DeletePaymentResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('DeletePaymentResult');
        if (statusData == 'GAGAL') {
          Future.delayed( const Duration(seconds: 1), () async {
            StatusAlert.show(context,
                title: 'Failed',
                configuration: const
                    IconConfiguration(icon: Icons.done, color: Colors.green),
                backgroundColor: Colors.grey[200]);
            setState(() {
              loading = false;
            });
          });
        } else {
          Future.delayed(const Duration(seconds: 1), () async {
            StatusAlert.show(
              context,
              title: 'Success',
              configuration:const
                  IconConfiguration(icon: Icons.done, color: Colors.green),
              backgroundColor: Colors.grey[200],
            );

            setState(() {
              loading = false;
            });

            Navigator.of(context).pop();

            widget.isUpdate(true);
          });
        }
      } else {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          title: '${response.statusCode}',
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          subtitle: 'Failed to delete attachment',
        );

        Future.delayed(const Duration(seconds: 1), () async {
          setState(() {
            loading = false;
          });
        });

        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return TryAgain(submit: (value) async {
                await deleteAttachmentIom();
              });
            });
      }
    } catch (e) {
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 1),
        title: '',
        configuration: const IconConfiguration(icon: Icons.error, color: Colors.red),
        subtitle: '$e',
      );

      Future.delayed(const Duration(seconds: 1), () async {
        setState(() {
          loading = false;
        });
      });

      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return TryAgain(submit: (value) async {
              await deleteAttachmentAgreement();
            });
          });
    }
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
                children: [
                  RichText(
                    text: TextSpan(
                        text: 'Do you really want to',
                        style: const TextStyle(color: Colors.black),
                        children: [
                          const TextSpan(
                            text: 'DELETE',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                          TextSpan(
                              text: widget.menu == 1
                                  ? 'Item Number ${widget.data.last['No IOM']}'
                                  : widget.menu == 2
                                      ? 'Item Number ${widget.data.last['No Agreement']}'
                                      : widget.menu == 3
                                          ? 'Item Number ${widget.data.last['No AgreementDetail']}'
                                          : '')
                        ]),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () async {
                    if(widget.menu==1){
                      await deletePaymentIom();
                    }else if(widget.menu==2){
                      await deletePaymentMstAgreement();
                    }else if(widget.menu==3){
                      await deletePaymentAgreement();
                    }
                  },
                  child: Text(
                    'Yes',
                    style: TextStyle(color: loading ? null : Colors.green),
                  )),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('No'))
            ],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          LoadingWidget(isLoading: loading, title: 'loading')
        ],
      ),
    );
  }
}
