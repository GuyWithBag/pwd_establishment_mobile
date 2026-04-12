import 'package:flutter/material.dart';
import '../main.dart';
import 'establishment_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _establishments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All Needs';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final _filters = [
    'All Needs',
    'Wheelchair',
    'Sensory Friendly',
    'Low Vision',
  ];

  // Maps filter labels to accessibility_features column names
  static const _filterToColumn = {
    'Wheelchair': 'has_ramp',
    'Sensory Friendly': 'has_hearing_loop',
    'Low Vision': 'has_braille',
  };

  @override
  void initState() {
    super.initState();
    _fetchEstablishments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEstablishments() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await supabase
          .from('establishments')
          .select('*, accessibility_features(*)')
          .order('created_at', ascending: false);

      // ignore: avoid_print
      print('Fetched ${data.length} establishments');
      if (data.isNotEmpty) {
        // ignore: avoid_print
        print('First item accessibility_features: ${data.first['accessibility_features']}');
      }
      if (mounted) {
        setState(() {
          _establishments = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredEstablishments {
    var list = _establishments;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) {
        final name = (e['name'] as String? ?? '').toLowerCase();
        final type = (e['type'] as String? ?? '').toLowerCase();
        final address = (e['address'] as String? ?? '').toLowerCase();
        return name.contains(q) || type.contains(q) || address.contains(q);
      }).toList();
    }

    // Apply accessibility filter
    if (_selectedFilter != 'All Needs') {
      final col = _filterToColumn[_selectedFilter];
      if (col != null) {
        list = list.where((e) {
          final f = _featuresMap(e);
          return f?[col] == true;
        }).toList();
      }
    }

    return list;
  }

  /// Normalises accessibility_features whether Supabase returns a Map or a List.
  static Map<String, dynamic>? _featuresMap(Map<String, dynamic> establishment) {
    final raw = establishment['accessibility_features'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty) return raw.first as Map<String, dynamic>;
    return null;
  }

  List<String> _getAccessibilityTags(Map<String, dynamic> establishment) {
    final f = _featuresMap(establishment);
    if (f == null) return [];
    final tags = <String>[];
    if (f['has_ramp'] == true) tags.add('Ramp Access');
    if (f['has_elevator'] == true) tags.add('Elevator');
    if (f['has_accessible_restroom'] == true) tags.add('Accessible Restroom');
    if (f['has_braille'] == true) tags.add('Braille');
    if (f['has_tactile_path'] == true) tags.add('Tactile Path');
    if (f['has_accessible_parking'] == true) tags.add('Parking');
    if (f['has_wide_doorways'] == true) tags.add('Wide Doors');
    if (f['has_hearing_loop'] == true) tags.add('Hearing Loop');
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find & Rate Places',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 14),
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search cafes, offices...',
                    hintStyle: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.slate400,
                    ),
                    filled: true,
                    fillColor: AppColors.slate100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Filter chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary600
                                : AppColors.slate100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.slate700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary600,
                    ),
                  )
                : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              const Text('Failed to load', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate800)),
                              const SizedBox(height: 8),
                              Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.slate500), textAlign: TextAlign.center),
                              const SizedBox(height: 20),
                              ElevatedButton(onPressed: _fetchEstablishments, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : RefreshIndicator(
                    onRefresh: _fetchEstablishments,
                    color: AppColors.primary600,
                    child: _filteredEstablishments.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 56,
                                      color: AppColors.slate400,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No establishments found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredEstablishments.length,
                            itemBuilder: (context, index) {
                              final e = _filteredEstablishments[index];
                              final tags = _getAccessibilityTags(e);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _EstablishmentCard(
                                  name: e['name'] ?? '',
                                  type: e['type'] ?? '',
                                  barangay: e['barangay'] ?? '',
                                  isVerified: e['is_verified'] == true,
                                  imageUrl: e['image_url'] as String?,
                                  tags: tags,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EstablishmentDetailScreen(
                                          establishmentId: e['id'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EstablishmentCard extends StatelessWidget {
  final String name;
  final String type;
  final String barangay;
  final bool isVerified;
  final String? imageUrl;
  final List<String> tags;
  final VoidCallback onTap;

  const _EstablishmentCard({
    required this.name,
    required this.type,
    required this.barangay,
    required this.isVerified,
    required this.tags,
    required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (imageUrl != null)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: AppColors.primary50,
                  child: const Center(
                    child: Icon(
                      Icons.business_rounded,
                      size: 48,
                      color: AppColors.primary200,
                    ),
                  ),
                ),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 140,
                        color: AppColors.slate100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary600,
                            strokeWidth: 2,
                          ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$type  •  $barangay',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD1FAE5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.slate200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: AppColors.slate700,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              child: const Text('View Details'),
            ),
          ),
          ],  // Column children
          ), // Column
          ), // Padding
        ],  // outer Column children
      ),    // outer Column
    );      // Container
  }
}
