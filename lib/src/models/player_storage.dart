import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/models/objectbox_helper.dart';

/// Helper class for managing player storage operations using ObjectBox
class PlayerStorage {
  /// Add a player to a team
  static TeamMember addPlayer(String teamId, String playerName) {
    return TeamMember.create(
      teamId: teamId,
      teamName: playerName,
    );
  }
  // Add this method to your PlayerStorage class
static bool isPlayerNameUnique(String teamId, String playerName, {String? excludePlayerId}) {
  final existingPlayers = getPlayersByTeam(teamId);
  
  for (final player in existingPlayers) {
    // Skip the current player when updating
    if (excludePlayerId != null && player.playerId == excludePlayerId) {
      continue;
    }
    
    // Case-insensitive comparison
    if (player.teamName.toLowerCase() == playerName.trim().toLowerCase()) {
      return false;
    }
  }
  
  return true;
}

  /// Get all players for a specific team
  static List<TeamMember> getPlayersByTeam(String teamId) {
    return TeamMember.getByTeamId(teamId);
  }

  /// Get a specific player by playerId
  static TeamMember? getPlayer(String playerId) {
    return TeamMember.getByPlayerId(playerId);
  }

  /// Update a player's name
  static void updatePlayerName(String playerId, String newName) {
    final player = TeamMember.getByPlayerId(playerId);
    if (player != null) {
      player.updateName(newName);
    }
  }

  /// Update a player object directly (for updating the TeamMember entity)
  static void updatePlayer(TeamMember player) {
    ObjectBoxHelper.teamMemberBox.put(player);
  }

  /// Delete a specific player
  static void deletePlayer(String playerId) {
    TeamMember.deleteByPlayerId(playerId);
  }

  /// Delete all players from a team
  static void clearTeamPlayers(String teamId) {
    TeamMember.deleteByTeamId(teamId);
  }

  /// Get count of players in a team
  static int getTeamPlayerCount(String teamId) {
    return TeamMember.getTeamMemberCount(teamId);
  }

  /// Get all players across all teams
  static List<TeamMember> getAllPlayers() {
    return TeamMember.getAll();
  }

  /// Search players by name
  static List<TeamMember> searchPlayersByName(String name) {
    return TeamMember.getByName(name);
  }

  /// Check if a player exists in a team
  static bool playerExistsInTeam(String teamId, String playerId) {
    final player = TeamMember.getByTeamAndPlayerId(teamId, playerId);
    return player != null;
  }

  /// Transfer a player to another team
  static void transferPlayer(String playerId, String newTeamId) {
    final player = TeamMember.getByPlayerId(playerId);
    if (player != null) {
      player.updateTeam(newTeamId);
    }
  }

  /// Get player details
  static Map<String, dynamic>? getPlayerDetails(String playerId) {
    final player = TeamMember.getByPlayerId(playerId);
    if (player == null) return null;

    return {
      'playerId': player.playerId,
      'teamId': player.teamId,
      'playerName': player.teamName,
      'dbId': player.id,
    };
  }

  /// Batch add players to a team
  static List<TeamMember> batchAddPlayers(String teamId, List<String> playerNames) {
    List<TeamMember> addedPlayers = [];
    
    for (var name in playerNames) {
      try {
        final player = addPlayer(teamId, name);
        addedPlayers.add(player);
      } catch (e) {
        // Log error but continue with other players
        print('Error adding player $name: $e');
      }
    }
    
    return addedPlayers;
  }

  /// Update all players in a team (clears and recreates)
  static void updateTeamPlayers(String teamId, List<String> playerNames) {
    clearTeamPlayers(teamId);
    batchAddPlayers(teamId, playerNames);
  }

  /// Remove a specific player from a team by player name
  static void removePlayerByName(String teamId, String playerName) {
    final players = getPlayersByTeam(teamId);
    for (var player in players) {
      if (player.teamName == playerName) {
        player.delete();
        break;
      }
    }
  }

  /// Update player name in a team
  static void updatePlayerInTeam(String teamId, String oldName, String newName) {
    final players = getPlayersByTeam(teamId);
    for (var player in players) {
      if (player.teamName == oldName) {
        player.updateName(newName);
        break;
      }
    }
  }

  /// Get player names as a list of strings
  static List<String> getPlayerNames(String teamId) {
    final players = getPlayersByTeam(teamId);
    return players.map((p) => p.teamName).toList();
  }

  /// Check if a player name exists in a team
  static bool playerNameExistsInTeam(String teamId, String playerName) {
    final players = getPlayersByTeam(teamId);
    return players.any((p) => p.teamName.toLowerCase() == playerName.toLowerCase());
  }
}