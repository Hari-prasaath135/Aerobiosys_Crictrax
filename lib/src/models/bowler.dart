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
  });

  // ─── Firestore Collection Helper ─────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> _col() =>
      FirebaseFirestore.instance.collection('bowlers_global');

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
    _col().doc(bowlerId).set(toMap()).catchError((_) {});
  }

  // ─── SYNCHRONOUS FACTORY: create ─────────────────────────────────────────
  static Bowler create({
    required String inningsId,
    required String teamId,
    required String playerId,
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
  }) async {
    final b = create(
        inningsId: inningsId, teamId: teamId, playerId: playerId);
    await _col().doc(b.bowlerId).set(b.toMap());
    return b;
  }

  static Future<void> delete(String bowlerId) async {
    _cache.remove(bowlerId);
    await _col().doc(bowlerId).delete();
  }

  static Future<void> loadFromFirestore(String inningsId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bowlers_global')
          .where('inningsId', isEqualTo: inningsId)
          .get();
      for (final doc in snap.docs) {
        Bowler.fromMap(doc.data());
      }
    } catch (_) {}
  }
}