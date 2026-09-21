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
      'Your day, services and HomePlace connections at a glance.';

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
      'Search your connected Sonarr and Radarr libraries.';

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
  String get loadingHome => 'Bringing your HomePlace together…';

  @override
  String get preparingShare => 'Preparing devices for secure sharing…';

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
  String get transfersSubtitle =>
      'Review every incoming item and choose exactly where outgoing content is sent.';

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
      'Check for clipboard, text, links and files while HomePlace is closed. Tap a private notification to review and confirm. Clipboard sending still requires the app open.';

  @override
  String get seamlessOwnAccountTransfers => 'Seamless files from my devices';

  @override
  String get seamlessOwnAccountTransfersBody =>
      'Automatically accept and save verified files sent by another device on your account while HomePlace is open. Family devices, links, text and clipboard still require confirmation.';

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
}
