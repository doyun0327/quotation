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

/// What a monthly purchase came to, for what the screen shows next.
enum SubscribeOutcome {
  /// Premium is on.
  done,

  /// Paid, but the store or RevenueCat has not confirmed it yet.
  verifying,

  /// The store is waiting for the payment (e.g. a slow card approval).
  pending,

  /// Closed without buying.
  canceled,

  /// Did not go through; see the code.
  failed,
}

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

  /// How long to wait after a purchase for the plan to show up as active.
  static const _verifyTimeout = Duration(seconds: 10);

  /// Monthly purchase with what happened, for the subscribe screens.
  /// A purchase that is paid but not active yet within [_verifyTimeout] is
  /// [SubscribeOutcome.verifying], never a failure: the customer-info
  /// listener turns premium on when RevenueCat confirms it.
  Future<({SubscribeOutcome outcome, String? code})> subscribeMonthly() async {
    _lastPurchaseState = null;
    final code = await buyMonthly();
    final state = _lastPurchaseState;
    if (state == 'canceled') return (outcome: SubscribeOutcome.canceled, code: null);
    if (state == 'pending') return (outcome: SubscribeOutcome.pending, code: null);
    if (code == 'verifying') {
      return (outcome: SubscribeOutcome.verifying, code: null);
    }
    if (code != null) return (outcome: SubscribeOutcome.failed, code: code);
    if (!membershipController.isPremium) {
      return (outcome: SubscribeOutcome.canceled, code: null);
    }
    return (outcome: SubscribeOutcome.done, code: null);
  }

  /// Set by [buyMonthly] for [subscribeMonthly]: 'canceled' or 'pending'.
  String? _lastPurchaseState;

  /// Waits up to [_verifyTimeout] for premium, checking RevenueCat again in
  /// case the update listener is slow.
  Future<bool> _waitForPremium() async {
    if (membershipController.isPremium) return true;
    final done = Completer<void>();
    void listener() {
      if (membershipController.isPremium && !done.isCompleted) done.complete();
    }

    membershipController.addListener(listener);
    try {
      final deadline = DateTime.now().add(_verifyTimeout);
      while (!done.isCompleted && DateTime.now().isBefore(deadline)) {
        await Future.any([
          done.future,
          Future<void>.delayed(const Duration(seconds: 2)),
        ]);
        if (done.isCompleted) break;
        try {
          _apply(await Purchases.getCustomerInfo());
        } catch (_) {}
      }
    } finally {
      membershipController.removeListener(listener);
    }
    return membershipController.isPremium;
  }

  /// Opens the monthly subscription sheet through RevenueCat.
  /// Returns an error code, `verifying` when it was paid but is not active
  /// yet, or null when it is active or the user cancelled.
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
      // The store took the payment; RevenueCat can need a few more seconds.
      if (!await _waitForPremium()) return 'verifying';
      return null;
    } on PlatformException catch (error) {
      final code = _purchaseErrorCode(error);
      if (code == 'canceled' || code == 'pending') {
        _lastPurchaseState = code;
        return null;
      }
      if (code == 'already') {
        // The store account owns it: attach it to this user so it stays on
        // after the next launch, instead of only flipping premium here.
        try {
          await Purchases.syncPurchasesForResult();
          _apply(await Purchases.getCustomerInfo());
        } catch (e) {
          debugPrint('buyMonthly already: $e');
        }
        if (!membershipController.isPremium) {
          membershipController.setPremium(true);
        }
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

  String? _monthlyPrice;
  Future<void>? _loadingMonthlyPrice;

  /// Store price of the monthly plan (e.g. "₩2,900"), or null until loaded.
  /// Shown before the purchase sheet, as store policy asks.
  String? get monthlyPrice => _monthlyPrice;

  Future<void> loadMonthlyPrice() {
    if (_monthlyPrice != null) return Future.value();
    return _loadingMonthlyPrice ??= _fetchMonthlyPrice().whenComplete(
      () => _loadingMonthlyPrice = null,
    );
  }

  Future<void> _fetchMonthlyPrice() async {
    if (await _ensureConfigured() != null) return;
    try {
      final package = _monthlyPackage(await Purchases.getOfferings());
      var price = package?.storeProduct.priceString;
      if (price == null) {
        final product = _monthlyProduct(
          await Purchases.getProducts([kPremiumMonthlyProductId]),
        );
        price = product?.priceString;
      }
      if (price == null || price.isEmpty) return;
      _monthlyPrice = price;
      notifyListeners();
    } catch (error) {
      debugPrint('loadMonthlyPrice: $error');
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
      final info = await Purchases.restorePurchases();
      // Restoring already read the store's purchases for this user, so the
      // result is final: apply it as is instead of starting another check.
      _syncedUsers.add(info.originalAppUserId);
      _apply(info);
      final premium = _hasPremium(info);
      final bought = {
        ...info.allPurchasedProductIdentifiers,
        for (final tx in info.nonSubscriptionTransactions) tx.productIdentifier,
      };
      final anyPack = CharacterPack.all.any(
        (pack) =>
            characterController.ownsPack(pack) ||
            bought.contains(pack.productId) ||
            info.entitlements.active.containsKey('pack_${pack.id}'),
      );
      if (!premium && !anyPack) {
        debugPrint(
          'restore_none: user=${info.originalAppUserId} '
          'subs=${info.activeSubscriptions} '
          'entitlements=${info.entitlements.active.keys.toList()} '
          'all=${info.allPurchasedProductIdentifiers}',
        );
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

  /// App user ids already checked against the store's own purchases.
  final Set<String> _syncedUsers = {};
  bool _syncing = false;

  bool _hasPremium(CustomerInfo info) {
    if (info.entitlements.active.containsKey(kPremiumEntitlementId)) {
      return true;
    }
    // Android reports subscriptions as "premium_monthly:<base plan>".
    if (info.activeSubscriptions.any(_isMonthlyProduct)) return true;
    return info.entitlements.active.values
        .any((e) => _isMonthlyProduct(e.productIdentifier));
  }

  /// The Play account can own the plan while RevenueCat looks at a user id
  /// it was not bought under (anonymous start, a new Firebase sign-in).
  /// Before locking premium, ask RevenueCat to read the store's purchases
  /// for this id once. Android only: on iPhone this may ask for a password.
  bool _needsStoreSync(CustomerInfo info) {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return !_syncedUsers.contains(info.originalAppUserId);
  }

  Future<void> _syncStorePurchases(String userId) async {
    _syncedUsers.add(userId);
    _syncing = true;
    CustomerInfo? info;
    try {
      await Purchases.syncPurchasesForResult();
      info = await Purchases.getCustomerInfo();
    } catch (error) {
      debugPrint('syncPurchases: $error');
    } finally {
      _syncing = false;
    }
    if (info != null) {
      _apply(info);
    } else {
      membershipController.setPremium(false);
    }
  }

  void _apply(CustomerInfo info) {
    final premium = _hasPremium(info);
    if (premium) {
      membershipController.setPremium(true);
    } else if (_syncing) {
      // Updates during the store check do not lock; its result decides.
    } else if (!_needsStoreSync(info)) {
      membershipController.setPremium(false);
    } else {
      // Keep the current state until the store has been checked, so a paid
      // plan does not flash locked.
      unawaited(_syncStorePurchases(info.originalAppUserId));
    }
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
