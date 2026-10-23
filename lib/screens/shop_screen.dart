import 'package:flutter/material.dart';
import 'package:quotation/ads/interstitial_ads.dart';
import 'package:quotation/data/billing_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/visual_style_controller.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.asSettings = false});

  /// Opened from the home character. The title reads as character settings.
  final bool asSettings;

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
  }

  Future<void> _select(AppCharacter character) async {
    final ok = await characterController.select(character);
    if (!ok || !mounted) return;
    await HomeWidgetSync.syncCharacter();
  }

  Future<void> _onTile(AppCharacter character) async {
    if (characterController.isUsable(character)) {
      await _select(character);
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: Listenable.merge([
        localeController,
        characterController,
        membershipController,
        visualStyleController,
      ]),
      builder: (context, _) {
        final t = AppStrings.current;
        final selected = characterController.character.id;
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
                  ],
                ),
              ),
              Expanded(
                child: characters.isEmpty
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
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final usable = characterController.isUsable(character);
                    final ad = characterController.canUnlockWithAd(character);
                    return _ShopTile(
                      character: character,
                      selected: selected == character.id,
                      locked: !usable,
                      ad: ad,
                      favorite: characterController.isFavorite(character),
                      accent: palette.accent,
                      onTap: _busy ? null : () => _onTile(character),
                      onFavorite: usable && !_busy
                          ? () => characterController.toggleFavorite(character)
                          : null,
                    );
                  },
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
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

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
          child: Text(
            label,
            style: AppTheme.body.copyWith(
              color: selected ? Colors.white : accent,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
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
                child: Image.asset(
                  character.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: visualStyleController.isClean
                      ? FilterQuality.medium
                      : FilterQuality.none,
                  isAntiAlias: visualStyleController.isClean,
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
                    child: Icon(
                      ad ? Icons.ondemand_video_rounded : Icons.lock_rounded,
                      color: accent,
                      size: 22,
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
                    icon: Icon(
                      favorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: favorite
                          ? const Color(0xFFFFB020)
                          : AppColors.muted,
                      size: 20,
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
