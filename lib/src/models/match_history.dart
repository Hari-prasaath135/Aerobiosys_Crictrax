import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final String tournamentId;
  final String createdBy;

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

  // ── Save to BOTH paths ────────────────────────────────────────────────────

  void save() {
    _cache[matchId] = this;
    _persistAsync();
  }

  // ── Fire-and-forget async write to Firestore ──────────────────────────────
  void _persistAsync() {
    if (createdBy.isEmpty) {
      debugPrint('⚠️ MatchHistory._persistAsync: createdBy is empty, skipping');
      return;
    }

    final data = toMap();
    final db = FirebaseFirestore.instance;

    // Path 1: flat list — always write
    db
        .collection('users')
        .doc(createdBy)
        .collection('matchHistories')
        .doc(id)
        .set(data, SetOptions(merge: true))
        .catchError((e) => debugPrint('❌ Failed to save to matchHistories: $e'));

    // Path 2: nested — standalone only
    if (tournamentId == 'standalone' || tournamentId.isEmpty) {
      db
          .collection('users')
          .doc(createdBy)
          .collection('matches')
          .doc(matchId)
          .collection('history')
          .doc(id)
          .set(data, SetOptions(merge: true))
          .catchError((e) => debugPrint('❌ Failed to save nested history: $e'));
    }
  }

  // ── Awaitable write — used before navigation to confirm Firestore write ───
  Future<void> persistAndAwait() async {
    if (createdBy.isEmpty) {
      debugPrint('⚠️ persistAndAwait: createdBy is empty, skipping');
      return;
    }

    final data = toMap();
    final db = FirebaseFirestore.instance;

    try {
      await db
          .collection('users')
          .doc(createdBy)
          .collection('matchHistories')
          .doc(id)
          .set(data, SetOptions(merge: true));
      debugPrint(
        '✅ persistAndAwait: written — '
        'isCompleted=$isCompleted, '
        'isOnProgress=$isOnProgress, '
        'isPaused=$isPaused, '
        'result=$result',
      );
    } catch (e) {
      debugPrint('❌ persistAndAwait matchHistories failed: $e');
    }

    if (tournamentId == 'standalone' || tournamentId.isEmpty) {
      try {
        await db
            .collection('users')
            .doc(createdBy)
            .collection('matches')
            .doc(matchId)
            .collection('history')
            .doc(id)
            .set(data, SetOptions(merge: true));
        debugPrint('✅ persistAndAwait: nested history written');
      } catch (e) {
        debugPrint('❌ persistAndAwait nested history failed: $e');
      }
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  void delete() {
    _cache.remove(matchId);
    if (createdBy.isEmpty) return;

    final db = FirebaseFirestore.instance;

    db
        .collection('users')
        .doc(createdBy)
        .collection('matches')
        .doc(matchId)
        .collection('history')
        .doc(id)
        .delete()
        .catchError((_) {});

    db
        .collection('users')
        .doc(createdBy)
        .collection('matchHistories')
        .doc(id)
        .delete()
        .catchError((_) {});
  }

  // ── Call this whenever match status changes (pause / resume / complete) ───
 void updateStatus({
  bool? isPaused,
  bool? isOnProgress,
  bool? isCompleted,
  String? result,
  String? pausedState,
  DateTime? matchEndTime,
}) {
  if (isPaused != null) this.isPaused = isPaused;
  if (isOnProgress != null) this.isOnProgress = isOnProgress;
  if (isCompleted != null) this.isCompleted = isCompleted;
  if (result != null) this.result = result;
  if (pausedState != null) this.pausedState = pausedState;
  if (matchEndTime != null) this.matchEndTime = matchEndTime;

  // Bump matchDate so this entry sorts to top on next load
  matchDate = DateTime.now();

  _cache[matchId] = this;
  _persistAsync();
}

  // ── Create (upsert by matchId) ────────────────────────────────────────────

  static MatchHistory? getByMatchId(String matchId) => _cache[matchId];

  // 🔥 NEW: Cache-first, Firestore-fallback lookup. Prevents creating a
  // duplicate document when the real one exists in Firestore but the
  // in-memory cache happens to be cold (fresh app process, screen reached
  // without a prior loadFromFirestore() call, etc.). Any code path that
  // decides "update vs create" MUST use this instead of the sync
  // getByMatchId when a missed match would otherwise mean data loss.
  static Future<MatchHistory?> fetchByMatchId(
    String matchId, {
    String? userId,
  }) async {
    final cached = _cache[matchId];
    if (cached != null) return cached;

    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty || matchId.isEmpty) return null;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('matchHistories')
          .where('matchId', isEqualTo: matchId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        debugPrint(
          '📥 fetchByMatchId: found existing doc in Firestore for '
          'matchId=$matchId (cache was cold) — reusing id=${snap.docs.first.id}',
        );
        return MatchHistory.fromMap(snap.docs.first.data());
      }
      debugPrint('📥 fetchByMatchId: no existing doc for matchId=$matchId');
    } catch (e) {
      debugPrint('❌ fetchByMatchId error: $e');
    }
    return null;
  }
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
    final existing = _cache[matchId];
    final entryId = existing?.id ?? const Uuid().v4();

    // Always resolve createdBy — never let it be empty
    final uid = createdBy.isNotEmpty
        ? createdBy
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    if (uid.isEmpty) {
      debugPrint(
        '⚠️ MatchHistory.create: createdBy is empty! History will not be saved to Firestore.',
      );
    }

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

  // ── Lookups ───────────────────────────────────────────────────────────────


  static List<MatchHistory> getAll() => _cache.values.toList();
  static List<MatchHistory> getCompleted() =>
      _cache.values.where((h) => h.isCompleted).toList();
  static List<MatchHistory> getPaused() =>
      _cache.values.where((h) => h.isPaused).toList();
  static List<MatchHistory> getOnProgress() =>
      _cache.values.where((h) => h.isOnProgress).toList();

  static void deleteByMatchId(String matchId) {
    final h = _cache.remove(matchId);
    h?.delete();
  }

  static void cleanupStaleEntries() {
    _cache.removeWhere((_, h) =>
        !h.isCompleted &&
        !h.isPaused &&
        !h.isOnProgress &&
        h.result.isEmpty &&
        h.matchId.isNotEmpty);
  }

  static void addToCache(MatchHistory h) => _cache[h.matchId] = h;
  static void clearCache() => _cache.clear();

  // ── Load from Firestore ───────────────────────────────────────────────────

  /// Loads from users/{uid}/matchHistories — scoped to current user only
  static Future<void> loadFromFirestore({String? userId}) async {
    try {
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        debugPrint('⚠️ loadFromFirestore: no uid, skipping');
        return;
      }

      debugPrint('📥 Loading match histories for uid=$uid');

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('matchHistories')
          .orderBy('matchDate', descending: true)
          .get();

      debugPrint('📥 Found ${snap.docs.length} history docs in Firestore');

      for (final doc in snap.docs) {
        MatchHistory.fromMap(doc.data());
      }
    } catch (e) {
      debugPrint('❌ loadFromFirestore error: $e');
    }
  }

  /// Load history for a specific match — from users/{uid}/matches/{matchId}/history
  static Future<void> loadForMatch(String matchId, {String? userId}) async {
    try {
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty || matchId.isEmpty) return;

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('matches')
          .doc(matchId)
          .collection('history')
          .get();

      for (final doc in snap.docs) {
        MatchHistory.fromMap(doc.data());
      }
    } catch (e) {
      debugPrint('❌ loadForMatch error: $e');
    }
  }
}