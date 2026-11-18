# Billing Integration Guide

## Overview
This guide explains how to integrate the subscription and billing system into the Flutter app using **RevenueCat** and the backend endpoints described in `docs/subscription/references/api-reference-subscription.md`.

## Prerequisites
1. **RevenueCat account** – create a project and obtain the public API key for iOS and Android.
2. **Backend `billingEnabled` flag** – ensure the backend returns `billingEnabled: true` for the user (controlled via plan/grant).
3. **Payments.lk or other gateway** – optional if you want to accept one‑off payments; not required for recurring subscriptions.

## Step‑by‑Step Integration

### 1. Add RevenueCat dependency
```yaml
# pubspec.yaml
dependencies:
  revenuecat: ^latest_version
```
Run `flutter pub get`.

### 2. Initialize RevenueCat
```dart
import 'package:revenuecat/revenuecat.dart';

void initRevenueCat() {
  // Replace with your actual keys
  const String iosKey = 'your_ios_key';
  const String androidKey = 'your_android_key';
  Purchases.configure(
    options: PurchasesOptions(
      apiKey: Platform.isIOS ? iosKey : androidKey,
      userDefaultsSuite: Purchases.userDefaultsSuite,
    ),
  );
}
```
Call `initRevenueCat()` early in `main()`.

### 3. Create the notifiers (see `phase-1-subscription.md`)
- `entitlementsNotifierProvider`
- `billingClientProvider`
- `billingAvailableProvider`
- `paywallNotifierProvider`

### 4. Paywall Screen
```dart
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({Key? key}) : super(key: key);
  @override ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}
class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(paywallNotifierProvider.notifier).loadOffers();
  }
  @override
  Widget build(BuildContext context) {
    return ref.watch(paywallNotifierProvider).when(
      data: (state) => // build UI with offers,
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```
### 5. Purchase Flow
```dart
void _onPurchase(String packageId) async {
  final outcome = await ref.read(paywallNotifierProvider.notifier).purchase(packageId);
  switch (outcome) {
    case PaywallOutcome.purchased:
      // Entitlements already updated via listener
      Navigator.pop(context);
      break;
    case PaywallOutcome.restored:
      Navigator.pop(context);
      break;
    case PaywallOutcome.cancelled:
      // User dismissed the sheet
      break;
  }
}
```

### 5. Restore Purchases
```dart
void _onRestore() async {
  final outcome = await ref.read(paywallNotifierProvider.notifier).restore();
  // same switch as above
}
```

### 6. Backend Sync
After a purchase or restore, the app calls `POST /api/subscription/refresh` (handled internally by `paywallNotifierProvider`). The backend then re‑reads the user’s entitlement from RevenueCat and updates `entitlementsNotifierProvider`.

### 7. Web Checkout (optional)
- If you want to allow web card payments, expose `POST /api/billing/paddle/checkout` from your website.
- The frontend creates a Paddle transaction and shows the Paddle.js checkout.
- After purchase, the same refresh flow updates entitlements.

## Testing
- Use RevenueCat **sandbox** mode for iOS and Android.
- Simulate purchases via the RevenueCat dashboard.
- Verify that after a purchase the app shows Pro features and the backend endpoint `/api/subscription` returns the correct `plan` and `source`.

## Checklist
- [ ] RevenueCat SDK integrated and initialized.
- [ ] Entitlement notifier correctly displays Free/Pro.
- [ ] Paywall presents correct offers for the platform.
- [ ] Purchase flow updates entitlements and UI.
- [ ] Restore purchases works.
- [ ] Backend `/api/subscription` reflects the new plan after a purchase.
- [ ] `billingAvailableProvider` gates UI correctly.

*End of billing integration guide.*