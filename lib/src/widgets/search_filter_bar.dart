import 'package:flutter/material.dart';
import '../theme/tournament_colors.dart';

/// Search input + status filter chips for the tournament list.
/// Purely a UI/discovery aid — filtering happens client-side over the
/// already-loaded tournament stream and never touches business logic.
class SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  static const List<String> filters = ['All', 'Live', 'Upcoming', 'Completed'];

  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: TournamentColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(
                color: TournamentColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search tournaments, city, ground...',
              hintStyle: const TextStyle(
                  color: TournamentColors.textSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: TournamentColors.primaryAccent, size: 20),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: TournamentColors.textSecondary, size: 18),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final label = filters[i];
              final selected = label == selectedFilter;
              return GestureDetector(
                onTap: () => onFilterSelected(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected ? TournamentColors.accentGradient : null,
                    color: selected ? null : TournamentColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          selected ? Colors.white : TournamentColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}