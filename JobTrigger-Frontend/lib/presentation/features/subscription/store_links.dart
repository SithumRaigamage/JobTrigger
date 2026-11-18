import 'package:flutter/foundation.dart';

import '../../../domain/subscription/subscription_status.dart';

/// The platform's own page for managing or cancelling a subscription,
/// which is where Apple and Google require users to be sent.
Uri manageSubscriptionUri(TargetPlatform platform) =>
    platform == TargetPlatform.iOS
    ? Uri.parse('https://apps.apple.com/account/subscriptions')
    : Uri.parse(
        'https://play.google.com/store/account/subscriptions'
        '?package=com.sraig.jobtrigger',
      );

/// "App Store" or "Google Play", for copy about the user's store.
String storeNameFor(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ? 'App Store' : 'Google Play';

/// The store a subscription was bought in, from its source.
String? storeNameOf(SubscriptionSource? source) => switch (source) {
  SubscriptionSource.appStore => 'App Store',
  SubscriptionSource.playStore => 'Google Play',
  _ => null,
};
