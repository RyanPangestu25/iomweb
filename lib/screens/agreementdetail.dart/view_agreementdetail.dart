// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation

import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:iomweb/backend/constants.dart';
import 'package:iomweb/screens/agreementdetail.dart/detailagreement.dart';
import 'package:iomweb/widgets/alertdialog/confirm_reset.dart';
import 'package:iomweb/widgets/alertdialog/log_error.dart';
import 'package:iomweb/widgets/loading.dart';
import 'package:iomweb/widgets/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;

class ViewAgreementDetail extends StatefulWidget {
  final String title;
  const ViewAgreementDetail({
    super.key,
    required this.title,
  });

  @override
  State<ViewAgreementDetail> createState() => _ViewAgreementDetailState();
}

class _ViewAgreementDetailState extends State<ViewAgreementDetail> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _scrollController1 = ScrollController();

  bool loading = false;
  bool _isConnected = false;
  bool visible = true;
  bool isStatus = false;
  bool isCompany = false;
  bool isYear = false;
  bool isHelp = false;
  bool isPeriod = false;
  bool isAttach = false;
  bool isOpen = false;
  bool isOD = false;
  bool isSL = false;
  List agreementdetail = [];
  List status = [
    'NONE',
    'VERIFIED PENDING PAYMENT',
    'VERIFIED PAYMENT',
    'APPROVED',
    'REJECTED',
    'VOID',
  ];
  List company = [];
  List year = [];
  ValueNotifier<List<dynamic>> filteredStatus = ValueNotifier([
    'NONE',
    'VERIFIED PENDING PAYMENT',
    'VERIFIED PAYMENT',
    'APPROVED',
    'REJECTED',
    'VOID',
  ]);
  ValueNotifier<List<dynamic>> filteredCompany = ValueNotifier([]);
  ValueNotifier<List<dynamic>> filteredYear = ValueNotifier([]);
  ValueNotifier<List<dynamic>> filteredAgreementDetail = ValueNotifier([]);

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

    agreementdetail.clear();
    await getAgreementDetail();

    Future.delayed(const Duration(seconds: 1), () async {
      await filterDate(dateRange.start, dateRange.end);
    });
  }

  Future<void> getAgreementDetail() async {
    try {
      setState(() {
        loading = true;
      });

      const String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetAgreement xmlns="http://tempuri.org/" />' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetAgreement),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetAgreement',
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
            final tglAgreement = listResult.findElements('TglAgreement').isEmpty
                ? 'No Data'
                : listResult.findElements('TglAgreement').first.innerText;
            final perihal = listResult.findElements('Perihal').isEmpty
                ? 'No Data'
                : listResult.findElements('Perihal').first.innerText;
            final description = listResult.findElements('Description').isEmpty
                ? 'No Data'
                : listResult.findElements('Description').first.innerText;
            final typePesawat = listResult.findElements('TypePesawat').isEmpty
                ? 'No Data'
                : listResult.findElements('TypePesawat').first.innerText;
            final currency = listResult.findElements('Currency').isEmpty
                ? ''
                : listResult.findElements('Currency').first.innerText;
            final biayaCharter = listResult.findElements('BiayaCharter').isEmpty
                ? 'No Data'
                : listResult.findElements('BiayaCharter').first.innerText;
            final revenue = listResult.findElements('Revenue').isEmpty
                ? 'No Data'
                : listResult.findElements('Revenue').first.innerText;
            final pembayaran = listResult.findElements('Pembayaran').isEmpty
                ? 'No Data'
                : listResult.findElements('Pembayaran').first.innerText;
            final lainLain = listResult.findElements('LainLain').isEmpty
                ? 'No Data'
                : listResult.findElements('LainLain').first.innerText;
            final tglFinanceverifikasiBelumterimapembayaran = listResult
                    .findElements('tgl_financeverifikasi_belumTerimaPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult
                    .findElements('tgl_financeverifikasi_belumTerimaPembayaran')
                    .first
                    .innerText;
            final tglFinanceverifikasiSudahterimapembayaran = listResult
                    .findElements('tgl_financeverifikasi_sudahTerimaPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult
                    .findElements('tgl_financeverifikasi_sudahTerimaPembayaran')
                    .first
                    .innerText;
            final tglKonfirmasiDireksi =
                listResult.findElements('Tgl_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Tgl_konfirmasi_direksi')
                        .first
                        .innerText;
            final statusKonfirmasiDireksi =
                listResult.findElements('Status_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Status_konfirmasi_direksi')
                        .first
                        .innerText;
            final currencyPPH = listResult.findElements('Currency_PPH').isEmpty
                ? ''
                : listResult.findElements('Currency_PPH').first.innerText;
            final biayaPPH = listResult.findElements('Biaya_PPH').isEmpty
                ? '0'
                : listResult.findElements('Biaya_PPH').first.innerText;
            final rute = listResult.findElements('Rute').isEmpty
                ? 'No Data'
                : listResult.findElements('Rute').first.innerText;
            final tanggal = listResult.findElements('Tanggal').isEmpty
                ? 'No Data'
                : listResult.findElements('Tanggal').first.innerText;
            final server = listResult.findElements('Server').isEmpty
                ? 'No Data'
                : listResult.findElements('Server').first.innerText;

            setState(() {
              if (!agreementdetail.any((data) => data['noAgreementdetail'] == noAgreementdetail)) {
                agreementdetail.add({
                  'noAgreementdetail': noAgreementdetail,
                  'tanggal': tglAgreement,
                  'perihal': perihal,
                  'charter': description,
                  'type': typePesawat,
                  'curr': currency,
                  'biaya': biayaCharter,
                  'revenue': revenue,
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
                  'currencyPPH': currencyPPH,
                  'biayaPPH': biayaPPH,
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
              for (var data in agreementdetail) {
                if (!company.contains(data['server'])) {
                  company.add(data['server']);
                }
              }

              for (var data in agreementdetail) {
                if (!year
                    .contains(DateTime.parse(data['tanggal']).toLocal().year)) {
                  year.add(DateTime.parse(data['tanggal']).toLocal().year);
                }
              }

              setState(() {
                filteredCompany.value = company;
                filteredAgreementDetail.value = agreementdetail;
                filteredYear.value = year;
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
        //debugprint('Error: ${response.statusCode}');
        //debugprint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Error Get Agreement Data',
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
                fail: 'Error Get Agreement Data',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getAgreementDetailOD() async {
    try {
      setState(() {
        loading = true;
      });

      const String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetAgreementOD xmlns="http://tempuri.org/" />' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetMstAgreementOD),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetAgreementOD',
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
            if (mounted) {
              StatusAlert.show(
                context,
                dismissOnBackgroundTap: true,
                duration: const Duration(seconds: 3),
                configuration: const IconConfiguration(
                  icon: Icons.error,
                  color: Colors.red,
                ),
                title: "No Data OD",
                backgroundColor: Colors.grey[300],
              );

              setState(() {
                loading = false;
              });
            }
          } else {
            final noAgreementdetail = listResult.findElements('NoAgreementDetail').isEmpty
                ? 'No Data'
                : listResult.findElements('NoAgreementdetail').first.innerText;
            final tglAgreement = listResult.findElements('TglAgreement').isEmpty
                ? 'No Data'
                : listResult.findElements('TglAgreement').first.innerText;
            final perihal = listResult.findElements('Perihal').isEmpty
                ? 'No Data'
                : listResult.findElements('Perihal').first.innerText;
            final description = listResult.findElements('Description').isEmpty
                ? 'No Data'
                : listResult.findElements('Description').first.innerText;
            final typePesawat = listResult.findElements('TypePesawat').isEmpty
                ? 'No Data'
                : listResult.findElements('TypePesawat').first.innerText;
            final currency = listResult.findElements('Currency').isEmpty
                ? ''
                : listResult.findElements('Currency').first.innerText;
            final biayaCharter = listResult.findElements('BiayaCharter').isEmpty
                ? 'No Data'
                : listResult.findElements('BiayaCharter').first.innerText;
            final revenue = listResult.findElements('Revenue').isEmpty
                ? 'No Data'
                : listResult.findElements('Revenue').first.innerText;
            final pembayaran = listResult.findElements('Pembayaran').isEmpty
                ? 'No Data'
                : listResult.findElements('Pembayaran').first.innerText;
            final lainLain = listResult.findElements('LainLain').isEmpty
                ? 'No Data'
                : listResult.findElements('LainLain').first.innerText;
            final tglFinanceverifikasiBelumterimapembayaran = listResult
                    .findElements('tgl_financeverifikasi_belumTerimaPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult
                    .findElements('tgl_financeverifikasi_belumTerimaPembayaran')
                    .first
                    .innerText;
            final tglFinanceverifikasiSudahterimapembayaran = listResult
                    .findElements('tgl_financeverifikasi_sudahTerimaPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult
                    .findElements('tgl_financeverifikasi_sudahTerimaPembayaran')
                    .first
                    .innerText;
            final tglKonfirmasiDireksi =
                listResult.findElements('Tgl_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Tgl_konfirmasi_direksi')
                        .first
                        .innerText;
            final statusKonfirmasiDireksi =
                listResult.findElements('Status_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Status_konfirmasi_direksi')
                        .first
                        .innerText;
            final currencyPPH = listResult.findElements('Currency_PPH').isEmpty
                ? ''
                : listResult.findElements('Currency_PPH').first.innerText;
            final biayaPPH = listResult.findElements('Biaya_PPH').isEmpty
                ? '0'
                : listResult.findElements('Biaya_PPH').first.innerText;
            final rute = listResult.findElements('Rute').isEmpty
                ? 'No Data'
                : listResult.findElements('Rute').first.innerText;
            final tanggal = listResult.findElements('Tanggal').isEmpty
                ? 'No Data'
                : listResult.findElements('Tanggal').first.innerText;
            final server = listResult.findElements('Server').isEmpty
                ? 'No Data'
                : listResult.findElements('Server').first.innerText;

            setState(() {
              if (!agreementdetail.any((data) => data['noAgreementdetail'] == noAgreementdetail)) {
                agreementdetail.add({
                  'noAgreementdetail': noAgreementdetail,
                  'tanggal': tglAgreement,
                  'perihal': perihal,
                  'charter': description,
                  'type': typePesawat,
                  'curr': currency,
                  'biaya': biayaCharter,
                  'revenue': revenue,
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
                  'currencyPPH': currencyPPH,
                  'biayaPPH': biayaPPH,
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
              for (var data in agreementdetail) {
                if (!company.contains(data['server'])) {
                  company.add(data['server']);
                }
              }

              for (var data in agreementdetail) {
                if (!year
                    .contains(DateTime.parse(data['tanggal']).toLocal().year)) {
                  year.add(DateTime.parse(data['tanggal']).toLocal().year);
                }
              }

              setState(() {
                filteredCompany.value = company;
                filteredAgreementDetail.value = agreementdetail;
                filteredYear.value = year;
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
        //debugprint('Error: ${response.statusCode}');
        //debugprint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Error Get Agreement OD',
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
                fail: 'Error Get Agreement OD',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getAgreementDetailSL() async {
    try {
      setState(() {
        loading = true;
      });

      const String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<GetAgreementSL xmlns="http://tempuri.org/" />' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_GetAgreementSL),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/GetAgreementSL',
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
            if (mounted) {
              StatusAlert.show(
                context,
                dismissOnBackgroundTap: true,
                duration: const Duration(seconds: 3),
                configuration: const IconConfiguration(
                  icon: Icons.error,
                  color: Colors.red,
                ),
                title: "No Data SL",
                backgroundColor: Colors.grey[300],
              );

              setState(() {
                loading = false;
              });
            }
          } else {
            final noAgreementdetail = listResult.findElements('NoAgreementDetail').isEmpty
                ? 'No Data'
                : listResult.findElements('NoAgreementDetail').first.innerText;
            final tglAgreement = listResult.findElements('TglAgreement').isEmpty
                ? 'No Data'
                : listResult.findElements('TglAgreement').first.innerText;
            final perihal = listResult.findElements('Perihal').isEmpty
                ? 'No Data'
                : listResult.findElements('Perihal').first.innerText;
            final description = listResult.findElements('Description').isEmpty
                ? 'No Data'
                : listResult.findElements('Description').first.innerText;
            final typePesawat = listResult.findElements('TypePesawat').isEmpty
                ? 'No Data'
                : listResult.findElements('TypePesawat').first.innerText;
            final currency = listResult.findElements('Currency').isEmpty
                ? ''
                : listResult.findElements('Currency').first.innerText;
            final biayaCharter = listResult.findElements('BiayaCharter').isEmpty
                ? 'No Data'
                : listResult.findElements('BiayaCharter').first.innerText;
            final revenue = listResult.findElements('Revenue').isEmpty
                ? 'No Data'
                : listResult.findElements('Revenue').first.innerText;
            final pembayaran = listResult.findElements('Pembayaran').isEmpty
                ? 'No Data'
                : listResult.findElements('Pembayaran').first.innerText;
            final lainLain = listResult.findElements('LainLain').isEmpty
                ? 'No Data'
                : listResult.findElements('LainLain').first.innerText;
            final tglFinanceverifikasiBelumterimapembayaran = listResult
                    .findElements('tgl_financeverifikasi_belumTerimaPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult
                    .findElements('tgl_financeverifikasi_belumTerimaPembayaran')
                    .first
                    .innerText;
            final tglFinanceverifikasiSudahterimapembayaran = listResult
                    .findElements('tgl_financeverifikasi_sudahTerimaPembayaran')
                    .isEmpty
                ? 'No Data'
                : listResult
                    .findElements('tgl_financeverifikasi_sudahTerimaPembayaran')
                    .first
                    .innerText;
            final tglKonfirmasiDireksi =
                listResult.findElements('Tgl_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Tgl_konfirmasi_direksi')
                        .first
                        .innerText;
            final statusKonfirmasiDireksi =
                listResult.findElements('Status_konfirmasi_direksi').isEmpty
                    ? 'No Data'
                    : listResult
                        .findElements('Status_konfirmasi_direksi')
                        .first
                        .innerText;
            final currencyPPH = listResult.findElements('Currency_PPH').isEmpty
                ? ''
                : listResult.findElements('Currency_PPH').first.innerText;
            final biayaPPH = listResult.findElements('Biaya_PPH').isEmpty
                ? '0'
                : listResult.findElements('Biaya_PPH').first.innerText;
            final rute = listResult.findElements('Rute').isEmpty
                ? 'No Data'
                : listResult.findElements('Rute').first.innerText;
            final tanggal = listResult.findElements('Tanggal').isEmpty
                ? 'No Data'
                : listResult.findElements('Tanggal').first.innerText;
            final server = listResult.findElements('Server').isEmpty
                ? 'No Data'
                : listResult.findElements('Server').first.innerText;

            setState(() {
              if (!agreementdetail.any((data) => data['noAgreementdetail'] == noAgreementdetail)) {
                agreementdetail.add({
                  'noAgreementdetail': noAgreementdetail,
                  'tanggal': tglAgreement,
                  'perihal': perihal,
                  'charter': description,
                  'type': typePesawat,
                  'curr': currency,
                  'biaya': biayaCharter,
                  'revenue': revenue,
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
                  'currencyPPH': currencyPPH,
                  'biayaPPH': biayaPPH,
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
              for (var data in agreementdetail) {
                if (!company.contains(data['server'])) {
                  company.add(data['server']);
                }
              }

              for (var data in agreementdetail) {
                if (!year
                    .contains(DateTime.parse(data['tanggal']).toLocal().year)) {
                  year.add(DateTime.parse(data['tanggal']).toLocal().year);
                }
              }

              setState(() {
                filteredCompany.value = company;
                filteredAgreementDetail.value = agreementdetail;
                filteredYear.value = year;
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
        //debugprint('Error: ${response.statusCode}');
        //debugprint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Error Get Agreement SL',
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
                fail: 'Error Get Agreement SL',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> filterStatus(DateTime startDate, DateTime endDate) async {
    if (isStatus && !isCompany && !isPeriod && searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          return status;
        }).toList();
      });
    } else if (isStatus &&
        !isCompany &&
        isPeriod &&
        searchController.text.isEmpty) {
      filterDate(startDate, endDate);
    } else if (!isStatus &&
        !isCompany &&
        isPeriod &&
        searchController.text.isEmpty) {
      filterDate(startDate, endDate);
    } else if (isStatus &&
        !isCompany &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else if (!isStatus &&
        !isCompany &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else if (isStatus && isCompany) {
      filterCompany(startDate, endDate);
    } else if (!isStatus && isCompany) {
      filterCompany(startDate, endDate);
    } else if (isStatus && isYear) {
      filterYear(startDate, endDate);
    } else if (!isStatus && isYear) {
      filterYear(startDate, endDate);
    } else {
      setState(() {
        filteredAgreementDetail.value = agreementdetail;
      });
    }
  }

  Future<void> filterCompany(DateTime startDate, DateTime endDate) async {
    if (!isStatus && isCompany && !isPeriod && searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final server = data['server'] == filteredCompany.value.last;
          return server;
        }).toList();
      });
    } else if (!isStatus && isCompany && isPeriod) {
      filterDate(startDate, endDate);
    } else if (!isStatus && !isCompany && isPeriod) {
      filterDate(startDate, endDate);
    } else if (!isStatus &&
        isCompany &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else if (!isStatus &&
        !isCompany &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else if (isStatus &&
        isCompany &&
        !isPeriod &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final server = data['server'] == filteredCompany.value.last;
          return status && server;
        }).toList();
      });
    } else if (isStatus &&
        !isCompany &&
        !isPeriod &&
        searchController.text.isEmpty) {
      filterStatus(startDate, endDate);
    } else if (isStatus && isCompany && isPeriod) {
      filterDate(startDate, endDate);
    } else if (isStatus && !isCompany && isPeriod) {
      filterDate(startDate, endDate);
    } else if (isStatus &&
        isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isEmpty) {
      filterYear(startDate, endDate);
    } else if (isStatus &&
        !isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isEmpty) {
      filterYear(startDate, endDate);
    } else if (!isStatus &&
        isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isEmpty) {
      filterYear(startDate, endDate);
    } else if (!isStatus &&
        isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else if (isStatus &&
        isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else if (isStatus &&
        isCompany &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else {
      setState(() {
        filteredAgreementDetail.value = agreementdetail;
      });
    }
  }

  Future<void> filterYear(DateTime startDate, DateTime endDate) async {
    if (!isStatus &&
        !isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          return tahun;
        }).toList();
      });
    } else if (!isStatus && !isCompany && isYear && isPeriod) {
      filterDate(startDate, endDate);
    } else if (!isStatus && !isCompany && !isYear && isPeriod) {
      filterDate(startDate, endDate);
    } else if (!isStatus &&
        !isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else if (!isStatus &&
        !isCompany &&
        !isYear &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else if (isStatus &&
        !isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isEmpty) {
      filterStatus(startDate, endDate);
    } else if (isStatus &&
        !isCompany &&
        !isYear &&
        !isPeriod &&
        searchController.text.isEmpty) {
      filterStatus(startDate, endDate);
    } else if (isStatus &&
        isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final server = data['server'] == filteredCompany.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          return status && server && tahun;
        }).toList();
      });
    } else if (!isStatus &&
        isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final server = data['server'] == filteredCompany.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          return server && tahun;
        }).toList();
      });
    } else if (!isStatus &&
        isCompany &&
        !isYear &&
        !isPeriod &&
        searchController.text.isEmpty) {
      filterCompany(startDate, endDate);
    } else if (isStatus &&
        isCompany &&
        !isYear &&
        !isPeriod &&
        searchController.text.isEmpty) {
      filterCompany(startDate, endDate);
    } else if (isStatus && !isCompany && isYear && isPeriod) {
      filterDate(startDate, endDate);
    } else if (isStatus && !isCompany && !isYear && isPeriod) {
      filterDate(startDate, endDate);
    } else if (isStatus && isCompany && isYear && isPeriod) {
      filterDate(startDate, endDate);
    } else if (isStatus && isCompany && !isYear && isPeriod) {
      filterDate(startDate, endDate);
    } else if (!isStatus && isCompany && isYear && isPeriod) {
      filterDate(startDate, endDate);
    } else if (!isStatus && isCompany && !isYear && isPeriod) {
      filterDate(startDate, endDate);
    } else if (!isStatus &&
        isCompany &&
        isYear &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else if (!isStatus &&
        isCompany &&
        !isYear &&
        !isPeriod &&
        searchController.text.isNotEmpty) {
      filterSearch(searchController.text);
    } else {
      setState(() {
        filteredAgreementDetail.value = agreementdetail;
      });
    }
  }

  Future<void> filterDate(DateTime startDate, DateTime endDate) async {
    DateTime period = DateTime.now();

    setState(() {
      filteredAgreementDetail.value = agreementdetail.where((data) {
        period = DateTime.parse(data['tanggal']).toLocal();
        return period.isAfter(startDate) && period.isBefore(endDate) ||
            period.isAtSameMomentAs(startDate) ||
            period.isAtSameMomentAs(endDate);
      }).toList();
    });

    if (isStatus && !isCompany && !isYear && searchController.text.isNotEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          period = DateTime.parse(data['tanggal']).toLocal();
          return status &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              status &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate) ||
              status &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              status &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (isStatus &&
        !isCompany &&
        !isYear &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          period = DateTime.parse(data['tanggal']).toLocal();
          return status &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status && period.isAtSameMomentAs(startDate) ||
              status && period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (isStatus &&
        isCompany &&
        !isYear &&
        searchController.text.isNotEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final server = data['server'] == filteredCompany.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          period = DateTime.parse(data['tanggal']).toLocal();
          return status &&
                  server &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status &&
                  server &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              status &&
                  server &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate) ||
              status &&
                  server &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status &&
                  server &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              status &&
                  server &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (isStatus &&
        isCompany &&
        !isYear &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final server = data['server'] == filteredCompany.value.last;
          period = DateTime.parse(data['tanggal']).toLocal();
          return status &&
                  server &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status && server && period.isAtSameMomentAs(startDate) ||
              status && server && period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (isStatus &&
        isCompany &&
        isYear &&
        searchController.text.isNotEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final server = data['server'] == filteredCompany.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          period = DateTime.parse(data['tanggal']).toLocal();
          return status &&
                  server &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status &&
                  server &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              status &&
                  server &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate) ||
              status &&
                  server &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status &&
                  server &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              status &&
                  server &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (isStatus &&
        isCompany &&
        isYear &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final server = data['server'] == filteredCompany.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          period = DateTime.parse(data['tanggal']).toLocal();
          return status &&
                  server &&
                  tahun &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status && server && tahun && period.isAtSameMomentAs(startDate) ||
              status && server && tahun && period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (!isStatus &&
        isCompany &&
        !isYear &&
        searchController.text.isNotEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final server = data['server'] == filteredCompany.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          period = DateTime.parse(data['tanggal']).toLocal();
          return server &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              server &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              server &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate) ||
              server &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              server &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              server &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (!isStatus &&
        isCompany &&
        !isYear &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final server = data['server'] == filteredCompany.value.last;
          period = DateTime.parse(data['tanggal']).toLocal();
          return server &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              server && period.isAtSameMomentAs(startDate) ||
              server && period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (!isStatus &&
        isCompany &&
        isYear &&
        searchController.text.isNotEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final server = data['server'] == filteredCompany.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          period = DateTime.parse(data['tanggal']).toLocal();
          return server &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              server &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              server &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate) ||
              server &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              server &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              server &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (!isStatus &&
        isCompany &&
        isYear &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final server = data['server'] == filteredCompany.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          period = DateTime.parse(data['tanggal']).toLocal();
          return server &&
                  tahun &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              server && tahun && period.isAtSameMomentAs(startDate) ||
              server && tahun && period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (!isStatus &&
        !isCompany &&
        isYear &&
        searchController.text.isNotEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          period = DateTime.parse(data['tanggal']).toLocal();
          return tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate) ||
              tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (!isStatus &&
        !isCompany &&
        isYear &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          period = DateTime.parse(data['tanggal']).toLocal();
          return tahun &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              tahun && period.isAtSameMomentAs(startDate) ||
              tahun && period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (!isStatus &&
        !isCompany &&
        !isYear &&
        searchController.text.isNotEmpty) {
      filteredAgreementDetail.value = agreementdetail.where((data) {
        final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
        final charter = data['charter'].toLowerCase();
        period = DateTime.parse(data['tanggal']).toLocal();
        return noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                period.isAfter(startDate) &&
                period.isBefore(endDate) ||
            noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                period.isAtSameMomentAs(startDate) ||
            noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                period.isAtSameMomentAs(endDate) ||
            charter.contains(searchController.text.toLowerCase()) &&
                period.isAfter(startDate) &&
                period.isBefore(endDate) ||
            charter.contains(searchController.text.toLowerCase()) &&
                period.isAtSameMomentAs(startDate) ||
            charter.contains(searchController.text.toLowerCase()) &&
                period.isAtSameMomentAs(endDate);
      }).toList();
    } else if (isStatus &&
        !isCompany &&
        isYear &&
        searchController.text.isEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          period = DateTime.parse(data['tanggal']).toLocal();
          return status &&
                  tahun &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status && tahun && period.isAtSameMomentAs(startDate) ||
              status && tahun && period.isAtSameMomentAs(endDate);
        }).toList();
      });
    } else if (isStatus &&
        !isCompany &&
        isYear &&
        searchController.text.isNotEmpty) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          period = DateTime.parse(data['tanggal']).toLocal();
          return status &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              status &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate) ||
              status &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAfter(startDate) &&
                  period.isBefore(endDate) ||
              status &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(startDate) ||
              status &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase()) &&
                  period.isAtSameMomentAs(endDate);
        }).toList();
      });
    }
  }

  Future<void> filterSearch(String query) async {
    setState(() {
      filteredAgreementDetail.value = agreementdetail.where((data) {
        final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
        final charter = data['charter'].toLowerCase();
        return noAgreementdetail.contains(query.toLowerCase()) ||
            charter.contains(query.toLowerCase());
      }).toList();
    });

    if (isStatus && isCompany && isYear) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final server = data['server'] == filteredCompany.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          return status &&
                  server &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) ||
              status &&
                  server &&
                  charter.contains(searchController.text.toLowerCase());
        }).toList();
      });
    } else if (isStatus && isCompany && !isYear) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final server = data['server'] == filteredCompany.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          return status &&
                  server &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) ||
              status &&
                  server &&
                  charter.contains(searchController.text.toLowerCase());
        }).toList();
      });
    } else if (isStatus && !isCompany && isYear) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          return status &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) ||
              status &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase());
        }).toList();
      });
    } else if (!isStatus && isCompany && isYear) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final server = data['server'] == filteredCompany.value.last;
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          return server &&
                  tahun &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) ||
              server &&
                  tahun &&
                  charter.contains(searchController.text.toLowerCase());
        }).toList();
      });
    } else if (isStatus) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final status = data['status'] == filteredStatus.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          return status &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) ||
              status && charter.contains(searchController.text.toLowerCase());
        }).toList();
      });
    } else if (isCompany) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final server = data['server'] == filteredCompany.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          return server &&
                  noAgreementdetail.contains(searchController.text.toLowerCase()) ||
              server && charter.contains(searchController.text.toLowerCase());
        }).toList();
      });
    } else if (isYear) {
      setState(() {
        filteredAgreementDetail.value = agreementdetail.where((data) {
          final tahun = DateTime.parse(data['tanggal']).toLocal().year ==
              filteredYear.value.last;
          final noAgreementdetail = data['noAgreementdetail'].toLowerCase();
          final charter = data['charter'].toLowerCase();
          return tahun && noAgreementdetail.contains(searchController.text.toLowerCase()) ||
              tahun && charter.contains(searchController.text.toLowerCase());
        }).toList();
      });
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

  Future<void> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userOpen = prefs.getString('userOpen');
    String? isOD = prefs.getString('isOD');
    String? isSL = prefs.getString('isSL');
    String nik = prefs.getString('nik') ?? 'No Data';

    setState(() {
      isOpen = userOpen == 'true' ? true : false;
      this.isOD = isOD == 'true' ? true : false;
      this.isSL = isSL == 'true' ? true : false;
      //debugprint('$isOpen');
    });

    if (this.isOD) {
      await getAgreementDetailOD();
    } else if (this.isSL) {
      await getAgreementDetailSL();
    } else {
      await getAgreementDetail();

      if (nik != 'No Data' &&
          (nik == '56000031' || nik == '101010' || nik == '101011')) {
        await getAgreementDetailOD();
        await getAgreementDetailSL();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initConnection();
      await getUser();
    });

    date.text =
        '${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.start.toString()).toLocal())} - ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.end.toString()).toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onDoubleTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        drawer: loading
            ? SizedBox(
                child: Center(
                  child: Text(
                    'Please wait till the loading done,',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).textScaler.scale(10)),
                  ),
                ),
              )
            : const Sidebar(),
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
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
                          isStatus = false;
                          isPeriod = false;
                          isCompany = false;
                          isYear = false;
                          searchController.clear();
                          filteredStatus.value = status;
                          filteredCompany.value = company;
                        });
                        agreementdetail.clear();
                        await getAgreementDetail();
                      },
                icon: const Icon(Icons.refresh)),
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
                icon: const Icon(Icons.help_outline))
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
                    children:  [
                      const Text('Filter By Status'),
                      SizedBox(
                        height: size.height * 0.1,
                        width: size.width,
                        child: Scrollbar(
                            controller: ScrollController(),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredStatus.value.length,
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.antiAlias,
                              controller: _scrollController,
                              separatorBuilder:
                                  (BuildContext context, int index) {
                                return SizedBox(width: size.width * 0.02);
                              },
                              itemBuilder: (context, index) {
                                return Row(
                                  children: [
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isStatus ? Colors.green : null,
                                          foregroundColor:
                                              isStatus ? Colors.white : null,
                                        ),
                                        onPressed: loading
                                            ? null
                                            : () async {
                                                setState(() {
                                                  isStatus = !isStatus;
                                                  filteredStatus.value =
                                                      isStatus
                                                          ? [status[index]]
                                                          : status;
                                                });
                                                await filterStatus(
                                                    dateRange.start,
                                                    dateRange.end);
                                              },
                                        child: isStatus
                                            ? Row(
                                                children: [
                                                  Text(filteredStatus
                                                      .value[index]),
                                                  SizedBox(
                                                    height: size.height * 0.02,
                                                  ),
                                                   const Icon(Icons.done)
                                                ],
                                              )
                                            : Text(filteredStatus.value[index]))
                                  ],
                                );
                              },
                            )),
                      ),
                     const  Text('Filter By Company'),
                      SizedBox(
                        height: filteredCompany.value.isEmpty
                            ? 0
                            : size.height * 0.1,
                        width: size.width,
                        child: Scrollbar(
                          controller: _scrollController1,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredCompany.value.length,
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.antiAlias,
                            controller: _scrollController1,
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return SizedBox(width: size.width * 0.02);
                            },
                            itemBuilder: (BuildContext context, index) {
                              return Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isCompany ? Colors.green : null,
                                      foregroundColor:
                                          isCompany ? Colors.white : null,
                                    ),
                                    onPressed: loading
                                        ? null
                                        : () async {
                                            setState(() {
                                              isCompany = !isCompany;
                                              filteredCompany.value = isCompany
                                                  ? [company[index]]
                                                  : company;
                                            });

                                            await filterCompany(
                                                dateRange.start, dateRange.end);
                                          },
                                    child: isCompany
                                        ? Row(
                                            children: [
                                              Text(
                                                  filteredCompany.value[index]),
                                              SizedBox(
                                                  width: size.width * 0.01),
                                              const Icon(Icons.done),
                                            ],
                                          )
                                        : Text(filteredCompany.value[index]),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const Text('Filter By Year'),
                      SizedBox(
                        height:
                            filteredYear.value.isEmpty ? 0 : size.height * 0.1,
                        width: size.width,
                        child: Scrollbar(
                          controller: _scrollController1,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredYear.value.length,
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.antiAlias,
                            controller: _scrollController1,
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return SizedBox(width: size.width * 0.02);
                            },
                            itemBuilder: (BuildContext context, index) {
                              return Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isYear ? Colors.green : null,
                                      foregroundColor:
                                          isYear ? Colors.white : null,
                                    ),
                                    onPressed: loading
                                        ? null
                                        : () async {
                                            setState(() {
                                              isYear = !isYear;
                                              filteredYear.value =
                                                  isYear ? [year[index]] : year;
                                            });

                                            await filterYear(
                                                dateRange.start, dateRange.end);
                                          },
                                    child: isYear
                                        ? Row(
                                            children: [
                                              Text(filteredYear.value[index]
                                                  .toString()),
                                              SizedBox(
                                                  width: size.width * 0.01),
                                              const Icon(Icons.done),
                                            ],
                                          )
                                        : Text(filteredYear.value[index]
                                            .toString()),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const Divider(
                        thickness: 2,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         const Text('Period From - Period To (Agreement Date)'),
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
                      const Text("Search (Agreement No./Agreement Name)"),
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
                      Text(
                          'Total Data = ${filteredAgreementDetail.value.length}'),
                      SizedBox(
                        height: size.height * 0.7,
                        child: Stack(
                          children: [
                            filteredAgreementDetail.value.isEmpty
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
                                    itemCount:
                                        filteredAgreementDetail.value.length,
                                    itemBuilder: (BuildContext context, index) {
                                      return Padding(
                                          padding:const  EdgeInsets.only(
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
                                                    Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                      return DetailAgreement(
                                                        isRefresh:
                                                            (value) async {
                                                          setState(() {
                                                            loading = true;
                                                            dateRange =
                                                                DateTimeRange(
                                                                    start: DateTime
                                                                        .now(),
                                                                    end: DateTime
                                                                        .now());
                                                            date.text =
                                                                '${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.start.toString()).toLocal())} - ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.end.toString()).toLocal())}';
                                                            isStatus = false;
                                                            isPeriod = false;
                                                            isCompany = false;
                                                            isYear = false;
                                                            searchController
                                                                .clear();
                                                            filteredStatus
                                                                .value = status;
                                                            filteredCompany
                                                                    .value =
                                                                company;
                                                          });
                                                          agreementdetail
                                                              .clear();
                                                          await getAgreementDetail();
                                                        },
                                                        agreementdetail:[filteredAgreementDetail.value[index]],
                                                      );
                                                    }));
                                                  },
                                            child: CupertinoListTile(
                                              leading: filteredAgreementDetail
                                                                  .value[index]
                                                              ['server'] ==
                                                          'LION' ||
                                                      filteredAgreementDetail
                                                                  .value[index]
                                                              ['server'] ==
                                                          'ANGKASA'
                                                  ? Image.asset(
                                                      'assets/images/logo.png')
                                                  : filteredAgreementDetail.value[index]
                                                              ['server'] ==
                                                          'SAJ'
                                                      ? Image.asset(
                                                          'assets/images/logosuper.png')
                                                      : filteredAgreementDetail
                                                                      .value[index]
                                                                  ['server'] ==
                                                              'WINGS'
                                                          ? Image.asset(
                                                              'assets/images/logowings.png')
                                                          : filteredAgreementDetail.value[index]['server'] == 'BATIK'
                                                              ? Image.asset('assets/images/logobatik.png')
                                                              : filteredAgreementDetail.value[index]['server'] == 'THAI'
                                                                  ? Image.asset('assets/images/logothai.png')
                                                                  : const Icon(Icons.business),
                                              title: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      filteredAgreementDetail
                                                              .value[index]
                                                          ['noAgreementdetail'].toString(),
                                                      textAlign: TextAlign.left,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    isOpen
                                                        ? filteredAgreementDetail
                                                                            .value[
                                                                        index][
                                                                    'tanggalRute'] ==
                                                                'No Data'
                                                            ? const SizedBox
                                                                .shrink()
                                                            : DateTime.parse(filteredAgreementDetail.value[index]
                                                                            [
                                                                            'tanggalRute'])
                                                                        .toLocal()
                                                                        .year ==
                                                                    DateTime.now()
                                                                        .year
                                                                ? IconButton(
                                                                    onPressed:
                                                                        () async {
                                                                      await showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (BuildContext context) {
                                                                            return ResetConfirmation(
                                                                              isSuccess: (value) async {
                                                                                if (value) {
                                                                                  setState(() {
                                                                                    loading = true;
                                                                                    dateRange = DateTimeRange(
                                                                                      start: DateTime.now(),
                                                                                      end: DateTime.now(),
                                                                                    );
                                                                                    date.text = '${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.start.toString()).toLocal())} - ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateRange.end.toString()).toLocal())}';
                                                                                    isStatus = false;
                                                                                    isPeriod = false;
                                                                                    isCompany = false;
                                                                                    isYear = false;
                                                                                    searchController.clear();
                                                                                    filteredStatus.value = status;
                                                                                    filteredCompany.value = company;
                                                                                  });

                                                                                  agreementdetail.clear();
                                                                                  await getAgreementDetail();
                                                                                }
                                                                              },
                                                                              noIOM: '',
                                                                              noAgreement: '',                                                                             noAgreementDetail: filteredAgreementDetail.value[index]['noAgreementdetail'],
                                                                              server: filteredAgreementDetail.value[index]['server'],
                                                                              isIOM: false,
                                                                            );
                                                                          });
                                                                    },
                                                                    tooltip:
                                                                        'Reset Approval',
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .approval,
                                                                      color: Colors
                                                                          .red,
                                                                    ),
                                                                  )
                                                                : const SizedBox
                                                                    .shrink()
                                                        : const SizedBox
                                                            .shrink()
                                                  ],
                                                ),
                                              ),
                                              subtitle: Column(
                                                children: [
                                                  SizedBox(
                                                    width: size.width * 0.65,
                                                    child: Row(
                                                      children: [
                                                        const Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text('Agreement Date '),
                                                            Text(
                                                                'Charter Name '),
                                                            Text('Route '),
                                                            Text(
                                                                'Charter Date '),
                                                            Text('Status '),
                                                          ],
                                                        ),
                                                        const Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(': '),
                                                            Text(': '),
                                                            Text(': '),
                                                            Text(': '),
                                                            Text(': '),
                                                          ],
                                                        ),
                                                        Expanded(
                                                            child: SizedBox(
                                                          width:
                                                              size.width * 0.1,
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                filteredAgreementDetail.value[index]
                                                                            [
                                                                            'tanggal'] ==
                                                                        'No Data'
                                                                    ? '${filteredAgreementDetail.value[index]['tanggal']}'
                                                                    : DateFormat(
                                                                            'dd MMM yyyy')
                                                                        .format(
                                                                            DateTime.parse(filteredAgreementDetail.value[index]['tanggal']).toLocal()),
                                                              ),
                                                              SingleChildScrollView(
                                                                scrollDirection:
                                                                    Axis.horizontal,
                                                                child: Text(
                                                                  filteredAgreementDetail
                                                                              .value[
                                                                          index]
                                                                      [
                                                                      'charter'],
                                                                ),
                                                              ),
                                                              Text(
                                                                filteredAgreementDetail
                                                                        .value[
                                                                    index]['rute'],
                                                              ),
                                                              Text(
                                                                filteredAgreementDetail.value[index]
                                                                            [
                                                                            'tanggalRute'] ==
                                                                        'No Data'
                                                                    ? filteredAgreementDetail
                                                                            .value[index]
                                                                        [
                                                                        'tanggalRute']
                                                                    : DateFormat(
                                                                            'dd MMM yyyy')
                                                                        .format(
                                                                            DateTime.parse(filteredAgreementDetail.value[index]['tanggalRute']).toLocal()),
                                                              ),
                                                              SizedBox(
                                                                width:
                                                                    size.width *
                                                                        0.45,
                                                                child:
                                                                    Text.rich(
                                                                  TextSpan(
                                                                    text: filteredAgreementDetail
                                                                        .value[
                                                                            index]
                                                                            [
                                                                            'status']
                                                                        .toString()
                                                                        .toUpperCase(),
                                                                    style:
                                                                        TextStyle(
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: filteredAgreementDetail.value[index]['status'] == 'VERIFIED PENDING PAYMENT' ||
                                                                              filteredAgreementDetail.value[index]['status'] ==
                                                                                  'VERIFIED PAYMENT'
                                                                          ? Colors
                                                                              .blue
                                                                          : filteredAgreementDetail.value[index]['status'] == 'APPROVED'
                                                                              ? Colors.green
                                                                              : filteredAgreementDetail.value[index]['status'] == 'REJECTED' || filteredAgreementDetail.value[index]['status'] == 'VOID'
                                                                                  ? Colors.red
                                                                                  : Colors.black,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ))
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                              trailing: filteredAgreementDetail.value[index]['status'] =='VERIFIED PAYMENT' ||
                                                    filteredAgreementDetail.value[index]['status'] =='APPROVED' ||
                                                    filteredAgreementDetail.value[index]['status'] == 'REJECTED' ||
                                                    filteredAgreementDetail.value[index]['status'] =='VOID' ?
                                                    const Icon(Icons.attach_file): null,
                                                     padding: const EdgeInsets.all(10),
                                                    
                                            ),
                                          ));
                                    }),
                                     LoadingWidget(
                                      isLoading: loading,
                                      title: 'Loading',
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Visibility(
                  visible: isHelp,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: size.height * 0.16,
                      margin: EdgeInsets.only(top: size.height * 0.02),
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