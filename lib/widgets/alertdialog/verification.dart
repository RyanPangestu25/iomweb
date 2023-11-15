// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../screens/view_iom.dart';
import '../../widgets/alertdialog/list_bank.dart';
import '../../widgets/alertdialog/list_curr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import '../loading.dart';
import 'try_again.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class Verification extends StatefulWidget {
  final Function(int) item;
  final List iom;
  final int lastItem;

  const Verification({
    super.key,
    required this.item,
    required this.iom,
    required this.lastItem,
  });

  @override
  State<Verification> createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool isClick = false;
  bool isBalance = false;
  int item = 0;
  Uint8List? _image;
  String titleFile = "No File Choosen";
  String fileName = '';
  String fileExt = '';
  String userName = '';
  String level = '';
  double saldo = 0;
  List<String> listNamaBank = [
    'Select',
  ];
  List<String> listCurr = [
    'Select',
  ];
  List<String> payType = [
    'Payment',
    'Pending Payment',
  ];
  ValueNotifier<List<String>> filteredPay = ValueNotifier([
    'Payment',
    'Pending Payment',
  ]);
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

  Future<void> verification(int isPayment) async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<Verification xmlns="http://tempuri.org/">' +
          '<isPayment>$isPayment</isPayment>' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<server>${widget.iom.last['server']}</server>' +
          '<VerifiedBy>$userName</VerifiedBy>' +
          '</Verification>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_Verification),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/Verification',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('VerificationResult').isEmpty
                ? 'GAGAL'
                : document.findAllElements('VerificationResult').first.text;

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

            if (isPayment == 1) {
              await verifPayment();
            } else {
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 2),
                configuration: const IconConfiguration(
                    icon: Icons.done, color: Colors.green),
                title: "Success",
                backgroundColor: Colors.grey[300],
              );

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
          subtitle: "Failed Verification",
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
        title: "Failed Verification",
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

  Future<void> verifPayment() async {
    try {
      setState(() {
        loading = true;
      });

      String namaBankPenerima =
          namaBank.text == 'OTHER' ? bank.text : namaBank.text;

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<VerificationPayment xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<Item>${(item + 1).toString()}</Item>' +
          '<Tgl_TerimaPembayaran>${DateFormat('dd-MMM-yyyy').parse(date.text).toLocal().toIso8601String()}</Tgl_TerimaPembayaran>' +
          '<NamaBankPenerima>$namaBankPenerima</NamaBankPenerima>' +
          '<AmountPembayaran>${amount.numberValue}</AmountPembayaran>' +
          '<CurrPembayaran>${curr.text.substring(0, 3)}</CurrPembayaran>' +
          '<server>${widget.iom.last['server']}</server>' +
          '</VerificationPayment>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_VerificationPayment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/VerificationPayment',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document
                .findAllElements('VerificationPaymentResult')
                .isEmpty
            ? 'GAGAL'
            : document.findAllElements('VerificationPaymentResult').first.text;

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

            await verifAtt();
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

  Future<void> verifAtt() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<VerificationAttach xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<Filename>$fileName</Filename>' +
          '<PDFFile>${base64Encode(_image!)}</PDFFile>' +
          '<UploadBy>$userName</UploadBy>' +
          '<UploadDate>${DateTime.now().toLocal().toIso8601String()}</UploadDate>' +
          '<Ext>$fileExt</Ext>' +
          '<Item>${(item + 1).toString()}</Item>' +
          '<server>${widget.iom.last['server']}</server>' +
          '</VerificationAttach>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_VerificationAttach),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/VerificationAttach',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document
                .findAllElements('VerificationAttachResult')
                .isEmpty
            ? 'GAGAL'
            : document.findAllElements('VerificationAttachResult').first.text;

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
              title: "Success ($item)",
              backgroundColor: Colors.grey[300],
            );

            if (mounted) {
              setState(() {
                saldo = saldo + amount.numberValue;
                loading = false;
                item = item + 1;
                amount.updateValue(0);
                titleFile = 'No File Choosen';

                widget.item(item);
              });
            }

            await cekSaldoIOM();
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
                      await verifAtt();
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
                    await verifAtt();
                  }
                },
              );
            });
      });
    }
  }

  Future<void> cekSaldoIOM() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<CekSaldoIOM xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<server>${widget.iom.last['server']}</server>' +
          '</CekSaldoIOM>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_CekSaldoIOM),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/CekSaldoIOM',
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
            final lastItem = listResult.findElements('LastItem').isEmpty
                ? '0'
                : listResult.findElements('LastItem').first.text;
            final total = listResult.findElements('Total').isEmpty
                ? '0'
                : listResult.findElements('Total').first.text;

            setState(() {
              item = int.parse(lastItem);
              saldo = double.parse(total);

              double.parse(total) >= double.parse(widget.iom.last['biaya'])
                  ? isBalance = true
                  : false;

              if (saldo == 0.0) {
                filteredPay.value = payType;
              } else {
                filteredPay.value = ['Payment'];
                isClick = true;
              }
            });

            debugPrint('$item');
            debugPrint(total);

            Future.delayed(const Duration(seconds: 1), () async {
              if (mounted) {
                setState(() {
                  loading = false;
                });
              }

              if (isBalance) {
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
              }
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
          subtitle: "Error Check IOM Balance",
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
        title: "Error Check IOM Balance",
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getUser();
      await cekSaldoIOM();
    });

    date.text = DateFormat('dd-MMM-yyyy')
        .format(DateTime.parse(selectDate.toString()).toLocal());

    item == 0 ? item = widget.lastItem : null;
  }

  @override
  void dispose() {
    date.dispose();
    bank.dispose();
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
                      const Text('Verification Type:'),
                      SizedBox(
                        height: size.height * 0.1,
                        width: size.width,
                        child: ListView.separated(
                          itemCount: filteredPay.value.length,
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(width: size.width * 0.02);
                          },
                          itemBuilder: (BuildContext context, index) {
                            return Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isClick ? Colors.green : null,
                                    foregroundColor:
                                        isClick ? Colors.white : null,
                                  ),
                                  onPressed: () async {
                                    setState(() {
                                      isClick = !isClick;
                                      filteredPay.value =
                                          isClick ? [payType[index]] : payType;
                                    });
                                  },
                                  child: isClick
                                      ? Row(
                                          children: [
                                            Text(filteredPay.value[index]),
                                            SizedBox(width: size.width * 0.01),
                                            const Icon(Icons.done),
                                          ],
                                        )
                                      : Text(filteredPay.value[index]),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      filteredPay.value.last == 'Pending Payment'
                          ? const SizedBox.shrink()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Item: $item'),
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
                                                color: Colors.redAccent,
                                                width: 2),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.redAccent,
                                                width: 2),
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
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
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
                                SizedBox(height: size.height * 0.03),
                                Container(
                                  width: size.width,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 1, color: Colors.black),
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
                            int isPayment = 0;

                            setState(() {
                              loading = true;
                              isPayment =
                                  filteredPay.value.last == 'Payment' ? 1 : 0;
                              debugPrint('Payment Status: $isPayment');
                            });

                            if (isPayment == 1 &&
                                (titleFile == 'No File Choosen')) {
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
                              await verification(isPayment);
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
