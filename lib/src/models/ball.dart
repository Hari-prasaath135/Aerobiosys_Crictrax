import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single ball event, written once per delivery to
/// tournaments/{tournamentId}/matches/{matchId}/innings/{inningsId}/balls/{ballId}
///
/// Unlike Batsman/Bowler, this is write-once (no in-memory cache, no mutation
/// methods) — it exists purely to feed the TV app's ball-by-ball tracker
/// (_BallByBallTracker / watchCurrentOverBalls in LiveScoreRepository).
class Ball {
  final String ballId;
  final String inningsId;
  final int overNumber;   // 0-indexed, matches LiveScoreRepository's query
  final int ballInOver;   // 0-indexed within the over (0..5 for legal balls)
  final int runs;         // runs off the bat (or byes/leg-byes value)
  final bool isWicket;
  final bool isWide;
  final bool isNoBall;
  final bool isBye;
  final bool isLegBye;
  final String display;   // e.g. '4', 'W', 'WD', 'NB2', '2RO' — same string
                           // already built in CricketScorerScreen's ballDisplay

  const Ball({
    required this.ballId,
    required this.inningsId,
    required this.overNumber,
    required this.ballInOver,
    required this.runs,
    required this.display,
    this.isWicket = false,
    this.isWide = false,
    this.isNoBall = false,
    this.isBye = false,
    this.isLegBye = false,
  });

  static CollectionReference<Map<String, dynamic>> col(
    String tournamentId,
    String matchId,
    String inningsId,
  ) {
    return FirebaseFirestore.instance
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .doc(matchId)
        .collection('innings')
        .doc(inningsId)
        .collection('balls');
  }

  Map<String, dynamic> toMap() => {
        'ballId': ballId,
        'inningsId': inningsId,
        'overNumber': overNumber,
        'ballInOver': ballInOver,
        'runs': runs,
        'isWicket': isWicket,
        'isWide': isWide,
        'isNoBall': isNoBall,
        'isBye': isBye,
        'isLegBye': isLegBye,
        'display': display,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Ball.fromMap(Map<String, dynamic> map) => Ball(
        ballId: map['ballId'] as String? ?? '',
        inningsId: map['inningsId'] as String? ?? '',
        overNumber: (map['overNumber'] as num?)?.toInt() ?? 0,
        ballInOver: (map['ballInOver'] as num?)?.toInt() ?? 0,
        runs: (map['runs'] as num?)?.toInt() ?? 0,
        isWicket: map['isWicket'] as bool? ?? false,
        isWide: map['isWide'] as bool? ?? false,
        isNoBall: map['isNoBall'] as bool? ?? false,
        isBye: map['isBye'] as bool? ?? false,
        isLegBye: map['isLegBye'] as bool? ?? false,
        display: map['display'] as String? ?? '',
      );
}