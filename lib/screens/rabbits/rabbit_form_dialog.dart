import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../controllers/rabbit_controller.dart';
import '../../../models/rabbit.dart';
import '../../../services/rabbit_service.dart';
import '../vision/vision_screen.dart';

/// Formulario para CREAR (rabbit == null) y EDITAR (rabbit != null)
class RabbitFormDialog extends StatefulWidget {
  final Rabbit? rabbit;

  const RabbitFormDialog({super.key, this.rabbit});

  @override
  State<RabbitFormDialog> createState() => _RabbitFormDialogState();
}

class _RabbitFormDialogState extends State<RabbitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final rabbitController = Get.find<RabbitController>();

  late final TextEditingController _breedCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _originCtrl;
  late final TextEditingController _registryNumberCtrl;
  late final TextEditingController _cageNumberCtrl;
  late final TextEditingController _chapetaCtrl;
  late final TextEditingController _lastWeightCtrl;

  final List<String> _genders = ['Macho', 'Hembra'];
  final List<String> _states = ['Saludable', 'En Tratamiento', 'Enfermo'];
  late String _gender;
  late String _state;
  DateTime? _birthDate;
  DateTime? _identificationEntryDate;
  int? _farmId;
  int? _motherId;
  int? _fatherId;
  XFile? _pickedPhoto;
  Uint8List? _aiPhotoBytes;
  String? _currentPhotoUrl;
  bool _isActiveBreeder = true;
  bool _saving = false;
  bool _chapetaAutoGenerada = false;
  String? _ultimaChapetaSugerida;

  late final Future<List<Map<String, dynamic>>> _farmsFuture;

  bool get _isEditing => widget.rabbit != null;

  /// La identificación con IA es solo para Admin y Veterinario (no Operario).
  bool get _canUseAI {
    final auth = Get.find<AuthController>();
    return auth.isAdmin || auth.isVeterinario;
  }

  @override
  void initState() {
    super.initState();
    final r = widget.rabbit;
    _currentPhotoUrl = r?.photoUrl;

    _breedCtrl = TextEditingController(text: r?.breed ?? '');
    _weightCtrl = TextEditingController(
      text: (r != null && r.weightKg > 0) ? '${r.weightKg}' : '',
    );
    _originCtrl = TextEditingController(text: r?.origin ?? '');
    _registryNumberCtrl = TextEditingController(text: r?.registryNumber ?? '');
    _cageNumberCtrl = TextEditingController(text: r?.cageNumber ?? '');
    _chapetaCtrl = TextEditingController(text: r?.chapeta ?? '');
    _lastWeightCtrl = TextEditingController(
      text: r?.lastWeightKg?.toString() ?? '',
    );
    if (r != null && !_genders.contains(r.gender)) _genders.add(r.gender);
    _gender = r?.gender ?? 'Macho';
    _isActiveBreeder = r?.isActiveBreeder ?? true;

    _state = r?.healthStatus ?? 'Saludable';
    if (_state.isEmpty) _state = 'Saludable';
    if (!_states.contains(_state)) _states.add(_state);

    _birthDate = r?.birthDate;
    _identificationEntryDate = r?.entryDate ?? r?.registrationDate;
    _farmId = (r != null && r.farmId != 0) ? r.farmId : null;
    _motherId = r?.motherId;
    _fatherId = r?.fatherId;

    // Autogenerar la chapeta cuando cambie la raza y el campo esté vacío.
    _breedCtrl.addListener(_onBreedChanged);
    // Si el usuario edita la chapeta manualmente, dejar de autogenerarla.
    _chapetaCtrl.addListener(_onChapetaChanged);

    // Cargar granjas desde la tabla `granja`
    _farmsFuture = Supabase.instance.client
        .from('granja')
        .select('id_granja, nombre')
        .order('nombre')
        .then((rows) => List<Map<String, dynamic>>.from(rows));
  }

  @override
  void dispose() {
    _breedCtrl.removeListener(_onBreedChanged);
    _chapetaCtrl.removeListener(_onChapetaChanged);
    _breedCtrl.dispose();
    _weightCtrl.dispose();
    _originCtrl.dispose();
    _registryNumberCtrl.dispose();
    _cageNumberCtrl.dispose();
    _chapetaCtrl.dispose();
    _lastWeightCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Seleccionar' : '${d.day}/${d.month}/${d.year}';

  Future<bool> _confirmWarning(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showAgeNotice(String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aviso reproductivo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() {
          _pickedPhoto = file;
          _aiPhotoBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Error al obtener la foto: $e');
      }
    }
  }

  Widget _buildPhotoPreview() {
    if (_pickedPhoto != null) {
      return FutureBuilder(
        future: _pickedPhoto!.readAsBytes(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        },
      );
    }
    if (_aiPhotoBytes != null) {
      return Image.memory(_aiPhotoBytes!, fit: BoxFit.cover);
    }
    if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      return Image.network(
        _currentPhotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_rounded,
          size: 40,
          color: Colors.grey,
        ),
      );
    }
    return const Center(
      child: Icon(Icons.pets_rounded, size: 48, color: Colors.grey),
    );
  }

  Future<void> _identifyBreedWithAI() async {
    final result = await Navigator.of(context).push<VisionResult>(
      MaterialPageRoute(builder: (_) => const VisionScreen()),
    );
    if (result == null || !mounted) return;
    // Forzar la regeneración de la chapeta con la raza detectada por la IA.
    _chapetaAutoGenerada = true;
    setState(() {
      _aiPhotoBytes = result.imagenBytes;
      _pickedPhoto = null;
      _breedCtrl.text = result.raza;
    });
  }

  void _onChapetaChanged() {
    if (!_chapetaAutoGenerada) return;
    // El listener dispara también cuando la autogeneración asigna el texto;
    // ese caso coincide con la última sugerencia y debe ignorarse.
    if (_chapetaCtrl.text == _ultimaChapetaSugerida) return;
    // El usuario sobrescribió el valor sugerido.
    _chapetaAutoGenerada = false;
  }

  /// Sugiere la chapeta cuando el usuario escribe/elige una raza y el campo
  /// de identificación todavía está vacío (o fue autogenerado antes).
  void _onBreedChanged() {
    if (_chapetaAutoGenerada || _chapetaCtrl.text.trim().isEmpty) {
      _sugerirChapeta(_breedCtrl.text);
    }
  }

  /// Prefijo de 2 letras a partir de la raza (ej. "Cabeza de León" -> "CL").
  String _prefijoRaza(String raza) {
    final palabras = raza
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (palabras.length >= 2) {
      return (palabras[0][0] + palabras[1][0]).toUpperCase();
    }
    final limpio = raza.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÑáéíóúñ]'), '');
    if (limpio.isEmpty) return 'CN';
    return limpio.substring(0, limpio.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Consulta cuántos conejos hay de esta raza y propone la siguiente
  /// chapeta correlativa (ej. CL-001, CL-002). No sobreescribe si el campo
  /// ya tiene un valor distinto.
  Future<void> _sugerirChapeta(String raza) async {
    if (raza.trim().isEmpty) return;
    final prefijo = _prefijoRaza(raza);
    try {
      final rows = await Supabase.instance.client
          .from('conejo')
          .select('chapeta')
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
          .ilike('chapeta', '$prefijo-%');
      final regex = RegExp('^$prefijo-(\\d+)\$');
      int max = 0;
      for (final row in rows) {
        final chapeta = (row['chapeta'] as String?) ?? '';
        final m = regex.firstMatch(chapeta);
        if (m != null) {
          final n = int.tryParse(m.group(1)!) ?? 0;
          if (n > max) max = n;
        }
      }
      final sugerida = '$prefijo-${(max + 1).toString().padLeft(3, '0')}';
      if (!mounted) return;
      _ultimaChapetaSugerida = sugerida;
      _chapetaAutoGenerada = true;
      setState(() {
        _chapetaCtrl.text = sugerida;
      });
    } catch (e) {
      debugPrint('No se pudo sugerir chapeta: $e');
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      AppSnackbar.warning(context, 'Selecciona la fecha de nacimiento');
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);

    try {
      String? photoUrl = widget.rabbit?.photoUrl;
      if (_pickedPhoto != null) {
        photoUrl = await RabbitService().uploadPhoto(_pickedPhoto!);
        if (photoUrl == null) {
          throw Exception('No se pudo subir la foto');
        }
      } else if (_aiPhotoBytes != null) {
        final aiFile = XFile.fromData(
          _aiPhotoBytes!,
          name: 'ai_${DateTime.now().millisecondsSinceEpoch}.jpg',
          mimeType: 'image/jpeg',
        );
        photoUrl = await RabbitService().uploadPhoto(aiFile);
        if (photoUrl == null) {
          throw Exception('No se pudo subir la foto de la IA');
        }
      }

      final old = widget.rabbit;
      final weightText = _weightCtrl.text.trim().replaceAll(',', '.');

      final rabbit = Rabbit(
        id: old?.id ?? '',
        name: null,
        breed: _breedCtrl.text.trim(),
        gender: _gender,
        birthDate: _birthDate!,
        weightKg: weightText.isEmpty ? 0 : double.parse(weightText),
        healthStatus: _state,
        farmId: _farmId!,
        motherId: _motherId,
        fatherId: _fatherId,
        registrationDate:
            _identificationEntryDate ?? old?.registrationDate ?? DateTime.now(),
        entryDate: _identificationEntryDate,
        origin: _originCtrl.text.trim().isEmpty
            ? null
            : _originCtrl.text.trim(),
        registryNumber: _registryNumberCtrl.text.trim().isEmpty
            ? null
            : _registryNumberCtrl.text.trim(),
        cageNumber: _cageNumberCtrl.text.trim().isEmpty
            ? null
            : _cageNumberCtrl.text.trim(),
        photoUrl: photoUrl,
        chapeta: _chapetaCtrl.text.trim(),
        placaInventario: old?.placaInventario,
        isActiveBreeder: _isActiveBreeder,
        lastWeightKg: double.tryParse(
          _lastWeightCtrl.text.trim().replaceAll(',', '.'),
        ),
      );

      final success = _isEditing
          ? await rabbitController.updateRabbit(old!.id, rabbit)
          : await rabbitController.createRabbit(rabbit);
      if (!success) throw Exception('Guardar conejo devolvió false');

      if (_isEditing && Get.isRegistered<DashboardController>()) {
        await Get.find<DashboardController>().loadDashboardData();
      }

      if (!mounted) return;
      AppSnackbar.success(
        context,
        _isEditing ? 'Conejo actualizado' : 'Conejo creado',
      );
      navigator.pop();
    } catch (e, st) {
      debugPrint('ERROR SUBMIT: $e');
      debugPrint('STACK: $st');
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.error(context, 'Error al guardar: $e');
      }
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  Widget _parentDropdown({
    required String label,
    required String gender,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    final candidates = rabbitController.rabbits
        .where((r) => r.gender == gender && r.id != widget.rabbit?.id)
        .toList();
    final ids = candidates.map((r) => int.tryParse(r.id)).toSet();
    return DropdownButtonFormField<int?>(
      initialValue: ids.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Sin registrar')),
        ...candidates.map(
          (r) => DropdownMenuItem<int?>(
            value: int.tryParse(r.id),
            child: Text(r.displayId),
          ),
        ),
      ],
      onChanged: (selectedId) async {
        Rabbit? selectedRabbit;
        for (final candidate in candidates) {
          if (int.tryParse(candidate.id) == selectedId) {
            selectedRabbit = candidate;
            break;
          }
        }

        if (selectedRabbit != null) {
          final ageDays = DateTime.now()
              .difference(selectedRabbit.birthDate)
              .inDays;
          if (ageDays < 120 &&
              !await _confirmWarning(
                'Reproductor muy joven',
                'El ${gender.toLowerCase()} seleccionado tiene menos de '
                    '4 meses. ¿Continuar de todas formas?',
              )) {
            return;
          }
          if (ageDays > 5 * 365) {
            await _showAgeNotice(
              'El ${gender.toLowerCase()} seleccionado tiene más de 5 años.',
            );
          }
        }
        if (mounted) onChanged(selectedId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar conejo' : 'Nuevo conejo'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildPhotoPreview(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _pickPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text('Cámara'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(
                            Icons.photo_library_rounded,
                            size: 18,
                          ),
                          label: const Text('Galería'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _chapetaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'N° de identificación *',
                    helperText: 'Ej: C-045, A-12 (visible en el conejo)',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Género *'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (nuevoSexo) {
                    setState(() {
                      final anterior = _gender;
                      _gender = nuevoSexo ?? 'Macho';

                      if (_gender == 'Macho' && anterior == 'Hembra') {
                        _isActiveBreeder = true;
                        _lastWeightCtrl.clear();
                      } else if (_gender == 'Hembra' && anterior == 'Macho') {
                        _isActiveBreeder = false;
                        _lastWeightCtrl.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _breedCtrl,
                        decoration: const InputDecoration(labelText: 'Raza *'),
                        validator: _required,
                      ),
                    ),
                    if (_canUseAI) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _saving ? null : _identifyBreedWithAI,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Identificar con IA'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final weight = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );
                    if (weight == null || weight <= 0) return 'Peso válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cageNumberCtrl,
                  decoration: const InputDecoration(labelText: 'Jaula'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _state,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: _states
                      .map(
                        (state) =>
                            DropdownMenuItem(value: state, child: Text(state)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _state = value!),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _farmsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'No se pudieron cargar las granjas: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                    final farms = snapshot.data ?? [];
                    final ids = farms
                        .map((farm) => farm['id_granja'] as int)
                        .toSet();
                    return DropdownButtonFormField<int>(
                      initialValue: ids.contains(_farmId) ? _farmId : null,
                      decoration: const InputDecoration(labelText: 'Granja *'),
                      items: farms
                          .map(
                            (farm) => DropdownMenuItem<int>(
                              value: farm['id_granja'] as int,
                              child: Text('${farm['nombre']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _farmId = value),
                      validator: (value) =>
                          value == null ? 'Selecciona una granja' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _parentDropdown(
                  label: 'Madre',
                  gender: 'Hembra',
                  value: _motherId,
                  onChanged: (value) => setState(() => _motherId = value),
                ),
                const SizedBox(height: 12),
                _parentDropdown(
                  label: 'Padre',
                  gender: 'Macho',
                  value: _fatherId,
                  onChanged: (value) => setState(() => _fatherId = value),
                ),
                const SizedBox(height: 12),
                if (_gender == 'Hembra') ...[
                  Card(
                    margin: const EdgeInsets.only(top: 16),
                    color: AppTheme.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Estado reproductivo',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'El estado reproductivo se gestiona desde el módulo de '
                            'Reproducción (monta, palpación, parto y destete).',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_gender == 'Macho') ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activo como reproductor'),
                    value: _isActiveBreeder,
                    onChanged: (value) =>
                        setState(() => _isActiveBreeder = value),
                  ),
                  TextFormField(
                    controller: _lastWeightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Último peso (kg)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final weight = double.tryParse(
                        value.trim().replaceAll(',', '.'),
                      );
                      if (weight == null || weight <= 0) return 'Peso válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _originCtrl,
                  decoration: const InputDecoration(labelText: 'Origen'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _registryNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Número de registro',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_rounded),
                  title: const Text('Fecha de ingreso al criadero'),
                  subtitle: Text(_fmt(_identificationEntryDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _identificationEntryDate ?? DateTime.now(),
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _identificationEntryDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake_rounded),
                  title: const Text('Fecha de nacimiento *'),
                  subtitle: Text(_fmt(_birthDate)),
                  onTap: _pickBirthDate,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
        Obx(
          () => ElevatedButton(
            onPressed: rabbitController.isLoading.value || _saving
                ? null
                : _save,
            child: rabbitController.isLoading.value || _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Guardar cambios' : 'Crear'),
          ),
        ),
      ],
    );
  }
}
