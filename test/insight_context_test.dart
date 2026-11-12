import 'package:flutter_test/flutter_test.dart';

import 'package:cunitech/services/insight_service.dart';

void main() {
  group('calculo de mortalidad para el analisis de la IA', () {
    test('calcula mortalidad y supervivencia sobre los partos', () {
      final datos = InsightService.calcularMortalidad([
        {
          'birth_date': '2026-11-01',
          'live_kits': 6,
          'dead_kits': 2,
          'adopted_kits': 1,
          'litter_size': 8,
          'average_weight': 0.42,
        },
        {
          'birth_date': '2026-10-20',
          'live_kits': 4,
          'dead_kits': 4,
          'adopted_kits': 0,
          'litter_size': 8,
        },
      ]);

      // 6 muertas de 16 nacidas -> 37.5%
      expect(datos['mortalidad_porcentaje'], 37.5);
      // 10 vivas de 16 -> 62.5%
      expect(datos['supervivencia_porcentaje'], 62.5);
      expect(datos['crias_vivas_30_dias'], 10);
      expect(datos['crias_muertas_30_dias'], 6);
      expect(datos['crias_adoptadas_30_dias'], 1);
      expect(datos['camadas_30_dias'], 2);
    });

    test('el historial de partos viaja al contexto', () {
      final datos = InsightService.calcularMortalidad([
        {
          'birth_date': '2026-11-01',
          'live_kits': 5,
          'dead_kits': 1,
          'adopted_kits': 0,
          'litter_size': 6,
          'average_weight': 0.5,
        },
      ]);

      final historial = datos['historial_partos'] as List;
      expect(historial, hasLength(1));
      final parto = historial.first as Map<String, dynamic>;
      expect(parto['fecha'], '2026-11-01');
      expect(parto['vivos'], 5);
      expect(parto['muertos'], 1);
      expect(parto['camada'], 6);
      expect(parto['peso_promedio_kg'], 0.5);
    });

    test('sin partos no divide entre cero', () {
      final datos = InsightService.calcularMortalidad(const []);
      expect(datos['mortalidad_porcentaje'], 0.0);
      expect(datos['supervivencia_porcentaje'], 0.0);
      expect(datos['camadas_30_dias'], 0);
      expect(datos['historial_partos'], isEmpty);
    });
  });
}
