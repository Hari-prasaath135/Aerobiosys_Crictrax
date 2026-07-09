import 'dart:io';
import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';
import '../theme/tournament_colors.dart';
import 'tournament_status_badge.dart';

/// Modern tournament list card: logo, name, status, location, dates,
/// organizer, and an owner-only quick actions menu — with a soft
/// entrance animation and a subtle stadium-style accent overlay.
class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final String status;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Used only to stagger the entrance animation across list items.
  final int index;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.status,
    required this.formatDate,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.index = 0,
  });

  bool get _isLive => status == 'Live';

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final isOwner = t.isOwnedByCurrentUser;
    final accent =
        _isLive ? TournamentColors.success : TournamentColors.primaryAccent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 40).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            gradient: TournamentColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isLive
                  ? TournamentColors.success.withOpacity(0.35)
                  : Colors.white.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Subtle stadium-light style radial accent overlay.
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [accent.withOpacity(0.10), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Logo(tournament: t),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: TournamentColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        color: TournamentColors.textSecondary,
                                        size: 13),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        '${t.city} • ${t.ground}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color:
                                              TournamentColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TournamentStatusBadge(status: status),
                              if (isOwner) ...[
                                const SizedBox(height: 2),
                                _OwnerMenu(onEdit: onEdit, onDelete: onDelete),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, color: TournamentColors.divider),
                      const SizedBox(height: 12),
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label:
                            '${formatDate(t.startDate)}  →  ${formatDate(t.endDate)}',
                      ),
                      const SizedBox(height: 8),
                      _InfoChip(
                        icon: Icons.person_rounded,
                        label: '${t.organizerName}  •  ${t.organizerPhone}',
                      ),
                      if (t.maxTeams > 0) ...[
                        const SizedBox(height: 8),
                        _InfoChip(
                          icon: Icons.groups_rounded,
                          label: 'Max ${t.maxTeams} teams',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final Tournament tournament;
  const _Logo({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final hasLogo =
        tournament.logoPath != null && tournament.logoPath!.isNotEmpty;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasLogo ? null : TournamentColors.accentGradient,
        image: hasLogo
            ? DecorationImage(
                image: FileImage(File(tournament.logoPath!)),
                fit: BoxFit.cover)
            : null,
      ),
      child: !hasLogo
          ? const Icon(Icons.emoji_events_rounded,
              color: Colors.white, size: 22)
          : null,
    );
  }
}

class _OwnerMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _OwnerMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: TournamentColors.surfaceSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: const Icon(Icons.more_vert_rounded,
          color: TournamentColors.textSecondary, size: 20),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_outlined,
                color: TournamentColors.primaryAccent, size: 18),
            SizedBox(width: 8),
            Text('Edit', style: TextStyle(color: Colors.white)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded,
                color: TournamentColors.error, size: 18),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: TournamentColors.error)),
          ]),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: TournamentColors.textSecondary, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TournamentColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}