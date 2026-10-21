// lib/screens/chat/voice_assistant_screen.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../services/chat_service.dart';
import '../../services/voice_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final ChatService _chatService = ChatService();

  bool _escuchando = false;
  bool _pensando = false;
  String _textoReconocido = '';
  String _respuesta = '';
  late AnimationController _animacionController;
  late Animation<double> _animacionEscala;

  @override
  void initState() {
    super.initState();
    _inicializar();
    _animacionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animacionEscala = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(
      CurvedAnimation(
        parent: _animacionController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _inicializar() async {
    await _voiceService.inicializar();
  }

  @override
  void dispose() {
    _animacionController.dispose();
    _voiceService.detener();
    super.dispose();
  }

  void _iniciarAnimacion() {
    _animacionController.repeat(reverse: true);
  }

  void _detenerAnimacion() {
    _animacionController.stop();
    _animacionController.reset();
  }

  Future<void> _empezarEscuchar() async {
    if (_escuchando || _pensando) return;

    setState(() {
      _escuchando = true;
      _textoReconocido = '';
      _respuesta = '';
    });
    _iniciarAnimacion();

    try {
      final texto = await _voiceService.escuchar();
      if (!mounted) return;
      setState(() {
        _textoReconocido = texto;
        _escuchando = false;
      });
      _detenerAnimacion();
      await _procesarTexto(texto);
    } catch (e) {
      if (!mounted) return;
      _detenerAnimacion();
      setState(() {
        _escuchando = false;
        _pensando = false;
      });
      AppSnackbar.error(context, 'No se pudo escuchar: $e');
    }
  }

  void _detenerEscuchar() {
    if (_escuchando) {
      _voiceService.detener();
      setState(() => _escuchando = false);
      _detenerAnimacion();
    }
  }

  Future<void> _procesarTexto(String texto) async {
    setState(() {
      _pensando = true;
    });

    try {
      final respuesta = await _chatService.enviarMensaje(texto);
      if (!mounted) return;
      setState(() {
        _respuesta = respuesta;
        _pensando = false;
      });
      await _voiceService.hablar(respuesta);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pensando = false;
      });
      AppSnackbar.error(context, 'No se pudo obtener respuesta: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente por Voz'),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_textoReconocido.isNotEmpty && !_pensando && !_escuchando) ...[
              Text(
                'Tu pregunta:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _textoReconocido,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ],
            if (_respuesta.isNotEmpty && !_pensando) ...[
              Text(
                'Respuesta:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _respuesta,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
            if (_pensando) ...[
              const CircularProgressIndicator(
                color: AppTheme.accent,
              ),
              const SizedBox(height: 16),
              Text(
                'Pensando...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
            ],
            if (!_pensando && _respuesta.isEmpty) ...[
              Text(
                _escuchando ? 'Escuchando...' : 'Mantén presionado para hablar',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!_escuchando)
                Text(
                  'Presiona el micrófono y habla',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
            ],
            const SizedBox(height: 48),
            GestureDetector(
              onLongPressStart: (_) => _empezarEscuchar(),
              onLongPressEnd: (_) => _detenerEscuchar(),
              onTap: () {
                if (!_escuchando && !_pensando) {
                  AppSnackbar.info(context, 'Mantén presionado para hablar');
                }
              },
              child: AnimatedBuilder(
                animation: _animacionEscala,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animacionEscala.value,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: _escuchando
                          ? Colors.red
                          : _pensando
                              ? AppTheme.accent.withValues(alpha: 0.5)
                              : AppTheme.accent,
                      child: Icon(
                        _pensando
                            ? Icons.hourglass_empty
                            : Icons.mic,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            if (!_escuchando && !_pensando && _respuesta.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _textoReconocido = '';
                    _respuesta = '';
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Preguntar de nuevo'),
              ),
          ],
        ),
      ),
    );
  }
}
