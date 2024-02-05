// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:printing/printing.dart';

class DisplayPDF extends StatefulWidget {
  final List pdf;

  const DisplayPDF({
    Key? key,
    required this.pdf,
  }) : super(key: key);

  @override
  State<DisplayPDF> createState() => _DisplayPDFState();
}

class _DisplayPDFState extends State<DisplayPDF> {
  Future<void> _printPDF() async {
    final pdfData = Uint8List.fromList(base64.decode(widget.pdf[0]['pdf']));

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name:
            '${widget.pdf[0]['attachmentType']}-${widget.pdf[0]['noIOM'].toString().replaceAll('/', '-')}__${Random().nextInt(999) + 1}.pdf',
      );

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: false,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          padding: const EdgeInsets.all(20),
          elevation: 10,
          content: Center(
            child: Text(
              'Error saving PDF: $e',
              textAlign: TextAlign.justify,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text("Display PDF"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await _printPDF();
            },
            icon: const Icon(Icons.print),
          ),
        ],
        foregroundColor: Colors.white,
        backgroundColor: Colors.redAccent,
      ),
      body: widget.pdf.isEmpty
          ? const Center(
              child: Text('No Data'),
            )
          : ListView.builder(
              itemCount: widget.pdf.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, index) {
                List<int> byteArray = base64.decode(widget.pdf[index]['pdf']);
                Uint8List uint8List = Uint8List.fromList(byteArray);

                return Container(
                  height: size.height,
                  width: size.width,
                  color: Colors.white,
                  child: SfPdfViewer.memory(uint8List),
                );
              },
            ),
    );
  }
}
