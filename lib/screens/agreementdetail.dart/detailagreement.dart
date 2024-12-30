// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data_table_2/data_table_2.dart';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iomweb/backend/constants.dart';
import 'package:iomweb/screens/agreementdetail.dart/attachmentagreement.dart';
import 'package:iomweb/screens/agreementdetail.dart/paymentagreement.dart';
import 'package:iomweb/widgets/alertdialog/approval/approval_iom.dart';
import 'package:iomweb/widgets/alertdialog/log_error.dart';
import 'package:iomweb/widgets/alertdialog/verification/verifiction_agreement.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;

class DetailAgreement extends StatefulWidget {
  final Function(bool) isRefresh;
  final List agreementdetail;
  const DetailAgreement({
    super.key,
    required this.isRefresh,
    required this.agreementdetail,
  });

  @override
  State<DetailAgreement> createState() => _DetailAgreementState();
}

class _DetailAgreementState extends State<DetailAgreement> {
  bool loading = false;
  bool _sortAscending = true;
  bool _isConnected = false;
  bool visible = true;
  bool isBalance = false;
  int _sortColumnIndex = 0;
  int currentPage = 1;
  int rowPerPages = PaginatedDataTable.defaultRowsPerPage;
  int item = 0;
  int level = 0;
  List jadwal = [];
  List payment = [];
  String status = '';
  TextEditingController pphAmount = TextEditingController();

