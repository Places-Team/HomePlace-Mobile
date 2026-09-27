import '../features/connection/connection_controller.dart';
import 'link_client.dart';

abstract interface class IdeaGateway {
  Future<LinkResult<Map<String, dynamic>>> page(
    AuthenticatedLinkSession session, {
    String? cursor,
  });

  Future<LinkResult<Map<String, dynamic>>> command(
    AuthenticatedLinkSession session,
    Map<String, dynamic> body,
  );
}

final class IdeaApi implements IdeaGateway {
  const IdeaApi({HttpLinkService? client})
    : _client = client ?? const HttpLinkService();

  final HttpLinkService _client;

  @override
  Future<LinkResult<Map<String, dynamic>>> page(
    AuthenticatedLinkSession session, {
    String? cursor,
  }) => _client.requestJson(
    session.address,
    'GET',
    Uri(
      path: '/api/link/ideas',
      queryParameters: cursor == null ? null : {'cursor': cursor},
    ).toString(),
    credential: session.credential,
    maxResponseBytes: 524288,
  );

  @override
  Future<LinkResult<Map<String, dynamic>>> command(
    AuthenticatedLinkSession session,
    Map<String, dynamic> body,
  ) => _client.requestJson(
    session.address,
    'POST',
    '/api/link/ideas',
    credential: session.credential,
    body: body,
    maxResponseBytes: 524288,
  );
}
