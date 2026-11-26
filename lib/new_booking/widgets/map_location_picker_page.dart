import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_pill_notification.dart';
import '../../core/widgets/circular_back_button.dart';

/// Shared helper for resolving device GPS location and formatting Google Maps links.
abstract final class LocationHelper {
  /// Default fallback center when no coordinates or GPS fix are available yet (Kochi, Kerala).
  static const LatLng defaultMapCenter = LatLng(10.0159, 76.3419);

  /// Formats [lat] and [lng] as a standard Google Maps link.
  static String formatGoogleMapsLink(double lat, double lng) {
    return 'https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
  }

  /// Attempts to extract coordinates from a Google Maps URL (`?q=lat,lng` or `@lat,lng`).
  static LatLng? tryParseLatLng(String? link) {
    if (link == null || link.trim().isEmpty) return null;
    final match = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)').firstMatch(link);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  /// Requests permission if needed and returns the current device position,
  /// falling back to last known position if a live fix times out.
  static Future<Position> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationException(
          'Location services are turned off. Please enable GPS.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const LocationException('Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationException(
          'Location permission is permanently denied. Enable it in Settings.',
        );
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        debugPrint('>>> [LocationHelper] Live fix failed, trying last known: $e');
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return lastKnown;
        }
        rethrow;
      }
    } on LocationException {
      rethrow;
    } on MissingPluginException {
      throw const LocationException(
        'Location plugin not loaded. Please stop and rebuild the app.',
      );
    } catch (e) {
      debugPrint('>>> [LocationHelper] getCurrentPosition error: $e');
      throw LocationException('Unable to get current location ($e)');
    }
  }
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
  @override
  String toString() => message;
}

/// Interactive map screen where the user can pan/drag the map under a centered pin
/// (or tap anywhere on the map) to pick a location and return a Google Maps URL.
class MapLocationPickerPage extends StatefulWidget {
  final String? initialMapLink;

  const MapLocationPickerPage({super.key, this.initialMapLink});

  @override
  State<MapLocationPickerPage> createState() => _MapLocationPickerPageState();
}

class _MapLocationPickerPageState extends State<MapLocationPickerPage> {
  final MapController _mapController = MapController();
  late LatLng _selectedPoint;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    final parsed = LocationHelper.tryParseLatLng(widget.initialMapLink);
    _selectedPoint = parsed ?? LocationHelper.defaultMapCenter;
    if (parsed == null) {
      _centerOnCurrentLocation(silentOnError: true);
    }
  }

  Future<void> _centerOnCurrentLocation({bool silentOnError = false}) async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);
    try {
      final pos = await LocationHelper.getCurrentPosition();
      if (!mounted) return;
      final target = LatLng(pos.latitude, pos.longitude);
      setState(() => _selectedPoint = target);
      _mapController.move(target, 16.0);
    } on LocationException catch (e) {
      if (mounted && !silentOnError) {
        AppNotification.showError(context, e.message);
      }
    } catch (_) {
      if (mounted && !silentOnError) {
        AppNotification.showError(context, 'Unable to fetch current location.');
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  void _confirmSelection() {
    final link = LocationHelper.formatGoogleMapsLink(
      _selectedPoint.latitude,
      _selectedPoint.longitude,
    );
    Navigator.of(context).pop(link);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? AppDarkColors.surface : Colors.white;
    final primaryTextColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final subtitleTextColor =
        isDark ? AppDarkColors.textSubtitle : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: CircularBackButton(
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          'Pick location on map',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        titleSpacing: 8,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: 15.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _selectedPoint = camera.center;
                  });
                }
              },
              onTap: (_, latLng) {
                setState(() => _selectedPoint = latLng);
                _mapController.move(latLng, _mapController.camera.zoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fitmate.task_chat',
              ),
            ],
          ),

          // Centered draggable pointer (map pans beneath this pin)
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_pin,
                      size: 46,
                      color: AppColors.logoRed,
                      shadows: const [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    Container(
                      width: 10,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top helper pill
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Drag map or tap to position the pin',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
              ),
            ),
          ),

          // My Location FAB
          Positioned(
            right: 16,
            bottom: 136,
            child: FloatingActionButton.small(
              heroTag: 'map_picker_my_location',
              backgroundColor: cardColor,
              foregroundColor: AppColors.primaryRed,
              onPressed: _isFetchingLocation
                  ? null
                  : () => _centerOnCurrentLocation(),
              child: _isFetchingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),

          // Bottom coordinates & Confirm button
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Coordinates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subtitleTextColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_selectedPoint.latitude.toStringAsFixed(6)}, '
                      '${_selectedPoint.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _confirmSelection,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
