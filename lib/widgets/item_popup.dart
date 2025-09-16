import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class ItemPopup extends StatelessWidget {
  final bool showItemPopup;
  final Color instagramGradientStart;
  final Color instagramGradientEnd;

  const ItemPopup({
    super.key,
    required this.showItemPopup,
    required this.instagramGradientStart,
    required this.instagramGradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (!showItemPopup) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [instagramGradientStart, instagramGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: instagramGradientStart.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shuffle,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                Provider.of<LanguageProvider>(context)
                        .getUITranslations()['random_shake'] ??
                    'Random Shake!!',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
