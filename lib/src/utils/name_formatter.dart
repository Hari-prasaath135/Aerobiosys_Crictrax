/// Formats a team name:
/// - Single word, 3 letters or fewer, all alphabetic → treated as an
///   abbreviation (CSK, GT, MI, DC) and kept fully UPPERCASE.
/// - Single word, longer than 3 letters → Title Case.
/// - Multiple words → Title Case each word.
String formatTeamName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return trimmed;

  final words = trimmed.split(RegExp(r'\s+'));

  if (words.length == 1) {
    final word = words.first;
    final isAbbreviation =
        word.length <= 3 && RegExp(r'^[A-Za-z]+$').hasMatch(word);
    if (isAbbreviation) return word.toUpperCase();
    return _capitalize(word);
  }

  return words.map(_capitalize).join(' ');
}

/// Formats a player name: always Title Case, word by word.
String formatPlayerName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed.split(RegExp(r'\s+')).map(_capitalize).join(' ');
}

String _capitalize(String word) {
  if (word.isEmpty) return word;
  return word[0].toUpperCase() + word.substring(1).toLowerCase();
}