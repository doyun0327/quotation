import 'package:flutter/material.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';

/// Settings › 위젯 설정 방법 (iPhone): how to add a widget to the Home
/// Screen and how to change the room on one, a screenshot per step
/// (assets/images/widget_guide, captured on iOS).
class WidgetHowToScreen extends StatelessWidget {
  const WidgetHowToScreen({super.key});

  static const _dir = 'assets/images/widget_guide';

  /// One list per add step; the 방 1~5 step swipes through its pictures.
  static const _addShots = [
    ['$_dir/add_1.jpg'],
    ['$_dir/add_2.jpg'],
    ['$_dir/add_3.jpg'],
    [
      '$_dir/add_room1.jpg',
      '$_dir/add_room2.jpg',
      '$_dir/add_room3.jpg',
      '$_dir/add_room4.jpg',
      '$_dir/add_room5.jpg',
    ],
    ['$_dir/add_5.jpg'],
    ['$_dir/add_6.jpg'],
  ];

  static const _changeShots = [
    '$_dir/change_1.jpg',
    '$_dir/change_2.jpg',
    '$_dir/change_3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final accent = context.palette.accent;
    final add = t.widgetAddSteps;
    final change = t.widgetChangeSteps;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7FD),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F7FD),
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
          ),
          title: Text(
            t.widgetHowToTitle,
            style: AppTheme.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: accent,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: accent,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: AppTheme.body.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
            unselectedLabelStyle: AppTheme.body.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              Tab(text: t.widgetAddSection),
              Tab(text: t.widgetChangeSection),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  for (var i = 0; i < _addShots.length; i++)
                    _Step(
                      number: i + 1,
                      text: i < add.length ? add[i] : '',
                      hint: _addShots[i].length > 1
                          ? t.widgetAddRoomsHint
                          : null,
                      images: _addShots[i],
                      accent: accent,
                    ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  for (var i = 0; i < _changeShots.length; i++)
                    _Step(
                      number: i + 1,
                      text: i < change.length ? change[i] : '',
                      images: [_changeShots[i]],
                      accent: accent,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.text,
    required this.images,
    required this.accent,
    this.hint,
  });

  final int number;
  final String text;
  final String? hint;
  final List<String> images;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: AppTheme.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: AppTheme.body.copyWith(
                        fontSize: 14.5,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint!,
                        style: AppTheme.body.copyWith(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (images.length == 1)
            Center(child: _Shot(images.first))
          else
            _ShotPager(images: images, accent: accent),
        ],
      ),
    );
  }
}

/// Phone-sized screenshot with a soft frame.
class _Shot extends StatelessWidget {
  const _Shot(this.asset);

  static const width = 240.0;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDCE5F2), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                .round(),
          ),
        ),
      ),
    );
  }
}

/// Swipe through several screenshots (the gallery's 방 1~5 pages).
class _ShotPager extends StatefulWidget {
  const _ShotPager({required this.images, required this.accent});

  final List<String> images;
  final Color accent;

  @override
  State<_ShotPager> createState() => _ShotPagerState();
}

class _ShotPagerState extends State<_ShotPager> {
  final _controller = PageController(viewportFraction: 0.72);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Screenshots are 1206×2622.
    const height = _Shot.width * 2622 / 1206 + 4;
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) =>
                Center(child: _Shot(widget.images[index])),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.images.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page
                      ? widget.accent
                      : widget.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
