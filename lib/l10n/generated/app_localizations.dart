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

  /// No description provided for @savedConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your HomePlace is saved'**
  String get savedConnectionTitle;

  /// No description provided for @savedConnectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The server is unavailable right now. Your connection is still saved.'**
  String get savedConnectionUnavailable;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Try connecting again'**
  String get retryConnection;

  /// No description provided for @changeServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Use another address'**
  String get changeServerAddress;

  /// No description provided for @plantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plants'**
  String get plantsTitle;

  /// No description provided for @plantsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A calmer way to care for what grows at home.'**
  String get plantsSubtitle;

  /// No description provided for @plantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add your first plant and its watering rhythm.'**
  String get plantsEmpty;

  /// No description provided for @plantsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get plantsSeeAll;

  /// No description provided for @plantsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add plant'**
  String get plantsAdd;

  /// No description provided for @plantsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get plantsName;

  /// No description provided for @plantsSpecies.
  ///
  /// In en, this message translates to:
  /// **'Plant or species'**
  String get plantsSpecies;

  /// No description provided for @plantsRoom.
  ///
  /// In en, this message translates to:
  /// **'Room or place'**
  String get plantsRoom;

  /// No description provided for @plantsNotes.
  ///
  /// In en, this message translates to:
  /// **'Care notes'**
  String get plantsNotes;

  /// No description provided for @plantsPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get plantsPhoto;

  /// No description provided for @plantsChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get plantsChangePhoto;

  /// No description provided for @plantsGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get plantsGallery;

  /// No description provided for @plantsCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get plantsCamera;

  /// No description provided for @plantsEveryDays.
  ///
  /// In en, this message translates to:
  /// **'Water every {days} days'**
  String plantsEveryDays(int days);

  /// No description provided for @plantsEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Water every day'**
  String get plantsEveryDay;

  /// No description provided for @plantsInterval.
  ///
  /// In en, this message translates to:
  /// **'Watering interval'**
  String get plantsInterval;

  /// No description provided for @plantsLastWatered.
  ///
  /// In en, this message translates to:
  /// **'Last watered'**
  String get plantsLastWatered;

  /// No description provided for @plantsWaterNow.
  ///
  /// In en, this message translates to:
  /// **'Watered now'**
  String get plantsWaterNow;

  /// No description provided for @plantsWatered.
  ///
  /// In en, this message translates to:
  /// **'Watering recorded'**
  String get plantsWatered;

  /// No description provided for @plantsUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get plantsUndo;

  /// No description provided for @plantsDueToday.
  ///
  /// In en, this message translates to:
  /// **'Water today'**
  String get plantsDueToday;

  /// No description provided for @plantsOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days} days'**
  String plantsOverdue(int days);

  /// No description provided for @plantsDueIn.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String plantsDueIn(int days);

  /// No description provided for @plantsDueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} need water'**
  String plantsDueCount(int count);

  /// No description provided for @plantsAllGood.
  ///
  /// In en, this message translates to:
  /// **'All cared for'**
  String get plantsAllGood;

  /// No description provided for @plantsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit plant'**
  String get plantsEdit;

  /// No description provided for @plantsSave.
  ///
  /// In en, this message translates to:
  /// **'Save plant'**
  String get plantsSave;

  /// No description provided for @plantsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete plant'**
  String get plantsDelete;

  /// No description provided for @plantsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this plant and its photo from this device?'**
  String get plantsDeleteConfirm;

  /// No description provided for @plantsLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Plant cards stay in this app\'s private storage for this connection. They are not sent to HomePlace.'**
  String get plantsLocalOnly;

  /// No description provided for @plantsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Plant cards could not be loaded. Try again.'**
  String get plantsLoadError;

  /// No description provided for @plantsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the plant. Try again.'**
  String get plantsSaveError;

  /// No description provided for @plantsPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Could not use this photo. Choose a smaller image.'**
  String get plantsPhotoError;

  /// No description provided for @plantsPickDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get plantsPickDate;

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

  /// No description provided for @transfersTab.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfersTab;

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
  /// **'Your plants and the next thing to do at home.'**
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

  /// No description provided for @monitorOverviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get monitorOverviewTab;

  /// No description provided for @monitorServicesTab.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get monitorServicesTab;

  /// No description provided for @monitorContainersTab.
  ///
  /// In en, this message translates to:
  /// **'Containers'**
  String get monitorContainersTab;

  /// No description provided for @monitorEventsTab.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get monitorEventsTab;

  /// No description provided for @monitoredChecksExplanation.
  ///
  /// In en, this message translates to:
  /// **'Availability checks, not Docker containers.'**
  String get monitoredChecksExplanation;

  /// No description provided for @containerSummary.
  ///
  /// In en, this message translates to:
  /// **'Docker containers'**
  String get containerSummary;

  /// No description provided for @totalContainers.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalContainers;

  /// No description provided for @runningContainers.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get runningContainers;

  /// No description provided for @stoppedContainers.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stoppedContainers;

  /// No description provided for @containerProblems.
  ///
  /// In en, this message translates to:
  /// **'Problems'**
  String get containerProblems;

  /// No description provided for @noContainers.
  ///
  /// In en, this message translates to:
  /// **'No Docker containers are available from the configured hosts.'**
  String get noContainers;

  /// No description provided for @containerRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get containerRunning;

  /// No description provided for @containerExited.
  ///
  /// In en, this message translates to:
  /// **'Exited'**
  String get containerExited;

  /// No description provided for @containerPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get containerPaused;

  /// No description provided for @containerRestarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting'**
  String get containerRestarting;

  /// No description provided for @containerDead.
  ///
  /// In en, this message translates to:
  /// **'Dead'**
  String get containerDead;

  /// No description provided for @containerCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get containerCreated;

  /// No description provided for @unknownState.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownState;

  /// No description provided for @serviceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get serviceOnline;

  /// No description provided for @serviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get serviceOffline;

  /// No description provided for @averageLatency.
  ///
  /// In en, this message translates to:
  /// **'Average latency'**
  String get averageLatency;

  /// No description provided for @lastChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked {time}'**
  String lastChecked(String time);

  /// No description provided for @noRecentEvents.
  ///
  /// In en, this message translates to:
  /// **'No recent monitoring events.'**
  String get noRecentEvents;

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

  /// No description provided for @preparingShare.
  ///
  /// In en, this message translates to:
  /// **'Preparing devices for secure sharing…'**
  String get preparingShare;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @errorDetails.
  ///
  /// In en, this message translates to:
  /// **'Something needs attention'**
  String get errorDetails;

  /// No description provided for @dismissError.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissError;

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

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

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
  /// **'HomePlace will send it only to {device}. The offer expires in 30 minutes.'**
  String confirmShareBody(String device);

  /// No description provided for @confirmMultipleShareBody.
  ///
  /// In en, this message translates to:
  /// **'HomePlace will send {count} items only to {device}. Each offer expires in 30 minutes.'**
  String confirmMultipleShareBody(int count, String device);

  /// No description provided for @confirmMultipleHouseholdShareBody.
  ///
  /// In en, this message translates to:
  /// **'This device belongs to {owner}. HomePlace will send {count} items only to {device} after you confirm. Each offer expires in 30 minutes.'**
  String confirmMultipleHouseholdShareBody(
    int count,
    String owner,
    String device,
  );

  /// No description provided for @confirmHouseholdShareBody.
  ///
  /// In en, this message translates to:
  /// **'This device belongs to {owner}. HomePlace will send the item only to {device} after you confirm. The offer expires in 30 minutes.'**
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

  /// No description provided for @itemsReadyToShare.
  ///
  /// In en, this message translates to:
  /// **'{count} items ready to send'**
  String itemsReadyToShare(int count);

  /// No description provided for @transfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfersTitle;

  /// No description provided for @transfersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review every incoming item and choose exactly where outgoing content is sent.'**
  String get transfersSubtitle;

  /// No description provided for @exchangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Temporary text link'**
  String get exchangeTitle;

  /// No description provided for @exchangeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share text with another device signed in to your HomePlace account. Direct device transfers remain separate.'**
  String get exchangeSubtitle;

  /// No description provided for @exchangeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open temporary links'**
  String get exchangeOpen;

  /// No description provided for @exchangeText.
  ///
  /// In en, this message translates to:
  /// **'Text to share'**
  String get exchangeText;

  /// No description provided for @exchangeAccountOnly.
  ///
  /// In en, this message translates to:
  /// **'Only your HomePlace account can open this link. Anyone with the link and access to your account may read it.'**
  String get exchangeAccountOnly;

  /// No description provided for @exchangeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Link expires after'**
  String get exchangeExpiry;

  /// No description provided for @exchangeTenMinutes.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get exchangeTenMinutes;

  /// No description provided for @exchangeOneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get exchangeOneHour;

  /// No description provided for @exchangeOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get exchangeOneDay;

  /// No description provided for @exchangeOneTime.
  ///
  /// In en, this message translates to:
  /// **'Remove after first open'**
  String get exchangeOneTime;

  /// No description provided for @exchangeOneTimeWarning.
  ///
  /// In en, this message translates to:
  /// **'An interrupted first open cannot be retried.'**
  String get exchangeOneTimeWarning;

  /// No description provided for @exchangeCreate.
  ///
  /// In en, this message translates to:
  /// **'Create private link'**
  String get exchangeCreate;

  /// No description provided for @exchangeActive.
  ///
  /// In en, this message translates to:
  /// **'Active text links'**
  String get exchangeActive;

  /// No description provided for @exchangeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active text links.'**
  String get exchangeEmpty;

  /// No description provided for @exchangeTextLink.
  ///
  /// In en, this message translates to:
  /// **'Private text link'**
  String get exchangeTextLink;

  /// No description provided for @exchangeReusable.
  ///
  /// In en, this message translates to:
  /// **'Reusable until expiry'**
  String get exchangeReusable;

  /// No description provided for @exchangeCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get exchangeCopy;

  /// No description provided for @exchangeCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied. Treat it as a secret.'**
  String get exchangeCopied;

  /// No description provided for @exchangeClipboardWarning.
  ///
  /// In en, this message translates to:
  /// **'Automatic clipboard sharing is on. Copying this link may send it to your approved devices.'**
  String get exchangeClipboardWarning;

  /// No description provided for @exchangeRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke link'**
  String get exchangeRevoke;

  /// No description provided for @exchangeRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'This link will stop working immediately. Revoke it?'**
  String get exchangeRevokeConfirm;

  /// No description provided for @exchangeReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to HomePlace and try again.'**
  String get exchangeReconnect;

  /// No description provided for @fileExchangeTitle.
  ///
  /// In en, this message translates to:
  /// **'File exchange'**
  String get fileExchangeTitle;

  /// No description provided for @fileExchangeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a file, then share a short-lived download link. Direct device transfers stay separate.'**
  String get fileExchangeSubtitle;

  /// No description provided for @fileExchangeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open file exchange'**
  String get fileExchangeOpen;

  /// No description provided for @fileExchangeChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose any file'**
  String get fileExchangeChoose;

  /// No description provided for @fileExchangeSizeError.
  ///
  /// In en, this message translates to:
  /// **'Choose a non-empty file within this server\'s {limit} upload limit.'**
  String fileExchangeSizeError(String limit);

  /// No description provided for @fileExchangeLimit.
  ///
  /// In en, this message translates to:
  /// **'Current server limit: {limit}'**
  String fileExchangeLimit(String limit);

  /// No description provided for @fileExchangePickError.
  ///
  /// In en, this message translates to:
  /// **'The file could not be opened. Choose it again.'**
  String get fileExchangePickError;

  /// No description provided for @fileExchangeAccess.
  ///
  /// In en, this message translates to:
  /// **'Who can download'**
  String get fileExchangeAccess;

  /// No description provided for @fileExchangeAccount.
  ///
  /// In en, this message translates to:
  /// **'My HomePlace account'**
  String get fileExchangeAccount;

  /// No description provided for @fileExchangePublic.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link'**
  String get fileExchangePublic;

  /// No description provided for @fileExchangePublicWarning.
  ///
  /// In en, this message translates to:
  /// **'This link is a secret. Anyone who gets it can download the file until it expires or you revoke it. Do not use it for private files unless you trust every recipient.'**
  String get fileExchangePublicWarning;

  /// No description provided for @fileExchangeQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick one-time code'**
  String get fileExchangeQuick;

  /// No description provided for @fileExchangeQuickWarning.
  ///
  /// In en, this message translates to:
  /// **'Public · 10 minutes · one download. Interrupted downloads cannot resume.'**
  String get fileExchangeQuickWarning;

  /// No description provided for @fileExchangeCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get fileExchangeCode;

  /// No description provided for @fileExchangeConfirmPublic.
  ///
  /// In en, this message translates to:
  /// **'Create external link'**
  String get fileExchangeConfirmPublic;

  /// No description provided for @fileExchangeUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload and create link'**
  String get fileExchangeUpload;

  /// No description provided for @fileExchangeActive.
  ///
  /// In en, this message translates to:
  /// **'Active file links'**
  String get fileExchangeActive;

  /// No description provided for @fileExchangeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active file links.'**
  String get fileExchangeEmpty;

  /// No description provided for @fileExchangeReceive.
  ///
  /// In en, this message translates to:
  /// **'Save a file from a link'**
  String get fileExchangeReceive;

  /// No description provided for @fileExchangeLink.
  ///
  /// In en, this message translates to:
  /// **'Link from this HomePlace server'**
  String get fileExchangeLink;

  /// No description provided for @fileExchangeCheck.
  ///
  /// In en, this message translates to:
  /// **'Check file'**
  String get fileExchangeCheck;

  /// No description provided for @fileExchangeInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'Enter a 22-character file code or /x link from this HomePlace server. Open five-character quick codes at the server\'s /f page in a browser.'**
  String get fileExchangeInvalidLink;

  /// No description provided for @fileExchangeDownload.
  ///
  /// In en, this message translates to:
  /// **'Download to Downloads'**
  String get fileExchangeDownload;

  /// No description provided for @fileExchangeSaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm to download and save this file on your phone.'**
  String get fileExchangeSaveConfirm;

  /// No description provided for @fileExchangeOneTimeWarning.
  ///
  /// In en, this message translates to:
  /// **'This link works only once. Starting the download uses it, even if the transfer is interrupted.'**
  String get fileExchangeOneTimeWarning;

  /// No description provided for @fileExchangeSaveError.
  ///
  /// In en, this message translates to:
  /// **'The file could not be saved. Check Downloads before trying again.'**
  String get fileExchangeSaveError;

  /// No description provided for @fileExchangeOpenSaved.
  ///
  /// In en, this message translates to:
  /// **'Open saved file'**
  String get fileExchangeOpenSaved;

  /// No description provided for @fileExchangeOpenError.
  ///
  /// In en, this message translates to:
  /// **'Android could not open the saved file.'**
  String get fileExchangeOpenError;

  /// No description provided for @noPendingTransfers.
  ///
  /// In en, this message translates to:
  /// **'No transfers need your attention right now.'**
  String get noPendingTransfers;

  /// No description provided for @outgoingItems.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send · {count}'**
  String outgoingItems(int count);

  /// No description provided for @waitingToSend.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a device'**
  String get waitingToSend;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

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

  /// No description provided for @incomingOffers.
  ///
  /// In en, this message translates to:
  /// **'Incoming items · {count}'**
  String incomingOffers(int count);

  /// No description provided for @moreIncomingOffers.
  ///
  /// In en, this message translates to:
  /// **'+{count} more incoming item(s)'**
  String moreIncomingOffers(int count);

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

  /// No description provided for @homePlaceProfiles.
  ///
  /// In en, this message translates to:
  /// **'HomePlace connections'**
  String get homePlaceProfiles;

  /// No description provided for @activeProfile.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeProfile;

  /// No description provided for @connectAnotherHomePlace.
  ///
  /// In en, this message translates to:
  /// **'Connect another HomePlace'**
  String get connectAnotherHomePlace;

  /// No description provided for @cancelAddingConnection.
  ///
  /// In en, this message translates to:
  /// **'Back to the connected HomePlace'**
  String get cancelAddingConnection;

  /// No description provided for @backgroundDelivery.
  ///
  /// In en, this message translates to:
  /// **'Background HomePlace checks'**
  String get backgroundDelivery;

  /// No description provided for @backgroundDeliveryBody.
  ///
  /// In en, this message translates to:
  /// **'Android checks connected HomePlace servers about every 15 minutes. The system may delay checks to save battery.'**
  String get backgroundDeliveryBody;

  /// No description provided for @backgroundIncomingOffers.
  ///
  /// In en, this message translates to:
  /// **'Incoming items in background'**
  String get backgroundIncomingOffers;

  /// No description provided for @backgroundIncomingOffersBody.
  ///
  /// In en, this message translates to:
  /// **'Check for clipboard, text, links and files while HomePlace is closed. Accepting a file queues a verified background download; text, links and clipboard still open HomePlace for confirmation.'**
  String get backgroundIncomingOffersBody;

  /// No description provided for @seamlessOwnAccountTransfers.
  ///
  /// In en, this message translates to:
  /// **'Seamless files from my devices'**
  String get seamlessOwnAccountTransfers;

  /// No description provided for @seamlessOwnAccountTransfersBody.
  ///
  /// In en, this message translates to:
  /// **'Automatically accept and save verified files sent by another device on your account, including during enabled background checks. Family devices, links, text and clipboard still require confirmation.'**
  String get seamlessOwnAccountTransfersBody;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Allow HomePlace notifications in Android settings to enable background delivery.'**
  String get notificationPermissionRequired;

  /// No description provided for @lastBackgroundCheck.
  ///
  /// In en, this message translates to:
  /// **'Last background check'**
  String get lastBackgroundCheck;

  /// No description provided for @backgroundNeverRun.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Android to run the first check.'**
  String get backgroundNeverRun;

  /// No description provided for @backgroundCheckedProfiles.
  ///
  /// In en, this message translates to:
  /// **'{time} · Checked {count} connection(s)'**
  String backgroundCheckedProfiles(String time, int count);

  /// No description provided for @backgroundCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'{time} · The check could not finish and will be retried.'**
  String backgroundCheckFailed(String time);

  /// No description provided for @notificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Notification history'**
  String get notificationHistory;

  /// No description provided for @notificationHistoryPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Stored in encrypted device storage for this HomePlace profile only.'**
  String get notificationHistoryPrivacy;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @allSections.
  ///
  /// In en, this message translates to:
  /// **'All sections'**
  String get allSections;

  /// No description provided for @allSectionsBody.
  ///
  /// In en, this message translates to:
  /// **'The spaces beyond your main tabs. Keep only what you use.'**
  String get allSectionsBody;

  /// No description provided for @customizeSections.
  ///
  /// In en, this message translates to:
  /// **'Customize sections'**
  String get customizeSections;

  /// No description provided for @customizeSectionsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose what appears here. Your main tabs stay in place.'**
  String get customizeSectionsBody;

  /// No description provided for @restoreSections.
  ///
  /// In en, this message translates to:
  /// **'Show all sections'**
  String get restoreSections;

  /// No description provided for @hiddenSectionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No extra sections are visible. Use Customize to bring them back.'**
  String get hiddenSectionsEmpty;

  /// No description provided for @everydaySection.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everydaySection;

  /// No description provided for @sharingSection.
  ///
  /// In en, this message translates to:
  /// **'Devices and sharing'**
  String get sharingSection;

  /// No description provided for @servicesSection.
  ///
  /// In en, this message translates to:
  /// **'Home and services'**
  String get servicesSection;

  /// No description provided for @systemSection.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemSection;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get availableNow;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @configureOnServer.
  ///
  /// In en, this message translates to:
  /// **'Configure in the HomePlace web control center'**
  String get configureOnServer;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devicesTitle;

  /// No description provided for @devicesBody.
  ///
  /// In en, this message translates to:
  /// **'Presence, ownership and the actions each paired device actually supports.'**
  String get devicesBody;

  /// No description provided for @shareCapableDevices.
  ///
  /// In en, this message translates to:
  /// **'Available for sharing'**
  String get shareCapableDevices;

  /// No description provided for @noLinkedDevices.
  ///
  /// In en, this message translates to:
  /// **'No other compatible devices are currently available.'**
  String get noLinkedDevices;

  /// No description provided for @capabilities.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get capabilities;

  /// No description provided for @clipboardModuleBody.
  ///
  /// In en, this message translates to:
  /// **'Private text handoff with confirmation and loop protection.'**
  String get clipboardModuleBody;

  /// No description provided for @notificationsModuleBody.
  ///
  /// In en, this message translates to:
  /// **'Delivery history and sensitive action approvals for this profile.'**
  String get notificationsModuleBody;

  /// No description provided for @automationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Automations'**
  String get automationsTitle;

  /// No description provided for @automationsBody.
  ///
  /// In en, this message translates to:
  /// **'Connect explicit events and actions without giving devices unrestricted control.'**
  String get automationsBody;

  /// No description provided for @automationArrival.
  ///
  /// In en, this message translates to:
  /// **'When I arrive home'**
  String get automationArrival;

  /// No description provided for @automationArrivalAction.
  ///
  /// In en, this message translates to:
  /// **'Turn on the hallway scene'**
  String get automationArrivalAction;

  /// No description provided for @automationDownload.
  ///
  /// In en, this message translates to:
  /// **'When a download finishes'**
  String get automationDownload;

  /// No description provided for @automationDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Notify my phone'**
  String get automationDownloadAction;

  /// No description provided for @automationBattery.
  ///
  /// In en, this message translates to:
  /// **'When server power is low'**
  String get automationBattery;

  /// No description provided for @automationBatteryAction.
  ///
  /// In en, this message translates to:
  /// **'Send a Telegram alert'**
  String get automationBatteryAction;

  /// No description provided for @automationSafety.
  ///
  /// In en, this message translates to:
  /// **'Every rule lists its trigger, target and required permission before it can be enabled.'**
  String get automationSafety;

  /// No description provided for @smartHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart home'**
  String get smartHomeTitle;

  /// No description provided for @smartHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Rooms, scenes, sensors and safe controls from the Home Assistant connection managed by HomePlace.'**
  String get smartHomeBody;

  /// No description provided for @smartHomeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Connect Home Assistant on the server to show real rooms and controls here.'**
  String get smartHomeEmpty;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @scenes.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get scenes;

  /// No description provided for @sensors.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get sensors;

  /// No description provided for @securityCenter.
  ///
  /// In en, this message translates to:
  /// **'Security and privacy'**
  String get securityCenter;

  /// No description provided for @securityCenterBody.
  ///
  /// In en, this message translates to:
  /// **'Review server identity, transport security, account isolation and approved permissions.'**
  String get securityCenterBody;

  /// No description provided for @accountIsolation.
  ///
  /// In en, this message translates to:
  /// **'Account-isolated sharing'**
  String get accountIsolation;

  /// No description provided for @accountIsolationBody.
  ///
  /// In en, this message translates to:
  /// **'Content is routed only to the selected approved device. Household transfers always require confirmation.'**
  String get accountIsolationBody;

  /// No description provided for @explicitCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Explicit capabilities'**
  String get explicitCapabilities;

  /// No description provided for @explicitCapabilitiesBody.
  ///
  /// In en, this message translates to:
  /// **'The phone advertises only actions supported by this operating system and current permissions.'**
  String get explicitCapabilitiesBody;

  /// No description provided for @verifiedIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verified server identity'**
  String get verifiedIdentity;

  /// No description provided for @verifiedIdentityBody.
  ///
  /// In en, this message translates to:
  /// **'HomePlace checks the server ID on reconnect and never silently accepts an invalid certificate.'**
  String get verifiedIdentityBody;

  /// No description provided for @openSection.
  ///
  /// In en, this message translates to:
  /// **'Open section'**
  String get openSection;

  /// No description provided for @manageSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage settings'**
  String get manageSettings;

  /// No description provided for @calendarModuleBody.
  ///
  /// In en, this message translates to:
  /// **'Calendar, reminders, plants and ideas in one place.'**
  String get calendarModuleBody;

  /// No description provided for @mediaModuleBody.
  ///
  /// In en, this message translates to:
  /// **'Search Radarr and Sonarr and follow download queues.'**
  String get mediaModuleBody;

  /// No description provided for @transfersModuleBody.
  ///
  /// In en, this message translates to:
  /// **'Send and receive text, links and files with an explicit recipient.'**
  String get transfersModuleBody;

  /// No description provided for @monitoringModuleBody.
  ///
  /// In en, this message translates to:
  /// **'Availability checks, Docker containers, service latency and events.'**
  String get monitoringModuleBody;

  /// No description provided for @telegramModuleBody.
  ///
  /// In en, this message translates to:
  /// **'Server-managed alerts and a connection test.'**
  String get telegramModuleBody;

  /// No description provided for @settingsModuleBody.
  ///
  /// In en, this message translates to:
  /// **'Language, appearance, background delivery, profiles and connection security.'**
  String get settingsModuleBody;

  /// No description provided for @privateWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Private workspace'**
  String get privateWorkspace;

  /// No description provided for @plannedServerApi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a compatible server API'**
  String get plannedServerApi;

  /// No description provided for @ideasTitle.
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get ideasTitle;

  /// No description provided for @ideasSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Catch a thought before it slips away.'**
  String get ideasSubtitle;

  /// No description provided for @ideasLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Only on this phone. This device has not been granted access to account ideas.'**
  String get ideasLocalOnly;

  /// No description provided for @ideasServerSynced.
  ///
  /// In en, this message translates to:
  /// **'Saved to your HomePlace account and available on your devices.'**
  String get ideasServerSynced;

  /// No description provided for @ideasSyncUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account ideas are unavailable right now. Phone ideas have not been uploaded.'**
  String get ideasSyncUnavailable;

  /// No description provided for @ideasImportLocal.
  ///
  /// In en, this message translates to:
  /// **'Import phone ideas'**
  String get ideasImportLocal;

  /// No description provided for @ideasImportPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy ideas saved on this phone to your HomePlace account? Existing phone copies will stay private on this device.'**
  String get ideasImportPrompt;

  /// No description provided for @ideasImportDone.
  ///
  /// In en, this message translates to:
  /// **'Phone ideas imported to HomePlace.'**
  String get ideasImportDone;

  /// No description provided for @ideasModuleBody.
  ///
  /// In en, this message translates to:
  /// **'Private quick capture, categories and reminder handoff.'**
  String get ideasModuleBody;

  /// No description provided for @ideasCaptureHint.
  ///
  /// In en, this message translates to:
  /// **'An idea, a link, or the next step…'**
  String get ideasCaptureHint;

  /// No description provided for @ideasAdd.
  ///
  /// In en, this message translates to:
  /// **'Save idea'**
  String get ideasAdd;

  /// No description provided for @ideasAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ideasAll;

  /// No description provided for @ideasEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'A clear page'**
  String get ideasEmptyTitle;

  /// No description provided for @ideasEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Save your first thought here. Turn it into a reminder when it needs a date.'**
  String get ideasEmptyBody;

  /// No description provided for @ideasInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get ideasInbox;

  /// No description provided for @ideasHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get ideasHome;

  /// No description provided for @ideasWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get ideasWork;

  /// No description provided for @ideasMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get ideasMedia;

  /// No description provided for @ideasLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get ideasLater;

  /// No description provided for @ideasCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get ideasCategory;

  /// No description provided for @ideasNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get ideasNewCategory;

  /// No description provided for @ideasCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get ideasCategoryName;

  /// No description provided for @ideasCategoryExists.
  ///
  /// In en, this message translates to:
  /// **'Use a different category name.'**
  String get ideasCategoryExists;

  /// No description provided for @ideasEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit idea'**
  String get ideasEdit;

  /// No description provided for @ideasNote.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get ideasNote;

  /// No description provided for @ideasPin.
  ///
  /// In en, this message translates to:
  /// **'Pin idea'**
  String get ideasPin;

  /// No description provided for @ideasUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin idea'**
  String get ideasUnpin;

  /// No description provided for @ideasComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get ideasComplete;

  /// No description provided for @ideasReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen idea'**
  String get ideasReopen;

  /// No description provided for @ideasPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get ideasPinned;

  /// No description provided for @ideasCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ideasCompleted;

  /// No description provided for @ideasActive.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get ideasActive;

  /// No description provided for @ideasArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get ideasArchive;

  /// No description provided for @ideasArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive idea'**
  String get ideasArchiveAction;

  /// No description provided for @ideasRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore idea'**
  String get ideasRestore;

  /// No description provided for @ideasArchiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No archived ideas yet.'**
  String get ideasArchiveEmpty;

  /// No description provided for @ideasDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get ideasDuplicate;

  /// No description provided for @ideasDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete idea'**
  String get ideasDelete;

  /// No description provided for @ideasDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this idea from this phone?'**
  String get ideasDeleteConfirm;

  /// No description provided for @ideasToReminder.
  ///
  /// In en, this message translates to:
  /// **'Make reminder'**
  String get ideasToReminder;

  /// No description provided for @ideasCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get ideasCopy;

  /// No description provided for @ideasClipboardWarning.
  ///
  /// In en, this message translates to:
  /// **'Automatic clipboard sharing is on. Copying this idea may send it to your approved devices.'**
  String get ideasClipboardWarning;

  /// No description provided for @ideasCopyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Copy anyway'**
  String get ideasCopyConfirm;

  /// No description provided for @ideasSaveError.
  ///
  /// In en, this message translates to:
  /// **'The idea could not be saved. Try again.'**
  String get ideasSaveError;

  /// No description provided for @ideasLoadError.
  ///
  /// In en, this message translates to:
  /// **'Ideas could not be opened on this device.'**
  String get ideasLoadError;

  /// No description provided for @ideasSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get ideasSave;

  /// No description provided for @quickTransferTile.
  ///
  /// In en, this message translates to:
  /// **'Add Transfers to Quick Settings'**
  String get quickTransferTile;

  /// No description provided for @quickTransferTileBody.
  ///
  /// In en, this message translates to:
  /// **'Open Transfers from the Samsung quick panel without starting on Home. Sending still needs confirmation.'**
  String get quickTransferTileBody;

  /// No description provided for @quickTransferTileAdded.
  ///
  /// In en, this message translates to:
  /// **'Transfers was added to Quick Settings.'**
  String get quickTransferTileAdded;

  /// No description provided for @quickTransferTileAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Transfers is already in Quick Settings.'**
  String get quickTransferTileAlreadyAdded;

  /// No description provided for @quickTransferTileNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Tile not added. You can add it manually while editing Quick Settings.'**
  String get quickTransferTileNotAdded;

  /// No description provided for @quickTransferTileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Automatic tile setup is unavailable. Add HomePlace transfers from the Quick Settings editor.'**
  String get quickTransferTileUnavailable;

  /// No description provided for @androidNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Android notification settings'**
  String get androidNotificationSettings;

  /// No description provided for @androidNotificationSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Manage notification permission, channels and lock-screen privacy in system settings.'**
  String get androidNotificationSettingsBody;
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
