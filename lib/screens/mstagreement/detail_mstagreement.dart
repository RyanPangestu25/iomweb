// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, prefer_final_fields, prefer_const_declarations
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:iomweb/backend/constants.dart';
import 'package:iomweb/screens/mstagreement/attachment_mstagreement.dart';
import 'package:iomweb/screens/mstagreement/payment_mstagreement.dart';
import 'package:iomweb/widgets/alertdialog/log_error.dart';
import 'package:iomweb/widgets/alertdialog/verification/verification_mstagreement.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;

class DetailMstAgreement extends StatefulWidget {
  final Function(bool) isRefresh;
  final List data;

  const DetailMstAgreement({
    super.key,
    required this.isRefresh,
    required this.data,
  });

  @override
  State<DetailMstAgreement> createState() => _DetailMstAgreementState();
}

class _DetailMstAgreementState extends State<DetailMstAgreement> {
  bool loading = false;
  bool isBalance = false;
  bool _isConnected = false;
  bool visible = true;
  List jadwal = [];
  List payment = [];
  int level = 0;
  int currentPage = 1;
  int rowPerPages = PaginatedDataTable.defaultRowsPerPage;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int item = 0;
  String status = '';

  Future<void> getmstagreement() async {
    try {
      setState(() {
        loading = true;
      });
      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetMstAgreementItem xmlns="http://tempuri.org/">' +
          '<NoAgreement>${widget.data.last['noAgreement']}</NoAgreement>' +
          '<server>${widget.data.last['server']}</server>' +
          '</GetMstAgreementItem>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetMstAgreementItem),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetMstAgreementItem',
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
                StatusAlert.show(context,
                    duration: const Duration(seconds: 1),
                    configuration: const IconConfiguration(
                        icon: Icons.error, color: Colors.red),
                    title: "No data",
                    backgroundColor: Colors.grey[300]);
                setState(() {
                  loading = false;
                });
              }
            });
          } else {
            final noAgreement =
                listResult.findAllElements('NoAgreement').isEmpty
                    ? "No Data"
                    : listResult.findAllElements('NoAgreement').first.innerText;
            final item = listResult.findAllElements('Item').isEmpty
                ? "No Data"
                : listResult.findAllElements('Item').first.innerText;
            final route = listResult.findAllElements('Route').isEmpty
                ? "No Data"
                : listResult.findAllElements('Route').first.innerText;
            final fee = listResult.findAllElements('Fee').isEmpty
                ? "No Data"
                : listResult.findAllElements('Fee').first.innerText;
            final currency = listResult.findAllElements('Currency').isEmpty
                ? "No Data"
                : listResult.findAllElements('Currency').first.innerText;
            final typepesawat =
                listResult.findAllElements('TypePesawat').isEmpty
                    ? "No Data"
                    : listResult.findAllElements('TypePesawat').first.innerText;
            final routekedua = listResult.findAllElements('RouteKedua').isEmpty
                ? "No Data"
                : listResult.findAllElements('RouteKedua').first.innerText;

            setState(() {
              if (!jadwal.any((data) => data['item'] == item)) {
                jadwal.add({
                  'noAgreement': noAgreement,
                  'item': item,
                  'route': route,
                  'fee': fee,
                  'currency': currency,
                  'typepesawat': typepesawat,
                  'routekedua': routekedua,
                });
              }
            });

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
        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Error Get Master Agreement Item',
                  error: response.body.toString(),
                );
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
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Error Get IOM Item',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> cekSaldoAgreement() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetIOMPayment xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.data.last['noIOM']}</NoIOM>' +
          '<server>${widget.data.last['server']}</server>' +
          '</GetIOMPayment>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_CekSaldoIOM),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetIOMPayment',
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
            final lastItem = listResult.findElements('LastItem').isEmpty
                ? '0'
                : listResult.findElements('LastItem').first.innerText;
            final total = listResult.findElements('Total').isEmpty
                ? '0'
                : listResult.findElements('Total').first.innerText;

            setState(() {
              item = int.parse(lastItem);
              double.parse(total) >= double.parse(widget.data.last['biaya'])
                  ? isBalance = true
                  : false;
            });

            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            });
          }
        }
      } else {
        if (mounted) {
          await showDialog(
              context: context,
              builder: (BuildContext context) {
                return LogError(
                    statusCode: response.statusCode.toString(),
                    fail: "Eror IOM Balance",
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
                  fail: "Eror IOM Balance",
                  error: e.toString());
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getMSTAgreementPayment() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetAgreementPayment xmlns="http://tempuri.org/">' +
          '<NoAgreement>${widget.data.last['NoAgreement']}</NoIOM>' +
          '<server>${widget.data.last['server']}</server>' +
          '</GetAgreementPayment>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetMstAgreementPayment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetIOMPayment',
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
      if (mounted) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return LogError(
                  statusCode: '',
                  fail: "Error Get IOM Payment",
                  error: e.toString());
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userLevel = prefs.getString('userLevel');

    setState(() {
      level = int.parse(userLevel ?? '0');
      //debugprint(level.toString());
    });
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getmstagreement();
      await getLevel();
      await initConnection();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          title: const Text(
            "Detail Master Agreement",
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
          actions: const [
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
            // IconButton(
            //   onPressed: loading
            //       ? null
            //       : () async {
            //           setState(() {
            //             loading = true;
            //             isBalance = false;
            //           });
            //           jadwal.clear();
            //           await getIOMItem();
            //           await cekSaldoIOM();
            //         },
            //   icon: const Icon(Icons.refresh),
            // ),
          ],
        ),
        body: Stack(
          children: [
            widget.data.isEmpty
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Agreement No',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue: widget.data.last['noAgreement'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text(
                          'Customer Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue: widget.data.last['customer'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text('NPWP No.'),
                        TextFormField(
                          initialValue: widget.data.last['noNPWP'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text(
                          'Reference No.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue: widget.data.last['noReference'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text(
                          'Approved By.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue: widget.data.last['approvedBy'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text(
                          'Term And Condition',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue: widget.data.last['tnC'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text(
                          'Currency',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue: widget.data.last['currency'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text(
                          'Amount Deposit ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue:
                              widget.data.last['amountDeposit'] != null
                                  ? NumberFormat.currency(
                                      locale: 'id',
                                      symbol: 'IDR ',
                                      decimalDigits: 0, // Jumlah desimal
                                    ).format(double.parse(
                                      widget.data.last['amountDeposit']))
                                  : 'No Data',
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text(
                          'Type of Agreement',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue: widget.data.last['jenisAgreement'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text(
                          'Signed By',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue: widget.data.last['signedby'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text(
                          'Signed By Charter',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue: widget.data.last['signedByCharterer'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        const Text(
                          'Rute',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        TextFormField(
                          initialValue: widget.data.last['rute'],
                          readOnly: true,
                          autocorrect: false,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              )),
                        ),
                        SizedBox(height: size.height * 0.015),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Period',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: size.height * 0.01,
                                  ),
                                  TextFormField(
                                    initialValue: widget
                                                .data.last['priodeAwal'] !=
                                            null
                                        ? DateFormat('dd-MMM-yyy').format(
                                            DateTime.parse(
                                                widget.data.last['priodeAwal']))
                                        : 'No Data',
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: size.height * 0.01),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'End Period',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: size.height * 0.01,
                                  ),
                                  TextFormField(
                                    initialValue:
                                        widget.data.last['priodeAkhir'] != null
                                            ? DateFormat('dd-MMM-yyy').format(
                                                DateTime.parse(
                                                  widget
                                                      .data.last['priodeAkhir'],
                                                ),
                                              )
                                            : 'No Data',
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                          initialValue: widget.data.last['status'],
                          autocorrect: false,
                          readOnly: true,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: widget.data.last['status'] ==
                                              'VERIFIED PENDING PAYMENT' ||
                                          widget.data.last['status'] ==
                                              'VERIFIED PAYMENT'
                                      ? Colors.blue
                                      : widget.data.last['status'] == 'APPROVED'
                                          ? Colors.green
                                          : widget.data.last['status'] ==
                                                      'REJECTED' ||
                                                  widget.data.last['status'] ==
                                                      'VOID'
                                              ? Colors.red
                                              : Colors.black,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: widget.data.last['status'] ==
                                              'VERIFIED PENDING PAYMENT' ||
                                          widget.data.last['status'] ==
                                              'VERIFIED PAYMENT'
                                      ? Colors.blue
                                      : widget.data.last['status'] == 'APPROVED'
                                          ? Colors.green
                                          : widget.data.last['status'] ==
                                                      'REJECTED' ||
                                                  widget.data.last['status'] ==
                                                      'VOID'
                                              ? Colors.red
                                              : Colors.black,
                                ),
                              ),
                              suffixIcon: IconButton(
                                  onPressed: loading
                                      ? null
                                      : level == 19
                                          ? null
                                          : () async {
                                              Navigator.of(context).push(
                                                  MaterialPageRoute(builder:
                                                      (BuildContext context) {
                                                return PaymentMstAgreement(
                                                    data: widget.data);
                                              }));
                                            },
                                  icon: Icon(
                                    Icons.arrow_circle_right,
                                    color: level == 19 ? null : Colors.green,
                                    size: size.height * 0.05,
                                  ))),
                        ),
                        SizedBox(height: size.height * 0.015),
                        TextButton(
                            onPressed: () async {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (BuildContext context) {
                                return AttachmentMstagreement(data: widget.data);
                              }));
                            },
                            child:  Row(
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
                                const Icon(
                                  Icons.arrow_forward,
                                )
                              ],
                            )),
                        SizedBox(height: size.height * 0.02),
                        const Text("Schedule:"),
                        SizedBox(
                          height: jadwal.isEmpty
                              ? size.height * 0.25
                              : jadwal.length < 5
                                  ? ((MediaQuery.of(context)
                                                  .textScaler
                                                  .scale(14) +
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
                              child: loading
                                  ? const Text('Waiting...')
                                  : const Text('No Data'),
                            ),
                            columns: const [
                              DataColumn2(
                                size: ColumnSize.S,
                                label: Center(
                                  child: Text(
                                    'No',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              DataColumn2(
                                size: ColumnSize.L,
                                label: Center(
                                  child: Text(
                                    'No Agreement',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              DataColumn2(
                                size: ColumnSize.M,
                                label: Center(
                                  child: Text(
                                    'Route',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              DataColumn2(
                                size: ColumnSize.L,
                                label: Center(
                                    child: Text(
                                  'Fee',
                                  textAlign: TextAlign.center,
                                )),
                              ),
                              DataColumn2(
                                size: ColumnSize.M,
                                label: Center(
                                  child: Text(
                                    'Currency',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              DataColumn2(
                                size: ColumnSize.M,
                                label: Center(
                                  child: Text(
                                    'Aircraft Type',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              DataColumn2(
                                size: ColumnSize.M,
                                label: Center(
                                  child: Text(
                                    'Second Route',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                            source: TableData(
                              jadwal: jadwal,
                              currentPage: currentPage,
                              rowsPerPage: rowPerPages,
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.015),
                      ],
                    ),
                  ),
          ],
        ),
        persistentFooterButtons: widget.data.last['status']=='void'
        ?[
                Center(
                  child: Text(
                    widget.data.last['status'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
            : level == 12
                ? (widget.data.last['status'] == 'VERIFIED PAYMENT' ||
                            widget.data.last['status'] == 'APPROVED' ||
                            widget.data.last['status'] == 'REJECTED') &&
                        isBalance
                    ? (widget.data.last['status'] == 'APPROVED' ||
                                widget.data.last['status'] == 'REJECTED') &&
                            !isBalance
                        ? [
                            Center(
                              child: Text(
                                widget.data.last['status'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.data.last['status'] ==
                                          'VERIFIED PAYMENT'
                                      ? Colors.blue
                                      : widget.data.last['status'] == 'APPROVED'
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
                                widget.data.last['status'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.data.last['status'] ==
                                          'VERIFIED PAYMENT'
                                      ? Colors.blue
                                      : widget.data.last['status'] == 'APPROVED'
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
                                    Size(size.width * 0.4, size.height * 0.08),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: loading
                                  ? null
                                  : () async {
                                      if (double.parse(widget.data.last['biaya']
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
                                            return VerificationMstagreement(
                                              item: (value) {
                                                setState(() {
                                                  item = value;
                                                });
                                              },
                                              data: widget.data,
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
                    ? widget.data.last['status'] == 'APPROVED' //||
                        // widget.iom.last['status'] == 'REJECTED' ||
                        // widget.iom.last['status'] == 'NONE'
                        ? [
                            Center(
                              child: Text(
                                widget.data.last['status'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.data.last['status'] == 'APPROVED'
                                      ? Colors.green
                                      : widget.data.last['status'] == 'REJECTED'
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
                                        size.width * 0.9, size.height * 0.08),
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          // setState(() {
                                          //   status = 'APPROVE';
                                          // });

                                          // await showDialog(
                                          //   context: context,
                                          //   builder: (BuildContext context) {
                                          //     List flightDate = [];

                                          //     for (var data in jadwal) {
                                          //       String tanggal =
                                          //           data['tanggal'];
                                          //       if (!flightDate
                                          //           .contains(tanggal)) {
                                          //         flightDate.add(tanggal);
                                          //       }
                                          //     }

                                          //     return ApprovalAgreementDetail(
                                          //       text: status,
                                          //       agreementDetail: widget.data,
                                          //       dataItem: jadwal,
                                          //       flightDate: flightDate,
                                          //     );
                                          //   },
                                          // );
                                        },
                                  child: const Text('Approval'),
                                ),
                              ],
                            ),
                          ]
                    : [
                        Center(
                          child: Text(
                            widget.data.last['status'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.data.last['status'] == 'NONE'
                                  ? Colors.black
                                  : widget.data.last['status'] ==
                                              'VERIFIED PAYMENT' ||
                                          widget.data.last['status'] ==
                                              'VERIFIED PENDING PAYMENT'
                                      ? Colors.blue
                                      : widget.data.last['status'] == 'APPROVED'
                                          ? Colors.green
                                          : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
        persistentFooterAlignment: AlignmentDirectional.center,
        );
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
          return Colors.grey;
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
        DataCell(Center(
            child: Text(
          data['noAgreement'],
          textAlign: TextAlign.center,
        ))),
        DataCell(
          Center(
            child: Text(
              data['route'],
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              NumberFormat('#,##0.00', 'id_ID')
                  .format(double.parse(data['fee'].toString()))
                  .replaceFirst('.', ','), // Ubah desimal dari '.' ke ','
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data['currency'],
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data['typepesawat'],
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data['routekedua'],
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
