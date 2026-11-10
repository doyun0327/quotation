// GENERATED from assets/images/character/{woman,man} alpha bounds — rerun the
// measurement script if character art changes.
//
// Transparent margin of each image as a fraction of its width/height.

import 'dart:math' as math;

/// Opaque-art bounds of a character image, so editing bounds and the
/// selection outline follow the drawn character instead of the image box.
class CharacterArtInsets {
  const CharacterArtInsets(this.aspect, this.left, this.right, this.top, this.bottom);

  /// Image width / height.
  final double aspect;
  final double left;
  final double right;
  final double top;
  final double bottom;

  static const none = CharacterArtInsets(1, 0, 0, 0, 0);

  static CharacterArtInsets forAsset(String assetPath) {
    final parts = assetPath.split('/');
    final file = parts.last;
    final folder = parts.length > 1 ? parts[parts.length - 2] : '';
    // Only woman/ files are keyed by bare name; other folders reuse names
    // (man/, christmas/01.png, shareEvent/01.png), so they carry the folder.
    if (folder != 'woman') return _byFile['$folder/$file'] ?? none;
    return _byFile[file] ?? none;
  }

  /// Transparent gaps (dp) between a [boxW]×[boxH] sprite box and the drawn
  /// art, with the image contained and centered in the box (BoxFit.contain).
  ({double left, double right, double top, double bottom}) gaps(
    double boxW,
    double boxH,
  ) {
    final dw = math.min(boxW, boxH * aspect);
    final dh = dw / aspect;
    final ox = (boxW - dw) / 2;
    final oy = (boxH - dh) / 2;
    return (
      left: ox + dw * left,
      right: ox + dw * right,
      top: oy + dh * top,
      bottom: oy + dh * bottom,
    );
  }

