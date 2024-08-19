// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'dart:math';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iomweb/widgets/loading.dart';
import 'package:status_alert/status_alert.dart';
import '../backend/constants.dart';
import '../screens/change_pass.dart';
import '../screens/home.dart';
import '../screens/iom_void.dart';
import '../screens/view_iom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/about.dart';
import '../screens/login.dart';
import 'alertdialog/log_error.dart';
import 'alertdialog/pick_date.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool loading = false;
  bool isSave = false;
  String randomID = '';
  List data = [];
  List report = [];
  Widget expan = const ExpansionTile(
    collapsedIconColor: Colors.white,
    collapsedTextColor: Colors.white,
    title: Text(
      "Menu",
    ),
    leading: Icon(Icons.receipt),
    textColor: Color.fromARGB(255, 5, 98, 173),
    children: [],
  );

  Future<void> genRandom() async {
    int random = Random().nextInt(4294967296);

    setState(() {
      randomID = 'FC' + random.toString();
    });

    //debugprint(randomID);

    await addTranKey();
  }

  Future<void> addTranKey() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<AddTranKey xmlns="http://tempuri.org/">' +
          '<nik>${data.last['nik']}</nik>' +
          '<TranKey>$randomID</TranKey>' +
          '</AddTranKey>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_AddTranKey),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/AddTranKey',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('AddTranKeyResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('AddTranKeyResult').first.text;

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
                  fail: 'Failed Add TranKey',
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
                fail: 'Failed Add TranKey',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getReportOverdue() async {
    try {
      setState(() {
        loading = true;
      });

      const String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetReportOverdue xmlns="http://tempuri.org/" />' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetReportOverdue),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetReportOverdue',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final listResultAll = document.findAllElements('Table');

        for (int index = 0; index < listResultAll.length; index++) {
          final listResult = listResultAll.toList()[index];

          final statusData = listResult.findElements('StatusData').isEmpty
              ? 'No Data'
              : listResult.findElements('StatusData').first.innerText;

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
                : listResult.findElements('NoIOM').first.innerText;
            final tglIOM = listResult.findElements('TglIOM').isEmpty
                ? 'No Data'
                : listResult.findElements('TglIOM').first.innerText;
            final dari = listResult.findElements('Dari').isEmpty
                ? 'No Data'
                : listResult.findElements('Dari').first.innerText;
            final kepadaYth = listResult.findElements('KepadaYth').isEmpty
                ? 'No Data'
                : listResult.findElements('KepadaYth').first.innerText;
            final ccYth = listResult.findElements('CCYth').isEmpty
                ? 'No Data'
                : listResult.findElements('CCYth').first.innerText;
            final perihal = listResult.findElements('Perihal').isEmpty
                ? 'No Data'
                : listResult.findElements('Perihal').first.innerText;
            final currency = listResult.findElements('Currency').isEmpty
                ? 'No Data'
                : listResult.findElements('Currency').first.innerText;
            final biayaCharter = listResult.findElements('BiayaCharter').isEmpty
                ? '0'
                : listResult.findElements('BiayaCharter').first.innerText;
            final createdDate = listResult.findElements('CreatedDate').isEmpty
                ? 'No Data'
                : listResult.findElements('CreatedDate').first.innerText;
            final createdBy = listResult.findElements('CreatedBy').isEmpty
                ? 'No Data'
                : listResult.findElements('CreatedBy').first.innerText;
            final namaResmi = listResult.findElements('NamaResmi').isEmpty
                ? 'No Data'
                : listResult.findElements('NamaResmi').first.innerText;
            final description = listResult.findElements('Description').isEmpty
                ? 'No Data'
                : listResult.findElements('Description').first.innerText;
            final item = listResult.findElements('Item').isEmpty
                ? '0'
                : listResult.findElements('Item').first.innerText;
            final tanggal = listResult.findElements('Tanggal').isEmpty
                ? 'No Data'
                : listResult.findElements('Tanggal').first.innerText;
            final rute = listResult.findElements('Rute').isEmpty
                ? 'No Data'
                : listResult.findElements('Rute').first.innerText;
            final amount = listResult.findElements('Amount').isEmpty
                ? '0'
                : listResult.findElements('Amount').first.innerText;
            final tglVerifikasi =
                listResult.findElements('Tgl_Verifikasi').isEmpty
                    ? 'No Data'
                    : listResult.findElements('Tgl_Verifikasi').first.innerText;
            final verifiedBy = listResult.findElements('VerifiedBy').isEmpty
                ? 'No Data'
                : listResult.findElements('VerifiedBy').first.innerText;
            final payNo = listResult.findElements('PayNo').isEmpty
                ? '0'
                : listResult.findElements('PayNo').first.innerText;
            final currPembayaran =
                listResult.findElements('CurrPembayaran').isEmpty
                    ? 'No Data'
                    : listResult.findElements('CurrPembayaran').first.innerText;
            final amountPembayaran = listResult
                    .findElements('AmountPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult.findElements('AmountPembayaran').first.innerText;
            final namaBankPenerima = listResult
                    .findElements('NamaBankPenerima')
                    .isEmpty
                ? 'No Data'
                : listResult.findElements('NamaBankPenerima').first.innerText;
            final tglTerimapembayaran =
                listResult.findElements('Tgl_TerimaPembayaran').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Tgl_TerimaPembayaran')
                        .first
                        .innerText;
            final tglKonfirmasiDireksi =
                listResult.findElements('Tgl_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Tgl_konfirmasi_direksi')
                        .first
                        .innerText;
            final confirmedBy = listResult.findElements('ConfirmedBy').isEmpty
                ? 'No Data'
                : listResult.findElements('ConfirmedBy').first.innerText;
            final statusKonfirmasiDireksi =
                listResult.findElements('Status_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Status_konfirmasi_direksi')
                        .first
                        .innerText;
            final logNo = listResult.findElements('LogNo').isEmpty
                ? '0'
                : listResult.findElements('LogNo').first.innerText;
            final userInsert = listResult.findElements('UserInsert').isEmpty
                ? 'No Data'
                : listResult.findElements('UserInsert').first.innerText;
            final insertDate = listResult.findElements('InsertDate').isEmpty
                ? 'No Data'
                : listResult.findElements('InsertDate').first.innerText;
            final status = listResult.findElements('Status').isEmpty
                ? 'No Data'
                : listResult.findElements('Status').first.innerText;
            final server = listResult.findElements('Server').isEmpty
                ? 'No Data'
                : listResult.findElements('Server').first.innerText;

            setState(() {
              if (!report.any((e) => e['no'] == index + 1)) {
                report.add({
                  'no': index,
                  'server': server,
                  'noIOM': noIOM,
                  'tglIom': tglIOM,
                  'dari': dari,
                  'kepadaYTH': kepadaYth,
                  'ccYTH': ccYth,
                  'perihal': perihal,
                  'curr': currency,
                  'biayaCharter': biayaCharter,
                  'createdDate': createdDate,
                  'createdBy': createdBy,
                  'namaResmi': namaResmi,
                  'desc': description,
                  'item': item,
                  'tanggal': tanggal,
                  'rute': rute,
                  'amount': amount,
                  'tglVerifikasi': tglVerifikasi,
                  'verifiedBy': verifiedBy,
                  'payNo': payNo,
                  'currPembayaran': currPembayaran,
                  'amountPembayaran': amountPembayaran,
                  'namaBankPenerima': namaBankPenerima,
                  'tglTerimaPembayaran': tglTerimapembayaran,
                  'tglKonfirmasiDireksi': tglKonfirmasiDireksi,
                  'confirmedBy': confirmedBy,
                  'statusKonfirmasiDireksi': statusKonfirmasiDireksi,
                  'logNo': logNo,
                  'userInsert': userInsert,
                  'insertDate': insertDate,
                  'status': status,
                });
              }
            });

            //debugprint(jsonEncode(report));
          }
        }

        Future.delayed(const Duration(seconds: 1), () async {
          if (report.isNotEmpty) {
            await downReport();
          }
        });
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
                  fail: 'Error Get Overdue Report',
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
                fail: 'Error Get Overdue Report',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> downReport() async {
    try {
      var excel = Excel.createExcel();
      var sheet = excel['IOM'];
      var sheet1 = excel['DetailIOM'];
      sheet.appendRow([
        'Company',
        'NoIom',
        'TglIom',
        'Curr',
        'BiayaCharter',
        'TglCreate',
        'UserCreate',
        'Username',
        'NamaPencharter',
        'TglVerifikasi',
        'UserVerifikasi',
        'TglApproval',
        'UserApproval',
        'StatusApproval',
      ]);
      sheet1.appendRow([
        'Company',
        'NoIom',
        'TglIom',
        'Dari',
        'KepadaYTH',
        'CCYTH',
        'Perihal',
        'Curr',
        'BiayaCharter',
        'TglCreate',
        'UserCreate',
        'Username',
        'NamaPencharter',
        'Item',
        'Tanggal',
        'Rute',
        'Currency',
        'Nilaipersegment',
        'TglVerifikasi',
        'UserVerifikasi',
        'PayNo',
        'CurrPaymentVerifikasi',
        'NilaiPaymentVerifikasi',
        'BankPaymentVerifikasi',
        'TglPaymentVerifikasi',
        'TglApproval',
        'UserApproval',
        'StatusApproval',
        'LogNo',
        'UserInsert',
        'InsertDate',
        'Status',
      ]);
      sheet.appendRow(List.generate(13, (index) => '================'));
      sheet1.appendRow(List.generate(31, (index) => '================'));
      for (var data in report) {
        sheet.appendRow([
          data['server'],
          data['noIOM'],
          data['tglIom'] == 'No Data'
              ? data['tglIom']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['tglIom']).toLocal()),
          data['curr'],
          data['biayaCharter'],
          data['createdDate'] == 'No Data'
              ? data['createdDate']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['createdDate']).toLocal()),
          data['createdBy'],
          data['namaResmi'],
          data['desc'],
          data['tglVerifikasi'] == 'No Data'
              ? data['tglVerifikasi']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['tglVerifikasi']).toLocal()),
          data['verifiedBy'],
          data['tglKonfirmasiDireksi'] == 'No Data'
              ? data['tglKonfirmasiDireksi']
              : DateFormat('dd-MMM-yyyy').format(
                  DateTime.parse(data['tglKonfirmasiDireksi']).toLocal()),
          data['confirmedBy'],
          data['statusKonfirmasiDireksi'],
        ]);
        sheet1.appendRow([
          data['server'],
          data['noIOM'],
          data['tglIom'] == 'No Data'
              ? data['tglIom']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['tglIom']).toLocal()),
          data['dari'],
          data['kepadaYTH'],
          data['ccYTH'],
          data['perihal'],
          data['curr'],
          data['biayaCharter'],
          data['createdDate'] == 'No Data'
              ? data['createdDate']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['createdDate']).toLocal()),
          data['createdBy'],
          data['namaResmi'],
          data['desc'],
          data['item'],
          data['tanggal'] == 'No Data'
              ? data['tanggal']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['tanggal']).toLocal()),
          data['rute'],
          data['curr'],
          data['amount'],
          data['tglVerifikasi'] == 'No Data'
              ? data['tglVerifikasi']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['tglVerifikasi']).toLocal()),
          data['verifiedBy'],
          data['payNo'],
          data['currPembayaran'],
          data['amountPembayaran'],
          data['namaBankPenerima'],
          data['tglTerimaPembayaran'] == 'No Data'
              ? data['tglTerimaPembayaran']
              : DateFormat('dd-MMM-yyyy').format(
                  DateTime.parse(data['tglTerimaPembayaran']).toLocal()),
          data['tglKonfirmasiDireksi'] == 'No Data'
              ? data['tglKonfirmasiDireksi']
              : DateFormat('dd-MMM-yyyy').format(
                  DateTime.parse(data['tglKonfirmasiDireksi']).toLocal()),
          data['confirmedBy'],
          data['statusKonfirmasiDireksi'],
          data['logNo'],
          data['userInsert'],
          data['insertDate'] == 'No Data'
              ? data['insertDate']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['insertDate']).toLocal()),
          data['status'],
        ]);
      }

      String fileName =
          'OVERDUEIOMTo${DateFormat('ddMMyy').format(DateTime.now().toLocal())}';

      //Simpan data byte ke file excel
      excel.save(fileName: '$fileName.xlsx');

      setState(() {
        isSave = true;
      });

      if (isSave) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            showCloseIcon: false,
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            padding: EdgeInsets.all(20),
            elevation: 10,
            content: Center(
              child: Text(
                'File Saved in Download',
                textAlign: TextAlign.justify,
              ),
            ),
          ),
        );
      }

      Future.delayed(const Duration(seconds: 1), () async {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }

        Navigator.of(context).pop();
      });

      Future.delayed(const Duration(seconds: 3), () async {
        if (mounted) {
          setState(() {
            isSave = false;
          });
        }
      });
    } catch (e) {
      //debugprint('$e');
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        configuration:
            const IconConfiguration(icon: Icons.error, color: Colors.red),
        title: "Error Download Overdue Report",
        subtitle: "$e",
        titleOptions: StatusAlertTextConfiguration(
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

  Future<Widget> cekLevel() async {
    if (data.last['level'] == '12') {
      setState(() {
        expan = ExpansionTile(
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          title: const Text(
            "Menu",
          ),
          leading: const Icon(Icons.receipt),
          textColor: const Color.fromARGB(255, 5, 98, 173),
          children: [
            if (data.last['nik'] == '56000031')
              ListTile(
                iconColor: Colors.white70,
                textColor: Colors.white70,
                leading: const Icon(Icons.circle_outlined),
                title: const Text("IOM Agreement"),
                onTap: () async {
                  await genRandom();

                  Future.delayed(const Duration(seconds: 1), () async {
                    String baseUrl =
                        'https://lgapvfncacc.com/IOMCharterWeb/AgreementCharter/';
                    String nik = data.last['nik'];
                    String tranKey = randomID;

                    String urlWithParameters = baseUrl +
                        '?NIK=' +
                        Uri.encodeComponent(nik) +
                        '&TranKey=' +
                        Uri.encodeComponent(tranKey);

                    if (await canLaunch(urlWithParameters)) {
                      await launch(urlWithParameters,
                          webOnlyWindowName: '_self');
                    } else {
                      StatusAlert.show(
                        context,
                        duration: const Duration(seconds: 1),
                        configuration: const IconConfiguration(
                          icon: Icons.error,
                          color: Colors.red,
                        ),
                        title: "Error while opening URL",
                        backgroundColor: Colors.grey[300],
                      );

                      throw 'Error while opening $urlWithParameters';
                    }
                  });
                },
              ),
            if (data.last['nik'] == '56000031')
              ListTile(
                iconColor: Colors.white70,
                textColor: Colors.white70,
                leading: const Icon(Icons.circle_outlined),
                title: const Text("Internal Memo Office IOM"),
                onTap: () async {
                  await genRandom();

                  Future.delayed(const Duration(seconds: 1), () async {
                    String baseUrl =
                        'https://lgapvfncacc.com/IOMCharterWeb/CreateIOM/';
                    String nik = data.last['nik'];
                    String tranKey = randomID;

                    String urlWithParameters = baseUrl +
                        '?NIK=' +
                        Uri.encodeComponent(nik) +
                        '&TranKey=' +
                        Uri.encodeComponent(tranKey);

                    if (await canLaunch(urlWithParameters)) {
                      await launch(urlWithParameters,
                          webOnlyWindowName: '_self');
                    } else {
                      StatusAlert.show(
                        context,
                        duration: const Duration(seconds: 1),
                        configuration: const IconConfiguration(
                          icon: Icons.error,
                          color: Colors.red,
                        ),
                        title: "Error while opening URL",
                        backgroundColor: Colors.grey[300],
                      );

                      throw 'Error while opening $urlWithParameters';
                    }
                  });
                },
              ),
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("IOM Verification"),
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) {
                    return const ViewIOM(
                      title: 'IOM Verification',
                    );
                  }),
                );
              },
            ),
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("IOM Void"),
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) {
                    return const IOMVoid();
                  }),
                );
              },
            ),
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("Download Report"),
              onTap: () async {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const PickDate();
                  },
                );
              },
            ),
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("Download Overdue Report"),
              onTap: () async {
                setState(() {
                  loading = true;
                });

                await getReportOverdue();
              },
            ),
          ],
        );
      });
    } else if (data.last['level'] == '10') {
      setState(() {
        expan = ExpansionTile(
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          title: const Text(
            "Menu",
          ),
          leading: const Icon(Icons.receipt),
          textColor: const Color.fromARGB(255, 5, 98, 173),
          children: [
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("IOM Approval"),
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) {
                    return const ViewIOM(
                      title: 'IOM Approval',
                    );
                  }),
                );
              },
            ),
          ],
        );
      });
    } else if (data.last['level'] == '19') {
      setState(() {
        expan = ExpansionTile(
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          title: const Text(
            "Menu",
          ),
          leading: const Icon(Icons.receipt),
          textColor: const Color.fromARGB(255, 5, 98, 173),
          children: [
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("IOM Agreement"),
              onTap: () async {
                await genRandom();

                Future.delayed(const Duration(seconds: 1), () async {
                  String baseUrl =
                      'https://lgapvfncacc.com/IOMCharterWeb/AgreementCharter/';
                  String nik = data.last['nik'];
                  String tranKey = randomID;

                  String urlWithParameters = baseUrl +
                      '?NIK=' +
                      Uri.encodeComponent(nik) +
                      '&TranKey=' +
                      Uri.encodeComponent(tranKey);

                  if (await canLaunch(urlWithParameters)) {
                    await launch(urlWithParameters, webOnlyWindowName: '_self');
                  } else {
                    StatusAlert.show(
                      context,
                      duration: const Duration(seconds: 1),
                      configuration: const IconConfiguration(
                        icon: Icons.error,
                        color: Colors.red,
                      ),
                      title: "Error while opening URL",
                      backgroundColor: Colors.grey[300],
                    );

                    throw 'Error while opening $urlWithParameters';
                  }
                });
              },
            ),
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("Internal Memo Office IOM"),
              onTap: () async {
                await genRandom();

                Future.delayed(const Duration(seconds: 1), () async {
                  String baseUrl =
                      'https://lgapvfncacc.com/IOMCharterWeb/CreateIOM/';
                  String nik = data.last['nik'];
                  String tranKey = randomID;

                  String urlWithParameters = baseUrl +
                      '?NIK=' +
                      Uri.encodeComponent(nik) +
                      '&TranKey=' +
                      Uri.encodeComponent(tranKey);

                  if (await canLaunch(urlWithParameters)) {
                    await launch(urlWithParameters, webOnlyWindowName: '_self');
                  } else {
                    StatusAlert.show(
                      context,
                      duration: const Duration(seconds: 1),
                      configuration: const IconConfiguration(
                        icon: Icons.error,
                        color: Colors.red,
                      ),
                      title: "Error while opening URL",
                      backgroundColor: Colors.grey[300],
                    );

                    throw 'Error while opening $urlWithParameters';
                  }
                });
              },
            ),
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("View IOM"),
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) {
                    return const ViewIOM(
                      title: 'View IOM',
                    );
                  }),
                );
              },
            ),
          ],
        );
      });
    } else {
      setState(() {
        expan = ExpansionTile(
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          title: const Text(
            "Menu",
          ),
          leading: const Icon(Icons.receipt),
          textColor: const Color.fromARGB(255, 5, 98, 173),
          children: [
            ListTile(
              iconColor: Colors.white70,
              textColor: Colors.white70,
              leading: const Icon(Icons.circle_outlined),
              title: const Text("View IOM"),
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) {
                    return const ViewIOM(
                      title: 'View IOM',
                    );
                  }),
                );
              },
            ),
          ],
        );
      });
    }

    return expan;
  }

  Future<void> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? nik = prefs.getString('nik');
    String? userEmail = prefs.getString('userEmail');
    String? userLevel = prefs.getString('userLevel');

    setState(() {
      data = [
        {
          'nik': nik,
          'email': userEmail,
          'level': userLevel,
        }
      ];
      //debugprint(jsonEncode(data));
    });

    await cekLevel();
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
      builder: (BuildContext context) {
        return const LoginScreen();
      },
    ), (route) => false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        SizedBox(
          width: size.width * 0.6,
          child: Drawer(
            backgroundColor: const Color(0xFF2E2E48),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                SizedBox(
                  height: size.height * 0.18,
                  child: DrawerHeader(
                    child: InkWell(
                      onTap: () async {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (BuildContext context) {
                            return const HomeScreen();
                          }),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.red,
                              boxShadow: const [
                                BoxShadow(
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: Offset(2, 1),
                                )
                              ],
                            ),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 2,
                                ),
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            'IOMCharter',
                            style: TextStyle(
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  MediaQuery.of(context).textScaleFactor * 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                expan,
                ListTile(
                  onTap: () async {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) {
                        return ChangePass(
                          nik: data.last['nik'],
                          email: data.last['email'],
                        );
                      },
                    ));
                  },
                  leading: const Icon(
                    Icons.lock_person,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Change Password',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                ListTile(
                  onTap: () async {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const About();
                      },
                    ));
                  },
                  leading: const Icon(
                    Icons.info,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'About',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                ListTile(
                  onTap: () async {
                    await logout();
                  },
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                    ),
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
    );
  }
}
