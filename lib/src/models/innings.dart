// innings.dart — in-memory cache backed by Firestore (fire-and-forget writes)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Innings {
  final String inningsId;
  final String matchId;
  final String battingTeamId;
  final String bowlingTeamId;
  final bool isSecondInnings;
  bool isCompleted;
  int targetRuns;
  bool hasValidTarget;

  /// Tournament this innings belongs to — needed for the nested Firestore path.
  final String tournamentId;

  // Derived convenience getter used by bluetooth_service.dart
  int get inningsNumber => isSecondInnings ? 2 : 1;

  // ─── Local In-Memory Cache ────────────────────────────────────────────────
  static final Map<String, Innings> _cache = {};

  Innings({
    required this.inningsId,
    required this.matchId,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.isSecondInnings,
    required this.isCompleted,
    required this.targetRuns,
    required this.hasValidTarget,
    required this.tournamentId,
  });

  // ─── Firestore path helper ────────────────────────────────────────────────
  /// /tournaments/{tournamentId}/matches/{matchId}/innings/{inningsId}
  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .collection('innings')
          .doc(inningsId);

  // ─── Serialisation ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'inningsId': inningsId,
        'matchId': matchId,
        'battingTeamId': battingTeamId,
        'bowlingTeamId': bowlingTeamId,
        'isSecondInnings': isSecondInnings,
        'isCompleted': isCompleted,
        'targetRuns': targetRuns,
        'hasValidTarget': hasValidTarget,
        'tournamentId': tournamentId,
      };

  factory Innings.fromMap(Map<String, dynamic> map) {
    final i = Innings(
      inningsId: map['inningsId'] as String,
      matchId: map['matchId'] as String? ?? '',
      battingTeamId: map['battingTeamId'] as String? ?? '',
      bowlingTeamId: map['bowlingTeamId'] as String? ?? '',
      isSecondInnings: map['isSecondInnings'] as bool? ?? false,
      isCompleted: map['isCompleted'] as bool? ?? false,
      targetRuns: (map['targetRuns'] as num?)?.toInt() ?? 0,
      hasValidTarget: map['hasValidTarget'] as bool? ?? false,
      tournamentId: map['tournamentId'] as String? ?? '',
    );
    _cache[i.inningsId] = i;
    return i;
  }

  // ─── Instance methods ─────────────────────────────────────────────────────
  void markCompleted() {
    isCompleted = true;
    _cache[inningsId] = this;
    _persistAsync();
  }

  void _persistAsync() {
    // Write to tournaments/{tournamentId}/matches/{matchId}/innings/{inningsId}
    // Falls back gracefully if tournamentId or matchId is empty.
    if (tournamentId.isNotEmpty && matchId.isNotEmpty) {
      _doc.set(toMap()).catchError((_) {});
    }
  }

  // ─── SYNCHRONOUS FACTORY: create (first innings) ─────────────────────────
  static Innings create({
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
    required String tournamentId,
  }) {
    final i = Innings(
      inningsId: const Uuid().v4(),
      matchId: matchId,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      isSecondInnings: false,
      isCompleted: false,
      targetRuns: 0,
      hasValidTarget: false,
      tournamentId: tournamentId,
    );
    _cache[i.inningsId] = i;
    i._persistAsync();
    return i;
  }

  // Alias used by playerselection_page.dart
  static Innings createFirstInnings({
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
    required String tournamentId,
  }) =>
      create(
        matchId: matchId,
        battingTeamId: battingTeamId,
        bowlingTeamId: bowlingTeamId,
        tournamentId: tournamentId,
      );

  // ─── SYNCHRONOUS FACTORY: createSecondInnings ────────────────────────────
  static Innings createSecondInnings({
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
    required int firstInningsScore,
    required String tournamentId,
  }) {
    final target = firstInningsScore + 1;
    final i = Innings(
      inningsId: const Uuid().v4(),
      matchId: matchId,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      isSecondInnings: true,
      isCompleted: false,
      targetRuns: target,
      hasValidTarget: true,
      tournamentId: tournamentId,
    );
    _cache[i.inningsId] = i;
    i._persistAsync();
    return i;
  }

  // ─── SYNCHRONOUS LOOKUPS ──────────────────────────────────────────────────
  static Innings? getByInningsId(String inningsId) => _cache[inningsId];

  static Innings? getFirstInnings(String matchId) {
    try {
      return _cache.values
          .firstWhere((i) => i.matchId == matchId && !i.isSecondInnings);
    } catch (_) {
      return null;
    }
  }

  static Innings? getSecondInnings(String matchId) {
    try {
      return _cache.values
          .firstWhere((i) => i.matchId == matchId && i.isSecondInnings);
    } catch (_) {
      return null;
    }
  }

  static List<Innings> getByMatchId(String matchId) =>
      _cache.values.where((i) => i.matchId == matchId).toList();

  // ─── Cache management ─────────────────────────────────────────────────────
  static void addToCache(Innings i) => _cache[i.inningsId] = i;
  static void clearCache() => _cache.clear();

  // ─── Async Firestore load ─────────────────────────────────────────────────
  /// Loads all innings for a match from:
  ///   /tournaments/{tournamentId}/matches/{matchId}/innings
  static Future<void> loadFromFirestore(String matchId,
      {String tournamentId = ''}) async {
    try {
      // Derive tournamentId from cache if not supplied.
      final tId = tournamentId.isNotEmpty
          ? tournamentId
          : (_cache.values
                  .where((i) => i.matchId == matchId)
                  .isNotEmpty
              ? _cache.values.firstWhere((i) => i.matchId == matchId).tournamentId
              : '');

      if (tId.isEmpty) return;

      final snap = await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tId)
          .collection('matches')
          .doc(matchId)
          .collection('innings')
          .get();
      for (final doc in snap.docs) {
        Innings.fromMap(doc.data());
      }
    } catch (_) {}
  }
}