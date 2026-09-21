import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/sharing/share_service.dart';
import 'package:homeplace/link/link_client.dart';

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
        'size': maxShareFileBytes,
      }),
      isNotNull,
    );
    expect(
      SharedContent.fromPlatform({
        'type': 'file',
        'path': '/tmp/item',
        'filename': 'item.bin',
        'size': maxShareFileBytes + 1,
      }),
      isNull,
    );
  });

  test('deduplicates the same pending Android share delivery', () {
    final pending = {
      'type': 'file',
      'path': '/private/cache/photo.jpg',
      'filename': 'photo.jpg',
      'mimeType': 'image/jpeg',
      'size': 2048,
    };

    final parsed = SharedContent.listFromPlatform([pending, pending]);

    expect(parsed, hasLength(1));
    expect(parsed.single.filename, 'photo.jpg');
  });

  test('keeps distinct files in one Android share batch', () {
    final parsed = SharedContent.listFromPlatform([
      {
        'type': 'file',
        'path': '/private/cache/one.bin',
        'filename': 'photo.jpg',
        'size': 2048,
      },
      {
        'type': 'file',
        'path': '/private/cache/two.bin',
        'filename': 'photo.jpg',
        'size': 2048,
      },
    ]);

    expect(parsed, hasLength(2));
  });
}
