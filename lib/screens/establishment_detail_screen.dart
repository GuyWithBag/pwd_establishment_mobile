import 'package:flutter/material.dart';
import '../main.dart';

class EstablishmentDetailScreen extends StatefulWidget {
  final String establishmentId;

  const EstablishmentDetailScreen({
    super.key,
    required this.establishmentId,
  });

  @override
  State<EstablishmentDetailScreen> createState() =>
      _EstablishmentDetailScreenState();
}

class _EstablishmentDetailScreenState extends State<EstablishmentDetailScreen> {
  Map<String, dynamic>? _establishment;
  Map<String, dynamic>? _features;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final estData = await supabase
          .from('establishments')
          .select()
          .eq('id', widget.establishmentId)
          .single();

      final featData = await supabase
          .from('accessibility_features')
          .select()
          .eq('establishment_id', widget.establishmentId)
          .maybeSingle() as Map<String, dynamic>?;

      final reportData = await supabase
          .from('access_reports')
          .select()
          .eq('establishment_id', widget.establishmentId)
          .order('submitted_at', ascending: false);

      if (mounted) {
        setState(() {
          _establishment = estData;
          _features = featData;
          _reports = List<Map<String, dynamic>>.from(reportData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary600),
            )
          : _establishment == null
              ? const Center(child: Text('Establishment not found'))
              : _buildContent(),
    );
  }

