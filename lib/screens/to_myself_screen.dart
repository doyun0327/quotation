import 'package:flutter/material.dart';
import 'package:quotation/data/quote_models.dart';
import 'package:quotation/data/quote_repository.dart';
import 'package:quotation/data/selection_controller.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/screens/quote_list_screen.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/widgets/category_browse_section.dart';

/// "나에게 건네는 말": the feeling categories (감사와 기쁨 … 꿈과 동기부여)
/// gathered behind one home row. Each opens with two-line quotes only.
class ToMyselfScreen extends StatelessWidget {
  const ToMyselfScreen({super.key});

  void _open(BuildContext context, MainCategory category, SubCategory sub) {
    selectionController.selectSubCategory(category.id, sub.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteListScreen(
          mainCategory: category,
          subCategory: sub,
          multiLineOnly: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final t = AppStrings.current;
        final palette = context.palette;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                  child: SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 28,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          t.toMyselfTitle,
                          style: AppTheme.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: CategoryBrowseSection(
                      onlyCategoryIds: QuoteRepository.toMyselfCategoryIds,
                      onSubcategoryTap: (category, sub) =>
                          _open(context, category, sub),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
