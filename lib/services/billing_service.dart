import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Play Billing for the one-time Fidelis Premium unlock ($9.99 managed product).
class BillingService {
  static const String premiumProductId = 'fidelis_premium';
  static final ValueNotifier<bool> premium = ValueNotifier<bool>(false);
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      premium.value = prefs.getBool('premium_owned') ?? false;
      final avail = await InAppPurchase.instance.isAvailable();
      if (!avail) return;
      _sub = InAppPurchase.instance.purchaseStream.listen(_onPurchases);
      await restore();
    } catch (_) {}
  }

  static Future<void> restore() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {}
  }

  /// Returns true if the purchase flow was started successfully.
  static Future<bool> buyPremium() async {
    try {
      final resp = await InAppPurchase.instance.queryProductDetails({premiumProductId});
      if (resp.productDetails.isEmpty) return false;
      final param = PurchaseParam(productDetails: resp.productDetails.first);
      return await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
    } catch (_) {
      return false;
    }
  }

  static Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == premiumProductId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        premium.value = true;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('premium_owned', true);
        } catch (_) {}
      }
      if (purchase.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(purchase);
        } catch (_) {}
      }
    }
  }
}