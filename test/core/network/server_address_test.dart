import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';

void main() {
  group('ServerAddressNormalizer', () {
    test('defaults a public hostname to HTTPS', () {
      final result = ServerAddressNormalizer.normalize('home.example.com');

      expect(result, isA<ValidAddress>());
      final address = (result as ValidAddress).address;
      expect(address.uri.toString(), 'https://home.example.com');
      expect(address.security, ConnectionSecurity.trustedHttps);
    });

    test('allows HTTP only on a private address', () {
      final result = ServerAddressNormalizer.normalize('http://192.168.1.20');

      expect(result, isA<ValidAddress>());
      expect(
        (result as ValidAddress).address.security,
        ConnectionSecurity.localHttp,
      );
    });

    test('supports bracketed IPv6 with a port', () {
      final result = ServerAddressNormalizer.normalize('[fd00::12]:8080');

      expect(result, isA<ValidAddress>());
      expect((result as ValidAddress).address.uri.scheme, 'http');
      expect(result.address.uri.host, 'fd00::12');
    });

    test('rejects public plain HTTP', () {
      final result = ServerAddressNormalizer.normalize(
        'http://home.example.com',
      );

      expect(result, isA<InvalidAddress>());
    });

    test('rejects paths and embedded credentials', () {
      expect(
        ServerAddressNormalizer.normalize('https://home.example.com/admin'),
        isA<InvalidAddress>(),
      );
      expect(
        ServerAddressNormalizer.normalize('https://user@home.example.com'),
        isA<InvalidAddress>(),
      );
    });

    test('rejects an invalid port without throwing', () {
      expect(
        ServerAddressNormalizer.normalize('home.example.com:not-a-port'),
        isA<InvalidAddress>(),
      );
    });
  });
}
