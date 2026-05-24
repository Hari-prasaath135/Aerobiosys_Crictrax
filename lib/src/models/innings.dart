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
  });

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
    FirebaseFirestore.instance
        .collection('innings_global')
        .doc(inningsId)
        .set(toMap())
        .catchError((_) {});
  }

  // ─── SYNCHRONOUS FACTORY: create (first innings) ─────────────────────────
  static Innings create({
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
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
  }) =>
      create(
        matchId: matchId,
        battingTeamId: battingTeamId,
        bowlingTeamId: bowlingTeamId,
      );

  // ─── SYNCHRONOUS FACTORY: createSecondInnings ────────────────────────────
  static Innings createSecondInnings({
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
    required int firstInningsScore,
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
  static Future<void> loadFromFirestore(String matchId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('innings_global')
          .where('matchId', isEqualTo: matchId)
          .get();
      for (final doc in snap.docs) {
        Innings.fromMap(doc.data());
      }
    } catch (_) {}
  }
}