import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/sharing/share_service.dart';
import 'package:homeplace/core/storage/transfer_activity_store.dart';

void main() {
  test('transfer activity serializes metadata without shared content', () {
    final activity = TransferActivity(
      direction: TransferDirection.sent,
      kind: SharedContentKind.file,
      peerName: 'Family tablet',
      at: DateTime.utc(2026, 9, 21, 12, 30),
    );

    final json = activity.toJson();
    expect(json.keys, containsAll(['direction', 'kind', 'peerName', 'at']));
    expect(json, isNot(contains('filename')));
    expect(json, isNot(contains('value')));
    final restored = TransferActivity.fromJson(json);
    expect(restored.direction, TransferDirection.sent);
    expect(restored.kind, SharedContentKind.file);
    expect(restored.peerName, 'Family tablet');
    expect(restored.at, DateTime.utc(2026, 9, 21, 12, 30));
  });
}
