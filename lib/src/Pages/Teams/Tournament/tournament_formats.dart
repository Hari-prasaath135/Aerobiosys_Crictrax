import 'package:flutter/material.dart';

class TournamentFormat {
  final String id;
  final String label;
  final String tagline;
  final String description;
  final String group;
  final IconData icon;

  const TournamentFormat({
    required this.id,
    required this.label,
    required this.tagline,
    required this.description,
    required this.group,
    required this.icon,
  });
}

const List<TournamentFormat> kFormats = [
  TournamentFormat(
    id: 'league',
    label: 'League / Round Robin',
    tagline: 'IPL group stage style',
    description:
        'Every team plays every other team exactly once. '
        'The most fair format — everyone gets equal game time — '
        'but requires more matches as the team count grows.',
    group: 'Quick',
    icon: Icons.loop,
  ),
  TournamentFormat(
    id: 'single_elimination',
    label: 'Single Elimination',
    tagline: 'World Cup knockout style',
    description:
        'Lose once and you\'re out. Bracket advances winner to the '
        'next round. Fast, dramatic, and perfect for large fields '
        'where you need a winner quickly.',
    group: 'Quick',
    icon: Icons.account_tree_outlined,
  ),
  TournamentFormat(
    id: 'ipl_full_league',
    label: 'IPL Full League',
    tagline: 'IPL full season format',
    description:
        'All teams play each other in a round-robin, then the '
        'top teams advance to semi-finals and a final. '
        'Balances fairness with exciting knockout drama.',
    group: 'Quick',
    icon: Icons.emoji_events_outlined,
  ),
  TournamentFormat(
    id: 'double_elimination',
    label: 'Double Elimination',
    tagline: 'Second-chance knockout',
    description:
        'You get one lifeline after a loss. Teams move between '
        'a Winners Bracket and a Losers Bracket. Popular in esports '
        'and competitive circuits where one bad day shouldn\'t '
        'end a team\'s tournament.',
    group: 'Advanced',
    icon: Icons.low_priority,
  ),
  TournamentFormat(
    id: 'fifa_world_cup',
    label: 'Group Stage + Knockout',
    tagline: 'FIFA World Cup format',
    description:
        'Teams are split into groups for mini round-robins. '
        'Top finishers from each group advance to a knockout bracket. '
        'The gold standard for large tournaments with 8+ teams.',
    group: 'Advanced',
    icon: Icons.public,
  ),
];