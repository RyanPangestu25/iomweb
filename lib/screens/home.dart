// ignore_for_file: must_be_immutable, prefer_typing_uninitialized_variables, no_logic_in_create_state

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/sidebar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isConnected = false;
  bool visible = true;

  Future<void> initConnection() async {
    Connectivity().checkConnectivity().then((value) {
      debugPrint('$value');
      if (value != ConnectivityResult.none) {
        setState(() {
          _isConnected = (value != ConnectivityResult.none);
        });

        if (_isConnected) {
          setState(() {
            visible = false;
          });
        } else {
          setState(() {
            visible = true;
          });
        }
      }

      Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        if (mounted) {
          setState(() {
            _isConnected = (result != ConnectivityResult.none);
          });

          if (_isConnected) {
            Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                visible = false;
              });
            });
          } else {
            setState(() {
              visible = true;
            });
          }
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initConnection();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      drawer: const Sidebar(),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        title: const Text(
          "Home Screen",
        ),
        elevation: 3,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home.png'),
            fit: BoxFit.fill,
          ),
        ),
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(
                  height: 30,
                ),
                Shimmer.fromColors(
                  baseColor: Colors.red.shade700,
                  highlightColor: Colors.grey.shade300,
                  child: Center(
                    child: Text(
                      "IOM",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).textScaleFactor * 40,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(3, 1),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: Colors.red.shade700,
                  highlightColor: Colors.grey.shade300,
                  child: Center(
                    child: Text(
                      "Charter",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).textScaleFactor * 40,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(3, 1),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: visible,
              child: Container(
                color: _isConnected ? Colors.green : Colors.red,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isConnected ? 'ONLINE' : 'OFFLINE',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: size.width * 0.01),
                    _isConnected
                        ? const SizedBox.shrink()
                        : const SizedBox(
                            height: 15,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.blue,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
