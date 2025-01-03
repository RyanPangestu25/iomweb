// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:status_alert/status_alert.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../../../backend/constants.dart';
import '../log_error.dart';

class DonwloadMaster extends StatefulWidget {
  const DonwloadMaster({super.key});

  @override
  State<DonwloadMaster> createState() => _DonwloadMasterState();
}

class _DonwloadMasterState extends State<DonwloadMaster> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool isSave = false;
  int level = 0;
  String airlines = 'Select';
  List mstagreement= [];
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
      List<String> noMaster = [];

      var excel = Excel.createExcel();
      var sheet = excel['Master Agreement'];
      var sheet1 = excel['Detail Master Agreement'];
      sheet.appendRow([
        'Company',
        'No Agreement',
        'Customer',
        'Periode Awal',
        'Periode Akhir',
        'No NPWP',
        'No Reference',
        'Approved By',
        'TnC',
        'Create Date',
        'Create By',
        'Tanggal Deposit',
        'Currency',
        'Amount Deposit',
        'Jenis Agreement',
        'Signed By',
        'Signed By Charter'
      ]);
      sheet1.appendRow([
        'Company',
        'No Agreement',
        'Customer',
        'Periode Awal',
        'Periode Akhir',
        'No NPWP',
        'No Reference',
        'Approved By',
        'TnC',
        'Create Date',
        'Create By',
        'Tanggal Deposit',
        'Currency',
        'Amount Deposit',
        'Jenis Agreement',
        'Signed By',
        'Signed By Charter',
        'Item',
        'Rute',
        'Amount',
        'Tanggal Verifikasi',
        'Verified By',
        'Tanggal Konfirmasi Direksi',
        'Confirmed By',
        'Status Konfirmasi Direksi',
        'Pay Number',
        'Currency Pembayaran',
        'Amount Pembayaran',
        'Nama Bank Penerima',
        'Tanggal Terima Pembayaran',
        'Log Number',
        'User Insert',
        'Insert Date',
        'Status'
      ]);
      sheet.appendRow(List.generate(16, (index) => '================'));
      sheet1.appendRow(List.generate(33, (index) => '================'));
      for (var data in mstagreement) {
        if (!noMaster.contains(data['noAgreement'])) {
          sheet.appendRow([
          data['server'],
          data['noAgreement'],
          data['customer'],
          data['periodeAwal'] == 'No Data'
              ? data['periodeAwal']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['periodeAwal']).toLocal()),
          data['periodeAkhir'] == 'No Data'
              ? data['periodeAkhir']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['periodeAkhir']).toLocal()),
          data['noNPWP'],
          data['noReference'],
          data['approvedBy'],
          data['tnc'],
          data['createDate'],
          data['createBy'],
          data['tglDeposit'] == 'No Data'
              ? data['tglDeposit']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['tglDeposit']).toLocal()),
          data['currency'],
          data['amountDeposit'],
          data['jenisAgreement'],
          data['signedby'],
          data['signedByCharterer'],
          ]);

          noMaster.add(data['noAgreement']);
        }

        sheet1.appendRow([
          data['server'],
          data['noAgreement'],
          data['customer'],
          data['periodeAwal'] == 'No Data'
              ? data['periodeAwal']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['periodeAwal']).toLocal()),
          data['periodeAkhir'] == 'No Data'
              ? data['periodeAkhir']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['periodeAkhir']).toLocal()),
          data['noNPWP'],
          data['noReference'],
          data['approvedBy'],
          data['tnc'],
          data['createDate'],
          data['createBy'],
          data['tglDeposit'] == 'No Data'
              ? data['tglDeposit']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['tglDeposit']).toLocal()),
          data['currency'],
          data['amountDeposit'],
          data['jenisAgreement'],
          data['signedby'],
          data['signedByCharterer'],
          data['item'],
          data['rute'],
          data['amount'],
          data['tgl_Verifikasi'] == 'No Data'
              ? data['tgl_Verifikasi']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['tgl_Verifikasi']).toLocal()),
          data['verifiedBy'],
          data['tgl_konfirmasi_direksi'] == 'No Data'
              ? data['tgl_konfirmasi_direksi']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['tgl_konfirmasi_direksi']).toLocal()),
          data['confirmedBy'],
          data['status_konfirmasi_direksi'],
          data['payNo'],
          data['currPembayaran'],
          data['amountPembayaran'],
          data['namaBankPenerima'],
          data['tgl_TerimaPembayaran'] == 'No Data'
              ? data['tgl_TerimaPembayaran']
              : DateFormat('dd-MMM-yyyy')
                  .format(DateTime.parse(data['tgl_TerimaPembayaran']).toLocal()),
          data['logNo'],
          data['userInsert'],
          data['insertDate'],
          data['status'],
        ]);
      }

      String fileName =
          '${airlines}MasterAgreement${DateFormat('ddMMyy').format(DateFormat('dd-MMM-yyyy').parse(dateFrom.text).toLocal())}To${DateFormat('ddMMyy').format(DateFormat('dd-MMM-yyyy').parse(dateTo.text).toLocal())}';

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
      //debugPrint('$e');
     await showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context){
        return LogError(
          statusCode: '', 
          fail: 'Error Donwload Report', 
          error: e.toString()
          );

      }
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
          '<GetReportMstAgreement xmlns="http://tempuri.org/">' +
          '<start>${DateFormat('dd-MMM-yyyy').parse(dateFrom.text).toLocal().toIso8601String()}</start>' +
          '<end>${DateFormat('dd-MMM-yyyy').parse(dateTo.text).toLocal().toIso8601String()}</end>' +
          '<server>$airlines</server>' +
          '</GetReportMstAgreement>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetReportMstAgreement),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetReportMstAgreement',
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
           final noAgreement = listResult.findElements('NoAgreement').isEmpty
                ? 'No Data'
                : listResult.findElements('NoAgreement').first.innerText;
            final customer = listResult.findElements('Customer').isEmpty
                ? 'No Data'
                : listResult.findElements('Customer').first.innerText;
            final periodeAwal = listResult.findAllElements('PriodeAwal').isEmpty
                ? 'No Data'
                : listResult.findAllElements('PriodeAwal').first.innerText;
            final periodeAkhir =
                listResult.findAllElements('PriodeAkhir').isEmpty
                    ? 'No Data'
                    : listResult.findAllElements('PriodeAkhir').first.innerText;
            final noNPWP = listResult.findAllElements('NoNPWP').isEmpty
                ? 'No Data'
                : listResult.findAllElements('NoNPWP').first.innerText;
            final noReference =
                listResult.findAllElements('NoReference').isEmpty
                    ? 'No Data'
                    : listResult.findAllElements('NoReference').first.innerText;

            final approvedBy = listResult.findAllElements('ApprovedBy').isEmpty
                ? 'No Data'
                : listResult.findAllElements('ApprovedBy').first.innerText;

            final tnc = listResult.findAllElements('TnC').isEmpty
                ? 'No Data'
                : listResult.findAllElements('TnC').first.innerText;

            final createDate = listResult.findAllElements('CreateDate').isEmpty
                ? 'No Data'
                : listResult.findAllElements('CreateDate').first.innerText;

            final createBy = listResult.findAllElements('CreateBy').isEmpty
                ? 'No Data'
                : listResult.findAllElements('CreateBy').first.innerText;

            final tglDeposit = listResult.findAllElements('TglDeposit').isEmpty
                ? 'No Data'
                : listResult.findAllElements('TglDeposit').first.innerText;

            final currency = listResult.findAllElements('Currency').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Currency').first.innerText;

            final amountDeposit = listResult
                    .findAllElements('AmountDeposit')
                    .isEmpty
                ? 'No Data'
                : listResult.findAllElements('AmountDeposit').first.innerText;

            final jenisAgreement = listResult
                    .findAllElements('JenisAgreement')
                    .isEmpty
                ? 'No Data'
                : listResult.findAllElements('JenisAgreement').first.innerText;

            final signedby = listResult.findAllElements('Signedby').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Signedby').first.innerText;

            final signedByCharterer =
                listResult.findAllElements('SignedByCharterer').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('SignedByCharterer')
                        .first
                        .innerText;

            final item = listResult.findAllElements('Item').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Item').first.innerText;

            final rute = listResult.findAllElements('Rute').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Rute').first.innerText;

            final amount = listResult.findAllElements('Amount').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Amount').first.innerText;

            final tglVerifikasi = listResult
                    .findAllElements('Tgl_Verifikasi')
                    .isEmpty
                ? 'No Data'
                : listResult.findAllElements('Tgl_Verifikasi').first.innerText;

            final verifiedBy = listResult.findAllElements('VerifiedBy').isEmpty
                ? 'No Data'
                : listResult.findAllElements('VerifiedBy').first.innerText;

            final tglkonfirmasidireksi =
                listResult.findAllElements('Tgl_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('Tgl_konfirmasi_direksi')
                        .first
                        .innerText;

            final confirmedBy =
                listResult.findAllElements('ConfirmedBy').isEmpty
                    ? 'No Data'
                    : listResult.findAllElements('ConfirmedBy').first.innerText;

            final statuskonfirmasidireksi =
                listResult.findAllElements('Status_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('Status_konfirmasi_direksi')
                        .first
                        .innerText;

            final payNo = listResult.findAllElements('PayNo').isEmpty
                ? 'No Data'
                : listResult.findAllElements('PayNo').first.innerText;

            final currPembayaran = listResult
                    .findAllElements('CurrPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult.findAllElements('CurrPembayaran').first.innerText;

            final amountPembayaran =
                listResult.findAllElements('AmountPembayaran').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('AmountPembayaran')
                        .first
                        .innerText;

            final namaBankPenerima =
                listResult.findAllElements('NamaBankPenerima').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('NamaBankPenerima')
                        .first
                        .innerText;
            final tglTerimaPembayaran =
                listResult.findAllElements('Tgl_TerimaPembayaran').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('Tgl_TerimaPembayaran')
                        .first
                        .innerText;

            final logNo = listResult.findAllElements('LogNo').isEmpty
                ? 'No Data'
                : listResult.findAllElements('LogNo').first.innerText;

            final userInsert = listResult.findAllElements('UserInsert').isEmpty
                ? 'No Data'
                : listResult.findAllElements('UserInsert').first.innerText;

            final insertDate = listResult.findAllElements('InsertDate').isEmpty
                ? 'No Data'
                : listResult.findAllElements('InsertDate').first.innerText;

            final status = listResult.findAllElements('Status').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Status').first.innerText;

            final server = listResult.findAllElements('Server').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Server').first.innerText;

            setState(() {
              if (!mstagreement.any((e) => e['no'] == index + 1)) {
                mstagreement.add({
                  'no': index,
                  'server': server,
                  'noAgreement': noAgreement,
                  'customer': customer,
                  'periodeAwal': periodeAwal,
                  'periodeAkhir': periodeAkhir,
                  'noNPWP': noNPWP,
                  'noReference': noReference,
                  'approvedBy': approvedBy,
                  'tnc': tnc,
                  'createDate': createDate,
                  'createBy': createBy,
                  'tglDeposit': tglDeposit,
                  'currency': currency,
                  'amountDeposit': amountDeposit,
                  'jenisAgreement': jenisAgreement,
                  'signedby': signedby,
                  'signedByCharterer': signedByCharterer,
                  'item': item,
                  'rute': rute,
                  'amount': amount,
                  'tgl_Verifikasi': tglVerifikasi,
                  'verifiedBy': verifiedBy,
                  'tgl_konfirmasi_direksi': tglkonfirmasidireksi,
                  'confirmedBy': confirmedBy,
                  'status_konfirmasi_direksi': statuskonfirmasidireksi,
                  'payNo': payNo,
                  'currPembayaran': currPembayaran,
                  'amountPembayaran': amountPembayaran,
                  'namaBankPenerima': namaBankPenerima,
                  'tgl_TerimaPembayaran': tglTerimaPembayaran,
                  'logNo': logNo,
                  'userInsert': userInsert,
                  'insertDate': insertDate,
                  'status': status,
                });
              }
            });

            //debugPrint(jsonEncode(iom));
          }
        }

        Future.delayed(const Duration(seconds: 1), () async {
          if (mstagreement.isNotEmpty) {
            await DownloadReport();
          }
        });
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
                  fail: 'Error Get Report',
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
                fail: 'Error Get Report',
                error: e.toString(),
              );
            });

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
          '<GetReportMstAgreementAll xmlns="http://tempuri.org/">' +
          '<start>${DateFormat('dd-MMM-yyyy').parse(dateFrom.text).toLocal().toIso8601String()}</start>' +
          '<end>${DateFormat('dd-MMM-yyyy').parse(dateTo.text).toLocal().toIso8601String()}</end>' +
          '</GetReportMstAgreementAll>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetReportMstAgreementAll),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetReportMstAgreementAll',
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
            final noAgreement = listResult.findElements('NoAgreement').isEmpty
                ? 'No Data'
                : listResult.findElements('NoAgreement').first.innerText;
            final customer = listResult.findElements('Customer').isEmpty
                ? 'No Data'
                : listResult.findElements('Customer').first.innerText;
            final periodeAwal = listResult.findAllElements('PriodeAwal').isEmpty
                ? 'No Data'
                : listResult.findAllElements('PriodeAwal').first.innerText;
            final periodeAkhir =
                listResult.findAllElements('PriodeAkhir').isEmpty
                    ? 'No Data'
                    : listResult.findAllElements('PriodeAkhir').first.innerText;
            final noNPWP = listResult.findAllElements('NoNPWP').isEmpty
                ? 'No Data'
                : listResult.findAllElements('NoNPWP').first.innerText;
            final noReference =
                listResult.findAllElements('NoReference').isEmpty
                    ? 'No Data'
                    : listResult.findAllElements('NoReference').first.innerText;

            final approvedBy = listResult.findAllElements('ApprovedBy').isEmpty
                ? 'No Data'
                : listResult.findAllElements('ApprovedBy').first.innerText;

            final tnc = listResult.findAllElements('TnC').isEmpty
                ? 'No Data'
                : listResult.findAllElements('TnC').first.innerText;

            final createDate = listResult.findAllElements('CreateDate').isEmpty
                ? 'No Data'
                : listResult.findAllElements('CreateDate').first.innerText;

            final createBy = listResult.findAllElements('CreateBy').isEmpty
                ? 'No Data'
                : listResult.findAllElements('CreateBy').first.innerText;

            final tglDeposit = listResult.findAllElements('TglDeposit').isEmpty
                ? 'No Data'
                : listResult.findAllElements('TglDeposit').first.innerText;

            final currency = listResult.findAllElements('Currency').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Currency').first.innerText;

            final amountDeposit = listResult
                    .findAllElements('AmountDeposit')
                    .isEmpty
                ? 'No Data'
                : listResult.findAllElements('AmountDeposit').first.innerText;

            final jenisAgreement = listResult
                    .findAllElements('JenisAgreement')
                    .isEmpty
                ? 'No Data'
                : listResult.findAllElements('JenisAgreement').first.innerText;

            final signedby = listResult.findAllElements('Signedby').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Signedby').first.innerText;

            final signedByCharterer =
                listResult.findAllElements('SignedByCharterer').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('SignedByCharterer')
                        .first
                        .innerText;

            final item = listResult.findAllElements('Item').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Item').first.innerText;

            final rute = listResult.findAllElements('Rute').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Rute').first.innerText;

            final amount = listResult.findAllElements('Amount').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Amount').first.innerText;

            final tglVerifikasi = listResult
                    .findAllElements('Tgl_Verifikasi')
                    .isEmpty
                ? 'No Data'
                : listResult.findAllElements('Tgl_Verifikasi').first.innerText;

            final verifiedBy = listResult.findAllElements('VerifiedBy').isEmpty
                ? 'No Data'
                : listResult.findAllElements('VerifiedBy').first.innerText;

            final tglkonfirmasidireksi =
                listResult.findAllElements('Tgl_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('Tgl_konfirmasi_direksi')
                        .first
                        .innerText;

            final confirmedBy =
                listResult.findAllElements('ConfirmedBy').isEmpty
                    ? 'No Data'
                    : listResult.findAllElements('ConfirmedBy').first.innerText;

            final statuskonfirmasidireksi =
                listResult.findAllElements('Status_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('Status_konfirmasi_direksi')
                        .first
                        .innerText;

            final payNo = listResult.findAllElements('PayNo').isEmpty
                ? 'No Data'
                : listResult.findAllElements('PayNo').first.innerText;

            final currPembayaran = listResult
                    .findAllElements('CurrPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult.findAllElements('CurrPembayaran').first.innerText;

            final amountPembayaran =
                listResult.findAllElements('AmountPembayaran').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('AmountPembayaran')
                        .first
                        .innerText;

            final namaBankPenerima =
                listResult.findAllElements('NamaBankPenerima').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('NamaBankPenerima')
                        .first
                        .innerText;
            final tglTerimaPembayaran =
                listResult.findAllElements('Tgl_TerimaPembayaran').isEmpty
                    ? 'No Data'
                    : listResult
                        .findAllElements('Tgl_TerimaPembayaran')
                        .first
                        .innerText;

            final logNo = listResult.findAllElements('LogNo').isEmpty
                ? 'No Data'
                : listResult.findAllElements('LogNo').first.innerText;

            final userInsert = listResult.findAllElements('UserInsert').isEmpty
                ? 'No Data'
                : listResult.findAllElements('UserInsert').first.innerText;

            final insertDate = listResult.findAllElements('InsertDate').isEmpty
                ? 'No Data'
                : listResult.findAllElements('InsertDate').first.innerText;

            final status = listResult.findAllElements('Status').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Status').first.innerText;

            final server = listResult.findAllElements('Server').isEmpty
                ? 'No Data'
                : listResult.findAllElements('Server').first.innerText;

            setState(() {
              if (!mstagreement.any((e) => e['no'] == index + 1)) {
                mstagreement.add({
                  'no': index,
                  'server': server,
                  'noAgreement': noAgreement,
                  'customer': customer,
                  'periodeAwal': periodeAwal,
                  'periodeAkhir': periodeAkhir,
                  'noNPWP': noNPWP,
                  'noReference': noReference,
                  'approvedBy': approvedBy,
                  'tnc': tnc,
                  'createDate': createDate,
                  'createBy': createBy,
                  'tglDeposit': tglDeposit,
                  'currency': currency,
                  'amountDeposit': amountDeposit,
                  'jenisAgreement': jenisAgreement,
                  'signedby': signedby,
                  'signedByCharterer': signedByCharterer,
                  'item': item,
                  'rute': rute,
                  'amount': amount,
                  'tgl_Verifikasi': tglVerifikasi,
                  'verifiedBy': verifiedBy,
                  'tgl_konfirmasi_direksi': tglkonfirmasidireksi,
                  'confirmedBy': confirmedBy,
                  'status_konfirmasi_direksi': statuskonfirmasidireksi,
                  'payNo': payNo,
                  'currPembayaran': currPembayaran,
                  'amountPembayaran': amountPembayaran,
                  'namaBankPenerima': namaBankPenerima,
                  'tgl_TerimaPembayaran': tglTerimaPembayaran,
                  'logNo': logNo,
                  'userInsert': userInsert,
                  'insertDate': insertDate,
                  'status': status,
                });
              }
            });


            //debugPrint(jsonEncode(iom));
          }
        }

        Future.delayed(const Duration(seconds: 1), () async {
          if (mstagreement.isNotEmpty) {
            await DownloadReport();
          }
        });
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
                  fail: 'Error Get Report All',
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
                fail: 'Error Get Report All',
                error: e.toString(),
              );
            });

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