  static const Map<String, CharacterArtInsets> _byFile = {
    // woman/ (looked up by file name)
    'character (1).png': CharacterArtInsets(1.0210, 0.233, 0.252, 0.160, 0.072),
    'character (10).png': CharacterArtInsets(1.0218, 0.024, 0.017, 0.006, 0.024),
    'character (11).png': CharacterArtInsets(1.0218, 0.086, 0.039, 0.082, 0.027),
    'character (12).png': CharacterArtInsets(1.0218, 0.148, 0.147, 0.081, 0.017),
    'character (13).png': CharacterArtInsets(1.0218, 0.229, 0.132, 0.081, 0.028),
    'character (14).png': CharacterArtInsets(1.0218, 0.223, 0.230, 0.065, 0.029),
    'character (15).png': CharacterArtInsets(1.0218, 0.214, 0.145, 0.000, 0.011),
    'character (16).png': CharacterArtInsets(1.0210, 0.268, 0.268, 0.039, 0.040),
    'character (17).png': CharacterArtInsets(1.0210, 0.254, 0.256, 0.121, 0.052),
    'character (18).png': CharacterArtInsets(1.0218, 0.285, 0.288, 0.143, 0.032),
    'character (19).png': CharacterArtInsets(1.0210, 0.245, 0.251, 0.121, 0.046),
    'character (2).png': CharacterArtInsets(1.0000, 0.218, 0.222, 0.128, 0.067),
    'character (20).png': CharacterArtInsets(1.0234, 0.143, 0.143, 0.081, 0.027),
    'character (21).png': CharacterArtInsets(1.0210, 0.278, 0.264, 0.051, 0.042),
    'character (22).png': CharacterArtInsets(1.0210, 0.251, 0.254, 0.110, 0.046),
    'character (23).png': CharacterArtInsets(1.0210, 0.195, 0.195, 0.050, 0.023),
    'character (24).png': CharacterArtInsets(1.0218, 0.185, 0.182, 0.052, 0.033),
    'character (25).png': CharacterArtInsets(1.0210, 0.178, 0.178, 0.093, 0.028),
    'character (26).png': CharacterArtInsets(1.0218, 0.195, 0.203, 0.081, 0.040),
    'character (27).png': CharacterArtInsets(1.0210, 0.240, 0.240, 0.085, 0.027),
    'character (28).png': CharacterArtInsets(1.0210, 0.134, 0.133, 0.106, 0.032),
    'character (29).png': CharacterArtInsets(1.0210, 0.236, 0.236, 0.079, 0.037),
    'character (3).png': CharacterArtInsets(1.0000, 0.253, 0.250, 0.104, 0.046),
    'character (30).png': CharacterArtInsets(1.0210, 0.245, 0.245, 0.101, 0.035),
    'character (31).png': CharacterArtInsets(1.0250, 0.238, 0.247, 0.118, 0.027),
    'character (32).png': CharacterArtInsets(1.0210, 0.264, 0.260, 0.055, 0.027),
    'character (33).png': CharacterArtInsets(1.0242, 0.243, 0.202, 0.040, 0.032),
    'character (34).png': CharacterArtInsets(1.0210, 0.232, 0.270, 0.076, 0.022),
    'character (35).png': CharacterArtInsets(1.0210, 0.255, 0.190, 0.044, 0.022),
    'character (36).png': CharacterArtInsets(1.0210, 0.249, 0.220, 0.067, 0.013),
    'character (37).png': CharacterArtInsets(1.0193, 0.246, 0.263, 0.076, 0.024),
    'character (38).png': CharacterArtInsets(1.0210, 0.249, 0.247, 0.083, 0.029),
    'character (39).png': CharacterArtInsets(1.0210, 0.259, 0.218, 0.072, 0.024),
    'character (4).png': CharacterArtInsets(1.0218, 0.230, 0.173, 0.061, 0.024),
    'character (40).png': CharacterArtInsets(1.0210, 0.254, 0.176, 0.066, 0.018),
    'character (41).png': CharacterArtInsets(1.0210, 0.255, 0.231, 0.079, 0.019),
    'character (42).png': CharacterArtInsets(1.0210, 0.264, 0.264, 0.037, 0.026),
    'character (43).png': CharacterArtInsets(1.0210, 0.260, 0.249, 0.098, 0.024),
    'character (44).png': CharacterArtInsets(1.0210, 0.258, 0.263, 0.073, 0.019),
    'character (45).png': CharacterArtInsets(1.0210, 0.277, 0.268, 0.051, 0.013),
    'character (46).png': CharacterArtInsets(1.0210, 0.267, 0.265, 0.034, 0.020),
    'character (47).png': CharacterArtInsets(1.0210, 0.264, 0.236, 0.085, 0.015),
    'character (48).png': CharacterArtInsets(1.0210, 0.270, 0.241, 0.056, 0.019),
    'character (49).png': CharacterArtInsets(1.0210, 0.292, 0.233, 0.080, 0.022),
    'character (5).png': CharacterArtInsets(1.0210, 0.239, 0.244, 0.156, 0.040),
    'character (50).png': CharacterArtInsets(1.0218, 0.278, 0.271, 0.074, 0.014),
    'character (51).png': CharacterArtInsets(1.0218, 0.300, 0.274, 0.055, 0.007),
    'character (52).png': CharacterArtInsets(1.0218, 0.259, 0.253, 0.079, 0.019),
    'character (53).png': CharacterArtInsets(1.0218, 0.291, 0.276, 0.088, 0.023),
    'character (54).png': CharacterArtInsets(1.0218, 0.289, 0.261, 0.073, 0.023),
    'character (55).png': CharacterArtInsets(1.0218, 0.276, 0.250, 0.108, 0.009),
    'character (56).png': CharacterArtInsets(1.0218, 0.271, 0.186, 0.063, 0.028),
    'character (57).png': CharacterArtInsets(1.0218, 0.278, 0.187, 0.072, 0.030),
    'character (58).png': CharacterArtInsets(1.0218, 0.258, 0.278, 0.078, 0.015),
    'character (59).png': CharacterArtInsets(1.0218, 0.265, 0.240, 0.090, 0.023),
    'character (6).png': CharacterArtInsets(1.0210, 0.252, 0.264, 0.080, 0.056),
    'character (60).png': CharacterArtInsets(1.0218, 0.293, 0.295, 0.070, 0.017),
    'character (61).png': CharacterArtInsets(1.0218, 0.285, 0.262, 0.059, 0.019),
    'character (62).png': CharacterArtInsets(1.0218, 0.276, 0.221, 0.047, 0.021),
    'character (63).png': CharacterArtInsets(1.0218, 0.289, 0.273, 0.075, 0.021),
    'character (64).png': CharacterArtInsets(0.9795, 0.258, 0.262, 0.109, 0.047),
    'character (7).png': CharacterArtInsets(1.0210, 0.232, 0.229, 0.106, 0.038),
    'character (8).png': CharacterArtInsets(1.0210, 0.251, 0.255, 0.129, 0.030),
    'character (9).png': CharacterArtInsets(1.0218, 0.224, 0.224, 0.082, 0.035),
    'character(65).png': CharacterArtInsets(1.0000, 0.245, 0.255, 0.208, 0.132),
    'character(66).png': CharacterArtInsets(1.0000, 0.213, 0.215, 0.054, 0.057),
    'character(67).png': CharacterArtInsets(1.0000, 0.197, 0.206, 0.153, 0.059),
    'character(68).png': CharacterArtInsets(1.0000, 0.273, 0.271, 0.073, 0.051),
    'character(69).png': CharacterArtInsets(1.0000, 0.274, 0.274, 0.072, 0.053),
    'character(70).png': CharacterArtInsets(1.0000, 0.253, 0.219, 0.054, 0.032),
    'character.png': CharacterArtInsets(1.0000, 0.242, 0.255, 0.203, 0.125),
    // man/ (looked up as 'man/<file>'; some names repeat woman files)
    'man/character (1).png': CharacterArtInsets(1.0218, 0.263, 0.256, 0.089, 0.037),
    'man/character (10).png': CharacterArtInsets(1.0185, 0.261, 0.263, 0.130, 0.043),
    'man/character (11).png': CharacterArtInsets(1.0242, 0.258, 0.268, 0.130, 0.046),
    'man/character (12).png': CharacterArtInsets(1.0218, 0.271, 0.260, 0.116, 0.036),
    'man/character (13).png': CharacterArtInsets(1.0185, 0.264, 0.278, 0.125, 0.029),
    'man/character (14).png': CharacterArtInsets(1.0185, 0.263, 0.267, 0.125, 0.026),
    'man/character (15).png': CharacterArtInsets(1.0218, 0.263, 0.259, 0.073, 0.046),
    'man/character (2).png': CharacterArtInsets(1.0185, 0.258, 0.265, 0.128, 0.048),
    'man/character (3).png': CharacterArtInsets(1.0210, 0.233, 0.238, 0.098, 0.049),
    'man/character (4).png': CharacterArtInsets(1.0218, 0.231, 0.239, 0.124, 0.045),
    'man/character (5).png': CharacterArtInsets(1.0185, 0.262, 0.269, 0.126, 0.033),
    'man/character (6).png': CharacterArtInsets(1.0185, 0.258, 0.265, 0.118, 0.029),
    'man/character (7).png': CharacterArtInsets(1.0185, 0.262, 0.271, 0.129, 0.031),
    'man/character (8).png': CharacterArtInsets(1.0234, 0.259, 0.268, 0.118, 0.031),
    'man/character (9).png': CharacterArtInsets(1.0185, 0.246, 0.280, 0.115, 0.053),
    'man/character(16).png': CharacterArtInsets(1.0000, 0.264, 0.269, 0.108, 0.060),
    'man/character(17).png': CharacterArtInsets(1.0000, 0.265, 0.264, 0.111, 0.057),
    'man/character(18).png': CharacterArtInsets(1.0000, 0.266, 0.262, 0.112, 0.049),
    'man/character(19).png': CharacterArtInsets(1.0218, 0.267, 0.260, 0.114, 0.035),
    'man/character(2).png': CharacterArtInsets(1.0218, 0.263, 0.256, 0.089, 0.037),
    'man/character(20).png': CharacterArtInsets(1.0000, 0.268, 0.263, 0.112, 0.054),
    'man/character(21).png': CharacterArtInsets(1.0218, 0.269, 0.261, 0.114, 0.035),
    'man/character(22).png': CharacterArtInsets(1.0000, 0.269, 0.264, 0.112, 0.061),
    'man/character(23).png': CharacterArtInsets(1.0000, 0.269, 0.265, 0.110, 0.061),
    'man/character(24).png': CharacterArtInsets(1.0000, 0.268, 0.265, 0.111, 0.054),
    'man/character(25).png': CharacterArtInsets(1.0000, 0.268, 0.265, 0.112, 0.061),
    'man/character(27).png': CharacterArtInsets(1.0000, 0.222, 0.231, 0.135, 0.060),
    'man/character(28).png': CharacterArtInsets(1.0000, 0.274, 0.279, 0.128, 0.053),
    'man/character(29).png': CharacterArtInsets(1.0000, 0.274, 0.278, 0.128, 0.048),
    'man/character(30).png': CharacterArtInsets(1.0000, 0.245, 0.268, 0.064, 0.034),
    'man/charcter(1).png': CharacterArtInsets(1.0185, 0.264, 0.278, 0.125, 0.029),
    // christmas/ pack (looked up as 'christmas/<file>')
    'christmas/01.png': CharacterArtInsets(0.8248, 0.246, 0.246, 0.125, 0.085),
    'christmas/02.png': CharacterArtInsets(0.8248, 0.246, 0.246, 0.122, 0.085),
    'christmas/03.png': CharacterArtInsets(0.8248, 0.241, 0.241, 0.164, 0.079),
    'christmas/04.png': CharacterArtInsets(0.9873, 0.206, 0.205, 0.028, 0.045),
    'christmas/05.png': CharacterArtInsets(0.9787, 0.230, 0.185, 0.035, 0.027),
    'christmas/06.png': CharacterArtInsets(1.0000, 0.273, 0.272, 0.073, 0.051),
    'christmas/07.png': CharacterArtInsets(1.0000, 0.274, 0.278, 0.132, 0.058),
    'christmas/08.png': CharacterArtInsets(1.0000, 0.268, 0.242, 0.108, 0.061),
    // shareEvent/ reward (looked up as 'shareEvent/<file>')
    'shareEvent/01.png': CharacterArtInsets(1.0000, 0.300, 0.303, 0.122, 0.054),
  };
}
