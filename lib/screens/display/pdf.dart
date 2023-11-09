import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
