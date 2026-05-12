import 'package:TURF_TOWN_/src/models/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'objectbox_helper.dart';

@Entity()
class TeamMember {
  @Id()
  int id; // Auto-incremented by ObjectBox
  
  @Unique()
  String playerId; // Primary key (p_01, p_02, etc.)
  
  String teamId; // Foreign key to Team
  
  String teamName; // Name of the player
  
  TeamMember({
    this.id = 0,
    required this.playerId,
    required this.teamId,
    required this.teamName,
  });

  // Static methods for database operations
  
  /// Creates a new team member with auto-generated playerId
  static TeamMember create({
    required String teamId,
    required String teamName,
  }) {
    final trimmedName = teamName.trim();
    
    // Validate player name
    if (trimmedName.isEmpty) {
      throw Exception('Player name cannot be empty');
    }
    
    if (trimmedName.length < 2) {
      throw Exception('Player name must be at least 2 characters');
    }
    
    if (trimmedName.length > 30) {
      throw Exception('Player name must be less than 30 characters');
    }
    
    // ✅ Check for duplicate name within the same team
    if (_isNameDuplicateInTeam(teamId, trimmedName)) {
      throw Exception('Player name "$trimmedName" already exists in this team');
    }
    
    // Generate next playerId
    final playerId = _generateNextPlayerId();
    
    final member = TeamMember(
      playerId: playerId,
      teamId: teamId,
      teamName: trimmedName,
    );
    
    ObjectBoxHelper.teamMemberBox.put(member);
    return member;
  }
  
  /// ✅ Check if a player name already exists in a specific team
  static bool _isNameDuplicateInTeam(String teamId, String playerName, {String? excludePlayerId}) {
    final query = ObjectBoxHelper.teamMemberBox
        .query(TeamMember_.teamId.equals(teamId))
        .build();
    final members = query.find();
    query.close();
    
    for (final member in members) {
      // Skip the current player when updating (if excludePlayerId is provided)
      if (excludePlayerId != null && member.playerId == excludePlayerId) {
        continue;
      }
      
      // Case-insensitive comparison
      if (member.teamName.toLowerCase() == playerName.toLowerCase()) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Generates the next sequential player ID (p_01, p_02, etc.)
  static String _generateNextPlayerId() {
    final allMembers = ObjectBoxHelper.teamMemberBox.getAll();
    
    if (allMembers.isEmpty) {
      return 'p_01';
    }
    
    // Extract numeric parts and find the maximum
    int maxNum = 0;
    for (final member in allMembers) {
      final numStr = member.playerId.replaceAll('p_', '');
      final num = int.tryParse(numStr) ?? 0;
      if (num > maxNum) {
        maxNum = num;
      }
    }
    
    // Increment and format with leading zeros
    final nextNum = maxNum + 1;
    return 'p_${nextNum.toString().padLeft(2, '0')}';
  }
  
  /// Get all team members
  static List<TeamMember> getAll() {
    return ObjectBoxHelper.teamMemberBox.getAll();
  }
  
  /// Get all members of a specific team
  static List<TeamMember> getByTeamId(String teamId) {
    final query = ObjectBoxHelper.teamMemberBox
        .query(TeamMember_.teamId.equals(teamId))
        .build();
    final members = query.find();
    query.close();
    return members;
  }
  
  /// Get a specific player by playerId
  static TeamMember? getByPlayerId(String playerId) {
    final query = ObjectBoxHelper.teamMemberBox
        .query(TeamMember_.playerId.equals(playerId))
        .build();
    final member = query.findFirst();
    query.close();
    return member;
  }
  
  /// Get a specific player by teamId and playerId
  static TeamMember? getByTeamAndPlayerId(String teamId, String playerId) {
    final query = ObjectBoxHelper.teamMemberBox
        .query(
          TeamMember_.teamId.equals(teamId) & 
          TeamMember_.playerId.equals(playerId)
        )
        .build();
    final member = query.findFirst();
    query.close();
    return member;
  }
  
  /// Get members by player name (case-insensitive search)
  static List<TeamMember> getByName(String name) {
    final query = ObjectBoxHelper.teamMemberBox
        .query(TeamMember_.teamName.contains(name, caseSensitive: false))
        .build();
    final members = query.find();
    query.close();
    return members;
  }
  
  /// Delete a team member by playerId
  static void deleteByPlayerId(String playerId) {
    final member = getByPlayerId(playerId);
    if (member != null) {
      ObjectBoxHelper.teamMemberBox.remove(member.id);
    }
  }
  
  /// Delete all members of a specific team
  static void deleteByTeamId(String teamId) {
    final members = getByTeamId(teamId);
    for (final member in members) {
      ObjectBoxHelper.teamMemberBox.remove(member.id);
    }
  }
  
  /// Get count of members in a team
  static int getTeamMemberCount(String teamId) {
    final query = ObjectBoxHelper.teamMemberBox
        .query(TeamMember_.teamId.equals(teamId))
        .build();
    final count = query.count();
    query.close();
    return count;
  }
  
  // Instance methods
  
  /// Save the current team member
  void save() {
    ObjectBoxHelper.teamMemberBox.put(this);
  }
  
  /// Delete the current team member
  void delete() {
    ObjectBoxHelper.teamMemberBox.remove(id);
  }
  
  /// ✅ Update player name with duplicate check
  void updateName(String newName) {
    final trimmedName = newName.trim();
    
    if (trimmedName.isEmpty) {
      throw Exception('Player name cannot be empty');
    }
    
    // Check for duplicates within the same team (excluding current player)
    if (_isNameDuplicateInTeam(teamId, trimmedName, excludePlayerId: playerId)) {
      throw Exception('Player name "$trimmedName" already exists in this team');
    }
    
    teamName = trimmedName;
    save();
  }
  
  /// Update team association
  void updateTeam(String newTeamId) {
    teamId = newTeamId;
    save();
  }
  
  @override
  String toString() {
    return 'TeamMember(id: $id, playerId: $playerId, teamId: $teamId, name: $teamName)';
  }
}