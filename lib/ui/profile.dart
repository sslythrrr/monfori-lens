// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  final String defaultUniqueCode;

  const Profile({super.key, required this.defaultUniqueCode});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late TextEditingController _codeController;
  late String _currentCode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _currentCode = widget.defaultUniqueCode;
    _codeController = TextEditingController(text: _currentCode);
    _loadSavedCode();
  }

  Future<void> _loadSavedCode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('user_code');
    if (savedCode != null && savedCode.isNotEmpty) {
      setState(() {
        _currentCode = savedCode;
        _codeController.text = savedCode;
      });
    }
  }

  Future<void> _saveCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_code', code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUniqueCodeSection(),
              const SizedBox(height: 24),
              _buildPreviewSection(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Text(
        'Pengaturan',
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildUniqueCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kode Unik Anda',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isEditing
              ? TextField(
                  controller: _codeController,
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Masukkan kode unik baru',
                    hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[400], fontSize: 16),
                  ),
                )
              : Text(
                  _currentCode,
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _toggleEditing,
              icon: Icon(_isEditing ? Icons.save : Icons.edit, size: 18),
              label: Text(
                _isEditing ? 'Simpan' : 'Ubah Kode',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
            if (_isEditing)
              TextButton(
                onPressed: _useDefaultCode,
                child: Text(
                  'Gunakan Kode Default',
                  style: GoogleFonts.poppins(
                      color: Colors.green[600], fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _toggleEditing() {
    setState(() {
      if (_isEditing) {
        String newCode = _codeController.text.trim();
        if (newCode.isEmpty) {
          _currentCode = widget.defaultUniqueCode;
          _codeController.text = widget.defaultUniqueCode;
        } else {
          _currentCode = newCode;
        }
        _saveCode(_currentCode);
      }
      _isEditing = !_isEditing;
    });
  }

  void _useDefaultCode() {
    setState(() {
      _codeController.text = widget.defaultUniqueCode;
      _currentCode = widget.defaultUniqueCode;
      _isEditing = false;
    });
    _saveCode(_currentCode);
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview Format Nama',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            '$_currentCode-mf000-tanggal-waktu.jpg',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
