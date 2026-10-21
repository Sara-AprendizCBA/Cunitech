// lib/screens/chat/assistant_chat_screen.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../services/chat_service.dart';

/// Mensaje mostrado en el chat (usuario o asistente).
class _ChatMessage {
  final String texto;
  final bool esUsuario;

  const _ChatMessage({required this.texto, required this.esUsuario});
}

/// Asistente conversacional de CUNITECH: el usuario pregunta sobre su criadero
/// y Gemini responde con el contexto real de la base de datos.
class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<_ChatMessage> _mensajes = [
    const _ChatMessage(
      texto: '¡Hola! Soy tu asistente CUNITECH. Pregúntame sobre la '
          'fertilidad, tus conejas o cualquier dato de tu criadero.',
      esUsuario: false,
    ),
  ];
  bool _enviando = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviar() async {
    final texto = _inputCtrl.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() {
      _mensajes.add(_ChatMessage(texto: texto, esUsuario: true));
      _enviando = true;
    });
    _inputCtrl.clear();
    _scrollAlFinal();

    try {
      final respuesta = await _chatService.enviarMensaje(texto);
      if (!mounted) return;
      setState(() {
        _mensajes.add(_ChatMessage(texto: respuesta, esUsuario: false));
        _enviando = false;
      });
      _scrollAlFinal();
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      AppSnackbar.error(context, 'No se pudo obtener respuesta: $e');
    }
  }

  Widget _buildBurbuja(_ChatMessage m) {
    final esUsuario = m.esUsuario;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!esUsuario) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: esUsuario ? AppTheme.accent : AppTheme.surfaceLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppTheme.radiusMd),
                  topRight: const Radius.circular(AppTheme.radiusMd),
                  bottomLeft: Radius.circular(esUsuario ? AppTheme.radiusMd : 4),
                  bottomRight:
                      Radius.circular(esUsuario ? 4 : AppTheme.radiusMd),
                ),
                border: esUsuario
                    ? null
                    : Border.all(color: AppTheme.borderLight),
              ),
              child: Text(
                m.texto,
                style: TextStyle(
                  color: esUsuario ? Colors.white : AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (esUsuario) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildEscribiendo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          const Text(
            'Escribiendo…',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 20),
            SizedBox(width: 8),
            Text('Asistente CUNITECH'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _mensajes.length + (_enviando ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i < _mensajes.length) return _buildBurbuja(_mensajes[i]);
                  return _buildEscribiendo();
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceLight,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      enabled: !_enviando,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu pregunta…',
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviando ? null : _enviar,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
