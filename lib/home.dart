import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'geolocation.dart';

class Home extends StatefulWidget {
  const Home({super.key});



  @override
  State<Home> createState() => _HomeState();

}

class _HomeState extends State<Home> {


  // Контроллер от Yandex map SDK.
  final mapControllerCompleter = Completer<YandexMapController>();
  late YandexMapController _controller;

  // Объекты на карте.
  final List<MapObject> mapObjects = [];

  // Поинты.
  List<Point> listPoints = [];

  // Маршруты.
  final List<DrivingSessionResult> results = [];
  late DrivingSessionResult result;
  late DrivingSession session;

  // Пользовательские дефолтные координаты.
  LatLong userPosition = const LatLong(lat: 0, long: 0);
  LatLong endPosition = const LatLong(lat: 0, long: 0);

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      _initPermission().ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          return Stack(
            children: <Widget>[

              YandexMap(
                onMapTap: (Point point) {
                  addMarker(point);
                },
                onMapCreated: (controller) async {
                  _controller = controller;
                  mapControllerCompleter.complete(controller);
                  await controller.toggleUserLayer(visible: true, autoZoomEnabled: true);
                },
                mapObjects: mapObjects,
                onUserLocationAdded: (UserLocationView view) async {
                  return view.copyWith(
                    pin: view.pin.copyWith(
                      icon: PlacemarkIcon.single(
                        PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage('lib/assets/img/posimarker.png'),
                        ),
                      ),
                    ),
                    arrow: view.arrow.copyWith(
                      icon: PlacemarkIcon.single(
                        PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage('lib/assets/img/posimarker.png'),
                        ),
                      ),
                    ),
                    accuracyCircle: view.accuracyCircle.copyWith(
                      fillColor: Colors.blue.withOpacity(0),
                      strokeColor: Colors.blue.withOpacity(0),
                      strokeWidth: 3,
                    ),
                  );
                },
              ),


              /// Поиск своей гео.
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    _moveToCurrentLocation(userPosition);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5.0,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7)
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 25,
                        child: Icon(Icons.my_location, color: Colors.black)
                    ),
                  ),
                ),
              ),

              /// Построить дорогу до метки.
              Positioned(
                bottom: 50,
                right: 50,
                child: GestureDetector(
                  onTap: () {
                    buildRoad();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5.0,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7)
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: Icon(Icons.place, color: Colors.black)
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
  /// Доступ на получение гео.
  Future<void> _initPermission() async {
    if (!await LocationService().checkPermission()) {
      await LocationService().requestPermission();
    }
    await _fetchCurrentLocation();
  }

  /// Поиск местоположения
  Future<void> _fetchCurrentLocation() async {
    LatLong location;
    const defLocation = CityLocation();
    try {
      location = await LocationService().getCurrentLocation();
    } catch (_) {
      location = defLocation;
    }

    userPosition = LatLong(
      lat: location.lat,
      long: location.long,
    );

    _moveToCurrentLocation(userPosition);
  }

  /// Метод для показа текущей позиции.
  // ignore: non_constant_identifier_names
  Future<void> _moveToCurrentLocation(LatLong LatLong) async {
    _controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: Point(latitude: LatLong.lat, longitude: LatLong.long),
            zoom: 18
        ),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.linear,
        duration: 1,
      ),
    );
  }

  /// Метод для добавления маркера.
  addMarker(Point point) async {

    PlacemarkMapObject markpic = PlacemarkMapObject(
      consumeTapEvents: true,
      mapId: const MapObjectId('mark'),
      point: Point(latitude: point.latitude, longitude: point.longitude),
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(image: BitmapDescriptor.fromAssetImage('lib/assets/img/posMarker.png'), scale: 0.75),
      ),
      opacity: 1.0,
    );

    endPosition = LatLong(
      lat: point.latitude,
      long: point.longitude,
    );

    setState(() {
      mapObjects.add(markpic);
    });
  }

  /// Метод прокладки маршрута.
  requestRoutes(LatLong startPoint, LatLong endPoint) async {
    List<RequestPoint> listRequestPoints = [
      RequestPoint(
        point: Point(
          latitude: startPoint.lat,
          longitude: startPoint.long,
        ),
        requestPointType: RequestPointType.wayPoint,
      ),
      RequestPoint(
        point: Point(
          latitude: endPoint.lat,
          longitude: endPoint.long,
        ),
        requestPointType: RequestPointType.wayPoint,
      ),
    ];

    var resultWithSession = YandexDriving.requestRoutes(
        points: listRequestPoints,
        drivingOptions: const DrivingOptions(
            initialAzimuth: 0, routesCount: 1, avoidTolls: true));

    return resultWithSession;
  }

  /// Создания дороги.
  void buildRoad() async {
    var resultWithSession = await requestRoutes(userPosition, endPosition);

    result = await resultWithSession.result;
    session = await resultWithSession.session;
    setState(() {
      result.routes?.asMap().forEach((i, route) {
        mapObjects.add(PolylineMapObject(
          mapId: MapObjectId('route_${i}_polyline'),
          polyline: Polyline(points: route.geometry),
          strokeColor: Colors.green,
          strokeWidth: 3,
        ));
      });
    });
  }
}
