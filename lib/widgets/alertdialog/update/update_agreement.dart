// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;
import '../../../backend/constants.dart';
import '../../loading.dart';
import '../log_error.dart';
import '../try_again.dart';

class EditAgreementDetail extends StatefulWidget {
  final Function(bool) isUpdate;
  final List editItem;
  final String server;

  const EditAgreementDetail({
    super.key,
    required this.isUpdate,
    required this.editItem,
    required this.server,
  });

  @override
  State<EditAgreementDetail> createState() => _EditAgreementDetailState();
}

class _EditAgreementDetailState extends State<EditAgreementDetail> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool isClick = false;
  bool isBalance = false;
  bool isNew = false;
  bool isBank = false;
  bool isCurr = false;
  Uint8List? _image;
  String titleFile = "No File Choosen";
  String fileName = '';
  String fileExt = '';
  String userName = '';
  String level = '';
  List attFile = [];
  List<String> listNamaBank = [];
  ValueNotifier<List<String>> filteredBank = ValueNotifier([]);
  List<String> listCurr = [];
  ValueNotifier<List<String>> filteredCurr = ValueNotifier([]);
  var hasilJson = '';

  TextEditingController date = TextEditingController();
  TextEditingController namaBank = TextEditingController();
  TextEditingController bank = TextEditingController();
  TextEditingController curr = TextEditingController();
  TextEditingController amount = TextEditingController();

  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();

  DateTime selectDate = DateTime.now();
  Future pickDate() async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: selectDate,
      firstDate: DateTime(1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (newDate == null) return;
    setState(() {
      selectDate = newDate;
      date.text = DateFormat('dd-MMM-yyyy')
          .format(DateTime.parse(selectDate.toString()).toLocal());
    }); //for button SAVE
  }

  Future<void> _getFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpeg', 'jpg', 'png'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      Uint8List? filePath = file.bytes;
      String ext = file.extension!;
      setState(() {
        fileName = 'WEB';
        fileExt = ext;
        titleFile = 'File Picked';
        _image = filePath;
      });
    } else {
      //debugPrint("No File Choosen");
    }
  }

  Future<void> filterBank(String query) async {
    setState(() {
      filteredBank.value = listNamaBank.where((data) {
        return data.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> filterCurr(String query) async {
    setState(() {
      filteredCurr.value = listCurr.where((data) {
        return data.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> getBank() async {
    try {
      setState(() {
        loading = true;
      });

      const String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ListBank xmlns="http://tempuri.org/" />' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_ListBank),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/ListBank',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final listResultAll = document.findAllElements('Table');

        for (final listResult in listResultAll) {
          final statusData = listResult.findElements('StatusData').isEmpty
              ? 'No Data'
              : listResult.findElements('StatusData').first.text;

          if (statusData == "GAGAL") {
            Future.delayed(const Duration(seconds: 1), () {
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 1),
                configuration: const IconConfiguration(
                    icon: Icons.error, color: Colors.red),
                title: "No Data",
                backgroundColor: Colors.grey[300],
              );
              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            });
          } else {
            final namaBank = listResult.findElements('NamaBank').first.text;

            setState(() {
              listNamaBank.add(namaBank);
            });

            // var hasilJson = jsonEncode(listNamaBank);
            //debugPrint(hasilJson);

            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          }
        }

        listNamaBank.add('OTHER');

        setState(() {
          filteredBank.value = listNamaBank;
        });
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
                  fail: 'Error Get Bank',
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
                fail: 'Error Get Bank',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getCurr() async {
    try {
      setState(() {
        loading = true;
      });

      const String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ListCurrency xmlns="http://tempuri.org/" />' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_ListCurrency),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/ListCurrency',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final listResultAll = document.findAllElements('Table');

        for (final listResult in listResultAll) {
          final statusData = listResult.findElements('StatusData').isEmpty
              ? 'No Data'
              : listResult.findElements('StatusData').first.text;

          if (statusData == "GAGAL") {
            Future.delayed(const Duration(seconds: 1), () {
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 1),
                configuration: const IconConfiguration(
                    icon: Icons.error, color: Colors.red),
                title: "No Data",
                backgroundColor: Colors.grey[300],
              );
              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            });
          } else {
            final currCode = listResult.findElements('CurrCode').first.text;
            final currName = listResult.findElements('CurrName').first.text;

            setState(() {
              listCurr.add('$currCode - $currName');
            });

            // var hasilJson = jsonEncode(listCurr);
            //debugPrint(hasilJson);

            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          }
        }

        setState(() {
          filteredCurr.value = listCurr;
        });
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
                  fail: 'Error Get Currency',
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
                fail: 'Error Get Currency',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> updatePaymentAgreement() async {
    try {
      setState(() {
        loading = true;
      });

      String namaBankPenerima =
          namaBank.text == 'OTHER' ? bank.text : namaBank.text;

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<UpdatePaymentAgreement xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.editItem.last['noAgreementdetail']}</NoAgreementDetail>' +
          '<Item>${widget.editItem.last['item']}</Item>' +
          '<Tgl_TerimaPembayaran>${DateFormat('dd-MMM-yyyy').parse(date.text).toLocal().toIso8601String()}</Tgl_TerimaPembayaran>' +
          '<NamaBankPenerima>$namaBankPenerima</NamaBankPenerima>' +
          '<AmountPembayaran>${amount.text.replaceAll(',', '')}</AmountPembayaran>' +
          '<CurrPembayaran>${curr.text.substring(0, 3)}</CurrPembayaran>' +
          '<server>${widget.server}</server>' +
          '</UpdatePaymentAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_UpdatePaymentAgreement),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/UpdatePaymentAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('UpdatePaymentAgreementResult').isEmpty
                ? 'GAGAL'
                : document.findAllElements('UpdatePaymentAgreementResult').first.text;

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
            if (mounted) {
              setState(() {
                loading = false;
              });
            }

            if (isNew) {
              await updateAttAgreement();
            } else {
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 2),
                configuration: const IconConfiguration(
                    icon: Icons.done, color: Colors.green),
                title: "Success Update Item (${widget.editItem.last['item']})",
                backgroundColor: Colors.grey[300],
              );

              Navigator.of(context).pop();

              widget.isUpdate(true);
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
                  fail: 'Failed Verification Payment',
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
                fail: 'Failed Verification Payment',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> updateAttAgreement() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<UpdateAttachAgreement xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.editItem.last['noAgreementdetail']}</NoAgreementDetail>' +
          '<Filename>$fileName</Filename>' +
          '<PDFFile>${base64Encode(_image!)}</PDFFile>' +
          '<UploadBy>$userName</UploadBy>' +
          '<UploadDate>${DateTime.now().toLocal().toIso8601String()}</UploadDate>' +
          '<Ext>$fileExt</Ext>' +
          '<Item>${widget.editItem.last['item']}</Item>' +
          '<server>${widget.editItem.last['server']}</server>' +
          '</UpdateAttachAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_UpdateAttachmentAgreement),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/UpdateAttachAgreement',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('UpdateAttachAgreementResult').isEmpty
                ? 'GAGAL'
                : document.findAllElements('UpdateAttachAgreementResult').first.text;

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
              title: "Success Update Item (${widget.editItem.last['item']})",
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

        if (mounted) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return TryAgain(
                  submit: (value) async {
                    if (value) {
                      await updateAttAgreement();
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
                  fail: 'Failed Add Attachment',
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
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await updateAttAgreement();
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
                fail: 'Failed Add Attachment',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getAgreementAttachment() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetAgreementAttachment xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.editItem.last['noAgreementdetail']}</NoAgreementDetail>' +
          '<Item>${widget.editItem.last['item']}</Item>' +
          '<attachmentType>BUKTI TERIMA PEMBAYARAN</attachmentType>' +
          '<server>${widget.server}</server>' +
          '</GetAgreementAttachment>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetAgreementAttachment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetAgreementAttachment',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final listResultAll = document.findAllElements('Table');

        for (final listResult in listResultAll) {
          final statusData = listResult.findElements('StatusData').isEmpty
              ? 'No Data'
              : listResult.findElements('StatusData').first.text;

          if (statusData == "GAGAL") {
            Future.delayed(const Duration(seconds: 1), () {
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 1),
                configuration: const IconConfiguration(
                    icon: Icons.error, color: Colors.red),
                title: "No Data",
                backgroundColor: Colors.grey[300],
              );
              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            });
          } else {
            final noAgreementDetail = listResult.findElements('NoAgreementDetail').isEmpty
                ? 'No Data'
                : listResult.findElements('NoAgreementDetail').first.text;
            final filename = listResult.findElements('Filename').isEmpty
                ? 'No Data'
                : listResult.findElements('Filename').first.text;
            final pdfFile = listResult.findElements('PDFFile').isEmpty
                ? 'No Data'
                : listResult.findElements('PDFFile').first.text;
            final ext = listResult.findElements('Ext').isEmpty
                ? 'No Data'
                : listResult.findElements('Ext').first.text;
            final attachmentType =
                listResult.findElements('attachmentType').isEmpty
                    ? 'No Data'
                    : listResult.findElements('attachmentType').first.text;

            setState(() {
              attFile.add({
                'noAgreementDetail': noAgreementDetail,
                'filename': filename,
                'pdf': pdfFile,
                'ext': ext,
                'attachmentType': attachmentType,
              });
            });

            // var hasilJson = jsonEncode(attFile);
            //debugPrint(hasilJson);

            Future.delayed(const Duration(seconds: 1), () async {
              if (mounted) {
                setState(() {
                  loading = false;
                });
              }

              await editItem();
            });
          }
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
                  fail: 'Error Get Agreement Attachment',
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
                fail: 'Error Get Agreement Attachment',
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
      //debugPrint(userName);

      level = userLevel ?? 'No Data';
      //debugPrint(level);
    });
  }

  Future<void> editItem() async {
    selectDate =
        DateTime.parse(widget.editItem.last['tanggal'].toString()).toLocal();
    date.text = DateFormat('dd-MMM-yyyy')
        .format(DateTime.parse(selectDate.toString()).toLocal());
    namaBank.text = widget.editItem.last['bank'];
    List curr1 = listCurr
        .where((data) => data.contains(widget.editItem.last['curr']))
        .toList();
    curr.text = curr1.last;
    amount.text = NumberFormat.currency(symbol: '')
        .format(
            double.parse(widget.editItem.last['amount'].replaceAll(',', '')))
        .toString();
    fileName = attFile.last['filename'];

    _image = base64Decode(attFile.last['pdf']);
    fileExt = attFile.last['ext'];
    titleFile = attFile.last['pdf'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getBank();
      await getCurr();
      await getUser();
      await getAgreementAttachment();
    });

    date.text = DateFormat('dd-MMM-yyyy')
        .format(DateTime.parse(selectDate.toString()).toLocal());
  }

  @override
  void dispose() {
    date.dispose();
    namaBank.dispose();
    bank.dispose();
    curr.dispose();
    amount.dispose();
    _focusNode.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        _focusNode1.unfocus();
        _focusNode2.unfocus();
        _focusNode3.unfocus();
      },
      child: SizedBox(
        height: size.height,
        child: Stack(
          children: [
            AlertDialog(
              title: const Center(
                child: Text(
                  'UPDATE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                clipBehavior: Clip.antiAlias,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Item: ${widget.editItem.last['item']}'),
                          const Divider(
                            thickness: 2,
                          ),
                          const Text("Payment Date"),
                          SizedBox(height: size.height * 0.005),
                          TextFormField(
                            controller: date,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            readOnly: true,
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(width: 1),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(width: 1),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () async {
                                  await pickDate();
                                },
                                icon: const Icon(
                                  Icons.calendar_month_outlined,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.01),
                          const Text("Bank Name"),
                          SizedBox(height: size.height * 0.005),
                          TextFormField(
                            focusNode: _focusNode,
                            controller: namaBank,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Color.fromARGB(255, 4, 88, 156),
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: Colors.red,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: Colors.red,
                                ),
                              ),
                              hintText: 'BCA',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Bank can't be empty";
                              } else if (!listNamaBank.contains(value)) {
                                return "Bank doesn't match";
                              } else {
                                return null;
                              }
                            },
                            onTap: () async {
                              setState(() {
                                isBank = true;
                              });
                              filterBank(namaBank.text);
                            },
                            onChanged: (value) {
                              setState(() {
                                isBank = true;
                              });
                              filterBank(value);
                            },
                            onEditingComplete: () {
                              setState(() {
                                isBank = true;
                              });
                              filterBank(namaBank.text);
                            },
                          ),
                          namaBank.text == 'OTHER'
                              ? TextFormField(
                                  focusNode: _focusNode1,
                                  controller: bank,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(width: 2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width: 2,
                                        color: Color.fromARGB(255, 4, 88, 156),
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width: 1,
                                        color: Colors.red,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width: 1,
                                        color: Colors.red,
                                      ),
                                    ),
                                    hintText: 'B***',
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "Text can't be empty";
                                    } else {
                                      return null;
                                    }
                                  },
                                )
                              : const SizedBox.shrink(),
                          isBank
                              ? SizedBox(
                                  height: filteredBank.value.isEmpty
                                      ? size.height * 0
                                      : filteredBank.value.length < 3
                                          ? ((MediaQuery.of(context)
                                                              .textScaleFactor *
                                                          14 +
                                                      2 * 18) *
                                                  filteredBank.value.length) +
                                              2 * size.height * 0.02
                                          : size.height * 0.2,
                                  width: size.width,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    clipBehavior: Clip.antiAlias,
                                    itemCount: filteredBank.value.length,
                                    itemBuilder: (BuildContext context, index) {
                                      return ListTile(
                                        title: Text(
                                          filteredBank.value[index],
                                        ),
                                        onTap: () async {
                                          setState(() {
                                            namaBank.text =
                                                filteredBank.value[index];
                                            isBank = false;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                          SizedBox(height: size.height * 0.01),
                          const Text("Currency"),
                          SizedBox(height: size.height * 0.005),
                          TextFormField(
                            focusNode: _focusNode2,
                            controller: curr,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Color.fromARGB(255, 4, 88, 156),
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: Colors.red,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: Colors.red,
                                ),
                              ),
                              hintText: 'IDR',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Currency can't be empty";
                              } else if (!listCurr.contains(value)) {
                                return "Currency doesn't match";
                              } else {
                                return null;
                              }
                            },
                            onTap: () async {
                              setState(() {
                                isCurr = true;
                              });
                              filterCurr(curr.text);
                            },
                            onChanged: (value) {
                              setState(() {
                                isCurr = true;
                              });
                              filterCurr(value);
                            },
                            onEditingComplete: () {
                              setState(() {
                                isCurr = true;
                              });
                              filterCurr(curr.text);
                            },
                          ),
                          isCurr
                              ? SizedBox(
                                  height: filteredCurr.value.isEmpty
                                      ? size.height * 0
                                      : filteredCurr.value.length < 3
                                          ? ((MediaQuery.of(context)
                                                              .textScaleFactor *
                                                          14 +
                                                      2 * 18) *
                                                  filteredCurr.value.length) +
                                              2 * size.height * 0.02
                                          : size.height * 0.2,
                                  width: size.width,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    clipBehavior: Clip.antiAlias,
                                    itemCount: filteredCurr.value.length,
                                    itemBuilder: (BuildContext context, index) {
                                      return ListTile(
                                        title: Text(
                                          filteredCurr.value[index],
                                        ),
                                        onTap: () async {
                                          setState(() {
                                            curr.text =
                                                filteredCurr.value[index];
                                            isCurr = false;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                          SizedBox(height: size.height * 0.01),
                          const Text("Amount"),
                          SizedBox(height: size.height * 0.005),
                          TextFormField(
                            focusNode: _focusNode3,
                            controller: amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                            ),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            autocorrect: false,
                            inputFormatters: [
                              CurrencyInputFormatter(),
                            ],
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Color.fromARGB(255, 4, 88, 156),
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: Colors.red,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: Colors.red,
                                ),
                              ),
                              hintText: '0.0',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Amount can't be empty";
                              } else {
                                return null;
                              }
                            },
                          ),
                          Column(
                            children: [
                              SizedBox(height: size.height * 0.03),
                              Container(
                                width: size.width,
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(width: 1, color: Colors.black),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 5),
                                    titleFile == 'No File Choosen'
                                        ? ElevatedButton(
                                            onPressed: () async {
                                              await _getFile();
                                            },
                                            child: const Text("Choose File"),
                                          )
                                        : ElevatedButton(
                                            onPressed: () async {
                                              setState(() {
                                                _image = null;
                                                titleFile = 'No File Choosen';
                                                isNew = true;
                                              });
                                            },
                                            child: const Text("Clear"),
                                          ),
                                    const SizedBox(width: 5),
                                    SizedBox(
                                      width: size.width > 400
                                          ? size.width * 0.35
                                          : size.width * 0.3,
                                      child: Text(
                                        titleFile,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    "Close",
                    style: TextStyle(
                      color: loading ? null : Colors.red,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            setState(() {
                              loading = true;
                            });

                            if (titleFile == 'No File Choosen') {
                              StatusAlert.show(
                                context,
                                duration: const Duration(seconds: 2),
                                configuration: const IconConfiguration(
                                    icon: Icons.error, color: Colors.red),
                                title: "Please Choose The File",
                                backgroundColor: Colors.grey[300],
                              );

                              setState(() {
                                loading = false;
                              });
                            } else {
                              await updatePaymentAgreement();
                            }
                          }
                        },
                  child: Text(
                    "Update",
                    style: TextStyle(
                      color: loading ? null : Colors.green,
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
      ),
    );
  }
}