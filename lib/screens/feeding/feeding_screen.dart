import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../controllers/feeding_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/dialog_animations.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_loading.dart';
import '../../models/alimentacion_jaula.dart';

class FeedingScreen extends StatefulWidget {
  const FeedingScreen({super.key});

  @override
  State<FeedingScreen> createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> {
  final FeedingController controller = Get.put(FeedingController());
  final AuthController authController = Get.find<AuthController>();
  Timer? _clockTimer;
  bool _historialExpandido = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      floatingActionButton: context.isMobile && !authController.isVeterinario
          ? FloatingActionButton.extended(
              onPressed: controller.jaulasDelUsuario.isEmpty
                  ? null
                  : () => _showFeedingForm(),
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar'),
            )
          : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          context.adaptivePadding,
        ).copyWith(bottom: context.isMobile ? 96 : context.adaptivePadding),
        child: Obx(() {
          if (controller.isLoading.value &&
              controller.feedings.isEmpty &&
              controller.jaulasDelUsuario.isEmpty) {
            return const AppLoadingList(shrinkWrap: true, itemCount: 3);
          }

          final pendientes = controller.jaulasPendientesHoy;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: context.isMobile ? 16 : 24),
              if (pendientes.isNotEmpty) ...[
                _buildPendingBanner(pendientes.length),
                SizedBox(height: context.isMobile ? 16 : 24),
              ],
              _buildDailyProgressCard(context),
              SizedBox(height: context.adaptivePadding),
              Text(
                'JAULAS DE HOY',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: context.isMobile ? 12 : 16),
              if (controller.jaulasDelUsuario.isEmpty)
                _buildNoCagesMessage()
              else
                _buildTodayCages(),
              SizedBox(height: context.adaptivePadding),
              Text(
                'HISTORIAL RECIENTE',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: context.isMobile ? 12 : 16),
              _buildHistoryList(),
              SizedBox(height: context.adaptivePadding),
              if (!context.isMobile && !authController.isVeterinario)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton.icon(
                    onPressed: controller.jaulasDelUsuario.isEmpty
                        ? null
                        : () => _showFeedingForm(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('REGISTRAR ALIMENTACIÓN'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    return Text(
      '${now.day} de ${_getMonthName(now.month)} · Cunicultura CBA',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPendingBanner(int count) => Container(
    padding: EdgeInsets.all(context.isMobile ? 12 : 16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFCC80)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Faltan $count ${count == 1 ? 'jaula' : 'jaulas'} por registrar',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFFE65100),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildDailyProgressCard(BuildContext context) {
    final percent = controller.porcentajeHoy.round().clamp(0, 100);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progreso del Día',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _PercentageBadge(percent: percent),
            ],
          ),
          SizedBox(height: context.isMobile ? 12 : 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 10,
              backgroundColor: AppTheme.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
          ),
          SizedBox(height: context.isMobile ? 12 : 16),
          Text(
            '${controller.jaulasRegistradasHoy} de '
            '${controller.totalJaulas} jaulas registradas',
          ),
          const SizedBox(height: 8),
          Text(
            'Total hoy: ${controller.kgRegistradosHoy.toStringAsFixed(1)} kg',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms);
  }

  Widget _buildNoCagesMessage() => AppCard(
    child: Text(
      'Asigna N° de jaula a tus conejos para usar este módulo',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppTheme.textSecondary),
    ),
  );

  Widget _buildTodayCages() {
    final registros = controller.registrosDeHoy;
    return Column(
      children: controller.jaulasDelUsuario.asMap().entries.map((entry) {
        final jaula = entry.value;
        final coincidencias = registros
            .where((item) => item.jaula == jaula)
            .toList();
        final registro = coincidencias.isEmpty ? null : coincidencias.first;
        return AnimatedListItem(
          index: entry.key,
          child: _CageFeedingTile(
            jaula: jaula,
            registro: registro,
            onTap: authController.isVeterinario
                ? null
                : () => _showFeedingForm(jaula: jaula, existing: registro),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryList() {
    final history = controller.feedings;
    if (history.isEmpty) {
      return Text(
        'Aún no hay registros de alimentación',
        style: TextStyle(color: AppTheme.textSecondary),
      );
    }

    final mostrarTodos = _historialExpandido || history.length <= 4;
    final visibles = mostrarTodos ? history.toList() : history.take(4).toList();

    return Column(
      children: [
        ...visibles.asMap().entries.map(
          (entry) => AnimatedListItem(
            index: entry.key,
            child: _HistoryCard(
              item: entry.value,
              canEdit: !authController.isVeterinario,
              onDelete: () => _confirmarEliminarRegistro(entry.value),
            ),
          ),
        ),
        if (history.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _historialExpandido = !_historialExpandido),
                icon: Icon(
                  _historialExpandido
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(
                  _historialExpandido
                      ? 'Ver menos'
                      : 'Ver ${history.length - 4} más',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmarEliminarRegistro(AlimentacionJaula item) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Eliminar el registro de ${item.jaula} del '
          '${item.fecha.day}/${item.fecha.month}/${item.fecha.year}? '
          'Esta acción no se puede deshacer.',
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

    final ok = await controller.deleteFeeding(item.id!);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'Registro eliminado');
    } else {
      AppSnackbar.error(context, 'Error al eliminar');
    }
  }

  Future<void> _showFeedingForm({
    String? jaula,
    AlimentacionJaula? existing,
  }) async {
    await showScaleDialog<void>(
      context: context,
      builder: (_) => _FeedingFormDialog(
        controller: controller,
        initialJaula: jaula,
        existing: existing,
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return months[month - 1];
  }
}

class _CageFeedingTile extends StatelessWidget {
  final String jaula;
  final AlimentacionJaula? registro;
  final VoidCallback? onTap;

  const _CageFeedingTile({
    required this.jaula,
    required this.registro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final registered = registro != null;
    final color = registered ? AppTheme.success : AppTheme.warning;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        leading: Icon(
          registered ? Icons.check_circle : Icons.circle_outlined,
          color: color,
        ),
        title: Text('Jaula $jaula'),
        subtitle: registered
            ? Text(
                '${registro!.cantidadKg} kg'
                '${registro!.tipoComida == null ? '' : ' · ${registro!.tipoComida}'}',
              )
            : const Text('Pendiente de registro'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _PercentageBadge extends StatelessWidget {
  final int percent;

  const _PercentageBadge({required this.percent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.success.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      '$percent% Completado',
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppTheme.success,
      ),
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  final AlimentacionJaula item;
  final VoidCallback onDelete;
  final bool canEdit;

  const _HistoryCard({
    required this.item,
    required this.onDelete,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final completed = item.estado.toLowerCase() == 'completado';
    final color = completed ? AppTheme.success : AppTheme.warning;
    final dateLabel =
        '${item.fecha.day} de ${_monthName(item.fecha.month)} ${item.fecha.year}';
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(Icons.restaurant_rounded, color: color),
        title: Text('Jaula ${item.jaula} · $dateLabel'),
        subtitle: Text(
          '${item.cantidadKg} kg'
          '${item.tipoComida == null ? '' : ' · ${item.tipoComida}'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit) ...[
              IconButton(
                tooltip: 'Eliminar registro',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppTheme.danger,
                ),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
            ],
            _StatusBadge(status: item.estado, color: color),
          ],
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return months[month - 1];
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class _FeedingFormDialog extends StatefulWidget {
  final FeedingController controller;
  final String? initialJaula;
  final AlimentacionJaula? existing;

  const _FeedingFormDialog({
    required this.controller,
    this.initialJaula,
    this.existing,
  });

  @override
  State<_FeedingFormDialog> createState() => _FeedingFormDialogState();
}

class _FeedingFormDialogState extends State<_FeedingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _jaula;
  late DateTime _fecha;
  late String? _tipoComida;
  late String _estado;
  late final TextEditingController _cantidadController;
  late final TextEditingController _notasController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _jaula = item?.jaula ?? widget.initialJaula;
    _fecha = item?.fecha ?? DateTime.now();
    _tipoComida = item?.tipoComida;
    _estado = item?.estado ?? 'Completado';
    _cantidadController = TextEditingController(
      text: item?.cantidadKg.toString() ?? '',
    );
    _notasController = TextEditingController(text: item?.notas ?? '');
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jaulas = widget.controller.jaulasDelUsuario.toList();
    final dialogWidth = MediaQuery.of(context).size.width < 500
        ? double.infinity
        : 420.0;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.restaurant_menu_rounded, color: AppTheme.accent),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              widget.existing == null
                  ? 'Registrar alimentación'
                  : 'Editar alimentación',
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
                DropdownButtonFormField<String>(
                  initialValue: _jaula,
                  decoration: InputDecoration(
                    labelText: 'Jaula',
                    hintText: 'Selecciona una jaula',
                    prefixIcon: const Icon(Icons.meeting_room_rounded),
                    helperText: jaulas.isEmpty
                        ? 'Registra conejos con N° de jaula primero'
                        : null,
                  ),
                  items: jaulas
                      .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                      .toList(),
                  onChanged: jaulas.isEmpty
                      ? null
                      : (value) => setState(() => _jaula = value),
                  validator: (value) =>
                      value == null ? 'Selecciona jaula' : null,
                ),
                SizedBox(height: context.isMobile ? 12 : 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(Icons.calendar_today_rounded, size: 20),
                    title: const Text('Fecha', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _pickDate,
                  ),
                ),
                SizedBox(height: context.isMobile ? 12 : 16),
                TextFormField(
                  controller: _cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    helperText: 'Ej: 5.5',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.scale_rounded),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    return amount == null || amount <= 0
                        ? 'Ingresa una cantidad válida'
                        : null;
                  },
                ),
                SizedBox(height: context.isMobile ? 12 : 16),
                DropdownButtonFormField<String>(
                  initialValue: _tipoComida,
                  decoration: const InputDecoration(
                    labelText: 'Momento del día',
                    hintText: 'Selecciona',
                    prefixIcon: Icon(Icons.restaurant_rounded),
                  ),
                  items: ['Mañana', 'Tarde', 'Noche']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _tipoComida = value),
                ),
                SizedBox(height: context.isMobile ? 12 : 16),
                DropdownButtonFormField<String>(
                  initialValue: _estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    prefixIcon: Icon(Icons.check_circle_outline_rounded),
                  ),
                  items: ['Completado', 'Parcial']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _estado = value);
                  },
                ),
                SizedBox(height: context.isMobile ? 12 : 16),
                TextFormField(
                  controller: _notasController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    helperText: 'Observaciones opcionales',
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

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha.isAfter(today) ? today : _fecha,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _jaula == null) return;
    setState(() => _saving = true);

    final navigator = Navigator.of(context);

    final existing = widget.existing;
    final item = AlimentacionJaula(
      id: existing?.id,
      jaula: _jaula!,
      fecha: _fecha,
      cantidadKg: double.parse(_cantidadController.text),
      tipoComida: _tipoComida,
      estado: _estado,
      notas: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
      userId: existing?.userId,
    );

    final ok = existing?.id == null
        ? await widget.controller.createFeeding(item)
        : await widget.controller.updateFeeding(existing!.id!, item);

    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      AppSnackbar.error(context, 'Error al guardar');
      return;
    }

    AppSnackbar.success(context, 'Registro de alimentación guardado');
    navigator.pop();
  }
}
