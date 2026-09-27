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
  String get savedConnectionTitle => 'Ваш HomePlace сохранён';

  @override
  String get savedConnectionUnavailable =>
      'Сервер сейчас недоступен. Подключение осталось на устройстве.';

  @override
  String get retryConnection => 'Повторить подключение';

  @override
  String get changeServerAddress => 'Указать другой адрес';

  @override
  String get plantsTitle => 'Мои растения';

  @override
  String get plantsSubtitle => 'Спокойный уход за тем, что растёт дома.';

  @override
  String get plantsEmpty => 'Добавьте первое растение и ритм его полива.';

  @override
  String get plantsSeeAll => 'Все растения';

  @override
  String get plantsAdd => 'Добавить растение';

  @override
  String get plantsName => 'Название';

  @override
  String get plantsSpecies => 'Вид растения';

  @override
  String get plantsRoom => 'Комната или место';

  @override
  String get plantsNotes => 'Заметки по уходу';

  @override
  String get plantsPhoto => 'Добавить фото';

  @override
  String get plantsChangePhoto => 'Заменить фото';

  @override
  String get plantsGallery => 'Выбрать из галереи';

  @override
  String get plantsCamera => 'Сфотографировать';

  @override
  String plantsEveryDays(int days) {
    return 'Поливать каждые $days дн.';
  }

  @override
  String get plantsEveryDay => 'Поливать каждый день';

  @override
  String get plantsInterval => 'Интервал полива';

  @override
  String get plantsLastWatered => 'Последний полив';

  @override
  String get plantsWaterNow => 'Полито сейчас';

  @override
  String get plantsWatered => 'Полив отмечен';

  @override
  String get plantsUndo => 'Отменить';

  @override
  String get plantsDueToday => 'Полить сегодня';

  @override
  String plantsOverdue(int days) {
    return 'Просрочено на $days дн.';
  }

  @override
  String plantsDueIn(int days) {
    return 'Через $days дн.';
  }

  @override
  String plantsDueCount(int count) {
    return 'Нужен полив: $count';
  }

  @override
  String get plantsAllGood => 'Все политы';

  @override
  String get plantsEdit => 'Изменить растение';

  @override
  String get plantsSave => 'Сохранить растение';

  @override
  String get plantsDelete => 'Удалить растение';

  @override
  String get plantsDeleteConfirm =>
      'Удалить растение и его фото с этого устройства?';

  @override
  String get plantsLocalOnly =>
      'Карточки хранятся в закрытом хранилище приложения для этого подключения и не отправляются в HomePlace.';

  @override
  String get plantsLoadError =>
      'Не удалось загрузить карточки растений. Повторите попытку.';

  @override
  String get plantsSaveError =>
      'Не удалось сохранить растение. Повторите попытку.';

  @override
  String get plantsPhotoError =>
      'Не удалось использовать фото. Выберите изображение поменьше.';

  @override
  String get plantsPickDate => 'Выбрать дату';

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
  String get transfersTab => 'Передачи';

  @override
  String get monitorTab => 'Контроль';

  @override
  String get everythingInPlace => 'Всё на своих местах';

  @override
  String get homeOverviewBody =>
      'Растения и ближайшие домашние дела — без лишнего.';

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
  String get monitorOverviewTab => 'Обзор';

  @override
  String get monitorServicesTab => 'Сервисы';

  @override
  String get monitorContainersTab => 'Контейнеры';

  @override
  String get monitorEventsTab => 'События';

  @override
  String get monitoredChecksExplanation =>
      'Это проверки доступности, а не Docker-контейнеры.';

  @override
  String get containerSummary => 'Docker-контейнеры';

  @override
  String get totalContainers => 'Всего';

  @override
  String get runningContainers => 'Запущено';

  @override
  String get stoppedContainers => 'Остановлено';

  @override
  String get containerProblems => 'Проблемы';

  @override
  String get noContainers =>
      'На настроенных Docker-хостах контейнеры не найдены.';

  @override
  String get containerRunning => 'Запущен';

  @override
  String get containerExited => 'Остановлен';

  @override
  String get containerPaused => 'На паузе';

  @override
  String get containerRestarting => 'Перезапускается';

  @override
  String get containerDead => 'Недоступен';

  @override
  String get containerCreated => 'Создан';

  @override
  String get unknownState => 'Неизвестно';

  @override
  String get serviceOnline => 'В сети';

  @override
  String get serviceOffline => 'Не в сети';

  @override
  String get averageLatency => 'Средняя задержка';

  @override
  String lastChecked(String time) {
    return 'Проверено: $time';
  }

  @override
  String get noRecentEvents => 'Недавних событий мониторинга нет.';

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
  String get preparingShare => 'Готовим устройства для безопасной отправки…';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get errorDetails => 'Требуется внимание';

  @override
  String get dismissError => 'Скрыть';

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
    return 'HomePlace отправит его только на устройство «$device». Предложение исчезнет через 30 минут.';
  }

  @override
  String confirmMultipleShareBody(int count, String device) {
    return 'HomePlace отправит $count объектов только на устройство «$device». Каждое предложение исчезнет через 30 минут.';
  }

  @override
  String confirmMultipleHouseholdShareBody(
    int count,
    String owner,
    String device,
  ) {
    return 'Это устройство принадлежит пользователю $owner. После подтверждения HomePlace отправит $count объектов только на «$device». Каждое предложение исчезнет через 30 минут.';
  }

  @override
  String confirmHouseholdShareBody(String owner, String device) {
    return 'Это устройство принадлежит пользователю $owner. После подтверждения HomePlace отправит объект только на «$device». Предложение исчезнет через 30 минут.';
  }

  @override
  String get send => 'Отправить';

  @override
  String shareSent(String device) {
    return 'Отправлено на устройство «$device».';
  }

  @override
  String itemsReadyToShare(int count) {
    return 'Готово к отправке: $count';
  }

  @override
  String get transfersTitle => 'Передачи';

  @override
  String get transfersSubtitle =>
      'Проверяйте каждый входящий объект и точно выбирайте получателя исходящих данных.';

  @override
  String get exchangeTitle => 'Временная ссылка на текст';

  @override
  String get exchangeSubtitle =>
      'Передайте текст другому устройству с входом в ваш аккаунт HomePlace. Прямая передача между устройствами остаётся отдельно.';

  @override
  String get exchangeOpen => 'Открыть временные ссылки';

  @override
  String get exchangeText => 'Текст для передачи';

  @override
  String get exchangeAccountOnly =>
      'Ссылку может открыть только ваш аккаунт HomePlace. Тот, у кого есть ссылка и доступ к аккаунту, сможет прочитать текст.';

  @override
  String get exchangeExpiry => 'Срок действия';

  @override
  String get exchangeTenMinutes => '10 минут';

  @override
  String get exchangeOneHour => '1 час';

  @override
  String get exchangeOneDay => '1 день';

  @override
  String get exchangeOneTime => 'Удалить после первого открытия';

  @override
  String get exchangeOneTimeWarning =>
      'Прерванное первое открытие нельзя повторить.';

  @override
  String get exchangeCreate => 'Создать приватную ссылку';

  @override
  String get exchangeActive => 'Активные ссылки на текст';

  @override
  String get exchangeEmpty => 'Активных ссылок на текст нет.';

  @override
  String get exchangeTextLink => 'Приватная ссылка на текст';

  @override
  String get exchangeReusable => 'Доступна до конца срока';

  @override
  String get exchangeCopy => 'Скопировать ссылку';

  @override
  String get exchangeCopied => 'Ссылка скопирована. Храните её как секрет.';

  @override
  String get exchangeClipboardWarning =>
      'Автоматическая передача буфера включена. Копирование ссылки может отправить её на ваши разрешённые устройства.';

  @override
  String get exchangeRevoke => 'Отозвать ссылку';

  @override
  String get exchangeRevokeConfirm =>
      'Ссылка сразу перестанет работать. Отозвать её?';

  @override
  String get exchangeReconnect =>
      'Подключитесь к HomePlace и попробуйте снова.';

  @override
  String get fileExchangeTitle => 'Обмен файлами';

  @override
  String get fileExchangeSubtitle =>
      'Загрузите файл и поделитесь краткосрочной ссылкой для скачивания. Прямая передача между устройствами остаётся отдельно.';

  @override
  String get fileExchangeOpen => 'Открыть обмен файлами';

  @override
  String get fileExchangeChoose => 'Выбрать любой файл';

  @override
  String fileExchangeSizeError(String limit) {
    return 'Выберите непустой файл в пределах лимита загрузки этого сервера — $limit.';
  }

  @override
  String fileExchangeLimit(String limit) {
    return 'Текущий лимит сервера: $limit';
  }

  @override
  String get fileExchangePickError =>
      'Не удалось открыть файл. Выберите его ещё раз.';

  @override
  String get fileExchangeAccess => 'Кто может скачать';

  @override
  String get fileExchangeAccount => 'Мой аккаунт HomePlace';

  @override
  String get fileExchangePublic => 'Любой, у кого есть ссылка';

  @override
  String get fileExchangePublicWarning =>
      'Эта ссылка — секрет. Любой, кто её получит, сможет скачать файл до истечения срока или отзыва ссылки. Не используйте её для личных файлов, если не доверяете всем получателям.';

  @override
  String get fileExchangeConfirmPublic => 'Создать внешнюю ссылку';

  @override
  String get fileExchangeUpload => 'Загрузить и создать ссылку';

  @override
  String get fileExchangeActive => 'Активные ссылки на файлы';

  @override
  String get fileExchangeEmpty => 'Активных ссылок на файлы нет.';

  @override
  String get fileExchangeReceive => 'Сохранить файл по ссылке';

  @override
  String get fileExchangeLink => 'Ссылка с этого сервера HomePlace';

  @override
  String get fileExchangeCheck => 'Проверить файл';

  @override
  String get fileExchangeInvalidLink =>
      'Введите код или ссылку на файл с подключённого сервера HomePlace.';

  @override
  String get fileExchangeDownload => 'Скачать в Загрузки';

  @override
  String get fileExchangeSaveConfirm =>
      'Подтвердите скачивание и сохранение файла на телефон.';

  @override
  String get fileExchangeOneTimeWarning =>
      'Ссылка одноразовая. Начало скачивания использует её, даже если передача прервётся.';

  @override
  String get fileExchangeSaveError =>
      'Не удалось сохранить файл. Перед повтором проверьте папку «Загрузки».';

  @override
  String get fileExchangeOpenSaved => 'Открыть сохранённый файл';

  @override
  String get fileExchangeOpenError =>
      'Android не смог открыть сохранённый файл.';

  @override
  String get noPendingTransfers =>
      'Сейчас нет передач, требующих вашего внимания.';

  @override
  String outgoingItems(int count) {
    return 'Ожидают отправки · $count';
  }

  @override
  String get waitingToSend => 'Ожидает выбора устройства';

  @override
  String get remove => 'Убрать';

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
  String incomingOffers(int count) {
    return 'Входящие объекты · $count';
  }

  @override
  String moreIncomingOffers(int count) {
    return 'Ещё входящих объектов: $count';
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

  @override
  String get homePlaceProfiles => 'Подключения HomePlace';

  @override
  String get activeProfile => 'Активно';

  @override
  String get connectAnotherHomePlace => 'Подключить другой HomePlace';

  @override
  String get cancelAddingConnection => 'Вернуться к подключённому HomePlace';

  @override
  String get backgroundDelivery => 'Фоновые проверки HomePlace';

  @override
  String get backgroundDeliveryBody =>
      'Android проверяет подключённые серверы HomePlace примерно раз в 15 минут. Система может отложить проверку ради батареи.';

  @override
  String get backgroundIncomingOffers => 'Входящие объекты в фоне';

  @override
  String get backgroundIncomingOffersBody =>
      'Проверять буфер, текст, ссылки и файлы, пока HomePlace закрыт. Принятие файла ставит проверенную загрузку в фон; текст, ссылки и буфер открывают HomePlace для подтверждения.';

  @override
  String get seamlessOwnAccountTransfers => 'Бесшовные файлы с моих устройств';

  @override
  String get seamlessOwnAccountTransfersBody =>
      'Автоматически принимать и сохранять проверенные файлы с другого устройства вашего аккаунта, в том числе во время включённых фоновых проверок. Семейные устройства, ссылки, текст и буфер всё равно требуют подтверждения.';

  @override
  String get notificationPermissionRequired =>
      'Разрешите уведомления HomePlace в настройках Android, чтобы включить фоновую доставку.';

  @override
  String get lastBackgroundCheck => 'Последняя фоновая проверка';

  @override
  String get backgroundNeverRun => 'Ожидаем первую проверку от Android.';

  @override
  String backgroundCheckedProfiles(String time, int count) {
    return '$time · Проверено подключений: $count';
  }

  @override
  String backgroundCheckFailed(String time) {
    return '$time · Проверка не завершилась и будет повторена.';
  }

  @override
  String get notificationHistory => 'История уведомлений';

  @override
  String get notificationHistoryPrivacy =>
      'Хранится в зашифрованном хранилище устройства только для этого профиля HomePlace.';

  @override
  String get viewAll => 'Показать все';

  @override
  String get allSections => 'Все разделы';

  @override
  String get allSectionsBody =>
      'То, что не вошло в основные вкладки. Оставьте только нужное.';

  @override
  String get customizeSections => 'Настроить разделы';

  @override
  String get customizeSectionsBody =>
      'Выберите, что показывать здесь. Основные вкладки останутся на месте.';

  @override
  String get restoreSections => 'Показать все разделы';

  @override
  String get hiddenSectionsEmpty =>
      'Дополнительные разделы скрыты. Откройте настройку, чтобы вернуть их.';

  @override
  String get everydaySection => 'Каждый день';

  @override
  String get sharingSection => 'Устройства и обмен';

  @override
  String get servicesSection => 'Дом и сервисы';

  @override
  String get systemSection => 'Система';

  @override
  String get availableNow => 'Уже работает';

  @override
  String get preview => 'Макет';

  @override
  String get configureOnServer => 'Настройте в веб-интерфейсе HomePlace';

  @override
  String get devicesTitle => 'Устройства';

  @override
  String get devicesBody =>
      'Присутствие, владелец и только те действия, которые действительно поддерживает устройство.';

  @override
  String get shareCapableDevices => 'Доступны для передачи';

  @override
  String get noLinkedDevices =>
      'Сейчас нет других доступных совместимых устройств.';

  @override
  String get capabilities => 'Возможности';

  @override
  String get clipboardModuleBody =>
      'Приватная передача текста с подтверждением и защитой от зацикливания.';

  @override
  String get notificationsModuleBody =>
      'История доставки и подтверждения важных действий только для этого профиля.';

  @override
  String get automationsTitle => 'Автоматизации';

  @override
  String get automationsBody =>
      'Связывайте явные события и действия без неограниченного доступа к устройствам.';

  @override
  String get automationArrival => 'Когда я прихожу домой';

  @override
  String get automationArrivalAction => 'Включить сцену в прихожей';

  @override
  String get automationDownload => 'Когда загрузка завершена';

  @override
  String get automationDownloadAction => 'Уведомить телефон';

  @override
  String get automationBattery => 'Когда питание сервера на исходе';

  @override
  String get automationBatteryAction => 'Отправить предупреждение в Telegram';

  @override
  String get automationSafety =>
      'Перед включением правило показывает триггер, получателя и необходимое разрешение.';

  @override
  String get smartHomeTitle => 'Умный дом';

  @override
  String get smartHomeBody =>
      'Комнаты, сцены, датчики и безопасное управление через подключение Home Assistant в HomePlace.';

  @override
  String get smartHomeEmpty =>
      'Подключите Home Assistant на сервере, чтобы здесь появились настоящие комнаты и элементы управления.';

  @override
  String get rooms => 'Комнаты';

  @override
  String get scenes => 'Сцены';

  @override
  String get sensors => 'Датчики';

  @override
  String get securityCenter => 'Безопасность и приватность';

  @override
  String get securityCenterBody =>
      'Проверяйте идентификатор сервера, защиту канала, изоляцию аккаунтов и выданные разрешения.';

  @override
  String get accountIsolation => 'Обмен изолирован по аккаунтам';

  @override
  String get accountIsolationBody =>
      'Данные идут только на выбранное подтверждённое устройство. Передача семье всегда требует подтверждения.';

  @override
  String get explicitCapabilities => 'Явные возможности';

  @override
  String get explicitCapabilitiesBody =>
      'Телефон объявляет только действия, доступные в этой ОС и с текущими разрешениями.';

  @override
  String get verifiedIdentity => 'Проверенная личность сервера';

  @override
  String get verifiedIdentityBody =>
      'HomePlace сверяет ID сервера при переподключении и не принимает неверный сертификат без предупреждения.';

  @override
  String get openSection => 'Открыть раздел';

  @override
  String get manageSettings => 'Открыть настройки';

  @override
  String get calendarModuleBody =>
      'Календарь, напоминания, растения и идеи в одном месте.';

  @override
  String get mediaModuleBody =>
      'Поиск в Radarr и Sonarr и контроль очередей загрузки.';

  @override
  String get transfersModuleBody =>
      'Отправка и приём текста, ссылок и файлов с точным выбором получателя.';

  @override
  String get monitoringModuleBody =>
      'Проверки доступности, Docker-контейнеры, задержка сервисов и события.';

  @override
  String get telegramModuleBody =>
      'Оповещения под управлением сервера и проверка подключения.';

  @override
  String get settingsModuleBody =>
      'Язык, тема, фоновая доставка, профили и безопасность подключения.';

  @override
  String get privateWorkspace => 'Приватное пространство';

  @override
  String get plannedServerApi => 'Ожидает совместимого API сервера';

  @override
  String get ideasTitle => 'Идеи';

  @override
  String get ideasSubtitle => 'Сохраните мысль, пока она не потерялась.';

  @override
  String get ideasLocalOnly =>
      'Только на этом телефоне. У этого устройства пока нет доступа к идеям аккаунта.';

  @override
  String get ideasServerSynced =>
      'Сохраняется в вашем аккаунте HomePlace и доступно на ваших устройствах.';

  @override
  String get ideasSyncUnavailable =>
      'Идеи аккаунта сейчас недоступны. Идеи телефона не загружены на сервер.';

  @override
  String get ideasImportLocal => 'Импортировать идеи телефона';

  @override
  String get ideasImportPrompt =>
      'Скопировать идеи, сохранённые на телефоне, в ваш аккаунт HomePlace? Локальные копии останутся на этом устройстве.';

  @override
  String get ideasImportDone => 'Идеи телефона импортированы в HomePlace.';

  @override
  String get ideasModuleBody =>
      'Приватные заметки, категории и превращение в напоминания.';

  @override
  String get ideasCaptureHint => 'Идея, ссылка или следующий шаг…';

  @override
  String get ideasAdd => 'Сохранить идею';

  @override
  String get ideasAll => 'Все';

  @override
  String get ideasEmptyTitle => 'Чистый лист';

  @override
  String get ideasEmptyBody =>
      'Запишите первую мысль. Когда появится срок, превратите её в напоминание.';

  @override
  String get ideasInbox => 'Входящие';

  @override
  String get ideasHome => 'Дом';

  @override
  String get ideasWork => 'Работа';

  @override
  String get ideasMedia => 'Медиа';

  @override
  String get ideasLater => 'Потом';

  @override
  String get ideasCategory => 'Категория';

  @override
  String get ideasNewCategory => 'Новая категория';

  @override
  String get ideasCategoryName => 'Название категории';

  @override
  String get ideasCategoryExists => 'Выберите другое название категории.';

  @override
  String get ideasEdit => 'Изменить идею';

  @override
  String get ideasNote => 'Подробности';

  @override
  String get ideasPin => 'Закрепить идею';

  @override
  String get ideasUnpin => 'Открепить идею';

  @override
  String get ideasComplete => 'Отметить выполненной';

  @override
  String get ideasReopen => 'Вернуть идею';

  @override
  String get ideasPinned => 'Закреплено';

  @override
  String get ideasCompleted => 'Выполнено';

  @override
  String get ideasActive => 'Текущие';

  @override
  String get ideasArchive => 'Архив';

  @override
  String get ideasArchiveAction => 'В архив';

  @override
  String get ideasRestore => 'Вернуть из архива';

  @override
  String get ideasArchiveEmpty => 'В архиве пока нет идей.';

  @override
  String get ideasDuplicate => 'Дублировать';

  @override
  String get ideasDelete => 'Удалить идею';

  @override
  String get ideasDeleteConfirm => 'Удалить эту идею с телефона?';

  @override
  String get ideasToReminder => 'Сделать напоминанием';

  @override
  String get ideasCopy => 'Копировать текст';

  @override
  String get ideasClipboardWarning =>
      'Автоматическая передача буфера включена. Скопированный текст может отправиться на ваши подтверждённые устройства.';

  @override
  String get ideasCopyConfirm => 'Всё равно копировать';

  @override
  String get ideasSaveError => 'Не удалось сохранить идею. Попробуйте ещё раз.';

  @override
  String get ideasLoadError => 'Не удалось открыть идеи на этом устройстве.';

  @override
  String get ideasSave => 'Сохранить изменения';

  @override
  String get quickTransferTile => 'Добавить «Передачи» в быстрые настройки';

  @override
  String get quickTransferTileBody =>
      'Открывайте передачи из шторки Samsung, минуя главную страницу. Отправка по-прежнему требует подтверждения.';

  @override
  String get quickTransferTileAdded =>
      '«Передачи» добавлены в быстрые настройки.';

  @override
  String get quickTransferTileAlreadyAdded =>
      '«Передачи» уже есть в быстрых настройках.';

  @override
  String get quickTransferTileNotAdded =>
      'Плитка не добавлена. Её можно добавить вручную при редактировании быстрых настроек.';

  @override
  String get quickTransferTileUnavailable =>
      'Автоматическое добавление недоступно. Добавьте «Передачи HomePlace» в редакторе быстрых настроек.';

  @override
  String get androidNotificationSettings => 'Настройки уведомлений Android';

  @override
  String get androidNotificationSettingsBody =>
      'Управление разрешением, категориями и приватностью на экране блокировки.';
}
