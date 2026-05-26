import 'package:TURF_TOWN_/src/models/match.dart';

class MatchStorage {
  MatchStorage._();

  static Match createMatch({
    required String teamId1,
    required String teamId2,
    required int overs,
    required String createdBy,

    String tossWonBy = '',
    bool chooseToBat = true,
    int? batBowlFlag,

    bool allowNoball = true,
    bool allowWide = true,
    bool isNoballAllowed = true,
    bool isWideAllowed = true,

    DateTime? matchDate,

    String teamId1Name = '',
    String teamId1OwnerUid = '',
    String teamId2Name = '',
    String teamId2OwnerUid = '',
    int noballFlag = 1,
    int wideFlag = 1,

    // ✅ FIXED: defaults to 'standalone' instead of '' so path
    // resolution in Match._doc correctly routes to
    // users/{createdBy}/matches/{matchId}
    String? tournamentId,
  }) {
    // ✅ Resolve tournamentId — never allow empty string
    // Empty / null both mean standalone match
    final resolvedTournamentId =
        (tournamentId == null || tournamentId.trim().isEmpty)
            ? 'standalone'
            : tournamentId.trim();

    final resolvedBatBowlFlag = batBowlFlag ?? (chooseToBat ? 1 : 2);

    // ✅ Both allowNoball + isNoballAllowed must be true
    final resolvedNoball = allowNoball && isNoballAllowed;
    final resolvedWide = allowWide && isWideAllowed;

    // ✅ createdBy must never be empty — guard before reaching Firestore
    assert(createdBy.isNotEmpty, 'createdBy (uid) must not be empty');

    return Match.create(
      teamId1: teamId1,
      teamId2: teamId2,
      overs: overs,
      tossWonBy: tossWonBy,
      batBowlFlag: resolvedBatBowlFlag,
      isNoballAllowed: resolvedNoball,
      isWideAllowed: resolvedWide,
      matchDate: matchDate,
      tournamentId: resolvedTournamentId, // ✅ Always 'standalone' or a real ID
      createdBy: createdBy,
    );
  }

  static Match? getByMatchId(String matchId) => Match.getByMatchId(matchId);

  static List<Match> getAllMatches() => Match.getAll();
}