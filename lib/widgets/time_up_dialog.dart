import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeUpDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final Map<String, String> translations;

  // Instagram gradient colors
  static const Color instagramGradientStart = Color(0xFF833AB4);
  static const Color instagramGradientEnd = Color(0xFFF77737);

  const TimeUpDialog({
    super.key,
    required this.onRetry,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [instagramGradientStart, instagramGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              translations['times_up'] ?? "Time's Up!",
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: instagramGradientStart,
              ),
              child: Text(translations['retry'] ?? "Retry"),
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
            ),
          ],
        ),
      ),
    );
  }
}
