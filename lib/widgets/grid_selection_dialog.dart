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

  // 실시간 화면 크기 기반 동적 크기 계산 (고정 분류 제거)

  // 안전한 크기 계산을 위한 헬퍼 메서드
  double _getProportionalSize(double basePercentage,
      {double minSize = 0, double maxSize = double.infinity}) {
    final calculatedSize = _screenWidth * basePercentage;
    return calculatedSize.clamp(minSize, maxSize);
  }

  double _getProportionalHeight(double basePercentage,
      {double minSize = 0, double maxSize = double.infinity}) {
    final calculatedSize = _screenHeight * basePercentage;
    return calculatedSize.clamp(minSize, maxSize);
  }

  // 다이얼로그 크기 - 화면 비율에 따라 동적 조정
  double get _dialogWidth {
    // 화면 너비가 클수록 다이얼로그 비율을 줄여서 적절한 크기 유지
    if (_screenWidth >= 768) return _screenWidth * 0.4; // 태블릿/폴더블 펼침
    if (_screenWidth >= 414) return _screenWidth * 0.7; // 중간 크기
    return _screenWidth * 0.85; // 작은 화면
  }

  double get _dialogMaxHeight => _screenHeight * 0.8;

  // 패딩 및 테두리 - 화면 크기에 비례 (최소/최대 제한)
  double get _containerPadding =>
      _getProportionalSize(0.05, minSize: 16, maxSize: 32);
  double get _borderRadius =>
      _getProportionalSize(0.06, minSize: 12, maxSize: 24);

  // 폰트 크기 - 화면 크기에 비례하여 연속적으로 조정 (최소/최대 제한)
  double get _titleFontSize =>
      _getProportionalSize(0.055, minSize: 18, maxSize: 32);
  double get _subtitleFontSize =>
      _getProportionalSize(0.035, minSize: 12, maxSize: 20);
  double get _buttonTextFontSize =>
      _getProportionalSize(0.035, minSize: 12, maxSize: 20);

  // 간격 - 화면 높이에 비례 (최소/최대 제한)
  double get _titleBottomSpacing =>
      _getProportionalHeight(0.015, minSize: 8, maxSize: 20);
  double get _subtitleBottomSpacing =>
      _getProportionalHeight(0.04, minSize: 16, maxSize: 40);
  double get _gridRowSpacing =>
      _getProportionalHeight(0.025, minSize: 12, maxSize: 30);
  double get _buttonTopSpacing =>
      _getProportionalHeight(0.04, minSize: 16, maxSize: 40);

  // 그리드 옵션 크기 - 화면 너비에 비례하여 연속적으로 조정 (최소/최대 제한)
  double get _gridOptionSize =>
      _getProportionalSize(0.26, minSize: 80, maxSize: 150);

  double get _gridOptionSpacing =>
      _getProportionalSize(0.025, minSize: 8, maxSize: 20);

  // 아이콘 크기 - 화면 너비에 비례하여 연속적으로 조정 (최소/최대 제한)
  double get _gridIconSize =>
      _getProportionalSize(0.085, minSize: 24, maxSize: 48);

  // 그리드 옵션 내부 폰트 크기 - 화면 너비에 비례하여 연속적으로 조정 (최소/최대 제한)
  double get _gridValueFontSize =>
      _getProportionalSize(0.042, minSize: 14, maxSize: 24);
  double get _multiplierFontSize =>
      _getProportionalSize(0.03, minSize: 10, maxSize: 18);

  // 실제 사용 가능한 공간을 기반으로 한 동적 크기 계산 메서드
  double _calculateDynamicWidth(
      double availableWidth, Orientation orientation) {
    // 폴더블 화면에서 실제 사용 가능한 공간을 고려한 너비 계산
    if (orientation == Orientation.landscape) {
      // 가로 모드에서는 더 넓게 사용
      if (availableWidth >= 1200) return availableWidth * 0.35; // 대형 폴더블 펼침
      if (availableWidth >= 800) return availableWidth * 0.45; // 중형 폴더블 펼침
      if (availableWidth >= 600) return availableWidth * 0.6; // 작은 폴더블 펼침
      return availableWidth * 0.75; // 일반 가로 모드
    } else {
      // 세로 모드에서는 적당한 비율 사용
      if (availableWidth >= 800) return availableWidth * 0.4; // 폴더블 펼침
      if (availableWidth >= 600) return availableWidth * 0.5; // 중간 크기
      if (availableWidth >= 400) return availableWidth * 0.7; // 일반 스마트폰
      return availableWidth * 0.85; // 작은 스마트폰
    }
  }

  double _calculateDynamicHeight(
      double availableHeight, Orientation orientation) {
    // 폴더블 화면에서 실제 사용 가능한 높이를 고려
    // 위아래 여백을 더 주어 여유로운 레이아웃 구성
    if (orientation == Orientation.landscape) {
      // 가로 모드에서는 높이를 더 적게 사용
      if (availableHeight >= 800)
        return availableHeight * 0.65; // 대형 폴더블 (60% → 65%)
      if (availableHeight >= 600)
        return availableHeight * 0.7; // 중형 폴더블 (65% → 70%)
      return availableHeight * 0.75; // 일반 가로 모드 (70% → 75%)
    } else {
      // 세로 모드에서는 높이를 더 많이 사용
      if (availableHeight >= 1000)
        return availableHeight * 0.75; // 대형 폴더블 (70% → 75%)
      if (availableHeight >= 800)
        return availableHeight * 0.8; // 중형 폴더블 (75% → 80%)
      return availableHeight * 0.85; // 일반 세로 모드 (80% → 85%)
    }
  }

  // 팝업창의 실제 크기를 기반으로 한 동적 UI 요소 크기 계산 메서드들
  double _getDynamicContainerPadding(double dialogWidth) {
    return (dialogWidth * 0.06).clamp(18.0, 36.0); // 0.05 → 0.06, 더 여유로운 패딩
  }

  double _getDynamicBorderRadius(double dialogWidth) {
    return (dialogWidth * 0.06).clamp(12.0, 24.0);
  }

  double _getDynamicTitleFontSize(double dialogWidth) {
    return (dialogWidth * 0.065)
        .clamp(22.0, 38.0); // 0.055 → 0.065, 18-32 → 22-38
  }

  double _getDynamicSubtitleFontSize(double dialogWidth) {
    return (dialogWidth * 0.042)
        .clamp(14.0, 24.0); // 0.035 → 0.042, 12-20 → 14-24
  }

  double _getDynamicButtonTextFontSize(double dialogWidth) {
    return (dialogWidth * 0.042)
        .clamp(14.0, 24.0); // 0.035 → 0.042, 12-20 → 14-24
  }

  double _getDynamicTitleBottomSpacing(double dialogHeight) {
    return (dialogHeight * 0.02).clamp(10.0, 25.0); // 0.015 → 0.02, 더 여유로운 간격
  }

  double _getDynamicSubtitleBottomSpacing(double dialogHeight) {
    return (dialogHeight * 0.045).clamp(18.0, 45.0); // 0.04 → 0.045, 더 여유로운 간격
  }

  double _getDynamicGridRowSpacing(double dialogHeight) {
    return (dialogHeight * 0.03).clamp(15.0, 35.0); // 0.025 → 0.03, 더 여유로운 간격
  }

  double _getDynamicButtonTopSpacing(double dialogHeight) {
    return (dialogHeight * 0.045).clamp(18.0, 45.0); // 0.04 → 0.045, 더 여유로운 간격
  }

  double _getDynamicGridOptionSize(double dialogWidth) {
    return (dialogWidth * 0.3)
        .clamp(90.0, 170.0); // 0.26 → 0.3, 80-150 → 90-170
  }

  double _getDynamicGridOptionSpacing(double dialogWidth) {
    return (dialogWidth * 0.03).clamp(10.0, 24.0); // 0.025 → 0.03, 8-20 → 10-24
  }

  double _getDynamicGridIconSize(double dialogWidth) {
    return (dialogWidth * 0.1).clamp(28.0, 56.0); // 0.085 → 0.1, 24-48 → 28-56
  }

  double _getDynamicGridValueFontSize(double dialogWidth) {
    return (dialogWidth * 0.05)
        .clamp(16.0, 28.0); // 0.042 → 0.05, 14-24 → 16-28
  }

  double _getDynamicMultiplierFontSize(double dialogWidth) {
    return (dialogWidth * 0.035)
        .clamp(12.0, 22.0); // 0.03 → 0.035, 10-18 → 12-22
  }

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
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // 실제 사용 가능한 공간 측정
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;

            // 디버깅: 실제 측정된 크기 출력
            print('폴더블 팝업창 실제 공간 측정:');
            print('  사용 가능한 너비: $availableWidth');
            print('  사용 가능한 높이: $availableHeight');
            print('  화면 방향: $orientation');
            print('  MediaQuery 너비: ${MediaQuery.of(context).size.width}');
            print('  MediaQuery 높이: ${MediaQuery.of(context).size.height}');

            // 실제 사용 가능한 공간을 기반으로 동적 크기 계산
            final dynamicDialogWidth =
                _calculateDynamicWidth(availableWidth, orientation);
            final dynamicDialogHeight =
                _calculateDynamicHeight(availableHeight, orientation);

            // 팝업창의 실제 크기를 기반으로 모든 UI 요소의 크기를 동적 계산
            final dynamicContainerPadding =
                _getDynamicContainerPadding(dynamicDialogWidth);
            final dynamicBorderRadius =
                _getDynamicBorderRadius(dynamicDialogWidth);
            final dynamicTitleFontSize =
                _getDynamicTitleFontSize(dynamicDialogWidth);
            final dynamicSubtitleFontSize =
                _getDynamicSubtitleFontSize(dynamicDialogWidth);
            final dynamicButtonTextFontSize =
                _getDynamicButtonTextFontSize(dynamicDialogWidth);
            final dynamicTitleBottomSpacing =
                _getDynamicTitleBottomSpacing(dynamicDialogHeight);
            final dynamicSubtitleBottomSpacing =
                _getDynamicSubtitleBottomSpacing(dynamicDialogHeight);
            final dynamicGridRowSpacing =
                _getDynamicGridRowSpacing(dynamicDialogHeight);
            final dynamicButtonTopSpacing =
                _getDynamicButtonTopSpacing(dynamicDialogHeight);
            final dynamicGridOptionSize =
                _getDynamicGridOptionSize(dynamicDialogWidth);
            final dynamicGridOptionSpacing =
                _getDynamicGridOptionSpacing(dynamicDialogWidth);
            final dynamicGridIconSize =
                _getDynamicGridIconSize(dynamicDialogWidth);
            final dynamicGridValueFontSize =
                _getDynamicGridValueFontSize(dynamicDialogWidth);
            final dynamicMultiplierFontSize =
                _getDynamicMultiplierFontSize(dynamicDialogWidth);

            // 디버깅: 동적 계산된 크기 출력
            print('팝업창 동적 크기 계산:');
            print('  다이얼로그 너비: $dynamicDialogWidth');
            print('  다이얼로그 높이: $dynamicDialogHeight');
            print('  제목 폰트 크기: $dynamicTitleFontSize');
            print('  그리드 옵션 크기: $dynamicGridOptionSize');

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(dynamicBorderRadius),
              ),
              elevation: dynamicDialogWidth * 0.025,
              backgroundColor: Colors.white,
              child: Container(
                width: dynamicDialogWidth,
                constraints: BoxConstraints(
                  maxHeight: dynamicDialogHeight,
                ),
                padding: EdgeInsets.all(dynamicContainerPadding),
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
                            _translations['select_grid_size'] ??
                                'Select Grid Size',
                            style: _getTextStyle(
                              fontSize: dynamicTitleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(height: dynamicTitleBottomSpacing),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _translations['choose_difficulty'] ??
                              'Choose difficulty level',
                          style: _getTextStyle(
                            fontSize: dynamicSubtitleFontSize,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: dynamicSubtitleBottomSpacing),
                      // Grid options - first row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['4x4', '4x6'].map((String value) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: dynamicGridOptionSpacing),
                            child: _buildGridOption(
                                context,
                                value,
                                widget.currentGridSize,
                                dynamicGridOptionSize,
                                dynamicGridIconSize,
                                dynamicGridValueFontSize,
                                dynamicMultiplierFontSize),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: dynamicGridRowSpacing),
                      // Grid options - second row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['6x6', '6x8'].map((String value) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: dynamicGridOptionSpacing),
                            child: _buildGridOption(
                                context,
                                value,
                                widget.currentGridSize,
                                dynamicGridOptionSize,
                                dynamicGridIconSize,
                                dynamicGridValueFontSize,
                                dynamicMultiplierFontSize),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: dynamicButtonTopSpacing),
                      // Cancel button
                      SizedBox(
                        width: double.infinity,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(null),
                          borderRadius:
                              BorderRadius.circular(_borderRadius * 0.7),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: dynamicDialogWidth * 0.08,
                              vertical: dynamicDialogHeight * 0.018,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(_borderRadius * 0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF833AB4).withOpacity(0.3),
                                  blurRadius: dynamicDialogWidth * 0.03,
                                  offset:
                                      Offset(0, dynamicDialogHeight * 0.008),
                                ),
                              ],
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _translations['cancel'] ?? 'Cancel',
                                  style: _getTextStyle(
                                    fontSize: dynamicButtonTextFontSize,
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
          },
        );
      },
    );
  }

  // Build grid option widget
  Widget _buildGridOption(
      BuildContext context,
      String value,
      String currentGridSize,
      double gridOptionSize,
      double gridIconSize,
      double gridValueFontSize,
      double multiplierFontSize) {
    final bool isSelected = value == currentGridSize;

    // 동적 크기 계산
    final optionBorderRadius = gridOptionSize * 0.2;
    final iconSpacing = gridOptionSize * 0.08;
    final valueSpacing = gridOptionSize * 0.04;
    final multiplierPadding = gridOptionSize * 0.09;
    final multiplierBorderRadius = gridOptionSize * 0.11;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(value);
        },
        borderRadius: BorderRadius.circular(optionBorderRadius),
        child: Container(
          width: gridOptionSize,
          height: gridOptionSize,
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
                size: gridIconSize,
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
                    fontSize: gridValueFontSize,
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
                      fontSize: multiplierFontSize,
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
