import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/subscription/billing_offer.dart';
import '../../domain/subscription/subscription_repository.dart';
import '../../domain/subscription/subscription_status.dart';
import '../billing/billing_client.dart';
import '../billing/revenuecat_billing_client.dart';
import '../models/subscription/subscription_dto.dart';

part 'subscription_repository_impl.g.dart';

/// The last `GET /api/subscription` body (non-secret). Listed in
/// `userScopedPrefKeys`, so sign-out removes it.
const subscriptionCacheKey = 'subscription_cache';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._dio, this._billing);

  final Dio _dio;
  final BillingClient _billing;

  @override
  Future<SubscriptionSnapshot?> cached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(subscriptionCacheKey);
      if (raw == null) return null;
      return SubscriptionDto.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      ).toDomain();
    } on Object {
      // A cache that can't be read is no cache.
      return null;
    }
  }

  @override
  Future<Result<SubscriptionSnapshot, AppFailure>> load() =>
      _snapshot(() => _dio.get<Map<String, dynamic>>('/api/subscription'));

  @override
  Future<Result<SubscriptionSnapshot, AppFailure>> refresh() => _snapshot(
    () => _dio.post<Map<String, dynamic>>('/api/subscription/refresh'),
  );

  Future<Result<SubscriptionSnapshot, AppFailure>> _snapshot(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) => guardRequest(() async {
    final body = (await call()).data!;
    final snapshot = SubscriptionDto.fromJson(body).toDomain();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(subscriptionCacheKey, jsonEncode(body));
    } on Object {
      // Best effort: the answer is still good without a cache.
    }
    return snapshot;
  });

  @override
  Future<Result<List<BillingOffer>, AppFailure>> offerings() =>
      _billingCall(_billing.offerings);

  @override
  Future<Result<void, AppFailure>> purchase(BillingOffer offer) =>
      _billingCall(() => _billing.purchase(offer));

  @override
  Future<Result<void, AppFailure>> restore() => _billingCall(_billing.restore);

  Future<Result<T, AppFailure>> _billingCall<T>(
    Future<T> Function() call,
  ) async {
    try {
      return Ok(await call());
    } on BillingCancelled {
      return const Err(PurchaseCancelled());
    } on BillingException catch (error) {
      return Err(UnknownFailure(error.debugMessage));
    }
  }
}

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) =>
    SubscriptionRepositoryImpl(
      ref.watch(dioBackendProvider),
      ref.watch(billingClientProvider),
    );
