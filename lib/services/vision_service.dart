// lib/services/vision_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';

/// Resultado de la identificación de raza por foto.
class RazaIdentificacion {
  final String raza;
  final String confianza; // 'alta' | 'media' | 'baja'
  final String descripcion;

  const RazaIdentificacion({
    required this.raza,
    required this.confianza,
    required this.descripcion,
  });

  factory RazaIdentificacion.fromJson(Map<String, dynamic> json) {
    final confianza = (json['confianza'] as String? ?? 'baja').toLowerCase();
    return RazaIdentificacion(
      raza: json['raza'] as String? ?? 'No identificada',
      confianza: ['alta', 'media', 'baja'].contains(confianza)
          ? confianza
          : 'baja',
      descripcion: json['descripcion'] as String? ?? '',
    );
  }
}

/// Identifica la raza de un conejo a partir de una foto usando Gemini 2.0
/// Flash vía la Edge Function `identify-breed` (la API key vive en los
/// secretos de Supabase, nunca en el cliente).
class VisionService {
  final _supabase = Supabase.instance.client;

  /// Convierte la imagen a Base64, la envía a la Edge Function y devuelve
  /// la identificación. Lanza [Exception] si algo falla.
  Future<RazaIdentificacion> identificarRaza(Uint8List bytesImagen) async {
    try {
      final response = await _supabase.functions.invoke(
        'identify-breed',
        body: {'imagen_base64': base64Encode(bytesImagen)},
      );

      if (response.status < 200 || response.status >= 300) {
        logger.e('identify-breed respondió ${response.status}');
        throw Exception('El servicio de IA no está disponible');
      }

      final data = response.data;
      if (data is! Map) {
        throw Exception('Respuesta inválida del servicio de IA');
      }

      final identificacion = RazaIdentificacion.fromJson(
        data.cast<String, dynamic>(),
      );
      if (identificacion.raza.isEmpty) {
        throw Exception('No se pudo identificar la raza');
      }
      return identificacion;
    } catch (e) {
      logger.e('Error identificarRaza', error: e);
      rethrow;
    }
  }
}
