import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HomePlace'**
  String get appName;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your HomePlace, on your phone'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Connect securely to the HomePlace server you host.'**
  String get welcomeBody;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to HomePlace'**
  String get connectTitle;

  /// No description provided for @connectBody.
  ///
  /// In en, this message translates to:
  /// **'Enter an HTTPS domain, local hostname, local IP address, or scan a HomePlace QR code.'**
  String get connectBody;

  /// No description provided for @serverAddress.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddress;

  /// No description provided for @serverHint.
  ///
  /// In en, this message translates to:
  /// **'home.example.net or 192.168.1.20:3200'**
  String get serverHint;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQr;

  /// No description provided for @cameraExplanation.
  ///
  /// In en, this message translates to:
  /// **'HomePlace uses the camera only while scanning a connection QR code.'**
  String get cameraExplanation;

  /// No description provided for @allowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get allowCamera;

  /// No description provided for @checkingServer.
  ///
  /// In en, this message translates to:
  /// **'Checking server…'**
  String get checkingServer;

  /// No description provided for @serverVerified.
  ///
  /// In en, this message translates to:
  /// **'Server verified'**
  String get serverVerified;

  /// No description provided for @readyToPair.
  ///
  /// In en, this message translates to:
  /// **'Ready to pair'**
  String get readyToPair;

  /// No description provided for @secureConnection.
  ///
  /// In en, this message translates to:
  /// **'Encrypted HTTPS connection'**
  String get secureConnection;

  /// No description provided for @localHttpWarning.
  ///
  /// In en, this message translates to:
  /// **'Unencrypted local-network connection'**
  String get localHttpWarning;

  /// No description provided for @selfSignedWarning.
  ///
  /// In en, this message translates to:
  /// **'The certificate is not publicly trusted. Confirm this SHA-256 fingerprint only if it matches your HomePlace server:'**
  String get selfSignedWarning;

  /// No description provided for @trustCertificate.
  ///
  /// In en, this message translates to:
  /// **'Trust this certificate'**
  String get trustCertificate;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @serverId.
  ///
  /// In en, this message translates to:
  /// **'Server ID'**
  String get serverId;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @protocol.
  ///
  /// In en, this message translates to:
  /// **'Link protocol'**
  String get protocol;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair this device'**
  String get pair;

  /// No description provided for @pairingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This server version does not provide device pairing yet.'**
  String get pairingUnavailable;

  /// No description provided for @notificationExplanation.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so HomePlace can deliver test and device notifications. The capability is not advertised when permission is unavailable.'**
  String get notificationExplanation;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @pairingTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve this phone'**
  String get pairingTitle;

  /// No description provided for @pairingBody.
  ///
  /// In en, this message translates to:
  /// **'Open Devices in the HomePlace web interface and approve the request with this code.'**
  String get pairingBody;

  /// No description provided for @pairingCode.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code'**
  String get pairingCode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connectedBody.
  ///
  /// In en, this message translates to:
  /// **'This device is registered with HomePlace. Presence and incoming events are active while the app is open.'**
  String get connectedBody;

  /// No description provided for @lastNotification.
  ///
  /// In en, this message translates to:
  /// **'Last notification'**
  String get lastNotification;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect and revoke'**
  String get disconnect;

  /// No description provided for @useAnotherAddress.
  ///
  /// In en, this message translates to:
  /// **'Use another address'**
  String get useAnotherAddress;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get diagnostics;

  /// No description provided for @noDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'No technical details are available.'**
  String get noDiagnostics;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @expiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires at {time}'**
  String expiresAt(String time);

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @calendarTab.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get calendarTab;

  /// No description provided for @requestsTab.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsTab;

  /// No description provided for @monitorTab.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get monitorTab;

  /// No description provided for @everythingInPlace.
  ///
  /// In en, this message translates to:
  /// **'Everything in its place'**
  String get everythingInPlace;

  /// No description provided for @homeOverviewBody.
  ///
  /// In en, this message translates to:
  /// **'Your day, services and HomePlace connections at a glance.'**
  String get homeOverviewBody;

  /// No description provided for @onlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get onlineNow;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @nextUp.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get nextUp;

  /// No description provided for @nothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get nothingPlanned;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @reminderTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What should HomePlace remind you about?'**
  String get reminderTitleHint;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get repeatNone;

  /// No description provided for @repeatHourly.
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get repeatHourly;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get repeatYearly;

  /// No description provided for @repeatInterval.
  ///
  /// In en, this message translates to:
  /// **'Every {count} {unit}'**
  String repeatInterval(int count, String unit);

  /// No description provided for @repeatUnitHour.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get repeatUnitHour;

  /// No description provided for @repeatUnitDay.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get repeatUnitDay;

  /// No description provided for @repeatUnitWeek.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get repeatUnitWeek;

  /// No description provided for @repeatUnitMonth.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get repeatUnitMonth;

  /// No description provided for @repeatUnitYear.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get repeatUnitYear;

  /// No description provided for @customRepeat.
  ///
  /// In en, this message translates to:
  /// **'Custom: {rule}'**
  String customRepeat(String rule);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @calendarNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Calendar in HomePlace settings to see events here.'**
  String get calendarNotConnected;

  /// No description provided for @noCalendarEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming calendar events.'**
  String get noCalendarEvents;

  /// No description provided for @addCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addCalendarEvent;

  /// No description provided for @editCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get editCalendarEvent;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get eventTitle;

  /// No description provided for @eventLocation.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get eventLocation;

  /// No description provided for @eventStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get eventStarts;

  /// No description provided for @eventEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get eventEnds;

  /// No description provided for @noEventsOnDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned for this day.'**
  String get noEventsOnDay;

  /// No description provided for @deleteCalendarEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get deleteCalendarEventTitle;

  /// No description provided for @deleteCalendarEventBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be removed from your calendar.'**
  String deleteCalendarEventBody(String title);

  /// No description provided for @repeatFlexible.
  ///
  /// In en, this message translates to:
  /// **'Custom interval'**
  String get repeatFlexible;

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get repeatEvery;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Media requests'**
  String get requestsTitle;

  /// No description provided for @requestsBody.
  ///
  /// In en, this message translates to:
  /// **'Search your connected Sonarr and Radarr libraries.'**
  String get requestsBody;

  /// No description provided for @searchMedia.
  ///
  /// In en, this message translates to:
  /// **'Search films and series'**
  String get searchMedia;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @inLibrary.
  ///
  /// In en, this message translates to:
  /// **'In library'**
  String get inLibrary;

  /// No description provided for @noMediaServices.
  ///
  /// In en, this message translates to:
  /// **'Connect Sonarr or Radarr in HomePlace settings first.'**
  String get noMediaServices;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent: {title}'**
  String requestSent(String title);

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @upcomingMedia.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingMedia;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @activeDownloads.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeDownloads(int count);

  /// No description provided for @monitoringTitle.
  ///
  /// In en, this message translates to:
  /// **'Small but watchful'**
  String get monitoringTitle;

  /// No description provided for @monitoringBody.
  ///
  /// In en, this message translates to:
  /// **'A live summary of the checks HomePlace already runs.'**
  String get monitoringBody;

  /// No description provided for @onlineCount.
  ///
  /// In en, this message translates to:
  /// **'{online} of {total} online'**
  String onlineCount(int online, int total);

  /// No description provided for @allQuiet.
  ///
  /// In en, this message translates to:
  /// **'All quiet'**
  String get allQuiet;

  /// No description provided for @recentEvents.
  ///
  /// In en, this message translates to:
  /// **'Recent events'**
  String get recentEvents;

  /// No description provided for @noMonitors.
  ///
  /// In en, this message translates to:
  /// **'Add availability checks to dashboard tiles to see them here.'**
  String get noMonitors;

  /// No description provided for @telegramTitle.
  ///
  /// In en, this message translates to:
  /// **'Telegram bridge'**
  String get telegramTitle;

  /// No description provided for @telegramConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected and ready'**
  String get telegramConnected;

  /// No description provided for @telegramDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Not configured on the server'**
  String get telegramDisconnected;

  /// No description provided for @telegramTest.
  ///
  /// In en, this message translates to:
  /// **'Send test'**
  String get telegramTest;

  /// No description provided for @telegramSent.
  ///
  /// In en, this message translates to:
  /// **'A test message was sent to Telegram.'**
  String get telegramSent;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Connection settings'**
  String get settings;

  /// No description provided for @loadingHome.
  ///
  /// In en, this message translates to:
  /// **'Bringing your HomePlace together…'**
  String get loadingHome;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @permissionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Reconnect this device to approve the new mobile permissions.'**
  String get permissionsRequired;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @clipboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Clipboard relay'**
  String get clipboardTitle;

  /// No description provided for @clipboardBody.
  ///
  /// In en, this message translates to:
  /// **'Send the current Android clipboard to your other approved devices.'**
  String get clipboardBody;

  /// No description provided for @clipboardSend.
  ///
  /// In en, this message translates to:
  /// **'Send clipboard'**
  String get clipboardSend;

  /// No description provided for @clipboardIncoming.
  ///
  /// In en, this message translates to:
  /// **'Clipboard from {device}'**
  String clipboardIncoming(String device);

  /// No description provided for @clipboardCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get clipboardCopy;

  /// No description provided for @clipboardDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get clipboardDismiss;

  /// No description provided for @clipboardSent.
  ///
  /// In en, this message translates to:
  /// **'Clipboard sent to {count} device(s).'**
  String clipboardSent(int count);

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'The clipboard does not contain text.'**
  String get clipboardEmpty;

  /// No description provided for @clipboardNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No other compatible device is connected to this account.'**
  String get clipboardNoDevices;

  /// No description provided for @automaticClipboard.
  ///
  /// In en, this message translates to:
  /// **'Send clipboard automatically'**
  String get automaticClipboard;

  /// No description provided for @automaticClipboardBody.
  ///
  /// In en, this message translates to:
  /// **'While HomePlace is open, send changed text to your approved devices. Incoming text still requires confirmation.'**
  String get automaticClipboardBody;

  /// No description provided for @automaticClipboardSent.
  ///
  /// In en, this message translates to:
  /// **'New clipboard text was sent to {count} device(s).'**
  String automaticClipboardSent(int count);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @connectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Connection security'**
  String get connectionSecurity;

  /// No description provided for @localUnencryptedConnection.
  ///
  /// In en, this message translates to:
  /// **'Unencrypted local-network connection'**
  String get localUnencryptedConnection;

  /// No description provided for @serverIdentity.
  ///
  /// In en, this message translates to:
  /// **'Server ID'**
  String get serverIdentity;

  /// No description provided for @readyToShare.
  ///
  /// In en, this message translates to:
  /// **'Ready to share'**
  String get readyToShare;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @chooseDevice.
  ///
  /// In en, this message translates to:
  /// **'Choose a device'**
  String get chooseDevice;

  /// No description provided for @onlyYourDevices.
  ///
  /// In en, this message translates to:
  /// **'Your devices stay account-isolated. Household devices appear only when their owner explicitly allows sharing.'**
  String get onlyYourDevices;

  /// No description provided for @noShareDevices.
  ///
  /// In en, this message translates to:
  /// **'No compatible approved devices are available.'**
  String get noShareDevices;

  /// No description provided for @yourDevice.
  ///
  /// In en, this message translates to:
  /// **'Your device'**
  String get yourDevice;

  /// No description provided for @householdDevice.
  ///
  /// In en, this message translates to:
  /// **'Household · {owner}'**
  String householdDevice(String owner);

  /// No description provided for @deviceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get deviceOnline;

  /// No description provided for @deviceOffline.
  ///
  /// In en, this message translates to:
  /// **'May receive it when HomePlace is opened'**
  String get deviceOffline;

  /// No description provided for @confirmShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Send this item?'**
  String get confirmShareTitle;

  /// No description provided for @confirmShareBody.
  ///
  /// In en, this message translates to:
  /// **'HomePlace will send it only to {device}. The offer expires in five minutes.'**
  String confirmShareBody(String device);

  /// No description provided for @confirmHouseholdShareBody.
  ///
  /// In en, this message translates to:
  /// **'This device belongs to {owner}. HomePlace will send the item only to {device} after you confirm. The offer expires in five minutes.'**
  String confirmHouseholdShareBody(String owner, String device);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @shareSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to {device}.'**
  String shareSent(String device);

  /// No description provided for @recentTransfers.
  ///
  /// In en, this message translates to:
  /// **'Recent transfers'**
  String get recentTransfers;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearHistory;

  /// No description provided for @transferHistoryPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Stored securely for this device profile. Shared content and filenames are never saved here.'**
  String get transferHistoryPrivacy;

  /// No description provided for @transferSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {device}'**
  String transferSentTo(String device);

  /// No description provided for @transferReceivedFrom.
  ///
  /// In en, this message translates to:
  /// **'Received from {device}'**
  String transferReceivedFrom(String device);

  /// No description provided for @incomingShare.
  ///
  /// In en, this message translates to:
  /// **'From {device}'**
  String incomingShare(String device);

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @acceptAndSave.
  ///
  /// In en, this message translates to:
  /// **'Accept and save'**
  String get acceptAndSave;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {filename} to Downloads/HomePlace.'**
  String fileSaved(String filename);

  /// No description provided for @upcomingReminders.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingReminders;

  /// No description provided for @overdueReminders.
  ///
  /// In en, this message translates to:
  /// **'Past due'**
  String get overdueReminders;

  /// No description provided for @completedReminders.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedReminders;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get editReminder;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @clearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clear completed'**
  String get clearCompleted;

  /// No description provided for @deleteReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder?'**
  String get deleteReminderTitle;

  /// No description provided for @deleteReminderBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be permanently deleted.'**
  String deleteReminderBody(String title);

  /// No description provided for @clearCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear completed reminders?'**
  String get clearCompletedTitle;

  /// No description provided for @clearCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'All completed reminders for this account will be permanently deleted.'**
  String get clearCompletedBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
