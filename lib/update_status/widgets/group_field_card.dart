import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable Group dropdown selection card.
class GroupFieldCard extends StatelessWidget {
  final String selectedGroup;
  final ValueChanged<String> onGroupChanged;

  const GroupFieldCard({
    super.key,
    required this.selectedGroup,
    required this.onGroupChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Group',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GROUP',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSubtitle,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedGroup,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.dropdownBackground,
                surfaceTintColor: Colors.transparent,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSubtitle,
                  size: 22,
                ),
                onSelected: onGroupChanged,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'Personal Care',
                    child: Text('Personal Care'),
                  ),
                  PopupMenuItem(
                    value: 'VIP Client',
                    child: Text('VIP Client'),
                  ),
                  PopupMenuItem(
                    value: 'Commercial',
                    child: Text('Commercial'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
