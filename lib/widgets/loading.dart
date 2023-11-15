import 'dart:async';
import 'package:flutter/material.dart';

class LoadingWidget extends StatefulWidget {
  final bool isLoading;

  const LoadingWidget({Key? key, required this.isLoading}) : super(key: key);

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> {
  bool titik1 = false;
  bool titik2 = false;
  bool titik3 = false;
  Timer? timer;

  void startTimer() {
    const duration = Duration(seconds: 1);
    timer = Timer.periodic(duration, (Timer t) {
      setState(() {
        if (!titik1) {
          titik1 = true;
          titik2 = false;
          titik3 = false;
        } else if (titik1 && !titik2 && !titik3) {
          titik1 = true;
          titik2 = true;
          titik3 = false;
        } else if (titik2 && !titik3) {
          titik1 = true;
          titik2 = true;
          titik3 = true;
        } else if (titik3) {
          titik1 = false;
          titik2 = false;
          titik3 = false;
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      startTimer();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return widget.isLoading
        ? Container(
            color: Colors.black54,
            child: Center(
              child: Builder(
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0)),
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        SizedBox(width: size.width * 0.02),
                        Row(
                          children: [
                            const Text('Loading '),
                            Visibility(
                              visible: titik1,
                              child: const Text('. '),
                            ),
                            Visibility(
                              visible: titik2,
                              child: const Text('. '),
                            ),
                            Visibility(
                              visible: titik3,
                              child: const Text('. '),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        : const SizedBox.shrink(); // Empty widget if not loading
  }
}
