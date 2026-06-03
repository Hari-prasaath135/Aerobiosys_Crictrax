import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Match {
  final String matchId;
  String get id => matchId;

  final String teamId1;
  final String teamId2;
  final int overs;
  final bool isNoballAllowed;
  final bool isWideAllowed;
  final DateTime? matchDate;
  bool isCompleted;

  final String tossWonBy;
  final int batBowlFlag;
  final String tournamentId;
  final String createdBy;

  bool get isBattingFirst => batBowlFlag == 1;

  static final Map<String, Match> _cache = {};

  Match({
    required this.matchId,
    required this.teamId1,
    required this.teamId2,
    required this.overs,
    required this.isNoballAllowed,
    required this.isWideAllowed,
    required this.tossWonBy,
    required this.tournamentId,
    required this.createdBy,
    this.batBowlFlag = 1,
    this.matchDate,
    this.isCompleted = false,
  });

  String getBattingTeamId() {
    if (isBattingFirst) return tossWonBy;
    return tossWonBy == teamId1 ? teamId2 : teamId1;
  }

  String getBowlingTeamId() {
    final batting = getBattingTeamId();
    return batting == teamId1 ? teamId2 : teamId1;
  }

  // ✅ FIXED: Proper closing brace + standalone routing
  DocumentReference<Map<String, dynamic>> get _doc {
    if (tournamentId == 'standalone') {
      // Standalone matches go under users/{createdBy}/matches/{matchId}
      return FirebaseFirestore.instance
          .collection('users')
          .doc(createdBy)
          .collection('matches')
          .doc(matchId);
    }
    // Tournament matches stay under tournaments/{tournamentId}/matches/{matchId}
    return FirebaseFirestore.instance
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .doc(matchId);
  }

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
        'tournamentId': tournamentId,
        'createdBy': createdBy,
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
      tournamentId: map['tournamentId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
    );
    _cache[m.matchId] = m;
    return m;
  }

  void save() {
    _cache[matchId] = this;
    if (createdBy.isNotEmpty) {
      // ✅ Works for both standalone (users path) and tournament (tournaments path)
      // since _doc already resolves the correct path
      _doc.set(toMap()).catchError((e) {
        debugPrint('❌ Failed to save match to Firestore: $e');
      });
    }
  }

  static Match create({
    required String teamId1,
    required String teamId2,
    required int overs,
    required String tossWonBy,
    required String tournamentId,
    required String createdBy,
    bool isNoballAllowed = true,
    bool isWideAllowed = true,
    int batBowlFlag = 1,
    DateTime? matchDate,
  }) {
    if (tournamentId.isEmpty) {
      throw Exception('Tournament ID is required');
    }
    if (createdBy.isEmpty) {
      throw Exception('Creator UID is required');
    }

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
      tournamentId: tournamentId,
      createdBy: createdBy,
    );
    _cache[m.matchId] = m;
    m.save();
    return m;
  }

  static Match? getByMatchId(String matchId) => _cache[matchId];
  static List<Match> getAll() => _cache.values.toList();
  static void addToCache(Match m) => _cache[m.matchId] = m;
  static void clearCache() => _cache.clear();

  static Future<void> loadForMatch(String matchId, {String? userId}) async {
  try {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty || matchId.isEmpty) return;

    final db = FirebaseFirestore.instance;

    // Path 1: users/{uid}/matches/{matchId}
    final docUser = await db
        .collection('users')
        .doc(uid)
        .collection('matches')
        .doc(matchId)
        .get();

    if (docUser.exists && docUser.data() != null) {
      Match.fromMap(docUser.data()!);
      debugPrint('✅ Match loaded (user path): $matchId');
      return;
    }

    // Path 2: search tournaments
    final tournamentsSnap = await db.collection('tournaments').get();
    for (final tDoc in tournamentsSnap.docs) {
      final docTournament = await db
          .collection('tournaments')
          .doc(tDoc.id)
          .collection('matches')
          .doc(matchId)
          .get();

      if (docTournament.exists && docTournament.data() != null) {
        Match.fromMap(docTournament.data()!);
        debugPrint('✅ Match loaded (tournament path): $matchId');
        return;
      }
    }

    debugPrint('⚠️ Match not found in any path: $matchId');
  } catch (e) {
    debugPrint('❌ Match.loadForMatch error: $e');
  }
}

  // ✅ FIXED: loadFromFirestore handles both standalone and tournament paths
  static Future<void> loadFromFirestore(String matchId,
      {String tournamentId = '', String createdBy = ''}) async {
    try {
      final cached = _cache[matchId];
      final tId =
          tournamentId.isNotEmpty ? tournamentId : (cached?.tournamentId ?? '');
      final uid =
          createdBy.isNotEmpty ? createdBy : (cached?.createdBy ?? '');

      if (tId.isEmpty) return;

      DocumentSnapshot<Map<String, dynamic>> doc;

      if (tId == 'standalone') {
        // ✅ Fetch from users/{uid}/matches/{matchId}
        if (uid.isEmpty) {
          final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
          if (currentUid.isEmpty) return;
          doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .collection('matches')
              .doc(matchId)
              .get();
        } else {
          doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('matches')
              .doc(matchId)
              .get();
        }
      } else {
        // Fetch from tournaments/{tournamentId}/matches/{matchId}
        doc = await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(tId)
            .collection('matches')
            .doc(matchId)
            .get();
      }

      if (doc.exists && doc.data() != null) {
        Match.fromMap(doc.data()!);
      }
    } catch (_) {}
  }
}