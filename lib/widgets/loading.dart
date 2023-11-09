import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final bool isLoading;

  const LoadingWidget({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return isLoading
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
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02),
                        const Text('Loading . . .'),
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