  Widget _buildAppBarBackground(Map<String, dynamic> e) {
    final imageUrl = e['image_url'] as String?;
    final type = e['type'] as String? ?? '';
    if (imageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _gradientBackground(type),
          ),
          // Dark gradient overlay so title is readable
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
              ),
            ),
          ),
        ],
      );
    }
    return _gradientBackground(type);
  }

  Widget _gradientBackground(String type) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary700, AppColors.primary500],
        ),
      ),
      child: Center(
        child: Icon(
          _getTypeIcon(type),
          size: 64,
          color: Colors.white.withAlpha(77),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final e = _establishment!;
    final name = e['name'] ?? '';
    final type = e['type'] ?? '';
    final address = e['address'] ?? '';
    final barangay = e['barangay'] ?? '';
    final isVerified = e['is_verified'] == true;

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.primary600,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildAppBarBackground(e),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.slate100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 18,
                            color: AppColors.slate500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                          const Spacer(),
                          if (isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFD1FAE5),
                                ),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppColors.slate500,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$address, $barangay',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.slate600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Accessibility Features
                const Text(
                  'Accessibility Features',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 14),
                _buildFeaturesGrid(),

                const SizedBox(height: 24),

                // Access Reports
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Access Reports',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_reports.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_reports.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.slate100),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 40,
                          color: AppColors.slate400,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No reports yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._reports.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReportCard(
                          report: r,
                          onTap: () => _showReportDetail(context, r),
                        ),
                      )),

                const SizedBox(height: 20),

                // Submit report button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showReportDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Submit a Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid() {
    if (_features == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.slate100),
        ),
        child: const Column(
          children: [
            Icon(Icons.info_outline_rounded, size: 40, color: AppColors.slate400),
            SizedBox(height: 12),
            Text(
              'No accessibility data yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      );
    }

    final featureList = [
      _FeatureItem('Ramp Access', Icons.accessible_rounded, _features!['has_ramp'] == true),
      _FeatureItem('Elevator', Icons.elevator_outlined, _features!['has_elevator'] == true),
      _FeatureItem('Accessible Restroom', Icons.wc_rounded, _features!['has_accessible_restroom'] == true),
      _FeatureItem('Braille Signs', Icons.menu_book_rounded, _features!['has_braille'] == true),
      _FeatureItem('Tactile Path', Icons.timeline_rounded, _features!['has_tactile_path'] == true),
      _FeatureItem('Accessible Parking', Icons.local_parking_rounded, _features!['has_accessible_parking'] == true),
      _FeatureItem('Wide Doorways', Icons.door_sliding_outlined, _features!['has_wide_doorways'] == true),
      _FeatureItem('Hearing Loop', Icons.hearing_rounded, _features!['has_hearing_loop'] == true),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate100),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.8,
        children: featureList
            .map(
              (f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: f.available
                      ? const Color(0xFFECFDF5)
                      : AppColors.slate50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: f.available
                        ? const Color(0xFFD1FAE5)
                        : AppColors.slate200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      f.icon,
                      size: 18,
                      color: f.available
                          ? const Color(0xFF059669)
                          : AppColors.slate400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: f.available
                              ? const Color(0xFF047857)
                              : AppColors.slate500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<String> _fetchUserLabel(String? userId) async {
    if (userId == null) return 'Anonymous';
    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      if (profile == null) return 'Anonymous';
      final role = profile['role'] as String? ?? 'user';
      return '${role[0].toUpperCase()}${role.substring(1)} (${userId.substring(0, 8)}…)';
    } catch (_) {
      return 'Anonymous';
    }
  }

  void _showReportDetail(BuildContext context, Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReportDetailSheet(
        report: report,
        fetchUserLabel: _fetchUserLabel,
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final featureController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Submit Access Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: featureController,
              decoration: InputDecoration(
                labelText: 'Feature Reported',
                hintText: 'e.g. Ramp, Elevator, Restroom',
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary500,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add any details...',
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary500,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final feature = featureController.text.trim();
                  if (feature.isEmpty) return;

                  try {
                    await supabase.from('access_reports').insert({
                      'establishment_id': widget.establishmentId,
                      'submitted_by': user.id,
                      'feature_reported': feature,
                      'description': descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchData();
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Failed to submit: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
      case 'cafe':
        return Icons.restaurant_rounded;
      case 'government':
        return Icons.account_balance_rounded;
      case 'transit':
        return Icons.directions_transit_rounded;
      case 'hospital':
      case 'clinic':
        return Icons.local_hospital_rounded;
      case 'school':
      case 'university':
        return Icons.school_rounded;
      case 'library':
        return Icons.local_library_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'mall':
      case 'shop':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.business_rounded;
    }
  }
}

class _FeatureItem {
  final String label;
  final IconData icon;
  final bool available;

  _FeatureItem(this.label, this.icon, this.available);
}

String _formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  } catch (_) {
    return isoDate;
  }
}

Map<String, Color> _statusColors(String status) {
  switch (status) {
    case 'approved':
      return {'color': const Color(0xFF059669), 'bg': const Color(0xFFECFDF5)};
    case 'rejected':
      return {'color': const Color(0xFFDC2626), 'bg': const Color(0xFFFEF2F2)};
    default:
      return {'color': const Color(0xFFD97706), 'bg': const Color(0xFFFFFBEB)};
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final feature = report['feature_reported'] ?? '';
    final status = report['status'] ?? 'pending';
    final submittedAt = report['submitted_at'] as String?;
    final colors = _statusColors(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  if (submittedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(submittedAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.slate400),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors['bg'],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors['color']),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.slate400, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailSheet extends StatefulWidget {
  final Map<String, dynamic> report;
  final Future<String> Function(String?) fetchUserLabel;

  const _ReportDetailSheet({required this.report, required this.fetchUserLabel});

  @override
  State<_ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<_ReportDetailSheet> {
  String? _submitterLabel;
  String? _reviewerLabel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final submittedBy = widget.report['submitted_by'] as String?;
    final reviewedBy = widget.report['reviewed_by'] as String?;

    final results = await Future.wait([
      widget.fetchUserLabel(submittedBy),
      widget.fetchUserLabel(reviewedBy),
    ]);

    if (mounted) {
      setState(() {
        _submitterLabel = results[0];
        _reviewerLabel = results[1];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final feature = report['feature_reported'] ?? '';
    final description = report['description'] as String?;
    final status = report['status'] ?? 'pending';
    final submittedAt = report['submitted_at'] as String?;
    final reviewedAt = report['reviewed_at'] as String?;
    final colors = _statusColors(status);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  feature,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: colors['bg'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors['color'],
                  ),
                ),
              ),
            ],
          ),

          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.slate600,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(color: AppColors.slate100),
          const SizedBox(height: 16),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary600, strokeWidth: 2))
          else ...[
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Submitted by',
              value: _submitterLabel ?? 'Anonymous',
            ),
            if (submittedAt != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Submitted on',
                value: _formatDate(submittedAt),
              ),
            ],
            if (reviewedAt != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.manage_accounts_outlined,
                label: 'Reviewed by',
                value: _reviewerLabel ?? 'Anonymous',
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Reviewed on',
                value: _formatDate(reviewedAt),
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.slate400),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.slate400, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate700),
            ),
          ],
        ),
      ],
    );
  }
}
