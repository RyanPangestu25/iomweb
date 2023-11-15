// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously, must_be_immutable, prefer_typing_uninitialized_variables

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:status_alert/status_alert.dart';
import '../../backend/constants.dart';
import '../loading.dart';

class ListBank extends StatefulWidget {
  final Function(String) namaBank;

  const ListBank({
    Key? key,
    required this.namaBank,
  }) : super(key: key);

  @override
  State<ListBank> createState() => _ListBankState();
}

class _ListBankState extends State<ListBank> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  List<String> listNamaBank = [];
  ValueNotifier<List<String>> filteredBank = ValueNotifier([]);

  TextEditingController searchController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  Future<void> getBank() async {
    try {
      setState(() {
        loading = true;
      });

      const String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ListBank xmlns="http://tempuri.org/" />' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_ListBank),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/ListBank',
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
            final namaBank = listResult.findElements('NamaBank').first.text;

            setState(() {
              listNamaBank.add(namaBank);
            });

            var hasilJson = jsonEncode(listNamaBank);
            debugPrint(hasilJson);

            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          }
        }

        listNamaBank.add('OTHER');

        setState(() {
          filteredBank.value = listNamaBank;
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
          subtitle: "Error Get Bank",
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
        title: "Error Get Bank",
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

  Future<void> filterSearch(String query) async {
    setState(() {
      filteredBank.value = listNamaBank.where((data) {
        return data.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getBank();
    });
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
      child: SizedBox(
        height: size.height,
        child: Stack(
          children: [
            AlertDialog(
              title: const Center(
                  child: Text(
                'Bank List',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              )),
              content: SingleChildScrollView(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
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

                                    setState(() {
                                      filteredBank.value = listNamaBank;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        onChanged: (value) async {
                          await filterSearch(value);
                        },
                        onEditingComplete: () async {
                          await filterSearch(searchController.text);
                        },
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.2,
                      width: size.width,
                      child: ListView.builder(
                        shrinkWrap: true,
                        clipBehavior: Clip.antiAlias,
                        itemCount: filteredBank.value.length,
                        itemBuilder: (BuildContext context, index) {
                          return ListTile(
                            title: Text(
                              filteredBank.value[index],
                            ),
                            onTap: () async {
                              Navigator.of(context).pop();
                              widget.namaBank(filteredBank.value[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
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
                borderRadius: BorderRadius.circular(6.0),
              ),
            ),
            LoadingWidget(isLoading: loading),
          ],
        ),
      ),
    );
  }
}
