import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_pill_notification.dart';
import 'lead_form_card.dart';
import 'map_location_picker_page.dart';

/// Card for entering a Google Maps location link manually,
/// using the current GPS location, or picking a point on an interactive map.
class LocationLinkCard extends StatefulWidget {
  final TextEditingController controller;
  final Future<String> Function()? onFetchCurrentLocation;

  const LocationLinkCard({
    super.key,
    required this.controller,
    this.onFetchCurrentLocation,
  });

  @override
  State<LocationLinkCard> createState() => _LocationLinkCardState();
}

class _LocationLinkCardState extends State<LocationLinkCard> {
  bool _isFetchingCurrent = false;

  Future<void> _handleCurrentLocation() async {
    if (_isFetchingCurrent) return;
    setState(() => _isFetchingCurrent = true);
    try {
      final link = widget.onFetchCurrentLocation != null
          ? await widget.onFetchCurrentLocation!()
          : await _defaultFetchCurrentLink();
      if (!mounted) return;
      widget.controller.text = link;
      setState(() {});
    } on LocationException catch (e) {
      if (mounted) {
        AppNotification.showError(context, e.message, aboveBottomNav: true);
      }
    } catch (_) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Unable to get current location',
          aboveBottomNav: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingCurrent = false);
      }
    }
  }

  Future<String> _defaultFetchCurrentLink() async {
    final pos = await LocationHelper.getCurrentPosition();
    return LocationHelper.formatGoogleMapsLink(pos.latitude, pos.longitude);
  }

  Future<void> _handlePickOnMap() async {
    final pickedLink = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerPage(
          initialMapLink: widget.controller.text.trim(),
        ),
      ),
    );
    if (!mounted || pickedLink == null || pickedLink.isEmpty) return;
    widget.controller.text = pickedLink;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppDarkColors.textPrimary : const Color(0xFF0F172A);
    final placeholderColor =
        isDark ? AppDarkColors.textPlaceholder : const Color(0xFF94A3B8);
    final chipBg = isDark
        ? AppDarkColors.darkGrey
        : AppColors.primaryRed.withValues(alpha: 0.08);
    final chipBorder = isDark
        ? AppDarkColors.border
        : AppColors.primaryRed.withValues(alpha: 0.25);

    return LeadFormCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Location Link',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(Optional)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: placeholderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              return TextField(
                controller: widget.controller,
                keyboardType: TextInputType.url,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppDarkColors.textPrimary
                      : const Color(0xFF334155),
                ),
                decoration: InputDecoration(
                  hintText: 'https://maps.app.goo.gl/...',
                  hintStyle: TextStyle(color: placeholderColor, fontSize: 13.5),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: placeholderColor,
                          ),
                          tooltip: 'Clear location link',
                          onPressed: () => widget.controller.clear(),
                        )
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LocationActionButton(
                  icon: Icons.my_location_rounded,
                  label: 'Current Location',
                  isLoading: _isFetchingCurrent,
                  backgroundColor: chipBg,
                  borderColor: chipBorder,
                  textColor: isDark
                      ? AppDarkColors.textPrimary
                      : AppColors.primaryRed,
                  onTap: _isFetchingCurrent ? null : _handleCurrentLocation,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LocationActionButton(
                  icon: Icons.pin_drop_outlined,
                  label: 'Pick on Map',
                  backgroundColor: chipBg,
                  borderColor: chipBorder,
                  textColor: isDark
                      ? AppDarkColors.textPrimary
                      : AppColors.primaryRed,
                  onTap: _handlePickOnMap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _LocationActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                )
              else
                Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
