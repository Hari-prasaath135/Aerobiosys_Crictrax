import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final String tournamentId;
  final String createdBy;  // ✅ NEW

  int get inningsNumber => isSecondInnings ? 2 : 1;

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
    required this.createdBy,  // ✅ NEW
  });

DocumentReference<Map<String, dynamic>> get _doc {
  final db = FirebaseFirestore.instance;
  final base = tournamentId == 'standalone'
      ? db.collection('users').doc(createdBy).collection('matches').doc(matchId)
      : db.collection('tournaments').doc(tournamentId).collection('matches').doc(matchId);
  return base.collection('innings').doc(inningsId);
}

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
        'createdBy': createdBy,  // ✅ NEW
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
      createdBy: map['createdBy'] as String? ?? '',  // ✅ NEW
    );
    _cache[i.inningsId] = i;
    return i;
  }

  void markCompleted() {
    isCompleted = true;
    _cache[inningsId] = this;
    _persistAsync();
  }

void _persistAsync() {
  if (matchId.isNotEmpty &&
      (tournamentId == 'standalone' ? createdBy.isNotEmpty : tournamentId.isNotEmpty)) {
    _doc.set(toMap()).catchError((_) {});
  }
}
  static Innings create({
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
    required String tournamentId,
    required String createdBy,  
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
      createdBy: createdBy,  // ✅ NEW
    );
    _cache[i.inningsId] = i;
    i._persistAsync();
    return i;
  }

  static Innings createFirstInnings({
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
    required String tournamentId,
    required String createdBy,  //
  }) =>
      create(
        matchId: matchId,
        battingTeamId: battingTeamId,
        bowlingTeamId: bowlingTeamId,
        tournamentId: tournamentId,
        createdBy: createdBy,  // 
      );

  static Innings createSecondInnings({
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
    required int firstInningsScore,
    required String tournamentId,
    required String createdBy,  //
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
      createdBy: createdBy,  // ✅ NEW
    );
    _cache[i.inningsId] = i;
    i._persistAsync();
    return i;
  }

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

  static void addToCache(Innings i) => _cache[i.inningsId] = i;
  static void clearCache() => _cache.clear();

/// Load innings for a specific match from Firestore
static Future<void> loadForMatch(String matchId, {String? userId}) async {
  try {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty || matchId.isEmpty) return;

    debugPrint('📥 Loading innings for matchId=$matchId');

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matches')
        .doc(matchId)
        .collection('innings')
        .get();

    debugPrint('📥 Found ${snap.docs.length} innings docs');

    for (final doc in snap.docs) {
      Innings.fromMap(doc.data()); // populates cache via fromMap
    }
  } catch (e) {
    debugPrint('❌ Innings.loadForMatch error: $e');
  }
}

static Future<void> loadFromFirestore(String matchId,
    {String tournamentId = '', String createdBy = ''}) async {
  try {
    final cached = _cache.values.where((i) => i.matchId == matchId);
    final tId = tournamentId.isNotEmpty
        ? tournamentId
        : (cached.isNotEmpty ? cached.first.tournamentId : '');
    final uid = createdBy.isNotEmpty
        ? createdBy
        : (cached.isNotEmpty ? cached.first.createdBy : '');

    if (tId.isEmpty) return;
    if (tId == 'standalone' && uid.isEmpty) return;

    final db = FirebaseFirestore.instance;
    final base = tId == 'standalone'
        ? db.collection('users').doc(uid).collection('matches').doc(matchId)
        : db.collection('tournaments').doc(tId).collection('matches').doc(matchId);

    final snap = await base.collection('innings').get();
    for (final doc in snap.docs) { Innings.fromMap(doc.data()); }
  } catch (_) {}
}
}