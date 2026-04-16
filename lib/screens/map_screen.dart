import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';
import 'establishment_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  List<Map<String, dynamic>> _establishments = [];
  bool _isLoading = true;

  // Default center: Davao City
  static const _defaultCenter = LatLng(7.0707, 125.6087);

  @override
  void initState() {
    super.initState();
    _fetchEstablishments();
  }

  Future<void> _fetchEstablishments() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('establishments')
          .select('*, accessibility_features(*)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _establishments = List<Map<String, dynamic>>.from(data)
              .where((e) => e['latitude'] != null && e['longitude'] != null)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Marker> _buildMarkers() {
    return _establishments.map((e) {
      final lat = (e['latitude'] as num).toDouble();
      final lng = (e['longitude'] as num).toDouble();
      final isVerified = e['is_verified'] == true;

      return Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showEstablishmentSheet(e),
          child: Container(
            decoration: BoxDecoration(
              color: isVerified ? AppColors.primary600 : AppColors.slate500,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.accessible_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showEstablishmentSheet(Map<String, dynamic> e) {
    final tags = _getAccessibilityTags(e);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    e['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                ),
                if (e['is_verified'] == true)
                  const Icon(Icons.verified_rounded,
                      size: 20, color: Color(0xFF059669)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${e['type'] ?? ''}  •  ${e['barangay'] ?? ''}',
              style: const TextStyle(fontSize: 13, color: AppColors.slate500),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: const Color(0xFFD1FAE5)),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EstablishmentDetailScreen(
                        establishmentId: e['id'],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Details'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  List<String> _getAccessibilityTags(Map<String, dynamic> establishment) {
    final raw = establishment['accessibility_features'];
    Map<String, dynamic>? f;
    if (raw is Map<String, dynamic>) f = raw;
    if (raw is List && raw.isNotEmpty) f = raw.first as Map<String, dynamic>;
    if (f == null) return [];

    final tags = <String>[];
    if (f['has_ramp'] == true) tags.add('Ramp');
    if (f['has_elevator'] == true) tags.add('Elevator');
    if (f['has_accessible_restroom'] == true) tags.add('Restroom');
    if (f['has_braille'] == true) tags.add('Braille');
    if (f['has_tactile_path'] == true) tags.add('Tactile');
    if (f['has_accessible_parking'] == true) tags.add('Parking');
    if (f['has_wide_doorways'] == true) tags.add('Wide Doors');
    if (f['has_hearing_loop'] == true) tags.add('Hearing Loop');
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.pwd_establishment_mobile',
            ),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),
        // Top bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.accessible_rounded,
                    color: AppColors.primary600, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${_establishments.length} accessible places',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Re-center button
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () {
              _mapController.move(_defaultCenter, 14);
            },
            backgroundColor: AppColors.surface,
            child: const Icon(Icons.my_location_rounded,
                color: AppColors.primary600),
          ),
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary600),
          ),
      ],
    );
  }
}
