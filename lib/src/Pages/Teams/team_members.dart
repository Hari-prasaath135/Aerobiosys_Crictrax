import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/team_storage.dart';

class TeamMembersScreen extends StatefulWidget {
  final String teamName;

  const TeamMembersScreen({super.key, required this.teamName});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  Team? team; // Changed from List<String> players to Team? team
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam(); // Changed from _loadPlayers to _loadTeam
  }

  Future<void> _loadTeam() async { // Changed method name
    setState(() => isLoading = true);
    final loadedTeam = await TeamStorage.getTeamByName(widget.teamName);
    if (mounted && loadedTeam != null) {
      setState(() {
        team = loadedTeam;
        isLoading = false;
      });
    } else if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _showAddPlayerModal() {
    final TextEditingController playerNameController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3E),
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
                  'Add Player',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.065,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: playerNameController,
                  autofocus: false,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Player Name',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontFamily: 'Poppins',
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF5C5C5E),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF2B7790),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      String playerName = playerNameController.text.trim();
                      
                      if (playerName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a player name!'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      // Check for duplicate
                      if (team != null && team!.players.contains(playerName)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Player already exists in this team!'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      Navigator.of(dialogContext).pop();
                      
                      // Add player to storage
                      await TeamStorage.addPlayerToTeam(widget.teamName, playerName);
                      
                      // Reload team
                      await _loadTeam();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$playerName added successfully!'),
                            backgroundColor: const Color(0xFF2B7790),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        playerNameController.dispose();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B7790),
                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width * 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editPlayer(int index) {
    if (team == null) return;
    
    final TextEditingController editController = TextEditingController(text: team!.players[index]);
    final String oldPlayerName = team!.players[index];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Player',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.065,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: editController,
                  autofocus: false,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Player Name',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'Poppins',
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF5C5C5E),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF2B7790),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      String newPlayerName = editController.text.trim();
                      
                      if (newPlayerName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a player name!'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      // Check for duplicate (excluding current player)
                      if (team != null && team!.players.contains(newPlayerName) && newPlayerName != oldPlayerName) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Player name already exists!'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      Navigator.of(dialogContext).pop();
                      
                      // Update player in storage
                      await TeamStorage.updatePlayerInTeam(widget.teamName, oldPlayerName, newPlayerName);
                      
                      // Reload team
                      await _loadTeam();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Player updated successfully!'),
                            backgroundColor: Color(0xFF2B7790),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        editController.dispose();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B7790),
                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width * 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deletePlayer(int index) {
    if (team == null) return;
    
    final playerToDelete = team!.players[index];
    final isCaptain = team!.captain == playerToDelete;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3C3C3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Player',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$playerToDelete"?${isCaptain ? ' (Captain)' : ''}',
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                final updatedPlayers = List<String>.from(team!.players)..removeAt(index);
                final updatedTeam = Team(
                  name: team!.name,
                  players: updatedPlayers,
                  captain: isCaptain ? null : team!.captain,
                );
                
                await TeamStorage.updateTeam(widget.teamName, updatedTeam);
                await _loadTeam();
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140088),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140088),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.teamName,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF140088), Colors.black],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2B7790),
                  ),
                )
              : team == null
                  ? const Center(
                      child: Text(
                        'Team not found',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;

                        return Column(
                          children: [
                            Expanded(
                              child: team!.players.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 100),
                                        child: Text(
                                          'No players added yet.\nTap + to add a player.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: w * 0.045,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: w * 0.04,
                                        vertical: w * 0.02,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Players (${team!.players.length})',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: w * 0.06,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: w * 0.04),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: team!.players.length,
                                              itemBuilder: (context, index) {
                                                final player = team!.players[index];
                                                final isCaptain = team!.captain == player;
                                                
                                                return Container(
                                                  key: ValueKey('player_$index'),
                                                  margin: EdgeInsets.only(bottom: w * 0.04),
                                                  padding: EdgeInsets.all(w * 0.045),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        const Color(0xFF2B7790).withOpacity(0.3),
                                                        const Color(0xFF1E1E1E).withOpacity(0.8),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: isCaptain 
                                                          ? const Color(0xFFFFD700).withOpacity(0.6) 
                                                          : const Color(0xFF2B7790).withOpacity(0.5),
                                                      width: isCaptain ? 2 : 1.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: isCaptain 
                                                            ? const Color(0xFFFFD700).withOpacity(0.3)
                                                            : const Color(0xFF2B7790).withOpacity(0.2),
                                                        blurRadius: 15,
                                                        offset: const Offset(0, 5),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.all(w * 0.025),
                                                        decoration: BoxDecoration(
                                                          color: isCaptain ? const Color(0xFFFFD700) : const Color(0xFF2B7790),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Icon(
                                                          isCaptain ? Icons.star : Icons.person,
                                                          color: isCaptain ? Colors.black : Colors.white,
                                                          size: w * 0.06,
                                                        ),
                                                      ),
                                                      SizedBox(width: w * 0.03),
                                                      
                                                      Expanded(
                                                        child: Text(
                                                          isCaptain ? '$player (C)' : player,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: w * 0.045,
                                                            fontFamily: 'Poppins',
                                                            fontWeight: isCaptain ? FontWeight.w700 : FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      
                                                      // Captain Icon
                                                      GestureDetector(
                                                        onTap: () async {
                                                          final newCaptain = isCaptain ? null : player;
                                                          await TeamStorage.updateTeamCaptain(widget.teamName, newCaptain);
                                                          await _loadTeam();
                                                          
                                                          if (mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  isCaptain 
                                                                      ? 'Captain removed' 
                                                                      : '$player is now the captain!',
                                                                ),
                                                                backgroundColor: isCaptain ? Colors.orange : Colors.green,
                                                                duration: const Duration(seconds: 2),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Container(
                                                          padding: EdgeInsets.all(w * 0.02),
                                                          child: Icon(
                                                            isCaptain ? Icons.star : Icons.star_border,
                                                            color: isCaptain ? const Color(0xFFFFD700) : const Color(0xFF2B7790),
                                                            size: w * 0.055,
                                                          ),
                                                        ),
                                                      ),
                                                      
                                                      SizedBox(width: w * 0.02),
                                                      
                                                      // Edit Icon
                                                      GestureDetector(
                                                        onTap: () => _editPlayer(index),
                                                        child: Container(
                                                          padding: EdgeInsets.all(w * 0.02),
                                                          child: Icon(
                                                            Icons.edit_outlined,
                                                            color: const Color(0xFF2B7790),
                                                            size: w * 0.055,
                                                          ),
                                                        ),
                                                      ),
                                                      
                                                      SizedBox(width: w * 0.02),
                                                      
                                                      // Delete Icon
                                                      GestureDetector(
                                                        onTap: () => _deletePlayer(index),
                                                        child: Container(
                                                          padding: EdgeInsets.all(w * 0.02),
                                                          child: Icon(
                                                            Icons.delete_outline,
                                                            color: Colors.red,
                                                            size: w * 0.055,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlayerModal,
        backgroundColor: const Color(0xFF2B7790),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}