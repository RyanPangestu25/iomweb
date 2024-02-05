// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DisplayIMG extends StatefulWidget {
  final List image;

  const DisplayIMG({
    Key? key,
    required this.image,
  }) : super(key: key);

  @override
  State<DisplayIMG> createState() => _DisplayIMGState();
}

class _DisplayIMGState extends State<DisplayIMG> {
  Future<void> _printPDF() async {
    final pdfData = Uint8List.fromList(base64.decode(widget.image[0]['pdf']));

    try {
      final doc = pw.Document();

      // Directly add the PDF content as an image on a single page
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              child: pw.Image(pw.MemoryImage(pdfData)),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => await doc.save(),
        name:
            '${widget.image[0]['attachmentType']}-${widget.image[0]['noIOM'].toString().replaceAll('/', '-')}__${Random().nextInt(999) + 1}.pdf',
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
        title: const Text("Display Image"),
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
      body: ListView.builder(
        itemCount: widget.image.length,
        itemBuilder: (context, index) {
          List<int> byteArray = base64.decode(widget.image[index]['pdf']);
          Uint8List uint8List = Uint8List.fromList(byteArray);

          return SizedBox(
            height: size.height,
            width: size.width,
            child: PhotoView(
              imageProvider: MemoryImage(uint8List),
            ),
          );
        },
      ),
    );
  }
}
