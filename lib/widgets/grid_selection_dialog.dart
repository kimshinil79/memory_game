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

  // 화면 크기 기반 동적 크기 계산
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

  // 화면 크기 분류
  bool get _isSmallScreen => _screenWidth < 360 || _screenHeight < 640;
  bool get _isMediumScreen => _screenWidth < 414 || _screenHeight < 736;
  bool get _isLargeScreen => _screenWidth >= 768;

  // 동적 크기 계산
  double get _dialogWidth =>
      _isLargeScreen ? _screenWidth * 0.4 : _screenWidth * 0.85;

  double get _dialogMaxHeight => _screenHeight * 0.8;

  double get _containerPadding => _screenWidth * 0.06;
  double get _borderRadius => _screenWidth * 0.07;

  // 동적 폰트 크기
  double get _titleFontSize => _isSmallScreen
      ? _screenWidth * 0.06
      : _isMediumScreen
          ? _screenWidth * 0.065
          : _screenWidth * 0.07;

  double get _subtitleFontSize => _isSmallScreen
      ? _screenWidth * 0.035
      : _isMediumScreen
          ? _screenWidth * 0.038
          : _screenWidth * 0.04;

  double get _buttonTextFontSize => _isSmallScreen
      ? _screenWidth * 0.035
      : _isMediumScreen
          ? _screenWidth * 0.038
          : _screenWidth * 0.04;

  // 동적 간격
  double get _titleBottomSpacing => _screenHeight * 0.015;
  double get _subtitleBottomSpacing => _screenHeight * 0.04;
  double get _gridRowSpacing => _screenHeight * 0.025;
  double get _buttonTopSpacing => _screenHeight * 0.04;

  // 그리드 옵션 크기
  double get _gridOptionSize => _isSmallScreen
      ? _screenWidth * 0.25
      : _isMediumScreen
          ? _screenWidth * 0.28
          : _screenWidth * 0.25;

  double get _gridOptionSpacing => _screenWidth * 0.025;

  // 아이콘 크기
  double get _gridIconSize => _isSmallScreen
      ? _screenWidth * 0.08
      : _isMediumScreen
          ? _screenWidth * 0.085
          : _screenWidth * 0.09;

  // 그리드 옵션 내부 폰트 크기
  double get _gridValueFontSize => _isSmallScreen
      ? _screenWidth * 0.04
      : _isMediumScreen
          ? _screenWidth * 0.043
          : _screenWidth * 0.045;

  double get _multiplierFontSize => _isSmallScreen
      ? _screenWidth * 0.028
      : _isMediumScreen
          ? _screenWidth * 0.03
          : _screenWidth * 0.032;

  // Helper method for creating text styles with dynamic sizing
  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black87,
    String? fontFamily,
  }) {
    final style = GoogleFonts.poppins(
      fontSize: fontSize,
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
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      elevation: _screenWidth * 0.025,
      backgroundColor: Colors.white,
      child: Container(
        width: _dialogWidth,
        constraints: BoxConstraints(
          maxHeight: _dialogMaxHeight,
        ),
        padding: EdgeInsets.all(_containerPadding),
        child: SingleChildScrollView(
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
                      fontSize: _titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: _titleBottomSpacing),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _translations['choose_difficulty'] ??
                      'Choose difficulty level',
                  style: _getTextStyle(
                    fontSize: _subtitleFontSize,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: _subtitleBottomSpacing),
              // Grid options - first row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['4x4', '4x6'].map((String value) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: _gridOptionSpacing),
                    child: _buildGridOption(
                        context, value, widget.currentGridSize),
                  );
                }).toList(),
              ),
              SizedBox(height: _gridRowSpacing),
              // Grid options - second row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['6x6', '6x8'].map((String value) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: _gridOptionSpacing),
                    child: _buildGridOption(
                        context, value, widget.currentGridSize),
                  );
                }).toList(),
              ),
              SizedBox(height: _buttonTopSpacing),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(null),
                  borderRadius: BorderRadius.circular(_borderRadius * 0.7),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _screenWidth * 0.08,
                      vertical: _screenHeight * 0.018,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(_borderRadius * 0.7),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF833AB4).withOpacity(0.3),
                          blurRadius: _screenWidth * 0.03,
                          offset: Offset(0, _screenHeight * 0.008),
                        ),
                      ],
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _translations['cancel'] ?? 'Cancel',
                          style: _getTextStyle(
                            fontSize: _buttonTextFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  // Build grid option widget
  Widget _buildGridOption(
      BuildContext context, String value, String currentGridSize) {
    final bool isSelected = value == currentGridSize;

    // 동적 크기 계산
    final optionBorderRadius = _gridOptionSize * 0.2;
    final iconSpacing = _gridOptionSize * 0.08;
    final valueSpacing = _gridOptionSize * 0.04;
    final multiplierPadding = _gridOptionSize * 0.09;
    final multiplierBorderRadius = _gridOptionSize * 0.11;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(value);
        },
        borderRadius: BorderRadius.circular(optionBorderRadius),
        child: Container(
          width: _gridOptionSize,
          height: _gridOptionSize,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(optionBorderRadius),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Color(0xFF833AB4).withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius:
                    isSelected ? _screenWidth * 0.025 : _screenWidth * 0.013,
                offset: Offset(0, _screenHeight * 0.005),
                spreadRadius: isSelected ? 1 : 0,
              ),
            ],
            border: isSelected
                ? null
                : Border.all(
                    color: Colors.grey.shade300, width: _screenWidth * 0.004),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value.contains('6x8') || value.contains('6x6')
                    ? Icons.grid_on_rounded
                    : Icons.grid_4x4_rounded,
                size: _gridIconSize,
                color: isSelected
                    ? Colors.white
                    : Color(0xFF833AB4).withOpacity(0.7),
              ),
              SizedBox(height: iconSpacing),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: _getTextStyle(
                    fontSize: _gridValueFontSize,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
              SizedBox(height: valueSpacing),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: multiplierPadding * 0.7,
                    vertical: multiplierPadding * 0.3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : Color(0xFF833AB4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(multiplierBorderRadius),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_translations['multiplier'] ?? '×'}${_getGridSizeMultiplier(value)}',
                    style: _getTextStyle(
                      fontSize: _multiplierFontSize,
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
