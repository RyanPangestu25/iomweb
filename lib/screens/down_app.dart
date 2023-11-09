// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, non_constant_identifier_names, deprecated_member_use, use_build_context_synchronously, must_be_immutable, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:store_redirect/store_redirect.dart';

class UpdateApp extends StatefulWidget {
  const UpdateApp({Key? key}) : super(key: key);

  @override
  State<UpdateApp> createState() => UpdateAppState();
}

class UpdateAppState extends State<UpdateApp> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ListView.builder(
        itemCount: 1,
        itemBuilder: (context, index) {
          return SizedBox(
            height: size.height,
            child: AlertDialog(
              title: Center(
                child: Text(
                  'Update',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).textScaleFactor * 20,
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    StoreRedirect.redirect(
                      androidAppId: "com.lion.iomcharter",
                    );
                  },
                  child: const Text("Download"),
                ),
                TextButton(
                  child: const Text("Close"),
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('splash', (route) => false);
                  },
                ),
              ],
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'We have a new version',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).textScaleFactor * 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
