import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class GridSelectionDialog {
  static Future<String?> show(BuildContext context, String currentGridSize) {
    // 상위 컨텍스트에서 LanguageProvider 가져오기
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    return showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        // LanguageProvider를 다이얼로그에 전달
        return ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
          child: GridSelectionDialogContent(currentGridSize: currentGridSize),
        );
      },
    );
  }
}

class GridSelectionDialogContent extends StatefulWidget {
  final String currentGridSize;

  const GridSelectionDialogContent({
    Key? key,
    required this.currentGridSize,
  }) : super(key: key);

  @override
  _GridSelectionDialogContentState createState() =>
      _GridSelectionDialogContentState();
}

class _GridSelectionDialogContentState
    extends State<GridSelectionDialogContent> {
  LanguageProvider? _languageProvider;
  Map<String, String> _translations = {};
  bool _didInitProvider = false;

  // Define text scale factor for dynamic text sizing
  double get _textScaleFactor {
    final width = MediaQuery.of(context).size.width;
    // Adjust these breakpoints as needed
    if (width < 360) return 0.8;
    if (width < 400) return 0.9;
    return 1.0;
  }

  // Helper method for creating text styles with dynamic sizing
  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black87,
    String? fontFamily,
  }) {
    final style = GoogleFonts.poppins(
      fontSize: fontSize * _textScaleFactor,
      fontWeight: fontWeight,
      color: color,
    );
    return style;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Provider 초기화 (첫 번째 didChangeDependencies 호출에서만)
    if (!_didInitProvider) {
      _initializeLanguageProvider();
      _didInitProvider = true;
    }
  }

  void _initializeLanguageProvider() {
    try {
      _languageProvider = Provider.of<LanguageProvider>(context, listen: false);

      // 번역 데이터 업데이트 - nationality 기반 UI 언어 사용
      if (_languageProvider != null) {
        _updateTranslations();
      }
    } catch (e) {
      print('LanguageProvider 초기화 오류: $e');
    }
  }

  // 번역 업데이트 헬퍼 메서드
  void _updateTranslations() {
    if (_languageProvider != null && mounted) {
      setState(() {
        // nationality 기반 UI 언어로 번역 받기
        _translations = _languageProvider!.getUITranslations();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Container(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient text
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _translations['select_grid_size'] ?? 'Select Grid Size',
                  style: _getTextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _translations['choose_difficulty'] ?? 'Choose difficulty level',
                style: _getTextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: 32),
            // Grid options - first row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['4x4', '4x6'].map((String value) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child:
                      _buildGridOption(context, value, widget.currentGridSize),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Grid options - second row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['6x6', '6x8'].map((String value) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child:
                      _buildGridOption(context, value, widget.currentGridSize),
                );
              }).toList(),
            ),
            SizedBox(height: 32),
            // Cancel button
            InkWell(
              onTap: () => Navigator.of(context).pop(null),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF833AB4).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _translations['cancel'] ?? 'Cancel',
                    style: _getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build grid option widget
  Widget _buildGridOption(
      BuildContext context, String value, String currentGridSize) {
    final bool isSelected = value == currentGridSize;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(value);
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Color(0xFF833AB4).withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 10 : 5,
                offset: Offset(0, 4),
                spreadRadius: isSelected ? 1 : 0,
              ),
            ],
            border: isSelected
                ? null
                : Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value.contains('6x8') || value.contains('6x6')
                    ? Icons.grid_on_rounded
                    : Icons.grid_4x4_rounded,
                size: 36 * _textScaleFactor,
                color: isSelected
                    ? Colors.white
                    : Color(0xFF833AB4).withOpacity(0.7),
              ),
              SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: _getTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : Color(0xFF833AB4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_translations['multiplier'] ?? '×'}${_getGridSizeMultiplier(value)}',
                    style: _getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Color(0xFF833AB4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Calculate score multiplier based on grid size
  int _getGridSizeMultiplier(String gridSize) {
    switch (gridSize) {
      case '4x4':
        return 1; // Base multiplier
      case '4x6':
        return 3; // Triple points for 4x6 grid
      case '6x6':
        return 5; // 5x points for 6x6 grid
      case '6x8':
        return 8; // 8x points for 6x8 grid
      default:
        return 1;
    }
  }
}
