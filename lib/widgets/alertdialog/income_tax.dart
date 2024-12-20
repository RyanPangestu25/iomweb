// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import '../loading.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'log_error.dart';

class IncomeTax extends StatefulWidget {
  final Function(String) pphAmount;
  final List iom;

  const IncomeTax({
    super.key,
    required this.pphAmount,
    required this.iom,
  });

  @override
  State<IncomeTax> createState() => _IncomeTaxState();
}

class _IncomeTaxState extends State<IncomeTax> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool isCurr = false;
  bool isPercent = false;
  List<String> listCurr = [];
  List<String> listPercent = ['0%', '1.8%', '2.64%'];
  ValueNotifier<List<String>> filteredCurr = ValueNotifier([]);
  ValueNotifier<List<String>> filteredPer = ValueNotifier([
    '0%',
    '1.8%',
    '2.64%',
  ]);

  TextEditingController curr = TextEditingController();
  TextEditingController percent = TextEditingController();
  TextEditingController amount = TextEditingController();

  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();

  Future<void> filterCurr(String query) async {
    setState(() {
      filteredCurr.value = listCurr.where((data) {
        return data.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> filterPer(String query) async {
    setState(() {
      if (query == '0.00') {
        filteredPer.value = listPercent.toList();
      } else {
        filteredPer.value = listPercent.where((data) {
          return data.toString().contains(query.toString());
        }).toList();
      }
    });
  }

  Future<void> getCurr() async {
    try {
      setState(() {
        loading = true;
      });

      const String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ListCurrency xmlns="http://tempuri.org/" />' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_ListCurrency),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/ListCurrency',
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
            final currCode = listResult.findElements('CurrCode').first.text;
            final currName = listResult.findElements('CurrName').first.text;

            setState(() {
              listCurr.add('$currCode - $currName');
            });

            var hasilJson = jsonEncode(listCurr);
            debugPrint(hasilJson);

            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          }
        }

        setState(() {
          filteredCurr.value = listCurr;
        });
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Error Get Currency',
                  error: response.body.toString(),
                );
              });

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('$e');

      if (mounted) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Error Get Currency',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> updatePPH() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<UpdatePPH xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<Currency_PPH>${curr.text.substring(0, 3)}</Currency_PPH>' +
          '<Persentase_PPH>${percent.text.replaceAll(',', '')}</Persentase_PPH>' +
          '<Biaya_PPH>${amount.text.replaceAll(',', '')}</Biaya_PPH>' +
          '<server>${widget.iom.last['server']}</server>' +
          '</UpdatePPH>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_UpdatePPH),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/UpdatePPH',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('UpdatePPHResult').isEmpty
            ? 'GAGAL'
            : document.findAllElements('UpdatePPHResult').first.text;

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
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 2),
              configuration: const IconConfiguration(
                  icon: Icons.done, color: Colors.green),
              title: "Success",
              backgroundColor: Colors.grey[300],
            );

            if (mounted) {
              setState(() {
                loading = false;
              });
            }

            widget.pphAmount(curr.text.substring(0, 3) +
                " " +
                NumberFormat.currency(locale: 'id_ID', symbol: '')
                    .format(
                      double.parse(amount.text.toString().replaceAll(',', '')),
                    )
                    .toString());
            Navigator.of(context).pop();
          });
        }
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Failed Update Tax',
                  error: response.body.toString(),
                );
              });

          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('$e');

      if (mounted) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Failed Update Tax',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  void countTax() {
    double iomValue = double.parse(widget.iom.last['biaya']);
    double percentValue =
        double.tryParse(this.percent.text.replaceAll(',', '')) ?? 0.0;
    double percent = percentValue / 100;
    double total = 0.0;
    setState(() {
      total = iomValue * percent;
      amount.text = NumberFormat.currency(symbol: '').format(total);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getCurr();
    });

    percent.addListener(() {
      countTax();
    });
  }

  @override
  void dispose() {
    percent.removeListener(() {
      countTax();
    });
    curr.dispose();
    percent.dispose();
    amount.dispose();
    _focusNode.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        _focusNode1.unfocus();
        _focusNode2.unfocus();
      },
      child: SizedBox(
        height: size.height,
        child: Stack(
          children: [
            AlertDialog(
              title: const Center(
                child: Text(
                  'INCOME TAX',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                clipBehavior: Clip.antiAlias,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Currency"),
                          SizedBox(height: size.height * 0.005),
                          TextFormField(
                            focusNode: _focusNode,
                            controller: curr,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Color.fromARGB(255, 4, 88, 156),
                                ),
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
                              hintText: 'IDR',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Currency can't be empty";
                              } else if (!listCurr.contains(value)) {
                                return "Currency doesn't match";
                              } else {
                                return null;
                              }
                            },
                            onTap: () async {
                              setState(() {
                                isCurr = true;
                              });
                              filterCurr(curr.text);
                            },
                            onChanged: (value) {
                              setState(() {
                                isCurr = true;
                              });
                              filterCurr(value);
                            },
                            onEditingComplete: () {
                              setState(() {
                                isCurr = true;
                              });
                              filterCurr(curr.text);
                            },
                          ),
                          isCurr
                              ? SizedBox(
                                  height: filteredCurr.value.isEmpty
                                      ? size.height * 0
                                      : filteredCurr.value.length < 3
                                          ? ((MediaQuery.of(context)
                                                              .textScaleFactor *
                                                          14 +
                                                      2 * 18) *
                                                  filteredCurr.value.length) +
                                              2 * size.height * 0.02
                                          : size.height * 0.2,
                                  width: size.width,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    clipBehavior: Clip.antiAlias,
                                    itemCount: filteredCurr.value.length,
                                    itemBuilder: (BuildContext context, index) {
                                      return ListTile(
                                        title: Text(
                                          filteredCurr.value[index],
                                        ),
                                        onTap: () async {
                                          setState(() {
                                            curr.text =
                                                filteredCurr.value[index];
                                            isCurr = false;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                          SizedBox(height: size.height * 0.01),
                          const Text("Percentage (%)"),
                          SizedBox(height: size.height * 0.005),
                          TextFormField(
                            focusNode: _focusNode1,
                            controller: percent,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                            ),
                            inputFormatters: [
                              CurrencyInputFormatter(),
                            ],
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Color.fromARGB(255, 4, 88, 156),
                                ),
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
                              hintText: '1%',
                              suffixText: '%',
                            ),
                            validator: (value) {
                              if (value!.isEmpty || value == '0.00') {
                                return "Percentage can't be empty or 0";
                              } else {
                                return null;
                              }
                            },
                            onTap: () async {
                              setState(() {
                                isPercent = true;
                              });
                              filterPer(curr.text);
                            },
                            onChanged: (value) {
                              setState(() {
                                isPercent = true;
                              });
                              filterPer(value);
                            },
                            onEditingComplete: () {
                              setState(() {
                                isPercent = true;
                              });
                              filterPer(curr.text);
                            },
                          ),
                          isPercent
                              ? SizedBox(
                                  height: filteredPer.value.isEmpty
                                      ? size.height * 0
                                      : filteredPer.value.length < 3
                                          ? ((MediaQuery.of(context)
                                                              .textScaleFactor *
                                                          14 +
                                                      2 * 18) *
                                                  filteredPer.value.length) +
                                              2 * size.height * 0.02
                                          : size.height * 0.2,
                                  width: size.width,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    clipBehavior: Clip.antiAlias,
                                    itemCount: filteredPer.value.length,
                                    itemBuilder: (BuildContext context, index) {
                                      return ListTile(
                                        title: Text(
                                          filteredPer.value[index],
                                        ),
                                        onTap: () async {
                                          setState(() {
                                            percent.text = filteredPer
                                                .value[index]
                                                .replaceAll('%', '');
                                            isPercent = false;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                          SizedBox(height: size.height * 0.01),
                          const Text("Amount"),
                          SizedBox(height: size.height * 0.005),
                          TextFormField(
                            focusNode: _focusNode2,
                            controller: amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: true,
                            ),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            autocorrect: false,
                            inputFormatters: [
                              CurrencyInputFormatter(),
                            ],
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Color.fromARGB(255, 4, 88, 156),
                                ),
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
                              hintText: '0.0',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Amount can't be empty";
                              } else {
                                return null;
                              }
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            await updatePPH();
                          }
                        },
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      color: loading ? null : Colors.green,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            LoadingWidget(
              isLoading: loading,
              title: 'Loading',
            ),
          ],
        ),
      ),
    );
  }
}
