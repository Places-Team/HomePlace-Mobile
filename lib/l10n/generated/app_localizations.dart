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
  /// **'Secure HTTPS connection'**
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
