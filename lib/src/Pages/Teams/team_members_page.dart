import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/player_storage.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';

class TeamMembersPage extends StatefulWidget {
  final Team team;

  const TeamMembersPage({
    super.key,
    required this.team,
  });

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  int? memberCount;
  List<TextEditingController> playerControllers = [];
  List<FocusNode> focusNodes = [];
  bool isEditingCount = false;

  @override
  void initState() {
    super.initState();
    _checkExistingMembers();
  }

  void _checkExistingMembers() {
    if (widget.team.teamCount > 0) {
      setState(() {
        memberCount = widget.team.teamCount;
        isEditingCount = false;
      });
      _initializePlayerFields(widget.team.teamCount);
      _loadExistingPlayers();
    } else {
      setState(() {
        isEditingCount = true;
      });
    }
  }

  void _initializePlayerFields(int count) {
    playerControllers.clear();
    focusNodes.clear();
    
    for (int i = 0; i < count; i++) {
      playerControllers.add(TextEditingController());
      focusNodes.add(FocusNode());
    }
  }

  void _loadExistingPlayers() {
    try {
      final existingPlayers = PlayerStorage.getPlayersByTeam(widget.team.teamId);
      
      // Load existing players into fields
      for (int i = 0; i < existingPlayers.length && i < playerControllers.length; i++) {
        playerControllers[i].text = existingPlayers[i].teamName;
      }
      
      // If memberCount is MORE than existing players, leave extra fields empty for new players
      // This is already handled by the initialization
    } catch (e) {
      _showSnackBar('Error loading players: $e', Colors.red);
    }
  }

