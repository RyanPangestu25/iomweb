// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '/widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import 'log_error.dart';

class VoidReason extends StatefulWidget {
  final Function(bool) isSuccess;
  final List iom;

  const VoidReason({
    super.key,
    required this.isSuccess,
    required this.iom,
  });

  @override
  State<VoidReason> createState() => _VoidReasonState();
}

class _VoidReasonState extends State<VoidReason> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  String userName = '';

  TextEditingController reason = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode1 = FocusNode();

  Future<void> addReason() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<AddReason xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<ConfirmedBy>$userName</ConfirmedBy>' +
          '<VoidReason>${reason.text}</VoidReason>' +
          '<Device>Android</Device>' +
          '<server>${widget.iom.last['server']}</server>' +
          '</AddReason>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_AddReason),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/AddReason',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData = document.findAllElements('AddReasonResult').isEmpty
            ? 'No Data'
            : document.findAllElements('AddReasonResult').first.text;

        if (statusData == "GAGAL") {
          Future.delayed(const Duration(seconds: 1), () {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 1),
              configuration:
                  const IconConfiguration(icon: Icons.error, color: Colors.red),
              title: "Failed Add Reason",
              backgroundColor: Colors.grey[300],
            );

            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          });
        } else {
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 2),
            configuration: const IconConfiguration(
              icon: Icons.done,
              color: Colors.green,
            ),
            title: "Success",
            backgroundColor: Colors.grey[300],
          );

          Future.delayed(const Duration(seconds: 1), () async {
            if (mounted) {
              setState(() {
                loading = false;
              });
            }

            widget.isSuccess(true);
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
                  fail: 'Failed Add Reason',
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
                fail: 'Failed Add Reason',
                error: e.toString(),
              );
            });

        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('userName');

    setState(() {
      this.userName = userName ?? 'No Data';
      debugPrint(userName);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getUser();
    });
  }

  @override
  void dispose() {
    reason.dispose();
    _focusNode.dispose();
    _focusNode1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () async {
        _focusNode.unfocus();
        _focusNode1.unfocus();
      },
      child: Stack(
        children: [
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: const Center(
              child: Text(
                'Void Reason',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
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
                          setState(() {
                            loading = true;
                          });

                          await addReason();
                        }
                      },
                child: const Text(
                  "Submit",
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
                child: const Text(
                  "Close",
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
            content: SingleChildScrollView(
              clipBehavior: Clip.antiAlias,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "IOM No",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: size.height * 0.005),
                    TextFormField(
                      focusNode: _focusNode,
                      readOnly: true,
                      initialValue: widget.iom.last['noIOM'],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    const Text(
                      "Void Reason",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: size.height * 0.005),
                    TextFormField(
                      focusNode: _focusNode1,
                      controller: reason,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      maxLines: 2,
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
                        hintText: 'Description',
                      ),
                      validator: (value) {
                        if (value!.isEmpty || value == ' ') {
                          return "Reason can't be empty";
                        } else if (value.length < 3) {
                          return "Reason can't be lower than 3 characters";
                        } else {
                          return null;
                        }
                      },
                    ),
                  ],
                ),
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
