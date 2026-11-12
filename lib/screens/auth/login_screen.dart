import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/pressable_scale.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const bool _registroPublicoHabilitado = false;
  bool isLogin = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  final _confirmPasswordController = TextEditingController();

  // Focus nodes explicitos: el foco se conserva aunque el formulario se
  // reconstruya (por ejemplo al cambiar el estado de carga o de error).
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;
  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  int _totalConejos = 0;
  double _tasaSupervivencia = 0;
  int _partosMes = 0;
  bool _statsLoaded = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _cargarStats();
  }

  Future<void> _cargarStats() async {
    try {
      final stats = await _supabase.rpc('get_public_stats');

      if (mounted) {
        setState(() {
          _totalConejos = (stats['total_conejo'] as num?)?.toInt() ?? 0;
          _partosMes = (stats['total_partos_mes'] as num?)?.toInt() ?? 0;
          _tasaSupervivencia =
              (stats['tasa_supervivencia'] as num?)?.toDouble() ?? 0;
          _statsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error cargando stats: $e');
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (isDesktop) {
            return Row(
              children: [
                Expanded(child: _buildHero(isDesktop: true)),
                Expanded(
                  child: _buildFormPanel(context, compact: false),
                ),
              ],
            );
          }

          return Column(
            children: [
              SizedBox(
                height: constraints.maxHeight * 0.30,
                child: _buildHero(isDesktop: false),
              ),
              Expanded(
                child: _buildFormPanel(context, compact: true),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHero({required bool isDesktop}) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/Conejos.jpg', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.45, 1],
              colors: isDesktop
                  ? const [
                      Color(0x0F1A1510),
                      Color(0x401A1510),
                      Color(0x991A1510),
                    ]
                  : const [
                      Color(0x1A1A1510),
                      Color(0x591A1510),
                      Color(0xB31A1510),
                    ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: isDesktop
                  ? const [0, 0.45, 0.82]
                  : const [0, 0.45, 0.78],
              colors: isDesktop
                  ? const [
                      Color(0x661A1510),
                      Color(0x261A1510),
                      Colors.transparent,
                    ]
                  : const [
                      Color(0x8C1A1510),
                      Color(0x401A1510),
                      Colors.transparent,
                    ],
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentLight.withValues(alpha: 0.10),
            ),
          ),
        ),
        if (isDesktop)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.72, 1],
                colors: [
                  Colors.transparent,
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 56 : 20),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 520 : 320,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroLogo(compact: !isDesktop),
                    SizedBox(height: isDesktop ? 52 : 18),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: isDesktop ? 46 : 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.08,
                          letterSpacing: -0.8,
                          shadows: const [
                            Shadow(
                              color: Color(0xCC000000),
                              blurRadius: 20,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        children: const [
                          TextSpan(text: 'GESTIÓN PROFESIONAL\nDE '),
                          TextSpan(
                            text: 'CRIADEROS',
                            style: TextStyle(color: AppTheme.accentLight),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 700.ms)
                        .scale(
                          begin: const Offset(0.98, 0.98),
                          end: const Offset(1, 1),
                        ),
                    if (isDesktop) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Controla tu granja con precisión veterinaria, '
                        'eficiencia operativa y tranquilidad profesional.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.6,
                          shadows: const [
                            Shadow(
                              color: Color(0x99000000),
                              blurRadius: 10,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 900.ms, delay: 120.ms),
                      const SizedBox(height: 56),
                      _buildHeroStats(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormPanel(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final horizontalPadding = compact ? 20.0 : 56.0;
    final verticalPadding = compact ? 28.0 : 48.0;

    final errorBackground = isDark
        ? AppTheme.dangerDark.withValues(alpha: 0.18)
        : const Color(0xFFFFF1F1);
    final errorBorder = isDark
        ? AppTheme.dangerDark
        : const Color(0xFFF3B5B5);
    final errorIcon = isDark
        ? const Color(0xFFFCA5A5)
        : const Color(0xFFB54747);
    final errorText = isDark
        ? const Color(0xFFFECACA)
        : const Color(0xFF9B3434);

    final formContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 14,
              color: AppTheme.accent,
            ),
            SizedBox(width: 6),
            Text(
              'ACCESO SEGURO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isLogin ? 'Bienvenido de nuevo' : 'Crear nueva cuenta',
          style: TextStyle(
            fontSize: compact ? 30 : 32,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isLogin
              ? 'Ingresa tus credenciales para continuar.'
              : 'Registra tu granja y empieza ahora.',
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        if (_registroPublicoHabilitado) ...[
          _buildAuthTabs(context),
          const SizedBox(height: 24),
        ],
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              if (!isLogin) ...[
                _buildFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  compact: compact,
                  label: "Nombre de la Granja",
                  hint: "Granja Los Conejos",
                  icon: Icons.business_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre de la granja';
                    }
                    return null;
                  },
                ),
              ],
              _buildFormField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                compact: compact,
                label: "Correo electrónico",
                hint: "Correo electrónico",
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Ingresa tu correo electrónico';
                  }
                  if (!_emailRe.hasMatch(email)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              _buildFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                compact: compact,
                label: "Contraseña",
                hint: "••••••••",
                icon: Icons.lock_rounded,
                obscure: _obscurePassword,
                onToggleObscure: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!_isLoading) {
                    _authenticate();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              if (!isLogin) ...[
                _buildFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  compact: compact,
                  label: "Confirmar Contraseña",
                  hint: "••••••••",
                  icon: Icons.lock_rounded,
                  obscure: _obscureConfirmPassword,
                  onToggleObscure: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 28),
              _buildAuthButton(),
            ],
          ),
        ),
        // El mensaje de error va DESPUES del formulario y dentro de un espacio
        // de altura RESERVADA: si apareciera o desapareciera, el contenido
        // centrado cambiaria de alto, los campos se desplazarian y en Web el
        // clic se perderia antes de que el campo reciba el foco.
        SizedBox(
          height: _errorSlotHeight,
          child: _errorMessage == null
              ? null
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: errorBackground,
                    border: Border.all(color: errorBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: errorIcon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: errorText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),
        _buildContactFooter(context),
      ],
    );

    final animatedForm = formContent
        .animate()
        .fadeIn(duration: 700.ms)
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: compact ? null : theme.scaffoldBackgroundColor,
        gradient: compact
            ? RadialGradient(
                center: const Alignment(1.1, -1.1),
                radius: 1.6,
                colors: [
                  AppTheme.accent.withValues(alpha: isDark ? 0.16 : 0.10),
                  theme.scaffoldBackgroundColor,
                ],
              )
            : null,
        borderRadius: compact
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = constraints.maxHeight - verticalPadding * 2;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minHeight < 0 ? 0 : minHeight,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? 430 : 480,
                  ),
                  child: animatedForm,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showContactAdminDialog(BuildContext context) async {
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: theme.colorScheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.accent,
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Solicitud de Acceso',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 16),
                Text(
                  'El acceso al sistema CUNITECH es gestionado exclusivamente por el Administrador del criadero.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulletItem(context, 'El acceso es creado por el Administrador.'),
                      const SizedBox(height: 10),
                      _buildBulletItem(context, 'Envía un correo con tus datos personales para solicitarlo.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _sendAccessRequestEmail();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Enviar Correo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendAccessRequestEmail() async {
    const String email = 'soporte.cunitech@gmail.com';
    const String subject =
        'Solicitud formal de alta de usuario y registro de datos de contacto - CUNITECH';
    const String body =
        'Estimado(a) Administrador(a) de CUNITECH,\n\nReciba un cordial saludo. Me pongo en contacto con usted con el propósito de solicitar formalmente la creación de una cuenta de acceso al sistema de gestión, con el fin de poder operar dentro de la plataforma del criadero.\n\nCon el objetivo de que el equipo administrativo pueda validar el perfil, coordinar la entrega de credenciales y establecer un canal de comunicación directo, a continuación detallo los datos personales y de contacto requeridos:\n\n- Nombre completo: [Ingresar nombre completo del usuario]\n- Rol o perfil solicitado: [Ingresar el rol correspondiente, ej. Veterinario]\n- Correo electrónico de contacto: [Ingresar correo electrónico]\n- Número de teléfono / Móvil: [Ingresar número de contacto]\n\nAgradezco de antemano su atención a la presente solicitud, así como el tiempo dedicado a la gestión de mis credenciales de acceso. Quedo a su entera disposición en caso de que requiera información adicional para completar el proceso de registro.\n\nAtentamente,\n\n[Nombre del usuario solicitante]\n[Rol o documento de identificación, si aplica]';

    final Uri emailLaunchUri = Uri.parse(
      'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      final canLaunch = await canLaunchUrl(emailLaunchUri);
      if (!canLaunch) {
        if (mounted) {
          AppSnackbar.info(
            context,
            'No se pudo abrir el correo. Contacta a soporte.cunitech@gmail.com',
          );
        }
        return;
      }
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        AppSnackbar.info(
          context,
          'No se pudo abrir el correo. Contacta a soporte.cunitech@gmail.com',
        );
      }
    }
  }

  Widget _buildContactFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta?',
          style: TextStyle(
            fontSize: 13.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () => _showContactAdminDialog(context),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Contacta al administrador',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // ========== HERO LOGO ==========
  Widget _buildHeroLogo({bool compact = false}) {
    final iconBox = Container(
      width: compact ? 48 : 64,
      height: compact ? 48 : 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.pets_rounded,
        color: AppTheme.accentLight,
        size: compact ? 28 : 38,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1.04, 1.04),
          duration: 2800.ms,
          curve: Curves.easeInOut,
        );

    return Row(
      children: [
        iconBox,
        SizedBox(width: compact ? 12 : 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CUNITECH',
              style: TextStyle(
                fontSize: compact ? 19 : 23,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Merriweather',
                letterSpacing: 1.4,
              ),
            ),
            Text(
              compact ? 'Cunicultura inteligente' : 'Rabbit Farm Management',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                color: Colors.white.withValues(alpha: 0.78),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  // ========== HERO STATS ==========
  Widget _buildHeroStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            _statsLoaded ? '$_totalConejos' : '—',
            'Conejos',
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatItem(
            _statsLoaded ? '${_tasaSupervivencia.toStringAsFixed(1)}%' : '—',
            'Supervivencia',
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatItem(
            _statsLoaded ? '$_partosMes' : '—',
            'Partos/mes',
          ),
        ),
      ],
    ).animate().fadeIn(duration: 1000.ms, delay: 200.ms);
  }

  Widget _buildStatItem(String value, String label) {
    return AnimatedOpacity(
      opacity: _statsLoaded ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ========== AUTH TABS ==========
  Widget _buildAuthTabs(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (_registroPublicoHabilitado) ...[
            _buildTabButton(
              context,
              "Iniciar Sesión",
              isLogin,
              onTap: () => setState(() => isLogin = true),
            ),
            _buildTabButton(
              context,
              "Registrarse",
              !isLogin,
              onTap: () => setState(() => isLogin = false),
            ),
          ] else
            _buildTabButton(context, "Iniciar Sesión", true),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    String text,
    bool selected, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            vertical: context.isMobile ? 10 : (context.isTablet ? 12 : 14),
          ),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppTheme.accent
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  // ========== CAMPOS DEL FORMULARIO ==========

  /// Altura reservada para el mensaje de validacion de cada campo.
  ///
  /// El mensaje se dibuja DENTRO de este espacio y nunca debajo del campo.
  /// Si el campo creciera al aparecer el error, los campos de abajo se
  /// desplazarian y el clic del usuario aterrizaria en otro widget: por eso
  /// el campo "parecia congelado" y el cursor no aparecia.
  static const double _validationSlotHeight = 30;

  /// Altura reservada para el mensaje de error general del formulario.
  /// Mismo motivo que [_validationSlotHeight]: el alto del contenido no puede
  /// cambiar cuando el mensaje aparece o desaparece.
  static const double _errorSlotHeight = 80;

  Widget _buildFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required bool compact,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                obscureText: obscure,
                onSubmitted: onFieldSubmitted,
                onChanged: field.didChange,
                // El foco se pide explicitamente: en Web el teclado virtual
                // solo se abre si el nodo de foco gana la peticion.
                onTap: () => focusNode.requestFocus(),
                // Solo se suelta el foco de ESTE campo. Usar
                // FocusScope.of(context).unfocus() limpienia el ambito
                // completo y podia robarle el foco al campo que el usuario
                // acababa de pulsar.
                onTapOutside: (_) => focusNode.unfocus(),
                cursorColor: AppTheme.accent,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(
                    icon,
                    color: AppTheme.accent.withValues(alpha: 0.85),
                    size: 20,
                  ),
                  suffixIcon: onToggleObscure == null
                      ? null
                      : IconButton(
                          onPressed: onToggleObscure,
                          icon: Icon(
                            obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            size: 20,
                          ),
                        ),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.74),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.45),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.45),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.accent,
                      width: 1.6,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: compact ? 18 : 20,
                  ),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.65,
                    ),
                    fontSize: 14,
                  ),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            _buildValidationSlot(field.errorText, theme.colorScheme.error),
          ],
        );
      },
    );
  }

  /// Espacio de altura fija donde se dibuja el error de validacion del campo.
  Widget _buildValidationSlot(String? errorText, Color errorColor) {
    return SizedBox(
      height: _validationSlotHeight,
      child: errorText == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 5, left: 2),
              child: Text(
                errorText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: errorColor,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ),
    );
  }

  // ========== AUTH BUTTON ==========
  Widget _buildAuthButton() {
    final enabled = !_isLoading;
    return PressableScale(
      enabled: enabled,
      pressedScale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: enabled
                ? const [
                    AppTheme.accentLight,
                    AppTheme.accent,
                    Color(0xFF6B4E36),
                  ]
                : [
                    AppTheme.accent.withValues(alpha: 0.5),
                    AppTheme.accent.withValues(alpha: 0.4),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? _authenticate : null,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isLogin ? 'INICIAR SESIÓN' : 'CREAR CUENTA',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== AUTENTICACIÓN CON SUPABASE (VIA EDGE FUNCTION) ====================
  Future<void> _authenticate() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isLogin) {
        final response = await _supabase.functions.invoke(
          'login',
          body: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );

        final data = response.data;
        if (data is! Map || data['session'] is! Map) {
          _setError('No se pudo iniciar sesión. Intenta de nuevo.');
          return;
        }

        final session = data['session'] as Map;
        final refreshToken = session['refresh_token'];
        if (refreshToken is! String || refreshToken.isEmpty) {
          _setError('No se pudo iniciar sesión. Intenta de nuevo.');
          return;
        }

        await _supabase.auth.setSession(refreshToken);
      } else {
        final response = await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final user = response.user;
        if (user == null) {
          _setError('No se pudo crear la cuenta. Intenta de nuevo.');
          return;
        }

        await _supabase.from('usuario').insert({
          'id_usuario': user.id,
          'nombre': _nameController.text.trim(),
        });

        if (response.session != null) {
          await _supabase.auth.signOut();
        }

        if (!mounted) return;
        setState(() {
          isLogin = true;
          _nameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
        AppSnackbar.success(
          context,
          'Cuenta creada correctamente. Inicia sesión.',
        );
        return;
      }

      if (!mounted) return;
      AppSnackbar.success(context, 'Bienvenido');
      Navigator.of(context).pushReplacementNamed('/main');
    } on FunctionException catch (e) {
      _setError(_friendlyFunctionError(e));
    } on AuthException catch (e) {
      _setError(_friendlyAuthError(e));
    } on PostgrestException catch (e) {
      debugPrint('Error guardando usuario: $e');
      _setError('No se pudo completar el registro. Intenta de nuevo.');
    } catch (e) {
      debugPrint('Error de autenticación: $e');
      _setError('No se pudo conectar. Revisa tu conexión e intenta de nuevo.');
    } finally {
      if (mounted) {
        // El estado de carga SIEMPRE vuelve a false, exista o no error.
        setState(() => _isLoading = false);
        // NO se roba el foco aqui: en Web un requestFocus tras el fallo abria
        // el teclado y desplazaba la vista, de modo que el siguiente clic
        // aterrizaba fuera del campo. El foco se queda donde el usuario lo
        // dejo y cada campo vuelve a ser editable con un simple clic.
      }
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  String _friendlyFunctionError(FunctionException e) {
    final details = e.details;
    if (details is Map && details['error'] is String) {
      final message = (details['error'] as String).trim();
      if (message.isNotEmpty) return message;
    }
    if (details is String && details.trim().isNotEmpty) {
      return details.trim();
    }
    return switch (e.status) {
      400 => 'Revisa los datos ingresados.',
      401 => 'Correo o contraseña incorrectos.',
      403 => 'No tienes permisos para iniciar sesión.',
      429 => 'Demasiados intentos. Espera un momento.',
      >= 500 => 'Error del servidor. Intenta de nuevo.',
      _ => 'No se pudo iniciar sesión. Intenta de nuevo.',
    };
  }

  String _friendlyAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión.';
    }
    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return 'Este correo ya está registrado.';
    }
    if (message.contains('password should be at least') ||
        message.contains('password is too short')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (message.contains('rate limit') ||
        message.contains('too many') ||
        message.contains('security purposes')) {
      return 'Demasiados intentos. Espera un momento.';
    }
    if (message.contains('invalid refresh token')) {
      return 'La sesión expiró. Inicia sesión de nuevo.';
    }
    if (message.contains('invalid email')) {
      return 'Ingresa un correo electrónico válido.';
    }
    debugPrint('Error de autenticación: ${e.message}');
    return 'No se pudo completar la operación. Intenta de nuevo.';
  }
}
