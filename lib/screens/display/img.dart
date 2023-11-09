import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

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
