class UserProfile {
  final String idUsuario;
  final String nombre;
  final String? email;
  final String rol; // 'admin' | 'veterinario' | 'ayudante' | 'usuario'
  final bool activo;
  final String? createdBy;
  final DateTime? createdAt;

  const UserProfile({
    required this.idUsuario,
    required this.nombre,
    this.email,
    required this.rol,
    this.activo = true,
    this.createdBy,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      idUsuario: json['id_usuario'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String?,
      rol: json['rol'] as String? ?? 'usuario',
      activo: json['activo'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  bool get esAdmin => rol == 'admin';
  bool get esVeterinario => rol == 'veterinario';
  bool get esAyudante => rol == 'ayudante';
  bool get esUsuario => rol == 'usuario';
  bool get tieneRolAsignado => rol != 'usuario';
}
