import '../features/connection/connection_controller.dart';
import 'link_client.dart';

final class MediaTitle {
  const MediaTitle({
    required this.id,
    required this.kind,
    required this.title,
    required this.originalTitle,
    required this.overview,
    required this.status,
    this.poster,
    this.year,
    this.rating,
  });

  final int id;
  final String kind;
  final String title;
  final String? originalTitle;
  final String overview;
  final String status;
  final String? poster;
  final int? year;
  final double? rating;

  factory MediaTitle.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! int ||
        (value['id'] as int) < 1 ||
        !['movie', 'tv'].contains(value['kind']) ||
        value['title'] is! String ||
        (value['title'] as String).trim().isEmpty ||
        value['status'] is! String) {
      throw const FormatException('Invalid media title.');
    }
    return MediaTitle(
      id: value['id'] as int,
      kind: value['kind'] as String,
      title: value['title'] as String,
      originalTitle: value['originalTitle'] as String?,
      overview: value['overview'] as String? ?? '',
      status: value['status'] as String,
      poster: safeMediaImagePath(value['poster']),
      year: value['year'] as int?,
      rating: (value['rating'] as num?)?.toDouble(),
    );
  }
}

String? safeMediaImagePath(Object? value) {
  if (value is! String || value.length > 600) return null;
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasFragment ||
      uri.pathSegments.contains('..') ||
      !(uri.path == '/api/media/tmdb-image' ||
          uri.path.startsWith('/api/media/jellyfin-image/'))) {
    return null;
  }
  return value;
}

final class MediaCatalog {
  const MediaCatalog({
    required this.configured,
    required this.unavailable,
    required this.items,
    required this.page,
    required this.pages,
  });
  final bool configured;
  final bool unavailable;
  final List<MediaTitle> items;
  final int page;
  final int pages;

  factory MediaCatalog.fromJson(Map<String, dynamic> value) {
    final rows = value['items'];
    if (value['configured'] is! bool ||
        rows is! List ||
        rows.length > 100 ||
        value['page'] is! int ||
        value['pages'] is! int) {
      throw const FormatException('Invalid media catalog.');
    }
    return MediaCatalog(
      configured: value['configured'] as bool,
      unavailable: value['unavailable'] == true,
      items: rows.map(MediaTitle.fromJson).toList(growable: false),
      page: value['page'] as int,
      pages: value['pages'] as int,
    );
  }
}

final class MediaSeason {
  const MediaSeason(this.number, this.name);
  final int number;
  final String name;
}

final class MediaProfile {
  const MediaProfile(this.key, this.label);
  final String key;
  final String label;
}

final class MediaDetails {
  const MediaDetails(this.title, this.seasons, this.profiles);
  final MediaTitle title;
  final List<MediaSeason> seasons;
  final List<MediaProfile> profiles;

  factory MediaDetails.fromJson(Map<String, dynamic> value) {
    final details = value['details'];
    final profiles = value['profiles'];
    if (details is! Map<String, dynamic> || profiles is! List) {
      throw const FormatException('Invalid media details.');
    }
    final seasons = details['seasons'];
    if (seasons is! List || seasons.length > 100 || profiles.length > 100) {
      throw const FormatException('Invalid media options.');
    }
    return MediaDetails(
      MediaTitle.fromJson(details),
      seasons
          .map((row) {
            if (row is! Map<String, dynamic> || row['number'] is! int) {
              throw const FormatException('Invalid media season.');
            }
            return MediaSeason(
              row['number'] as int,
              row['name'] as String? ?? '',
            );
          })
          .toList(growable: false),
      profiles
          .map((row) {
            if (row is! Map<String, dynamic> ||
                row['key'] is! String ||
                row['label'] is! String) {
              throw const FormatException('Invalid media profile.');
            }
            return MediaProfile(row['key'] as String, row['label'] as String);
          })
          .toList(growable: false),
    );
  }
}

abstract interface class MediaGateway {
  Future<LinkResult<MediaCatalog>> discover(
    AuthenticatedLinkSession session, {
    required String query,
    required String kind,
    required String category,
    required String language,
    required int page,
  });
  Future<LinkResult<MediaDetails>> details(
    AuthenticatedLinkSession session,
    MediaTitle title,
    String language,
  );
  Future<LinkResult<void>> request(
    AuthenticatedLinkSession session,
    MediaTitle title, {
    List<int>? seasons,
    String? profileKey,
  });
}

final class MediaApi implements MediaGateway {
  const MediaApi({this.client = const HttpLinkService()});
  final HttpLinkService client;

  @override
  Future<LinkResult<MediaCatalog>> discover(
    AuthenticatedLinkSession session, {
    required String query,
    required String kind,
    required String category,
    required String language,
    required int page,
  }) async {
    final params = <String, String>{
      'kind': kind,
      'category': category,
      'page': '$page',
      'lang': language,
      if (query.trim().isNotEmpty) 'q': query.trim(),
    };
    final path = Uri(
      path: '/api/link/media',
      queryParameters: params,
    ).toString();
    final result = await client.requestJson(
      session.address,
      'GET',
      path,
      credential: session.credential,
      maxResponseBytes: 512 * 1024,
    );
    if (result case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      return LinkSuccess(
        MediaCatalog.fromJson(
          (result as LinkSuccess<Map<String, dynamic>>).value,
        ),
      );
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned invalid media results.',
      );
    }
  }

  @override
  Future<LinkResult<MediaDetails>> details(
    AuthenticatedLinkSession session,
    MediaTitle title,
    String language,
  ) async {
    final path = '/api/link/media/${title.kind}/${title.id}?lang=$language';
    final result = await client.requestJson(
      session.address,
      'GET',
      path,
      credential: session.credential,
      maxResponseBytes: 128 * 1024,
    );
    if (result case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      return LinkSuccess(
        MediaDetails.fromJson(
          (result as LinkSuccess<Map<String, dynamic>>).value,
        ),
      );
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned invalid media details.',
      );
    }
  }

  @override
  Future<LinkResult<void>> request(
    AuthenticatedLinkSession session,
    MediaTitle title, {
    List<int>? seasons,
    String? profileKey,
  }) async {
    final result = await client.requestJson(
      session.address,
      'POST',
      '/api/link/media/requests',
      credential: session.credential,
      body: {
        'kind': title.kind,
        'mediaId': title.id,
        ...?seasons == null ? null : {'seasons': seasons},
        ...?profileKey == null ? null : {'profileKey': profileKey},
      },
    );
    if (result case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    final value = (result as LinkSuccess<Map<String, dynamic>>).value;
    if (value['ok'] != true) {
      return LinkFailure(
        LinkFailureKind.invalidResponse,
        value['error'] as String? ?? 'HomePlace did not accept the request.',
      );
    }
    return const LinkSuccess(null);
  }
}
