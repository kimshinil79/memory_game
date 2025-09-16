import 'package:flutter/material.dart';

class MemoryCard extends StatelessWidget {
  final int index;
  final String imageId;
  final bool isFlipped;
  final bool showRedBorder;
  final VoidCallback onTap;

  const MemoryCard({
    super.key,
    required this.index,
    required this.imageId,
    required this.isFlipped,
    required this.showRedBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4, // 그림자 효과 추가
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 모서리 둥글게
          side: showRedBorder
              ? const BorderSide(
                  color: Colors.redAccent, width: 5.0) // 테두리 두께를 5.0으로 증가
              : BorderSide.none,
        ),
        key: ValueKey(index),
        color: Colors.white,
        child: Center(
          child: isFlipped
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/pictureDB_webp/$imageId.webp',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : Image.asset(
                  'assets/icon/memoryGame.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
        ),
      ),
    );
  }
}
