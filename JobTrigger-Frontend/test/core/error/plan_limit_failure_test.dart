import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';

DioException _response(int status, Object? data) => DioException(
  requestOptions: RequestOptions(path: '/api/credentials'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/api/credentials'),
    statusCode: status,
    data: data,
  ),
);

void main() {
  test('a PLAN_LIMIT 403 becomes a PlanLimitFailure with the server copy', () {
    final failure = PlanLimitFailure.tryFrom(
      _response(403, {
        'message': 'Free includes one server.',
        'code': 'PLAN_LIMIT',
        'limit': 'maxCredentialsTotal',
      }),
    );
    expect(failure, isNotNull);
    expect(failure!.limit, 'maxCredentialsTotal');
    expect(failure.message, 'Free includes one server.');
  });

  test('any other 403, status or body is not a plan limit', () {
    expect(PlanLimitFailure.tryFrom(_response(403, {'message': 'no'})), isNull);
    expect(
      PlanLimitFailure.tryFrom(_response(400, {'code': 'PLAN_LIMIT'})),
      isNull,
    );
    expect(PlanLimitFailure.tryFrom(_response(403, '<html>')), isNull);
  });

  test('the shared mapping is unchanged: a 403 is still a PermissionFailure '
      'with its existing copy', () {
    final failure = AppFailure.fromDioException(
      _response(403, {'code': 'PLAN_LIMIT', 'limit': 'x', 'message': 'm'}),
    );
    expect(failure, isA<PermissionFailure>());
    expect(
      failure.message,
      "You don't have permission to do this on this server.",
    );
  });

  test('a cancelled purchase has no copy to show', () {
    expect(const PurchaseCancelled().message, isEmpty);
  });
}
