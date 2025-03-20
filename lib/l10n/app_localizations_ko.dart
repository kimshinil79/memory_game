// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '메모리 게임';

  @override
  String get gameTab => '게임';

  @override
  String get brainHealthTab => '두뇌 건강';

  @override
  String get testTab => '테스트';

  @override
  String get signIn => '로그인';

  @override
  String get signOut => '로그아웃';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get nickname => '닉네임';

  @override
  String get age => '나이';

  @override
  String get gender => '성별';

  @override
  String get country => '국가';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get selectGender => '성별 선택';

  @override
  String get selectCountry => '국가 선택';

  @override
  String get update => '업데이트';

  @override
  String get cancel => '취소';

  @override
  String get loginRequired => '로그인 필요';

  @override
  String get pleaseSignIn => '메모리 게임을 플레이하려면 로그인하세요';

  @override
  String get selectNumberOfPlayers => '플레이어 수 선택';

  @override
  String get selectGridSize => '그리드 크기 선택';
}
