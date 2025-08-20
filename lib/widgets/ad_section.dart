import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdSection extends StatelessWidget {
  final bool isBannerAdReady;
  final BannerAd? bannerAd;
  final bool isAdLoading;
  final LoadAdError? adLoadError;
  final Color instagramGradientStart;
  final VoidCallback onRetry;

  const AdSection({
    Key? key,
    required this.isBannerAdReady,
    this.bannerAd,
    required this.isAdLoading,
    this.adLoadError,
    required this.instagramGradientStart,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 광고가 성공적으로 로드된 경우
    if (isBannerAdReady && bannerAd != null) {
      // 광고 높이를 제한하여 메모리 게임 공간 확보
      final adHeight = bannerAd!.size.height.toDouble();
      final maxAdHeight = 80.0; // 최대 광고 높이 제한
      final finalAdHeight = adHeight > maxAdHeight ? maxAdHeight : adHeight;

      return Container(
        height: finalAdHeight,
        child: AdWidget(ad: bannerAd!),
      );
    }

    // 광고 로딩 중인 경우
    if (isAdLoading) {
      return Container(
        height: 30, // 40에서 30으로 줄임
        margin: EdgeInsets.symmetric(
            horizontal: 16, vertical: 2), // vertical도 4에서 2로 줄임
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 12, // 14에서 12로 줄임
                height: 12, // 14에서 12로 줄임
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    instagramGradientStart,
                  ),
                ),
              ),
              SizedBox(width: 6), // 8에서 6으로 줄임
              Text(
                '광고 로딩 중...',
                style: GoogleFonts.notoSans(
                  fontSize: 10, // 11에서 10으로 줄임
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 광고 로드에 실패한 경우
    if (adLoadError != null) {
      return Container(
        height: 28, // 높이 제한 추가
        margin: EdgeInsets.symmetric(
            horizontal: 16, vertical: 2), // vertical을 4에서 2로 줄임
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Padding(
          padding: EdgeInsets.all(6), // 8에서 6으로 줄임
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 12, // 14에서 12로 줄임
              ),
              SizedBox(width: 4), // 6에서 4로 줄임
              Expanded(
                child: Text(
                  '광고 로드 실패: ${_getAdErrorCause(adLoadError!.code)}',
                  style: GoogleFonts.notoSans(
                    fontSize: 9, // 10에서 9로 줄임
                    color: Colors.red.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 3), // 4에서 3으로 줄임
              TextButton(
                onPressed: onRetry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 11, // 12에서 11로 줄임
                      color: instagramGradientStart,
                    ),
                    SizedBox(width: 1), // 2에서 1로 줄임
                    Text(
                      '재시도',
                      style: GoogleFonts.notoSans(
                        fontSize: 8, // 9에서 8로 줄임
                        color: instagramGradientStart,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: TextButton.styleFrom(
                  minimumSize: Size(0, 0),
                  padding: EdgeInsets.symmetric(
                      horizontal: 3, vertical: 1), // 4,2에서 3,1로 줄임
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 초기 상태 (아직 광고 로드 시도하지 않음)
    return Container(
      height: 30, // 40에서 30으로 줄임
      margin: EdgeInsets.symmetric(
          horizontal: 16, vertical: 2), // vertical을 4에서 2로 줄임
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          '광고 준비 중...',
          style: GoogleFonts.notoSans(
            fontSize: 10, // 11에서 10으로 줄임
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  String _getAdErrorCause(int errorCode) {
    switch (errorCode) {
      case 0:
        return "내부 오류 - AdMob SDK 문제";
      case 1:
        return "잘못된 요청 - 광고 단위 ID 또는 요청 설정 문제";
      case 2:
        return "네트워크 오류 - 인터넷 연결 확인 필요";
      case 3:
        return "광고 없음 - 현재 표시할 광고가 없음 (에뮬레이터에서 흔함)";
      case 8:
        return "앱 ID 무료 등록 - AdMob 계정 설정 필요";
      default:
        return "알 수 없는 오류 ($errorCode)";
    }
  }
}
