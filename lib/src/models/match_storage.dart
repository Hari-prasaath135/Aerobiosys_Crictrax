import 'package:TURF_TOWN_/src/models/match.dart';

class MatchStorage {
  MatchStorage._();

  /// Creates a match and stores it in the local cache.
  ///
  /// Accepts ALL parameters used by both call-sites:
  ///   • InitialTeamPage  → tossWonBy + chooseToBat + allowNoball + allowWide
  ///   • TeamPage (via FirestoreService.createMatch) → tossWonBy + batBowlFlag
  static Match createMatch({
    required String teamId1,
    required String teamId2,
    required int overs,

    // ── Toss (at least one of the two styles must be provided) ─────────────
    String tossWonBy = '',
    bool chooseToBat = true,   // InitialTeamPage style
    int? batBowlFlag,           // TeamPage/FirestoreService style (1=bat,2=bowl)

    // ── Extras ──────────────────────────────────────────────────────────────
    bool allowNoball = true,
    bool allowWide = true,
    bool isNoballAllowed = true, // alias kept for compatibility
    bool isWideAllowed = true,   // alias kept for compatibility

    DateTime? matchDate,

    // ── TeamPage extended fields (stored on Match for reference) ─────────────
    String teamId1Name = '',
    String teamId1OwnerUid = '',
    String teamId2Name = '',
    String teamId2OwnerUid = '',
    int noballFlag = 1,
    int wideFlag = 1,
    String? tournamentId,
  }) {
    // Resolve batBowlFlag: explicit value wins; otherwise derive from chooseToBat.
    final resolvedBatBowlFlag = batBowlFlag ?? (chooseToBat ? 1 : 2);

    // Resolve noball/wide from either parameter style.
    final resolvedNoball = allowNoball && isNoballAllowed;
    final resolvedWide = allowWide && isWideAllowed;

    return Match.create(
      teamId1: teamId1,
      teamId2: teamId2,
      overs: overs,
      tossWonBy: tossWonBy,
      batBowlFlag: resolvedBatBowlFlag,
      isNoballAllowed: resolvedNoball,
      isWideAllowed: resolvedWide,
      matchDate: matchDate,
      tournamentId: tournamentId ?? '', // ← was missing
    );
  }

  static Match? getByMatchId(String matchId) => Match.getByMatchId(matchId);

  static List<Match> getAllMatches() => Match.getAll();
}