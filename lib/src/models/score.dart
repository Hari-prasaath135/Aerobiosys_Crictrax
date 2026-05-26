import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Score {
  final String scoreId;
  final String inningsId;
  int totalRuns;
  int wickets;
  double overs;
  int currentBall;
  double crr;
  int byes;
  int wides;
  int noBalls;
  int totalExtras;
  List<String> currentOver;
  String strikeBatsmanId;
  String nonStrikeBatsmanId;
  String currentBowlerId;

  final String tournamentId;
  final String matchId;
  final String createdBy;  // ✅ NEW

  static final Map<String, Score> _cache = {};

  Score({
    required this.scoreId,
    required this.inningsId,
    required this.totalRuns,
    required this.wickets,
    required this.overs,
    required this.currentBall,
    required this.crr,
    required this.byes,
    required this.wides,
    required this.noBalls,
    required this.totalExtras,
    required this.currentOver,
    required this.strikeBatsmanId,
    required this.nonStrikeBatsmanId,
    required this.currentBowlerId,
    required this.tournamentId,
    required this.matchId,
    required this.createdBy,  // ✅ NEW
  });

  String get extrasDisplay {
    final total = byes + wides + noBalls;
    return '$total (W:$wides NB:$noBalls B:$byes)';
  }
DocumentReference<Map<String, dynamic>> get _doc {
  final db = FirebaseFirestore.instance;
  final base = tournamentId == 'standalone'
      ? db.collection('users').doc(createdBy).collection('matches').doc(matchId)
      : db.collection('tournaments').doc(tournamentId).collection('matches').doc(matchId);
  return base.collection('innings').doc(inningsId).collection('scores').doc(scoreId);
}

  Map<String, dynamic> toMap() => {
        'scoreId': scoreId,
        'inningsId': inningsId,
        'totalRuns': totalRuns,
        'wickets': wickets,
        'overs': overs,
        'currentBall': currentBall,
        'crr': crr,
        'byes': byes,
        'wides': wides,
        'noBalls': noBalls,
        'totalExtras': totalExtras,
        'currentOver': currentOver,
        'strikeBatsmanId': strikeBatsmanId,
        'nonStrikeBatsmanId': nonStrikeBatsmanId,
        'currentBowlerId': currentBowlerId,
        'tournamentId': tournamentId,
        'matchId': matchId,
        'createdBy': createdBy,  // ✅ NEW
      };

  factory Score.fromMap(Map<String, dynamic> map) {
    final rawOver = map['currentOver'];
    final over = rawOver is List
        ? rawOver.map((e) => e.toString()).toList()
        : <String>[];

    final s = Score(
      scoreId: map['scoreId'] as String? ?? const Uuid().v4(),
      inningsId: map['inningsId'] as String? ?? '',
      totalRuns: (map['totalRuns'] as num?)?.toInt() ?? 0,
      wickets: (map['wickets'] as num?)?.toInt() ?? 0,
      overs: (map['overs'] as num?)?.toDouble() ?? 0.0,
      currentBall: (map['currentBall'] as num?)?.toInt() ?? 0,
      crr: (map['crr'] as num?)?.toDouble() ?? 0.0,
      byes: (map['byes'] as num?)?.toInt() ?? 0,
      wides: (map['wides'] as num?)?.toInt() ?? 0,
      noBalls: (map['noBalls'] as num?)?.toInt() ?? 0,
      totalExtras: (map['totalExtras'] as num?)?.toInt() ?? 0,
      currentOver: over,
      strikeBatsmanId: map['strikeBatsmanId'] as String? ?? '',
      nonStrikeBatsmanId: map['nonStrikeBatsmanId'] as String? ?? '',
      currentBowlerId: map['currentBowlerId'] as String? ?? '',
      tournamentId: map['tournamentId'] as String? ?? '',
      matchId: map['matchId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',  // ✅ NEW
    );
    _cache[s.inningsId] = s;
    return s;
  }

  void save() {
    totalExtras = byes + wides + noBalls;
    _cache[inningsId] = this;
    _persistAsync();
  }

void _persistAsync() {
  if (matchId.isNotEmpty && inningsId.isNotEmpty &&
      (tournamentId == 'standalone' ? createdBy.isNotEmpty : tournamentId.isNotEmpty)) {
    _doc.set(toMap()).catchError((_) {});
  }
}

  static Score create(String inningsId,
      {required String tournamentId, 
       required String matchId,
       required String createdBy}) {  // ✅ NEW - REQUIRED
    final s = Score(
      scoreId: const Uuid().v4(),
      inningsId: inningsId,
      totalRuns: 0,
      wickets: 0,
      overs: 0.0,
      currentBall: 0,
      crr: 0.0,
      byes: 0,
      wides: 0,
      noBalls: 0,
      totalExtras: 0,
      currentOver: [],
      strikeBatsmanId: '',
      nonStrikeBatsmanId: '',
      currentBowlerId: '',
      tournamentId: tournamentId,
      matchId: matchId,
      createdBy: createdBy,  // ✅ NEW
    );
    _cache[inningsId] = s;
    s._persistAsync();
    return s;
  }

  static Score? getByInningsId(String inningsId) => _cache[inningsId];

  static void addToCache(Score s) => _cache[s.inningsId] = s;
  static void clearCache() => _cache.clear();

static Future<void> loadFromFirestore(String inningsId,
    {String tournamentId = '', String matchId = '', String createdBy = ''}) async {
  try {
    if (matchId.isEmpty) return;
    if (tournamentId == 'standalone' && createdBy.isEmpty) return;
    if (tournamentId != 'standalone' && tournamentId.isEmpty) return;

    final db = FirebaseFirestore.instance;
    final base = tournamentId == 'standalone'
        ? db.collection('users').doc(createdBy).collection('matches').doc(matchId)
        : db.collection('tournaments').doc(tournamentId).collection('matches').doc(matchId);

    final snap = await base
        .collection('innings')
        .doc(inningsId)
        .collection('scores')
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) { Score.fromMap(snap.docs.first.data()); }
  } catch (_) {}
}
}