import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/mating.dart';
import '../../models/birth.dart';
import '../../models/kit.dart';
import '../../controllers/birth_controller.dart';
import '../../controllers/kit_controller.dart';
import '../../services/notification_service.dart';
import 'birth_registration_screen.dart';
import '../../widgets/cards/breeding_card.dart';
import '../../core/theme/app_theme.dart';

class ReproductionScreen extends StatefulWidget {
  const ReproductionScreen({super.key});

  @override
  State<ReproductionScreen> createState() => _ReproductionScreenState();
}

class _ReproductionScreenState extends State<ReproductionScreen> {
  List<Mating> matings = [];
  final birthController = Get.isRegistered<BirthController>()
      ? Get.find<BirthController>()
      : Get.put(BirthController());
  final kitController = Get.isRegistered<KitController>()
      ? Get.find<KitController>()
      : Get.put(KitController());

  @override
  void initState() {
    super.initState();
    // Datos de ejemplo
    matings = [
      Mating(
        id: "M-001",
        doeId: "C-045",
        buckId: "C-012",
        matingDate: DateTime.now().subtract(const Duration(days: 25)),
        expectedBirthDate: DateTime.now().add(const Duration(days: 7)),
        status: "En gestación",
      ),
    ];

  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      color: AppTheme.bgLight,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 20, isMobile ? 16 : 32, 0),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reproducción', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 12),
                        _buildTabs(context),
                      ],
                    )
                  : Row(
                children: [
                  Text(
                    'Reproducción',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  Expanded(child: _buildTabs(context)),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const TabBar(
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.all(Radius.circular(10))),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: [
          Tab(icon: Icon(Icons.favorite_border_rounded, size: 20), text: 'Montas'),
          Tab(icon: Icon(Icons.child_care_rounded, size: 20), text: 'Nacimientos'),
          Tab(icon: Icon(Icons.pets_rounded, size: 20), text: 'Crías'),
        ],
      ),
    );
  }

  Widget _buildMatingsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: matings.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BreedingCard(mating: matings[index]),
        );
      },
    );
  }

  Widget _buildBirthsTab() {
    return Obx(() {
      if (birthController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (birthController.births.isEmpty) {
        return const Center(child: Text('No hay nacimientos registrados'));
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        itemCount: birthController.births.length,
        itemBuilder: (context, index) => _BirthCard(
          birth: birthController.births[index],
          onDelete: () => _confirmDeleteBirth(birthController.births[index]),
        ),
      );
    });
  }

  Widget _buildCriasTab() {
    return Obx(() {
      if (kitController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return Stack(
        children: [
          if (kitController.kits.isEmpty)
            const Center(child: Text('No hay crías registradas'))
          else
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
              itemCount: kitController.kits.length,
              itemBuilder: (context, index) => _KitCard(
                kit: kitController.kits[index],
                onEdit: () => _showKitForm(kitController.kits[index]),
                onDelete: () => _confirmDeleteKit(kitController.kits[index]),
              ),
            ),
          Positioned(
            right: 24,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () => _showKitForm(),
              backgroundColor: AppTheme.accent,
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      );
    });
  }

  void _confirmDeleteBirth(Birth birth) {
    Get.dialog(AlertDialog(
      title: const Text('Eliminar nacimiento'),
      content: Text('¿Deseas eliminar el nacimiento ${birth.id}?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancelar')),
        TextButton(onPressed: () { Get.back(); birthController.deleteBirth(birth.id); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _confirmDeleteKit(Kit kit) {
    Get.dialog(AlertDialog(
      title: const Text('Eliminar cría'),
      content: Text('¿Deseas eliminar la cría ${kit.id}?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancelar')),
        TextButton(onPressed: () { Get.back(); kitController.deleteKit(kit.id); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  Future<void> _showKitForm([Kit? kit]) async {
    final result = await Get.dialog<Kit>(_KitFormDialog(kit: kit), barrierDismissible: false);
    if (result == null) return;
    if (kit == null) {
      await kitController.createKit(result);
    } else {
      await kitController.updateKit(kit.id, result);
    }
  }

  void _registerNew(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: const BirthRegistrationScreen(),
      ),
    );
  }

  Widget buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _registerNew(context),
      backgroundColor: AppTheme.accent,
      elevation: 4,
      child: const Icon(Icons.add_rounded),
    );
  }

  /// Programa una notificación de alerta de parto
  Future<void> scheduleBirthAlert(Mating mating) async {
    if (mating.expectedBirthDate != null) {
      final daysLeft = mating.expectedBirthDate!.difference(DateTime.now()).inDays;

      if (daysLeft <= 7) {
        await NotificationService().showNotification(
          id: 1001,
          title: "¡Alerta de Parto!",
          body: "La coneja ${mating.doeId} tiene parto estimado en $daysLeft días",
        );
      }
    }
  }
}

class _BirthCard extends StatelessWidget {
  final Birth birth;
  final VoidCallback onDelete;

  const _BirthCard({required this.birth, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final survivalRate = birth.litterSize > 0
        ? ((birth.liveKits / birth.litterSize) * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.child_care_rounded,
                    size: 32,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 24),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Nacimiento ${birth.id}",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          _SurvivalBadge(rate: survivalRate),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Madre: ${birth.motherId}",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${birth.litterSize} crías • Promedio ${birth.averageWeight}g",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KitCard extends StatelessWidget {
  final Kit kit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KitCard({required this.kit, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
            child: const Icon(Icons.pets_rounded, color: AppTheme.accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cría ${kit.id}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Madre: ${kit.motherId} • ${kit.ageDays} días'),
                Text('${kit.currentWeight} kg • ${kit.healthStatus}', style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red)),
        ],
      ),
    );
  }
}

class _KitFormDialog extends StatefulWidget {
  final Kit? kit;

  const _KitFormDialog({this.kit});

  @override
  State<_KitFormDialog> createState() => _KitFormDialogState();
}

class _KitFormDialogState extends State<_KitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _motherController;
  late final TextEditingController _fatherController;
  late final TextEditingController _birthWeightController;
  late final TextEditingController _currentWeightController;
  late final TextEditingController _ageController;
  late String _healthStatus;
  late DateTime _birthDate;

  @override
  void initState() {
    super.initState();
    final kit = widget.kit;
    _idController = TextEditingController(text: kit?.id ?? '');
    _motherController = TextEditingController(text: kit?.motherId ?? '');
    _fatherController = TextEditingController(text: kit?.fatherId ?? '');
    _birthWeightController = TextEditingController(text: kit?.birthWeight.toString() ?? '');
    _currentWeightController = TextEditingController(text: kit?.currentWeight.toString() ?? '');
    _ageController = TextEditingController(text: kit?.ageDays.toString() ?? '');
    _healthStatus = kit?.healthStatus ?? 'Saludable';
    _birthDate = kit?.birthDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _idController.dispose();
    _motherController.dispose();
    _fatherController.dispose();
    _birthWeightController.dispose();
    _currentWeightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Obligatorio' : null;

  String? _positive(String? value, {bool integer = false}) {
    if (_required(value) != null) return 'Obligatorio';
    final number = integer ? int.tryParse(value!) : double.tryParse(value!);
    return number == null || number <= 0 ? 'Debe ser mayor que cero' : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.kit == null ? 'Nueva Cría' : 'Editar Cría'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _idController, enabled: widget.kit == null, decoration: const InputDecoration(labelText: 'ID'), validator: _required),
                TextFormField(controller: _motherController, decoration: const InputDecoration(labelText: 'ID de la madre'), validator: _required),
                TextFormField(controller: _fatherController, decoration: const InputDecoration(labelText: 'ID del padre (opcional)')),
                TextFormField(controller: _birthWeightController, decoration: const InputDecoration(labelText: 'Peso al nacer (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _positive),
                TextFormField(controller: _currentWeightController, decoration: const InputDecoration(labelText: 'Peso actual (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _positive),
                TextFormField(controller: _ageController, decoration: const InputDecoration(labelText: 'Edad (días)'), keyboardType: TextInputType.number, validator: (value) => _positive(value, integer: true)),
                DropdownButtonFormField<String>(value: _healthStatus, decoration: const InputDecoration(labelText: 'Estado sanitario'), items: const [DropdownMenuItem(value: 'Saludable', child: Text('Saludable')), DropdownMenuItem(value: 'En tratamiento', child: Text('En tratamiento')), DropdownMenuItem(value: 'Enfermo', child: Text('Enfermo'))], onChanged: (value) => setState(() => _healthStatus = value!),),
                ListTile(title: const Text('Fecha de nacimiento'), subtitle: Text('${_birthDate.day}/${_birthDate.month}/${_birthDate.year}'), trailing: const Icon(Icons.calendar_today), onTap: _pickDate),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(context: context, initialDate: _birthDate, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (date != null) setState(() => _birthDate = date);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final current = widget.kit;
    Get.back(result: Kit(
      id: _idController.text.trim(),
      motherId: _motherController.text.trim(),
      fatherId: _fatherController.text.trim().isEmpty ? null : _fatherController.text.trim(),
      birthDate: _birthDate,
      birthWeight: double.parse(_birthWeightController.text),
      currentWeight: double.parse(_currentWeightController.text),
      ageDays: int.parse(_ageController.text),
      healthStatus: _healthStatus,
      weaningDate: current?.weaningDate,
    ));
  }
}

class _SurvivalBadge extends StatelessWidget {
  final int rate;

  const _SurvivalBadge({required this.rate});

  @override
  Widget build(BuildContext context) {
    final color = rate >= 90 ? AppTheme.success : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$rate%",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "Supervivencia",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
