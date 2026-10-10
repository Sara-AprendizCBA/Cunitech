import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rabbit.dart';
import '../../controllers/rabbit_controller.dart';
import 'rabbit_form_dialog.dart';

// ─────────────────────────────────────────────
// DETALLE DEL CONEJO
// ─────────────────────────────────────────────

class RabbitDetailScreen extends StatelessWidget {
  final Rabbit rabbit;

  const RabbitDetailScreen({super.key, required this.rabbit});

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget _buildPhotoColumn(Rabbit rabbit) {
    final photoUrl = rabbit.photoUrl;
    final photo = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: AspectRatio(
          aspectRatio: 1,
          child: photoUrl != null && photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoPlaceholder(),
                )
              : _photoPlaceholder(),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: photo
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.95, 0.95)),
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(rabbit),
      ],
    );
  }

  Widget _buildSummaryCard(Rabbit rabbit) {
    final rows = [
      _infoRow('Chapeta', rabbit.displayId),
      _infoRow('Raza', _displayValue(rabbit.breed)),
      _infoRow('Género', rabbit.gender),
      _infoRow('Edad', _age(rabbit.birthDate)),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              rows[index],
              if (index < rows.length - 1)
                const Divider(height: 1, color: AppTheme.borderLight),
            ],
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return const ColoredBox(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Icon(Icons.pets_rounded, size: 80, color: AppTheme.textTertiary),
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context, Rabbit rabbit) {
    final sections = <Widget>[
      _buildIdentitySection(rabbit),
      _buildBirthSection(rabbit),
      if (rabbit.gender == 'Hembra') _buildReproductiveSection(rabbit),
      _buildHealthSection(rabbit),
    ];

    return Column(
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          sections[index]
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: 100 * index),
              )
              .slideY(begin: 0.05, end: 0),
          if (index < sections.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildIdentitySection(Rabbit rabbit) {
    final name = rabbit.name?.trim();
    return _sectionCard(
      icon: Icons.pets_rounded,
      title: 'IDENTIDAD',
      rows: [
        if (name != null && name.isNotEmpty) _infoRow('Nombre', name),
        _infoRow('Placa Inventario', _displayValue(rabbit.placaInventario)),
        _infoRow('Jaula', _displayValue(rabbit.cageNumber)),
      ],
    );
  }

  Widget _buildBirthSection(Rabbit rabbit) {
    return _sectionCard(
      icon: Icons.cake_rounded,
      title: 'NACIMIENTO Y PESO',
      rows: [
        _infoRow('Fecha Nacimiento', _fmt(rabbit.birthDate)),
        _infoRow(
          'Peso',
          rabbit.weightKg > 0 ? '${_formatWeight(rabbit.weightKg)} kg' : '—',
        ),
        _infoRow('Fecha Ingreso', _fmt(rabbit.registrationDate)),
      ],
    );
  }

  Widget _buildReproductiveSection(Rabbit rabbit) {
    final rows = <Widget>[
      _infoRow(
        'Estado reproductivo',
        '',
        badge: _reproductiveBadge(rabbit.reproductiveStatus),
      ),
      if (rabbit.reproductiveStatus == 'Servida' ||
          rabbit.reproductiveStatus == 'Gestante')
        _infoRow('Fecha de monta', _formatNullableDate(rabbit.matingDate)),
      if (rabbit.reproductiveStatus == 'Gestante')
        _infoRow(
          'Fecha probable parto',
          _formatNullableDate(rabbit.expectedBirthDate),
        ),
      if (rabbit.reproductiveStatus == 'Lactante') ...[
        _infoRow(
          'Fecha parto real',
          _formatNullableDate(rabbit.actualBirthDate),
        ),
        _infoRow('N° crías', rabbit.actualLitterSize?.toString() ?? '—'),
      ],
      if (rabbit.reproductiveStatus == 'Descarte') ...[
        _infoRow('Motivo descarte', _displayValue(rabbit.discardReason)),
        _infoRow('Fecha descarte', _formatNullableDate(rabbit.discardDate)),
      ],
    ];

    return _sectionCard(
      icon: Icons.favorite_rounded,
      title: 'ESTADO REPRODUCTIVO',
      rows: rows,
    );
  }

  Widget _buildHealthSection(Rabbit rabbit) {
    return _sectionCard(
      icon: Icons.health_and_safety_rounded,
      title: 'SALUD',
      rows: [
        _infoRow(
          'Estado general',
          '',
          badge: _healthBadge(rabbit.healthStatus),
        ),
        if (rabbit.fatherId != null) _infoRow('Padre', '#${rabbit.fatherId}'),
        if (rabbit.motherId != null) _infoRow('Madre', '#${rabbit.motherId}'),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> rows,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < rows.length; index++) ...[
              rows[index],
              if (index < rows.length - 1)
                const Divider(height: 1, color: AppTheme.borderLight),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Widget? badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  badge ??
                  Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayValue(String? value) =>
      value == null || value.isEmpty ? '—' : value;

  String _formatNullableDate(DateTime? date) => date == null ? '—' : _fmt(date);

  String _formatWeight(double weight) => weight == weight.roundToDouble()
      ? weight.toStringAsFixed(0)
      : weight.toString();

  String _age(DateTime birthDate) {
    final days = DateTime.now().difference(birthDate).inDays;
    if (days < 30) return '$days días';
    if (days < 365) return '${(days / 30).floor()} meses';
    final years = (days / 365).floor();
    final months = ((days % 365) / 30).floor();
    return months > 0 ? '$years años $months meses' : '$years años';
  }

  Widget _healthBadge(String status) {
    final normalizedStatus = status.toLowerCase();
    final background = normalizedStatus == 'saludable'
        ? const Color(0xFFDCFCE7)
        : normalizedStatus.contains('tratamiento')
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFFEE2E2);
    final foreground = normalizedStatus == 'saludable'
        ? const Color(0xFF166534)
        : normalizedStatus.contains('tratamiento')
        ? const Color(0xFF92400E)
        : const Color(0xFF991B1B);
    return _badge(status, background: background, foreground: foreground);
  }

  Widget _reproductiveBadge(String status) {
    final colors = switch (status) {
      'Servida' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'Gestante' => (const Color(0xFFFFEDD5), const Color(0xFF9A3412)),
      'Lactante' => (const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
      'Descarte' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };
    return _badge(status, background: colors.$1, foreground: colors.$2);
  }

  Widget _badge(
    String value, {
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  AppBar _buildHeader(BuildContext context, Rabbit rabbit) {
    return AppBar(
      title: Text(
        rabbit.displayId,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppTheme.bgLight,
      elevation: 0,
      foregroundColor: AppTheme.textPrimary,
      actions: [
        ElevatedButton.icon(
          onPressed: () => Get.dialog(
            RabbitFormDialog(rabbit: rabbit),
            barrierDismissible: false,
          ),
          icon: const Icon(Icons.edit),
          label: const Text('Editar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Más acciones',
          onSelected: (action) {
            if (action == 'delete') _confirmDelete(context, rabbit);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppTheme.danger),
                  SizedBox(width: 8),
                  Text('Eliminar conejo'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Rabbit rabbit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar conejo'),
        content: Text('¿Deseas eliminar a ${rabbit.displayId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final controller = Get.find<RabbitController>();
    await controller.deleteRabbit(rabbit.id);
    if (context.mounted &&
        !controller.rabbits.any((item) => item.id == rabbit.id)) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildMobileLayout(BuildContext context, Rabbit rabbit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhotoColumn(rabbit),
        const SizedBox(height: 24),
        _buildInfoColumn(context, rabbit),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Rabbit rabbit, {
    required bool isTablet,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: _buildPhotoColumn(rabbit)),
        SizedBox(width: isTablet ? 24 : 32),
        Expanded(flex: 6, child: _buildInfoColumn(context, rabbit)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rabbitController = Get.find<RabbitController>();

    // Obx: si se edita el conejo, el detalle se actualiza solo
    return Obx(() {
      final r = rabbitController.getRabbitById(rabbit.id) ?? rabbit;
      final width = MediaQuery.of(context).size.width;
      final isMobile = width < 900;
      final isTablet = width < 1200;

      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: _buildHeader(context, r),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: isMobile
              ? _buildMobileLayout(context, r)
              : _buildDesktopLayout(context, r, isTablet: isTablet),
        ),
      );
    });
  }
}
