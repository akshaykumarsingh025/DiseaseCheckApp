import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/report.dart';
import '../services/storage_service.dart';

class ReportHistoryScreen extends ConsumerStatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  ConsumerState<ReportHistoryScreen> createState() =>
      _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends ConsumerState<ReportHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<HealthReport> _displayedReports = [];
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadMoreReports();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
    setState(() {
      _currentPage = 0;
      _displayedReports.clear();
      _hasMore = true;
    });
    await _loadMoreReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past Reports')),
      body: _displayedReports.isEmpty && !_isLoadingMore
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No past reports found.\nEnter new data to get a risk assessment.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _displayedReports.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _displayedReports.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final report = _displayedReports[index];

                  String subtitleText = 'Low Risk';
                  Color riskColor = Colors.green;

                  if (report.highRiskDiseases.isNotEmpty) {
                    final first = report.highRiskDiseases.first;
                    subtitleText =
                        'High Risk: ${first['disease'] ?? 'Unknown'}';
                    riskColor = Colors.red;
                  } else if (report.moderateRiskDiseases.isNotEmpty) {
                    final first = report.moderateRiskDiseases.first;
                    subtitleText =
                        'Moderate Risk: ${first['disease'] ?? 'Unknown'}';
                    riskColor = Colors.orange;
                  }

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.description, color: riskColor),
                      title: Text(
                        'Report ${report.date.toString().split(' ')[0]}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        subtitleText,
                        style: TextStyle(
                            color: riskColor, fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/report', extra: report);
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
