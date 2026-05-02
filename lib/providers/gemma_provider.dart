import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gemma_service.dart';

class GemmaState {
  final bool isEnabled;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final int downloadedBytes;
  final int totalBytes;
  final String? downloadError;
  final bool isRefining;
  final double refineProgress;
  final String? refinedText;
  final String? refineError;
  final String language;

  const GemmaState({
    this.isEnabled = false,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.downloadError,
    this.isRefining = false,
    this.refineProgress = 0,
    this.refinedText,
    this.refineError,
    this.language = 'english',
  });

  String get downloadProgressText {
    if (totalBytes > 0) {
      final receivedMB = downloadedBytes / (1024 * 1024);
      final totalMB = totalBytes / (1024 * 1024);
      return '${receivedMB.toStringAsFixed(0)} / ${totalMB.toStringAsFixed(0)} MB';
    }
    final receivedMB = downloadedBytes / (1024 * 1024);
    return '${receivedMB.toStringAsFixed(0)} MB / ~2,500 MB';
  }

  GemmaState copyWith({
    bool? isEnabled,
    bool? isDownloaded,
    bool? isDownloading,
    double? downloadProgress,
    int? downloadedBytes,
    int? totalBytes,
    String? downloadError,
    bool? isRefining,
    double? refineProgress,
    String? refinedText,
    String? refineError,
    String? language,
  }) {
    return GemmaState(
      isEnabled: isEnabled ?? this.isEnabled,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadError: downloadError,
      isRefining: isRefining ?? this.isRefining,
      refineProgress: refineProgress ?? this.refineProgress,
      refinedText: refinedText,
      refineError: refineError,
      language: language ?? this.language,
    );
  }
}

class GemmaNotifier extends StateNotifier<GemmaState> {
  GemmaNotifier() : super(const GemmaState());

  Future<void> loadState() async {
    final enabled = await GemmaService.isEnabled();
    final downloaded = await GemmaService.isModelDownloaded();
    final lang = await GemmaService.getLanguage();
    state = state.copyWith(isEnabled: enabled, isDownloaded: downloaded, language: lang);

    if (downloaded) {
      final ok = await GemmaService.initializeModel();
      if (!ok) {
        state = state.copyWith(isEnabled: false);
      }
    }
  }

  Future<void> setLanguage(String lang) async {
    await GemmaService.setLanguage(lang);
    state = state.copyWith(language: lang, refinedText: null);
  }

  Future<void> startDownload() async {
    state = state.copyWith(
      isDownloading: true,
      downloadProgress: 0,
      downloadedBytes: 0,
      totalBytes: 0,
      downloadError: null,
    );

    await GemmaService.downloadModel(
      onProgress: (p, received, total) {
        state = state.copyWith(
          downloadProgress: p,
          downloadedBytes: received,
          totalBytes: total,
        );
      },
      onComplete: () {
        state = state.copyWith(
          isDownloading: false,
          isDownloaded: true,
          downloadProgress: 1.0,
          isEnabled: true,
        );
      },
      onError: (e) {
        state = state.copyWith(
          isDownloading: false,
          downloadError: e,
        );
      },
    );
  }

  Future<void> deleteModel() async {
    await GemmaService.deleteModel();
    state = state.copyWith(
      isDownloaded: false,
      refinedText: null,
      isEnabled: false,
      refineError: null,
    );
  }

  Future<void> refineReport(String rawText) async {
    state = state.copyWith(
      isRefining: true,
      refineProgress: 0.1,
      refinedText: null,
      refineError: null,
    );

    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(refineProgress: 0.3);

    final result = await GemmaService.refineReport(rawText, language: state.language);

    if (result.success && result.text != null) {
      state = state.copyWith(
        isRefining: false,
        refineProgress: 1.0,
        refinedText: result.text,
        refineError: null,
      );
    } else {
      state = state.copyWith(
        isRefining: false,
        refineProgress: 1.0,
        refineError: result.error ?? 'AI could not generate an explanation. Please try again.',
      );
    }
  }
}

final gemmaProvider = StateNotifierProvider<GemmaNotifier, GemmaState>((ref) {
  final notifier = GemmaNotifier();
  notifier.loadState();
  return notifier;
});
