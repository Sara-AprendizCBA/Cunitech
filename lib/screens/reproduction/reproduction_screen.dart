import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/reproduccion_controller.dart';
import '../../models/reproduccion.dart';
import '../../services/predictor_service.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/responsive.dart';

class ReproductionScreen extends StatefulWidget {
  const ReproductionScreen({super.key});

  @override
  State<ReproductionScreen> createState() => _ReproductionScreenState();
}

class _ReproductionScreenState extends State<ReproductionScreen> {
  final reproController = Get.put(ReproduccionController());
  final authController = Get.find<AuthController>();
  final predictor = PredictorService();
  String _matingFilter = 'Todas';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (tabContext) {
          final tabController = DefaultTabController.of(tabContext);
          return AnimatedBuilder(
            animation: tabController,
            builder: (innerContext, _) => Scaffold(
              backgroundColor: AppTheme.bgLight,
              floatingActionButton: innerContext.isMobile &&
                      tabController.index == 0 &&
                      !authController.isVeterinario
                  ? FloatingActionButton(
                      onPressed: () => _showMatingForm(),
                      tooltip: 'Nueva monta',
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.add_rounded),
                    )
                  : null,
              body: Column(
                children: [
            // Custom Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.adaptivePaddingH,
                isMobile ? 12 : 20,
                context.adaptivePaddingH,
                0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: _buildTabs(context),
              ),
            ),

            SizedBox(height: isMobile ? 16 : 20),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildMatingsTab(),
                  _buildBirthsTab(),
                  _buildCriasTab(),
                ],
              ),
            ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: TabBar(
        isScrollable: context.isMobile,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.all(Radius.circular(10))),
        labelColor: Colors.white,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        tabs: [
          Tab(icon: Icon(Icons.favorite_border_rounded, size: 20), text: 'Montas'),
          Tab(icon: Icon(Icons.child_care_rounded, size: 20), text: 'Nacimientos'),
          Tab(icon: Icon(Icons.pets_rounded, size: 20), text: 'Crías'),
        ],
      ),
    );
  }

  Widget _buildMatingsTab() {
    return Obx(() {
      if (reproController.isLoading.value &&
          reproController.reproducciones.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final List<Reproduccion> filtered;
      switch (_matingFilter) {
        case 'Pendientes':
          filtered = reproController.servidas;
        case 'Gestantes':
          filtered = reproController.gestantes;
        case 'Fallidas':
          filtered = reproController.fallidas;
        default:
          filtered = reproController.reproducciones.toList();
      }
      final isMobile = context.isMobile;
      final theme = Theme.of(context);

      return ListView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 80 : 24,
          8,
          isMobile ? 16 : 24,
          isMobile ? 16 : 24,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MatingStatCard(
                      label: 'Servidas',
                      count: reproController.servidas.length,
                      color: const Color(0xFFFEF3C7),
                      foreground: const Color(0xFF92400E),
                    ),
                    _MatingStatCard(
                      label: 'Gestantes',
                      count: reproController.gestantes.length,
                      color: const Color(0xFFDCFCE7),
                      foreground: const Color(0xFF166534),
                    ),
                    _MatingStatCard(
                      label: 'Fallidas',
                      count: reproController.fallidas.length,
                      color: const Color(0xFFFEE2E2),
                      foreground: const Color(0xFF991B1B),
                    ),
                    if (reproController.proximasPalpaciones.isNotEmpty)
                      _MatingStatCard(
                        label: 'Palpaciones',
                        count: reproController.proximasPalpaciones.length,
                        color: const Color(0xFFFFEDD5),
                        foreground: const Color(0xFF9A3412),
                      ),
                  ],
                ),
              ),
              if (!context.isMobile && !authController.isVeterinario) ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _showMatingForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar monta'),
                ),
              ],
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Wrap(
            spacing: 8,
            children: ['Todas', 'Pendientes', 'Gestantes', 'Fallidas']
                .map(
                  (filter) => ChoiceChip(
                    label: Text(filter),
                    selected: _matingFilter == filter,
                    selectedColor: AppTheme.accent,
                    labelStyle: TextStyle(
                      color: _matingFilter == filter
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (_) => setState(() => _matingFilter = filter),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          if (filtered.isEmpty)
            _EmptyMatingsState(
              hasAnyMatings: reproController.reproducciones.isNotEmpty,
            )
          else
            ...filtered.map(_buildMatingCard),
        ],
      );
    });
  }

  Widget _buildMatingCard(Reproduccion r) {
    final doe = _rabbitLabel(reproController.conejas, r.idConeja);
    final buck = r.idConejopadre == null
        ? 'Sin registrar macho'
        : _rabbitLabel(reproController.machos, r.idConejopadre!);
    final days = r.diasDesdeMonta ?? 0;
    final (phaseTitle, phaseSubtitle) = _faseActualInfo(r);
    final partoInminente = r.estado == 'Gestante' && _dentroDelRangoDeParto(r);
    final theme = Theme.of(context);


    late IconData headerIcon;
    late Color headerIconColor;
    late Color badgeColor;
    late Color badgeForeground;
    late String badgeText;
    switch (r.estado) {
      case 'Gestante':
        headerIcon = Icons.pregnant_woman_rounded;
        headerIconColor = const Color(0xFF166534);
        badgeColor = const Color(0xFFDCFCE7);
        badgeForeground = const Color(0xFF166534);
        final due = r.fechaProbableParto;
        final daysLeft = due == null ? null : due.difference(DateTime.now()).inDays;
        badgeText = daysLeft == null
            ? 'Gestante'
            : 'Gestante · Parto en $daysLeft días';
        break;
      case 'Fallida':
        headerIcon = Icons.cancel_rounded;
        headerIconColor = const Color(0xFF991B1B);
        badgeColor = const Color(0xFFFEE2E2);
        badgeForeground = const Color(0xFF991B1B);
        badgeText = 'Fallida';
        break;
      case 'Lactante':
        headerIcon = Icons.child_care_rounded;
        headerIconColor = const Color(0xFF1E40AF);
        badgeColor = const Color(0xFFDBEAFE);
        badgeForeground = const Color(0xFF1E40AF);
        badgeText = 'Lactante';
        break;
      default:
        headerIcon = Icons.hourglass_top_rounded;
        headerIconColor = const Color(0xFFEA580C);
        badgeColor = const Color(0xFFFEF3C7);
        badgeForeground = const Color(0xFF92400E);
        badgeText = r.tocaPalpacion ? 'Toca palpación' : 'En espera (día $days)';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: context.isMobile ? 12 : 16),
      padding: EdgeInsets.all(context.isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: partoInminente
              ? const Color(0xFFDC2626)
              : theme.colorScheme.outlineVariant,
          width: partoInminente ? 2 : 1,
        ),
        boxShadow: partoInminente
            ? [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: headerIconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Monta',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _MatingStatusBadge(
                text: badgeText,
                color: badgeColor,
                foreground: badgeForeground,
              ),
            ],
          ),
          SizedBox(height: context.isMobile ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  doe,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '×',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  buck,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '📅 ${_formatMatingDate(r.fechaMonta)} · Hace $days días',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: context.isMobile ? 12 : 16),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          SizedBox(height: context.isMobile ? 12 : 16),
          _MatingTimeline(r: r),
          if (phaseTitle.isNotEmpty) ...[
            SizedBox(height: context.isMobile ? 12 : 16),
            Divider(color: theme.colorScheme.outlineVariant, height: 1),
            SizedBox(height: context.isMobile ? 12 : 16),
            Text(
              '📍 Fase actual: $phaseTitle',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '⏰ $phaseSubtitle',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
          if (r.estado == 'Servida' && r.tocaPalpacion) ...[
            SizedBox(height: context.isMobile ? 12 : 16),
            Divider(color: theme.colorScheme.outlineVariant, height: 1),
          ],
          if (r.estado == 'Gestante' || r.estado == 'Servida') ...[
            SizedBox(height: context.isMobile ? 12 : 16),
            _SmartPredictorLine(reproduccion: r, predictor: predictor),
          ],
          SizedBox(height: context.isMobile ? 12 : 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!authController.isVeterinario) ...[
                OutlinedButton.icon(
                  onPressed: () => _showMatingForm(existing: r),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmDeleteMating(r),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: BorderSide(
                      color: AppTheme.danger.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
              if (r.estado == 'Servida' && r.tocaPalpacion) ...[
                if (!authController.isVeterinario) ...[
                  FilledButton(
                    onPressed: () => _confirmPregnancy(r),
                    child: const Text('Confirmar preñez'),
                  ),
                  OutlinedButton(
                    onPressed: () => _registerFailure(r),
                    child: const Text('Registrar falla'),
                  ),
                ] else
                  OutlinedButton(
                    onPressed: () => _showMatingDetails(r),
                    child: const Text('Ver detalles'),
                  ),
              ] else if (r.estado == 'Servida') ...[
                OutlinedButton(
                  onPressed: () => _showMatingDetails(r),
                  child: const Text('Ver detalles'),
                ),
              ] else if (r.estado == 'Gestante') ...[
                if (authController.isAdmin || authController.isAyudante)
                  FilledButton(
                    onPressed: () => _showBirthForm(r),
                    child: const Text('Registrar parto'),
                  ),
              ] else if (r.estado == 'Fallida') ...[
                if (!authController.isVeterinario)
                  OutlinedButton.icon(
                    onPressed: () => _showMatingForm(
                      initialDoeId: r.idConeja,
                      initialBuckId: r.idConejopadre,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  (String, String) _faseActualInfo(Reproduccion r) {
    final hoy = DateTime.now();
    final dias = r.diasDesdeMonta ?? 0;
    final palpacion = r.fechaMonta.add(const Duration(days: 12));
    final parto =
        r.fechaProbableParto ?? r.fechaMonta.add(const Duration(days: 31));

    switch (r.estado) {
      case 'Servida':
        if (r.tocaPalpacion) {
          return (
            'Ventana de palpación',
            'Hoy es el día $dias. Confirma si está preñada.',
          );
        }
        final faltan = palpacion.difference(hoy).inDays;
        if (faltan < 0) {
          return (
            '⚠️ Palpación vencida',
            'La palpación ya venció hace ${faltan.abs()} días. '
                'Confirma el resultado o registra la falla.',
          );
        }
        return (
          'Espera post-monta',
          'La palpación se hace en $faltan días (día 12).',
        );
      case 'Gestante':
        final faltan = parto.difference(hoy).inDays;
        return ('Gestación', 'Parto probable en $faltan días.');
      case 'Fallida':
        return ('Monta fallida', 'Puedes reintentar con una nueva monta.');
      case 'Lactante':
        final destete = (r.fechaParto ?? hoy).add(const Duration(days: 30));
        final faltan = destete.difference(hoy).inDays;
        return ('Lactancia', 'Destete estimado en $faltan días.');
      default:
        return ('', '');
    }
  }

  bool _dentroDelRangoDeParto(Reproduccion r) {
    final due =
        r.fechaProbableParto ?? r.fechaMonta.add(const Duration(days: 31));
    final hoy = DateTime.now();
    final d = DateTime(hoy.year, hoy.month, hoy.day);
    final inicio = DateTime(due.year, due.month, due.day).subtract(
      const Duration(days: 1),
    );
    final fin = DateTime(due.year, due.month, due.day).add(
      const Duration(days: 1),
    );
    return !d.isBefore(inicio) && !d.isAfter(fin);
  }

  String _rabbitLabel(List<Map<String, dynamic>> rabbits, int id) {
    final matches =
        rabbits.where((rabbit) => rabbit['id_conejo'] == id).toList();
    if (matches.isEmpty) return 'Conejo $id';
    return matches.first['chapeta'] as String? ?? 'Conejo $id';
  }

  String _formatMatingDate(DateTime date) =>
      '${date.day} ${_monthShort(date.month)}';

  Future<void> _showMatingForm({
    int? initialDoeId,
    int? initialBuckId,
    Reproduccion? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _MatingFormDialog(
        controller: reproController,
        initialDoeId: initialDoeId,
        initialBuckId: initialBuckId,
        existing: existing,
      ),
    );
  }

  Future<void> _confirmPregnancy(Reproduccion r) async {
    final doe = _rabbitLabel(reproController.conejas, r.idConeja);
    final dueDate = r.fechaMonta.add(const Duration(days: 31));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar preñez'),
        content: Text(
          '¿Confirmar que $doe está gestante?\n'
          'Fecha probable de parto: ${_formatFullDate(dueDate)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await reproController.confirmarPrenez(r);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'Preñez confirmada');
    } else {
      AppSnackbar.error(context, 'Error al confirmar preñez');
    }
  }

  Future<void> _registerFailure(Reproduccion r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar falla'),
        content: const Text('¿Confirmas que la monta resultó fallida?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar falla'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await reproController.registrarFalla(r);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'Falla registrada');
    } else {
      AppSnackbar.error(context, 'Error al registrar la falla');
    }
  }

  Future<void> _showMatingDetails(Reproduccion r) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detalles de la monta'),
        content: Text(
          'Coneja: ${_rabbitLabel(reproController.conejas, r.idConeja)}\n'
          'Macho: ${r.idConejopadre == null ? 'Sin registrar' : _rabbitLabel(reproController.machos, r.idConejopadre!)}\n'
          'Fecha: ${_formatFullDate(r.fechaMonta)}\n'
          'Días desde la monta: ${r.diasDesdeMonta ?? 0}\n'
          'Notas: ${r.notas?.isNotEmpty == true ? r.notas : 'Sin notas'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBirthForm(Reproduccion r) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _BirthFormDialog(controller: reproController, reproduccion: r),
    );
  }

  Future<void> _confirmDeleteMating(Reproduccion r) async {
    final doe = _rabbitLabel(reproController.conejas, r.idConeja);
    final nacimientos = reproController.nacimientos
        .where((birth) => birth['reproduccion_id'] == r.idReproduccion)
        .toList();
    final nacimientoIds = nacimientos
        .map((birth) => birth['id']?.toString())
        .whereType<String>()
        .toSet();
    final crias = reproController.crias
        .where((kit) => nacimientoIds.contains(kit['birth_id']?.toString()))
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
            const SizedBox(width: 12),
            const Text('Eliminar monta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Eliminar la monta de $doe del '
              '${_formatFullDate(r.fechaMonta)}?',
            ),
            if (nacimientos.isNotEmpty || crias.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'También se eliminarán:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (nacimientos.isNotEmpty)
                Text(
                  '• ${nacimientos.length} registro(s) de nacimiento asociado(s)',
                ),
              if (crias.isNotEmpty)
                Text('• ${crias.length} crías generadas'),
              const SizedBox(height: 8),
              const Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(color: AppTheme.danger, fontSize: 12),
              ),
            ],
          ],
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

    if (confirmed != true || !mounted) return;

    final ok = await reproController.deleteReproduccion(r.idReproduccion!);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'Monta eliminada');
    } else {
      AppSnackbar.error(context, 'Error al eliminar');
    }
  }

  Widget _buildBirthsTab() {
    return Obx(() {
      if (reproController.isLoading.value && reproController.nacimientos.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (reproController.nacimientos.isEmpty) {
        return const Center(child: Text('No hay nacimientos registrados'));
      }
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(
          context.isMobile ? 16 : 24,
          8,
          context.isMobile ? 16 : 24,
          context.isMobile ? 16 : 24,
        ),
        itemCount: reproController.nacimientos.length,
        itemBuilder: (context, index) => _BirthCard(
          birth: reproController.nacimientos[index],
          conejas: reproController.conejas,
        ),
      );
    });
  }

  Widget _buildCriasTab() {
    return Obx(() {
      final crias = reproController.criasVivas;
      if (reproController.isLoading.value && crias.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (crias.isEmpty) {
        return const Center(child: Text('No hay crías vivas registradas'));
      }
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(
          context.isMobile ? 16 : 24,
          8,
          context.isMobile ? 16 : 24,
          context.isMobile ? 16 : 24,
        ),
        itemCount: crias.length,
        itemBuilder: (context, index) => _KitCard(kit: crias[index]),
      );
    });
  }
}

String _formatFullDate(DateTime date) =>
    '${date.day} ${_monthShort(date.month)} ${date.year}';

String _monthShort(int month) => const [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ][month - 1];

class _MatingTimeline extends StatelessWidget {
  final Reproduccion r;

  const _MatingTimeline({required this.r});

  @override
  Widget build(BuildContext context) {
    final monta = r.fechaMonta;
    final palpacion = monta.add(const Duration(days: 12));
    final parto = r.fechaProbableParto ?? monta.add(const Duration(days: 31));
    final destete = parto.add(const Duration(days: 30));
    final hoy = DateTime.now();

    var currentStep = 0;
    if (r.estado == 'Fallida') {
      currentStep = 1;
    } else if (r.estado == 'Gestante') {
      currentStep = 2;
    } else if (r.estado == 'Lactante') {
      currentStep = 3;
    } else if (hoy.isAfter(palpacion)) {
      currentStep = 1;
    }

    final hitos = <(String, DateTime)>[
      ('Monta', monta),
      ('Palpación', palpacion),
      ('Parto', parto),
      ('Destete', destete),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = context.isMobile;
        final apilar = compacto && constraints.maxWidth < 360;

        if (apilar) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < hitos.length; i++) ...[
                _hito(hitos[i].$1, hitos[i].$2, i, currentStep,
                    compacto: true),
                if (i < hitos.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Container(
                      width: 2,
                      height: 12,
                      color: _colorLinea(i, currentStep),
                    ),
                  ),
              ],
            ],
          );
        }

        return Row(
          children: [
            _hito(hitos[0].$1, hitos[0].$2, 0, currentStep,
                compacto: compacto),
            _linea(0, currentStep),
            _hito(hitos[1].$1, hitos[1].$2, 1, currentStep,
                compacto: compacto),
            _linea(1, currentStep),
            _hito(hitos[2].$1, hitos[2].$2, 2, currentStep,
                compacto: compacto),
            _linea(2, currentStep),
            _hito(hitos[3].$1, hitos[3].$2, 3, currentStep,
                compacto: compacto),
          ],
        );
      },
    );
  }

  Widget _hito(
    String label,
    DateTime fecha,
    int index,
    int current, {
    required bool compacto,
  }) {
    final Color color;
    final String icono;
    if (index < current) {
      color = AppTheme.success;
      icono = '✅';
    } else if (index == current) {
      final diasDesdeMonta = r.diasDesdeMonta ?? 0;
      final esPalpacionVencida =
          index == 1 && r.estado == 'Servida' && diasDesdeMonta > 16;
      color = esPalpacionVencida
          ? const Color(0xFF991B1B)
          : AppTheme.warning;
      icono = esPalpacionVencida ? '⚠️' : '⏳';
    } else {
      color = AppTheme.textTertiary;
      icono = '○';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: compacto ? 8 : 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(icono, style: TextStyle(fontSize: compacto ? 12 : 14)),
        const SizedBox(height: 2),
        Text(
          compacto ? '${fecha.day}' : '${fecha.day} ${_monthShort(fecha.month)}',
          style: TextStyle(fontSize: compacto ? 8 : 10, color: color),
        ),
      ],
    );
  }

  Color _colorLinea(int index, int current) {
    final palpacionVencida = r.estado == 'Servida' &&
        (r.diasDesdeMonta ?? 0) > 16;
    if (index < current) return AppTheme.success;
    if (index == 0 && palpacionVencida) return const Color(0xFF991B1B);
    return AppTheme.borderLight;
  }

  Widget _linea(int index, int current) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(height: 2, color: _colorLinea(index, current)),
      ),
    );
  }
}

