import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Full-width action button to update the customer lead status.
class UpdateStatusButton extends StatelessWidget {
  final VoidCallback? onTap;

  const UpdateStatusButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Status update dialog opened'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.whatsappGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Update Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
