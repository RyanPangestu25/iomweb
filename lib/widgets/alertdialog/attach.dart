// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, deprecated_member_use, use_build_context_synchronously, must_be_immutable

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_alert/status_alert.dart';
import 'package:xml/xml.dart' as xml;
import '../../backend/constants.dart';
import '../loading.dart';
import 'log_error.dart';
import 'try_again.dart';

class Attachment extends StatefulWidget {
  final Function(bool) isSuccess;
  final List iom;

  const Attachment({
    super.key,
    required this.isSuccess,
    required this.iom,
  });

  @override
  State<Attachment> createState() => _AttachmentState();
}

class _AttachmentState extends State<Attachment> {
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  Uint8List? _image;
  String titleFile = "No File Choosen";
  String fileName = '';
  String fileExt = '';
  String userName = '';
  String level = '';
  String attType = 'Select';
  List<String> listAttType = [
    'Select',
    'Proposal',
    'Bukti Transfer',
    'NPWP/KTP',
    'IOM Signed',
    'Agreement',
  ];

  DropdownMenuItem<String> buildmenuItem(String item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  Future<void> _getFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpeg', 'jpg', 'png'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      Uint8List? filePath = file.bytes;
      String ext = file.extension!;
      setState(() {
        fileName = 'WEB-$attType-${widget.iom.last['noIOM']}';
        fileExt = ext;
        titleFile = 'File Picked';
        _image = filePath;
      });
    } else {
      debugPrint("No File Choosen");
    }
  }

  Future<void> addAttachment() async {
    try {
      setState(() {
        loading = true;
      });

      final String soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>' +
          '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<AddAttachment xmlns="http://tempuri.org/">' +
          '<NoIOM>${widget.iom.last['noIOM']}</NoIOM>' +
          '<Filename>$fileName</Filename>' +
          '<PDFFile>${base64Encode(_image!)}</PDFFile>' +
          '<UploadBy>$userName</UploadBy>' +
          '<Ext>$fileExt</Ext>' +
          '<attachmentType>$attType</attachmentType>' +
          '<server>${widget.iom.last['server']}</server>' +
          '</AddAttachment>' +
          '</soap:Body>' +
          '</soap:Envelope>';

      final response = await http.post(Uri.parse(url_AddAttachment),
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'SOAPAction': 'http://tempuri.org/AddAttachment',
            'Access-Control-Allow-Credentials': 'true',
            'Content-type': 'text/xml; charset=utf-8'
          },
          body: soapEnvelope);

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final statusData =
            document.findAllElements('AddAttachmentResult').isEmpty
                ? 'GAGAL'
                : document.findAllElements('AddAttachmentResult').first.text;

        if (statusData == "GAGAL") {
          Future.delayed(const Duration(seconds: 1), () {
            StatusAlert.show(
              context,
              dismissOnBackgroundTap: true,
              duration: const Duration(seconds: 10),
              configuration: const IconConfiguration(
                icon: Icons.error,
                color: Colors.red,
              ),
              title: "Failed Add Attachment",
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

            StatusAlert.show(
              context,
              dismissOnBackgroundTap: true,
              duration: const Duration(seconds: 10),
              configuration: const IconConfiguration(
                icon: Icons.done,
                color: Colors.green,
              ),
              title: "Success",
              backgroundColor: Colors.grey[300],
            );

            widget.isSuccess(true);
          });
        }
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Desc: ${response.body}');

        if (mounted) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return TryAgain(
                  submit: (value) async {
                    if (value) {
                      await addAttachment();
                    }
                  },
                );
              });

          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return LogError(
                  statusCode: response.statusCode.toString(),
                  fail: 'Failed Add Attachment',
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
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TryAgain(
                submit: (value) async {
                  if (value) {
                    await addAttachment();
                  }
                },
              );
            });

        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return LogError(
                statusCode: '',
                fail: 'Failed Add Attachment',
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
    String? userLevel = prefs.getString('userLevel');

    setState(() {
      this.userName = userName ?? 'No Data';
      debugPrint(userName);

      level = userLevel ?? 'No Data';
      debugPrint(level);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      height: size.height,
      child: Stack(
        children: [
          AlertDialog(
            icon: Icon(
              Icons.attach_file,
              size: size.height * 0.1,
            ),
            iconColor: Colors.green,
            title: const Text('Attachment'),
            content: SingleChildScrollView(
              clipBehavior: Clip.antiAlias,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Attachment Type:'),
                    SizedBox(height: size.height * 0.005),
                    DropdownButtonFormField(
                      value: attType,
                      itemHeight: null,
                      isExpanded: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: listAttType.map(buildmenuItem).toList(),
                      onChanged: (value) async {
                        setState(() {
                          attType = value!;
                        });
                      },
                      validator: (value) {
                        if (value == "Select") {
                          return "Att. Type can't be Select";
                        } else {
                          return null;
                        }
                      },
                    ),
                    SizedBox(height: size.height * 0.02),
                    Container(
                      width: size.width,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.black),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 5),
                          titleFile == 'No File Choosen'
                              ? ElevatedButton(
                                  onPressed: () async {
                                    await _getFile();
                                  },
                                  child: const Text("Choose File"),
                                )
                              : ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      _image = null;
                                      titleFile = 'No File Choosen';
                                    });
                                  },
                                  child: const Text("Clear"),
                                ),
                          const SizedBox(width: 5),
                          SizedBox(
                            width: size.width > 400
                                ? size.width * 0.35
                                : size.width * 0.3,
                            child: Text(
                              titleFile,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          setState(() {
                            loading = true;
                          });

                          if ((titleFile == 'No File Choosen')) {
                            StatusAlert.show(
                              context,
                              duration: const Duration(seconds: 2),
                              configuration: const IconConfiguration(
                                  icon: Icons.error, color: Colors.red),
                              title: "Please Choose The File",
                              backgroundColor: Colors.grey[300],
                            );

                            setState(() {
                              loading = false;
                            });
                          } else {
                            await addAttachment();
                          }
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
    );
  }
}
