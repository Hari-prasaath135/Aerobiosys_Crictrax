import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ─── Local In-Memory Cache ────────────────────────────────────────────────
  // Key: batId → Batsman
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
    this.dismissalType,
    this.bowlerIdWhoGotWicket,
    this.fielderIdWhoRanOut,
  });

  // ─── Firestore Collection Helper ─────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> _col(
          String tournamentId, String matchId, String inningsId) =>
      FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .collection('innings')
          .doc(inningsId)
          .collection('batsmen');

  static String _generateId() => const Uuid().v4();

  static double calcStrikeRate(int runs, int balls) =>
      balls == 0 ? 0.0 : (runs / balls) * 100;

  // ─── Serialisation ────────────────────────────────────────────────────────
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
    );
    _cache[b.batId] = b;
    return b;
  }

  // ─── copyWith ─────────────────────────────────────────────────────────────
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
      );

  // ─── updateStats (called by scorer screen synchronously) ─────────────────
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
    // Update cache
    _cache[batId] = this;
    // Persist asynchronously (fire-and-forget)
    _persistAsync();
  }

  // ─── markAsOut ────────────────────────────────────────────────────────────
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

  // ─── save (synchronous — updates cache, fires Firestore in background) ───
  void save() {
    _cache[batId] = this;
    _persistAsync();
  }

  void _persistAsync() {
    // Fire-and-forget Firestore write; errors are non-fatal
    FirebaseFirestore.instance
        .collection('batsmen_global')
        .doc(batId)
        .set(toMap())
        .catchError((e) {
      // ignore persistence errors — local cache is source of truth
    });
  }

  // ─── SYNCHRONOUS FACTORY: create ─────────────────────────────────────────
  /// Creates a new Batsman, stores it in the cache, and fires a background
  /// Firestore write. Returns synchronously.
  static Batsman create({
    required String inningsId,
    required String teamId,
    required String playerId,
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
    );
    _cache[batsman.batId] = batsman;
    batsman._persistAsync();
    return batsman;
  }

  // ─── SYNCHRONOUS LOOKUP: getByBatId ──────────────────────────────────────
  static Batsman? getByBatId(String batId) => _cache[batId];

  // ─── SYNCHRONOUS LOOKUP: getByInningsAndTeam ─────────────────────────────
  static List<Batsman> getByInningsAndTeam(String inningsId, String teamId) {
    return _cache.values
        .where((b) => b.inningsId == inningsId && b.teamId == teamId)
        .toList();
  }

  // ─── SYNCHRONOUS LOOKUP: getByPlayerId ───────────────────────────────────
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

  // ─── SYNCHRONOUS LOOKUP: getByInningsId ──────────────────────────────────
  static List<Batsman> getByInningsId(String inningsId) {
    return _cache.values.where((b) => b.inningsId == inningsId).toList();
  }

  // ─── Cache population from Firestore (call once on app start / match load) ─
  static Future<void> loadFromFirestore({
    required String tournamentId,
    required String matchId,
    required String inningsId,
  }) async {
    try {
      final snap =
          await _col(tournamentId, matchId, inningsId).get();
      for (final doc in snap.docs) {
        Batsman.fromMap(doc.data()); // fromMap stores to cache
      }
    } catch (e) {
      // Silently ignore — cache retains any previously loaded data
    }
  }

  /// Stream version — kept for screens that want real-time updates.
  static Stream<List<Batsman>> streamByInnings(
      String tournamentId, String matchId, String inningsId) {
    return _col(tournamentId, matchId, inningsId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Batsman.fromMap(d.data())).toList());
  }

  // ─── Legacy async API (kept for backward-compat with older callers) ───────
  static Future<Batsman> createAsync({
    required String tournamentId,
    required String matchId,
    required String inningsId,
    required String teamId,
    required String teamOwnerUid,
    required String playerId,
    required String playerName,
  }) async {
    final b = create(
      inningsId: inningsId,
      teamId: teamId,
      teamOwnerUid: teamOwnerUid,
      playerId: playerId,
      playerName: playerName,
    );
    await _col(tournamentId, matchId, inningsId)
        .doc(b.batId)
        .set(b.toMap());
    return b;
  }

  static Future<void> delete(String tournamentId, String matchId,
      String inningsId, String batId) async {
    _cache.remove(batId);
    await _col(tournamentId, matchId, inningsId).doc(batId).delete();
  }

  // ─── Cache management helpers ─────────────────────────────────────────────
  static void addToCache(Batsman b) => _cache[b.batId] = b;

  static void clearCache() => _cache.clear();

  static void removeFromCache(String batId) => _cache.remove(batId);
}