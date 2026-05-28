import 'package:flutter/material.dart';
import '../../models/mating.dart';
import '../../models/birth.dart';
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
  List<Birth> births = [];

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

    births = [
      Birth(
        id: "N-001",
        matingId: "M-001",
        motherId: "C-045",
        birthDate: DateTime.now().subtract(const Duration(days: 5)),
        litterSize: 9,
        averageWeight: 45.5,
        liveKits: 8,
        deadKits: 1,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgLight,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
              child: Row(
                children: [
                  Text(
                    'Reproducción',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: const TabBar(
                      isScrollable: true,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.textSecondary,
                      tabs: [
                        Tab(
                          icon: Icon(Icons.favorite_border_rounded, size: 20),
                          text: "Montas",
                        ),
                        Tab(
                          icon: Icon(Icons.child_care_rounded, size: 20),
                          text: "Nacimientos",
                        ),
                        Tab(
                          icon: Icon(Icons.pets_rounded, size: 20),
                          text: "Crías",
                        ),
                      ],
                    ),
                  ),
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: births.length,
      itemBuilder: (context, index) {
        final birth = births[index];
        return _BirthCard(birth: birth);
      },
    );
  }

  Widget _buildCriasTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_rounded, size: 64, color: AppTheme.textTertiary),
          SizedBox(height: 16),
          Text(
            "Seguimiento de Crías",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            "Próximamente",
            style: TextStyle(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
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

  const _BirthCard({required this.birth});

  @override
  Widget build(BuildContext context) {
    final survivalRate = ((birth.liveKits / birth.litterSize) * 100).round();

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
                    color: AppTheme.accent.withOpacity(0.1),
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

                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppTheme.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        color: color.withOpacity(0.1),
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