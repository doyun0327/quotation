import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quotation/ads/interstitial_ads.dart';
import 'package:quotation/data/billing_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/user_profile_sync.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:quotation/widgets/app_pixel_icon.dart';
import 'package:quotation/widgets/hamfoot_icon.dart';
import 'package:quotation/widgets/sign_in_flow.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    this.asSettings = false,
    this.pickForRoomSelectedId,
  });

  /// Opened from the home character. The title reads as character settings.
  final bool asSettings;

  /// Opened from the widget decorator: picking returns the character via
  /// Navigator.pop instead of changing the main-screen character. The value
  /// is the room's current character, shown as selected.
  final String? pickForRoomSelectedId;

  bool get _pickForRoom => pickForRoomSelectedId != null;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _busy = false;
  CharacterGroup _group = CharacterGroup.female;

  @override
  void initState() {
    super.initState();
    InterstitialAds.preload();
    unawaited(billingController.loadPackPrices());
  }

  String _packPrice(CharacterPack pack) =>
      billingController.packPrice(pack) ?? '₩900';

  /// Confirms and buys [pack] once (owned forever, separate from premium).
  Future<void> _buyPack(CharacterPack pack) async {
    final t = AppStrings.current;
    final name = t.characterPackName(pack.id);
    final price = _packPrice(pack);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.shopPackBuyTitle(name), style: AppTheme.body),
        content: Text(
          t.shopPackBuyBody(pack.characterIds.length, price),
          style: AppTheme.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.togetherCheerCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.shopPackBuy(price)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (!await suggestSignInBeforePurchase(context) || !mounted) return;
    final code = await billingController.buyPack(pack);
    if (!mounted) return;
    if (code != null) {
      _toast(t.billingError(code));
      return;
    }
    if (characterController.ownsPack(pack)) _toast(t.shopPackBought(name));
  }

  Future<void> _select(AppCharacter character) async {
    if (widget._pickForRoom) {
      if (characterController.isUsable(character) && mounted) {
        Navigator.of(context).pop(character);
      }
      return;
    }
    final ok = await characterController.select(character);
    if (!ok || !mounted) return;
    await HomeWidgetSync.syncCharacter();
    await UserProfileSync.syncCharacter();
  }

  Future<void> _onTile(AppCharacter character) async {
    if (characterController.isUsable(character)) {
      await _select(character);
      return;
    }
    final pack = character.pack;
    if (pack != null) {
      await _buyPack(pack);
      if (mounted && characterController.isUsable(character)) {
        await _select(character);
      }
      return;
    }
    final t = AppStrings.current;
    if (characterController.canUnlockWithAd(character)) {
      final watch = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.shopAdUnlock, style: AppTheme.body),
          content: Text(t.shopAdUnlockBody, style: AppTheme.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.togetherCheerCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.shopAdConfirm),
            ),
          ],
        ),
      );
      if (watch != true || !mounted || _busy) return;
      setState(() => _busy = true);
      final watched = await InterstitialAds.show();
      if (!mounted) return;
      setState(() => _busy = false);
      if (!watched) {
        _toast(t.shopAdFailed);
        return;
      }
      final unlocked = await characterController.unlockWithAd(character);
      if (!mounted) return;
      if (!unlocked) {
        _toast(t.shopNeedPremium);
        return;
      }
      await _select(character);
      if (mounted) _toast(t.shopUnlocked);
      return;
    }

    final subscribe = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.premiumTitle, style: AppTheme.body),
        content: Text(t.shopNeedPremium, style: AppTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.premiumLockedDismiss),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.shopSubscribe),
          ),
        ],
      ),
    );
    if (subscribe != true || !mounted) return;
    if (!await suggestSignInBeforePurchase(context) || !mounted) return;
    final code = await billingController.buyMonthly();
    if (!mounted) return;
    if (code != null) {
      _toast(t.billingError(code));
      return;
    }
    if (characterController.isUsable(character)) {
      await _select(character);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Paw on a character tile: toggle favorite, confirm when it was added.
  void _toggleFavorite(AppCharacter character) {
    final adding = !characterController.isFavorite(character);
    unawaited(characterController.toggleFavorite(character));
    if (!adding) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _toast(AppStrings.current.characterFavoriteAdded);
  }

  Widget _tile(AppCharacter character, String selected, Color accent) {
    final usable = characterController.isUsable(character);
    return _ShopTile(
      character: character,
      selected: selected == character.id,
      locked: !usable,
      ad: characterController.canUnlockWithAd(character),
      favorite: characterController.isFavorite(character),
      accent: accent,
      onTap: _busy ? null : () => _onTile(character),
      onFavorite: _busy ? null : () => _toggleFavorite(character),
    );
  }

  /// Special tab: one section per pack, newest first.
  Widget _buildPacks(BuildContext context, String selected) {
    final t = AppStrings.current;
    final accent = context.palette.accent;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final (index, pack) in CharacterPack.all.indexed) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 0, 10),
            child: Row(
              children: [
                Text(
                  t.characterPackName(pack.id),
                  style: AppTheme.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                if (index == 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5A7A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.shopPackNew,
                      style: AppTheme.body.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (characterController.ownsPack(pack))
                  Text(
                    t.shopPackOwned,
                    style: AppTheme.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  )
                else
                  FilledButton(
                    onPressed: _busy || billingController.isBusy
                        ? null
                        : () => _buyPack(pack),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      t.shopPackBuy(_packPrice(pack)),
                      style: AppTheme.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final character in pack.characters)
                _tile(character, selected, accent),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: Listenable.merge([
        localeController,
        characterController,
        membershipController,
        visualStyleController,
        billingController,
      ]),
      builder: (context, _) {
        final t = AppStrings.current;
        final selected =
            widget.pickForRoomSelectedId ?? characterController.character.id;
        final pool = AppCharacter.inGroup(_group);
        final characters = [...pool]..sort((a, b) {
            int rank(AppCharacter character) {
              if (!characterController.isUsable(character)) return 2;
              return characterController.isFavorite(character) ? 0 : 1;
            }

            final byRank = rank(a).compareTo(rank(b));
            if (byRank != 0) return byRank;
            return pool.indexOf(a).compareTo(pool.indexOf(b));
          });
        return Scaffold(
          backgroundColor: const Color(0xFFF3F7FD),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F7FD),
            elevation: 0,
            title: Text(
              widget.asSettings ? t.characterSettingsTitle : t.shopTitle,
              style: AppTheme.body.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: palette.accent,
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    _GroupChip(
                      label: t.shopGroupFemale,
                      selected: _group == CharacterGroup.female,
                      accent: palette.accent,
                      onTap: () =>
                          setState(() => _group = CharacterGroup.female),
                    ),
                    const SizedBox(width: 8),
                    _GroupChip(
                      label: t.shopGroupMale,
                      selected: _group == CharacterGroup.male,
                      accent: palette.accent,
                      onTap: () => setState(() => _group = CharacterGroup.male),
                    ),
                    const SizedBox(width: 8),
                    _GroupChip(
                      label: t.shopGroupSpecial,
                      selected: _group == CharacterGroup.special,
                      accent: palette.accent,
                      dot: characterController.hasUnseenPack,
                      onTap: () {
                        setState(() => _group = CharacterGroup.special);
                        unawaited(characterController.markPacksSeen());
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _group == CharacterGroup.special
                    ? _buildPacks(context, selected)
                    : characters.isEmpty
                    ? Center(
                        child: Text(
                          t.shopMaleEmpty,
                          style: AppTheme.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: characters.length,
                  itemBuilder: (context, index) =>
                      _tile(characters[index], selected, palette.accent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.dot = false,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  /// New season not opened yet.
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : Colors.white,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.body.copyWith(
                  color: selected ? Colors.white : accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (dot) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5A7A),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.character,
    required this.selected,
    required this.locked,
    required this.ad,
    required this.favorite,
    required this.accent,
    required this.onTap,
    required this.onFavorite,
  });

  final AppCharacter character;
  final bool selected;
  final bool locked;
  final bool ad;
  final bool favorite;
  final Color accent;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : const Color(0xFFE4ECF7),
              width: selected ? 2.2 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = constraints.biggest.shortestSide;
                    final px = (side *
                            MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(1, 720);
                    return Image.asset(
                      character.assetPath,
                      fit: BoxFit.contain,
                      cacheWidth: px,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.none,
                      isAntiAlias: false,
                    );
                  },
                ),
              ),
              if (locked)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: AppPixelIcon(
                      AppGlyph.lock,
                      color: accent,
                      size: 18,
                    ),
                  ),
                ),
              if (onFavorite != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    onPressed: onFavorite,
                    icon: HamfootIcon(
                      size: 22,
                      active: favorite,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
