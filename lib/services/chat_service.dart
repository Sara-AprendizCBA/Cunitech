// lib/services/chat_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';

/// Envía preguntas al asistente conversacional de CUNITECH a través de la Edge
/// Function `chat-assistant` (Gemini + contexto real del criadero).
class ChatService {
  final _supabase = Supabase.instance.client;

  /// Envía [mensaje] al asistente y devuelve la respuesta de texto.
  /// Lanza [Exception] si algo falla.
  Future<String> enviarMensaje(String mensaje) async {
    try {
      final response = await _supabase.functions.invoke(
        'chat-assistant',
        body: {'mensaje': mensaje},
      );

      if (response.status < 200 || response.status >= 300) {
        logger.e('chat-assistant respondió ${response.status}');
        throw Exception('El asistente no está disponible');
      }

      final data = response.data;
      if (data is! Map || data['respuesta'] is! String) {
        throw Exception('Respuesta inválida del asistente');
      }
      return data['respuesta'] as String;
    } catch (e) {
      logger.e('Error enviarMensaje', error: e);
      rethrow;
    }
  }
}
