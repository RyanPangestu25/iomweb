// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import '../loading.dart';
import 'list_bank.dart';
import 'list_curr.dart';
import 'try_again.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class Edit extends StatefulWidget {
  final Function(bool) isUpdate;
  final List editItem;
  final String server;

  const Edit({
    super.key,
    required this.isUpdate,
    required this.editItem,
    required this.server,
  });

  @override
  State<Edit> createState() => _EditState();
}

class _EditState extends State<Edit> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool isClick = false;
  bool isBalance = false;
  bool isNew = false;
  Uint8List? _image;
  String titleFile = "No File Choosen";
  String fileName = '';
  String fileExt = '';
  String userName = '';
  String level = '';
  List attFile = [];
  List<String> listCurr = [];
  var hasilJson = '';

  DropdownMenuItem<String> buildmenuItem(String item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  TextEditingController date = TextEditingController();
  TextEditingController namaBank = TextEditingController();
  TextEditingController bank = TextEditingController();
  TextEditingController curr = TextEditingController();
  var amount = MoneyMaskedTextController();

  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode1 = FocusNode();

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
      debugPrint("No File Choosen");
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

            hasilJson = jsonEncode(listCurr);
            debugPrint(hasilJson);

            if (mounted) {
              setState(() {
                loading = false;
              });
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
          subtitle: "Error Get Currency",
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
        title: "Error Get Currency",
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

  Future<void> updatePayment() async {
    try {
      setState(() {
        loading = true;
      });

      String namaBankPenerima =
          namaBank.text == 'OTHER' ? bank.text : namaBank.text;

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<UpdatePayment xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.editItem.last['noIOM']}</NoIOM>' +
          '<Item>${widget.editItem.last['item']}</Item>' +
          '<Tgl_TerimaPembayaran>${DateFormat('dd-MMM-yyyy').parse(date.text).toLocal().toIso8601String()}</Tgl_TerimaPembayaran>' +
          '<NamaBankPenerima>$namaBankPenerima</NamaBankPenerima>' +
          '<AmountPembayaran>${amount.numberValue}</AmountPembayaran>' +
          '<CurrPembayaran>${curr.text.substring(0, 3)}</CurrPembayaran>' +
          '<server>${widget.server}</server>' +
          '</UpdatePayment>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_UpdatePayment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/UpdatePayment',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('UpdatePaymentResult').isEmpty
                ? 'GAGAL'
                : document.findAllElements('UpdatePaymentResult').first.text;

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
              await updateAtt();
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
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          title: "${response.statusCode}",
          subtitle: "Failed Verification Payment",
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
        title: "Failed Verification Payment",
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

  Future<void> updateAtt() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<UpdateAttach xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.editItem.last['noIOM']}</NoIOM>' +
          '<Filename>$fileName</Filename>' +
          '<PDFFile>${base64Encode(_image!)}</PDFFile>' +
          '<UploadBy>$userName</UploadBy>' +
          '<UploadDate>${DateTime.now().toLocal().toIso8601String()}</UploadDate>' +
          '<Ext>$fileExt</Ext>' +
          '<Item>${widget.editItem.last['item']}</Item>' +
          '<server>${widget.editItem.last['server']}</server>' +
          '</UpdateAttach>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_UpdateAttach),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/UpdateAttach',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('UpdateAttachResult').isEmpty
                ? 'GAGAL'
                : document.findAllElements('UpdateAttachResult').first.text;

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
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          title: "${response.statusCode}",
          subtitle: "Failed Add Attachment",
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
                      await updateAtt();
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
        title: "Failed Add Attachment",
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
                    await updateAtt();
                  }
                },
              );
            });
      });
    }
  }

  Future<void> getIOMAttachment() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetIOMAttachment xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.editItem.last['noIOM']}</NoIOM>' +
          '<Item>${widget.editItem.last['item']}</Item>' +
          '<attachmentType>BUKTI TERIMA PEMBAYARAN</attachmentType>' +
          '<server>${widget.server}</server>' +
          '</GetIOMAttachment>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetIOMAttachment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetIOMAttachment',
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
            final noIOM = listResult.findElements('NoIOM').isEmpty
                ? 'No Data'
                : listResult.findElements('NoIOM').first.text;
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
                'noIOM': noIOM,
                'filename': filename,
                'pdf': pdfFile,
                'ext': ext,
                'attachmentType': attachmentType,
              });
            });

            var hasilJson = jsonEncode(attFile);
            debugPrint(hasilJson);

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
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          title: "${response.statusCode}",
          subtitle: "Error Get IOM Attachment",
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
        title: "Error Get IOM Attachment",
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
    amount.updateValue(double.parse(widget.editItem.last['amount']));
    fileName = attFile.last['filename'];

    _image = base64Decode(attFile.last['pdf']);
    fileExt = attFile.last['ext'];
    titleFile = attFile.last['pdf'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getCurr();
      await getUser();
      await getIOMAttachment();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        _focusNode1.unfocus();
      },
      child: SizedBox(
        height: size.height,
        child: Stack(
          children: [
            AlertDialog(
              icon: Icon(
                Icons.done,
                size: size.height * 0.1,
              ),
              iconColor: Colors.green,
              title: const Text('VERIFICATION'),
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
                            controller: namaBank,
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
                                  await showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return ListBank(
                                        namaBank: (value) {
                                          setState(() {
                                            namaBank.text = value;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.list_alt,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                          namaBank.text == 'OTHER'
                              ? TextFormField(
                                  focusNode: _focusNode,
                                  controller: bank,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.redAccent, width: 2),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.redAccent, width: 2),
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
                          SizedBox(height: size.height * 0.01),
                          const Text("Currency"),
                          SizedBox(height: size.height * 0.005),
                          TextFormField(
                            controller: curr,
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
                                  await showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return ListCurr(
                                        curr: (value) {
                                          setState(() {
                                            curr.text = value;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.list_alt,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.01),
                          const Text("Amount"),
                          SizedBox(height: size.height * 0.005),
                          TextFormField(
                            focusNode: _focusNode1,
                            controller: amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                            ),
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
                              hintText: '0.0',
                            ),
                            validator: (value) {
                              if (value == '0,00') {
                                return "Amount can't be 0,00";
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
                              await updatePayment();
                            }
                          }
                        },
                  child: Text(
                    "Verification",
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
                    "Close",
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
      ),
    );
  }
}
