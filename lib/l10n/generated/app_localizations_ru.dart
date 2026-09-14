// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'HomePlace';

  @override
  String get welcomeTitle => 'Ваш HomePlace — теперь в телефоне';

  @override
  String get welcomeBody =>
      'Безопасно подключитесь к своему серверу HomePlace.';

  @override
  String get getStarted => 'Начать';

  @override
  String get connectTitle => 'Подключение к HomePlace';

  @override
  String get connectBody =>
      'Введите HTTPS-домен, локальное имя, локальный IP-адрес или отсканируйте QR-код HomePlace.';

  @override
  String get serverAddress => 'Адрес сервера';

  @override
  String get serverHint => 'home.example.net или 192.168.1.20:3200';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get scanQr => 'Сканировать QR-код';

  @override
  String get cameraExplanation =>
      'HomePlace использует камеру только во время сканирования QR-кода подключения.';

  @override
  String get allowCamera => 'Разрешить камеру';

  @override
  String get checkingServer => 'Проверяем сервер…';

  @override
  String get serverVerified => 'Сервер проверен';

  @override
  String get readyToPair => 'Можно подключать';

  @override
  String get secureConnection => 'Защищённое HTTPS-соединение';

  @override
  String get localHttpWarning => 'Незашифрованное соединение в локальной сети';

  @override
  String get selfSignedWarning =>
      'Сертификат не подтверждён общедоступным центром. Подтверждайте SHA-256 отпечаток, только если он совпадает с сервером HomePlace:';

  @override
  String get trustCertificate => 'Доверять сертификату';

  @override
  String get serverUrl => 'Адрес сервера';

  @override
  String get serverId => 'ID сервера';

  @override
  String get security => 'Безопасность';

  @override
  String get protocol => 'Протокол Link';

  @override
  String get pair => 'Подключить устройство';

  @override
  String get pairingUnavailable =>
      'Эта версия сервера пока не поддерживает подключение устройств.';

  @override
  String get notificationExplanation =>
      'Разрешите уведомления для тестовых и обычных сообщений HomePlace. Без разрешения эта возможность не объявляется серверу.';

  @override
  String get enableNotifications => 'Разрешить уведомления';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get pairingTitle => 'Подтвердите телефон';

  @override
  String get pairingBody =>
      'Откройте раздел «Устройства» в веб-интерфейсе HomePlace и подтвердите запрос с этим кодом.';

  @override
  String get pairingCode => 'Код подтверждения';

  @override
  String get cancel => 'Отмена';

  @override
  String get connected => 'Подключено';

  @override
  String get connectedBody =>
      'Устройство зарегистрировано в HomePlace. Присутствие и входящие события активны, пока приложение открыто.';

  @override
  String get lastNotification => 'Последнее уведомление';

  @override
  String get disconnect => 'Отключить и отозвать доступ';

  @override
  String get useAnotherAddress => 'Указать другой адрес';

  @override
  String get retry => 'Повторить';

  @override
  String get diagnostics => 'Диагностика';

  @override
  String get noDiagnostics => 'Технические сведения отсутствуют.';

  @override
  String get close => 'Закрыть';

  @override
  String expiresAt(String time) {
    return 'Истекает: $time';
  }
}
