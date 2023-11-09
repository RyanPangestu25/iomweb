// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/constants.dart';
import '../widgets/loading.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'display/img.dart';
import 'display/pdf.dart';

class Payment extends StatefulWidget {
  final List iom;

  const Payment({
    super.key,
    required this.iom,
  });

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  bool _isConnected = false;
  bool visible = true;
  bool loading = false;
  bool _sortAscending = true;
  int _sortColumnIndex = 0;
  int currentPage = 1;
  int rowPerPages = PaginatedDataTable.defaultRowsPerPage;
  List payment = [];
  List att = [];

  Future<void> getIOMPayment() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetIOMPayment xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<server>${widget.iom.last['server']}</server>' +
          '</GetIOMPayment>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetIOMPayment),
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
            final item = listResult.findElements('Item').isEmpty
                ? 'No Data'
                : listResult.findElements('Item').first.text;
            final tglTerimaPembayaran = listResult
                    .findElements('Tgl_TerimaPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult.findElements('Tgl_TerimaPembayaran').first.text;
            final namaBankPenerima =
                listResult.findElements('NamaBankPenerima').isEmpty
                    ? 'No Data'
                    : listResult.findElements('NamaBankPenerima').first.text;
            final amountPembayaran =
                listResult.findElements('AmountPembayaran').isEmpty
                    ? '0'
                    : listResult.findElements('AmountPembayaran').first.text;
            final currPembayaran =
                listResult.findElements('CurrPembayaran').isEmpty
                    ? '0'
                    : listResult.findElements('CurrPembayaran').first.text;

            setState(() {
              payment.add({
                'noIOM': noIOM,
                'item': item,
                'tanggal': tglTerimaPembayaran,
                'bank': namaBankPenerima,
                'amount': amountPembayaran,
                'curr': currPembayaran,
              });
            });

            var hasilJson = jsonEncode(payment);
            debugPrint(hasilJson);

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
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          title: "${response.statusCode}",
          subtitle: "Error Get IOM Payment",
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
        title: "Error Get IOM Payment",
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

  Future<void> getIOMAttachment(index) async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetIOMAttachment xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<Item>${payment[index]['item']}</Item>' +
          '<server>${widget.iom.last['server']}</server>' +
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
              att.add({
                'noIOM': noIOM,
                'filename': filename,
                'pdf': pdfFile,
                'ext': ext,
                'attachmentType': attachmentType,
              });
            });

            var hasilJson = jsonEncode(att);
            debugPrint(hasilJson);

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

  Future<void> initConnection() async {
    Connectivity().checkConnectivity().then((value) {
      debugPrint('$value');
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
      await initConnection();
      await getIOMPayment();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double totalAmount = 0.0;
    for (int i = 0; i < payment.length; i++) {
      totalAmount += double.parse(payment[i]['amount']);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        title: const Text(
          "Detail Payment",
        ),
        elevation: 3,
        actions: [
          IconButton(
            onPressed: loading
                ? null
                : () async {
                    setState(() {
                      loading = true;
                    });
                    payment.clear();
                    await getIOMPayment();
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
                Text.rich(
                  TextSpan(
                    text: 'Total Amount = ',
                    children: [
                      TextSpan(
                        text: NumberFormat.currency(locale: 'id_ID', symbol: '')
                            .format(totalAmount)
                            .toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: size.height * 0.023,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                SizedBox(
                  height: payment.isEmpty
                      ? size.height * 0.25
                      : payment.length < 5
                          ? ((MediaQuery.of(context).textScaleFactor * 14 +
                                      2 * 18) *
                                  payment.length) +
                              2 * size.height * 0.085
                          : size.height * 0.4,
                  child: PaginatedDataTable2(
                    border: TableBorder.all(width: 1),
                    minWidth: 600,
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Payment',
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Date',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            _sortColumnIndex = columnIndex;
                            _sortAscending = ascending;
                            if (ascending) {
                              payment.sort((a, b) {
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
                              payment.sort((a, b) {
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Bank',
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Name',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const DataColumn2(
                        size: ColumnSize.S,
                        label: Center(
                          child: Text(
                            'Currency',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn2(
                        size: ColumnSize.M,
                        label: const Center(
                          child: Text(
                            'Amount',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            _sortColumnIndex = columnIndex;
                            _sortAscending = ascending;
                            if (ascending) {
                              payment.sort(
                                (a, b) {
                                  double balA = double.parse(a['amount']);
                                  double balB = double.parse(b['amount']);

                                  return balA.compareTo(balB);
                                },
                              );
                            } else {
                              payment.sort((a, b) {
                                double balA = double.parse(a['amount']);
                                double balB = double.parse(b['amount']);

                                return balB.compareTo(balA);
                              });
                            }
                          });
                        },
                      ),
                      const DataColumn2(
                        size: ColumnSize.M,
                        label: Center(
                          child: Text(
                            'Attachment',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    source: TableData(
                      payment: payment,
                      currentPage: currentPage,
                      rowsPerPage: rowPerPages,
                      action: (index) async {
                        setState(() {
                          att.clear();
                          loading = true;
                        });

                        await getIOMAttachment(index);

                        Future.delayed(const Duration(seconds: 1), () async {
                          if (att.isNotEmpty) {
                            if (att.last['ext'].toString().contains('pdf')) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) {
                                  return DisplayPDF(
                                    pdf: att,
                                  );
                                },
                              ));
                            } else if (att.last['ext']
                                    .toString()
                                    .contains('jpg') ||
                                att.last['ext'].toString().contains('jpeg') ||
                                att.last['ext'].toString().contains('png')) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) {
                                  return DisplayIMG(
                                    image: att,
                                  );
                                },
                              ));
                            }
                          } else {
                            StatusAlert.show(
                              context,
                              duration: const Duration(seconds: 1),
                              configuration: const IconConfiguration(
                                  icon: Icons.error, color: Colors.red),
                              title: "No Data",
                              backgroundColor: Colors.grey[300],
                            );
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: visible,
            child: Container(
              color: _isConnected ? Colors.green : Colors.red,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isConnected ? 'ONLINE' : 'OFFLINE',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: size.width * 0.01),
                  _isConnected
                      ? const SizedBox.shrink()
                      : const SizedBox(
                          height: 15,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.blue,
                          ),
                        ),
                ],
              ),
            ),
          ),
          LoadingWidget(isLoading: loading),
        ],
      ),
    );
  }
}

class TableData extends DataTableSource {
  final List payment;
  final int currentPage;
  final int rowsPerPage;
  final Function(int) action;

  TableData({
    required this.payment,
    required this.currentPage,
    required this.rowsPerPage,
    required this.action,
  });

  @override
  DataRow? getRow(int index) {
    assert(index >= 0);

    if (index >= payment.length) throw 'index > ${payment.length}';

    final dataIndex =
        (index + (currentPage - 1) * rowsPerPage).clamp(0, payment.length - 1);
    final data = payment[dataIndex];

    return DataRow2(
      color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
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
            child: data['tglTerimaPembayaran'] == 'No Data'
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
              data['bank'],
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              data['curr'],
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              NumberFormat.currency(locale: 'id_ID', symbol: '')
                  .format(double.parse(data['amount']))
                  .toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Center(
            child: IconButton(
              onPressed: () async {
                action(index);
              },
              icon: const Icon(
                Icons.photo_library,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => payment.length;

  @override
  int get selectedRowCount => 0;
}
