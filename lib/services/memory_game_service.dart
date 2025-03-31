import 'package:flutter/material.dart';

class MemoryGameService extends ChangeNotifier {
  // 현재 그리드 크기
  String _gridSize = '4x4';

  // 그리드 크기 옵션들
  final List<String> gridSizeOptions = ['4x4', '4x6', '6x6', '6x8'];

  // 리스너들 (위젯에서 이벤트를 구독할 수 있게 함)
  final List<Function(String)> _gridChangeListeners = [];

  // 그리드 크기 getter
  String get gridSize => _gridSize;

  // 그리드 크기 setter
  set gridSize(String newSize) {
    if (gridSizeOptions.contains(newSize) && _gridSize != newSize) {
      _gridSize = newSize;
      // 모든 리스너에게 변경 알림
      for (var listener in _gridChangeListeners) {
        listener(newSize);
      }
      notifyListeners();
    }
  }

  // 그리드 변경 리스너 추가
  void addGridChangeListener(Function(String) listener) {
    if (!_gridChangeListeners.contains(listener)) {
      _gridChangeListeners.add(listener);
    }
  }

  // 그리드 변경 리스너 제거
  void removeGridChangeListener(Function(String) listener) {
    _gridChangeListeners.remove(listener);
  }

  // 그리드 크기에 따른 점수 계수 계산
  int getGridSizeMultiplier(String gridSize) {
    switch (gridSize) {
      case '4x4':
        return 1; // 기본 계수
      case '4x6':
        return 3; // 4x6 그리드에 대해 3배 점수
      case '6x6':
        return 5; // 6x6 그리드에 대해 5배 점수
      case '6x8':
        return 8; // 6x8 그리드에 대해 8배 점수
      default:
        return 1;
    }
  }
}
