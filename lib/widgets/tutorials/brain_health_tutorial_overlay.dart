import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class BrainHealthTutorialOverlay extends StatelessWidget {
  final bool showTutorial;
  final bool doNotShowAgain;
  final Function(bool) onDoNotShowAgainChanged;
  final VoidCallback onClose;
  final double textScaleFactor;

  const BrainHealthTutorialOverlay({
    Key? key,
    required this.showTutorial,
    required this.doNotShowAgain,
    required this.onDoNotShowAgainChanged,
    required this.onClose,
    required this.textScaleFactor,
  }) : super(key: key);

  Widget _buildTutorialItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20 * textScaleFactor,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15 * textScaleFactor,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13 * textScaleFactor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showTutorial) return const SizedBox.shrink();

    final Color tutorialColor = Colors.purple.shade500;
    final translations =
        Provider.of<LanguageProvider>(context).getUITranslations();

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: doNotShowAgain,
                          onChanged: (value) =>
                              onDoNotShowAgainChanged(value ?? false),
                          activeColor: tutorialColor,
                        ),
                        Text(
                          translations['dont_show_again'] ??
                              'Don\'t show again',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14 * textScaleFactor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: onClose,
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Text(
                  translations['brain_health_dashboard'] ??
                      'Brain Health Dashboard',
                  style: GoogleFonts.notoSans(
                    fontSize: 20 * textScaleFactor,
                    fontWeight: FontWeight.bold,
                    color: tutorialColor,
                  ),
                ),
                SizedBox(height: 15),
                _buildTutorialItem(
                  Icons.psychology,
                  translations['brain_health_index_title'] ??
                      'Brain Health Index',
                  translations['brain_health_index_desc'] ??
                      'Check your brain health score improved through memory games. Higher levels increase dementia prevention effect.',
                  tutorialColor,
                ),
                SizedBox(height: 10),
                _buildTutorialItem(
                  Icons.bar_chart,
                  translations['activity_graph_title'] ?? 'Activity Graph',
                  translations['activity_graph_desc'] ??
                      'View changes in your brain health score over time through the graph.',
                  tutorialColor,
                ),
                SizedBox(height: 10),
                _buildTutorialItem(
                  Icons.emoji_events,
                  translations['ranking_system_title'] ?? 'Ranking System',
                  translations['ranking_system_desc'] ??
                      'Compare your brain health score with other users and check your ranking.',
                  tutorialColor,
                ),
                SizedBox(height: 10),
                _buildTutorialItem(
                  Icons.assessment,
                  translations['game_statistics_title'] ?? 'Game Statistics',
                  translations['game_statistics_desc'] ??
                      'Check various statistics such as games played, matches found, and best records.',
                  tutorialColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
