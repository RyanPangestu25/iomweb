// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously, must_be_immutable, prefer_typing_uninitialized_variables

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:status_alert/status_alert.dart';
import '../../backend/constants.dart';
import '../loading.dart';

class ListCurr extends StatefulWidget {
  final Function(String) curr;

  const ListCurr({
    Key? key,
    required this.curr,
  }) : super(key: key);

  @override
  State<ListCurr> createState() => _ListCurrState();
}

class _ListCurrState extends State<ListCurr> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  List<String> listCurr = [];
  ValueNotifier<List<String>> filteredCurr = ValueNotifier([]);

  TextEditingController searchController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

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
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 1),
          configuration:
              const IconConfiguration(icon: Icons.error, color: Colors.red),
          title: "${response.statusCode}",
          subtitle: "Error Get Currency",
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
        title: "Error Get Currency",
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
      filteredCurr.value = listCurr.where((data) {
        return data.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getCurr();
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
                'Currency List',
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
                                      filteredCurr.value = listCurr;
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
                        itemCount: filteredCurr.value.length,
                        itemBuilder: (BuildContext context, index) {
                          return ListTile(
                            title: Text(
                              filteredCurr.value[index],
                            ),
                            onTap: () async {
                              Navigator.of(context).pop();
                              widget.curr(filteredCurr.value[index]);
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
