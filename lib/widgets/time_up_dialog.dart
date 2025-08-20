import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class TimeUpDialog extends StatelessWidget {
  final VoidCallback onRetry;

  // Instagram gradient colors
  static const Color instagramGradientStart = Color(0xFF833AB4);
  static const Color instagramGradientEnd = Color(0xFFF77737);

  const TimeUpDialog({
    Key? key,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 번역 텍스트를 위한 언어 제공자
    final translations = Provider.of<LanguageProvider>(context, listen: false)
        .getUITranslations();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
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
            SizedBox(height: 24),
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
