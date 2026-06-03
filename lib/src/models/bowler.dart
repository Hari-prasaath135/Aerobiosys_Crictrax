import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Bowler {
  final String bowlerId;
  final String inningsId;
  final String teamId;
  final String playerId;
  final String playerName; // ✅ NEW
  int balls;
  double overs;
  int runsConceded;
  int wickets;
  int maidens;
  int extras;
  double economy;

  final String tournamentId;
  final String matchId;
  final String createdBy;

  static final Map<String, Bowler> _cache = {};

  Bowler({
    required this.bowlerId,
    required this.inningsId,
    required this.teamId,
    required this.playerId,
    this.playerName = '', // ✅ NEW
    required this.balls,
    required this.overs,
    required this.runsConceded,
    required this.wickets,
    required this.maidens,
    required this.extras,
    required this.economy,
    required this.tournamentId,
    required this.matchId,
    required this.createdBy,
  });

  static CollectionReference<Map<String, dynamic>> _col(
      String tournamentId, String matchId, String inningsId,
      {String createdBy = ''}) {
    final db = FirebaseFirestore.instance;
    final base = tournamentId == 'standalone'
        ? db.collection('users').doc(createdBy).collection('matches').doc(matchId)
        : db.collection('tournaments').doc(tournamentId).collection('matches').doc(matchId);
    return base.collection('innings').doc(inningsId).collection('bowlers');
  }

  static String _generateId() => const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'bowlerId': bowlerId,
        'inningsId': inningsId,
        'teamId': teamId,
        'playerId': playerId,
        'playerName': playerName, // ✅ NEW
        'balls': balls,
        'overs': overs,
        'runsConceded': runsConceded,
        'wickets': wickets,
        'maidens': maidens,
        'extras': extras,
        'economy': economy,
        'tournamentId': tournamentId,
        'matchId': matchId,
        'createdBy': createdBy,
      };

  factory Bowler.fromMap(Map<String, dynamic> map) {
    final b = Bowler(
      bowlerId: map['bowlerId'] as String,
      inningsId: map['inningsId'] as String? ?? '',
      teamId: map['teamId'] as String? ?? '',
      playerId: map['playerId'] as String,
      playerName: map['playerName'] as String? ?? '', // ✅ NEW
      balls: (map['balls'] as num?)?.toInt() ?? 0,
      overs: (map['overs'] as num?)?.toDouble() ?? 0.0,
      runsConceded: (map['runsConceded'] as num?)?.toInt() ?? 0,
      wickets: (map['wickets'] as num?)?.toInt() ?? 0,
      maidens: (map['maidens'] as num?)?.toInt() ?? 0,
      extras: (map['extras'] as num?)?.toInt() ?? 0,
      economy: (map['economy'] as num?)?.toDouble() ?? 0.0,
      tournamentId: map['tournamentId'] as String? ?? '',
      matchId: map['matchId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
    );
    _cache[b.bowlerId] = b;
    return b;
  }

  void updateStats(
    int runs,
    bool isWicket, {
    int extrasRuns = 0,
    bool countBall = true,
  }) {
    runsConceded += runs;
    if (isWicket) wickets++;
    extras += extrasRuns;

    if (countBall) {
      balls++;
      final completedOvers = balls ~/ 6;
      final remainingBalls = balls % 6;
      overs = completedOvers + (remainingBalls / 10.0);

      final totalOvers = completedOvers + (remainingBalls / 6.0);
      economy = totalOvers > 0 ? (runsConceded / totalOvers) : 0.0;
    }

    _cache[bowlerId] = this;
    _persistAsync();
  }

  void incrementMaiden() {
    maidens++;
    _cache[bowlerId] = this;
    _persistAsync();
  }

  void save() {
    _cache[bowlerId] = this;
    _persistAsync();
  }

  void _persistAsync() {
    if (matchId.isNotEmpty && inningsId.isNotEmpty &&
        (tournamentId == 'standalone'
            ? createdBy.isNotEmpty
            : tournamentId.isNotEmpty)) {
      _col(tournamentId, matchId, inningsId, createdBy: createdBy)
          .doc(bowlerId)
          .set(toMap())
          .catchError((e) {
        debugPrint('❌ Failed to save bowler: $e');
      });
    }
  }

  static Bowler create({
    required String inningsId,
    required String teamId,
    required String playerId,
    String playerName = '', // ✅ NEW
    required String tournamentId,
    required String matchId,
    required String createdBy,
  }) {
    final bowler = Bowler(
      bowlerId: _generateId(),
      inningsId: inningsId,
      teamId: teamId,
      playerId: playerId,
      playerName: playerName, // ✅ NEW
      balls: 0,
      overs: 0.0,
      runsConceded: 0,
      wickets: 0,
      maidens: 0,
      extras: 0,
      economy: 0.0,
      tournamentId: tournamentId,
      matchId: matchId,
      createdBy: createdBy,
    );
    _cache[bowler.bowlerId] = bowler;
    bowler._persistAsync();
    return bowler;
  }

  static Bowler? getByBowlerId(String bowlerId) => _cache[bowlerId];

  static List<Bowler> getByInningsAndTeam(String inningsId, String teamId) {
    return _cache.values
        .where((b) => b.inningsId == inningsId && b.teamId == teamId)
        .toList();
  }

  static List<Bowler> getByInningsId(String inningsId) {
    return _cache.values.where((b) => b.inningsId == inningsId).toList();
  }

  static void addToCache(Bowler b) => _cache[b.bowlerId] = b;
  static void clearCache() => _cache.clear();

  static Future<Bowler> createAsync({
    required String inningsId,
    required String teamId,
    required String playerId,
    String playerName = '', // ✅ NEW
    required String tournamentId,
    required String matchId,
    required String createdBy,
  }) async {
    final b = create(
      inningsId: inningsId,
      teamId: teamId,
      playerId: playerId,
      playerName: playerName, // ✅ NEW
      tournamentId: tournamentId,
      matchId: matchId,
      createdBy: createdBy,
    );
    await _col(tournamentId, matchId, inningsId, createdBy: createdBy)
        .doc(b.bowlerId)
        .set(b.toMap());
    return b;
  }

  static Future<void> delete(
      String tournamentId, String matchId, String inningsId, String bowlerId,
      {String createdBy = ''}) async {
    _cache.remove(bowlerId);
    await _col(tournamentId, matchId, inningsId, createdBy: createdBy)
        .doc(bowlerId)
        .delete();
  }
  // In bowler.dart — add this static method
static Future<void> loadForInnings(
  String inningsId, {
  required String matchId,
  required String userId,
}) async {
  try {
    if (inningsId.isEmpty || userId.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('matches')
        .doc(matchId)
        .collection('innings')
        .doc(inningsId)
        .collection('bowlers')
        .get();
    for (final doc in snap.docs) {
      Bowler.fromMap(doc.data());
    }
  } catch (e) {
    debugPrint('❌ Bowler.loadForInnings error: $e');
  }
}
  static Future<void> loadFromFirestore(String inningsId,
      {String tournamentId = '',
      String matchId = '',
      String createdBy = ''}) async {
    try {
      if (matchId.isEmpty) return;
      if (tournamentId == 'standalone' && createdBy.isEmpty) return;
      if (tournamentId != 'standalone' && tournamentId.isEmpty) return;

      final snap = await _col(tournamentId, matchId, inningsId,
              createdBy: createdBy)
          .get();
      for (final doc in snap.docs) {
        Bowler.fromMap(doc.data());
      }
    } catch (_) {}
  }
}