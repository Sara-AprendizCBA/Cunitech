import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../controllers/rabbit_controller.dart';
import '../../../models/rabbit.dart';

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

  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _weightCtrl;

  final List<String> _genders = ['Macho', 'Hembra'];
  final List<String> _states = ['Saludable', 'En Tratamiento', 'Enfermo'];

  late String _gender;
  late String _state;
  DateTime? _birthDate;
  late DateTime _entryDate;
  int? _farmId;
  int? _motherId;
  int? _fatherId;

  late final Future<List<Map<String, dynamic>>> _farmsFuture;

  bool get _isEditing => widget.rabbit != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rabbit;

    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _breedCtrl = TextEditingController(text: r?.breed ?? '');
    _weightCtrl = TextEditingController(
        text: (r != null && r.weightKg > 0) ? '${r.weightKg}' : '');

    if (r != null && !_genders.contains(r.gender)) _genders.add(r.gender);
    _gender = r?.gender ?? 'Macho';

    _state = r?.healthStatus ?? 'Saludable';
    if (_state.isEmpty) _state = 'Saludable';
    if (!_states.contains(_state)) _states.add(_state);

    _birthDate = r?.birthDate;
    _entryDate = r?.registrationDate ?? DateTime.now();
    _farmId = (r != null && r.farmId != 0) ? r.farmId : null;
    _motherId = r?.motherId;
    _fatherId = r?.fatherId;

    // Cargar granjas desde la tabla `granja`
    _farmsFuture = Supabase.instance.client
        .from('granja')
        .select('id_granja, nombre')
        .order('nombre')
        .then((rows) => List<Map<String, dynamic>>.from(rows));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Seleccionar' : '${d.day}/${d.month}/${d.year}';

  Future<void> _pickDate({required bool birth}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (birth ? _birthDate : _entryDate) ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => birth ? _birthDate = picked : _entryDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      Get.snackbar('Falta un dato', 'Selecciona la fecha de nacimiento');
      return;
    }

    final old = widget.rabbit;
    final weightText = _weightCtrl.text.trim().replaceAll(',', '.');

    final rabbit = Rabbit(
      id: old?.id ?? '',
      name: _nameCtrl.text.trim(),
      breed: _breedCtrl.text.trim(),
      gender: _gender,
      birthDate: _birthDate!,
      weightKg: weightText.isEmpty ? 0 : double.parse(weightText),
      healthStatus: _state,
      farmId: _farmId!,
      motherId: _motherId,
      fatherId: _fatherId,
      registrationDate: _entryDate,
    );

    // El controlador cierra el diálogo y muestra el mensaje
    if (_isEditing) {
      await rabbitController.updateRabbit(old!.id, rabbit);
    } else {
      await rabbitController.createRabbit(rabbit);
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
        ...candidates.map((r) => DropdownMenuItem<int?>(
              value: int.tryParse(r.id),
              child: Text('${r.name} #${r.id}'),
            )),
      ],
      onChanged: onChanged,
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
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _breedCtrl,
                  decoration: const InputDecoration(labelText: 'Raza *'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration:
                            const InputDecoration(labelText: 'Género *'),
                        items: _genders
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Peso (kg)'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n =
                              double.tryParse(v.trim().replaceAll(',', '.'));
                          if (n == null || n <= 0) return 'Peso válido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _state,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: _states
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _state = v!),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _farmsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const LinearProgressIndicator();
                    }
                    if (snap.hasError) {
                      return Text(
                          'No se pudieron cargar las granjas: ${snap.error}',
                          style: const TextStyle(color: Colors.red));
                    }
                    final farms = snap.data ?? [];
                    final ids =
                        farms.map((f) => f['id_granja'] as int).toSet();
                    return DropdownButtonFormField<int>(
                      initialValue: ids.contains(_farmId) ? _farmId : null,
                      decoration: const InputDecoration(labelText: 'Granja *'),
                      items: farms
                          .map((f) => DropdownMenuItem<int>(
                                value: f['id_granja'] as int,
                                child: Text('${f['nombre']}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _farmId = v),
                      validator: (v) =>
                          v == null ? 'Selecciona una granja' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _parentDropdown(
                  label: 'Madre',
                  gender: 'Hembra',
                  value: _motherId,
                  onChanged: (v) => setState(() => _motherId = v),
                ),
                const SizedBox(height: 12),
                _parentDropdown(
                  label: 'Padre',
                  gender: 'Macho',
                  value: _fatherId,
                  onChanged: (v) => setState(() => _fatherId = v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake_rounded),
                  title: const Text('Fecha de nacimiento *'),
                  subtitle: Text(_fmt(_birthDate)),
                  onTap: () => _pickDate(birth: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Fecha de ingreso *'),
                  subtitle: Text(_fmt(_entryDate)),
                  onTap: () => _pickDate(birth: false),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar'),
        ),
        Obx(
          () => ElevatedButton(
            onPressed: rabbitController.isLoading.value ? null : _save,
            child: rabbitController.isLoading.value
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