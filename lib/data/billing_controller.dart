import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:quotation/config/revenuecat_config.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/membership_controller.dart';

/// Play and App Store product id. Import this into RevenueCat and attach it to [kPremiumEntitlementId].
const kPremiumMonthlyProductId = 'premium_monthly';

/// RevenueCat entitlement identifier. Must match the dashboard exactly.
const kPremiumEntitlementId = 'premium';

class BillingController extends ChangeNotifier {
  StreamSubscription<User?>? _authSub;
  Future<String?>? _configuring;
  bool _configured = false;
  bool _busy = false;
  String? _loggedInUid;
  String? lastError;

  bool get isBusy => _busy;

  Future<void> initialize() async {
    final code = await _ensureConfigured();
    if (code != null) {
      lastError = code;
      debugPrint('RevenueCat initialize: $code');
    }
  }

  /// Opens the monthly subscription sheet through RevenueCat.
  /// Returns an error code, or null when the sheet opened or the user cancelled.
  Future<String?> buyMonthly() async {
    if (_busy) return null;
    _busy = true;
    lastError = null;
    notifyListeners();
    try {
      final setup = await _ensureConfigured();
      if (setup != null) {
        lastError = setup;
        return lastError;
      }
      final offerings = await Purchases.getOfferings();
      final package = _monthlyPackage(offerings);
      final PurchaseResult result;
      if (package != null) {
        result = await Purchases.purchase(PurchaseParams.package(package));
      } else {
        final products = await Purchases.getProducts([
          kPremiumMonthlyProductId,
        ]);
        final product = _monthlyProduct(products);
        if (product == null) {
          lastError = 'not_found';
          debugPrint(
            'Missing monthly package for $kPremiumMonthlyProductId. '
            'current=${offerings.current?.identifier} '
            'offerings=${offerings.all.keys.toList()}',
          );
          return lastError;
        }
        final option = product.defaultOption;
        result = await Purchases.purchase(
          option == null
              ? PurchaseParams.storeProduct(product)
              : PurchaseParams.subscriptionOption(option),
        );
      }
      _apply(result.customerInfo);
      if (!membershipController.isPremium) {
        lastError = 'failed';
        return lastError;
      }
      return null;
    } on PlatformException catch (error) {
      final code = _purchaseErrorCode(error);
      if (code == 'canceled' || code == 'pending') return null;
      if (code == 'already') {
        membershipController.setPremium(true);
        return null;
      }
      lastError = code;
      debugPrint('buyMonthly: ${error.code} ${error.message}');
      return lastError;
    } catch (error) {
      lastError = 'failed';
      debugPrint('buyMonthly: $error');
      return lastError;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  final Map<String, String> _packPrices = {};

  /// Store price for [pack] (e.g. "₩900"), or null until it has loaded.
  String? packPrice(CharacterPack pack) => _packPrices[pack.productId];

  /// Loads pack prices from the store so the special tab can show them.
  Future<void> loadPackPrices() async {
    if (await _ensureConfigured() != null) return;
    try {
      final products = await Purchases.getProducts(
        [for (final pack in CharacterPack.all) pack.productId],
        productCategory: ProductCategory.nonSubscription,
      );
      for (final product in products) {
        _packPrices[product.identifier] = product.priceString;
      }
      notifyListeners();
    } catch (error) {
      debugPrint('loadPackPrices: $error');
    }
  }

  /// One-time purchase of a character pack (non-consumable). Returns an error
  /// code, or null when it was bought, already owned, or the user cancelled.
  Future<String?> buyPack(CharacterPack pack) async {
    if (_busy) return null;
    _busy = true;
    lastError = null;
    notifyListeners();
    try {
      final setup = await _ensureConfigured();
      if (setup != null) {
        lastError = setup;
        return lastError;
      }
      final products = await Purchases.getProducts(
        [pack.productId],
        productCategory: ProductCategory.nonSubscription,
      );
      StoreProduct? product;
      for (final p in products) {
        if (p.identifier == pack.productId) product = p;
      }
      if (product == null) {
        lastError = 'not_found';
        debugPrint('buyPack: missing product ${pack.productId}');
        return lastError;
      }
      final result =
          await Purchases.purchase(PurchaseParams.storeProduct(product));
      _apply(result.customerInfo);
      if (!characterController.ownsPack(pack)) {
        // Store confirmed the purchase but the info lagged; trust the result.
        await characterController.addOwnedPacks([pack.id]);
      }
      return null;
    } on PlatformException catch (error) {
      final code = _purchaseErrorCode(error);
      if (code == 'canceled' || code == 'pending') return null;
      if (code == 'already') {
        await characterController.addOwnedPacks([pack.id]);
        return null;
      }
      lastError = code;
      debugPrint('buyPack: ${error.code} ${error.message}');
      return lastError;
    } catch (error) {
      lastError = 'failed';
      debugPrint('buyPack: $error');
      return lastError;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Restores a plan bought on this store account (App Review requires this).
  /// Returns an error code, `not_found` when nothing is active, or null.
  Future<String?> restorePurchases() async {
    if (_busy) return null;
    _busy = true;
    lastError = null;
    notifyListeners();
    try {
      final setup = await _ensureConfigured();
      if (setup != null) {
        lastError = setup;
        return lastError;
      }
      _apply(await Purchases.restorePurchases());
      final anyPack = CharacterPack.all.any(characterController.ownsPack);
      if (!membershipController.isPremium && !anyPack) {
        lastError = 'restore_none';
        return lastError;
      }
      return null;
    } on PlatformException catch (error) {
      lastError = _purchaseErrorCode(error);
      debugPrint('restorePurchases: ${error.code} ${error.message}');
      return lastError;
    } catch (error) {
      lastError = 'failed';
      debugPrint('restorePurchases: $error');
      return lastError;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> _ensureConfigured() {
    if (!RevenueCatConfig.isSupportedPlatform) return Future.value('unavailable');
    if (!RevenueCatConfig.isConfigured) return Future.value('missing_key');
    if (_configured) return Future.value(null);
    return _configuring ??= _configure();
  }

  Future<String?> _configure() async {
    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      await Purchases.configure(
        PurchasesConfiguration(RevenueCatConfig.apiKey),
      );
      Purchases.addCustomerInfoUpdateListener(_apply);
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user == null) return;
        unawaited(_logIn(user.uid));
      });
      _configured = true;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _logIn(uid);
      } else {
        _apply(await Purchases.getCustomerInfo());
      }
      return null;
    } catch (error) {
      _configuring = null;
      debugPrint('Purchases.configure: $error');
      return 'unavailable';
    }
  }

  Future<void> _logIn(String uid) async {
    if (!_configured || _loggedInUid == uid) return;
    _loggedInUid = uid;
    try {
      final result = await Purchases.logIn(uid);
      _apply(result.customerInfo);
    } catch (error) {
      _loggedInUid = null;
      debugPrint('Purchases.logIn: $error');
    }
  }

  Package? _monthlyPackage(Offerings offerings) {
    final ordered = <Offering>[
      if (offerings.current != null) offerings.current!,
      for (final offering in offerings.all.values)
        if (offering.identifier != offerings.current?.identifier) offering,
    ];
    for (final offering in ordered) {
      final monthly = offering.monthly;
      if (monthly != null) return monthly;
      for (final package in offering.availablePackages) {
        final productId = package.storeProduct.identifier;
        final packageId = package.identifier;
        if (_isMonthlyProduct(productId) ||
            packageId == r'$rc_monthly' ||
            packageId == 'monthly') {
          return package;
        }
      }
    }
    return null;
  }

  StoreProduct? _monthlyProduct(List<StoreProduct> products) {
    for (final product in products) {
      if (_isMonthlyProduct(product.identifier)) return product;
    }
    return products.isEmpty ? null : products.first;
  }

  bool _isMonthlyProduct(String id) {
    return id == kPremiumMonthlyProductId ||
        id.startsWith('$kPremiumMonthlyProductId:');
  }

  void _apply(CustomerInfo info) {
    final entitled =
        info.entitlements.active.containsKey(kPremiumEntitlementId);
    final subscribed =
        info.activeSubscriptions.contains(kPremiumMonthlyProductId);
    var productMatch = false;
    for (final entitlement in info.entitlements.active.values) {
      if (entitlement.productIdentifier == kPremiumMonthlyProductId) {
        productMatch = true;
        break;
      }
    }
    membershipController.setPremium(entitled || subscribed || productMatch);
    // Bought packs (non-consumables) stay in the purchase history forever.
    final bought = {
      ...info.allPurchasedProductIdentifiers,
      for (final tx in info.nonSubscriptionTransactions) tx.productIdentifier,
    };
    unawaited(characterController.addOwnedPacks([
      for (final pack in CharacterPack.all)
        if (bought.contains(pack.productId) ||
            info.entitlements.active.containsKey('pack_${pack.id}'))
          pack.id,
    ]));
  }

  String _purchaseErrorCode(PlatformException error) {
    try {
      switch (PurchasesErrorHelper.getErrorCode(error)) {
        case PurchasesErrorCode.purchaseCancelledError:
          return 'canceled';
        case PurchasesErrorCode.paymentPendingError:
          return 'pending';
        case PurchasesErrorCode.productAlreadyPurchasedError:
          return 'already';
        case PurchasesErrorCode.storeProblemError:
        case PurchasesErrorCode.purchaseNotAllowedError:
        case PurchasesErrorCode.offlineConnectionError:
          return 'unavailable';
        case PurchasesErrorCode.productNotAvailableForPurchaseError:
        case PurchasesErrorCode.configurationError:
          return 'not_found';
        default:
          return 'failed';
      }
    } catch (_) {
      return 'failed';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    if (_configured) {
      Purchases.removeCustomerInfoUpdateListener(_apply);
    }
    super.dispose();
  }
}

final billingController = BillingController();
