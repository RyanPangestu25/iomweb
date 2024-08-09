import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';

class LogError extends StatefulWidget {
  final String statusCode;
  final String fail;
  final String error;

  const LogError({
    super.key,
    required this.statusCode,
    required this.fail,
    required this.error,
  });

  @override
  State<LogError> createState() => _LogErrorState();
}

class _LogErrorState extends State<LogError> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AlertDialog(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.statusCode != ''
              ? Text(
                  widget.statusCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                )
              : const SizedBox.shrink(),
          Text(
            widget.fail,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).textScaler.scale(16),
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FlutterClipboard.copy(widget.error);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                showCloseIcon: false,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                padding: EdgeInsets.all(20),
                elevation: 10,
                content: Center(
                  child: Text(
                    'Error Messages copied!',
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
            );
          },
          child: const Text(
            "Copy",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
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
      content: SizedBox(
        height: size.height * 0.12,
        width: size.width * 0.7,
        child: SingleChildScrollView(
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.error,
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
