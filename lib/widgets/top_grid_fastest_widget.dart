import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'package:flag/flag.dart';

class TopGridFastestWidget extends StatefulWidget {
  const TopGridFastestWidget({super.key});

  @override
  State<TopGridFastestWidget> createState() => _TopGridFastestWidgetState();
}

class _TopGridFastestWidgetState extends State<TopGridFastestWidget>
    with SingleTickerProviderStateMixin {
  final List<String> _gridSizes = const ['4x4', '4x6', '6x6', '6x8'];
  String _selectedGrid = '4x4';

  late Future<List<Map<String, dynamic>>> _future;
  late Stream<List<Map<String, dynamic>>> _stream;

  // K-pop Demon Hunters gradient colors
  final Color _gradientStart = const Color(0xFFFF2D95);
  final Color _gradientEnd = const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _future = _fetchFastest(_selectedGrid);
    _stream = _streamFastest(_selectedGrid);
  }

  Future<List<Map<String, dynamic>>> _fetchFastest(String gridSize) async {
    try {
      final fieldPath = 'brain_health.bestTimesByGridSize.$gridSize';
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(fieldPath, isGreaterThan: 0)
          .orderBy(fieldPath)
          .limit(5)
          .get();

      final List<Map<String, dynamic>> results = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final nickname = (data['nickname'] as String?) ?? 'Player';
        final country = (data['country'] as String?) ?? 'us';
        final bestTimes = (data['brain_health'] != null &&
                data['brain_health'] is Map &&
                (data['brain_health'] as Map)
                    .containsKey('bestTimesByGridSize'))
            ? ((data['brain_health'] as Map)['bestTimesByGridSize']
                as Map<String, dynamic>)
            : <String, dynamic>{};
        final timeSec = (bestTimes[gridSize] is int)
            ? bestTimes[gridSize] as int
            : (bestTimes[gridSize] is double)
                ? (bestTimes[gridSize] as double).round()
                : 0;

        if (timeSec > 0) {
          results.add({
            'nickname': nickname,
            'country': country,
            'time': timeSec,
          });
        }
      }

      return results;
    } catch (e) {
      // Fallback: if index is missing, do a broader fetch and sort client-side
      try {
        final snapshot =
            await FirebaseFirestore.instance.collection('users').get();
        final List<Map<String, dynamic>> all = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data['brain_health'] is! Map) continue;
          final bh = data['brain_health'] as Map<String, dynamic>;
          if (bh['bestTimesByGridSize'] is! Map) continue;
          final bt = bh['bestTimesByGridSize'] as Map<String, dynamic>;
          if (!bt.containsKey(gridSize)) continue;
          final raw = bt[gridSize];
          final timeSec = raw is int ? raw : (raw is double ? raw.round() : 0);
          if (timeSec <= 0) continue;
          all.add({
            'nickname': (data['nickname'] as String?) ?? 'Player',
            'country': (data['country'] as String?) ?? 'us',
            'time': timeSec,
          });
        }
        all.sort((a, b) => (a['time'] as int).compareTo(b['time'] as int));
        return all.take(5).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _streamFastest(String gridSize) {
    final fieldPath = 'brain_health.bestTimesByGridSize.$gridSize';
    return FirebaseFirestore.instance
        .collection('users')
        .where(fieldPath, isGreaterThan: 0)
        .orderBy(fieldPath)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      final List<Map<String, dynamic>> results = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final nickname = (data['nickname'] as String?) ?? 'Player';
        final country = (data['country'] as String?) ?? 'us';
        final bestTimes = (data['brain_health'] != null &&
                data['brain_health'] is Map &&
                (data['brain_health'] as Map).containsKey('bestTimesByGridSize'))
            ? ((data['brain_health'] as Map)['bestTimesByGridSize']
                as Map<String, dynamic>)
            : <String, dynamic>{};
        final timeSec = (bestTimes[gridSize] is int)
            ? bestTimes[gridSize] as int
            : (bestTimes[gridSize] is double)
                ? (bestTimes[gridSize] as double).round()
                : 0;
        if (timeSec > 0) {
          results.add({
            'nickname': nickname,
            'country': country,
            'time': timeSec,
          });
        }
      }
      return results;
    });
  }

  void _onSelect(String grid) {
    setState(() {
      _selectedGrid = grid;
      _future = _fetchFastest(_selectedGrid);
      _stream = _streamFastest(_selectedGrid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final translations = Provider.of<LanguageProvider>(context, listen: false)
        .getUITranslations();

    final title =
        translations['top_fastest_by_grid'] ?? 'Top 5 Fastest by Grid';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2430),
            Color(0xFF2F3542),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFF2D95).withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF00E5FF),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2D95).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.speed, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      title,
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GridSelector(
              grids: _gridSizes,
              selected: _selectedGrid,
              onSelect: _onSelect,
              gradientStart: _gradientStart,
              gradientEnd: _gradientEnd,
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                key: ValueKey<String>(_selectedGrid),
                stream: _stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Column(
                      children: [
                        _SkeletonRow(),
                        _SkeletonRow(),
                        _SkeletonRow(),
                        _SkeletonRow(),
                        _SkeletonRow(),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        translations['failed_to_load'] ?? 'Failed to load',
                        style: GoogleFonts.notoSans(color: Colors.red),
                      ),
                    );
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252B3A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.hourglass_empty, color: Color(0xFF00E5FF)),
                          const SizedBox(width: 8),
                          Text(
                            translations['no_records_yet'] ?? 'No records yet',
                            style: GoogleFonts.notoSans(color: const Color(0xFF00E5FF)),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < list.length; i++)
                        _RankRow(
                          rank: i + 1,
                          nickname: list[i]['nickname'] as String,
                          country: list[i]['country'] as String,
                          seconds: list[i]['time'] as int,
                          gradientStart: _gradientStart,
                          gradientEnd: _gradientEnd,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 랭킹별 카드 스타일 정의
class CardStyle {
  final BoxDecoration decoration;
  final Color badgeColor;
  final BoxDecoration badgeDecoration;
  final double elevation;

  CardStyle({
    required this.decoration,
    required this.badgeColor,
    required this.badgeDecoration,
    required this.elevation,
  });
}

CardStyle _getCardStyle(int rank, Color gradientStart, Color gradientEnd) {
  switch (rank) {
    case 1: // 1등 - 네온 핑크 그라데이션
      return CardStyle(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF2D95),
              Color(0xFF00E5FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF2D95),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2D95).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        badgeColor: Colors.white,
        badgeDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        elevation: 8,
      );
    case 2: // 2등 - 네온 시안
      return CardStyle(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF00E5FF),
              Color(0xFF0099CC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF00E5FF),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        badgeColor: Colors.white,
        badgeDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        elevation: 6,
      );
    case 3: // 3등 - 네온 보라
      return CardStyle(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF9C27B0),
              Color(0xFF673AB7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF9C27B0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        badgeColor: Colors.white,
        badgeDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        elevation: 4,
      );
    case 4: // 4등 - 네온 그린
      return CardStyle(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF8BC34A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4CAF50),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        badgeColor: Colors.white,
        badgeDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        elevation: 3,
      );
    default: // 5등 - 기본 네온 스타일
      return CardStyle(
        decoration: BoxDecoration(
          color: const Color(0xFF252B3A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF00E5FF), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        badgeColor: const Color(0xFF00E5FF),
        badgeDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00E5FF),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        elevation: 2,
      );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String nickname;
  final String country;
  final int seconds;
  final Color gradientStart;
  final Color gradientEnd;

  const _RankRow({
    required this.rank,
    required this.nickname,
    required this.country,
    required this.seconds,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    // 랭킹별 카드 스타일 가져오기
    final CardStyle cardStyle = _getCardStyle(rank, gradientStart, gradientEnd);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.symmetric(
        vertical: rank <= 3 ? 12 : 10,
        horizontal: rank <= 3 ? 14 : 12,
      ),
      decoration: cardStyle.decoration,
      child: Row(
        children: [
          Container(
            height: rank <= 3 ? 36 : 32,
            width: rank <= 3 ? 36 : 32,
            alignment: Alignment.center,
            decoration: cardStyle.badgeDecoration,
            child: Text(
              rank.toString(),
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: rank <= 3 ? 16 : 14,
                color: cardStyle.badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flag.fromString(
            country.toLowerCase(),
            height: 18,
            width: 24,
            borderRadius: 2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              vertical: rank <= 3 ? 8 : 6,
              horizontal: rank <= 3 ? 12 : 10,
            ),
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFF2D95).withOpacity(0.2)
                  : rank == 2
                      ? const Color(0xFF00E5FF).withOpacity(0.2)
                      : rank == 3
                          ? const Color(0xFF9C27B0).withOpacity(0.2)
                          : rank == 4
                              ? const Color(0xFF4CAF50).withOpacity(0.2)
                              : const Color(0xFF00E5FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(rank <= 3 ? 12 : 10),
              border: Border.all(
                color: rank == 1
                    ? const Color(0xFFFF2D95)
                    : rank == 2
                        ? const Color(0xFF00E5FF)
                        : rank == 3
                            ? const Color(0xFF9C27B0)
                            : rank == 4
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF00E5FF),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: rank <= 3 ? 18 : 16,
                  color: rank == 1
                      ? const Color(0xFFFF2D95)
                      : rank == 2
                          ? const Color(0xFF00E5FF)
                          : rank == 3
                              ? const Color(0xFF9C27B0)
                              : rank == 4
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF00E5FF),
                ),
                const SizedBox(width: 6),
                Text(
                  '${seconds}s',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: rank <= 3 ? 14 : 13,
                    color: rank == 1
                        ? const Color(0xFFFF2D95)
                        : rank == 2
                            ? const Color(0xFF00E5FF)
                            : rank == 3
                                ? const Color(0xFF9C27B0)
                                : rank == 4
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFF00E5FF),
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

class _GridSelector extends StatelessWidget {
  final List<String> grids;
  final String selected;
  final void Function(String) onSelect;
  final Color gradientStart;
  final Color gradientEnd;

  const _GridSelector({
    required this.grids,
    required this.selected,
    required this.onSelect,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: grids.map((g) {
        final bool isSelected = g == selected;
        return GestureDetector(
          onTap: () => onSelect(g),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : const Color(0xFF252B3A),
              border: Border.all(
                color: isSelected ? Colors.transparent : const Color(0xFF00E5FF),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF2D95).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              g,
              style: GoogleFonts.notoSans(
                color: isSelected ? Colors.white : const Color(0xFF00E5FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252B3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E5FF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 18,
            width: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 28,
            width: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}
