import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Full-width action button to update the customer lead status.
class UpdateStatusButton extends StatelessWidget {
  final VoidCallback onTap;

  const UpdateStatusButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenColor =
        isDark ? AppDarkColors.whatsappGreen : AppColors.whatsappGreen;
    final textColor = isDark ? const Color(0xFF06140D) : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: greenColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Update Status',
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
