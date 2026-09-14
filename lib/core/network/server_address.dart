import 'dart:io';

enum ConnectionSecurity { trustedHttps, localHttp, confirmedCertificate }

final class ServerAddress {
  const ServerAddress({
    required this.uri,
    required this.isLocal,
    required this.security,
    this.certificateFingerprint,
  });

  final Uri uri;
  final bool isLocal;
  final ConnectionSecurity security;
  final String? certificateFingerprint;

  ServerAddress trustFingerprint(String fingerprint) => ServerAddress(
    uri: uri,
    isLocal: isLocal,
    security: ConnectionSecurity.confirmedCertificate,
    certificateFingerprint: fingerprint,
  );
}

sealed class AddressValidation {
  const AddressValidation();
}

final class ValidAddress extends AddressValidation {
  const ValidAddress(this.address);
  final ServerAddress address;
}

final class InvalidAddress extends AddressValidation {
  const InvalidAddress(this.message);
  final String message;
}

abstract final class ServerAddressNormalizer {
  static AddressValidation normalize(String input) {
    final raw = input.trim().replaceFirst(RegExp(r'/+$'), '');
    if (raw.isEmpty) return const InvalidAddress('Enter a server address.');
    if (RegExp(r'\s').hasMatch(raw)) {
      return const InvalidAddress('The address cannot contain spaces.');
    }

    final hasScheme = raw.contains('://');
    if (hasScheme) {
      final scheme = raw.substring(0, raw.indexOf('://')).toLowerCase();
      if (scheme != 'http' && scheme != 'https') {
        return const InvalidAddress('Use an HTTP or HTTPS address.');
      }
    }

    final initial = Uri.tryParse(hasScheme ? raw : 'http://$raw');
    if (initial == null || initial.host.isEmpty || initial.port == 0) {
      return const InvalidAddress(
        'Check the server name, IP address, and port.',
      );
    }
    if (initial.userInfo.isNotEmpty) {
      return const InvalidAddress(
        'Credentials cannot be included in the server address.',
      );
    }
    if ((initial.path.isNotEmpty && initial.path != '/') ||
        initial.hasQuery ||
        initial.hasFragment) {
      return const InvalidAddress(
        'Enter the HomePlace server address without a path, query, or fragment.',
      );
    }

    final local = _isLocalHost(initial.host);
    final scheme = hasScheme
        ? initial.scheme.toLowerCase()
        : (local ? 'http' : 'https');
    if (scheme == 'http' && !local) {
      return const InvalidAddress('Public server addresses must use HTTPS.');
    }
    final uri = initial.replace(scheme: scheme, path: '');
    return ValidAddress(
      ServerAddress(
        uri: uri,
        isLocal: local,
        security: scheme == 'https'
            ? ConnectionSecurity.trustedHttps
            : ConnectionSecurity.localHttp,
      ),
    );
  }

  static bool _isLocalHost(String host) {
    final value = host.toLowerCase();
    if (value == 'localhost' || value.endsWith('.local')) return true;
    if (!value.contains('.') && !value.contains(':')) return true;

    final ipv4 = value.split('.').map(int.tryParse).toList(growable: false);
    if (ipv4.length == 4 &&
        ipv4.every((part) => part != null && part >= 0 && part <= 255)) {
      final octets = ipv4.cast<int>();
      return octets[0] == 10 ||
          octets[0] == 127 ||
          (octets[0] == 192 && octets[1] == 168) ||
          (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
          (octets[0] == 169 && octets[1] == 254);
    }

    final address = InternetAddress.tryParse(value);
    if (address?.type != InternetAddressType.IPv6) return false;
    final bytes = address!.rawAddress;
    final loopback =
        bytes.take(15).every((byte) => byte == 0) && bytes.last == 1;
    final uniqueLocal = bytes.first & 0xfe == 0xfc;
    final linkLocal = bytes.first == 0xfe && bytes[1] & 0xc0 == 0x80;
    return loopback || uniqueLocal || linkLocal;
  }
}
