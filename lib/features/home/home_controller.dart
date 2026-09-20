import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../link/link_client.dart';
import '../../link/mobile_api.dart';
import '../../link/mobile_models.dart';
import '../connection/connection_controller.dart';

final class HomeController extends ChangeNotifier {
  HomeController({required this.sessionProvider, MobileApi? api})
    : _api = api ?? const MobileApi();

  final Future<AuthenticatedLinkSession?> Function() sessionProvider;
  final MobileApi _api;
  MobileOverview? overview;
  List<MobileSearchResult> searchResults = const [];
  String? error;
  String? notice;
  bool loading = true;
  bool refreshing = false;
  bool searching = false;
  String? busyId;
  Timer? _refreshTimer;

  Future<void> initialize() async {
    await refresh(initial: true);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refresh(),
    );
  }

  Future<void> refresh({bool initial = false}) async {
    if (refreshing) return;
    refreshing = true;
    if (initial) loading = true;
    notifyListeners();
    final session = await sessionProvider();
    if (session == null) {
      error = 'The secure connection is unavailable.';
    } else {
      final result = await _api.overview(session);
      if (result case LinkSuccess<MobileOverview> success) {
        overview = success.value;
        error = null;
      } else if (result case LinkFailure<MobileOverview> failure) {
        error = failure.message;
      }
    }
    loading = false;
    refreshing = false;
    notifyListeners();
  }

  Future<void> createReminder(String title, DateTime at, String repeat) async {
    final session = await sessionProvider();
    if (session == null || title.trim().isEmpty) return;
    busyId = 'new-reminder';
    notifyListeners();
    await _run(
      () => _api.createReminder(
        session,
        title: title.trim(),
        at: at,
        repeat: repeat,
      ),
    );
  }

  Future<void> completeReminder(String id) async {
    final session = await sessionProvider();
    if (session == null) return;
    busyId = id;
    notifyListeners();
    await _run(() => _api.completeReminder(session, id));
  }

  Future<void> deleteReminder(String id) async {
    final session = await sessionProvider();
    if (session == null) return;
    busyId = id;
    notifyListeners();
    await _run(() => _api.deleteReminder(session, id));
  }

  Future<void> search(String query) async {
    final session = await sessionProvider();
    if (session == null || query.trim().length < 2) return;
    searching = true;
    error = null;
    notifyListeners();
    final result = await _api.search(session, query.trim());
    if (result case LinkSuccess<List<MobileSearchResult>> success) {
      searchResults = success.value;
    } else if (result case LinkFailure<List<MobileSearchResult>> failure) {
      error = failure.message;
    }
    searching = false;
    notifyListeners();
  }

  Future<void> addRequest(MobileSearchResult item) async {
    final session = await sessionProvider();
    if (session == null) return;
    busyId = '${item.instanceLabel}:${item.externalId}';
    notifyListeners();
    final result = await _api.addRequest(session, item);
    if (result is LinkSuccess<void>) {
      notice = item.title;
      searchResults = searchResults
          .map(
            (candidate) =>
                candidate.externalId == item.externalId &&
                    candidate.instanceLabel == item.instanceLabel
                ? MobileSearchResult(
                    instanceLabel: candidate.instanceLabel,
                    kind: candidate.kind,
                    title: candidate.title,
                    inLibrary: true,
                    externalId: candidate.externalId,
                    year: candidate.year,
                    poster: candidate.poster,
                    overview: candidate.overview,
                  )
                : candidate,
          )
          .toList(growable: false);
      await refresh();
    } else if (result case LinkFailure<void> failure) {
      error = failure.message;
    }
    busyId = null;
    notifyListeners();
  }

  Future<void> testTelegram() async {
    final session = await sessionProvider();
    if (session == null) return;
    busyId = 'telegram';
    notifyListeners();
    final result = await _api.testTelegram(session);
    if (result is LinkSuccess<void>) {
      notice = 'telegram';
      error = null;
    } else if (result case LinkFailure<void> failure) {
      error = failure.message;
    }
    busyId = null;
    notifyListeners();
  }

  Future<void> sendClipboard(Future<String?> Function() readText) async {
    final session = await sessionProvider();
    if (session == null) return;
    final text = (await readText())?.trim() ?? '';
    if (text.isEmpty) {
      error = 'clipboard_empty';
      notifyListeners();
      return;
    }
    busyId = 'clipboard';
    notifyListeners();
    final result = await _api.relayClipboard(session, text);
    if (result case LinkSuccess<int> success) {
      notice = 'clipboard:${success.value}';
      error = null;
    } else if (result case LinkFailure<int> failure) {
      error = failure.message;
    }
    busyId = null;
    notifyListeners();
  }

  Future<void> _run(Future<LinkResult<void>> Function() action) async {
    final result = await action();
    if (result is LinkSuccess<void>) {
      error = null;
      await refresh();
    } else if (result case LinkFailure<void> failure) {
      error = failure.message;
    }
    busyId = null;
    notifyListeners();
  }

  void clearMessage() {
    error = null;
    notice = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
