// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';

class PickDate extends StatefulWidget {
  const PickDate({super.key});

  @override
  State<PickDate> createState() => _PickDateState();
}

class _PickDateState extends State<PickDate> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool isSave = false;
  int level = 0;
  String airlines = 'Select';
  List iom = [];
  List<String> listAirlines = [
    'Select',
    'ALL',
    'LION',
    'SAJ',
    'ANGKASA',
    'WINGS',
    'BATIK'
  ];

  TextEditingController dateFrom = TextEditingController();
  TextEditingController dateTo = TextEditingController();

  DropdownMenuItem<String> buildmenuItem(String item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  Future<void> pickDateFrom() async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate == null) return;

    setState(() {
      dateFrom.text = DateFormat('dd-MMM-yyyy')
          .format(DateTime.parse(newDate.toString()).toLocal());
    }); //for button SAVE
  }

  Future<void> pickDateTo() async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate == null) return;

    setState(() {
      dateTo.text = DateFormat('dd-MMM-yyyy')
          .format(DateTime.parse(newDate.toString()).toLocal());
    }); //for button SAVE
  }

  Future<void> DownloadReport() async {
    try {
      var excel = Excel.createExcel();
      var sheet = excel['IOMCharterWeb'];
      sheet.appendRow([
        if (airlines == 'ALL')
          {
            'Company',
          },
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
      sheet.appendRow(List.generate(31, (index) => '========'));
      for (var data in iom) {
        sheet.appendRow([
          if (airlines == 'ALL')
            {
              data['server'],
            },
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
          '${airlines}IOM${DateFormat('ddMMyy').format(DateFormat('dd-MMM-yyyy').parse(dateFrom.text).toLocal())}To${DateFormat('ddMMyy').format(DateFormat('dd-MMM-yyyy').parse(dateTo.text).toLocal())}';

      //Simpan data byte ke file excel
      excel.save(fileName: '$fileName.xlsx');

      setState(() {
        isSave = true;
      });

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
      debugPrint('$e');
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        configuration:
            const IconConfiguration(icon: Icons.error, color: Colors.red),
        title: "Error Download Report",
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

  Future<void> getReport() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetReport xmlns="http://tempuri.org/">' +
          '<start>${DateFormat('dd-MMM-yyyy').parse(dateFrom.text).toLocal().toIso8601String()}</start>' +
          '<end>${DateFormat('dd-MMM-yyyy').parse(dateTo.text).toLocal().toIso8601String()}</end>' +
          '<server>$airlines</server>' +
          '</GetReport>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetReport),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetReport',
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
            final tgl_Verifikasi =
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
            final tgl_TerimaPembayaran =
                listResult.findElements('Tgl_TerimaPembayaran').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Tgl_TerimaPembayaran')
                        .first
                        .innerText;
            final tgl_konfirmasi_direksi =
                listResult.findElements('Tgl_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Tgl_konfirmasi_direksi')
                        .first
                        .innerText;
            final confirmedBy = listResult.findElements('ConfirmedBy').isEmpty
                ? 'No Data'
                : listResult.findElements('ConfirmedBy').first.innerText;
            final status_konfirmasi_direksi =
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

            setState(() {
              if (!iom.any((e) => e['no'] == index + 1)) {
                iom.add({
                  'no': index,
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
                  'desc': description,
                  'item': item,
                  'tanggal': tanggal,
                  'rute': rute,
                  'amount': amount,
                  'tglVerifikasi': tgl_Verifikasi,
                  'verifiedBy': verifiedBy,
                  'payNo': payNo,
                  'currPembayaran': currPembayaran,
                  'amountPembayaran': amountPembayaran,
                  'namaBankPenerima': namaBankPenerima,
                  'tglTerimaPembayaran': tgl_TerimaPembayaran,
                  'tglKonfirmasiDireksi': tgl_konfirmasi_direksi,
                  'confirmedBy': confirmedBy,
                  'statusKonfirmasiDireksi': status_konfirmasi_direksi,
                  'logNo': logNo,
                  'userInsert': userInsert,
                  'insertDate': insertDate,
                  'status': status,
                });
              }
            });

            debugPrint(jsonEncode(iom));
          }
        }

        Future.delayed(const Duration(seconds: 1), () async {
          if (iom.isNotEmpty) {
            await DownloadReport();
          }
        });
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          title: "${response.statusCode}",
          subtitle: "Error Get Report",
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
        title: "Error Get Report",
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

  Future<void> getReportAll() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetReportAll xmlns="http://tempuri.org/">' +
          '<start>${DateFormat('dd-MMM-yyyy').parse(dateFrom.text).toLocal().toIso8601String()}</start>' +
          '<end>${DateFormat('dd-MMM-yyyy').parse(dateTo.text).toLocal().toIso8601String()}</end>' +
          '</GetReportAll>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetReportAll),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetReportAll',
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
            final tgl_Verifikasi =
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
            final tgl_TerimaPembayaran =
                listResult.findElements('Tgl_TerimaPembayaran').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Tgl_TerimaPembayaran')
                        .first
                        .innerText;
            final tgl_konfirmasi_direksi =
                listResult.findElements('Tgl_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Tgl_konfirmasi_direksi')
                        .first
                        .innerText;
            final confirmedBy = listResult.findElements('ConfirmedBy').isEmpty
                ? 'No Data'
                : listResult.findElements('ConfirmedBy').first.innerText;
            final status_konfirmasi_direksi =
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
              if (!iom.any((e) => e['no'] == index + 1)) {
                iom.add({
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
                  'desc': description,
                  'item': item,
                  'tanggal': tanggal,
                  'rute': rute,
                  'amount': amount,
                  'tglVerifikasi': tgl_Verifikasi,
                  'verifiedBy': verifiedBy,
                  'payNo': payNo,
                  'currPembayaran': currPembayaran,
                  'amountPembayaran': amountPembayaran,
                  'namaBankPenerima': namaBankPenerima,
                  'tglTerimaPembayaran': tgl_TerimaPembayaran,
                  'tglKonfirmasiDireksi': tgl_konfirmasi_direksi,
                  'confirmedBy': confirmedBy,
                  'statusKonfirmasiDireksi': status_konfirmasi_direksi,
                  'logNo': logNo,
                  'userInsert': userInsert,
                  'insertDate': insertDate,
                  'status': status,
                });
              }
            });

            debugPrint(jsonEncode(iom));
          }
        }

        Future.delayed(const Duration(seconds: 1), () async {
          if (iom.isNotEmpty) {
            await DownloadReport();
          }
        });
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          title: "${response.statusCode}",
          subtitle: "Error Get Report",
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
        title: "Error Get Report",
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

  @override
  void initState() {
    super.initState();

    dateFrom = TextEditingController(
        text: DateFormat('dd-MMM-yyyy').format(DateTime.now().toLocal()));
    dateTo = TextEditingController(
        text: DateFormat('dd-MMM-yyyy').format(DateTime.now().toLocal()));
  }

  @override
  void dispose() {
    dateFrom.dispose();
    dateTo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AlertDialog(
      title: const Text(
        'Download Report',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      icon: Icon(
        Icons.file_download,
        size: size.height * 0.1,
      ),
      iconColor: Colors.green,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
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

                    if (airlines != 'ALL') {
                      await getReport();
                    } else {
                      await getReportAll();
                    }

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
                  }
                },
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(),
                )
              : const Text(
                  "Download",
                  style: TextStyle(
                    color: Colors.green,
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
      content: SingleChildScrollView(
        clipBehavior: Clip.antiAlias,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please Pick Date',
                textAlign: TextAlign.start,
              ),
              SizedBox(height: size.height * 0.03),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: dateFrom,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                  await pickDateFrom();
                                },
                          icon: Icon(
                            Icons.calendar_month_outlined,
                            color: loading ? null : Colors.green,
                          ),
                        ),
                        label: const Text('Date From'),
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    TextFormField(
                      controller: dateTo,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                  await pickDateTo();
                                },
                          icon: Icon(
                            Icons.calendar_month_outlined,
                            color: loading ? null : Colors.green,
                          ),
                        ),
                        label: const Text('Date To'),
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    DropdownButtonFormField(
                      value: airlines,
                      itemHeight: null,
                      isExpanded: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1),
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
                      ),
                      items: listAirlines.map(buildmenuItem).toList(),
                      onChanged: (value) {
                        if (!loading) {
                          setState(() {
                            airlines = value!;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == "Select") {
                          return "Please Choose Airlines";
                        } else {
                          return null;
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.03),
            ]),
      ),
    );
  }
}
