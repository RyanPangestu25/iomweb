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
  String instruksi = '';
  bool isShow = false;

  String getInstruksi(String error) {
    if (error.contains('Timeout')) {
      return 'The connection timed out. Please check your internet and try again.';
    } else if (error.contains('SocketException')) {
      return 'No internet connection. Please check your networks.';
    } else if (widget.statusCode != '') {
      switch (widget.statusCode) {
        case '400':
          return "Bad request. Please check your input. Note: Don't use & @ < > : / ? * | ";
        case '401':
          return 'Unauthorized. Please contact IT.'; //Please log in again
        case '403':
          return 'Please contact IT.'; //You do not have permission to access this resource
        case '404':
          return 'Resource not found. Please contact IT.'; //Please check the URL
        case '500':
          return 'Server error. Please try again later or contact IT.';
        default:
          return 'Unexpected server error. Please try again later or contact IT.';
      }
    } else if (error.contains('XML')) {
      return 'Invalid server response. Please contact IT.';
    }
    return 'An unexpected error occurred: ${error.toString()}';
  }

  @override
  void initState() {
    super.initState();
    instruksi = getInstruksi(widget.error);
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
            Navigator.of(context).pop();
          },
          child: const Text(
            "Close",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            FlutterClipboard.copy(widget.error);

            if (mounted) {
              try {
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
              } catch (e) {
                rethrow;
              }
            }
          },
          child: const Text(
            "Copy",
          ),
        ),
      ],
      content: SizedBox(
        height: isShow ? size.height * 0.5 : size.height * 0.15,
        width: size.width * 0.7,
        child: SingleChildScrollView(
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                instruksi,
                textAlign: TextAlign.justify,
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    isShow = !isShow;
                  });
                },
                child: Text(
                  !isShow ? 'Error Description' : 'Close',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: isShow ? Colors.red : null,
                  ),
                ),
              ),
              if (isShow)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(thickness: 3),
                    Text(
                      widget.error,
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}