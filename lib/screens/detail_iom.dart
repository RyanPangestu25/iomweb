// ignore_for_file: prefer_typing_uninitialized_variables, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../backend/constants.dart';
import '../screens/attachment.dart';
import '../screens/payment.dart';
import '../screens/view_iom.dart';
import '../widgets/alertdialog/confirmation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/alertdialog/verification.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../widgets/loading.dart';

class DetailIOM extends StatefulWidget {
  final List iom;

  const DetailIOM({
    super.key,
    required this.iom,
  });

  @override
  State<DetailIOM> createState() => _DetailIOMState();
}

class _DetailIOMState extends State<DetailIOM> {
  bool _isConnected = false;
  bool visible = true;
  bool loading = false;
  bool _sortAscending = true;
  bool isBalance = false;
  String status = '';
  int level = 0;
  int _sortColumnIndex = 0;
  int currentPage = 1;
  int rowPerPages = PaginatedDataTable.defaultRowsPerPage;
  int item = 0;
  List jadwal = [];
  List att = [];

  Future<void> getIOMItem() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetIOMItem xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<server>${widget.iom.last['server']}</server>' +
          '</GetIOMItem>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetIOMItem),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetIOMItem',
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
            final tanggal = listResult.findElements('Tanggal').isEmpty
                ? 'No Data'
                : listResult.findElements('Tanggal').first.text;
            final rute = listResult.findElements('Rute').isEmpty
                ? 'No Data'
                : listResult.findElements('Rute').first.text;
            final blockTime = listResult.findElements('BlockTime').isEmpty
                ? 'PT0M'
                : listResult.findElements('BlockTime').first.text;
            final keterangan = listResult.findElements('Keterangan').isEmpty
                ? 'No Data'
                : listResult.findElements('Keterangan').first.text;
            final flightNumber = listResult.findElements('FlightNumber').isEmpty
                ? 'No Data'
                : listResult.findElements('FlightNumber').first.text;
            final airlineCode = listResult.findElements('AirlineCode').isEmpty
                ? 'No Data'
                : listResult.findElements('AirlineCode').first.text;

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
                  'noIOM': noIOM,
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

