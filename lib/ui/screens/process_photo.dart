import 'package:flutter/material.dart';

class ProcessScreen extends StatelessWidget {
  final Stream<double> progressStream;

  const ProcessScreen({super.key, required this.progressStream});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<double>(
              stream: progressStream,
              builder: (context, snapshot) {
                return CircularProgressIndicator(
                  value: snapshot.data,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(height: 20),
            StreamBuilder<double>(
              stream: progressStream,
              builder: (context, snapshot) {
                final progress = snapshot.data ?? 0.0;
                return Text(
                  'Processing Photos... ${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
