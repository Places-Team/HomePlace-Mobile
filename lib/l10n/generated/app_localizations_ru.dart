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
  String get secureConnection => 'Защищённое подключение HTTPS';

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

  @override
  String get homeTab => 'Дом';

  @override
  String get calendarTab => 'Планы';

  @override
  String get requestsTab => 'Заявки';

  @override
  String get monitorTab => 'Контроль';

  @override
  String get everythingInPlace => 'Всё на своих местах';

  @override
  String get homeOverviewBody =>
      'День, сервисы и связи HomePlace — одним взглядом.';

  @override
  String get onlineNow => 'Сейчас в сети';

  @override
  String get needsAttention => 'Требует внимания';

  @override
  String get nextUp => 'Ближайшее';

  @override
  String get nothingPlanned => 'Пока ничего не запланировано';

  @override
  String get calendarTitle => 'Календарь';

  @override
  String get remindersTitle => 'Напоминания';

  @override
  String get addReminder => 'Добавить напоминание';

  @override
  String get reminderTitleHint => 'О чём напомнить?';

  @override
  String get dateAndTime => 'Дата и время';

  @override
  String get repeat => 'Повтор';

  @override
  String get repeatNone => 'Не повторять';

  @override
  String get repeatHourly => 'Каждый час';

  @override
  String get repeatDaily => 'Каждый день';

  @override
  String get repeatWeekly => 'Каждую неделю';

  @override
  String get repeatMonthly => 'Каждый месяц';

  @override
  String get repeatYearly => 'Каждый год';

  @override
  String repeatInterval(int count, String unit) {
    return 'Каждые $count $unit';
  }

  @override
  String get repeatUnitHour => 'ч.';

  @override
  String get repeatUnitDay => 'дн.';

  @override
  String get repeatUnitWeek => 'нед.';

  @override
  String get repeatUnitMonth => 'мес.';

  @override
  String get repeatUnitYear => 'г.';

  @override
  String customRepeat(String rule) {
    return 'Особый повтор: $rule';
  }

  @override
  String get save => 'Сохранить';

  @override
  String get complete => 'Выполнить';

  @override
  String get delete => 'Удалить';

  @override
  String get calendarNotConnected =>
      'Подключите Google Calendar в настройках HomePlace, чтобы видеть события здесь.';

  @override
  String get noCalendarEvents => 'Ближайших событий в календаре нет.';

  @override
  String get addCalendarEvent => 'Добавить событие';

  @override
  String get editCalendarEvent => 'Изменить событие';

  @override
  String get eventTitle => 'Название события';

  @override
  String get eventLocation => 'Место (необязательно)';

  @override
  String get eventStarts => 'Начало';

  @override
  String get eventEnds => 'Окончание';

  @override
  String get noEventsOnDay => 'На этот день ничего не запланировано.';

  @override
  String get deleteCalendarEventTitle => 'Удалить событие?';

  @override
  String deleteCalendarEventBody(String title) {
    return 'Событие «$title» будет удалено из календаря.';
  }

  @override
  String get repeatFlexible => 'Свой интервал';

  @override
  String get repeatEvery => 'Каждые';

  @override
  String get requestsTitle => 'Заявки на медиа';

  @override
  String get requestsBody =>
      'Поиск по подключённым библиотекам Sonarr и Radarr.';

  @override
  String get searchMedia => 'Найти фильм или сериал';

  @override
  String get search => 'Найти';

  @override
  String get request => 'Заказать';

  @override
  String get inLibrary => 'Уже в библиотеке';

  @override
  String get noMediaServices =>
      'Сначала подключите Sonarr или Radarr в настройках HomePlace.';

  @override
  String requestSent(String title) {
    return 'Заявка отправлена: $title';
  }

  @override
  String get queue => 'Очередь';

  @override
  String get upcomingMedia => 'Скоро';

  @override
  String get downloads => 'Загрузки';

  @override
  String activeDownloads(int count) {
    return 'Активных: $count';
  }

  @override
  String get monitoringTitle => 'Небольшой, но внимательный';

  @override
  String get monitoringBody =>
      'Живая сводка проверок, которые уже выполняет HomePlace.';

  @override
  String onlineCount(int online, int total) {
    return 'В сети $online из $total';
  }

  @override
  String get allQuiet => 'Всё спокойно';

  @override
  String get recentEvents => 'Последние события';

  @override
  String get noMonitors =>
      'Добавьте проверки доступности плиткам на панели, чтобы видеть их здесь.';

  @override
  String get telegramTitle => 'Связь с Telegram';

  @override
  String get telegramConnected => 'Подключён и готов';

  @override
  String get telegramDisconnected => 'Не настроен на сервере';

  @override
  String get telegramTest => 'Проверить связь';

  @override
  String get telegramSent => 'Тестовое сообщение отправлено в Telegram.';

  @override
  String get refresh => 'Обновить';

  @override
  String get settings => 'Настройки подключения';

  @override
  String get loadingHome => 'Собираем ваш HomePlace…';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get permissionsRequired =>
      'Переподключите устройство, чтобы подтвердить новые разрешения приложения.';

  @override
  String get today => 'Сегодня';

  @override
  String get tomorrow => 'Завтра';

  @override
  String get allDay => 'Весь день';

  @override
  String get clipboardTitle => 'Общий буфер';

  @override
  String get clipboardBody =>
      'Отправьте текст из буфера Android на другие подтверждённые устройства.';

  @override
  String get clipboardSend => 'Отправить буфер';

  @override
  String clipboardIncoming(String device) {
    return 'Буфер с устройства $device';
  }

  @override
  String get clipboardCopy => 'Скопировать';

  @override
  String get clipboardDismiss => 'Отклонить';

  @override
  String clipboardSent(int count) {
    return 'Буфер отправлен на устройств: $count.';
  }

  @override
  String get clipboardEmpty => 'В буфере обмена нет текста.';

  @override
  String get clipboardNoDevices =>
      'К этому аккаунту не подключено другое совместимое устройство.';

  @override
  String get automaticClipboard => 'Отправлять буфер автоматически';

  @override
  String get automaticClipboardBody =>
      'Пока HomePlace открыт, изменённый текст отправляется на ваши подтверждённые устройства. Получение всё равно требует подтверждения.';

  @override
  String automaticClipboardSent(int count) {
    return 'Новый текст отправлен на устройств: $count.';
  }

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get appearance => 'Оформление';

  @override
  String get appVersion => 'Версия приложения';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get themeLight => 'Светлое';

  @override
  String get themeDark => 'Тёмное';

  @override
  String get connectionSecurity => 'Безопасность подключения';

  @override
  String get localUnencryptedConnection =>
      'Незашифрованное подключение в локальной сети';

  @override
  String get serverIdentity => 'ID сервера';

  @override
  String get readyToShare => 'Готово к отправке';

  @override
  String get choose => 'Выбрать';

  @override
  String get chooseDevice => 'Выберите устройство';

  @override
  String get onlyYourDevices =>
      'Ваши устройства изолированы внутри аккаунта. Семейные появляются только после явного разрешения их владельца.';

  @override
  String get noShareDevices =>
      'Нет доступных совместимых подтверждённых устройств.';

  @override
  String get yourDevice => 'Ваше устройство';

  @override
  String householdDevice(String owner) {
    return 'Семья · $owner';
  }

  @override
  String get deviceOnline => 'Сейчас в сети';

  @override
  String get deviceOffline => 'Получит при открытии HomePlace';

  @override
  String get confirmShareTitle => 'Отправить этот объект?';

  @override
  String confirmShareBody(String device) {
    return 'HomePlace отправит его только на устройство «$device». Предложение исчезнет через пять минут.';
  }

  @override
  String confirmHouseholdShareBody(String owner, String device) {
    return 'Это устройство принадлежит пользователю $owner. После подтверждения HomePlace отправит объект только на «$device». Предложение исчезнет через пять минут.';
  }

  @override
  String get send => 'Отправить';

  @override
  String shareSent(String device) {
    return 'Отправлено на устройство «$device».';
  }

  @override
  String get recentTransfers => 'Недавние передачи';

  @override
  String get clearHistory => 'Очистить';

  @override
  String get transferHistoryPrivacy =>
      'Хранится защищённо для этого профиля устройства. Содержимое и имена файлов сюда не записываются.';

  @override
  String transferSentTo(String device) {
    return 'Отправлено на «$device»';
  }

  @override
  String transferReceivedFrom(String device) {
    return 'Получено от «$device»';
  }

  @override
  String incomingShare(String device) {
    return 'От устройства «$device»';
  }

  @override
  String get decline => 'Отклонить';

  @override
  String get acceptAndSave => 'Принять и сохранить';

  @override
  String get open => 'Открыть';

  @override
  String fileSaved(String filename) {
    return 'Файл $filename сохранён в Downloads/HomePlace.';
  }

  @override
  String get upcomingReminders => 'Ближайшие';

  @override
  String get overdueReminders => 'Прошедшие';

  @override
  String get completedReminders => 'Выполненные';

  @override
  String get overdue => 'Просрочено';

  @override
  String get editReminder => 'Изменить напоминание';

  @override
  String get restore => 'Вернуть';

  @override
  String get clearCompleted => 'Очистить выполненные';

  @override
  String get deleteReminderTitle => 'Удалить напоминание?';

  @override
  String deleteReminderBody(String title) {
    return 'Напоминание «$title» будет удалено без возможности восстановления.';
  }

  @override
  String get clearCompletedTitle => 'Удалить выполненные?';

  @override
  String get clearCompletedBody =>
      'Все выполненные напоминания этого аккаунта будут удалены без возможности восстановления.';
}
