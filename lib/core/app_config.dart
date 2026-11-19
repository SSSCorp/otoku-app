/// Build-time configuration, read from `--dart-define` values.
///
/// Nothing here needs a `.env` file: with no defines the app runs on
/// OpenStreetMap with no API key. To opt in to Google Maps, run:
///
/// ```sh
/// flutter run --print-dtd --dart-define=MAP_PROVIDER=google \
///   --dart-define=GOOGLE_MAPS_API_KEY=<key>
/// ```
///
/// (or `--dart-define-from-file=.env` with only those two entries; the Android
/// build also reads `GOOGLE_MAPS_API_KEY` from `.env` for the manifest).
enum MapProvider { osm, google }

class AppConfig {
  const AppConfig({
    this.requestedProvider = MapProvider.osm,
    this.googleMapsApiKey = '',
  });

  factory AppConfig.fromEnvironment() => AppConfig(
    requestedProvider: parseProvider(
      const String.fromEnvironment('MAP_PROVIDER'),
    ),
    googleMapsApiKey: const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
  );

  static MapProvider parseProvider(String? raw) =>
      (raw ?? '').trim().toLowerCase() == 'google'
      ? MapProvider.google
      : MapProvider.osm;

  final MapProvider requestedProvider;
  final String googleMapsApiKey;

  bool get hasGoogleKey => googleMapsApiKey.trim().isNotEmpty;

  /// The provider actually used. Google Maps without a key falls back to OSM.
  MapProvider get effectiveProvider =>
      requestedProvider == MapProvider.google && hasGoogleKey
      ? MapProvider.google
      : MapProvider.osm;

  /// True when Google was requested but cannot be used (so the UI can say so).
  bool get googleFellBack =>
      requestedProvider == MapProvider.google && !hasGoogleKey;

  static const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const osmAttribution = '© OpenStreetMap contributors';
  static const userAgentPackage = 'id.otoku.app';
}
