// lib/screens/vision/vision_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../services/vision_service.dart';

/// Resultado devuelto por [VisionScreen]: la raza identificada y los bytes
/// de la foto analizada (para reusarla como foto del conejo).
class VisionResult {
  final String raza;
  final Uint8List imagenBytes;

  const VisionResult({required this.raza, required this.imagenBytes});
}

/// Pantalla de identificación de raza por foto con Gemini Vision.
/// Al detectar la raza devuelve un [VisionResult] con [Navigator.pop].
class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  final VisionService _visionService = VisionService();

  Uint8List? _fotoBytes;
  bool _analizando = false;
  RazaIdentificacion? _resultado;
  String? _error;

  bool get _puedeUsarIA {
    final auth = Get.find<AuthController>();
    return auth.isAdmin || auth.isVeterinario;
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();

      setState(() {
        _fotoBytes = bytes;
        _analizando = true;
        _resultado = null;
        _error = null;
      });

      final resultado = await _visionService.identificarRaza(bytes);

      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _analizando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analizando = false;
        _error = 'No se pudo analizar la foto: $e';
      });
      AppSnackbar.error(context, 'Error al identificar la raza');
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'Tomar / Subir foto',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Tomar foto con la cámara'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndAnalyze(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Subir desde la galería'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndAnalyze(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoPreview() {
    final bytes = _fotoBytes;
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_camera_rounded,
                    size: 48,
                    color: AppTheme.textTertiary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sube una foto para comenzar',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Image.memory(
              bytes,
              fit: BoxFit.contain,
              width: double.infinity,
              height: 300,
            ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: AppTheme.danger.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: AppTheme.danger, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_puedeUsarIA) {
      return Scaffold(
        appBar: AppBar(title: const Text('Identificar raza con IA')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Solo Administradores y Veterinarios pueden usar la '
              'identificación con IA.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Identificar raza con IA')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sube o toma una foto del conejo y la IA detectará la raza.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _analizando ? null : _showSourceSheet,
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Tomar / Subir foto'),
              ),
            ),
            const SizedBox(height: 20),
            _buildFotoPreview(),
            const SizedBox(height: 16),
            if (_analizando) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Analizando foto con IA…',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              _buildErrorCard(),
            ],
            if (_resultado != null) ...[
              const SizedBox(height: 8),
              _ResultCard(resultado: _resultado!),
              if (_resultado!.raza != 'No identificada' &&
                  _resultado!.raza.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fotoBytes == null
                      ? null
                      : () => Navigator.pop(
                          context,
                          VisionResult(
                            raza: _resultado!.raza,
                            imagenBytes: _fotoBytes!,
                          ),
                        ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Usar esta raza'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final RazaIdentificacion resultado;

  const _ResultCard({required this.resultado});

  Color get _confianzaColor {
    switch (resultado.confianza) {
      case 'alta':
        return AppTheme.success;
      case 'media':
        return AppTheme.warning;
      default:
        return AppTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final descripcion = resultado.raza == 'No identificada'
        ? 'Asegúrate de que la foto muestre el cuerpo completo del conejo y '
              'tenga buena iluminación.'
        : resultado.descripcion;

    return Card(
      color: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: AppTheme.accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pets_rounded,
                  color: AppTheme.accent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Resultado',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _confianzaColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Confianza: ${resultado.confianza}',
                    style: TextStyle(
                      color: _confianzaColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              resultado.raza,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (descripcion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
