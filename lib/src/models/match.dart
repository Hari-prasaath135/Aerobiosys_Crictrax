// match.dart
// In-memory cache backed by Firestore (fire-and-forget writes).
// Goal: never block on Firestore; always work offline.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Match {
  final String matchId;

  /// Auto-generated surrogate key — used by playerselection_page as `match.id`.
  String get id => matchId;

  final String teamId1;
  final String teamId2;
  final int overs;
  final bool isNoballAllowed;
  final bool isWideAllowed;
  final DateTime? matchDate;
  bool isCompleted;

  // ── Toss fields (required by InitialTeamPage / playerselection_page) ──────
  final String tossWonBy;      // teamId of the team that won the toss
  final int batBowlFlag;       // 1 = toss winner bats first, 2 = toss winner bowls first

  /// True when the toss-winner chose to bat first.
  bool get isBattingFirst => batBowlFlag == 1;

  // ─── Local In-Memory Cache ────────────────────────────────────────────────
  static final Map<String, Match> _cache = {};

  Match({
    required this.matchId,
    required this.teamId1,
    required this.teamId2,
    required this.overs,
    required this.isNoballAllowed,
    required this.isWideAllowed,
    required this.tossWonBy,
    this.batBowlFlag = 1,
    this.matchDate,
    this.isCompleted = false,
  });

  // ─── Derived helpers used by playerselection_page ─────────────────────────

  /// Returns the teamId of the team currently batting.
  String getBattingTeamId() {
    // isBattingFirst → toss winner bats
    if (isBattingFirst) return tossWonBy;
    // toss winner bowls → the other team bats
    return tossWonBy == teamId1 ? teamId2 : teamId1;
  }

  /// Returns the teamId of the team currently bowling.
  String getBowlingTeamId() {
    final batting = getBattingTeamId();
    return batting == teamId1 ? teamId2 : teamId1;
  }

  // ─── Serialisation ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'teamId1': teamId1,
        'teamId2': teamId2,
        'overs': overs,
        'isNoballAllowed': isNoballAllowed,
        'isWideAllowed': isWideAllowed,
        'isCompleted': isCompleted,
        'tossWonBy': tossWonBy,
        'batBowlFlag': batBowlFlag,
        'matchDate': matchDate?.toIso8601String(),
      };

  factory Match.fromMap(Map<String, dynamic> map) {
    final m = Match(
      matchId: map['matchId'] as String? ?? const Uuid().v4(),
      teamId1: map['teamId1'] as String? ?? '',
      teamId2: map['teamId2'] as String? ?? '',
      overs: (map['overs'] as num?)?.toInt() ?? 20,
      isNoballAllowed: map['isNoballAllowed'] as bool? ?? true,
      isWideAllowed: map['isWideAllowed'] as bool? ?? true,
      isCompleted: map['isCompleted'] as bool? ?? false,
      tossWonBy: map['tossWonBy'] as String? ?? '',
      batBowlFlag: (map['batBowlFlag'] as num?)?.toInt() ?? 1,
      matchDate: map['matchDate'] != null
          ? DateTime.tryParse(map['matchDate'] as String)
          : null,
    );
    _cache[m.matchId] = m;
    return m;
  }

  // ─── Persist (fire-and-forget — never blocks scoring) ────────────────────
  void save() {
    _cache[matchId] = this;
    FirebaseFirestore.instance
        .collection('matches_global')
        .doc(matchId)
        .set(toMap())
        .catchError((_) {});
  }

  // ─── SYNCHRONOUS FACTORY ──────────────────────────────────────────────────
  static Match create({
    required String teamId1,
    required String teamId2,
    required int overs,
    required String tossWonBy,
    bool isNoballAllowed = true,
    bool isWideAllowed = true,
    int batBowlFlag = 1,
    DateTime? matchDate,
  }) {
    final m = Match(
      matchId: const Uuid().v4(),
      teamId1: teamId1,
      teamId2: teamId2,
      overs: overs,
      isNoballAllowed: isNoballAllowed,
      isWideAllowed: isWideAllowed,
      tossWonBy: tossWonBy,
      batBowlFlag: batBowlFlag,
      matchDate: matchDate ?? DateTime.now(),
    );
    _cache[m.matchId] = m;
    m.save(); // fire-and-forget
    return m;
  }

  // ─── SYNCHRONOUS LOOKUPS ──────────────────────────────────────────────────
  static Match? getByMatchId(String matchId) => _cache[matchId];
  static List<Match> getAll() => _cache.values.toList();

  // ─── Cache management ─────────────────────────────────────────────────────
  static void addToCache(Match m) => _cache[m.matchId] = m;
  static void clearCache() => _cache.clear();

  // ─── Async Firestore load (called at app start / resume) ─────────────────
  static Future<void> loadFromFirestore(String matchId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('matches_global')
          .doc(matchId)
          .get();
      if (doc.exists && doc.data() != null) {
        Match.fromMap(doc.data()!);
      }
    } catch (_) {}
  }
}