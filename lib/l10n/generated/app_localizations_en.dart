// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HomePlace';

  @override
  String get savedConnectionTitle => 'Your HomePlace is saved';

  @override
  String get savedConnectionUnavailable =>
      'The server is unavailable right now. Your connection is still saved.';

  @override
  String get retryConnection => 'Try connecting again';

  @override
  String get changeServerAddress => 'Use another address';

  @override
  String get plantsTitle => 'Your plants';

  @override
  String get plantsSubtitle => 'A calmer way to care for what grows at home.';

  @override
  String get plantsEmpty => 'Add your first plant and its watering rhythm.';

  @override
  String get plantsSeeAll => 'See all';

  @override
  String get plantsAdd => 'Add plant';

  @override
  String get plantsName => 'Name';

  @override
  String get plantsSpecies => 'Plant or species';

  @override
  String get plantsRoom => 'Room or place';

  @override
  String get plantsNotes => 'Care notes';

  @override
  String get plantsPhoto => 'Add a photo';

  @override
  String get plantsChangePhoto => 'Change photo';

  @override
  String get plantsGallery => 'Choose from gallery';

  @override
  String get plantsCamera => 'Take a photo';

  @override
  String plantsEveryDays(int days) {
    return 'Water every $days days';
  }

  @override
  String get plantsEveryDay => 'Water every day';

  @override
  String get plantsInterval => 'Watering interval';

  @override
  String get plantsLastWatered => 'Last watered';

  @override
  String get plantsWaterNow => 'Watered now';

  @override
  String get plantsWatered => 'Watering recorded';

  @override
  String get plantsUndo => 'Undo';

  @override
  String get plantsDueToday => 'Water today';

  @override
  String plantsOverdue(int days) {
    return 'Overdue by $days days';
  }

  @override
  String plantsDueIn(int days) {
    return 'In $days days';
  }

  @override
  String plantsDueCount(int count) {
    return '$count need water';
  }

  @override
  String get plantsAllGood => 'All cared for';

  @override
  String get plantsEdit => 'Edit plant';

  @override
  String get plantsSave => 'Save plant';

  @override
  String get plantsDelete => 'Delete plant';

  @override
  String get plantsDeleteConfirm =>
      'Delete this plant and its photo from this device?';

  @override
  String get plantsLocalOnly =>
      'Plant cards stay in this app\'s private storage for this connection. They are not sent to HomePlace.';

  @override
  String get plantsLoadError => 'Plant cards could not be loaded. Try again.';

  @override
  String get plantsSynced => 'Plants are synced with your HomePlace account.';

  @override
  String get plantsSyncNeedsAttention => 'Plant sync needs attention.';

  @override
  String get plantsSyncError =>
      'Could not sync plants. Check the connection and device permission, then retry. Your changes are kept on this device.';

  @override
  String plantsPending(int count) {
    return 'Waiting to sync: $count';
  }

  @override
  String plantsLocalAvailable(int count) {
    return 'Local-only plants: $count';
  }

  @override
  String get plantsImportTitle => 'Add local plants to HomePlace?';

  @override
  String plantsImportConfirm(int count) {
    return 'Add $count local plant cards to this HomePlace account? The original cards and photos stay on this device.';
  }

  @override
  String get plantsImport => 'Add to HomePlace';

  @override
  String get plantsConflict =>
      'This plant changed on another device. Choose which version to keep.';

  @override
  String get plantsUseServer => 'Use server version';

  @override
  String get plantsKeepMine => 'Keep my changes';

  @override
  String get plantsUseServerConfirm =>
      'Discard this phone\'s pending change and keep the server version?';

  @override
  String get plantsKeepMineConfirm =>
      'Retry this phone\'s change over the latest server version? This may replace another device\'s edit.';

  @override
  String get plantsPhotosLocal =>
      'Photos of synced plants can be stored privately in this account. Local originals remain on this device.';

  @override
  String get plantsImportPhotos =>
      'Also upload existing photos to this account';

  @override
  String get plantsReminderSettings => 'Watering alerts';

  @override
  String get plantsReminderSettingsHint =>
      'HomePlace sends alerts for overdue plants. Telegram uses the chat configured on your server and may be visible to others there.';

  @override
  String get plantsRemindersEnabled => 'Enable watering alerts';

  @override
  String get plantsReminderApp => 'HomePlace notifications';

  @override
  String get plantsReminderTelegram => 'Telegram';

  @override
  String get plantsReminderTime => 'Time of day';

  @override
  String plantsReminderRepeatDays(int days) {
    return 'Repeat while overdue, every $days days';
  }

  @override
  String get plantsReminderOnce => 'Notify once per watering cycle';

  @override
  String get plantsReminderSave => 'Save alert settings';

  @override
  String get plantsPlantReminders => 'Remind me to water this plant';

  @override
  String get plantsReminderUnavailable =>
      'Plant alerts need an updated HomePlace server and device permission.';

  @override
  String get plantsLocalAndShared =>
      'Shared cards sync with your account. Local-only cards are sent only if you choose to import them.';

  @override
  String get plantsDeleteSharedConfirm =>
      'Delete this plant from your HomePlace account? Photos on this device are kept.';

  @override
  String get plantsSaveError => 'Could not save the plant. Try again.';

  @override
  String get plantsPhotoError =>
      'Could not use this photo. Choose a smaller image.';

  @override
  String get plantsPickDate => 'Choose date';

  @override
  String get welcomeTitle => 'Your HomePlace, on your phone';

  @override
  String get welcomeBody =>
      'Connect securely to the HomePlace server you host.';

  @override
  String get getStarted => 'Get started';

  @override
  String get connectTitle => 'Connect to HomePlace';

  @override
  String get connectBody =>
      'Enter an HTTPS domain, local hostname, local IP address, or scan a HomePlace QR code.';

  @override
  String get serverAddress => 'Server address';

  @override
  String get serverHint => 'home.example.net or 192.168.1.20:3200';

  @override
  String get continueAction => 'Continue';

  @override
  String get scanQr => 'Scan QR code';

  @override
  String get cameraExplanation =>
      'HomePlace uses the camera only while scanning a connection QR code.';

  @override
  String get allowCamera => 'Allow camera';

  @override
  String get checkingServer => 'Checking server…';

  @override
  String get serverVerified => 'Server verified';

  @override
  String get readyToPair => 'Ready to pair';

  @override
  String get secureConnection => 'Encrypted HTTPS connection';

  @override
  String get localHttpWarning => 'Unencrypted local-network connection';

  @override
  String get selfSignedWarning =>
      'The certificate is not publicly trusted. Confirm this SHA-256 fingerprint only if it matches your HomePlace server:';

  @override
  String get trustCertificate => 'Trust this certificate';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverId => 'Server ID';

  @override
  String get security => 'Security';

  @override
  String get protocol => 'Link protocol';

  @override
  String get pair => 'Pair this device';

  @override
  String get pairingUnavailable =>
      'This server version does not provide device pairing yet.';

  @override
  String get notificationExplanation =>
      'Allow notifications so HomePlace can deliver test and device notifications. The capability is not advertised when permission is unavailable.';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get notNow => 'Not now';

  @override
  String get pairingTitle => 'Approve this phone';

  @override
  String get pairingBody =>
      'Open Devices in the HomePlace web interface and approve the request with this code.';

  @override
  String get pairingCode => 'Confirmation code';

  @override
  String get cancel => 'Cancel';

  @override
  String get connected => 'Connected';

  @override
  String get connectedBody =>
      'This device is registered with HomePlace. Presence and incoming events are active while the app is open.';

  @override
  String get lastNotification => 'Last notification';

  @override
  String get disconnect => 'Disconnect and revoke';

  @override
  String get useAnotherAddress => 'Use another address';

  @override
  String get retry => 'Try again';

  @override
  String get diagnostics => 'Troubleshooting';

  @override
  String get noDiagnostics => 'No technical details are available.';

  @override
  String get close => 'Close';

  @override
  String expiresAt(String time) {
    return 'Expires at $time';
  }

  @override
  String get homeTab => 'Home';

  @override
  String get calendarTab => 'Plan';

  @override
  String get requestsTab => 'Requests';

  @override
  String get transfersTab => 'Transfers';

  @override
  String get monitorTab => 'Monitor';

  @override
  String get everythingInPlace => 'Everything in its place';

  @override
  String get homeOverviewBody =>
      'Your plants and the next thing to do at home.';

  @override
  String get onlineNow => 'Online now';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get nextUp => 'Next up';

  @override
  String get nothingPlanned => 'Nothing planned yet';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get reminderTitleHint => 'What should HomePlace remind you about?';

  @override
  String get dateAndTime => 'Date and time';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatNone => 'Does not repeat';

  @override
  String get repeatHourly => 'Every hour';

  @override
  String get repeatDaily => 'Every day';

  @override
  String get repeatWeekly => 'Every week';

  @override
  String get repeatMonthly => 'Every month';

  @override
  String get repeatYearly => 'Every year';

  @override
  String repeatInterval(int count, String unit) {
    return 'Every $count $unit';
  }

  @override
  String get repeatUnitHour => 'hours';

  @override
  String get repeatUnitDay => 'days';

  @override
  String get repeatUnitWeek => 'weeks';

  @override
  String get repeatUnitMonth => 'months';

  @override
  String get repeatUnitYear => 'years';

  @override
  String customRepeat(String rule) {
    return 'Custom: $rule';
  }

  @override
  String get save => 'Save';

  @override
  String get complete => 'Complete';

  @override
  String get delete => 'Delete';

  @override
  String get calendarNotConnected =>
      'Connect Google Calendar in HomePlace settings to see events here.';

  @override
  String get noCalendarEvents => 'No upcoming calendar events.';

  @override
  String get addCalendarEvent => 'Add event';

  @override
  String get editCalendarEvent => 'Edit event';

  @override
  String get eventTitle => 'Event title';

  @override
  String get eventLocation => 'Location (optional)';

  @override
  String get eventStarts => 'Starts';

  @override
  String get eventEnds => 'Ends';

  @override
  String get noEventsOnDay => 'Nothing planned for this day.';

  @override
  String get deleteCalendarEventTitle => 'Delete event?';

  @override
  String deleteCalendarEventBody(String title) {
    return '“$title” will be removed from your calendar.';
  }

  @override
  String get repeatFlexible => 'Custom interval';

  @override
  String get repeatEvery => 'Every';

  @override
  String get requestsTitle => 'Media requests';

  @override
  String get requestsBody =>
      'Discover films and series, then send requests through HomePlace.';

  @override
  String get mediaAll => 'All';

  @override
  String get mediaAutomation => 'Sonarr, Radarr and download queues';

  @override
  String get mediaMovies => 'Films';

  @override
  String get mediaSeries => 'Series';

  @override
  String get mediaAnime => 'Anime';

  @override
  String get mediaQuality => 'Quality profile';

  @override
  String get mediaDefaultQuality => 'Server default';

  @override
  String get mediaSeasons => 'Seasons';

  @override
  String get mediaAllSeasonsHint =>
      'Leave all unselected to request every season.';

  @override
  String get mediaRequested => 'Request sent to HomePlace.';

  @override
  String get mediaPermissionNeeded =>
      'Enable media.request for this device in HomePlace Devices to browse the catalog.';

  @override
  String get mediaNotConfigured =>
      'Set up Seerr in HomePlace to browse the catalog.';

  @override
  String get mediaUnavailable =>
      'The media service is temporarily unavailable. Try again later.';

  @override
  String get mediaNoResults => 'No titles found. Try another search.';

  @override
  String get mediaPrevious => 'Previous page';

  @override
  String get mediaNext => 'Next page';

  @override
  String mediaStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get mediaAvailable => 'Available';

  @override
  String get mediaPartiallyAvailable => 'Partially available';

  @override
  String get mediaAlreadyRequested => 'Requested';

  @override
  String get mediaPending => 'Pending approval';

  @override
  String get mediaMissing => 'Not requested';

  @override
  String get searchMedia => 'Search films and series';

  @override
  String get search => 'Search';

  @override
  String get request => 'Request';

  @override
  String get inLibrary => 'In library';

  @override
  String get noMediaServices =>
      'Connect Sonarr or Radarr in HomePlace settings first.';

  @override
  String requestSent(String title) {
    return 'Request sent: $title';
  }

  @override
  String get queue => 'Queue';

  @override
  String get upcomingMedia => 'Upcoming';

  @override
  String get downloads => 'Downloads';

  @override
  String activeDownloads(int count) {
    return '$count active';
  }

  @override
  String get monitoringTitle => 'Small but watchful';

  @override
  String get monitoringBody =>
      'A live summary of the checks HomePlace already runs.';

  @override
  String get monitorOverviewTab => 'Overview';

  @override
  String get monitorServicesTab => 'Services';

  @override
  String get monitorContainersTab => 'Containers';

  @override
  String get monitorEventsTab => 'Events';

  @override
  String get monitoredChecksExplanation =>
      'Availability checks, not Docker containers.';

  @override
  String get containerSummary => 'Docker containers';

  @override
  String get totalContainers => 'Total';

  @override
  String get runningContainers => 'Running';

  @override
  String get stoppedContainers => 'Stopped';

  @override
  String get containerProblems => 'Problems';

  @override
  String get noContainers =>
      'No Docker containers are available from the configured hosts.';

  @override
  String get containerRunning => 'Running';

  @override
  String get containerExited => 'Exited';

  @override
  String get containerPaused => 'Paused';

  @override
  String get containerRestarting => 'Restarting';

  @override
  String get containerDead => 'Dead';

  @override
  String get containerCreated => 'Created';

  @override
  String get unknownState => 'Unknown';

  @override
  String get serviceOnline => 'Online';

  @override
  String get serviceOffline => 'Offline';

  @override
  String get averageLatency => 'Average latency';

  @override
  String lastChecked(String time) {
    return 'Checked $time';
  }

  @override
  String get noRecentEvents => 'No recent monitoring events.';

  @override
  String onlineCount(int online, int total) {
    return '$online of $total online';
  }

  @override
  String get allQuiet => 'All quiet';

  @override
  String get recentEvents => 'Recent events';

  @override
  String get noMonitors =>
      'Add availability checks to dashboard tiles to see them here.';

  @override
  String get telegramTitle => 'Telegram bridge';

  @override
  String get telegramConnected => 'Connected and ready';

  @override
  String get telegramDisconnected => 'Not configured on the server';

  @override
  String get telegramTest => 'Send test';

  @override
  String get telegramSent => 'A test message was sent to Telegram.';

  @override
  String get refresh => 'Refresh';

  @override
  String get settings => 'Connection settings';

  @override
  String get preparingShare => 'Preparing devices for secure sharing…';

  @override
  String get quickShareTitle => 'Share with HomePlace';

  @override
  String get quickShareWaiting =>
      'Your selection is ready. Connecting to your HomePlace…';

  @override
  String get tryAgain => 'Try again';

  @override
  String get errorDetails => 'Something needs attention';

  @override
  String get dismissError => 'Dismiss';

  @override
  String get permissionsRequired =>
      'Reconnect this device to approve the new mobile permissions.';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get allDay => 'All day';

  @override
  String get clipboardTitle => 'Clipboard relay';

  @override
  String get clipboardBody =>
      'Send the current Android clipboard to your other approved devices.';

  @override
  String get clipboardSend => 'Send clipboard';

  @override
  String clipboardIncoming(String device) {
    return 'Clipboard from $device';
  }

  @override
  String get clipboardCopy => 'Copy';

  @override
  String get clipboardDismiss => 'Dismiss';

  @override
  String clipboardSent(int count) {
    return 'Clipboard sent to $count device(s).';
  }

  @override
  String get clipboardEmpty => 'The clipboard does not contain text.';

  @override
  String get clipboardNoDevices =>
      'No other compatible device is connected to this account.';

  @override
  String get automaticClipboard => 'Send clipboard automatically';

  @override
  String get automaticClipboardBody =>
      'While HomePlace is open, send changed text to your approved devices. Incoming text still requires confirmation.';

  @override
  String automaticClipboardSent(int count) {
    return 'New clipboard text was sent to $count device(s).';
  }

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Russian';

  @override
  String get appearance => 'Appearance';

  @override
  String get appVersion => 'App version';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get connectionSecurity => 'Connection security';

  @override
  String get localUnencryptedConnection =>
      'Unencrypted local-network connection';

  @override
  String get serverIdentity => 'Server ID';

  @override
  String get readyToShare => 'Ready to share';

  @override
  String get choose => 'Choose';

  @override
  String get chooseDevice => 'Choose a device';

  @override
  String get onlyYourDevices =>
      'Your devices stay account-isolated. Household devices appear only when their owner explicitly allows sharing.';

  @override
  String get noShareDevices => 'No compatible approved devices are available.';

  @override
  String get yourDevice => 'Your device';

  @override
  String householdDevice(String owner) {
    return 'Household · $owner';
  }

  @override
  String get deviceOnline => 'Online now';

  @override
  String get deviceOffline => 'May receive it when HomePlace is opened';

  @override
  String get confirmShareTitle => 'Send this item?';

  @override
  String confirmShareBody(String device) {
    return 'HomePlace will send it only to $device. The offer expires in 30 minutes.';
  }

  @override
  String confirmMultipleShareBody(int count, String device) {
    return 'HomePlace will send $count items only to $device. Each offer expires in 30 minutes.';
  }

  @override
  String confirmMultipleHouseholdShareBody(
    int count,
    String owner,
    String device,
  ) {
    return 'This device belongs to $owner. HomePlace will send $count items only to $device after you confirm. Each offer expires in 30 minutes.';
  }

  @override
  String confirmHouseholdShareBody(String owner, String device) {
    return 'This device belongs to $owner. HomePlace will send the item only to $device after you confirm. The offer expires in 30 minutes.';
  }

  @override
  String get send => 'Send';

  @override
  String shareSent(String device) {
    return 'Sent to $device.';
  }

  @override
  String itemsReadyToShare(int count) {
    return '$count items ready to send';
  }

  @override
  String get transfersTitle => 'Transfers';

  @override
  String get sendFromPhone => 'Send from this phone';

  @override
  String get sendFromPhoneHint =>
      'Choose files, then pick a device and confirm. Nothing is sent automatically.';

  @override
  String get choosePhotos => 'Photos';

  @override
  String get chooseFiles => 'Files';

  @override
  String get preparingFiles => 'Preparing files on this device…';

  @override
  String get transfersSubtitle =>
      'Review every incoming item and choose exactly where outgoing content is sent.';

  @override
  String get exchangeTitle => 'Temporary text link';

  @override
  String get exchangeSubtitle =>
      'Share text with another device signed in to your HomePlace account. Direct device transfers remain separate.';

  @override
  String get exchangeOpen => 'Open temporary links';

  @override
  String get exchangeText => 'Text to share';

  @override
  String get exchangeAccountOnly =>
      'Only your HomePlace account can open this link. Anyone with the link and access to your account may read it.';

  @override
  String get exchangeExpiry => 'Link expires after';

  @override
  String get exchangeTenMinutes => '10 minutes';

  @override
  String get exchangeOneHour => '1 hour';

  @override
  String get exchangeOneDay => '1 day';

  @override
  String get exchangeOneTime => 'Remove after first open';

  @override
  String get exchangeOneTimeWarning =>
      'An interrupted first open cannot be retried.';

  @override
  String get exchangeCreate => 'Create private link';

  @override
  String get exchangeActive => 'Active text links';

  @override
  String get exchangeEmpty => 'No active text links.';

  @override
  String get exchangeTextLink => 'Private text link';

  @override
  String get exchangeReusable => 'Reusable until expiry';

  @override
  String get exchangeCopy => 'Copy link';

  @override
  String get exchangeCopied => 'Link copied. Treat it as a secret.';

  @override
  String get exchangeClipboardWarning =>
      'Automatic clipboard sharing is on. Copying this link may send it to your approved devices.';

  @override
  String get exchangeRevoke => 'Revoke link';

  @override
  String get exchangeRevokeConfirm =>
      'This link will stop working immediately. Revoke it?';

  @override
  String get exchangeReconnect => 'Reconnect to HomePlace and try again.';

  @override
  String get fileExchangeTitle => 'File exchange';

  @override
  String get fileExchangeSubtitle =>
      'Upload a file, then share a short-lived download link. Direct device transfers stay separate.';

  @override
  String get fileExchangeOpen => 'Open file exchange';

  @override
  String get fileExchangeChoose => 'Choose any file';

  @override
  String fileExchangeSizeError(String limit) {
    return 'Choose a non-empty file within this server\'s $limit upload limit.';
  }

  @override
  String fileExchangeLimit(String limit) {
    return 'Current server limit: $limit';
  }

  @override
  String get fileExchangePickError =>
      'The file could not be opened. Choose it again.';

  @override
  String get fileExchangeAccess => 'Who can download';

  @override
  String get fileExchangeAccount => 'My HomePlace account';

  @override
  String get fileExchangePublic => 'Anyone with the link';

  @override
  String get fileExchangePublicWarning =>
      'This link is a secret. Anyone who gets it can download the file until it expires or you revoke it. Do not use it for private files unless you trust every recipient.';

  @override
  String get fileExchangeQuick => 'Quick one-time code';

  @override
  String get fileExchangeQuickWarning =>
      'Public · 10 minutes · one download. Interrupted downloads cannot resume.';

  @override
  String get fileExchangeCode => 'Code';

  @override
  String get fileExchangeConfirmPublic => 'Create external link';

  @override
  String get fileExchangeUpload => 'Upload and create link';

  @override
  String get fileExchangeActive => 'Active file links';

  @override
  String get fileExchangeEmpty => 'No active file links.';

  @override
  String get fileExchangeReceive => 'Save a file from a link';

  @override
  String get fileExchangeLink => 'Link from this HomePlace server';

  @override
  String get fileExchangeCheck => 'Check file';

  @override
  String get fileExchangeInvalidLink =>
      'Enter a 22-character file token, a five-character quick code, or a link from this HomePlace server.';

  @override
  String get fileExchangeDownload => 'Download to Downloads';

  @override
  String get fileExchangeSaveConfirm =>
      'Confirm to download and save this file on your phone.';

  @override
  String get fileExchangeOneTimeWarning =>
      'This link works only once. Starting the download uses it, even if the transfer is interrupted.';

  @override
  String get fileExchangeSaveError =>
      'The file could not be saved. Check Downloads before trying again.';

  @override
  String get fileExchangeOpenSaved => 'Open saved file';

  @override
  String get fileExchangeOpenError => 'Android could not open the saved file.';

  @override
  String get noPendingTransfers =>
      'No transfers need your attention right now.';

  @override
  String outgoingItems(int count) {
    return 'Waiting to send · $count';
  }

  @override
  String get waitingToSend => 'Waiting for a device';

  @override
  String get remove => 'Remove';

  @override
  String get recentTransfers => 'Recent transfers';

  @override
  String get clearHistory => 'Clear';

  @override
  String get transferHistoryPrivacy =>
      'Stored securely for this device profile. Shared content and filenames are never saved here.';

  @override
  String transferSentTo(String device) {
    return 'Sent to $device';
  }

  @override
  String transferReceivedFrom(String device) {
    return 'Received from $device';
  }

  @override
  String incomingShare(String device) {
    return 'From $device';
  }

  @override
  String incomingOffers(int count) {
    return 'Incoming items · $count';
  }

  @override
  String moreIncomingOffers(int count) {
    return '+$count more incoming item(s)';
  }

  @override
  String get decline => 'Decline';

  @override
  String get acceptAndSave => 'Accept and save';

  @override
  String get open => 'Open';

  @override
  String fileSaved(String filename) {
    return 'Saved $filename to Downloads/HomePlace.';
  }

  @override
  String get savedFileReady => 'Ready in Downloads';

  @override
  String savedFileActions(String filename) {
    return 'Downloaded $filename. Tap to open; hold to open its folder.';
  }

  @override
  String get openDownloadsFolder => 'Open folder';

  @override
  String get downloadsFolderUnavailable =>
      'Android could not open Downloads/HomePlace. Find it in your Files app.';

  @override
  String get upcomingReminders => 'Upcoming';

  @override
  String get overdueReminders => 'Past due';

  @override
  String get completedReminders => 'Completed';

  @override
  String get overdue => 'Overdue';

  @override
  String get editReminder => 'Edit reminder';

  @override
  String get restore => 'Restore';

  @override
  String get clearCompleted => 'Clear completed';

  @override
  String get deleteReminderTitle => 'Delete reminder?';

  @override
  String deleteReminderBody(String title) {
    return '“$title” will be permanently deleted.';
  }

  @override
  String get clearCompletedTitle => 'Clear completed reminders?';

  @override
  String get clearCompletedBody =>
      'All completed reminders for this account will be permanently deleted.';

  @override
  String get homePlaceProfiles => 'HomePlace connections';

  @override
  String get activeProfile => 'Active';

  @override
  String get connectAnotherHomePlace => 'Connect another HomePlace';

  @override
  String get cancelAddingConnection => 'Back to the connected HomePlace';

  @override
  String get backgroundDelivery => 'Background HomePlace checks';

  @override
  String get backgroundDeliveryBody =>
      'Android checks connected HomePlace servers about every 15 minutes. The system may delay checks to save battery.';

  @override
  String get backgroundIncomingOffers => 'Incoming items in background';

  @override
  String get backgroundIncomingOffersBody =>
      'Check for clipboard, text, links and files while HomePlace is closed. Accepting a file queues a verified background download; text, links and clipboard still open HomePlace for confirmation.';

  @override
  String get seamlessOwnAccountTransfers => 'Seamless files from my devices';

  @override
  String get seamlessOwnAccountTransfersBody =>
      'Automatically accept and save verified files sent by another device on your account, including during enabled background checks. Family devices, links, text and clipboard still require confirmation.';

  @override
  String get notificationPermissionRequired =>
      'Allow HomePlace notifications in Android settings to enable background delivery.';

  @override
  String get lastBackgroundCheck => 'Last background check';

  @override
  String get backgroundNeverRun =>
      'Waiting for Android to run the first check.';

  @override
  String backgroundCheckedProfiles(String time, int count) {
    return '$time · Checked $count connection(s)';
  }

  @override
  String backgroundCheckFailed(String time) {
    return '$time · The check could not finish and will be retried.';
  }

  @override
  String get notificationHistory => 'Notification history';

  @override
  String get notificationHistoryPrivacy =>
      'Stored in encrypted device storage for this HomePlace profile only.';

  @override
  String get viewAll => 'View all';

  @override
  String get allSections => 'All sections';

  @override
  String get allSectionsBody =>
      'The spaces beyond your main tabs. Keep only what you use.';

  @override
  String get customizeSections => 'Customize sections';

  @override
  String get customizeSectionsBody =>
      'Choose what appears here. Your main tabs stay in place.';

  @override
  String get restoreSections => 'Show all sections';

  @override
  String get hiddenSectionsEmpty =>
      'No extra sections are visible. Use Customize to bring them back.';

  @override
  String get everydaySection => 'Every day';

  @override
  String get sharingSection => 'Devices and sharing';

  @override
  String get servicesSection => 'Home and services';

  @override
  String get systemSection => 'System';

  @override
  String get availableNow => 'Available now';

  @override
  String get preview => 'Preview';

  @override
  String get configureOnServer =>
      'Configure in the HomePlace web control center';

  @override
  String get devicesTitle => 'Devices';

  @override
  String get devicesBody =>
      'Presence, ownership and the actions each paired device actually supports.';

  @override
  String get shareCapableDevices => 'Available for sharing';

  @override
  String get noLinkedDevices =>
      'No other compatible devices are currently available.';

  @override
  String get capabilities => 'Capabilities';

  @override
  String get clipboardModuleBody =>
      'Private text handoff with confirmation and loop protection.';

  @override
  String get notificationsModuleBody =>
      'Delivery history and sensitive action approvals for this profile.';

  @override
  String get automationsTitle => 'Automations';

  @override
  String get automationsBody =>
      'Connect explicit events and actions without giving devices unrestricted control.';

  @override
  String get automationArrival => 'When I arrive home';

  @override
  String get automationArrivalAction => 'Turn on the hallway scene';

  @override
  String get automationDownload => 'When a download finishes';

  @override
  String get automationDownloadAction => 'Notify my phone';

  @override
  String get automationBattery => 'When server power is low';

  @override
  String get automationBatteryAction => 'Send a Telegram alert';

  @override
  String get automationSafety =>
      'Every rule lists its trigger, target and required permission before it can be enabled.';

  @override
  String get smartHomeTitle => 'Smart home';

  @override
  String get smartHomeBody =>
      'Rooms, scenes, sensors and safe controls from the Home Assistant connection managed by HomePlace.';

  @override
  String get smartHomeEmpty =>
      'Connect Home Assistant on the server to show real rooms and controls here.';

  @override
  String get rooms => 'Rooms';

  @override
  String get scenes => 'Scenes';

  @override
  String get sensors => 'Sensors';

  @override
  String get securityCenter => 'Security and privacy';

  @override
  String get securityCenterBody =>
      'Review server identity, transport security, account isolation and approved permissions.';

  @override
  String get accountIsolation => 'Account-isolated sharing';

  @override
  String get accountIsolationBody =>
      'Content is routed only to the selected approved device. Household transfers always require confirmation.';

  @override
  String get explicitCapabilities => 'Explicit capabilities';

  @override
  String get explicitCapabilitiesBody =>
      'The phone advertises only actions supported by this operating system and current permissions.';

  @override
  String get verifiedIdentity => 'Verified server identity';

  @override
  String get verifiedIdentityBody =>
      'HomePlace checks the server ID on reconnect and never silently accepts an invalid certificate.';

  @override
  String get openSection => 'Open section';

  @override
  String get manageSettings => 'Manage settings';

  @override
  String get calendarModuleBody =>
      'Calendar, reminders, plants and ideas in one place.';

  @override
  String get mediaModuleBody =>
      'Search Radarr and Sonarr and follow download queues.';

  @override
  String get transfersModuleBody =>
      'Send and receive text, links and files with an explicit recipient.';

  @override
  String get monitoringModuleBody =>
      'Availability checks, Docker containers, service latency and events.';

  @override
  String get telegramModuleBody =>
      'Server-managed alerts and a connection test.';

  @override
  String get settingsModuleBody =>
      'Language, appearance, background delivery, profiles and connection security.';

  @override
  String get privateWorkspace => 'Private workspace';

  @override
  String get plannedServerApi => 'Waiting for a compatible server API';

  @override
  String get ideasTitle => 'Ideas';

  @override
  String get ideasSubtitle => 'Catch a thought before it slips away.';

  @override
  String get ideasLocalOnly =>
      'Only on this phone. This device has not been granted access to account ideas.';

  @override
  String get ideasServerSynced =>
      'Saved to your HomePlace account and available on your devices.';

  @override
  String get ideasSyncUnavailable =>
      'Account ideas are unavailable right now. Phone ideas have not been uploaded.';

  @override
  String get ideasImportLocal => 'Import phone ideas';

  @override
  String get ideasImportPrompt =>
      'Copy ideas saved on this phone to your HomePlace account? Existing phone copies will stay private on this device.';

  @override
  String get ideasImportDone => 'Phone ideas imported to HomePlace.';

  @override
  String get ideasModuleBody =>
      'Private quick capture, categories and reminder handoff.';

  @override
  String get ideasCaptureHint => 'An idea, a link, or the next step…';

  @override
  String get ideasAdd => 'Save idea';

  @override
  String get ideasAll => 'All';

  @override
  String get ideasEmptyTitle => 'A clear page';

  @override
  String get ideasEmptyBody =>
      'Save your first thought here. Turn it into a reminder when it needs a date.';

  @override
  String get ideasInbox => 'Inbox';

  @override
  String get ideasHome => 'Home';

  @override
  String get ideasWork => 'Work';

  @override
  String get ideasMedia => 'Media';

  @override
  String get ideasLater => 'Later';

  @override
  String get ideasCategory => 'Category';

  @override
  String get ideasNewCategory => 'New category';

  @override
  String get ideasCategoryName => 'Category name';

  @override
  String get ideasCategoryExists => 'Use a different category name.';

  @override
  String get ideasEdit => 'Edit idea';

  @override
  String get ideasNote => 'Details';

  @override
  String get ideasPin => 'Pin idea';

  @override
  String get ideasUnpin => 'Unpin idea';

  @override
  String get ideasComplete => 'Mark complete';

  @override
  String get ideasReopen => 'Reopen idea';

  @override
  String get ideasPinned => 'Pinned';

  @override
  String get ideasCompleted => 'Completed';

  @override
  String get ideasActive => 'Current';

  @override
  String get ideasArchive => 'Archive';

  @override
  String get ideasArchiveAction => 'Archive idea';

  @override
  String get ideasRestore => 'Restore idea';

  @override
  String get ideasArchiveEmpty => 'No archived ideas yet.';

  @override
  String get ideasDuplicate => 'Duplicate';

  @override
  String get ideasDelete => 'Delete idea';

  @override
  String get ideasDeleteConfirm => 'Delete this idea from this phone?';

  @override
  String get ideasToReminder => 'Make reminder';

  @override
  String get ideasCopy => 'Copy text';

  @override
  String get ideasClipboardWarning =>
      'Automatic clipboard sharing is on. Copying this idea may send it to your approved devices.';

  @override
  String get ideasCopyConfirm => 'Copy anyway';

  @override
  String get ideasSaveError => 'The idea could not be saved. Try again.';

  @override
  String get ideasLoadError => 'Ideas could not be opened on this device.';

  @override
  String get ideasSave => 'Save changes';

  @override
  String get quickTransferTile => 'Add Transfers to Quick Settings';

  @override
  String get quickTransferTileBody =>
      'Open Transfers from the Samsung quick panel without starting on Home. Sending still needs confirmation.';

  @override
  String get quickTransferTileAdded => 'Transfers was added to Quick Settings.';

  @override
  String get quickTransferTileAlreadyAdded =>
      'Transfers is already in Quick Settings.';

  @override
  String get quickTransferTileNotAdded =>
      'Tile not added. You can add it manually while editing Quick Settings.';

  @override
  String get quickTransferTileUnavailable =>
      'Automatic tile setup is unavailable. Add HomePlace transfers from the Quick Settings editor.';

  @override
  String get androidNotificationSettings => 'Android notification settings';

  @override
  String get androidNotificationSettingsBody =>
      'Manage notification permission, channels and lock-screen privacy in system settings.';
}
