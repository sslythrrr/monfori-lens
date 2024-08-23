// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:monforilens/ui/screens/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay untuk menampilkan splash screen selama beberapa detik
    Future.delayed(const Duration(seconds: 3), () {
      // Pindah ke halaman utama setelah delay
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const HomePage(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Warna background splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Logo gambar
            Image.asset(
              'assets/images/splash.png',
              width: 200, // Lebar logo
              height: 200, // Tinggi logo
            ),
            const SizedBox(height: 20), // Jarak antara logo dan spinner
            // Spinner
            const SpinKitCircle(
              color: Colors.blue, // Warna spinner
              size: 70.0, // Ukuran spinner
            ),
          ],
        ),
      ),
    );
  }
}