  Future<void> getAgreementItem() async {
    try {
      setState(() {
        loading = true;
      });

     
      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetAgreementItem xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.agreementdetail.last['noAgreementdetail']}</NoAgreementDetail>'+
          '<server>${widget.agreementdetail.last['server']}</server>'+
          '</GetAgreementItem>'+
          '</soap:Body>' +
          '</soap:Envelope>';


      final response = await http.post(Uri.parse(url_GetAgreementItem),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetAgreementItem',
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
              : listResult.findElements('StatusData').first.innerText;

          if (statusData == "GAGAL") {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                StatusAlert.show(
                  context,
                  duration: const Duration(seconds: 1),
                  configuration: const IconConfiguration(
                      icon: Icons.error, color: Colors.red),
                  title: "No Data",
                  backgroundColor: Colors.grey[300],
                );

                setState(() {
                  loading = false;
                });
              }
            });
          } else {
            final noAgreementdetail = listResult.findElements('NoAgreementDetail').isEmpty
                ? 'No Data'
                : listResult.findElements('NoAgreementDetail').first.innerText;
            final item = listResult.findElements('Item').isEmpty
                ? 'No Data'
                : listResult.findElements('Item').first.innerText;
            final tanggal = listResult.findElements('Tanggal').isEmpty
                ? 'No Data'
                : listResult.findElements('Tanggal').first.innerText;
            final rute = listResult.findElements('Rute').isEmpty
                ? 'No Data'
                : listResult.findElements('Rute').first.innerText;
            final blockTime = listResult.findElements('BlockTime').isEmpty
                ? 'PT0M'
                : listResult.findElements('BlockTime').first.innerText;
            final keterangan = listResult.findElements('Keterangan').isEmpty
                ? 'No Data'
                : listResult.findElements('Keterangan').first.innerText;
            final flightNumber = listResult.findElements('FlightNumber').isEmpty
                ? 'No Data'
                : listResult.findElements('FlightNumber').first.innerText;
            final airlineCode = listResult.findElements('AirlineCode').isEmpty
                ? 'No Data'
                : listResult.findElements('AirlineCode').first.innerText;

            // Parse the blockTime string to extract the hours and minutes
            int hours = 0;
            int minutes = 0;
            if (blockTime.contains('H')) {
              hours = int.parse(blockTime.substring(2, blockTime.indexOf("H")));
            }

            if (blockTime.contains('M')) {
              if (hours != 0) {
                minutes = int.parse(blockTime.substring(
                    blockTime.indexOf("H") + 1, blockTime.indexOf("M")));
              } else {
                minutes =
                    int.parse(blockTime.substring(2, blockTime.indexOf("M")));
              }
            }

            // Create a DateTime object and add the parsed duration to it
            DateTime currentTime =
                DateTime.parse('2023-11-02T00:00:00.0000000');
            DateTime convertedTime = currentTime.add(
              Duration(hours: hours, minutes: minutes),
            );

            setState(() {
              if (!jadwal.any((data) => data['item'] == item)) {
                jadwal.add({
                  'noAgreementdetail': noAgreementdetail,
                  'item': item,
                  'tanggal': tanggal,
                  'rute': rute,
                  'blockTime': convertedTime.toString(),
                  'ket': keterangan,
                  'flightNumber': flightNumber,
                  'airlineCode': airlineCode,
                });
              }
            });

            // var hasilJson = jsonEncode(jadwal);
            //debugprint(hasilJson);

            Future.delayed(const Duration(seconds: 1), () async {
              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            });
          }
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
                  fail: 'Error Get Agreement Item',
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
                fail: 'Error Get Agree Item',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  // Future<void> cekSaldoDetailAgreement() async {
  //   try {
  //     setState(() {
  //       loading = true;
  //     });

  //     final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><CekSaldoIOM xmlns="http://tempuri.org/"><NoIOM>${widget.agreementdetail.last['noIOM']}</NoIOM><server>${widget.agreementdetail.last['server']}</server></CekSaldoIOM></soap:Body></soap:Envelope>';

  //     final response = await http.post(Uri.parse(url_CekSaldoIOM),
  //         headers: <String, String>{
  //           "Access-Control-Allow-Origin": "*",
  //           'SOAPAction': 'http://tempuri.org/CekSaldoIOM',
  //           'Access-Control-Allow-Credentials': 'true',
  //           'Content-type': 'text/xml; charset=utf-8'
  //         },
  //         body: soapEnvelope);

  //     if (response.statusCode == 200) {
  //       final document = xml.XmlDocument.parse(response.body);

  //       final listResultAll = document.findAllElements('Table');

  //       for (final listResult in listResultAll) {
  //         final statusData = listResult.findElements('StatusData').isEmpty
  //             ? 'No Data'
  //             : listResult.findElements('StatusData').first.innerText;

  //         if (statusData == "GAGAL") {
  //           Future.delayed(const Duration(seconds: 1), () {
  //             if (mounted) {
  //               StatusAlert.show(
  //                 context,
  //                 duration: const Duration(seconds: 1),
  //                 configuration: const IconConfiguration(
  //                     icon: Icons.error, color: Colors.red),
  //                 title: "No Data",
  //                 backgroundColor: Colors.grey[300],
  //               );

  //               setState(() {
  //                 loading = false;
  //               });
  //             }
  //           });
  //         } else {
  //           final lastItem = listResult.findElements('LastItem').isEmpty
  //               ? '0'
  //               : listResult.findElements('LastItem').first.innerText;
  //           final total = listResult.findElements('Total').isEmpty
  //               ? '0'
  //               : listResult.findElements('Total').first.innerText;

  //           setState(() {
  //             item = int.parse(lastItem);
  //             double.parse(total) >=
  //                     double.parse(widget.agreementdetail.last['biaya'])
  //                 ? isBalance = true
  //                 : false;
  //           });

  //           //debugprint('$item');
  //           //debugprint(total);

  //           Future.delayed(const Duration(seconds: 1), () async {
  //             if (mounted) {
  //               setState(() {
  //                 loading = false;
  //               });
  //             }
  //           });
  //         }
  //       }
  //     } else {
  //       //debugprint('Error: ${response.statusCode}');
  //       //debugprint('Desc: ${response.body}');

  //       if (mounted) {
  //         await showDialog(
  //             context: context,
  //             barrierDismissible: false,
  //             builder: (BuildContext context) {
  //               return LogError(
  //                 statusCode: response.statusCode.toString(),
  //                 fail: 'Error Check IOM Balance',
  //                 error: response.body.toString(),
  //               );
  //             });

  //         setState(() {
  //           loading = false;
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     //debugprint('$e');

  //     if (mounted) {
  //       await showDialog(
  //           context: context,
  //           barrierDismissible: false,
  //           builder: (BuildContext context) {
  //             return LogError(
  //               statusCode: '',
  //               fail: 'Error Check IOM Balance',
  //               error: e.toString(),
  //             );
  //           });

  //       setState(() {
  //         loading = false;
  //       });
  //     }
  //   }
  // }



  Future<void> getAgreementPayment() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>'+
      '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+
      '<soap:Body>'+
      '<GetAgreementPayment xmlns="http://tempuri.org/">'+
      '<NoAgreementDetail>${widget.agreementdetail.last['noAgreementdetail']}</NoAgreementDetail>'+
      '<server>${widget.agreementdetail.last['server']}</server>'+
      '</GetAgreementPayment>'+
      '</soap:Body>'+
      '</soap:Envelope>';


      final response = await http.post(Uri.parse(url_GetAgreementPayment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetAgreementPayment',
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
              : listResult.findElements('StatusData').first.innerText;

          if (statusData == "GAGAL") {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                StatusAlert.show(
                  context,
                  duration: const Duration(seconds: 1),
                  configuration: const IconConfiguration(
                      icon: Icons.error, color: Colors.red),
                  title: "No Data",
                  backgroundColor: Colors.grey[300],
                );

                setState(() {
                  loading = false;
                });
              }
            });
          } else {
            final noAgreement = listResult.findElements('NoAgreement').isEmpty
                ? 'No Data'
                : listResult.findElements('NoAgreement').first.innerText;
            final item = listResult.findElements('Item').isEmpty
                ? 'No Data'
                : listResult.findElements('Item').first.innerText;
            final tglTerimaPembayaran =
                listResult.findElements('Tgl_TerimaPembayaran').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Tgl_TerimaPembayaran')
                        .first
                        .innerText;
            final namaBankPenerima = listResult
                    .findElements('NamaBankPenerima')
                    .isEmpty
                ? 'No Data'
                : listResult.findElements('NamaBankPenerima').first.innerText;
            final amountPembayaran = listResult
                    .findElements('AmountPembayaran')
                    .isEmpty
                ? '0'
                : listResult.findElements('AmountPembayaran').first.innerText;
            final currPembayaran =
                listResult.findElements('CurrPembayaran').isEmpty
                    ? '0'
                    : listResult.findElements('CurrPembayaran').first.innerText;

            setState(() {
              payment.add({
                'noAgreement': noAgreement,
                'item': item,
                'tanggal': tglTerimaPembayaran,
                'bank': namaBankPenerima,
                'amount': amountPembayaran,
                'curr': currPembayaran,
              });
            });

            // var hasilJson = jsonEncode(payment);
            //debugprint(hasilJson);
          }
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
                  fail: 'Error Get IOM Payment',
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
                fail: 'Error Get IOM Payment',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> initConnection() async {
    Connectivity().checkConnectivity().then((value) {
      //debugprint('$value');
      if (value != ConnectivityResult.none) {
        setState(() {
          _isConnected = (value != ConnectivityResult.none);
        });

        if (_isConnected) {
          setState(() {
            visible = false;
          });
        } else {
          setState(() {
            visible = true;
          });
        }
      }

      Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        if (mounted) {
          setState(() {
            _isConnected = (result != ConnectivityResult.none);
          });

          if (_isConnected) {
            Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                visible = false;
              });
            });
          } else {
            setState(() {
              visible = true;
            });
          }
        }
      });
    });
  }

  Future<void> getLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userLevel = prefs.getString('userLevel');

    setState(() {
      level = int.parse(userLevel ?? '0');
      //debugprint(level.toString());
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initConnection();
      await getLevel();
      await getAgreementItem();
      // await cekSaldoDetailAgreement();
    });

    pphAmount.text.isEmpty
        ? pphAmount.text = widget.agreementdetail.last['currencyPPH'] +
            " " +
            NumberFormat.currency(locale: 'id_ID', symbol: '')
                .format(
                  double.parse(widget.agreementdetail.last['biayaPPH']
                      .replaceAll(',', '.')),
                )
                .toString()
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.isRefresh(true);

          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          title: const Text(
            "Agreement Detail",
          ),
          elevation: 3,
          leading: IconButton(
            onPressed: () async {
              widget.isRefresh(true);
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
          actions: [
            // IconButton(
            //   onPressed: loading
            //       ? null
            //       : () async {
            //           setState(() {
            //             loading = true;
            //             payment.clear();
            //           });
            //           await getIOMPayment();

            //           await Future.delayed(const Duration(milliseconds: 100),
            //               () async {
            //             await createExcelFile();
            //           });

            //           if (isSave) {
            //             ScaffoldMessenger.of(context).showSnackBar(
            //               SnackBar(
            //                 showCloseIcon: false,
            //                 duration: const Duration(seconds: 5),
            //                 behavior: SnackBarBehavior.floating,
            //                 padding: const EdgeInsets.all(20),
            //                 elevation: 10,
            //                 content: Center(
            //                   child: Text(
            //                     'File Saved in $excelPath',
            //                     textAlign: TextAlign.justify,
            //                   ),
            //                 ),
            //               ),
            //             );
            //           }
            //         },
            //   icon: const Icon(Icons.download_for_offline),
            // ),
            IconButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() {
                        loading = true;
                        isBalance = false;
                      });
                      jadwal.clear();
                      await getAgreementItem();
                      // await cekSaldoDetailAgreement();
                    },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Agreement No',
                    style:  TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget.agreementdetail.last['noAgreementdetail'],
                    autocorrect: false,
                    readOnly: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Agreement Name",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget.agreementdetail.last['charter'],
                    autocorrect: false,
                    readOnly: true,
                    maxLines: 2,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Agreement Date",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue:
                        widget.agreementdetail.last['tanggal'] == 'No Data'
                            ? widget.agreementdetail.last['tanggal']
                            : DateFormat('dd-MMM-yyyy').format(DateTime.parse(
                                    widget.agreementdetail.last['tanggal'])
                                .toLocal()),
                    autocorrect: false,
                    readOnly: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget.agreementdetail.last['perihal'],
                    autocorrect: false,
                    readOnly: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Agreement Cost",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget.agreementdetail.last['curr'] +
                        ' ' +
                        NumberFormat.currency(locale: 'id_ID', symbol: '')
                            .format(
                              double.parse(widget.agreementdetail.last['biaya']
                                  .replaceAll(',', '.')),
                            )
                            .toString(),
                    autocorrect: false,
                    readOnly: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Revenue",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget.agreementdetail.last['revenue'],
                    autocorrect: false,
                    readOnly: true,
                    maxLines: 1,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Payment",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget.agreementdetail.last['pembayaran'],
                    autocorrect: false,
                    readOnly: true,
                    maxLines: 2,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Note",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget.agreementdetail.last['note'],
                    autocorrect: false,
                    readOnly: true,
                    maxLines: 2,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Status",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget.agreementdetail.last['status'],
                    autocorrect: false,
                    readOnly: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2,
                          color: widget.agreementdetail.last['status'] ==
                                      'VERIFIED PENDING PAYMENT' ||
                                  widget.agreementdetail.last['status'] ==
                                      'VERIFIED PAYMENT'
                              ? Colors.blue
                              : widget.agreementdetail.last['status'] ==
                                      'APPROVED'
                                  ? Colors.green
                                  : widget.agreementdetail.last['status'] ==
                                              'REJECTED' ||
                                          widget.agreementdetail
                                                  .last['status'] ==
                                              'VOID'
                                      ? Colors.red
                                      : Colors.black,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2,
                          color: widget.agreementdetail.last['status'] ==
                                      'VERIFIED PENDING PAYMENT' ||
                                  widget.agreementdetail.last['status'] ==
                                      'VERIFIED PAYMENT'
                              ? Colors.blue
                              : widget.agreementdetail.last['status'] ==
                                      'APPROVED'
                                  ? Colors.green
                                  : widget.agreementdetail.last['status'] ==
                                              'REJECTED' ||
                                          widget.agreementdetail
                                                  .last['status'] ==
                                              'VOID'
                                      ? Colors.red
                                      : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Verification Pending Payment Date",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget
                                .agreementdetail.last['verifNoPayStatus'] ==
                            'No Data'
                        ? widget.agreementdetail.last['verifNoPayStatus']
                        : DateFormat('dd-MMM-yyyy').format(DateTime.parse(
                                widget.agreementdetail.last['verifNoPayStatus'])
                            .toLocal()),
                    autocorrect: false,
                    readOnly: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Verification Payment Date",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget
                                .agreementdetail.last['verifPayStatus'] ==
                            'No Data'
                        ? widget.agreementdetail.last['verifPayStatus']
                        : DateFormat('dd-MMM-yyyy').format(DateTime.parse(
                                widget.agreementdetail.last['verifPayStatus'])
                            .toLocal()),
                    autocorrect: false,
                    readOnly: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Approved Date",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue:
                        widget.agreementdetail.last['approveDate'] == 'No Data'
                            ? widget.agreementdetail.last['approveDate']
                            : DateFormat('dd-MMM-yyyy').format(DateTime.parse(
                                    widget.agreementdetail.last['approveDate'])
                                .toLocal()),
                    autocorrect: false,
                    readOnly: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Payment Status",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    initialValue: widget.agreementdetail.last['payStatus'],
                    autocorrect: false,
                    readOnly: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2,
                          color:
                              widget.agreementdetail.last['payStatus'] == 'PAID'
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2,
                          color:
                              widget.agreementdetail.last['payStatus'] == 'PAID'
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                      suffixIcon: IconButton(
                        onPressed: loading
                            ? null
                            : level == 19
                                ? null
                                : () async {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (BuildContext context) {
                                        return PaymentAgreementDetail(
                                          agreementdetail: widget.agreementdetail,
                                        );
                                      },
                                    ));
                                  },
                        icon: Icon(
                          Icons.arrow_circle_right,
                          color: level == 19 ? null : Colors.green,
                          size: size.height * 0.05,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  const Text(
                    "Income Tax",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  TextFormField(
                    controller: pphAmount,
                    autocorrect: false,
                    readOnly: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) {
                          return AttachmentDetailAgreement(
                            agreementdetail: widget.agreementdetail,
                          );
                        },
                      ));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'View Attachment',
                          style: TextStyle(
                            fontSize:
                                MediaQuery.of(context).textScaler.scale(16),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: size.height * 0.05,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  const Text("Schedule:"),
                  SizedBox(height: size.height * 0.01),
                  SizedBox(
                    height: jadwal.isEmpty
                        ? size.height * 0.25
                        : jadwal.length < 5
                            ? ((MediaQuery.of(context).textScaler.scale(14) +
                                        2 * 18) *
                                    jadwal.length) +
                                2 * size.height * 0.085
                            : size.height * 0.4,
                    child: PaginatedDataTable2(
                      border: TableBorder.all(width: 1),
                      minWidth: 1000,
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      rowsPerPage: rowPerPages,
                      onRowsPerPageChanged: (value) {
                        rowPerPages = value!;
                      },
                      sortArrowIcon: Icons.keyboard_arrow_up,
                      smRatio: 0.35,
                      lmRatio: 1.4,
                      renderEmptyRowsInTheEnd: false,
                      showFirstLastButtons: true,
                      horizontalMargin: size.width * 0,
                      columnSpacing: 15,
                      empty: Center(
                          child:
                              loading ? const Text('Waiting...') : const Text('No Data')),
                      columns: [
                       const DataColumn2(
                          size: ColumnSize.S,
                          label: Center(
                            child: Text(
                              'No',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataColumn2(
                          size: ColumnSize.M,
                          label: const Center(
                            child: Text(
                              'Flight Date',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumnIndex = columnIndex;
                              _sortAscending = ascending;
                              if (ascending) {
                                jadwal.sort((a, b) {
                                  // Mendapatkan tanggal dari data a dan b dalam format DateTime
                                  DateTime dateA = DateTime.parse(a['tanggal']);
                                  DateTime dateB = DateTime.parse(b['tanggal']);

                                  // Membandingkan berdasarkan tahun dan bulan
                                  int yearComparison =
                                      dateA.year.compareTo(dateB.year);
                                  int monthComparison =
                                      dateA.month.compareTo(dateB.month);

                                  // Jika tahun sama, bandingkan bulan
                                  if (yearComparison == 0) {
                                    return monthComparison;
                                  } else {
                                    return yearComparison;
                                  }
                                });
                              } else {
                                jadwal.sort((a, b) {
                                  DateTime dateA = DateTime.parse(a['tanggal']);
                                  DateTime dateB = DateTime.parse(b['tanggal']);

                                  int yearComparison =
                                      dateB.year.compareTo(dateA.year);
                                  int monthComparison =
                                      dateB.month.compareTo(dateA.month);

                                  if (yearComparison == 0) {
                                    return monthComparison;
                                  } else {
                                    return yearComparison;
                                  }
                                });
                              }
                            });
                          },
                        ),
                        const DataColumn2(
                          size: ColumnSize.L,
                          label: Center(
                            child: Text(
                              'Route',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const DataColumn2(
                          size: ColumnSize.S,
                          label: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'BLK',
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'TIME',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataColumn2(
                          size: ColumnSize.M,
                          label: const Center(
                            child: Text(
                              'Description',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumnIndex = columnIndex;
                              _sortAscending = ascending;
                              if (ascending) {
                                jadwal.sort(
                                  (a, b) {
                                    return a['ket'].compareTo(b['ket']);
                                  },
                                );
                              } else {
                                jadwal.sort(
                                    (a, b) => b['ket'].compareTo(a['ket']));
                              }
                            });
                          },
                        ),
                        DataColumn2(
                          size: ColumnSize.M,
                          label: const Center(
                            child: Text(
                              'Flight Number',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumnIndex = columnIndex;
                              _sortAscending = ascending;
                              if (ascending) {
                                jadwal.sort(
                                  (a, b) {
                                    return a['flightNumber']
                                        .compareTo(b['flightNumber']);
                                  },
                                );
                              } else {
                                jadwal.sort((a, b) => b['flightNumber']
                                    .compareTo(a['flightNumber']));
                              }
                            });
                          },
                        ),
                        DataColumn2(
                          size: ColumnSize.M,
                          label: const Center(
                            child: Text(
                              'Airline Code',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumnIndex = columnIndex;
                              _sortAscending = ascending;
                              if (ascending) {
                                jadwal.sort(
                                  (a, b) {
                                    return a['airlineCode']
                                        .compareTo(b['airlineCode']);
                                  },
                                );
                              } else {
                                jadwal.sort((a, b) => b['airlineCode']
                                    .compareTo(a['airlineCode']));
                              }
                            });
                          },
                        ),
                      ],
                      source: TableData(
                        currentPage: currentPage,
                        rowsPerPage: rowPerPages,
                        jadwal: jadwal,
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
        persistentFooterButtons: widget.agreementdetail.last['status'] == 'VOID'
            ? [
                Center(
                  child: Text(
                    widget.agreementdetail.last['status'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
            : level == 12
                ? (widget.agreementdetail.last['status'] == 'VERIFIED PAYMENT' ||
                            widget.agreementdetail.last['status'] == 'APPROVED' ||
                            widget.agreementdetail.last['status'] == 'REJECTED') &&
                        isBalance
                    ? (widget.agreementdetail.last['status'] == 'APPROVED' ||
                                widget.agreementdetail.last['status'] == 'REJECTED') &&
                            !isBalance
                        ? [
                            Center(
                              child: Text(
                                widget.agreementdetail.last['status'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.agreementdetail.last['status'] ==
                                          'VERIFIED PAYMENT'
                                      ? Colors.blue
                                      : widget.agreementdetail.last['status'] == 'APPROVED'
                                          ? Colors.green
                                          : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ]
                        : [
                            Center(
                              child: Text(
                                widget.agreementdetail.last['status'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.agreementdetail.last['status'] ==
                                          'VERIFIED PAYMENT'
                                      ? Colors.blue
                                      : widget.agreementdetail.last['status'] == 'APPROVED'
                                          ? Colors.green
                                          : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ]
                    : [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                fixedSize:
                                    Size(size.width*0.9, size.height * 0.08),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: loading
                                  ? null
                                  : () async {
                                      if (double.parse(widget.agreementdetail.last['biaya']
                                              .replaceAll(',', '.')) ==
                                          0.00) {
                                        StatusAlert.show(
                                          context,
                                          duration: const Duration(seconds: 1),
                                          configuration:
                                              const IconConfiguration(
                                            icon: Icons.error,
                                            color: Colors.red,
                                          ),
                                          title: "Verified Failed",
                                          subtitle: "0 IOM Cost",
                                          backgroundColor: Colors.grey[300],
                                        );
                                      } else {
                                        await showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return VerificationAgreement(
                                              item: (value) {
                                                setState(() {
                                                  item = value;
                                                });
                                              },
                                              agreementdetail: widget.agreementdetail,
                                              lastItem: item,
                                            );
                                          },
                                        );
                                      }
                                    },
                              child: const Text('Verification'),
                            ),
                            
                          ],
                        )
                      ]
                : level == 10
                    ? widget.agreementdetail.last['status'] == 'APPROVED' //||
                        // widget.iom.last['status'] == 'REJECTED' ||
                        // widget.iom.last['status'] == 'NONE'
                        ? [
                            Center(
                              child: Text(
                                widget.agreementdetail.last['status'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.agreementdetail.last['status'] == 'APPROVED'
                                      ? Colors.green
                                      : widget.agreementdetail.last['status'] == 'REJECTED'
                                          ? Colors.red
                                          : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ]
                        : [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    fixedSize: Size(
                                        size.width * 0.4, size.height * 0.08),
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          setState(() {
                                            status = 'APPROVE';
                                          });

                                          await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              List flightDate = [];

                                              for (var data in jadwal) {
                                                String tanggal =
                                                    data['tanggal'];
                                                if (!flightDate
                                                    .contains(tanggal)) {
                                                  flightDate.add(tanggal);
                                                }
                                              }

                                              return Confirmation(
                                                text: status,
                                                iom: widget.agreementdetail,
                                                iomItem: jadwal,
                                                flightDate: flightDate,
                                              );
                                            },
                                          );
                                        },
                                  child: const Text('Approval'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    fixedSize: Size(
                                        size.width * 0.4, size.height * 0.08),
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          setState(() {
                                            status = 'REJECT';
                                          });

                                          await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Confirmation(
                                                text: status,
                                                iom: widget.agreementdetail,
                                                iomItem: jadwal,
                                                flightDate: const [],
                                              );
                                            },
                                          );
                                        },
                                  child: const Text('Rejection'),
                                ),
                              ],
                            ),
                          ]
                    : [
                        Center(
                          child: Text(
                            widget.agreementdetail.last['status'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.agreementdetail.last['status'] == 'NONE'
                                  ? Colors.black
                                  : widget.agreementdetail.last['status'] ==
                                              'VERIFIED PAYMENT' ||
                                          widget.agreementdetail.last['status'] ==
                                              'VERIFIED PENDING PAYMENT'
                                      ? Colors.blue
                                      : widget.agreementdetail.last['status'] == 'APPROVED'
                                          ? Colors.green
                                          : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
    ));
  }
}

class TableData extends DataTableSource {
  final List jadwal;
  final int currentPage;
  final int rowsPerPage;

  TableData({
    required this.jadwal,
    required this.currentPage,
    required this.rowsPerPage,
  });

  @override
  DataRow? getRow(int index) {
    assert(index >= 0);

    if (index >= jadwal.length) throw 'index > ${jadwal.length}';

    final dataIndex =
        (index + (currentPage - 1) * rowsPerPage).clamp(0, jadwal.length - 1);
    final data = jadwal[dataIndex];

    return DataRow2(
      color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        // Even rows will have a grey color.
        if (index.isOdd) {
          return Colors.grey.withOpacity(0.3);
        }
        return null; // Use default value for other states and odd rows.
      }),
      cells: <DataCell>[
        DataCell(
          Center(
            child: Text(
              data['item'].toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: data['tanggal'] == 'No Data'
                ? const Text(
                    'No Data',
                    textAlign: TextAlign.center,
                  )
                : Text(
                    DateFormat('dd-MMM-yyyy').format(
                      DateTime.parse(
                        data['tanggal'],
                      ).toLocal(),
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data['rute'],
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              DateFormat('HH:mm').format(
                DateTime.parse(
                  data['blockTime'],
                ).toLocal(),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data['ket'],
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data['flightNumber'],
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data['airlineCode'],
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => jadwal.length;

  @override
  int get selectedRowCount => 0;
}