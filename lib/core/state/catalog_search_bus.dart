import 'package:flutter/foundation.dart';

class CatalogSearchBus extends ChangeNotifier {
  String _text = '';
  bool _goToCatalog = false;
  int? _categoryId;
  String? _tag;

  String get text => _text;
  bool get goToCatalog => _goToCatalog;
  int? get categoryId => _categoryId;
  String? get tag => _tag;

  void openCatalogWithSearch(String text) {
    _text = text;
    _goToCatalog = true;
    _categoryId = null;
    _tag = null;
    notifyListeners();
  }

  void openCatalogWithCategory({int? categoryId, String? tag}) {
    _text = '';
    _goToCatalog = true;
    _categoryId = categoryId;
    _tag = tag;
    notifyListeners();
  }

  void consumeGoToCatalog() {
    _goToCatalog = false;
  }
}
