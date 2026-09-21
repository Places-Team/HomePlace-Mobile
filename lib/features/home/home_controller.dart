import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sharing/share_service.dart';
import '../../core/storage/transfer_activity_store.dart';
import '../../link/link_client.dart';
import '../../link/mobile_api.dart';
import '../../link/mobile_models.dart';
import '../connection/connection_controller.dart';

final class HomeController extends ChangeNotifier {
  HomeController({
    required this.sessionProvider,
    MobileApi? api,
    TransferActivityStore? activityStore,
  }) : _api = api ?? const MobileApi(),
       _activityStore = activityStore ?? const PlatformTransferActivityStore();

  final Future<AuthenticatedLinkSession?> Function() sessionProvider;
  final MobileApi _api;
  final TransferActivityStore _activityStore;
  MobileOverview? overview;
  List<MobileSearchResult> searchResults = const [];
  List<MobileCalendarEvent>? calendarEvents;
  bool calendarLoading = false;
  String? error;
  String? notice;
  bool loading = true;
  bool refreshing = false;
  bool searching = false;
  String? busyId;
  Timer? _refreshTimer;
  Timer? _clipboardTimer;
  Future<String?> Function()? _clipboardReader;
  String? _lastAutoClipboardText;
  bool _autoClipboardBusy = false;
  bool autoClipboardEnabled = false;
  List<TransferActivity> transferActivity = const [];
  String? _activityScope;
  double? fileTransferProgress;
  String? activeFileTransferId;
  LinkTransferCancellation? _fileTransferCancellation;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    autoClipboardEnabled = preferences.getBool('clipboard.autoSend') ?? false;
    await _loadTransferActivity();
    await refresh(initial: true);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refresh(),
    );
    _restartClipboardTimer();
  }

  void bindClipboardReader(Future<String?> Function() reader) {
    _clipboardReader = reader;
    _restartClipboardTimer();
  }

  Future<void> setAutoClipboardEnabled(bool value) async {
    if (autoClipboardEnabled == value) return;
    autoClipboardEnabled = value;
    _lastAutoClipboardText = null;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('clipboard.autoSend', value);
    _restartClipboardTimer();
  }

  void _restartClipboardTimer() {
    _clipboardTimer?.cancel();
    _clipboardTimer = null;
    if (!autoClipboardEnabled || _clipboardReader == null) return;
    unawaited(_relayClipboardIfChanged());
    _clipboardTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(_relayClipboardIfChanged()),
    );
  }

  Future<void> _relayClipboardIfChanged() async {
    if (_autoClipboardBusy || !autoClipboardEnabled) return;
    final reader = _clipboardReader;
    if (reader == null) return;
    _autoClipboardBusy = true;
    try {
      final text = (await reader())?.trim() ?? '';
      if (text.isEmpty || text == _lastAutoClipboardText) return;
      _lastAutoClipboardText = text;
      final session = await sessionProvider();
      if (session == null) return;
      final result = await _api.relayClipboard(session, text);
      if (result case LinkSuccess<int> success when success.value > 0) {
        notice = 'clipboard_auto:${success.value}';
        error = null;
        notifyListeners();
      }
    } finally {
      _autoClipboardBusy = false;
    }
  }

  Future<void> refresh({bool initial = false}) async {
    if (refreshing) return;
    refreshing = true;
    if (initial) loading = true;
    notifyListeners();
    try {
      final session = await sessionProvider().timeout(
        const Duration(seconds: 15),
      );
      if (session == null) {
        error = 'The secure connection is unavailable.';
      } else {
        final result = await _api
            .overview(session)
            .timeout(const Duration(seconds: 20));
        if (result case LinkSuccess<MobileOverview> success) {
          overview = success.value;
          error = null;
        } else if (result case LinkFailure<MobileOverview> failure) {
          error = failure.message;
        }
      }
    } on TimeoutException {
      error = 'HomePlace did not respond in time. Pull down to try again.';
    } on Object {
      error = 'HomePlace could not refresh securely. Pull down to try again.';
    } finally {
      loading = false;
      refreshing = false;
      notifyListeners();
    }
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

  Future<void> updateReminder(
    MobileReminder reminder,
    String title,
    DateTime at,
    String repeat,
  ) async {
    final session = await sessionProvider();
    if (session == null || title.trim().isEmpty) return;
    busyId = reminder.id;
    notifyListeners();
    await _run(
      () => _api.updateReminder(
        session,
        reminder,
        title: title.trim(),
        at: at,
        repeat: repeat,
      ),
    );
  }

  Future<void> reopenReminder(String id) async {
    final session = await sessionProvider();
    if (session == null) return;
    busyId = id;
    notifyListeners();
    await _run(() => _api.reopenReminder(session, id));
  }

  Future<void> deleteCompletedReminders() async {
    final session = await sessionProvider();
    if (session == null) return;
    busyId = 'completed-reminders';
    notifyListeners();
    await _run(() => _api.deleteCompletedReminders(session));
  }

  Future<void> deleteReminder(String id) async {
    final session = await sessionProvider();
    if (session == null) return;
    busyId = id;
    notifyListeners();
    await _run(() => _api.deleteReminder(session, id));
  }

  Future<void> loadCalendar(DateTime from, DateTime to) async {
    final session = await sessionProvider();
    if (session == null || calendarLoading) return;
    calendarLoading = true;
    notifyListeners();
    final result = await _api.calendar(session, from, to);
    if (result case LinkSuccess<List<MobileCalendarEvent>> success) {
      calendarEvents = success.value;
      error = null;
    } else if (result case LinkFailure<List<MobileCalendarEvent>> failure) {
      error = failure.message;
    }
    calendarLoading = false;
    notifyListeners();
  }

  Future<void> saveCalendarEvent({
    MobileCalendarEvent? existing,
    required String summary,
    required DateTime start,
    required DateTime end,
    required bool allDay,
    String? location,
    required DateTime rangeFrom,
    required DateTime rangeTo,
  }) async {
    final session = await sessionProvider();
    if (session == null || summary.trim().isEmpty) return;
    busyId = existing == null ? 'new-calendar-event' : existing.id;
    notifyListeners();
    final result = await _api.saveCalendarEvent(
      session,
      existing: existing,
      summary: summary.trim(),
      start: start,
      end: end,
      allDay: allDay,
      location: location,
    );
    if (result is LinkSuccess<void>) {
      error = null;
      calendarEvents = null;
      await loadCalendar(rangeFrom, rangeTo);
    } else if (result case LinkFailure<void> failure) {
      error = failure.message;
    }
    busyId = null;
    notifyListeners();
  }

  Future<void> deleteCalendarEvent(
    MobileCalendarEvent event,
    DateTime rangeFrom,
    DateTime rangeTo,
  ) async {
    final session = await sessionProvider();
    if (session == null) return;
    busyId = event.id;
    notifyListeners();
    final result = await _api.deleteCalendarEvent(session, event.id);
    if (result is LinkSuccess<void>) {
      error = null;
      calendarEvents = null;
      await loadCalendar(rangeFrom, rangeTo);
    } else if (result case LinkFailure<void> failure) {
      error = failure.message;
    }
    busyId = null;
    notifyListeners();
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
      if (success.value == 0) {
        error = 'clipboard_no_devices';
      } else {
        notice = 'clipboard:${success.value}';
        error = null;
      }
    } else if (result case LinkFailure<int> failure) {
      error = failure.message;
    }
    busyId = null;
    notifyListeners();
  }

  Future<bool> sendSharedContent(
    MobileShareTarget target,
    SharedContent content,
  ) async {
    if (busyId == 'share') return false;
    final session = await sessionProvider();
    if (session == null) return false;
    busyId = 'share';
    error = null;
    final cancellation = content.kind == SharedContentKind.file
        ? LinkTransferCancellation()
        : null;
    _fileTransferCancellation = cancellation;
    activeFileTransferId = cancellation == null ? null : 'outgoing';
    fileTransferProgress = cancellation == null ? null : 0;
    notifyListeners();
    final result = await _api.relayShare(
      session,
      target,
      content,
      cancellation: cancellation,
      onProgress: cancellation == null ? null : _updateFileTransferProgress,
    );
    final sent = result is LinkSuccess<void>;
    if (sent) {
      notice = 'share:${target.name}';
      await _recordTransfer(TransferDirection.sent, content.kind, target.name);
    } else if (result case LinkFailure<void> failure
        when failure.kind != LinkFailureKind.cancelled) {
      error = failure.message;
    }
    busyId = null;
    _finishFileTransfer(cancellation);
    notifyListeners();
    return sent;
  }

  Future<bool> acceptSharedFile(
    PendingShareOffer offer,
    ConnectionController connection,
  ) async {
    final session = await sessionProvider();
    if (session == null ||
        offer.transferId == null ||
        offer.size == null ||
        offer.sha256 == null) {
      return false;
    }
    busyId = 'receive:${offer.eventId}';
    error = null;
    final cancellation = LinkTransferCancellation();
    _fileTransferCancellation = cancellation;
    activeFileTransferId = offer.eventId;
    fileTransferProgress = 0;
    notifyListeners();
    DownloadedLinkFile? downloaded;
    String? temporaryPath;
    var savedSuccessfully = false;
    try {
      temporaryPath = await connection.createIncomingTemporaryFilePath();
      final result = await _api.downloadSharedFile(
        session,
        offer.transferId!,
        destinationPath: temporaryPath,
        expectedSize: offer.size!,
        expectedSha256: offer.sha256!,
        cancellation: cancellation,
        onProgress: _updateFileTransferProgress,
      );
      if (result case LinkSuccess<DownloadedLinkFile> success) {
        downloaded = success.value;
        final saved = await connection.saveIncomingFile(
          offer,
          downloaded.file.path,
        );
        if (!saved) {
          error = 'This file offer is no longer available.';
        } else {
          savedSuccessfully = true;
          notice = 'file:${offer.filename ?? ''}';
          await _recordTransfer(
            TransferDirection.received,
            SharedContentKind.file,
            offer.sourceName,
          );
        }
      } else if (result case LinkFailure<DownloadedLinkFile> failure
          when failure.kind != LinkFailureKind.cancelled) {
        error = failure.message;
      }
    } on PlatformException catch (exception) {
      error = exception.message?.trim().isNotEmpty == true
          ? exception.message!.trim()
          : 'The shared file could not be saved. Please try again.';
    } on Object {
      error = 'The shared file could not be saved. Please try again.';
    } finally {
      if (downloaded != null) {
        try {
          await downloaded.file.delete();
        } on Object {
          // Saving succeeded or already has a useful error for the user.
        }
      } else if (temporaryPath != null) {
        try {
          await File(temporaryPath).delete();
        } on Object {
          // Download failures already have an actionable user-facing error.
        }
      }
      busyId = null;
      _finishFileTransfer(cancellation);
      notifyListeners();
    }
    return savedSuccessfully;
  }

  void cancelFileTransfer() => _fileTransferCancellation?.cancel();

  void _updateFileTransferProgress(int transferred, int total) {
    if (total <= 0) return;
    final next = (transferred / total).clamp(0.0, 1.0);
    final previous = fileTransferProgress ?? 0;
    if (next < 1 && next - previous < .01) return;
    fileTransferProgress = next;
    notifyListeners();
  }

  void _finishFileTransfer(LinkTransferCancellation? cancellation) {
    if (!identical(_fileTransferCancellation, cancellation)) return;
    _fileTransferCancellation = null;
    activeFileTransferId = null;
    fileTransferProgress = null;
  }

  Future<void> acceptIncomingTextOrUrl(
    PendingShareOffer offer,
    ConnectionController connection,
  ) async {
    try {
      if (!await connection.acceptIncomingTextOrUrl(offer)) return;
      await _recordTransfer(
        TransferDirection.received,
        offer.kind,
        offer.sourceName,
      );
    } on Object {
      error = 'The incoming item could not be opened. Please try again.';
      notifyListeners();
    }
  }

  Future<void> clearTransferActivity() async {
    transferActivity = const [];
    notifyListeners();
    final scope = _activityScope;
    if (scope == null) return;
    try {
      await _activityStore.clear(scope);
    } on Object {
      // Transfer history is optional and must never affect the connection.
    }
  }

  Future<void> _loadTransferActivity() async {
    final session = await sessionProvider();
    if (session == null) return;
    final scope = _scopeFor(session);
    _activityScope = scope;
    try {
      transferActivity = await _activityStore.read(scope);
    } on Object {
      transferActivity = const [];
    }
  }

  Future<void> _recordTransfer(
    TransferDirection direction,
    SharedContentKind kind,
    String peerName,
  ) async {
    var scope = _activityScope;
    if (scope == null) {
      final session = await sessionProvider();
      if (session == null) return;
      scope = _scopeFor(session);
      _activityScope = scope;
    }
    transferActivity = [
      TransferActivity(
        direction: direction,
        kind: kind,
        peerName: peerName,
        at: DateTime.now(),
      ),
      ...transferActivity,
    ].take(20).toList(growable: false);
    notifyListeners();
    try {
      await _activityStore.write(scope, transferActivity);
    } on Object {
      // The confirmed transfer succeeded even when optional history cannot save.
    }
  }

  String _scopeFor(AuthenticatedLinkSession session) => sha256
      .convert(utf8.encode('${session.serverId}:${session.credential}'))
      .toString();

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
    _clipboardTimer?.cancel();
    super.dispose();
  }
}
