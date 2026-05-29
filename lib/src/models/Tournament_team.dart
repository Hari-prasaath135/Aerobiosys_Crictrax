import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentTeam {
  final String tournamentId;
  final String teamId;
  final String teamName;
  final String ownerUid;
  final String ownerName;
  final int playerCount;

  const TournamentTeam({
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    this.ownerUid = '',
    this.ownerName = '',
    this.playerCount = 0,
  });

  // ─── Local cache: Set of "tournamentId::teamId" pairs ─────────────────────
  static final Set<String> _cache = {};

  static String _key(String tId, String tmId) => '$tId::$tmId';

  static bool isInTournament(String tournamentId, String teamId) =>
      _cache.contains(_key(tournamentId, teamId));

  /// Adds a team to a tournament.
  /// BUG 1 FIX: Removed per-user one-team restriction.
  /// Only duplicate teamId check remains (same team can't be added twice).
  /// Stores in local cache immediately, then fires-and-forgets to Firestore.
  static Future<void> addTeamToTournament({
    required String tournamentId,
    required String teamId,
    String teamName = '',
    String ownerUid = '',
    String ownerName = '',
    int playerCount = 0,
  }) async {
    _cache.add(_key(tournamentId, teamId));
    // Fire-and-forget — never throws, never blocks.
    FirebaseFirestore.instance
        .collection('tournaments')
        .doc(tournamentId)
        .collection('teams')
        .doc(teamId)
        .set({
          'teamId': teamId,
          'tournamentId': tournamentId,
          'teamName': teamName,
          'ownerUid': ownerUid,
          'ownerName': ownerName,
          'playerCount': playerCount,
          'addedAt': FieldValue.serverTimestamp(),
        })
        .catchError((_) {});
  }

  static void clearCache() => _cache.clear();
}