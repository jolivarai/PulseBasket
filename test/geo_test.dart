import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_basket/core/formatters.dart';
import 'package:pulso_basket/core/geo.dart';

void main() {
  group('Geo.haversine', () {
    test('0 metros entre el mismo punto', () {
      expect(Geo.haversine(4.65, -74.05, 4.65, -74.05), closeTo(0, 0.01));
    });

    test('distancia conocida: Bogotá -> Medellín ≈ 240 km', () {
      // 4.7110,-74.0721  ->  6.2442,-75.5812
      final double d = Geo.haversine(4.7110, -74.0721, 6.2442, -75.5812);
      expect(d / 1000, closeTo(240, 12));
    });
  });

  group('DistanceFilter', () {
    test('descarta precisión mala', () {
      final DistanceFilter f = DistanceFilter();
      expect(f.add(lat: 4.0, lng: -74.0, accuracy: 80, rawSpeed: 3), 0);
    });

    test('no acumula ruido por debajo del umbral', () {
      final DistanceFilter f = DistanceFilter(minMovement: 3);
      f.add(lat: 4.000000, lng: -74.000000, accuracy: 5, rawSpeed: 0);
      // ~1 m al norte: por debajo del umbral de 3 m
      final double gained =
          f.add(lat: 4.000009, lng: -74.000000, accuracy: 5, rawSpeed: 0);
      expect(gained, 0);
    });

    test('acumula un desplazamiento real', () {
      final DistanceFilter f = DistanceFilter(minMovement: 3, maxAccuracy: 25);
      f.add(lat: 4.000000, lng: -74.000000, accuracy: 5, rawSpeed: 3);
      // ~22 m al norte
      final double gained =
          f.add(lat: 4.000200, lng: -74.000000, accuracy: 5, rawSpeed: 3);
      expect(gained, greaterThan(15));
      expect(gained, lessThan(30));
    });
  });

  group('Fmt', () {
    test('ritmo 3,33 m/s ≈ 5\'00"', () {
      expect(Fmt.pace(1000 / 300), "5'00\"");
    });

    test('sin movimiento devuelve guiones', () {
      expect(Fmt.pace(0), "--'--\"");
    });

    test('distancia en metros y kilómetros', () {
      expect(Fmt.distance(850), '850 m');
      expect(Fmt.distance(12000), '12,0 km');
    });
  });
}
