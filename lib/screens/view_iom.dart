// ignore_for_file: prefer_typing_uninitialized_variables, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/constants.dart';
import '../widgets/loading.dart';
import '../widgets/sidebar.dart';
import 'detail_iom.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class ViewIOM extends StatefulWidget {
  final String title;

  const ViewIOM({
    super.key,
    required this.title,
  });

  @override
  State<ViewIOM> createState() => _ViewIOMState();
}

class _ViewIOMState extends State<ViewIOM> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool _isConnected = false;
  bool visible = true;
  bool isClick = false;
  bool isHelp = false;
  bool isPeriod = false;
  bool isAttach = false;
  List iom = [];
  List status = [
    'NONE',
    'VERIFIED PENDING PAYMENT',
    'VERIFIED PAYMENT',
    'APPROVED',
    'REJECTED',
    'LION',
    'SAJ',
    'WINGS',
    'ANGKASA',
    'BATIK',
  ];
  ValueNotifier<List<dynamic>> filteredStatus = ValueNotifier([
    'NONE',
    'VERIFIED PENDING PAYMENT',
    'VERIFIED PAYMENT',
    'APPROVED',
    'REJECTED',
    'LION',
    'SAJ',
    'WINGS',
    'ANGKASA',
    'BATIK',
  ]);
  ValueNotifier<List<dynamic>> filteredIOM = ValueNotifier([]);

  TextEditingController searchController = TextEditingController();
  TextEditingController date = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  Future pickDateRange() async {
    DateTimeRange? newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: dateRange,
      firstDate: DateTime(1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (newDateRange == null) return; //for button X

    setState(() {
      dateRange = newDateRange;
      date.text =
          '${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.start.toString()).toLocal())} - ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.end.toString()).toLocal())}';
      isPeriod = true;
    }); //for button SAVE

    iom.clear();
    await getIOM();

    Future.delayed(const Duration(seconds: 1), () async {
      await filterDate(dateRange.start, dateRange.end);
    });
  }

  Future<void> getIOM() async {
    try {
      setState(() {
        loading = true;
      });

      const String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetIOM xmlns="http://tempuri.org/" />' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetIOM),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetIOM',
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
            final tglIOM = listResult.findElements('TglIOM').isEmpty
                ? 'No Data'
                : listResult.findElements('TglIOM').first.text;
            final perihal = listResult.findElements('Perihal').isEmpty
                ? 'No Data'
                : listResult.findElements('Perihal').first.text;
            final description = listResult.findElements('Description').isEmpty
                ? 'No Data'
                : listResult.findElements('Description').first.text;
            final typePesawat = listResult.findElements('TypePesawat').isEmpty
                ? 'No Data'
                : listResult.findElements('TypePesawat').first.text;
            final currency = listResult.findElements('Currency').isEmpty
                ? ''
                : listResult.findElements('Currency').first.text;
            final biayaCharter = listResult.findElements('BiayaCharter').isEmpty
                ? 'No Data'
                : listResult.findElements('BiayaCharter').first.text;
            final pembayaran = listResult.findElements('Pembayaran').isEmpty
                ? 'No Data'
                : listResult.findElements('Pembayaran').first.text;
            final lainLain = listResult.findElements('LainLain').isEmpty
                ? 'No Data'
                : listResult.findElements('LainLain').first.text;
            final tglFinanceverifikasiBelumterimapembayaran = listResult
                    .findElements('tgl_financeverifikasi_belumTerimaPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult
                    .findElements('tgl_financeverifikasi_belumTerimaPembayaran')
                    .first
                    .text;
            final tglFinanceverifikasiSudahterimapembayaran = listResult
                    .findElements('tgl_financeverifikasi_sudahTerimaPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult
                    .findElements('tgl_financeverifikasi_sudahTerimaPembayaran')
                    .first
                    .text;
            final tglKonfirmasiDireksi = listResult
                    .findElements('Tgl_konfirmasi_direksi')
                    .isEmpty
                ? 'No Data'
                : listResult.findElements('Tgl_konfirmasi_direksi').first.text;
            final statusKonfirmasiDireksi =
                listResult.findElements('Status_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Status_konfirmasi_direksi')
                        .first
                        .text;
            final rute = listResult.findElements('Rute').isEmpty
                ? 'No Data'
                : listResult.findElements('Rute').first.text;
            final tanggal = listResult.findElements('Tanggal').isEmpty
                ? 'No Data'
                : listResult.findElements('Tanggal').first.text;
            final server = listResult.findElements('Server').isEmpty
                ? 'No Data'
                : listResult.findElements('Server').first.text;

            setState(() {
              if (!iom.any((data) => data['noIOM'] == noIOM)) {
                iom.add({
                  'noIOM': noIOM,
                  'tanggal': tglIOM,
                  'perihal': perihal,
                  'charter': description,
                  'type': typePesawat,
                  'curr': currency,
                  'biaya': biayaCharter,
                  'pembayaran': pembayaran,
                  'note': lainLain,
                  'status': tglFinanceverifikasiBelumterimapembayaran ==
                          'No Data'
                      ? tglFinanceverifikasiSudahterimapembayaran == 'No Data'
                          ? statusKonfirmasiDireksi == 'No Data'
                              ? 'NONE'
                              : statusKonfirmasiDireksi.toUpperCase()
                          : statusKonfirmasiDireksi == 'No Data'
                              ? 'VERIFIED PAYMENT'
                              : statusKonfirmasiDireksi.toUpperCase()
                      : tglFinanceverifikasiSudahterimapembayaran == 'No Data'
                          ? statusKonfirmasiDireksi == 'No Data'
                              ? 'VERIFIED PENDING PAYMENT'
                              : statusKonfirmasiDireksi.toUpperCase()
                          : statusKonfirmasiDireksi == 'No Data'
                              ? 'VERIFIED PAYMENT'
                              : statusKonfirmasiDireksi.toUpperCase(),
                  'verifNoPayStatus': tglFinanceverifikasiBelumterimapembayaran,
                  'verifPayStatus': tglFinanceverifikasiSudahterimapembayaran,
                  'approveDate': tglKonfirmasiDireksi,
                  'payStatus': tglFinanceverifikasiBelumterimapembayaran ==
                          'No Data'
                      ? tglFinanceverifikasiSudahterimapembayaran == 'No Data'
                          ? 'PENDING'
                          : 'PAID'
                      : tglFinanceverifikasiSudahterimapembayaran == 'No Data'
                          ? 'PENDING'
                          : 'PAID',
                  'rute': rute,
                  'tanggalRute': tanggal,
                  'server': server,
                  'isAttach': '',
                });
              }
            });

            // var hasilJson = jsonEncode(iom);
            // debugPrint(hasilJson);

            Future.delayed(const Duration(seconds: 1), () async {
              setState(() {
                filteredIOM.value = iom;
              });

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
          subtitle: "Error Get IOM",
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
        title: "Error Get IOM",
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

  Future<void> filterStatus(DateTime startDate, DateTime endDate) async {
    if (isClick && !isPeriod && searchController.text.isEmpty) {
      if (filteredStatus.value.last == 'LION' ||
          filteredStatus.value.last == 'SAJ' ||
          filteredStatus.value.last == 'ANGKASA' ||
          filteredStatus.value.last == 'BATIK' ||
          filteredStatus.value.last == 'WINGS') {
        setState(() {
          filteredIOM.value = iom.where((data) {
            return data['server'] == filteredStatus.value.last;
          }).toList();
        });
      } else {
        setState(() {
          filteredIOM.value = iom.where((data) {
            return data['status'] == filteredStatus.value.last;
          }).toList();
        });
      }
    } else if (isClick && isPeriod) {
      filterDate(startDate, endDate);
    } else if (!isClick && isPeriod) {
      filterDate(startDate, endDate);
    } else if (isClick && searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else if (!isClick && searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else {
      setState(() {
        filteredIOM.value = iom;
      });
    }
  }

  Future<void> filterDate(DateTime startDate, DateTime endDate) async {
    setState(() {
      filteredIOM.value = iom.where((data) {
        final period = DateTime.parse(data['tanggal']);
        return period.isAfter(startDate) && period.isBefore(endDate) ||
            period.isAtSameMomentAs(startDate) ||
            period.isAtSameMomentAs(endDate);
      }).toList();
    });

    if (searchController.text.isNotEmpty) {
      final filteredMix = iom.where((data) {
        final noIOM = data['noIOM'].toLowerCase();
        final period = DateTime.parse(data['tanggal']);
        return noIOM.contains(searchController.text.toLowerCase()) &&
                period.isAfter(startDate) &&
                period.isBefore(endDate) ||
            noIOM.contains(searchController.text.toLowerCase()) &&
                period.isAtSameMomentAs(startDate) ||
            noIOM.contains(searchController.text.toLowerCase()) &&
                period.isAtSameMomentAs(endDate);
      }).toList();
      setState(() {
        filteredIOM.value = filteredMix;
      });
    }

    if (isClick && searchController.text.isNotEmpty) {
      if (filteredStatus.value.last == 'LION' ||
          filteredStatus.value.last == 'SAJ' ||
          filteredStatus.value.last == 'ANGKASA' ||
          filteredStatus.value.last == 'BATIK' ||
          filteredStatus.value.last == 'WINGS') {
        setState(() {
          filteredIOM.value = iom.where((data) {
            final noIOM = data['noIOM'].toLowerCase();
            final period = DateTime.parse(data['tanggal']);
            return data['server'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase()) &&
                    period.isAfter(startDate) &&
                    period.isBefore(endDate) ||
                data['server'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase()) &&
                    period.isAtSameMomentAs(startDate) ||
                data['server'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase()) &&
                    period.isAtSameMomentAs(endDate);
          }).toList();
        });
      } else {
        setState(() {
          filteredIOM.value = iom.where((data) {
            final noIOM = data['noIOM'].toLowerCase();
            final period = DateTime.parse(data['tanggal']);
            return data['status'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase()) &&
                    period.isAfter(startDate) &&
                    period.isBefore(endDate) ||
                data['status'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase()) &&
                    period.isAtSameMomentAs(startDate) ||
                data['status'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase()) &&
                    period.isAtSameMomentAs(endDate);
          }).toList();
        });
      }
    } else if (isClick && searchController.text.isEmpty) {
      if (filteredStatus.value.last == 'LION' ||
          filteredStatus.value.last == 'SAJ' ||
          filteredStatus.value.last == 'ANGKASA' ||
          filteredStatus.value.last == 'BATIK' ||
          filteredStatus.value.last == 'WINGS') {
        setState(() {
          filteredIOM.value = iom.where((data) {
            final period = DateTime.parse(data['tanggal']);
            return data['server'] == filteredStatus.value.last &&
                    period.isAfter(startDate) &&
                    period.isBefore(endDate) ||
                data['server'] == filteredStatus.value.last &&
                    period.isAtSameMomentAs(startDate) ||
                data['server'] == filteredStatus.value.last &&
                    period.isAtSameMomentAs(endDate);
          }).toList();
        });
      } else {
        setState(() {
          filteredIOM.value = iom.where((data) {
            final period = DateTime.parse(data['tanggal']);
            return data['status'] == filteredStatus.value.last &&
                    period.isAfter(startDate) &&
                    period.isBefore(endDate) ||
                data['status'] == filteredStatus.value.last &&
                    period.isAtSameMomentAs(startDate) ||
                data['status'] == filteredStatus.value.last &&
                    period.isAtSameMomentAs(endDate);
          }).toList();
        });
      }
    }
  }

  Future<void> filterSearch(String query) async {
    setState(() {
      filteredIOM.value = iom.where((data) {
        final noIOM = data['noIOM'].toLowerCase();
        return noIOM.contains(query.toLowerCase());
      }).toList();
    });

    if (isClick) {
      if (filteredStatus.value.last == 'LION' ||
          filteredStatus.value.last == 'SAJ' ||
          filteredStatus.value.last == 'ANGKASA' ||
          filteredStatus.value.last == 'BATIK' ||
          filteredStatus.value.last == 'WINGS') {
        setState(() {
          filteredIOM.value = iom.where((data) {
            final noIOM = data['noIOM'].toLowerCase();
            return data['server'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase()) ||
                data['server'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase()) ||
                data['server'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase());
          }).toList();
        });
      } else {
        setState(() {
          filteredIOM.value = iom.where((data) {
            final noIOM = data['noIOM'].toLowerCase();
            return data['status'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase()) ||
                data['status'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase()) ||
                data['status'] == filteredStatus.value.last &&
                    noIOM.contains(searchController.text.toLowerCase());
          }).toList();
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

      await getIOM();
    });

    date.text =
        '${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.start.toString()).toLocal())} - ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.end.toString()).toLocal())}';
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        drawer: loading
            ? SizedBox(
                child: Center(
                  child: Text(
                    'Please wait till the loading done',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).textScaleFactor * 20,
                    ),
                  ),
                ),
              )
            : const Sidebar(),
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          title: Text(widget.title),
          elevation: 3,
          actions: [
            IconButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() {
                        loading = true;
                        dateRange = DateTimeRange(
                          start: DateTime.now(),
                          end: DateTime.now(),
                        );
                        date.text =
                            '${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.start.toString()).toLocal())} - ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.end.toString()).toLocal())}';
                        isPeriod = false;
                        searchController.clear();
                        filteredStatus.value = status;
                      });
                      iom.clear();
                      await getIOM();
                    },
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Tips',
              onPressed: () async {
                setState(() {
                  isHelp = true;
                });

                Future.delayed(const Duration(seconds: 10), () {
                  setState(() {
                    isHelp = false;
                  });
                });
              },
              icon: const Icon(
                Icons.help_outline,
              ),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Filter by:'),
                      SizedBox(
                        height: size.height * 0.1,
                        width: size.width,
                        child: ListView.separated(
                          itemCount: filteredStatus.value.length,
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.antiAlias,
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
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          setState(() {
                                            isClick = !isClick;
                                            filteredStatus.value = isClick
                                                ? [status[index]]
                                                : status;
                                          });

                                          await filterStatus(
                                              dateRange.start, dateRange.end);
                                        },
                                  child: isClick
                                      ? Row(
                                          children: [
                                            Text(filteredStatus.value[index]),
                                            SizedBox(width: size.width * 0.01),
                                            const Icon(Icons.done),
                                          ],
                                        )
                                      : Text(filteredStatus.value[index]),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const Divider(
                        thickness: 2,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Period From - Period To'),
                          SizedBox(height: size.height * 0.01),
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
                                onPressed: loading
                                    ? null
                                    : () async {
                                        await pickDateRange();
                                      },
                                icon: Icon(
                                  Icons.calendar_month_outlined,
                                  color: loading ? null : Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text("Search"),
                      const SizedBox(height: 5),
                      Form(
                        key: _formKey,
                        child: TextField(
                          readOnly: loading,
                          focusNode: _focusNode,
                          selectionHeightStyle: BoxHeightStyle.tight,
                          controller: searchController,
                          autocorrect: false,
                          decoration: InputDecoration(
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(width: 2),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2,
                                color: Color.fromARGB(255, 4, 88, 156),
                              ),
                            ),
                            suffixIcon: searchController.text.isEmpty
                                ? const Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  )
                                : IconButton(
                                    onPressed: () async {
                                      searchController.clear();

                                      if (!isPeriod) {
                                        filterStatus(
                                            dateRange.start, dateRange.end);
                                      } else {
                                        filterDate(
                                            dateRange.start, dateRange.end);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          onChanged: (value) {
                            if (value.isEmpty) {
                              if (!isPeriod) {
                                filterStatus(dateRange.start, dateRange.end);
                              } else {
                                filterDate(dateRange.start, dateRange.end);
                              }
                            } else {
                              if (isPeriod) {
                                filterDate(dateRange.start, dateRange.end);
                              } else {
                                filterSearch(value);
                              }
                            }
                          },
                          onEditingComplete: () {
                            if (searchController.text.isEmpty) {
                              if (!isPeriod) {
                                filterStatus(dateRange.start, dateRange.end);
                              } else {
                                filterDate(dateRange.start, dateRange.end);
                              }
                            } else {
                              if (isPeriod) {
                                filterDate(dateRange.start, dateRange.end);
                              } else {
                                filterSearch(searchController.text);
                              }
                            }
                          },
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      Text('Total Data = ${filteredIOM.value.length}'),
                      SizedBox(
                        height: size.height * 0.7,
                        child: Stack(
                          children: [
                            filteredIOM.value.isEmpty
                                ? ListView.builder(
                                    itemCount: 1,
                                    itemBuilder: (BuildContext context, index) {
                                      return const Padding(
                                        padding: EdgeInsets.only(
                                          top: 8.0,
                                          bottom: 8.0,
                                        ),
                                        child: Center(
                                          child: Text('No Data'),
                                        ),
                                      );
                                    },
                                  )
                                : ListView.builder(
                                    itemCount: filteredIOM.value.length,
                                    itemBuilder: (BuildContext context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                          bottom: 8.0,
                                        ),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 10,
                                            padding: const EdgeInsets.all(6),
                                            shape: BeveledRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          onPressed: loading
                                              ? null
                                              : () async {
                                                  Navigator.of(context)
                                                      .push(MaterialPageRoute(
                                                    builder:
                                                        (BuildContext context) {
                                                      return DetailIOM(
                                                        iom: [
                                                          filteredIOM
                                                              .value[index]
                                                        ],
                                                      );
                                                    },
                                                  ));
                                                },
                                          child: CupertinoListTile.notched(
                                            leading: filteredIOM.value[index]
                                                            ['server'] ==
                                                        'LION' ||
                                                    filteredIOM.value[index]
                                                            ['server'] ==
                                                        'ANGKASA'
                                                ? Image.asset(
                                                    'assets/images/logo.png')
                                                : filteredIOM.value[index]
                                                            ['server'] ==
                                                        'SAJ'
                                                    ? Image.asset(
                                                        'assets/images/logosuper.png')
                                                    : filteredIOM.value[index]
                                                                ['server'] ==
                                                            'WINGS'
                                                        ? Image.asset(
                                                            'assets/images/logowings.png')
                                                        : filteredIOM.value[
                                                                        index]
                                                                    ['server'] ==
                                                                'BATIK'
                                                            ? Image.asset('assets/images/logobatik.png')
                                                            : const Icon(Icons.business),
                                            title: Text(
                                              filteredIOM.value[index]['noIOM'],
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Row(
                                              children: [
                                                const Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'IOM Date ',
                                                    ),
                                                    Text('Charter '),
                                                    Text('Route '),
                                                    Text('Route Date '),
                                                    Text('Status '),
                                                  ],
                                                ),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      ': ${DateFormat('dd MMM yyyy').format(DateTime.parse(filteredIOM.value[index]['tanggal']).toLocal())}',
                                                    ),
                                                    SizedBox(
                                                      width: size.width * 0.5,
                                                      child: Text(
                                                        ': ${filteredIOM.value[index]['charter']}',
                                                        style: const TextStyle(
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                        ': ${filteredIOM.value[index]['rute']}'),
                                                    Text(
                                                        ': ${DateFormat('dd MMM yyyy').format(DateTime.parse(filteredIOM.value[index]['tanggalRute']).toLocal())}'),
                                                    Text.rich(
                                                      TextSpan(
                                                        text: ': ',
                                                        children: [
                                                          TextSpan(
                                                            text: filteredIOM
                                                                .value[index]
                                                                    ['status']
                                                                .toString()
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: filteredIOM.value[index]
                                                                              [
                                                                              'status'] ==
                                                                          'VERIFIED PENDING PAYMENT' ||
                                                                      filteredIOM.value[index]
                                                                              [
                                                                              'status'] ==
                                                                          'VERIFIED PAYMENT'
                                                                  ? Colors.blue
                                                                  : filteredIOM.value[index]
                                                                              [
                                                                              'status'] ==
                                                                          'APPROVED'
                                                                      ? Colors
                                                                          .green
                                                                      : filteredIOM.value[index]['status'] ==
                                                                              'REJECTED'
                                                                          ? Colors
                                                                              .red
                                                                          : Colors
                                                                              .black,
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            trailing: filteredIOM.value[index]
                                                            ['status'] ==
                                                        'VERIFIED PAYMENT' ||
                                                    filteredIOM.value[index]
                                                            ['status'] ==
                                                        'APPROVED' ||
                                                    filteredIOM.value[index]
                                                            ['status'] ==
                                                        'REJECTED'
                                                ? const Icon(Icons.attach_file)
                                                : null,
                                            padding: const EdgeInsets.all(10),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            LoadingWidget(isLoading: loading),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: isHelp,
                  child: Positioned(
                    right: size.width * 0.3,
                    top: size.height * 0.02,
                    child: Container(
                      height: size.height * 0.16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.black54,
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        children: [
                          const Text(
                            'Click Any Status',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'to Filter The Data',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          const Text(
                            'Click Again to',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Remove The Filter',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}