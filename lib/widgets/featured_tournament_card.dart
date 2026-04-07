import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FeaturedTournamentCard extends StatelessWidget {
  final String tournamentName;
  final String teamSlots;       // e.g. "25 teams · 4 per team"
  final String organizerName;   // from organizerName field
  final String tournamentDate;  // formatted from date Timestamp
  final String imagePath;       // may be empty — shows icon placeholder
  final VoidCallback onRegister;
  final VoidCallback onViewDetails;

  const FeaturedTournamentCard({
    super.key,
    required this.tournamentName,
    required this.teamSlots,
    required this.organizerName,
    required this.tournamentDate,
    required this.imagePath,
    required this.onRegister,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Game image / icon placeholder ──────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: imagePath.isNotEmpty
                ? Image.network(
                    imagePath,
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),

          // ── Info ───────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournamentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(teamSlots,
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 11)),
                      if (tournamentDate.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.calendar_today,
                              color: AppColors.primaryOrange, size: 11),
                          const SizedBox(width: 3),
                          Text(tournamentDate,
                              style: const TextStyle(
                                  color: AppColors.grey, fontSize: 10)),
                        ]),
                      ],
                    ],
                  ),
                  // ── Buttons ───────────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: onRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.background,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('REGISTER',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: onViewDetails,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.white,
                            side: const BorderSide(
                                color: AppColors.primaryOrange),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('VIEW DETAILS',
                              style: TextStyle(fontSize: 8)),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          // ── Organizer ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Organized\nBy',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.grey, fontSize: 9)),
                const SizedBox(height: 4),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.darkGrey,
                  child: Text(
                    organizerName.isNotEmpty
                        ? organizerName[0].toUpperCase()
                        : 'O',
                    style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                if (organizerName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 50,
                      child: Text(
                        organizerName.split(' ').first,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      color: AppColors.darkGrey,
      child: const Icon(Icons.sports_esports,
          color: AppColors.primaryOrange, size: 36),
    );
  }
}