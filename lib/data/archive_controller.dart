import 'package:flutter/foundation.dart';

class ArchiveItem {
  const ArchiveItem({
    required this.id,
    required this.text,
    required this.savedAt,
    required this.categoryId,
    required this.categoryTitle,
    this.subCategoryId,
    this.subCategoryTitle,
    this.author,
  });

  final String id;
  final String text;
  final DateTime savedAt;
  final String categoryId;
  final String categoryTitle;
  final String? subCategoryId;
  final String? subCategoryTitle;
  final String? author;
}

class ArchiveGroup {
  const ArchiveGroup({
    required this.categoryId,
    required this.categoryTitle,
    required this.items,
    this.subCategoryId,
  });

  final String categoryId;
  final String? subCategoryId;
  final String categoryTitle;
  final List<ArchiveItem> items;
}

class ArchiveController extends ChangeNotifier {
  final List<ArchiveItem> _items = [];

  List<ArchiveItem> get items => List.unmodifiable(_items);

  bool contains(String id) => _items.any((item) => item.id == id);

  List<ArchiveGroup> get groupedByCategory {
    final order = <String>[];
    final map = <String, List<ArchiveItem>>{};

    for (final item in _items) {
      final subId = item.subCategoryId;
      final key = (subId != null && subId.isNotEmpty)
          ? '${item.categoryId}:$subId'
          : item.categoryId;
      map.putIfAbsent(key, () {
        order.add(key);
        return <ArchiveItem>[];
      }).add(item);
    }

    return [
      for (final key in order)
        ArchiveGroup(
          categoryId: map[key]!.first.categoryId,
          subCategoryId: map[key]!.first.subCategoryId,
          categoryTitle: map[key]!.first.subCategoryTitle ??
              map[key]!.first.categoryTitle,
          items: List.unmodifiable(map[key]!),
        ),
    ];
  }

  bool toggle({
    required String id,
    required String text,
    required String categoryId,
    required String categoryTitle,
    String? subCategoryId,
    String? subCategoryTitle,
    String? author,
  }) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items.removeAt(index);
      notifyListeners();
      return false;
    }

    _items.insert(
      0,
      ArchiveItem(
        id: id,
        text: text,
        savedAt: DateTime.now(),
        categoryId: categoryId,
        categoryTitle: categoryTitle,
        subCategoryId: subCategoryId,
        subCategoryTitle: subCategoryTitle,
        author: author,
      ),
    );
    notifyListeners();
    return true;
  }

  void remove(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}

final archiveController = ArchiveController();
