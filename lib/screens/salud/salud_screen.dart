// lib/screens/salud/salud_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/rabbit_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../models/tratamiento.dart';
import '../../services/salud_service.dart';

class SaludScreen extends StatefulWidget {
  const SaludScreen({super.key});

  @override
  State<SaludScreen> createState() => _SaludScreenState();
}

class _SaludScreenState extends State<SaludScreen> {
  final SaludService _service = SaludService();
  final AuthController _auth = Get.find<AuthController>();

  List<Tratamiento> _items = [];
  bool _loading = true;
  String _filtro = 'todos';

  static const List<String> _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _loading = true);
    final data = await _service.getAll();
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  // ==================== FILTRADO ====================
  List<Tratamiento> get _filtrados {
    switch (_filtro) {
      case 'vacunas':
        return _items.where((t) => t.tipo == 'vacuna').toList();
      case 'tratamientos':
        return _items
            .where((t) => t.tipo == 'tratamiento' || t.tipo == 'desparasitacion')
            .toList();
      case 'proximas':
        final hoy = DateTime.now();
        final desde = DateTime(hoy.year, hoy.month, hoy.day);
        final hasta = desde.add(const Duration(days: 7));
        return _items
            .where((t) =>
                t.fechaProxima != null &&
                !t.fechaProxima!.isBefore(desde) &&
                !t.fechaProxima!.isAfter(hasta))
            .toList();
      default:
        return _items;
    }
  }

  String _fmtFecha(DateTime d) => '${d.day} ${_meses[d.month - 1]} ${d.year}';

  IconData _iconoTipo(String tipo) => switch (tipo) {
        'vacuna' => Icons.vaccines_outlined,
        'desparasitacion' => Icons.pest_control_rounded,
        _ => Icons.medical_services_outlined,
      };

  // ==================== ACCIONES ====================
  Future<void> _abrirFormulario({Tratamiento? existing}) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => _TratamientoFormDialog(
        service: _service,
        existing: existing,
      ),
    );
    if (guardado == true) {
      await _cargar();
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Salud'),
      ),
      floatingActionButton: Obx(() {
        if (!_auth.isVeterinario) return const SizedBox.shrink();
        return FloatingActionButton(
          tooltip: 'Registrar tratamiento',
          onPressed: () => _abrirFormulario(),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      }),
      body: SafeArea(
        child: Column(
          children: [
            _buildFiltros(context),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLista(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    const filtros = <String, String>{
      'todos': 'Todos',
      'vacunas': 'Vacunas',
      'tratamientos': 'Tratamientos',
      'proximas': 'Próximas',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filtros.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(e.value),
                selected: _filtro == e.key,
                onSelected: (_) => setState(() => _filtro = e.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLista(BuildContext context) {
    final items = _filtrados;
    if (items.isEmpty) {
      return _emptyState(context);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildCard(context, items[i]),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'No hay tratamientos registrados',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Tratamiento t) {
    final theme = Theme.of(context);
    final esVet = _auth.isVeterinario;
    final destino = t.nombreConejo ?? t.jaulaGrupo ?? 'Sin ID';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: ListTile(
        onTap: esVet ? () => _abrirFormulario(existing: t) : null,
        leading: Icon(_iconoTipo(t.tipo), color: theme.colorScheme.primary),
        title: Text('$destino - ${t.producto}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Aplicado: ${_fmtFecha(t.fechaAplicacion)}'),
            if (t.fechaProxima != null) ...[
              const SizedBox(height: 6),
              _ChipProxima(fecha: _fmtFecha(t.fechaProxima!)),
            ],
          ],
        ),
        isThreeLine: t.fechaProxima != null,
        trailing: esVet
            ? Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.outline)
            : null,
      ),
    );
  }
}

// ==================== CHIP "PRÓXIMA" ====================
class _ChipProxima extends StatelessWidget {
  final String fecha;

  const _ChipProxima({required this.fecha});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gris = theme.dividerTheme.color ?? theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: gris,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Próxima: $fecha',
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}

// ==================== DIÁLOGO AGREGAR/EDITAR ====================
class _TratamientoFormDialog extends StatefulWidget {
  final SaludService service;
  final Tratamiento? existing;

  const _TratamientoFormDialog({required this.service, this.existing});

  @override
  State<_TratamientoFormDialog> createState() =>
      _TratamientoFormDialogState();
}

class _TratamientoFormDialogState extends State<_TratamientoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final RabbitController _rabbits = Get.isRegistered<RabbitController>()
      ? Get.find<RabbitController>()
      : Get.put(RabbitController());

  final _productoCtrl = TextEditingController();
  final _dosisCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  late int? _conejoId;
  late String _tipo;
  String? _via;
  late DateTime _fechaAplicacion;
  DateTime? _fechaProxima;
  bool _saving = false;

  static const _tipos = <String, String>{
    'vacuna': 'Vacuna',
    'tratamiento': 'Tratamiento',
    'desparasitacion': 'Desparasitación',
  };
  static const List<String> _vias = ['SC', 'IM', 'Oral', 'Tópica'];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _conejoId = t?.conejoId;
    _tipo = t?.tipo ?? 'vacuna';
    _via = t?.via;
    _fechaAplicacion = t?.fechaAplicacion ?? DateTime.now();
    _fechaProxima = t?.fechaProxima;
    _productoCtrl.text = t?.producto ?? '';
    _dosisCtrl.text = t?.dosis ?? '';
    _notasCtrl.text = t?.notas ?? '';
  }

  @override
  void dispose() {
    _productoCtrl.dispose();
    _dosisCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  String _fmtFecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _pickAplicacion() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaAplicacion.isAfter(DateTime.now())
          ? DateTime.now()
          : _fechaAplicacion,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaAplicacion = picked);
  }

  Future<void> _pickProxima() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaProxima ?? hoy,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 2),
    );
    if (picked != null) setState(() => _fechaProxima = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _conejoId == null) return;
    setState(() => _saving = true);

    final navigator = Navigator.of(context);
    final t = Tratamiento(
      id: widget.existing?.id ?? '',
      conejoId: _conejoId,
      jaulaGrupo: widget.existing?.jaulaGrupo,
      tipo: _tipo,
      producto: _productoCtrl.text.trim(),
      dosis: _dosisCtrl.text.trim().isEmpty ? null : _dosisCtrl.text.trim(),
      via: _via,
      fechaAplicacion: _fechaAplicacion,
      fechaProxima: _fechaProxima,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );

    final ok = _isEditing
        ? await widget.service.update(t)
        : await widget.service.create(t);

    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      AppSnackbar.error(context, 'No se pudo guardar el tratamiento');
      return;
    }

    AppSnackbar.success(
      context,
      _isEditing ? 'Tratamiento actualizado' : 'Tratamiento registrado',
    );
    navigator.pop(true);
  }

  Future<void> _eliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tratamiento'),
        content: const Text(
          '¿Eliminar este tratamiento? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final ok = await widget.service.delete(widget.existing!.id);
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      AppSnackbar.error(context, 'No se pudo eliminar el tratamiento');
      return;
    }
    AppSnackbar.success(context, 'Tratamiento eliminado');
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final rabbits = _rabbits.rabbits;
    final ids = rabbits.map((r) => int.tryParse(r.id)).toSet();
    final dialogWidth =
        MediaQuery.of(context).size.width < 500 ? double.infinity : 440.0;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isEditing
                ? Icons.edit_outlined
                : Icons.health_and_safety_outlined,
            color: AppTheme.accent,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _isEditing ? 'Editar tratamiento' : 'Nuevo tratamiento',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: ids.contains(_conejoId) ? _conejoId : null,
                  decoration: InputDecoration(
                    labelText: 'Conejo',
                    hintText: 'Selecciona un conejo',
                    prefixIcon: const Icon(Icons.pets_outlined),
                    helperText: rabbits.isEmpty
                        ? 'No hay conejos registrados'
                        : null,
                  ),
                  items: rabbits
                      .map((r) => DropdownMenuItem<int>(
                            value: int.tryParse(r.id),
                            child: Text(r.displayId),
                          ))
                      .toList(),
                  onChanged: rabbits.isEmpty
                      ? null
                      : (value) => setState(() => _conejoId = value),
                  validator: (value) =>
                      value == null ? 'Selecciona un conejo' : null,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _tipos.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _tipo = value);
                  },
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _productoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Producto',
                    hintText: 'Ej: Ivermectina',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el producto'
                      : null,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _dosisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosis',
                    hintText: 'Ej: 0.5 ml o 1 cc',
                    prefixIcon: Icon(Icons.straighten_rounded),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                DropdownButtonFormField<String>(
                  initialValue: _via,
                  decoration: const InputDecoration(
                    labelText: 'Vía de aplicación',
                    prefixIcon: Icon(Icons.vaccines_outlined),
                  ),
                  items: _vias
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (value) => setState(() => _via = value),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildDateTile(
                  label: 'Fecha de aplicación',
                  value: _fmtFecha(_fechaAplicacion),
                  icon: Icons.event_available_rounded,
                  onTap: _saving ? null : _pickAplicacion,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildDateTile(
                  label: 'Próxima dosis (opcional)',
                  value:
                      _fechaProxima == null ? 'Sin programar' : _fmtFecha(_fechaProxima!),
                  icon: Icons.event_repeat_rounded,
                  onTap: _saving ? null : _pickProxima,
                  onClear: _fechaProxima == null
                      ? null
                      : () => setState(() => _fechaProxima = null),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _notasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    hintText: 'Observaciones opcionales',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton.icon(
            onPressed: _saving ? null : _eliminar,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.danger, size: 20),
            label: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }

  Widget _buildDateTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback? onTap,
    VoidCallback? onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(icon, size: 20),
        title: Text(label, style: const TextStyle(fontSize: 12)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        trailing: onClear != null
            ? IconButton(
                tooltip: 'Quitar',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
