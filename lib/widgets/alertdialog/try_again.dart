// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously, must_be_immutable, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';

class TryAgain extends StatefulWidget {
  final Function(bool) submit;

  const TryAgain({
    Key? key,
    required this.submit,
  }) : super(key: key);

  @override
  State<TryAgain> createState() => _TryAgainState();
}

class _TryAgainState extends State<TryAgain> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ListView.builder(
        itemCount: 1,
        itemBuilder: (context, index) {
          return SizedBox(
            height: size.height,
            child: AlertDialog(
              icon: Icon(
                Icons.error,
                size: MediaQuery.of(context).size.height * 0.13,
              ),
              iconColor: Colors.red,
              title: Center(
                child: Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).textScaleFactor * 20,
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    widget.submit(true);
                  },
                  child: const Text("Try Again"),
                ),
                TextButton(
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      "There's A Problem, Try Again?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).textScaleFactor * 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
