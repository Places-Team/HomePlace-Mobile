import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/sharing/share_service.dart';

void main() {
  test('accepts bounded text and safe web links from Android', () {
    expect(
      SharedContent.fromPlatform({'type': 'text', 'value': 'hello'})?.kind,
      SharedContentKind.text,
    );
    expect(
      SharedContent.fromPlatform({
        'type': 'url',
        'value': 'https://example.com/path',
      })?.kind,
      SharedContentKind.url,
    );
    expect(
      SharedContent.fromPlatform({
        'type': 'url',
        'value': 'https://user:secret@example.com',
      }),
      isNull,
    );
    expect(
      SharedContent.fromPlatform({
        'type': 'url',
        'value': 'file:///private/data',
      }),
      isNull,
    );
  });

  test('rejects oversized or incomplete files', () {
    expect(
      SharedContent.fromPlatform({
        'type': 'file',
        'path': '/tmp/item',
        'filename': 'item.bin',
        'size': 5 * 1024 * 1024,
      }),
      isNotNull,
    );
    expect(
      SharedContent.fromPlatform({
        'type': 'file',
        'path': '/tmp/item',
        'filename': 'item.bin',
        'size': 5 * 1024 * 1024 + 1,
      }),
      isNull,
    );
  });
}
