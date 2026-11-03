enum AmbientSound {
  rain(label: 'Rain', assetPath: 'assets/sounds/rain.mp3', requiresPro: false),
  whiteNoise(
    label: 'White Noise',
    assetPath: 'assets/sounds/white_noise.mp3',
    requiresPro: true,
  ),
  coffeeShop(
    label: 'Coffee Shop',
    assetPath: 'assets/sounds/coffee_shop.mp3',
    requiresPro: true,
  ),
  ocean(
    label: 'Ocean Waves',
    assetPath: 'assets/sounds/ocean.mp3',
    requiresPro: true,
  ),
  fireplace(
    label: 'Fireplace',
    assetPath: 'assets/sounds/fireplace.mp3',
    requiresPro: true,
  ),
  forest(
    label: 'Forest',
    assetPath: 'assets/sounds/forest.mp3',
    requiresPro: true,
  ),
  brownNoise(
    label: 'Brown Noise',
    assetPath: 'assets/sounds/brown_noise.mp3',
    requiresPro: true,
  ),
  library(
    label: 'Library',
    assetPath: 'assets/sounds/library.mp3',
    requiresPro: true,
  );

  const AmbientSound({
    required this.label,
    required this.assetPath,
    required this.requiresPro,
  });

  final String label;
  final String assetPath;
  final bool requiresPro;

  static AmbientSound fromName(String? value) {
    for (final sound in AmbientSound.values) {
      if (sound.name == value) return sound;
    }
    return AmbientSound.rain;
  }
}
