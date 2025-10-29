// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:monforilens/ui/profile.dart';
import 'package:monforilens/ui/select_photo.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late String _deviceUniqueCode;

  @override
  void initState() {
    super.initState();
    _initDeviceUniqueCode();
  }

  Future<void> _initDeviceUniqueCode() async {
    _deviceUniqueCode = await _getDeviceUniqueCode();
    setState(() {});
  }

  Future<String> _getDeviceUniqueCode() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    var bytes = utf8.encode(deviceId);
    var digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  void _openSelectPhoto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectPhoto(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'MonforiLens',
            style: GoogleFonts.lobster(
              color: Colors.green,
              fontWeight: FontWeight.w400,
              fontSize: 28,
              shadows: [
                const Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.green),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      Profile(defaultUniqueCode: _deviceUniqueCode)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedIcon(),
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildSubtitle(),
              const SizedBox(height: 40),
              _buildSelectPhotoButton(),
              const SizedBox(height: 60),
              _buildStepsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 80, 80, 80),
            Color.fromARGB(255, 150, 150, 150)
          ],
        ).createShader(bounds);
      },
      child: const Icon(
        Icons.add_a_photo,
        size: 100,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Urutkan dan Bagikan Foto',
      style: GoogleFonts.poppins(
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Pilih, atur, dan bagikan foto-fotomu dengan berurutan',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        color: Colors.black54,
        fontSize: 16,
      ),
    );
  }

  Widget _buildSelectPhotoButton() {
    return ElevatedButton(
      onPressed: _openSelectPhoto,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          Text(
            'Mulai ',
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    return Card(
      color: Colors.white70.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Cara Menggunakan Aplikasi',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildStepItem(Icons.photo_library, 'Pilih foto dari galeri'),
            _buildStepItem(
                Icons.compare_arrows, 'Pratinjau hasil dan sesuaikan urutan'),
            _buildStepItem(Icons.save_alt, 'Bagikan folder'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(IconData icon, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
