import 'package:workmanager/workmanager.dart';

const backgroundHeartbeatTask = 'homeplace.backgroundHeartbeat';
const backgroundHeartbeatUniqueName = 'homeplace-periodic-heartbeat';
const backgroundHeartbeatNowUniqueName = 'homeplace-heartbeat-now';
const backgroundIncomingActionUniqueName = 'homeplace-incoming-action';

Future<void> scheduleIncomingActionProcessing() =>
    Workmanager().registerOneOffTask(
      backgroundIncomingActionUniqueName,
      backgroundHeartbeatTask,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 15),
    );
