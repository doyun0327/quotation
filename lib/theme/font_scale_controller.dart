import 'package:flutter/foundation.dart';

enum FontScaleOption {
  small(id: 'small', name: '작게', scale: 0.9, sampleSize: 12),
  medium(id: 'medium', name: '보통', scale: 1.0, sampleSize: 14),
  large(id: 'large', name: '크게', scale: 1.15, sampleSize: 16),
  xLarge(id: 'xlarge', name: '더 크게', scale: 1.3, sampleSize: 18);

  const FontScaleOption({
    required this.id,
    required this.name,
    required this.scale,
    required this.sampleSize,
  });

  final String id;
  final String name;
  final double scale;
  final double sampleSize;

  static FontScaleOption byId(String id) {
    return FontScaleOption.values.firstWhere(
      (option) => option.id == id,
      orElse: () => FontScaleOption.medium,
    );
  }
}

class FontScaleController extends ChangeNotifier {
  FontScaleController({FontScaleOption? initial})
      : _option = initial ?? FontScaleOption.medium;

  FontScaleOption _option;

  FontScaleOption get option => _option;
  double get scale => _option.scale;

  void setOption(FontScaleOption option) {
    if (_option == option) return;
    _option = option;
    notifyListeners();
  }

  void setById(String id) => setOption(FontScaleOption.byId(id));
}

final fontScaleController = FontScaleController();
