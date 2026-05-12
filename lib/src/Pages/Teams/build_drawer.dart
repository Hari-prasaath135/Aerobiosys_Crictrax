const Divider(color: Colors.white24, height: 1),

ListTile(
  leading: const Icon(Icons.emoji_events, color: Colors.white),
  title: const Text(
    'Tournaments',
    style: TextStyle(color: Colors.white),
  ),
  subtitle: Text(
    'Create & manage tournaments',
    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
  ),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TournamentPage(),
      ),
    );
  },
),