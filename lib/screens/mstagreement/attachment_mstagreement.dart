// ignore_for_file: prefer_typing_uninitialized_variables, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:iomweb/backend/constants.dart';
import 'package:iomweb/screens/display/img.dart';
import 'package:iomweb/screens/display/pdf.dart';
import 'package:iomweb/widgets/alertdialog/attach.dart';
import 'package:iomweb/widgets/alertdialog/log_error.dart';
import 'package:http/http.dart' as http;
import 'package:iomweb/widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;

class AttachmentMstagreement extends StatefulWidget {
  final List data;
  const AttachmentMstagreement({super.key, required this.data});

  @override
  State<AttachmentMstagreement> createState() => _AttachmentMstagreementState();
}

class _AttachmentMstagreementState extends State<AttachmentMstagreement> {
  String level = '';
  bool _isConnected = false;
  bool loading = false;
  bool visible = true;
  List att = [];
  int _sortColumnIndex = 0;
  int currentPage = 1;
  int rowPerPages = PaginatedDataTable.defaultRowsPerPage;
  bool _sortAscending = true;
  List attFile = [];

  Future<void> getAttName() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetMstAgreementAttachmentName xmlns="http://tempuri.org/">' +
          '<NoAgreement>${widget.data.last['noAgreement']}</NoAgreement>' +
          '<server>${widget.data.last['server']}</server>' +
          '<level>$level</level>' +
          ' </GetMstAgreementAttachmentName>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response =
          await http.post(Uri.parse(url_GetMstAgreementAttachmentName),
              headers: <String, String>{
                "Access-Control-Allow-Origin": "*",
                'SOAPAction':
                    'http://tempuri.org/GetMstAgreementAttachmentName',
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
            final noAgreement = listResult.findElements('NoAgreement').isEmpty
                ? 'No Data'
                : listResult.findElements('NoAgreement').first.innerText;
            final filename = listResult.findElements('Filename').isEmpty
                ? 'No Data'
                : listResult.findElements('Filename').first.innerText;
            final jenisAtt = listResult.findElements('JenisAttachment').isEmpty
                ? 'No Data'
                : listResult.findElements('JenisAttachment').first.text;
            final fileupload = listResult.findElements('FileUpload').isEmpty
                ? 'No Data'
                : listResult.findElements('FileUpload').first.text;
            final ext = listResult.findElements('Ext').isEmpty
                ? 'No Data'
                : listResult.findElements('Ext').first.text;
            final id = listResult.findElements('Id').isEmpty
                ? 'No Data'
                : listResult.findElements('Id').first.text;

            setState(() {
              att.add({
                'noAgreement': noAgreement,
                'filename': filename,
                'jenisAtt': jenisAtt,
                'fileupload': fileupload,
                'ext': ext,
                'id': id
              });
            });

            // var hasilJson = jsonEncode(att);
            //debugPrint(hasilJson);

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
        //debugPrint('Error: ${response.statusCode}');
        //debugPrint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Error Get Attachment Name',
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
                fail: 'Error Get Attachment Name',
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
      //debugPrint('$value');
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
  Future<void> getMstAgreementAttachment(index) async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetMstAgreementAttachment xmlns="http://tempuri.org/">' +
          '<NoAgreement>${widget.data.last['noAgreement']}</NoAgreement>' +
          '<id>${att[index]['id']}</id>' +
          '<JenisAttachment>${att[index]['jenisAtt']}</JenisAttachment>' +
          '<server>${widget.data.last['server']}</server>' +
          '</GetMstAgreementAttachment>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetMstAgreementAttachment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetMstAgreementAttachment',
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
            final noAgreement = listResult.findElements('NoAgreement').isEmpty
                ? 'No Data'
                : listResult.findElements('NoAgreement').first.innerText;
            final filename = listResult.findElements('Filename').isEmpty
                ? 'No Data'
                : listResult.findElements('Filename').first.innerText;
            final pdf = listResult.findElements('FileUpload').isEmpty
                ? 'No Data'
                : listResult.findElements('FileUpload').first.innerText;
            final ext = listResult.findElements('Ext').isEmpty
                ? 'No Data'
                : listResult.findElements('Ext').first.innerText;
            final attachmentType = listResult
                    .findElements('JenisAttachment')
                    .isEmpty
                ? 'No Data'
                : listResult.findElements('JenisAttachment').first.innerText;

            setState(() {
              attFile.add({
                'noAgreement': noAgreement,
                'filename': filename,
                'pdf': pdf,
                'ext': ext.toLowerCase(),
                'jenisAttachment': attachmentType,
              });
            });

            //debugPrint(hasilJson);

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
        //debugPrint('Error: ${response.statusCode}');
        //debugPrint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Error Get IOM Attachment',
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

  Future<void> getLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userLevel = prefs.getString('userLevel');

    setState(() {
      level = userLevel ?? 'No Data';
      //debugPrint(level);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getAttName();
      await initConnection();
      await getLevel();
    });
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
          "Detail Attachment",
        ),
        elevation: 3,
        actions: [
          level == '12' || level == '19'
              ? IconButton(
                  tooltip: 'Add Attachment',
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() {
                            loading = true;
                          });

                          Future.delayed(const Duration(seconds: 1), () async {
                            if (mounted) {
                              setState(() {
                                loading = false;
                              });
                            }

                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Attachment(
                                    isSuccess: (value) async {
                                      if (value) {
                                        Navigator.of(context).pop();

                                        setState(() {
                                          loading = true;
                                          att.clear();
                                        });

                                        await getAttName();
                                      }
                                    },
                                    iom: widget.data,
                                  );
                                });
                          });
                        },
                  icon: const Icon(
                    Icons.add,
                    color: Colors.black,
                  ),
                )
              : const SizedBox.shrink(),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading
                ? null
                : () async {
                    setState(() {
                      loading = true;
                      att.clear();
                    });

                    await getAttName();
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
                SizedBox(
                  height: att.isEmpty
                      ? size.height * 0.25
                      : att.length < 5
                          ? ((MediaQuery.of(context).textScaleFactor * 14 +
                                      2 * 18) *
                                  att.length) +
                              2 * size.height * 0.085
                          : size.height * 0.4,
                  child: PaginatedDataTable2(
                      border: TableBorder.all(width: 1),
                      minWidth: 500,
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      sortArrowIcon: Icons.keyboard_arrow_up,
                      smRatio: 0.35,
                      lmRatio: 1.4,
                      rowsPerPage: rowPerPages,
                      renderEmptyRowsInTheEnd: false,
                      showFirstLastButtons: true,
                      horizontalMargin: size.width * 0,
                      columnSpacing: 15,
                      onRowsPerPageChanged: (value) {
                        rowPerPages = value!;
                      },
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
                        const DataColumn2(
                            label: Center(
                          child: Text(
                            'No. Agreement',
                            textAlign: TextAlign.center,
                          ),
                        )),
                        DataColumn2(
                          size: ColumnSize.M,
                          label: const Center(
                            child: Text(
                              'Filename',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumnIndex = columnIndex;
                              _sortAscending = ascending;
                              if (ascending) {
                                att.sort(
                                  (a, b) {
                                    return a['fileName']
                                        .compareTo(b['fileName']);
                                  },
                                );
                              } else {
                                att.sort((a, b) =>
                                    b['fileName'].compareTo(a['fileName']));
                              }
                            });
                          },
                        ),
                        DataColumn2(
                          size: ColumnSize.L,
                          label: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Attachment',
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Type',
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
                                att.sort(
                                  (a, b) {
                                    return a['attachmentType']
                                        .compareTo(b['attachmentType']);
                                  },
                                );
                              } else {
                                att.sort((a, b) => b['attachmentType']
                                    .compareTo(a['attachmentType']));
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
                        att: att,
                        currentPage: currentPage,
                        rowsPerPage: rowPerPages,
                        action: (index) async {
                          setState(() {
                            attFile.clear();
                            loading = true;
                          });

                          await getMstAgreementAttachment(index);

                          Future.delayed(const Duration(seconds: 1), () async {
                            if (attFile.isNotEmpty) {
                              if (attFile.last['ext']
                                  .toString()
                                  .contains('pdf')) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return DisplayPDF(
                                      pdf: attFile,
                                    );
                                  },
                                ));
                              } else if (attFile.last['ext']
                                      .toString()
                                      .contains('jpg') ||
                                  attFile.last['ext']
                                      .toString()
                                      .contains('jpeg') ||
                                  attFile.last['ext']
                                      .toString()
                                      .contains('png')) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return DisplayIMG(
                                      image: attFile,
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
                      )),
                )
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
          LoadingWidget(
            isLoading: loading,
            title: 'Loading',
          ),
        ],
      ),
    );
  }
}

class TableData extends DataTableSource {
  final List att;
  final int currentPage;
  final int rowsPerPage;
  final Function(int) action;

  TableData({
    required this.att,
    required this.currentPage,
    required this.rowsPerPage,
    required this.action,
  });

  @override
  DataRow? getRow(int index) {
    assert(index >= 0);

    if (index >= att.length) throw 'index > ${att.length}';

    final dataIndex =
        (index + (currentPage - 1) * rowsPerPage).clamp(0, att.length - 1);
    final data = att[dataIndex];

    return DataRow2(
      color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (index.isOdd) {
          return Colors.grey.withOpacity(0.3);
        }
        return null;
      }),
      cells: <DataCell>[
        DataCell(
          Center(
            child: Text(
              (index + 1).toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          SingleChildScrollView(
            child: Center(
              child: Text(
                data['noAgreement'],
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        DataCell(
          SingleChildScrollView(
            child: Center(
              child: Text(
                data['filename'],
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        DataCell(
          SingleChildScrollView(
            child: Center(
              child: Text(
                data['jenisAtt'],
                textAlign: TextAlign.center,
              ),
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
  int get rowCount => att.length;

  @override
  int get selectedRowCount => 0;
}
