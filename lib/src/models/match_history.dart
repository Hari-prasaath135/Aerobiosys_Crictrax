import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class MatchHistory {
  String id;
  final String matchId;
  final String teamAId;
  final String teamBId;
  DateTime matchDate;
  final String matchType;
  int team1Runs;
  int team1Wickets;
  double team1Overs;
  int team2Runs;
  int team2Wickets;
  double team2Overs;
  String result;
  bool isCompleted;
  bool isPaused;
  bool isOnProgress;
  String? pausedState;
  DateTime? matchStartTime;
  DateTime? matchEndTime;

  /// Which tournament this match belonged to.
  final String tournamentId;

  /// UID of the user who created this match — used to look up the right teams.
  final String createdBy;

  // ─── Local In-Memory Cache — keyed by matchId ─────────────────────────────
  static final Map<String, MatchHistory> _cache = {};

  MatchHistory({
    required this.id,
    required this.matchId,
    required this.teamAId,
    required this.teamBId,
    required this.matchDate,
    required this.matchType,
    required this.team1Runs,
    required this.team1Wickets,
    required this.team1Overs,
    required this.team2Runs,
    required this.team2Wickets,
    required this.team2Overs,
    required this.result,
    required this.isCompleted,
    required this.isPaused,
    this.isOnProgress = false,
    this.pausedState,
    this.matchStartTime,
    this.matchEndTime,
    this.tournamentId = '',
    this.createdBy = '',
  });

  // ─── Serialisation ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id': id,
        'matchId': matchId,
        'teamAId': teamAId,
        'teamBId': teamBId,
        'matchDate': matchDate.toIso8601String(),
        'matchType': matchType,
        'team1Runs': team1Runs,
        'team1Wickets': team1Wickets,
        'team1Overs': team1Overs,
        'team2Runs': team2Runs,
        'team2Wickets': team2Wickets,
        'team2Overs': team2Overs,
        'result': result,
        'isCompleted': isCompleted,
        'isPaused': isPaused,
        'isOnProgress': isOnProgress,
        'pausedState': pausedState,
        'matchStartTime': matchStartTime?.toIso8601String(),
        'matchEndTime': matchEndTime?.toIso8601String(),
        'tournamentId': tournamentId,
        'createdBy': createdBy,
      };

  factory MatchHistory.fromMap(Map<String, dynamic> map) {
    final h = MatchHistory(
      id: map['id'] as String? ?? const Uuid().v4(),
      matchId: map['matchId'] as String? ?? '',
      teamAId: map['teamAId'] as String? ?? '',
      teamBId: map['teamBId'] as String? ?? '',
      matchDate: map['matchDate'] != null
          ? DateTime.tryParse(map['matchDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      matchType: map['matchType'] as String? ?? 'CRICKET',
      team1Runs: (map['team1Runs'] as num?)?.toInt() ?? 0,
      team1Wickets: (map['team1Wickets'] as num?)?.toInt() ?? 0,
      team1Overs: (map['team1Overs'] as num?)?.toDouble() ?? 0.0,
      team2Runs: (map['team2Runs'] as num?)?.toInt() ?? 0,
      team2Wickets: (map['team2Wickets'] as num?)?.toInt() ?? 0,
      team2Overs: (map['team2Overs'] as num?)?.toDouble() ?? 0.0,
      result: map['result'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      isPaused: map['isPaused'] as bool? ?? false,
      isOnProgress: map['isOnProgress'] as bool? ?? false,
      pausedState: map['pausedState'] as String?,
      matchStartTime: map['matchStartTime'] != null
          ? DateTime.tryParse(map['matchStartTime'] as String)
          : null,
      matchEndTime: map['matchEndTime'] != null
          ? DateTime.tryParse(map['matchEndTime'] as String)
          : null,
      tournamentId: map['tournamentId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
    );
    if (h.matchId.isNotEmpty) _cache[h.matchId] = h;
    return h;
  }

  // ─── Instance: save ───────────────────────────────────────────────────────
  void save() {
    _cache[matchId] = this;
    _persistAsync();
  }

  /// Instance delete — removes from cache and Firestore.
  void delete() {
    _cache.remove(matchId);
    FirebaseFirestore.instance
        .collection('matchHistories')
        .doc(id)
        .delete()
        .catchError((_) {});
  }

  void _persistAsync() {
    FirebaseFirestore.instance
        .collection('matchHistories')
        .doc(id)
        .set(toMap())
        .catchError((_) {});
  }

  // ─── SYNCHRONOUS FACTORY: create (upserts by matchId) ────────────────────
  static MatchHistory create({
    required String matchId,
    required String teamAId,
    required String teamBId,
    required DateTime matchDate,
    required String matchType,
    required int team1Runs,
    required int team1Wickets,
    required double team1Overs,
    required int team2Runs,
    required int team2Wickets,
    required double team2Overs,
    required String result,
    required bool isCompleted,
    required bool isPaused,
    bool isOnProgress = false,
    String? pausedState,
    DateTime? matchStartTime,
    DateTime? matchEndTime,
    String tournamentId = '',
    String createdBy = '',
  }) {
    // Upsert — reuse existing document id so no duplicates per matchId
    final existing = _cache[matchId];
    final entryId = existing?.id ?? const Uuid().v4();

    // Fall back to current user uid if createdBy not supplied
    final uid = createdBy.isNotEmpty
        ? createdBy
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    final h = MatchHistory(
      id: entryId,
      matchId: matchId,
      teamAId: teamAId,
      teamBId: teamBId,
      matchDate: matchDate,
      matchType: matchType,
      team1Runs: team1Runs,
      team1Wickets: team1Wickets,
      team1Overs: team1Overs,
      team2Runs: team2Runs,
      team2Wickets: team2Wickets,
      team2Overs: team2Overs,
      result: result,
      isCompleted: isCompleted,
      isPaused: isPaused,
      isOnProgress: isOnProgress,
      pausedState: pausedState,
      matchStartTime: matchStartTime,
      matchEndTime: matchEndTime,
      tournamentId: tournamentId,
      createdBy: uid,
    );
    _cache[matchId] = h;
    h._persistAsync();
    return h;
  }

  // ─── SYNCHRONOUS LOOKUPS ──────────────────────────────────────────────────
  static MatchHistory? getByMatchId(String matchId) => _cache[matchId];
  static List<MatchHistory> getAll() => _cache.values.toList();
  static List<MatchHistory> getCompleted() =>
      _cache.values.where((h) => h.isCompleted).toList();
  static List<MatchHistory> getPaused() =>
      _cache.values.where((h) => h.isPaused).toList();
  static List<MatchHistory> getOnProgress() =>
      _cache.values.where((h) => h.isOnProgress).toList();

  // ─── Static delete by matchId ─────────────────────────────────────────────
  static void deleteByMatchId(String matchId) {
    final h = _cache.remove(matchId);
    if (h != null) {
      FirebaseFirestore.instance
          .collection('matchHistories')
          .doc(h.id)
          .delete()
          .catchError((_) {});
    }
  }

  // ─── Stale-entry cleanup (called by history_page) ─────────────────────────
  /// Removes cache entries whose result is empty and are neither completed
  /// nor paused nor on-progress — i.e. orphan records from crashed sessions.
  static void cleanupStaleEntries() {
    _cache.removeWhere((_, h) =>
        !h.isCompleted && !h.isPaused && !h.isOnProgress && h.result.isEmpty);
  }

  // ─── Cache management ─────────────────────────────────────────────────────
  static void addToCache(MatchHistory h) => _cache[h.matchId] = h;
  static void clearCache() => _cache.clear();

  // ─── Async Firestore load ─────────────────────────────────────────────────
  /// Loads only the current user's match histories from /matchHistories,
  /// filtered by createdBy == uid so users never see each other's matches.
  static Future<void> loadFromFirestore({String? userId}) async {
    try {
      final uid = userId ??
          FirebaseAuth.instance.currentUser?.uid ??
          '';
      if (uid.isEmpty) return;

      final snap = await FirebaseFirestore.instance
          .collection('matchHistories')
          .where('createdBy', isEqualTo: uid)
          .get();
      for (final doc in snap.docs) {
        MatchHistory.fromMap(doc.data());
      }
    } catch (_) {}
  }
}