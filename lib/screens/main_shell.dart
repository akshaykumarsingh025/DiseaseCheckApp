import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/feature_flags.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/notification_service.dart';
import '../services/opd_reminder_service.dart';
import '../services/storage_service.dart';
import '../services/payment_service.dart';
import '../services/ad_service.dart';
import '../services/remote_config_service.dart';
import 'tabs/today_tab.dart';
import 'tabs/track_tab.dart';
import 'tabs/tools_tab.dart';
import 'tabs/consult_tab.dart';
import 'tabs/more_tab.dart';

/// The app's main home surface: a five-tab bottom-navigation shell that replaces
/// the old single-scroll dashboard.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  bool _isOffline = false;
  bool _adFree = true;
  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  static const _titles = ['Today', 'Track', 'Tools', 'Consult', 'More'];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initAds();
    // Asked here rather than at first launch: by the time the shell is on
    // screen the user is signed in, so the prompt lands in context instead of
    // ahead of the splash. `ensureOpdAlertPermissions` is a no-op once granted.
    NotificationService.ensureOpdAlertPermissions();
    _watchAppointmentsForAlerts();
  }

  /// Keeps the OPD alarms in step with whatever the appointment stream says,
  /// for whichever side of the consultation this device belongs to.
  ///
  /// The shell is the one screen alive for both roles for the whole session, so
  /// this is where the subscription belongs — the OPD screens come and go.
  /// `listenManual` rather than `ref.listen` so it can fire immediately: the
  /// stream often already holds a value by the time the shell is built, and a
  /// change-only listener would then never run.
  void _watchAppointmentsForAlerts() {
    ref.listenManual<AsyncValue<List<Appointment>>>(
      userAppointmentsProvider,
      (_, next) {
        final appointments = next.valueOrNull;
        if (appointments == null) return;
        OpdReminderService.sync(appointments, asDoctor: FeatureFlags.isDoctor);
      },
      fireImmediately: true,
    );
  }

  Future<void> _initAds() async {
    final adFree = await PaymentService.isAdFree();
    if (mounted) setState(() => _adFree = adFree);
    AdService.loadInterstitial();
    _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    if (_adFree) return;
    if (!await AdService.adsAreEnabledForUser()) return;

    _bannerAd = BannerAd(
      adUnitId: RemoteConfigService.admobBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (_, __) {
          _bannerAd = null;
          _bannerLoaded = false;
        },
      ),
    );
    await _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      setState(() => _isOffline = result.contains(ConnectivityResult.none));
      Connectivity().onConnectivityChanged.listen((results) {
        if (mounted) {
          setState(
              () => _isOffline = results.contains(ConnectivityResult.none));
        }
      });
    } catch (_) {}
  }

  Future<void> _refreshCloud() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await StorageService.fetchAllFromCloud(user.uid);
        ref.invalidate(profileProvider);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [
      TodayTab(),
      TrackTab(),
      ToolsTab(),
      ConsultTab(),
      MoreTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Sync from cloud',
            icon: const Icon(Icons.cloud_sync_outlined),
            onPressed: _refreshCloud,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isOffline)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    Icon(Icons.cloud_off,
                        size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text('Offline — changes will sync when connected',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade900)),
                  ],
                ),
              ),
            Expanded(
              child: IndexedStack(index: _index, children: tabs),
            ),
            if (!_adFree && _bannerLoaded && _bannerAd != null)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Track'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Tools'),
          NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services),
              label: 'Consult'),
          NavigationDestination(
              icon: Icon(Icons.menu),
              selectedIcon: Icon(Icons.menu_open),
              label: 'More'),
        ],
      ),
    );
  }
}