  @override
  void dispose() {
    for (var controller in playerControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showStoredPlayersDialog() {
  final allPlayers = PlayerStorage.getPlayersByTeam(widget.team.teamId);
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1C2026),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stored Players (${allPlayers.length})',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: allPlayers.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No players stored for this team',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: allPlayers.length,
                itemBuilder: (context, index) {
                  final player = allPlayers[index];
                  final bool isValidTeam = player.teamId == widget.team.teamId;
                  
                  return Card(
                    color: const Color(0xFF2A2F3A),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C4FF).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF00C4FF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  player.teamName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (!isValidTeam)
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                            ],
                          ),
                          if (!isValidTeam)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Team ID mismatch! This player belongs to a different team.',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        if (allPlayers.isNotEmpty)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showClearPlayersConfirmation();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

  void _showClearPlayersConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text(
          'Clear All Players?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will delete all stored players for this team. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              PlayerStorage.clearTeamPlayers(widget.team.teamId);
              widget.team.updateCount(0);
              Navigator.pop(context);
              _showSnackBar('All players cleared', Colors.orange);
              setState(() {
                memberCount = null;
                isEditingCount = true;
                playerControllers.clear();
                focusNodes.clear();
              });
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
Future<void> _showMemberCountDialog() async {
  final controller = TextEditingController(
    text: memberCount?.toString() ?? '',
  );
  
  final result = await showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2026),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Team: ${widget.team.teamName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter Member Count',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
             TextField(
  controller: controller,
  autofocus: true,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(2),
  ],
  style: const TextStyle(
    color: Colors.black,
    fontFamily: 'Poppins',
    fontSize: 18,
  ),
  decoration: InputDecoration(
    hintText: '5-11 players',  // Changed from 'e.g., 11'
    hintStyle: const TextStyle(
      color: Color(0xFF9E9E9E),
      fontFamily: 'Poppins',
    ),
                    filled: true,
                    fillColor: const Color(0xFFD9D9D9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF00C4FF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onSubmitted: (value) {
                    final count = int.tryParse(value);
                    if (count != null && count > 0) {
                      Navigator.of(dialogContext).pop(count);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(null),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  Expanded(
  child: ElevatedButton(
    onPressed: () {
      final count = int.tryParse(controller.text);
      if (count == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid number'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (count < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Minimum 2 players required'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (count > 11) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 11 players allowed'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        Navigator.of(dialogContext).pop(count);
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00C4FF),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: const Text(
      'Next',
      style: TextStyle(
        color: Colors.white,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

  if (result != null && result > 0) {
    // ✅ REMOVED: widget.team.updateCount(result);
    // Don't update team count here - only update after players are saved
    setState(() {
      memberCount = result;
      isEditingCount = false;
    });
    _initializePlayerFields(result);
    _loadExistingPlayers();
  }
}
  // ✅ UPDATED: Added unique name validation
  void _savePlayers() {
  if (memberCount == null || memberCount! <= 0) {
    _showSnackBar('Please set member count first', Colors.orange);
    return;
  }

  List<String> playerNames = [];
  
  // First pass: collect all names and check for empty fields
  for (var controller in playerControllers) {
    final name = controller.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please fill all player names', Colors.orange);
      return;
    }
    playerNames.add(name);
  }

  // Check for duplicate names within the form (case-insensitive)
  Set<String> uniqueNames = {};
  for (var name in playerNames) {
    final lowerName = name.toLowerCase();
    if (uniqueNames.contains(lowerName)) {
      _showSnackBar('Duplicate player name found: "$name"', Colors.orange);
      return;
    }
    uniqueNames.add(lowerName);
  }

  try {
    // Get existing players
    final existingPlayers = PlayerStorage.getPlayersByTeam(widget.team.teamId);
    final existingCount = existingPlayers.length;
    
    if (memberCount! > existingCount) {
      // Adding new members - check for duplicates with existing players
      final newMembersToAdd = playerNames.sublist(existingCount);
      
      for (var playerName in newMembersToAdd) {
        bool isDuplicate = false;
        for (var existingPlayer in existingPlayers) {
          if (existingPlayer.teamName.toLowerCase() == playerName.toLowerCase()) {
            isDuplicate = true;
            break;
          }
        }
        
        if (isDuplicate) {
          _showSnackBar('Player name "$playerName" already exists in this team', Colors.orange);
          return;
        }
      }
      
      // All validations passed - add new players
      for (var playerName in newMembersToAdd) {
        PlayerStorage.addPlayer(widget.team.teamId, playerName);
      }
      
      // ✅ UPDATE: Only update team count based on actual saved players
      final actualPlayerCount = PlayerStorage.getTeamPlayerCount(widget.team.teamId);
      widget.team.updateCount(actualPlayerCount);
      
      _showSnackBar(
        '${newMembersToAdd.length} new player${newMembersToAdd.length > 1 ? 's' : ''} added to ${widget.team.teamName}',
        Colors.green,
      );
    } else if (memberCount! < existingCount) {
      _showSnackBar(
        'Cannot reduce member count. Use "Clear All" to remove players if needed.',
        Colors.orange,
      );
      return;
    } else {
      // Same count - update existing player names if changed
      bool hasChanges = false;
      
      for (int i = 0; i < playerNames.length && i < existingPlayers.length; i++) {
        if (existingPlayers[i].teamName != playerNames[i]) {
          bool isDuplicate = false;
          for (int j = 0; j < existingPlayers.length; j++) {
            if (i != j && existingPlayers[j].teamName.toLowerCase() == playerNames[i].toLowerCase()) {
              isDuplicate = true;
              break;
            }
          }
          
          if (isDuplicate) {
            _showSnackBar('Player name "${playerNames[i]}" already exists in this team', Colors.orange);
            return;
          }
          
          existingPlayers[i].teamName = playerNames[i];
          PlayerStorage.updatePlayer(existingPlayers[i]);
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        _showSnackBar('Player names updated', Colors.green);
      } else {
        _showSnackBar('No changes made', Colors.blue);
      }
    }
    
    Navigator.pop(context, true);
  } catch (e) {
    _showSnackBar('Error saving players: $e', Colors.red);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF283593), Color(0xFF1A237E), Color(0xFF000000)],
            stops: [0.0, 0.0, 0.2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: isEditingCount
                    ? _buildSetMemberCountView()
                    : _buildPlayersList(),
              ),
              if (!isEditingCount) _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.team.teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (memberCount != null)
                  Text(
                    'Manage $memberCount Players',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.storage, color: Color(0xFF00C4FF)),
            onPressed: _showStoredPlayersDialog,
            tooltip: 'View stored players',
          ),
          if (memberCount != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF00C4FF)),
              onPressed: _showMemberCountDialog,
              tooltip: 'Edit member count',
            ),
        ],
      ),
    );
  }

  Widget _buildSetMemberCountView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Set Member Count',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 22,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please set the number of players\nfor ${widget.team.teamName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _showMemberCountDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C4FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Set Member Count',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersList() {
    if (memberCount == null || memberCount! <= 0) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: memberCount!,
      itemBuilder: (context, index) {
        return _buildPlayerField(index);
      },
    );
  }

 Widget _buildPlayerField(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00C4FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00C4FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF00C4FF),
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: playerControllers[index],
              focusNode: focusNodes[index],
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
           decoration: InputDecoration(
  hintText: 'Enter the player name',  // Changed from '2-11 players'
  hintStyle: const TextStyle(
    color: Color(0xFF9E9E9E),
    fontFamily: 'Poppins',
  ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: (_) {
                if (index < focusNodes.length - 1) {
                  focusNodes[index + 1].requestFocus();
                } else {
                  _savePlayers();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _savePlayers,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C4FF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 0),
        ),
        child: const Text(
          'Save Players',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}