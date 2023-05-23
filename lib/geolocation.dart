// Класс координат.
import 'package:geolocator/geolocator.dart';

// Модель данных.
class LatLong {
  final double lat;
  final double long;

  const LatLong({
    required this.lat,
    required this.long,
  });
}

// Координаты города.
class CityLocation extends LatLong {
  const CityLocation({
    super.lat = 65.5333300,
    super.long = 72.5166700,
  });
}

abstract class AppLocation {
  Future<LatLong> getCurrentLocation();

  Future<bool> requestPermission();

  Future<bool> checkPermission();
}

// Сервис геолокаций.
class LocationService implements AppLocation {
  final defLocation = const CityLocation();

  /// Получение текущей гео.
  @override
  Future<LatLong> getCurrentLocation() async {
    return Geolocator.getCurrentPosition().then((value) {
      return LatLong(lat: value.latitude, long: value.longitude);
    }).catchError(
          (_) => defLocation,
    );
  }

  /// Отправить запрос на разрешение получения гео.
  @override
  Future<bool> requestPermission() {
    return Geolocator.requestPermission()
        .then((value) =>
    value == LocationPermission.always ||
        value == LocationPermission.whileInUse)
        .catchError((_) => false);
  }

  /// Проверка разрешения.
  @override
  Future<bool> checkPermission() {
    return Geolocator.checkPermission()
        .then((value) =>
    value == LocationPermission.always ||
        value == LocationPermission.whileInUse)
        .catchError((_) => false);
  }
}