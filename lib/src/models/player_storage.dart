// player_storage.dart
// Static helper that InitialTeamPage and playerselection_page call as:
//   PlayerStorage.getPlayersByTeam(teamId)
//   PlayerStorage.getTeamPlayerCount(teamId)
//   PlayerStorage.addPlayer(teamId, playerName)
//
// Delegates entirely to the TeamMember in-memory cache.

import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/models/team.dart';

class PlayerStorage {
  PlayerStorage._();

  /// Returns all players belonging to [teamId].
  static List<TeamMember> getPlayersByTeam(String teamId) =>
      TeamMember.getByTeamId(teamId);

  /// Returns the number of players in [teamId].
  static int getTeamPlayerCount(String teamId) =>
      TeamMember.getByTeamId(teamId).length;

  /// Creates a player in [teamId] and updates the team's count.
  static TeamMember addPlayer(String teamId, String playerName,
      {String role = ''}) {
    final member = TeamMember.create(
      teamId: teamId,
      playerName: playerName,
      role: role,
    );
    // Keep the Team.teamCount in sync
    final team = Team.getById(teamId);
    if (team != null) {
      team.updateCountSync(TeamMember.getByTeamId(teamId).length);
    }
    return member;
  }

  /// Removes a player from the cache (and fires a Firestore delete).
  static void removePlayer(String playerId) {
    final member = TeamMember.getByPlayerId(playerId);
    if (member == null) return;
    TeamMember.removeFromCache(playerId);
    // Update team count
    final team = Team.getById(member.teamId);
    if (team != null) {
      team.updateCountSync(TeamMember.getByTeamId(member.teamId).length);
    }
  }
}