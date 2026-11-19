import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cheap reachability probe used by the map to show an offline notice.
abstract interface class NetworkChecker {
  Future<bool> isOnline();
}

class DnsNetworkChecker implements NetworkChecker {
  const DnsNetworkChecker();
  @override
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('tile.openstreetmap.org')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

/// Hands a destination off to an external maps application.
abstract interface class ExternalMapLauncher {
  Future<bool> openDirections(LatLng destination, String label);
}

class UrlExternalMapLauncher implements ExternalMapLauncher {
  const UrlExternalMapLauncher();

  @override
  Future<bool> openDirections(LatLng destination, String label) async {
    final lat = destination.latitude, lng = destination.longitude;
    final candidates = [
      Uri.parse('google.navigation:q=$lat,$lng'),
      Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label)})'),
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
    ];
    for (final uri in candidates) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {
        // try the next handler
      }
    }
    return false;
  }
}
