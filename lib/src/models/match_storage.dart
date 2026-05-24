// match_storage.dart
// Static helper called by InitialTeamPage and playerselection_page as:
//   MatchStorage.createMatch(...)
//   MatchStorage.getByMatchId(id)
//   MatchStorage.getAllMatches()
//
// Delegates entirely to the Match in-memory cache.

import 'package:TURF_TOWN_/src/models/match.dart';

class MatchStorage {
  MatchStorage._();

  static Match createMatch({
    required String teamId1,
    required String teamId2,
    required int overs,
    bool isNoballAllowed = true,
    bool isWideAllowed = true,
    DateTime? matchDate,
  }) =>
      Match.create(
        teamId1: teamId1,
        teamId2: teamId2,
        overs: overs,
        isNoballAllowed: isNoballAllowed,
        isWideAllowed: isWideAllowed,
        matchDate: matchDate,
      );

  static Match? getByMatchId(String matchId) => Match.getByMatchId(matchId);

  static List<Match> getAllMatches() => Match.getAll();
}