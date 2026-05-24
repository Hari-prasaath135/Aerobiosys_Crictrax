import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Bowler {
  final String bowlerId;
  final String inningsId;
  final String teamId;
  final String playerId;
  int balls;
  double overs;
  int runsConceded;
  int wickets;
  int maidens;
  int extras;
  double economy;

  /// Needed to build the nested Firestore path.
  final String tournamentId;
  final String matchId;

  // ─── Local In-Memory Cache ────────────────────────────────────────────────
  static final Map<String, Bowler> _cache = {};

  Bowler({
    required this.bowlerId,
    required this.inningsId,
    required this.teamId,
    required this.playerId,
    required this.balls,
    required this.overs,
    required this.runsConceded,
    required this.wickets,
    required this.maidens,
    required this.extras,
    required this.economy,
    required this.tournamentId,
    required this.matchId,
  });

  // ─── Firestore Collection Helper ─────────────────────────────────────────
  /// /tournaments/{tournamentId}/matches/{matchId}/innings/{inningsId}/bowlers
  static CollectionReference<Map<String, dynamic>> _col(
          String tournamentId, String matchId, String inningsId) =>
      FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .collection('innings')
          .doc(inningsId)
          .collection('bowlers');

  static String _generateId() => const Uuid().v4();

  // ─── Serialisation ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'bowlerId': bowlerId,
        'inningsId': inningsId,
        'teamId': teamId,
        'playerId': playerId,
        'balls': balls,
        'overs': overs,
        'runsConceded': runsConceded,
        'wickets': wickets,
        'maidens': maidens,
        'extras': extras,
        'economy': economy,
        'tournamentId': tournamentId,
        'matchId': matchId,
      };

  factory Bowler.fromMap(Map<String, dynamic> map) {
    final b = Bowler(
      bowlerId: map['bowlerId'] as String,
      inningsId: map['inningsId'] as String? ?? '',
      teamId: map['teamId'] as String? ?? '',
      playerId: map['playerId'] as String,
      balls: (map['balls'] as num?)?.toInt() ?? 0,
      overs: (map['overs'] as num?)?.toDouble() ?? 0.0,
      runsConceded: (map['runsConceded'] as num?)?.toInt() ?? 0,
      wickets: (map['wickets'] as num?)?.toInt() ?? 0,
      maidens: (map['maidens'] as num?)?.toInt() ?? 0,
      extras: (map['extras'] as num?)?.toInt() ?? 0,
      economy: (map['economy'] as num?)?.toDouble() ?? 0.0,
      tournamentId: map['tournamentId'] as String? ?? '',
      matchId: map['matchId'] as String? ?? '',
    );
    _cache[b.bowlerId] = b;
    return b;
  }

  // ─── updateStats ──────────────────────────────────────────────────────────
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

  // ─── incrementMaiden ──────────────────────────────────────────────────────
  void incrementMaiden() {
    maidens++;
    _cache[bowlerId] = this;
    _persistAsync();
  }

  // ─── save ─────────────────────────────────────────────────────────────────
  void save() {
    _cache[bowlerId] = this;
    _persistAsync();
  }

  void _persistAsync() {
    // Write to tournaments/{tournamentId}/matches/{matchId}/innings/{inningsId}/bowlers/{bowlerId}
    if (tournamentId.isNotEmpty && matchId.isNotEmpty && inningsId.isNotEmpty) {
      _col(tournamentId, matchId, inningsId)
          .doc(bowlerId)
          .set(toMap())
          .catchError((_) {});
    }
  }

  // ─── SYNCHRONOUS FACTORY: create ─────────────────────────────────────────
  static Bowler create({
    required String inningsId,
    required String teamId,
    required String playerId,
    required String tournamentId,
    required String matchId,
  }) {
    final bowler = Bowler(
      bowlerId: _generateId(),
      inningsId: inningsId,
      teamId: teamId,
      playerId: playerId,
      balls: 0,
      overs: 0.0,
      runsConceded: 0,
      wickets: 0,
      maidens: 0,
      extras: 0,
      economy: 0.0,
      tournamentId: tournamentId,
      matchId: matchId,
    );
    _cache[bowler.bowlerId] = bowler;
    bowler._persistAsync();
    return bowler;
  }

  // ─── SYNCHRONOUS LOOKUPS ──────────────────────────────────────────────────
  static Bowler? getByBowlerId(String bowlerId) => _cache[bowlerId];

  static List<Bowler> getByInningsAndTeam(String inningsId, String teamId) {
    return _cache.values
        .where((b) => b.inningsId == inningsId && b.teamId == teamId)
        .toList();
  }

  static List<Bowler> getByInningsId(String inningsId) {
    return _cache.values.where((b) => b.inningsId == inningsId).toList();
  }

  // ─── Cache management ─────────────────────────────────────────────────────
  static void addToCache(Bowler b) => _cache[b.bowlerId] = b;

  static void clearCache() => _cache.clear();

  // ─── Legacy async API ─────────────────────────────────────────────────────
  static Future<Bowler> createAsync({
    required String inningsId,
    required String teamId,
    required String playerId,
    required String tournamentId,
    required String matchId,
  }) async {
    final b = create(
      inningsId: inningsId,
      teamId: teamId,
      playerId: playerId,
      tournamentId: tournamentId,
      matchId: matchId,
    );
    await _col(tournamentId, matchId, inningsId).doc(b.bowlerId).set(b.toMap());
    return b;
  }

  static Future<void> delete(
      String tournamentId, String matchId, String inningsId, String bowlerId) async {
    _cache.remove(bowlerId);
    await _col(tournamentId, matchId, inningsId).doc(bowlerId).delete();
  }

  // ─── Async Firestore load ─────────────────────────────────────────────────
  /// Reads from:
  ///   /tournaments/{tournamentId}/matches/{matchId}/innings/{inningsId}/bowlers
  static Future<void> loadFromFirestore(String inningsId,
      {String tournamentId = '', String matchId = ''}) async {
    try {
      if (tournamentId.isEmpty || matchId.isEmpty) return;

      final snap = await _col(tournamentId, matchId, inningsId).get();
      for (final doc in snap.docs) {
        Bowler.fromMap(doc.data());
      }
    } catch (_) {}
  }
}