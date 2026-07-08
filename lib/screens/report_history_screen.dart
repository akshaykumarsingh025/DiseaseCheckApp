import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/report.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';
import '../widgets/banner_ad_widget.dart';

class ReportHistoryScreen extends ConsumerStatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  ConsumerState<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends ConsumerState<ReportHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<HealthReport> _displayedReports = [];
  List<HealthReport> _allReports = [];
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  Set<String> _selectedForCompare = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    _allReports = StorageService.getAllReports();
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    List<HealthReport> filtered;
    if (query.isEmpty) {
      filtered = _allReports;
    } else {
      filtered = _allReports.where((r) {
        final allDiseases = [
          ...r.highRiskDiseases.map((e) => e['disease']?.toString().toLowerCase() ?? ''),
          ...r.moderateRiskDiseases.map((e) => e['disease']?.toString().toLowerCase() ?? ''),
          ...r.lowRiskDiseases.map((e) => e['disease']?.toString().toLowerCase() ?? ''),
          ...r.abnormalValues.map((e) => e.toLowerCase()),
        ];
        final dateStr = r.date.toString().split(' ').first.toLowerCase();
        return allDiseases.any((d) => d.contains(query)) || dateStr.contains(query);
      }).toList();
    }
    setState(() {
      _displayedReports = filtered;
      _currentPage = 1;
      _hasMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMoreReports();
    }
  }

  Future<void> _loadMoreReports() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final newReports = StorageService.getReportsPaginated(
      offset: _currentPage * _pageSize,
      limit: _pageSize,
    );
    setState(() {
      _displayedReports.addAll(newReports);
      _currentPage++;
      _hasMore = newReports.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    await _loadReports();
  }

  void _deleteReport(HealthReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report?'),
        content: Text('Delete the report from ${report.date.toString().split(' ')[0]}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService.deleteReport(report.reportId);
              _selectedForCompare.remove(report.reportId);
              await _refresh();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _compareReports() {
    if (_selectedForCompare.length != 2) return;
    final r1 = _allReports.firstWhere((r) => r.reportId == _selectedForCompare.elementAt(0));
    final r2 = _allReports.firstWhere((r) => r.reportId == _selectedForCompare.elementAt(1));
    context.push('/compare-reports', extra: {'report1': r1, 'report2': r2});
  }

  @override
  Widget build(BuildContext context) {
    final profile = StorageService.getProfile();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Reports'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _applyFilter();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(),
          ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by disease, date, or value...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: (_) => _applyFilter(),
                  ),
                ),
              )
            : null,
      ),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
      body: _displayedReports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No past reports found.\nEnter new data to get a risk assessment.', textAlign: TextAlign.center),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: Column(
                children: [
                  if (_selectedForCompare.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          Text('${_selectedForCompare.length}/2 selected for compare',
                              style: TextStyle(fontSize: 13, color: Colors.blue.shade700)),
                          const Spacer(),
                          if (_selectedForCompare.length == 2)
                            TextButton(
                              onPressed: _compareReports,
                              child: const Text('Compare Now'),
                            ),
                          TextButton(
                            onPressed: () => setState(() => _selectedForCompare.clear()),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _displayedReports.length,
                      itemBuilder: (context, index) {
                        final report = _displayedReports[index];
                        return _buildReportCard(report, profile);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReportCard(HealthReport report, UserProfile? profile) {
    String riskLabel = 'All Normal';
    Color riskColor = Colors.green;
    int totalDiseases = 0;

    if (report.highRiskDiseases.isNotEmpty) {
      riskLabel = 'High: ${report.highRiskDiseases.first['disease'] ?? 'Unknown'}';
      riskColor = Colors.red;
      totalDiseases += report.highRiskDiseases.length;
    }
    if (report.moderateRiskDiseases.isNotEmpty) {
      if (riskColor != Colors.red) {
        riskLabel = 'Moderate: ${report.moderateRiskDiseases.first['disease'] ?? 'Unknown'}';
        riskColor = Colors.orange;
      }
      totalDiseases += report.moderateRiskDiseases.length;
    }
    totalDiseases += report.lowRiskDiseases.length;

    final isSelected = _selectedForCompare.contains(report.reportId);
    final valueCount = report.abnormalValues.length + totalDiseases;
    final dateStr = report.date.toString().split(' ')[0];

    return Dismissible(
      key: Key(report.reportId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        _deleteReport(report);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected ? BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: () {
            setState(() {
              if (isSelected) {
                _selectedForCompare.remove(report.reportId);
              } else if (_selectedForCompare.length < 2) {
                _selectedForCompare.add(report.reportId);
              }
            });
          },
          onTap: () => context.push('/report', extra: report),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: riskColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(riskLabel, style: TextStyle(color: riskColor, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChip(Icons.science, '$valueCount findings', Colors.blue),
                    if (profile != null && profile.height != null && profile.weight != null)
                      _buildChip(Icons.monitor_weight, 'BMI tracked', Colors.teal),
                    if (report.aiRefinedText != null)
                      _buildChip(Icons.auto_awesome, 'AI analyzed', Colors.purple),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Selected for compare', style: TextStyle(fontSize: 11, color: Colors.blue)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Date,High Risk,Moderate Risk,Low Risk,Abnormal Values,AI Analyzed');
      for (var r in _allReports) {
        final high = r.highRiskDiseases.map((e) => e['disease']).join('; ');
        final mod = r.moderateRiskDiseases.map((e) => e['disease']).join('; ');
        final low = r.lowRiskDiseases.map((e) => e['disease']).join('; ');
        final abn = r.abnormalValues.join('; ');
        buffer.writeln('"${r.date.toString().split('.')[0]}","$high","$mod","$low","$abn","${r.aiRefinedText != null ? 'Yes' : 'No'}"');
      }
      final dir = Directory('/sdcard/Download');
      final file = File('${dir.path}/health_reports_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV saved to Downloads'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