class _MatingStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color foreground;

  const _MatingStatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 100),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: foreground, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                color: foreground,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _MatingStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color foreground;

  const _MatingStatusBadge({
    required this.text,
    required this.color,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

/// Línea de IA predictiva: muestra la estimación de parto (Gestante) o el
/// rango óptimo de palpación (Servida), con alertas inteligentes.
class _SmartPredictorLine extends StatefulWidget {
  final Reproduccion reproduccion;
  final PredictorService predictor;

  const _SmartPredictorLine({
    required this.reproduccion,
    required this.predictor,
  });

  @override
  State<_SmartPredictorLine> createState() => _SmartPredictorLineState();
}

class _SmartPredictorLineState extends State<_SmartPredictorLine> {
  late final Future<PrediccionFecha> _future;

  @override
  void initState() {
    super.initState();
    _future = _calcular();
  }

  Future<PrediccionFecha> _calcular() {
    final r = widget.reproduccion;
    if (r.estado == 'Gestante') {
      return widget.predictor.estimarParto(
        r.idConeja.toString(),
        fechaMonta: r.fechaMonta,
      );
    }
    return Future.value(widget.predictor.estimarPalpacion(r.fechaMonta));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PrediccionFecha>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            '🤖 Analizando historial...',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          );
        }

        final p = snapshot.data!;
        final esGestante = widget.reproduccion.estado == 'Gestante';
        final enRango = p.esHoy;

        if (esGestante) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '🤖 Parto estimado: '
                      '${PredictorService.formatearCorta(p.fecha)} '
                      '(rango ${p.rangoInicio.day}-${p.rangoFin.day})'
                      '${p.basadoEnHistorial ? ' · según su historial' : ''}',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (enRango) ...[
                const SizedBox(height: 8),
                const _SmartChip(
                  text: '¡Parto inminente!',
                  color: Color(0xFFFEE2E2),
                  foreground: Color(0xFF991B1B),
                  icon: Icons.priority_high_rounded,
                ),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppTheme.accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '🤖 Palpación óptima: '
                    '${PredictorService.formatearCorta(p.rangoInicio)} al '
                    '${PredictorService.formatearCorta(p.rangoFin)}',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (enRango) ...[
              const SizedBox(height: 8),
              const _SmartChip(
                text: '¡Hora de palpar!',
                color: Color(0xFFFEF3C7),
                foreground: Color(0xFF92400E),
                icon: Icons.touch_app_rounded,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SmartChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color foreground;
  final IconData icon;

  const _SmartChip({
    required this.text,
    required this.color,
    required this.foreground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _MatingFormDialog extends StatefulWidget {
  final ReproduccionController controller;
  final int? initialDoeId;
  final int? initialBuckId;
  final Reproduccion? existing;

  const _MatingFormDialog({
    required this.controller,
    this.initialDoeId,
    this.initialBuckId,
    this.existing,
  });

  @override
  State<_MatingFormDialog> createState() => _MatingFormDialogState();
}

class _MatingFormDialogState extends State<_MatingFormDialog> {
  static const int _sinMacho = -1;
  static const List<String> _estados = [
    'Vacía',
    'Servida',
    'Gestante',
    'Fallida',
    'Lactante',
    'Destete',
  ];

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _liveController = TextEditingController();
  final _deadController = TextEditingController(text: '0');
  final _adoptedController = TextEditingController(text: '0');
  final _weightController = TextEditingController();
  int? _doeId;
  int? _buckId;
  late DateTime _fechaMonta;
  DateTime? _fechaPalpacion;
  DateTime? _fechaProbableParto;
  DateTime? _fechaParto;
  DateTime? _fechaDestete;
  late String _estado;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _doeId = existing?.idConeja ?? widget.initialDoeId;
    _buckId = existing?.idConejopadre ?? widget.initialBuckId;
    _fechaMonta = existing?.fechaMonta ?? DateTime.now();
    _fechaPalpacion = existing?.fechaPalpacion ??
        _fechaMonta.add(const Duration(days: 12));
    _fechaProbableParto = existing?.fechaProbableParto ??
        _fechaMonta.add(const Duration(days: 31));
    _fechaParto = existing?.fechaParto;
    _fechaDestete = existing?.fechaDestete;
    _estado = existing?.estado ?? 'Servida';
    _liveController.text = existing?.numVivos.toString() ?? '';
    _deadController.text = (existing?.numMuertos ?? 0).toString();
    _adoptedController.text = (existing?.numAdoptados ?? 0).toString();
    _weightController.text = existing?.pesoPromedioCamada?.toString() ?? '';
    _notesController.text = existing?.notas ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _liveController.dispose();
    _deadController.dispose();
    _adoptedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final partoEstimado = _fechaProbableParto ??
        _fechaMonta.add(const Duration(days: 31));
    final diasParto = partoEstimado.difference(DateTime.now()).inDays;
    final desteteEstimado =
        (_fechaParto ?? partoEstimado).add(const Duration(days: 30));
    final diasDestete = desteteEstimado.difference(DateTime.now()).inDays;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: AppTheme.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.existing == null ? 'Registrar monta' : 'Editar monta',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: mobile ? double.maxFinite : 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('DATOS DE MONTA'),
                DropdownButtonFormField<int>(
                  initialValue: _doeId,
                  decoration: const InputDecoration(
                    labelText: 'Coneja',
                    prefixIcon: Icon(Icons.pets_rounded),
                  ),
                  items: widget.controller.conejas.map((rabbit) {
                    final id = rabbit['id_conejo'] as int;
                    return DropdownMenuItem(
                      value: id,
                      child: Text(rabbit['chapeta'] as String? ?? 'Coneja $id'),
                    );
                  }).toList(),
                  onChanged: widget.existing != null
                      ? null
                      : (value) => setState(() => _doeId = value),
                  validator: (value) =>
                      value == null ? 'Selecciona una coneja' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _buckId ?? _sinMacho,
                  decoration: const InputDecoration(
                    labelText: 'Macho (opcional)',
                    prefixIcon: Icon(Icons.pets_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: _sinMacho,
                      child: Text('Sin registrar'),
                    ),
                    ...widget.controller.machos.map((rabbit) {
                      final id = rabbit['id_conejo'] as int;
                      return DropdownMenuItem(
                        value: id,
                        child: Text(rabbit['chapeta'] as String? ?? 'Macho $id'),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(
                    () => _buckId = value == _sinMacho ? null : value,
                  ),
                ),
                const SizedBox(height: 16),
                _dateField(
                  'Fecha de monta',
                  _fechaMonta,
                  Icons.calendar_today_rounded,
                  (date) {
                    _fechaMonta = date;
                    _fechaPalpacion = date.add(const Duration(days: 12));
                    _fechaProbableParto = date.add(const Duration(days: 31));
                  },
                ),
                const SizedBox(height: 20),
                _sectionTitle('ESTADO REPRODUCTIVO'),
                DropdownButtonFormField<String>(
                  initialValue: _estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    prefixIcon: Icon(Icons.sync_rounded),
                  ),
                  items: _estados
                      .map((estado) => DropdownMenuItem(
                            value: estado,
                            child: Text(estado),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _changeEstado(value));
                  },
                ),
                if (_estado == 'Gestante' ||
                    _estado == 'Lactante' ||
                    _estado == 'Destete') ...[
                  const SizedBox(height: 20),
                  _sectionTitle('SEGUIMIENTO'),
                  _dateField(
                    'Fecha de palpación',
                    _fechaPalpacion,
                    Icons.touch_app_rounded,
                    (date) => _fechaPalpacion = date,
                  ),
                  const SizedBox(height: 16),
                  _dateField(
                    'Fecha probable de parto',
                    _fechaProbableParto,
                    Icons.event_rounded,
                    (date) => _fechaProbableParto = date,
                    allowFuture: true,
                  ),
                ],
                if (_estado == 'Fallida') ...[
                  const SizedBox(height: 16),
                  _dateField(
                    'Fecha de palpación',
                    _fechaPalpacion,
                    Icons.touch_app_rounded,
                    (date) => _fechaPalpacion = date,
                  ),
                ],
                if (_estado == 'Lactante' || _estado == 'Destete') ...[
                  const SizedBox(height: 20),
                  _sectionTitle('DATOS DEL PARTO'),
                  _dateField(
                    'Fecha de parto real',
                    _fechaParto,
                    Icons.child_care_rounded,
                    (date) => _fechaParto = date,
                  ),
                  const SizedBox(height: 16),
                  _numberField(
                    _liveController,
                    'N° vivos',
                    Icons.favorite_rounded,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _numberField(
                    _deadController,
                    'N° muertos',
                    Icons.close_rounded,
                  ),
                  const SizedBox(height: 16),
                  _numberField(
                    _adoptedController,
                    'N° adoptados',
                    Icons.swap_horiz_rounded,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Peso promedio de camada',
                      suffixText: 'g',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
                if (_estado == 'Destete') ...[
                  const SizedBox(height: 16),
                  _dateField(
                    'Fecha de destete',
                    _fechaDestete,
                    Icons.event_available_rounded,
                    (date) => _fechaDestete = date,
                    allowFuture: true,
                  ),
                ],
                const SizedBox(height: 20),
                _sectionTitle('NOTAS'),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _sectionTitle('RESUMEN'),
                Text(
                  'Fecha probable de parto: ${_formatFullDate(partoEstimado)} '
                  '(monta + 31 días)',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                if (_estado == 'Gestante') ...[
                  const SizedBox(height: 4),
                  Text('Parto en $diasParto días'),
                ],
                if (_estado == 'Lactante') ...[
                  const SizedBox(height: 4),
                  Text('Destete estimado en $diasDestete días'),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.danger),
                  ),
                ],
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

  void _changeEstado(String value) {
    _estado = value;
    if (value == 'Vacía') {
      _fechaPalpacion = null;
      _fechaProbableParto = null;
    } else if (value == 'Servida') {
      _fechaPalpacion = _fechaMonta.add(const Duration(days: 12));
      _fechaProbableParto = _fechaMonta.add(const Duration(days: 31));
    } else if (value == 'Fallida') {
      _fechaPalpacion ??= _fechaMonta.add(const Duration(days: 12));
      _fechaProbableParto = null;
    } else {
      _fechaPalpacion ??= _fechaMonta.add(const Duration(days: 12));
      _fechaProbableParto ??= _fechaMonta.add(const Duration(days: 31));
    }

    if (value != 'Lactante' && value != 'Destete') {
      _fechaParto = null;
      _liveController.clear();
      _deadController.text = '0';
      _adoptedController.text = '0';
      _weightController.clear();
    }
    if (value != 'Destete') _fechaDestete = null;
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: AppTheme.borderLight),
          ],
        ),
      );

  Widget _dateField(
    String label,
    DateTime? value,
    IconData icon,
    ValueChanged<DateTime> onSelected, {
    bool allowFuture = false,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pickDate(value, onSelected, allowFuture: allowFuture),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 12)),
                      Text(
                        value == null
                            ? 'Seleccionar fecha'
                            : _formatFullDate(value),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      );

  Widget _numberField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Campo obligatorio';
          }
          if (value != null && value.trim().isNotEmpty) {
            final number = int.tryParse(value.trim());
            if (number == null || number < 0) return 'Ingresa un número válido';
          }
          return null;
        },
      );

  Future<void> _pickDate(
    DateTime? current,
    ValueChanged<DateTime> onSelected, {
    bool allowFuture = false,
  }) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current == null || (!allowFuture && current.isAfter(today))
          ? today
          : current,
      firstDate: DateTime(2000),
      lastDate: allowFuture ? DateTime(2100) : today,
    );
    if (picked != null && mounted) setState(() => onSelected(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _doeId == null) return;
    final active = widget.existing == null &&
        widget.controller.reproducciones.any(
          (r) =>
              r.idConeja == _doeId &&
              (r.estado == 'Servida' || r.estado == 'Gestante'),
        );
    if (active) {
      setState(() {
        _error = 'Esta coneja ya tiene una monta activa (Servida/Gestante).';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final item = Reproduccion(
      idReproduccion: widget.existing?.idReproduccion,
      idConeja: _doeId!,
      idConejopadre: _buckId,
      fechaMonta: _fechaMonta,
      fechaParto: _fechaParto,
      numeroCrias: (int.tryParse(_liveController.text) ?? 0) +
          (int.tryParse(_adoptedController.text) ?? 0),
      userId: widget.existing?.userId,
      estado: _estado,
      fechaPalpacion: _fechaPalpacion,
      fechaProbableParto: _fechaProbableParto,
      fechaNidal: widget.existing?.fechaNidal,
      fechaDestete: _fechaDestete,
      numVivos: int.tryParse(_liveController.text) ?? 0,
      numMuertos: int.tryParse(_deadController.text) ?? 0,
      numAdoptados: int.tryParse(_adoptedController.text) ?? 0,
      pesoPromedioCamada: double.tryParse(
        _weightController.text.trim().replaceAll(',', '.'),
      ),
      notas: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    final existing = widget.existing;
    final ok = existing == null
        ? await widget.controller.createMonta(item)
        : await widget.controller.updateReproduccion(
            existing.idReproduccion!,
            item,
          );
    if (!mounted) return;
    if (ok) {
      navigator.pop();
    } else {
      setState(() => _saving = false);
      AppSnackbar.error(
        context,
        existing == null
            ? 'Error al registrar la monta'
            : 'Error al actualizar la monta',
      );
    }
  }
}

class _BirthFormDialog extends StatefulWidget {
  final ReproduccionController controller;
  final Reproduccion reproduccion;

  const _BirthFormDialog({
    required this.controller,
    required this.reproduccion,
  });

  @override
  State<_BirthFormDialog> createState() => _BirthFormDialogState();
}

class _BirthFormDialogState extends State<_BirthFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _liveController = TextEditingController();
  final _deadController = TextEditingController(text: '0');
  final _adoptedController = TextEditingController(text: '0');
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  int get _total =>
      (int.tryParse(_liveController.text) ?? 0) +
      (int.tryParse(_adoptedController.text) ?? 0);

  @override
  void dispose() {
    _liveController.dispose();
    _deadController.dispose();
    _adoptedController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Registrar parto'),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width < 600
              ? double.maxFinite
              : 420,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha de parto'),
                    subtitle: Text(_formatFullDate(_date)),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: _pickDate,
                  ),
                  _numberField(_liveController, 'N° vivos', required: true),
                  _numberField(_deadController, 'N° muertos'),
                  _numberField(_adoptedController, 'N° adoptados'),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Peso promedio de camada (g)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notas'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Text('Total de la camada: $_total gazapos'),
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
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Guardando…' : 'Guardar parto'),
          ),
        ],
      );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Campo obligatorio';
          }
          if (value != null && value.isNotEmpty) {
            final number = int.tryParse(value);
            if (number == null || number < 0) return 'Ingresa un número válido';
          }
          return null;
        },
      );

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final ok = await widget.controller.registrarParto(
      widget.reproduccion,
      fechaParto: _date,
      numVivos: int.parse(_liveController.text),
      numMuertos: int.tryParse(_deadController.text) ?? 0,
      numAdoptados: int.tryParse(_adoptedController.text) ?? 0,
      pesoPromedio: double.tryParse(_weightController.text),
      notas: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      navigator.pop();
    } else {
      setState(() => _saving = false);
      AppSnackbar.error(context, 'Error al registrar el parto');
    }
  }
}

class _BirthCard extends StatelessWidget {
  final Map<String, dynamic> birth;
  final List<Map<String, dynamic>> conejas;

  const _BirthCard({required this.birth, required this.conejas});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motherId = (birth['mother_id'] as num?)?.toInt();
    final mother = conejas.where(
      (coneja) => (coneja['id_conejo'] as num?)?.toInt() == motherId,
    );
    final motherLabel = mother.isEmpty
        ? 'ID ${motherId ?? '—'}'
        : (mother.first['chapeta']?.toString() ?? 'ID $motherId');
    final date = DateTime.tryParse(birth['birth_date']?.toString() ?? '');
    final litterSize = (birth['litter_size'] as num?)?.toInt() ?? 0;
    final liveKits = (birth['live_kits'] as num?)?.toInt() ?? 0;
    final deadKits = (birth['dead_kits'] as num?)?.toInt() ?? 0;
    final adoptedKits = (birth['adopted_kits'] as num?)?.toInt() ?? 0;
    final averageWeight = (birth['average_weight'] as num?)?.toDouble();
    final weaningDate = date?.add(const Duration(days: 30));

    return Container(
      margin: EdgeInsets.only(bottom: context.isMobile ? 12 : 16),
      padding: EdgeInsets.all(context.isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.child_care_rounded, color: AppTheme.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Parto de $motherLabel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (date != null) Text(_formatFullDate(date)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Madre: $motherLabel'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: '$litterSize crías', background: const Color(0xFFDBEAFE), foreground: const Color(0xFF1E40AF)),
              _Chip(label: '$liveKits vivos', background: const Color(0xFFDCFCE7), foreground: const Color(0xFF166534)),
              _Chip(label: '$deadKits muertos', background: const Color(0xFFFEE2E2), foreground: const Color(0xFF991B1B)),
              if (adoptedKits > 0)
                _Chip(label: '$adoptedKits adoptados', background: const Color(0xFFEDE9FE), foreground: const Color(0xFF5B21B6)),
            ],
          ),
          if (averageWeight != null || weaningDate != null) ...[
            const SizedBox(height: 12),
            Text(
              [
                if (averageWeight != null) 'Peso promedio: ${averageWeight.toStringAsFixed(1)} g',
                if (weaningDate != null) 'Destete estimado: ${_formatFullDate(weaningDate)}',
              ].join(' · '),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _KitCard extends StatelessWidget {
  final Map<String, dynamic> kit;

  const _KitCard({required this.kit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birthDate = DateTime.tryParse(kit['birth_date']?.toString() ?? '');
    final weaningDate = DateTime.tryParse(kit['weaning_date']?.toString() ?? '');
    final weight = (kit['current_weight'] as num?)?.toDouble();
    final ageDays = (kit['age_days'] as num?)?.toInt();
    final birthStatus = kit['estado_nacimiento']?.toString() ?? 'Vivo';
    final healthStatus = kit['health_status']?.toString();
    final isDead = birthStatus.toLowerCase() == 'muerto';
    final isWeaned = weaningDate != null && !weaningDate.isAfter(DateTime.now());
    final statusColor = isDead
        ? const Color(0xFF991B1B)
        : isWeaned
            ? const Color(0xFF1E40AF)
            : const Color(0xFF166534);
    final statusBackground = isDead
        ? const Color(0xFFFEE2E2)
        : isWeaned
            ? const Color(0xFFDBEAFE)
            : const Color(0xFFDCFCE7);
    final statusLabel = isDead ? 'Muerto' : isWeaned ? 'Destetado' : 'Vivo';

    return Container(
      margin: EdgeInsets.only(bottom: context.isMobile ? 12 : 16),
      padding: EdgeInsets.all(context.isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusBackground,
            child: Icon(
              isDead ? Icons.close_rounded : Icons.pets_rounded,
              color: statusColor,
            ),
          ),
          SizedBox(width: context.isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        kit['chapeta']?.toString().isNotEmpty == true
                            ? kit['chapeta'].toString()
                            : 'Cría ${kit['kit_numero'] ?? kit['id'] ?? ''}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _Chip(label: statusLabel, background: statusBackground, foreground: statusColor),
                  ],
                ),
                const SizedBox(height: 6),
                Text([
                  if (birthDate != null) 'Nacimiento: ${_formatFullDate(birthDate)}',
                  if (ageDays != null) '$ageDays días',
                ].join(' · ')),
                if (weight != null || healthStatus != null) ...[
                  const SizedBox(height: 4),
                  Text([
                    if (weight != null) '${weight.toStringAsFixed(2)} kg',
                    if (healthStatus != null && healthStatus.isNotEmpty) healthStatus,
                  ].join(' · '), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
                if (weaningDate != null) ...[
                  const SizedBox(height: 4),
                  Text('Destete: ${_formatFullDate(weaningDate)}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _EmptyMatingsState extends StatelessWidget {
  final bool hasAnyMatings;

  const _EmptyMatingsState({required this.hasAnyMatings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = hasAnyMatings;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              filtered
                  ? Icons.filter_alt_off_rounded
                  : Icons.favorite_border_rounded,
              size: 56,
              color: AppTheme.accent.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            filtered
                ? 'No hay montas en este filtro'
                : 'Aún no hay montas registradas',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!filtered) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Registra la primera monta con el botón +.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
