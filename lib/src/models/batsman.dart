import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Batsman {
  final String batId;
  final String inningsId;
  final String teamId;
  final String teamOwnerUid;
  final String playerId;
  final String playerName;
  int runs;
  int ballsFaced;
  int fours;
  int sixes;
  int dotBalls;
  double strikeRate;
  int extras;
  bool isOut;
  String? dismissalType;
  String? bowlerIdWhoGotWicket;
  String? fielderIdWhoRanOut;

  final String tournamentId;
  final String matchId;
  final String createdBy;  // ✅ NEW

  static final Map<String, Batsman> _cache = {};

  Batsman({
    required this.batId,
    required this.inningsId,
    required this.teamId,
    required this.teamOwnerUid,
    required this.playerId,
    required this.playerName,
    required this.runs,
    required this.ballsFaced,
    required this.fours,
    required this.sixes,
    required this.dotBalls,
    required this.strikeRate,
    required this.extras,
    required this.isOut,
    required this.tournamentId,
    required this.matchId,
    required this.createdBy,  // ✅ NEW
    this.dismissalType,
    this.bowlerIdWhoGotWicket,
    this.fielderIdWhoRanOut,
  });

static CollectionReference<Map<String, dynamic>> _col(
        String tournamentId, String matchId, String inningsId,
        {String createdBy = ''}) {
  final db = FirebaseFirestore.instance;
  final base = tournamentId == 'standalone'
      ? db.collection('users').doc(createdBy).collection('matches').doc(matchId)
      : db.collection('tournaments').doc(tournamentId).collection('matches').doc(matchId);
  return base.collection('innings').doc(inningsId).collection('batsmen');
}

  static String _generateId() => const Uuid().v4();

  static double calcStrikeRate(int runs, int balls) =>
      balls == 0 ? 0.0 : (runs / balls) * 100;

  Map<String, dynamic> toMap() => {
        'batId': batId,
        'inningsId': inningsId,
        'teamId': teamId,
        'teamOwnerUid': teamOwnerUid,
        'playerId': playerId,
        'playerName': playerName,
        'runs': runs,
        'ballsFaced': ballsFaced,
        'fours': fours,
        'sixes': sixes,
        'dotBalls': dotBalls,
        'strikeRate': strikeRate,
        'extras': extras,
        'isOut': isOut,
        'dismissalType': dismissalType,
        'bowlerIdWhoGotWicket': bowlerIdWhoGotWicket,
        'fielderIdWhoRanOut': fielderIdWhoRanOut,
        'tournamentId': tournamentId,
        'matchId': matchId,
        'createdBy': createdBy,  // ✅ NEW
      };

  factory Batsman.fromMap(Map<String, dynamic> map) {
    final b = Batsman(
      batId: map['batId'] as String,
      inningsId: map['inningsId'] as String,
      teamId: map['teamId'] as String? ?? '',
      teamOwnerUid: map['teamOwnerUid'] as String? ?? '',
      playerId: map['playerId'] as String,
      playerName: map['playerName'] as String? ?? '',
      runs: (map['runs'] as num?)?.toInt() ?? 0,
      ballsFaced: (map['ballsFaced'] as num?)?.toInt() ?? 0,
      fours: (map['fours'] as num?)?.toInt() ?? 0,
      sixes: (map['sixes'] as num?)?.toInt() ?? 0,
      dotBalls: (map['dotBalls'] as num?)?.toInt() ?? 0,
      strikeRate: (map['strikeRate'] as num?)?.toDouble() ?? 0.0,
      extras: (map['extras'] as num?)?.toInt() ?? 0,
      isOut: map['isOut'] as bool? ?? false,
      dismissalType: map['dismissalType'] as String?,
      bowlerIdWhoGotWicket: map['bowlerIdWhoGotWicket'] as String?,
      fielderIdWhoRanOut: map['fielderIdWhoRanOut'] as String?,
      tournamentId: map['tournamentId'] as String? ?? '',
      matchId: map['matchId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',  // ✅ NEW
    );
    _cache[b.batId] = b;
    return b;
  }

  Batsman copyWith({
    int? runs,
    int? ballsFaced,
    int? fours,
    int? sixes,
    int? dotBalls,
    double? strikeRate,
    int? extras,
    bool? isOut,
    String? dismissalType,
    String? bowlerIdWhoGotWicket,
    String? fielderIdWhoRanOut,
  }) =>
      Batsman(
        batId: batId,
        inningsId: inningsId,
        teamId: teamId,
        teamOwnerUid: teamOwnerUid,
        playerId: playerId,
        playerName: playerName,
        runs: runs ?? this.runs,
        ballsFaced: ballsFaced ?? this.ballsFaced,
        fours: fours ?? this.fours,
        sixes: sixes ?? this.sixes,
        dotBalls: dotBalls ?? this.dotBalls,
        strikeRate: strikeRate ?? this.strikeRate,
        extras: extras ?? this.extras,
        isOut: isOut ?? this.isOut,
        dismissalType: dismissalType ?? this.dismissalType,
        bowlerIdWhoGotWicket:
            bowlerIdWhoGotWicket ?? this.bowlerIdWhoGotWicket,
        fielderIdWhoRanOut: fielderIdWhoRanOut ?? this.fielderIdWhoRanOut,
        tournamentId: tournamentId,
        matchId: matchId,
        createdBy: createdBy,  // ✅ NEW
      );

  void updateStats(int runsScored,
      {int extrasRuns = 0, bool countBall = true}) {
    runs += runsScored;
    if (countBall) {
      ballsFaced++;
      if (runsScored == 0 && extrasRuns == 0) dotBalls++;
      if (runsScored == 4) fours++;
      if (runsScored == 6) sixes++;
    }
    strikeRate = calcStrikeRate(runs, ballsFaced);
    _cache[batId] = this;
    _persistAsync();
  }

  void markAsOut({
    String? bowlerIdWhoGotWicket,
    String? dismissalType,
    String? fielderIdWhoRanOut,
  }) {
    isOut = true;
    if (bowlerIdWhoGotWicket != null) {
      this.bowlerIdWhoGotWicket = bowlerIdWhoGotWicket;
      this.dismissalType = 'bowled';
    }
    if (dismissalType != null) this.dismissalType = dismissalType;
    if (fielderIdWhoRanOut != null) {
      this.fielderIdWhoRanOut = fielderIdWhoRanOut;
    }
    _cache[batId] = this;
    _persistAsync();
  }

  void save() {
    _cache[batId] = this;
    _persistAsync();
  }

  void _persistAsync() {
  if (matchId.isNotEmpty && inningsId.isNotEmpty &&
      (tournamentId == 'standalone' ? createdBy.isNotEmpty : tournamentId.isNotEmpty)) {
    _col(tournamentId, matchId, inningsId, createdBy: createdBy)
        .doc(batId)
        .set(toMap())
        .catchError((e) { debugPrint('❌ Failed to save batsman: $e'); });
  }
}

  static Batsman create({
    required String inningsId,
    required String teamId,
    required String playerId,
    required String tournamentId,
    required String matchId,
    required String createdBy,  // ✅ NEW - REQUIRED
    String teamOwnerUid = '',
    String playerName = '',
  }) {
    final batsman = Batsman(
      batId: _generateId(),
      inningsId: inningsId,
      teamId: teamId,
      teamOwnerUid: teamOwnerUid,
      playerId: playerId,
      playerName: playerName,
      runs: 0,
      ballsFaced: 0,
      fours: 0,
      sixes: 0,
      dotBalls: 0,
      strikeRate: 0.0,
      extras: 0,
      isOut: false,
      tournamentId: tournamentId,
      matchId: matchId,
      createdBy: createdBy,  // ✅ NEW
    );
    _cache[batsman.batId] = batsman;
    batsman._persistAsync();
    return batsman;
  }

  static Batsman? getByBatId(String batId) => _cache[batId];

  static List<Batsman> getByInningsAndTeam(String inningsId, String teamId) {
    return _cache.values
        .where((b) => b.inningsId == inningsId && b.teamId == teamId)
        .toList();
  }

  static Batsman? getByPlayerId(
      String inningsId, String teamId, String playerId) {
    try {
      return _cache.values.firstWhere(
        (b) =>
            b.inningsId == inningsId &&
            b.teamId == teamId &&
            b.playerId == playerId,
      );
    } catch (_) {
      return null;
    }
  }

  static List<Batsman> getByInningsId(String inningsId) {
    return _cache.values.where((b) => b.inningsId == inningsId).toList();
  }

static Future<void> loadFromFirestore(String inningsId,
    {String tournamentId = '', String matchId = '', String createdBy = ''}) async {
  try {
    if (matchId.isEmpty) return;
    if (tournamentId == 'standalone' && createdBy.isEmpty) return;
    if (tournamentId != 'standalone' && tournamentId.isEmpty) return;

    final snap = await _col(tournamentId, matchId, inningsId,
                            createdBy: createdBy).get();
    for (final doc in snap.docs) { Batsman.fromMap(doc.data()); }
  } catch (_) {}
}

  static Stream<List<Batsman>> streamByInnings(
      String tournamentId, String matchId, String inningsId) {
    return _col(tournamentId, matchId, inningsId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Batsman.fromMap(d.data())).toList());
  }



static Future<Batsman> createAsync({
  required String inningsId,
  required String teamId,
  required String teamOwnerUid,
  required String playerId,
  required String playerName,
  required String tournamentId,
  required String matchId,
  required String createdBy,
}) async {
  final b = create(
    inningsId: inningsId,
    teamId: teamId,
    teamOwnerUid: teamOwnerUid,
    playerId: playerId,
    playerName: playerName,
    tournamentId: tournamentId,
    matchId: matchId,
    createdBy: createdBy,
  );
  await _col(tournamentId, matchId, inningsId, createdBy: createdBy)
      .doc(b.batId)
      .set(b.toMap());
  return b;
}

static Future<void> delete(String tournamentId, String matchId,
    String inningsId, String batId, {String createdBy = ''}) async {
  _cache.remove(batId);
  await _col(tournamentId, matchId, inningsId, createdBy: createdBy)
      .doc(batId)
      .delete();
}

  static void addToCache(Batsman b) => _cache[b.batId] = b;
  static void clearCache() => _cache.clear();
  static void removeFromCache(String batId) => _cache.remove(batId);
}