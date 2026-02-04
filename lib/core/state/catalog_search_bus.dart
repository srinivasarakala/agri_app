import 'package:flutter/foundation.dart';

class CatalogSearchBus extends ChangeNotifier {
  String _text = '';
  bool _goToCatalog = false;

  String get text => _text;
  bool get goToCatalog => _goToCatalog;

  void openCatalogWithSearch(String text) {
    _text = text;
    _goToCatalog = true;
    notifyListeners();
  }

  void consumeGoToCatalog() {
    _goToCatalog = false;
  }
}
