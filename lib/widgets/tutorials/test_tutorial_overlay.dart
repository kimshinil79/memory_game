import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestTutorialOverlay extends StatelessWidget {
  final bool isSmallScreen;
  final double screenWidth;
  final double screenHeight;
  final double verticalSpacing;
  final double dialogPadding;
  final double dialogWidth;
  final double dialogMaxHeight;
  final double dialogBorderRadius;
  final double tutorialIconSize;
  final double tutorialTitleSize;
  final double tutorialDescSize;
  final Color primaryColor;
  final bool doNotShowAgain;
  final ValueChanged<bool?> onDoNotShowAgainChanged;
  final VoidCallback onClose;
  final Map<String, String> translations;

  const TestTutorialOverlay({
    super.key,
    required this.isSmallScreen,
    required this.screenWidth,
    required this.screenHeight,
    required this.verticalSpacing,
    required this.dialogPadding,
    required this.dialogWidth,
    required this.dialogMaxHeight,
    required this.dialogBorderRadius,
    required this.tutorialIconSize,
    required this.tutorialTitleSize,
    required this.tutorialDescSize,
    required this.primaryColor,
    required this.doNotShowAgain,
    required this.onDoNotShowAgainChanged,
    required this.onClose,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: Colors.black54,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  top: screenHeight * 0.01,
                  left: dialogPadding,
                  right: dialogPadding,
                ),
                child: Container(
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(dialogBorderRadius),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(dialogPadding),
                    child: Column(
                      children: [
                        _buildHeader(),
                        SizedBox(height: verticalSpacing),
                        _buildTitle(),
                        SizedBox(height: verticalSpacing),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildTutorialItems(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Transform.scale(
                scale: isSmallScreen ? 0.8 : 0.9,
                child: Checkbox(
                  value: doNotShowAgain,
                  onChanged: onDoNotShowAgainChanged,
                  activeColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.008),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  translations['dont_show_again'] ?? 'Don\'t show again',
                  style: GoogleFonts.poppins(
                    fontSize: tutorialDescSize,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: onClose,
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.03),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.school,
            color: primaryColor,
            size: tutorialIconSize,
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: Text(
            translations['how_to_play'] ?? 'How to Play',
            style: GoogleFonts.poppins(
              fontSize: tutorialTitleSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialItems() {
    return Column(
      children: [
        _buildTutorialItem(
          icon: Icons.quiz,
          title: translations['visual_memory_test'] ?? 'Visual Memory Test',
          description: translations['visual_memory_test_desc'] ??
              'Test your memory with 10 questions. Select the image that matches the correct word.',
        ),
        _buildTutorialItem(
          icon: Icons.volume_up,
          title: translations['audio_assistance'] ?? 'Audio Assistance',
          description: translations['audio_assistance_desc'] ??
              'Tap the sound icon to hear the correct word. The audio plays in your selected language.',
        ),
        _buildTutorialItem(
          icon: Icons.format_list_numbered,
          title: translations['question_navigation'] ?? 'Question Navigation',
          description: translations['question_navigation_desc'] ??
              'Use the number indicators at the top to navigate between questions or use the arrow buttons.',
        ),
        _buildTutorialItem(
          icon: Icons.check_circle_outline,
          title: translations['select_and_submit'] ?? 'Select and Submit',
          description: translations['select_and_submit_desc'] ??
              'Select an image for each question. Once all questions are answered, the Submit button appears.',
        ),
        _buildTutorialItem(
          icon: Icons.auto_graph,
          title: translations['results_and_progress'] ?? 'Results and Progress',
          description: translations['results_and_progress_desc'] ??
              'After submitting, view your score and restart with a new test if desired.',
        ),
      ],
    );
  }

  Widget _buildTutorialItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: verticalSpacing * 0.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: tutorialIconSize * 0.7,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: tutorialTitleSize * 0.75,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: tutorialDescSize,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
