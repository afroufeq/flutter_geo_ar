import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/poi/poi_display_mode.dart';

void main() {
  group('PoiDisplayMode', () {
    test('tiene los valores correctos', () {
      expect(PoiDisplayMode.values.length, equals(2));
      expect(PoiDisplayMode.values, contains(PoiDisplayMode.always));
      expect(PoiDisplayMode.values, contains(PoiDisplayMode.distanceBased));
    });

    test('always es el primer valor', () {
      expect(PoiDisplayMode.values.first, equals(PoiDisplayMode.always));
    });

    test('distanceBased es el segundo valor', () {
      expect(PoiDisplayMode.values[1], equals(PoiDisplayMode.distanceBased));
    });

    test('los valores son distintos', () {
      expect(PoiDisplayMode.always, isNot(equals(PoiDisplayMode.distanceBased)));
    });

    test('toString retorna el nombre correcto para always', () {
      expect(PoiDisplayMode.always.toString(), equals('PoiDisplayMode.always'));
    });

    test('toString retorna el nombre correcto para distanceBased', () {
      expect(PoiDisplayMode.distanceBased.toString(), equals('PoiDisplayMode.distanceBased'));
    });

    test('puede comparar valores usando ==', () {
      expect(PoiDisplayMode.always == PoiDisplayMode.always, isTrue);
      expect(PoiDisplayMode.distanceBased == PoiDisplayMode.distanceBased, isTrue);
      expect(PoiDisplayMode.always == PoiDisplayMode.distanceBased, isFalse);
    });

    test('puede usar en switch statement', () {
      String result;

      switch (PoiDisplayMode.always) {
        case PoiDisplayMode.always:
          result = 'always';
          break;
        case PoiDisplayMode.distanceBased:
          result = 'distanceBased';
          break;
      }

      expect(result, equals('always'));
    });

    test('puede iterar sobre todos los valores', () {
      final modes = <PoiDisplayMode>[];
      for (final mode in PoiDisplayMode.values) {
        modes.add(mode);
      }

      expect(modes.length, equals(2));
      expect(modes, contains(PoiDisplayMode.always));
      expect(modes, contains(PoiDisplayMode.distanceBased));
    });

    group('Comparación de índices', () {
      test('always tiene índice 0', () {
        expect(PoiDisplayMode.always.index, equals(0));
      });

      test('distanceBased tiene índice 1', () {
        expect(PoiDisplayMode.distanceBased.index, equals(1));
      });
    });

    group('Uso en Maps', () {
      test('puede usarse como key en Map', () {
        final map = <PoiDisplayMode, String>{
          PoiDisplayMode.always: 'Siempre mostrar',
          PoiDisplayMode.distanceBased: 'Basado en distancia',
        };

        expect(map[PoiDisplayMode.always], equals('Siempre mostrar'));
        expect(map[PoiDisplayMode.distanceBased], equals('Basado en distancia'));
      });

      test('puede usarse como value en Map', () {
        final map = <String, PoiDisplayMode>{
          'default': PoiDisplayMode.always,
          'lod': PoiDisplayMode.distanceBased,
        };

        expect(map['default'], equals(PoiDisplayMode.always));
        expect(map['lod'], equals(PoiDisplayMode.distanceBased));
      });
    });

    group('Uso en Sets', () {
      test('puede usarse en Set', () {
        final set = <PoiDisplayMode>{
          PoiDisplayMode.always,
          PoiDisplayMode.distanceBased,
        };

        expect(set.length, equals(2));
        expect(set.contains(PoiDisplayMode.always), isTrue);
        expect(set.contains(PoiDisplayMode.distanceBased), isTrue);
      });

      test('Set elimina duplicados correctamente', () {
        final set = <PoiDisplayMode>{
          PoiDisplayMode.always,
          PoiDisplayMode.always,
          PoiDisplayMode.distanceBased,
        };

        expect(set.length, equals(2));
      });
    });
  });
}
