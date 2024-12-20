
// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously



import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data_table_2/data_table_2.dart';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iomweb/backend/constants.dart';
import 'package:iomweb/screens/display/img.dart';
import 'package:iomweb/screens/display/pdf.dart';
import 'package:iomweb/widgets/alertdialog/attach.dart';
import 'package:iomweb/widgets/alertdialog/log_error.dart';
import 'package:iomweb/widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;

class AttachmentDetailAgreement extends StatefulWidget {
  final List agreementdetail;


  const AttachmentDetailAgreement({
    super.key,
    required this.agreementdetail
    
    });

  @override
  State<AttachmentDetailAgreement> createState() => _AttachmentDetailAgreementState();
}

class _AttachmentDetailAgreementState extends State<AttachmentDetailAgreement> {
  bool loading = false;
  bool _isConnected = false;
  bool visible = true;
  bool _sortAscending = true;
  List att = [];
  List attFile = [];
  String level = '';
  int _sortColumnIndex = 0;
  int rowPerPages = PaginatedDataTable.defaultRowsPerPage;
  int currentPage = 1;
  


Future<void> getAttName() async{
  try{
    setState(() {
      loading = true;
    });

    final soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          ' <GetAgreementAttachmentName xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.agreementdetail.last['noAgreementdetail']}</NoAgreementDetail>' +
          '<server>${widget.agreementdetail.last['server']}</server>' +
          '<level>$level</level>' +
          '</GetAgreementAttachmentName>' +
          '</soap:Body>' +
          '</soap:Envelope>';

    

    final response = await http.post(Uri.parse(url_GetAgreementAttachmentName),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetAgreementAttachmentName',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final listResultAll = document.findAllElements('Table');
        for (final listResult in listResultAll) {
          final statusData = listResult.findAllElements('StatusData').isEmpty
              ? 'No Data'
              : listResult.findAllElements('StatusData').first.innerText;

          if (statusData == "GAGAL") {
            Future.delayed(const Duration(seconds: 1), () {
              StatusAlert.show(
    
                context,
                duration: const Duration(seconds: 1),
                configuration:
                    const IconConfiguration(icon: Icons.error, color: Colors.red),
                title: 'NO DATA',
                backgroundColor: Colors.grey[300],
              );

              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            });
          } else {
            final fileName = listResult.findElements('Filename').isEmpty
                ? 'No Data'
                : listResult.findElements('Filename').first.innerText;
            final uploadedDate = listResult.findElements('UploadedDate').isEmpty
                ? 'No Data'
                : listResult.findElements('UploadedDate').first.innerText;
            final ext = listResult.findElements('Ext').isEmpty
                ? 'No Data'
                : listResult.findElements('Ext').first.innerText;
            final attachmentType =
                listResult.findElements('attachmentType').isEmpty
                    ? 'No Data'
                    : listResult.findElements('attachmentType').first.innerText;
            final item = listResult.findElements('Item').isEmpty
                ? 'No Data'
                : listResult.findElements('Item').first.innerText;

            setState(() {
              att.add({
                'item': item,
                'fileName': fileName,
                'date': uploadedDate,
                'ext': ext.toLowerCase(),
                'attachmentType': attachmentType,
              });
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
              builder: (BuildContext contex) {
                return LogError(
                    statusCode: response.statusCode.toString(),
                    fail: "Eror Get Attachment Name",
                    error: response.body.toString());
              });
          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                  statusCode: '',
                  fail: "Error Get Attachment Name",
                  error: e.toString());
            });
        setState(() {
          loading = false;
        });
      }
    }
  }

Future<void> getAttAgreement(index) async{
  try{
    setState(() {
      loading = true;
    });

    final soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetAgreementAttachment xmlns="http://tempuri.org/">' +
          '<NoAgreementDetail>${widget.agreementdetail.last['noAgreementdetail']}</NoAgreementDetail>' +
          '<Item>${att[index]['item']}</Item>' +
          '<attachmentType>${att[index]['attachmentType']}</attachmentType>' +
          '<server>${widget.agreementdetail.last['server']}</server>' +
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
          final statusData = listResult.findAllElements('StatusData').isEmpty
              ? 'No Data'
              : listResult.findAllElements('StatusData').first.text;

          if (statusData == "GAGAL") {
            Future.delayed(const Duration(seconds: 1), () {
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 1),
                configuration:
                    const IconConfiguration(icon: Icons.error, color: Colors.red),
                title: 'NO DATA',
                backgroundColor: Colors.grey[300],
              );

              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            });
          } else {
            final noAgreementdetail = listResult.findElements('NoAgreementDetail').isEmpty
                ? 'No Data'
                : listResult.findElements('NoAgreementDetail').first.innerText;
            final filename = listResult.findElements('Filename').isEmpty
                ? 'No Data'
                : listResult.findElements('Filename').first.innerText;
            final pdfFile = listResult.findElements('PDFFile').isEmpty
                ? 'No Data'
                : listResult.findElements('PDFFile').first.innerText;
            final ext = listResult.findElements('Ext').isEmpty
                ? 'No Data'
                : listResult.findElements('Ext').first.innerText;
            final attachmentType =
                listResult.findElements('attachmentType').isEmpty
                    ? 'No Data'
                    : listResult.findElements('attachmentType').first.innerText;


            setState(() {
              attFile.add({
                'noAgreeementDetail': noAgreementdetail,
                'filename': filename,
                'pdf': pdfFile,
                'ext': ext.toLowerCase(),
                'attachmentType': attachmentType,
              });
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
              builder: (BuildContext contex) {
                return LogError(
                    statusCode: response.statusCode.toString(),
                    fail: "Eror Get Attachment Agreement",
                    error: response.body.toString());
              });
          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                  statusCode: '',
                  fail: "Error Get Attachment Agreement",
                  error: e.toString());
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
      await initConnection();
      await getLevel();
      await getAttName();
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
          "Detail Attachment",
        ),
        elevation: 3,
        actions: [
          level=='12'|| level=='19'?
          IconButton(
            tooltip: 'Add Attachment',
            onPressed: loading? null :
            (){
              setState(() {
                loading = false;
              });

              Future.delayed(const Duration(seconds: 1), () async{

                if(mounted){
                  setState(() {
                  loading = false;
                });

                showDialog(
                  context: context, 
                  builder: (BuildContext context){
                    return Attachment(
                      isSuccess: (value) async{
                        if (value) {
                          Navigator.of(context).pop();
                           setState(() {
                             loading = true;
                             att.clear();
                               });
                              }

                              await getAttName();

                        
                      }, 
                      iom: widget.agreementdetail
                      );
                  }
                  );
                
              
                }

                
                }


              
              );
            }, 
            icon:const Icon(
              Icons.add,
              color: Colors.black,
              
            ),
            ):const SizedBox.shrink(),
            IconButton(

              tooltip: 'Refresh',
              onPressed: loading?null:
              () async{
                setState(() {
                  loading = true;
                });

                await getAttName();

              }, 
              icon: const Icon(Icons.refresh),
              )


        ],

      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: att.isEmpty?size.height*0.25 :att.length<5
                  ?((MediaQuery.of(context).textScaleFactor * 14 +
                                      2 * 18) *
                                  att.length) +
                              2 * size.height * 0.085
                              : size.height*0.4,
                  child: PaginatedDataTable2(
                    border: TableBorder.all(width: 1),
                    minWidth: 500,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    rowsPerPage: rowPerPages,
                    onRowsPerPageChanged: (value){
                      rowPerPages = value!;
                    },
                    sortArrowIcon: Icons.keyboard_arrow_up,
                    smRatio: 0.35,
                    lmRatio: 1.4,
                    renderEmptyRowsInTheEnd: false,
                    showFirstLastButtons: true,
                    horizontalMargin: size.width*0,
                    columnSpacing: 15,
                    empty: Center(
                      child: loading? const Text('Waiting...'):const Text('No Data')
                    ),


                    columns:[
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
                                  return a['fileName'].compareTo(b['fileName']);
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
                              att.sort((a, b) {
                                // Mendapatkan tanggal dari data a dan b dalam format DateTime
                                DateTime dateA = DateTime.parse(a['date']);
                                DateTime dateB = DateTime.parse(b['date']);

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
                              att.sort((a, b) {
                                DateTime dateA = DateTime.parse(a['date']);
                                DateTime dateB = DateTime.parse(b['date']);

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
                      action: (index) async{
                        setState(() {
  attFile.clear();
  loading = true;
});                     
                      await getAttAgreement(index);
                      Future.delayed(const Duration(seconds: 1), () async{
                        if(attFile.isNotEmpty){
                          if(attFile.last['ext'].toString().contains('pdf')){
                            Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context){
                              return DisplayPDF(pdf: attFile);
                            }));

                          }else if (attFile.last['ext']
                                    .toString()
                                    .contains('jpg') ||
                                attFile.last['ext']
                                    .toString()
                                    .contains('jpeg') ||
                                attFile.last['ext']
                                    .toString()
                                    .contains('png')){
                                      Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context){
                                        return DisplayIMG(image: attFile);
                                      }));
                                    }else{
                                      StatusAlert.show(
                                        context,
                                        duration: const Duration(seconds: 1),
                                        configuration: const IconConfiguration(
                                          icon: Icons.error,color: Colors.red
                                        ),
                                        title: "No Data",
                                        backgroundColor: Colors.grey[300],
                                      );
                                    }
                        }
                      }
                      );



                      }
                      )
                    
                    ),
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
                data['fileName'],
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        DataCell(
          Center(
            child: data['date'] == 'No Data'
                ? const Text(
                    'No Data',
                    textAlign: TextAlign.center,
                  )
                : Text(
                    DateFormat('dd-MMM-yyyy').format(
                      DateTime.parse(
                        data['date'],
                      ).toLocal(),
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
        DataCell(
          SingleChildScrollView(
            child: Center(
              child: Text(
                data['attachmentType'],
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