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
  String get secureConnection => 'Secure HTTPS connection';

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
}