            var hasilJson = jsonEncode(jadwal);
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
          subtitle: "Error Get IOM Item",
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
        title: "Error Get IOM Item",
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
              double.parse(total) >= double.parse(widget.iom.last['biaya'])
                  ? isBalance = true
                  : false;
            });

            debugPrint('$item');
            debugPrint(total);

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

  Future<void> getLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userLevel = prefs.getString('userLevel');

    setState(() {
      level = int.parse(userLevel ?? '0');
      debugPrint(level.toString());
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initConnection();
      await getLevel();
      await getIOMItem();
      await cekSaldoIOM();
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
          "Detail IOM",
        ),
        elevation: 3,
        leading: IconButton(
          onPressed: () async {
            if (level == 12) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) {
                  return const ViewIOM(
                    title: 'IOM Verification',
                  );
                },
              ));
            } else if (level == 10) {
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
          },
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loading
                ? null
                : () async {
                    setState(() {
                      loading = true;
                    });
                    jadwal.clear();
                    await getIOMItem();
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
                  "IOM No",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                TextFormField(
                  initialValue: widget.iom.last['noIOM'],
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
                  "Charter",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                TextFormField(
                  initialValue: widget.iom.last['charter'],
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
                  "Date",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                TextFormField(
                  initialValue: DateFormat('dd-MMM-yyyy').format(
                      DateTime.parse(widget.iom.last['tanggal']).toLocal()),
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
                TextFormField(
                  initialValue: widget.iom.last['perihal'],
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
                  "Cost",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                TextFormField(
                  initialValue: widget.iom.last['curr'] +
                      ' ' +
                      NumberFormat.currency(locale: 'id_ID', symbol: '')
                          .format(
                            double.parse(
                                widget.iom.last['biaya'].replaceAll(',', '.')),
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
                  "Payment",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                TextFormField(
                  initialValue: widget.iom.last['pembayaran'],
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
                  initialValue: widget.iom.last['note'],
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
                  initialValue: widget.iom.last['status'],
                  autocorrect: false,
                  readOnly: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 2,
                        color: widget.iom.last['status'] ==
                                    'VERIFIED PENDING PAYMENT' ||
                                widget.iom.last['status'] == 'VERIFIED PAYMENT'
                            ? Colors.blue
                            : widget.iom.last['status'] == 'APPROVED'
                                ? Colors.green
                                : widget.iom.last['status'] == 'REJECTED'
                                    ? Colors.red
                                    : Colors.black,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 2,
                        color: widget.iom.last['status'] ==
                                    'VERIFIED PENDING PAYMENT' ||
                                widget.iom.last['status'] == 'VERIFIED PAYMENT'
                            ? Colors.blue
                            : widget.iom.last['status'] == 'APPROVED'
                                ? Colors.green
                                : widget.iom.last['status'] == 'REJECTED'
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
                  initialValue: widget.iom.last['verifNoPayStatus'] == 'No Data'
                      ? widget.iom.last['verifNoPayStatus']
                      : DateFormat('dd-MMM-yyyy').format(
                          DateTime.parse(widget.iom.last['verifNoPayStatus'])
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
                  initialValue: widget.iom.last['verifPayStatus'] == 'No Data'
                      ? widget.iom.last['verifPayStatus']
                      : DateFormat('dd-MMM-yyyy').format(
                          DateTime.parse(widget.iom.last['verifPayStatus'])
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
                  initialValue: widget.iom.last['approveDate'] == 'No Data'
                      ? widget.iom.last['approveDate']
                      : DateFormat('dd-MMM-yyyy').format(
                          DateTime.parse(widget.iom.last['approveDate'])
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
                  initialValue: widget.iom.last['payStatus'],
                  autocorrect: false,
                  readOnly: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 2,
                        color: widget.iom.last['payStatus'] == 'PAID'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 2,
                        color: widget.iom.last['payStatus'] == 'PAID'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    suffixIcon: IconButton(
                      onPressed: loading
                          ? null
                          : () async {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) {
                                  return Payment(
                                    iom: widget.iom,
                                  );
                                },
                              ));
                            },
                      icon: Icon(
                        Icons.arrow_circle_right,
                        color: Colors.green,
                        size: size.height * 0.05,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) {
                        return IOMAttachment(
                          iom: widget.iom,
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
                          fontSize: MediaQuery.of(context).textScaleFactor * 16,
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
                          ? ((MediaQuery.of(context).textScaleFactor * 14 +
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
                            'Date',
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
                              jadwal
                                  .sort((a, b) => b['ket'].compareTo(a['ket']));
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
                              jadwal.sort((a, b) =>
                                  b['airlineCode'].compareTo(a['airlineCode']));
                            }
                          });
                        },
                      ),
                    ],
                    source: TableData(
                      jadwal: jadwal,
                      currentPage: currentPage,
                      rowsPerPage: rowPerPages,
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
      persistentFooterButtons: level == 12
          ? (widget.iom.last['status'] == 'VERIFIED PAYMENT' ||
                      widget.iom.last['status'] == 'APPROVED' ||
                      widget.iom.last['status'] == 'REJECTED') &&
                  isBalance
              ? (widget.iom.last['status'] == 'APPROVED' ||
                          widget.iom.last['status'] == 'REJECTED') &&
                      !isBalance
                  ? [
                      Center(
                        child: Text(
                          widget.iom.last['status'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                widget.iom.last['status'] == 'VERIFIED PAYMENT'
                                    ? Colors.blue
                                    : widget.iom.last['status'] == 'APPROVED'
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
                          widget.iom.last['status'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                widget.iom.last['status'] == 'VERIFIED PAYMENT'
                                    ? Colors.blue
                                    : widget.iom.last['status'] == 'APPROVED'
                                        ? Colors.green
                                        : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
              : [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(size.width, size.height * 0.08),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: loading
                        ? null
                        : () async {
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Verification(
                                  item: (value) {
                                    setState(() {
                                      item = value;
                                    });
                                  },
                                  iom: widget.iom,
                                  lastItem: item,
                                );
                              },
                            );
                          },
                    child: const Text('Verification'),
                  )
                ]
          : level == 10
              ? widget.iom.last['status'] == 'APPROVED' ||
                      widget.iom.last['status'] == 'REJECTED' ||
                      widget.iom.last['status'] == 'NONE'
                  ? [
                      Center(
                        child: Text(
                          widget.iom.last['status'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.iom.last['status'] == 'APPROVED'
                                ? Colors.green
                                : widget.iom.last['status'] == 'REJECTED'
                                    ? Colors.red
                                    : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
                  : [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                                    setState(() {
                                      status = 'APPROVE';
                                    });

                                    await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Confirmation(
                                          text: status,
                                          iom: widget.iom,
                                        );
                                      },
                                    );
                                  },
                            child: const Text('Approval'),
                          ),
                          SizedBox(width: size.width * 0.02),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              fixedSize:
                                  Size(size.width * 0.4, size.height * 0.08),
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
                                          iom: widget.iom,
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
                      widget.iom.last['status'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.iom.last['status'] == 'NONE'
                            ? Colors.black
                            : widget.iom.last['status'] == 'VERIFIED PAYMENT' ||
                                    widget.iom.last['status'] ==
                                        'VERIFIED PENDING PAYMENT'
                                ? Colors.blue
                                : widget.iom.last['status'] == 'APPROVED'
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