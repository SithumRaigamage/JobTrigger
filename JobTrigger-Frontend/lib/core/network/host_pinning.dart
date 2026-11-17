import 'package:dio/dio.dart';

/// Thrown (inside a [DioException]) when a request would leave the host a
/// client's credentials belong to.
class ForeignHostRequest implements Exception {
  const ForeignHostRequest(this.host);

  final String host;

  @override
  String toString() => 'Refused to send credentials to foreign host $host';
}

/// AUD-45: a client built with one server's credentials (Basic Auth or a
/// Bearer token in its default headers) refuses any request whose scheme,
/// host, or port differ from its own base URL. Dio sends absolute URLs as
/// given, with the default headers, so without this one unrewritten URL
/// (a notification tap did exactly that) was enough to hand one server's
/// credentials to another.
///
/// Add it first, so nothing else (a crumb fetch) runs for a refused
/// request. Paths under the base URL, relative or absolute, pass.
Interceptor hostPinningInterceptor() => InterceptorsWrapper(
  onRequest: (options, handler) {
    final base = Uri.tryParse(options.baseUrl);
    final target = options.uri;
    if (base == null ||
        target.scheme != base.scheme ||
        target.host.toLowerCase() != base.host.toLowerCase() ||
        target.port != base.port) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: ForeignHostRequest(target.host),
          message: 'Request to a host other than the server it belongs to',
        ),
      );
    }
    handler.next(options);
  },
);
