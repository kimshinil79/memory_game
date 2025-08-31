import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class MemoryGameTutorialOverlay extends StatelessWidget {
  final bool showTutorial;
  final bool doNotShowAgain;
  final Function(bool) onDoNotShowAgainChanged;
  final VoidCallback onClose;

  const MemoryGameTutorialOverlay({
    Key? key,
    required this.showTutorial,
    required this.doNotShowAgain,
    required this.onDoNotShowAgainChanged,
    required this.onClose,
  }) : super(key: key);

  Widget _buildTutorialItem(
    IconData icon,
    String title,
    String description,
    Color color,
    double iconSize,
    double titleFontSize,
    double descFontSize,
    double padding,
  ) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: descFontSize,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showTutorial) return const SizedBox.shrink();

    // 화면 크기 가져오기
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // 반응형 크기 계산
    final isSmallScreen = screenWidth < 360 || screenHeight < 640;
    final isMediumScreen = screenWidth < 414 || screenHeight < 736;

    // 동적 크기 설정
    final containerPadding = screenWidth * 0.05;
    final borderRadius = screenWidth * 0.05;

    // 동적 글씨 크기 설정
    final titleFontSize = isSmallScreen
        ? screenWidth * 0.048
        : isMediumScreen
            ? screenWidth * 0.042
            : screenWidth * 0.038;
    final itemTitleFontSize = isSmallScreen
        ? screenWidth * 0.038
        : isMediumScreen
            ? screenWidth * 0.034
            : screenWidth * 0.03;
    final itemDescFontSize = isSmallScreen
        ? screenWidth * 0.034
        : isMediumScreen
            ? screenWidth * 0.03
            : screenWidth * 0.026;
    final checkboxTextSize = isSmallScreen
        ? screenWidth * 0.036
        : isMediumScreen
            ? screenWidth * 0.032
            : screenWidth * 0.028;

    // 동적 간격 설정
    final titleBottomSpace = screenHeight * 0.02;
    final itemSpacing = screenHeight * 0.015;

    // 동적 아이콘 크기
    final iconSize = isSmallScreen
        ? screenWidth * 0.055
        : isMediumScreen
            ? screenWidth * 0.052
            : screenWidth * 0.045;

    // 언어 번역 가져오기
    final translations = Provider.of<LanguageProvider>(context, listen: false)
        .getUITranslations();

    final Color tutorialColor = Colors.blue.shade500;

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(
            top: screenHeight * 0.1,
            left: containerPadding,
            right: containerPadding,
          ),
          child: Container(
            width: screenWidth * 0.8,
            height: screenHeight * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: screenWidth * 0.025,
                  offset: Offset(0, screenHeight * 0.008),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(containerPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Transform.scale(
                            scale: isSmallScreen ? 0.8 : 0.9,
                            child: Checkbox(
                              value: doNotShowAgain,
                              onChanged: (value) =>
                                  onDoNotShowAgainChanged(value ?? false),
                              activeColor: tutorialColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(screenWidth * 0.008),
                              ),
                            ),
                          ),
                          Text(
                            translations['dont_show_again'] ??
                                'Don\'t show again',
                            style: GoogleFonts.poppins(
                              fontSize: checkboxTextSize,
                              color: Colors.black87,
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
                  SizedBox(height: titleBottomSpace),
                  Text(
                    translations['memory_game_guide'] ?? 'Memory Game Guide',
                    style: GoogleFonts.notoSans(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: tutorialColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: titleBottomSpace),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildTutorialItem(
                            Icons.touch_app,
                            translations['card_selection_title'] ??
                                'Card Selection',
                            translations['card_selection_desc'] ??
                                'Tap cards to flip and find matching pairs.',
                            tutorialColor,
                            iconSize,
                            itemTitleFontSize,
                            itemDescFontSize,
                            containerPadding * 0.6,
                          ),
                          SizedBox(height: itemSpacing),
                          _buildTutorialItem(
                            Icons.timer,
                            translations['time_limit_title'] ?? 'Time Limit',
                            translations['time_limit_desc'] ??
                                'Match all pairs within time limit. Faster matching earns higher score.',
                            tutorialColor,
                            iconSize,
                            itemTitleFontSize,
                            itemDescFontSize,
                            containerPadding * 0.6,
                          ),
                          SizedBox(height: itemSpacing),
                          _buildTutorialItem(
                            Icons.add_alarm,
                            translations['add_time_title'] ?? 'Add Time',
                            translations['add_time_desc'] ??
                                'Tap "+30s" to add time (costs Brain Health points).',
                            tutorialColor,
                            iconSize,
                            itemTitleFontSize,
                            itemDescFontSize,
                            containerPadding * 0.6,
                          ),
                          SizedBox(height: itemSpacing),
                          _buildTutorialItem(
                            Icons.people,
                            translations['multiplayer_title'] ?? 'Multiplayer',
                            translations['multiplayer_desc'] ??
                                'Change player count (1-4) to play with friends.',
                            tutorialColor,
                            iconSize,
                            itemTitleFontSize,
                            itemDescFontSize,
                            containerPadding * 0.6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
