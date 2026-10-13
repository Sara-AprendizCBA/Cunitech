import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/reportes_controller.dart';
import '../models/meta_mensual.dart';

final _marron = PdfColor.fromInt(0xFF6B4F3A);
final _grisEncabezado = PdfColor.fromInt(0xFFF0EDE9);
final _grisBorde = PdfColor.fromInt(0xFFCCCCCC);
final _verde = PdfColor.fromInt(0xFF166534);
final _rojo = PdfColor.fromInt(0xFF991B1B);

class PdfService {
  final _supabase = Supabase.instance.client;

  Future<void> exportarReporte({
    required ReportesController controller,
    required String nombreCriadero,
  }) async {
    final pdf = await _construirPdf(
      controller: controller,
      nombreCriadero: nombreCriadero,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => pdf,
      name: 'reporte_cunitech_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<Uint8List> _construirPdf({
    required ReportesController controller,
    required String nombreCriadero,
  }) async {
    final regular = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();
    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      // El encabezado conserva el texto institucional aunque falte el logo.
    }

    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month);
    final inicioMesSiguiente = DateTime(ahora.year, ahora.month + 1);
    final datos = await _cargarDatos(controller, inicioMes, inicioMesSiguiente);
    final fecha = '${ahora.day}/${ahora.month}/${ahora.year}';
    final hora = '${ahora.hour.toString().padLeft(2, '0')}:'
        '${ahora.minute.toString().padLeft(2, '0')}';
    final periodo = '${_nombreMes(ahora.month)} ${ahora.year}';

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 30),
        ),
        footer: (context) => _buildFooter(
          fecha: fecha,
          pagina: context.pageNumber,
          totalPaginas: context.pagesCount,
        ),
        build: (context) => [
          _buildHeader(logo: logo, nombreCriadero: nombreCriadero),
          pw.SizedBox(height: 12),
          _buildTitleBanner(),
          pw.SizedBox(height: 12),
          _buildDatosGenerales(
            fecha: '$fecha · $hora',
            responsable: _nombreResponsable(),
            periodo: periodo,
          ),
          pw.SizedBox(height: 24),
          _buildSection('RESUMEN DEL CRIADERO'),
          pw.SizedBox(height: 10),
          _buildResumenCriadero(datos),
          pw.SizedBox(height: 24),
          _buildSection('DESEMPEÑO REPRODUCTIVO DEL MES'),
          pw.SizedBox(height: 10),
          _buildDesempeno(datos, controller),
          pw.SizedBox(height: 24),
          _buildSection('METAS DEL MES'),
          pw.SizedBox(height: 10),
          _buildMetas(controller),
          pw.SizedBox(height: 24),
          _buildSection('ANÁLISIS Y RECOMENDACIONES'),
          pw.SizedBox(height: 10),
          _buildRecomendaciones(datos),
          pw.SizedBox(height: 24),
          _buildSection('ÚLTIMOS EVENTOS REGISTRADOS'),
          pw.SizedBox(height: 10),
          _buildEventos(controller),
          pw.SizedBox(height: 24),
          _buildSection('OBSERVACIONES Y FIRMAS'),
          pw.SizedBox(height: 10),
          _buildObservacionesYFirmas(),
        ],
      ),
    );
    return doc.save();
  }

  Future<_DatosReporte> _cargarDatos(
    ReportesController controller,
    DateTime inicioMes,
    DateTime inicioMesSiguiente,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No hay un usuario autenticado para generar el reporte.');
    }
    final inicio = _fechaIso(inicioMes);
    final fin = _fechaIso(inicioMesSiguiente);

    final montas = await _supabase
        .from('reproduccion')
        .select('id_reproduccion')
        .eq('user_id', userId)
        .gte('fecha_monta', inicio)
        .lt('fecha_monta', fin);
    final preneces = await _supabase
        .from('reproduccion')
        .select('id_reproduccion')
        .eq('user_id', userId)
        .inFilter('estado', ['Gestante', 'Lactante', 'Destete'])
        .gte('fecha_monta', inicio)
        .lt('fecha_monta', fin);
    final partos = await _supabase
        .from('births')
        .select('live_kits, dead_kits, adopted_kits, litter_size')
        .eq('user_id', userId)
        .gte('birth_date', inicio)
        .lt('birth_date', fin);
    final reproductoras = await _supabase
        .from('conejo')
        .select('id_conejo')
        .eq('user_id', userId)
        .eq('genero', 'Hembra')
        .inFilter('reproductive_status', [
          'Servida',
          'Gestante',
          'Lactante',
          'Destete',
        ]);
    final gestantes = await _supabase
        .from('conejo')
        .select('id_conejo')
        .eq('user_id', userId)
        .eq('genero', 'Hembra')
        .eq('reproductive_status', 'Gestante');
    final alertas = await _supabase
        .from('conejo')
        .select('id_conejo')
        .eq('user_id', userId)
        .inFilter('estado', ['En tratamiento', 'Enfermo']);

    var vivos = 0;
    var muertos = 0;
    var adoptados = 0;
    final listaPartos = (partos as List).cast<Map<String, dynamic>>();
    for (final parto in listaPartos) {
      vivos += (parto['live_kits'] as num?)?.toInt() ?? 0;
      muertos += (parto['dead_kits'] as num?)?.toInt() ?? 0;
      adoptados += (parto['adopted_kits'] as num?)?.toInt() ?? 0;
    }

    final cantidadMontas = (montas as List).length;
    final cantidadPreneces = (preneces as List).length;
    final fertilidad = cantidadMontas == 0
        ? 0.0
        : cantidadPreneces / cantidadMontas * 100;
    final supervivencia = vivos + muertos == 0
        ? 0.0
        : vivos / (vivos + muertos) * 100;
    final prolificidad = listaPartos.isEmpty ? 0.0 : vivos / listaPartos.length;

    return _DatosReporte(
      totalConejos: controller.totalConejos.value,
      reproductorasEnCiclo: (reproductoras as List).length,
      gestantes: (gestantes as List).length,
      alertas: (alertas as List).length,
      montas: cantidadMontas,
      preneces: cantidadPreneces,
      partos: listaPartos.length,
      vivos: vivos,
      muertos: muertos,
      adoptados: adoptados,
      fertilidad: fertilidad,
      supervivencia: supervivencia,
      prolificidad: prolificidad,
    );
  }

  String _nombreResponsable() {
    final user = _supabase.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final nombre = metadata['full_name'] ??
        metadata['name'] ??
        metadata['display_name'];
    if (nombre is String && nombre.trim().isNotEmpty) return nombre.trim();
    final correo = user?.email;
    if (correo != null && correo.contains('@')) return correo.split('@').first;
    return 'Admin';
  }

  pw.Widget _buildHeader({
    required pw.MemoryImage? logo,
    required String nombreCriadero,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _grisBorde, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              height: 90,
              padding: const pw.EdgeInsets.all(10),
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    nombreCriadero.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: _marron,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Sistema de gestión de criadero',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              height: 90,
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.center,
              child: logo == null
                  ? pw.Text(
                      'CUNITECH',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: _marron,
                      ),
                    )
                  : pw.Image(
                      logo,
                      width: 50,
                      height: 50,
                      fit: pw.BoxFit.contain,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTitleBanner() => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(20),
        color: _marron,
        alignment: pw.Alignment.center,
        child: pw.Text(
          'REPORTE DE ACTIVIDADES CUNÍCOLAS',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );

  pw.Widget _buildDatosGenerales({
    required String fecha,
    required String responsable,
    required String periodo,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _grisBorde, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _grisEncabezado),
          children: [
            _cell('FECHA DEL INFORME', header: true),
            _cell('RESPONSABLE', header: true),
            _cell('PERÍODO', header: true),
          ],
        ),
        pw.TableRow(children: [
          _cell(fecha),
          _cell(responsable),
          _cell(periodo),
        ]),
      ],
    );
  }

  pw.Widget _buildSection(String title) => pw.Container(
        width: double.infinity,
        color: _marron,
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 1.2,
          ),
        ),
      );

  pw.Widget _buildResumenCriadero(_DatosReporte data) {
    final items = [
      ('TOTAL DE CONEJOS', data.totalConejos),
      ('REPRODUCTORAS', data.reproductorasEnCiclo),
      ('GESTANTES', data.gestantes),
      ('ALERTAS', data.alertas),
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: _grisBorde, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _grisEncabezado),
          children: [for (final item in items) _cell(item.$1, header: true)],
        ),
        pw.TableRow(
          children: [
            for (final item in items)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '${item.$2}',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _marron,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDesempeno(
    _DatosReporte data,
    ReportesController controller,
  ) {
    final metas = {for (final meta in controller.metasMes) meta.kpi: meta};
    final filas = <(String, String, String, bool?)>[
      ('Montas realizadas', '${data.montas}', '-', null),
      (
        'Preñeces confirmadas',
        '${data.preneces} (${data.fertilidad.toStringAsFixed(0)}%)',
        '-',
        null,
      ),
      ('Partos registrados', '${data.partos}', '-', null),
      ('Gazapos vivos', '${data.vivos}', '-', null),
      ('Gazapos muertos', '${data.muertos}', '-', null),
      (
        'Prolificidad',
        '${data.prolificidad.toStringAsFixed(1)} gaz/par',
        _metaObjetivo(metas['prolificidad']),
        _cumple(data.prolificidad, metas['prolificidad']),
      ),
      (
        'Supervivencia',
        '${data.supervivencia.toStringAsFixed(0)}%',
        _metaObjetivo(metas['supervivencia']),
        _cumple(data.supervivencia, metas['supervivencia']),
      ),
      (
        'Tasa de fertilidad',
        '${data.fertilidad.toStringAsFixed(0)}%',
        _metaObjetivo(metas['fertilidad']),
        _cumple(data.fertilidad, metas['fertilidad']),
      ),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _grisBorde, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.4),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _grisEncabezado),
          children: [
            _cell('INDICADOR', header: true),
            _cell('VALOR', header: true),
            _cell('META', header: true),
          ],
        ),
        for (final fila in filas)
          pw.TableRow(
            children: [
              _cell(fila.$1),
              _cell(fila.$2),
              _cell(
                fila.$3 == '-' || fila.$4 == null
                    ? fila.$3
                    : '${fila.$3} ${fila.$4! ? '[OK]' : '[X]'}',
                background: fila.$4 == null
                    ? _grisEncabezado
                    : (fila.$4! ? PdfColor.fromInt(0xFFE8F5E9) : PdfColor.fromInt(0xFFFDECEC)),
                color: fila.$4 == null ? PdfColors.black : (fila.$4! ? _verde : _rojo),
                bold: fila.$4 != null,
              ),
            ],
          ),
      ],
    );
  }

  String _metaObjetivo(MetaMensual? meta) {
    if (meta == null) return '-';
    return '${meta.valorObjetivo.toStringAsFixed(1)} ${meta.unidad}';
  }

  bool? _cumple(double actual, MetaMensual? meta) {
    if (meta == null) return null;
    return actual >= meta.valorObjetivo;
  }

  pw.Widget _buildMetas(ReportesController controller) {
    final metas = controller.metasMes;
    if (metas.isEmpty) return _simpleMessage('Sin metas configuradas para este mes.');
    return pw.Table(
      border: pw.TableBorder.all(color: _grisBorde, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(0.8),
        4: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _grisEncabezado),
          children: [
            _cell('KPI', header: true),
            _cell('ACTUAL', header: true),
            _cell('META', header: true),
            _cell('DIF.', header: true),
            _cell('ESTADO', header: true),
          ],
        ),
        for (final meta in metas) _metaRow(meta, controller),
      ],
    );
  }

  pw.TableRow _metaRow(MetaMensual meta, ReportesController controller) {
    final actual = controller.valoresActualesKpi[meta.kpi] ?? 0;
    final diferencia = actual - meta.valorObjetivo;
    final cumple = actual >= meta.valorObjetivo;
    final color = cumple ? _verde : _rojo;
    final fondo = cumple
        ? PdfColor.fromInt(0xFFE8F5E9)
        : PdfColor.fromInt(0xFFFDECEC);
    return pw.TableRow(
      children: [
        _cell(meta.kpiLabel),
        _cell('${actual.toStringAsFixed(1)} ${meta.unidad}'),
        _cell('${meta.valorObjetivo.toStringAsFixed(1)} ${meta.unidad}'),
        _cell(
          '${diferencia >= 0 ? '+' : ''}${diferencia.toStringAsFixed(1)}',
          color: color,
          bold: true,
        ),
        _cell(
          controller.estadoMeta(meta),
          color: color,
          background: fondo,
          bold: true,
        ),
      ],
    );
  }

  pw.Widget _buildRecomendaciones(_DatosReporte data) {
    final recomendaciones = <(String, PdfColor)>[];
    if (data.fertilidad < 65) {
      recomendaciones.add((
        'Fertilidad baja (${data.fertilidad.toStringAsFixed(0)}%). '
            'Revisar seguimiento de montas y confirmación de preñez.',
        _rojo,
      ));
    }
    if (data.supervivencia < 80) {
      recomendaciones.add((
        'Supervivencia baja (${data.supervivencia.toStringAsFixed(0)}%). '
            'Revisar atención de los nidos y control de camada.',
        _rojo,
      ));
    }
    if (data.prolificidad < 7) {
      recomendaciones.add((
        'Prolificidad de ${data.prolificidad.toStringAsFixed(1)} gaz/par. '
            'Revisar selección reproductiva y registros de parto.',
        _rojo,
      ));
    }
    if (recomendaciones.isEmpty) {
      recomendaciones.add((
        'Todos los indicadores evaluados están dentro de los valores de referencia.',
        _verde,
      ));
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final recomendacion in recomendaciones)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  recomendacion.$2 == _verde ? '[OK]  ' : '[!]  ',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: recomendacion.$2,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    recomendacion.$1,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _buildEventos(ReportesController controller) {
    final eventos = <_Evento>[];
    for (final nacimiento in controller.nacimientosRecientes.take(5)) {
      final fecha = _parseFecha(nacimiento['birth_date']);
      if (fecha != null) {
        eventos.add(_Evento(
          fecha: fecha,
          tipo: 'Nacimiento',
          detalle: '${nacimiento['chapeta_madre'] ?? 'Sin ID'} · '
              '${nacimiento['live_kits'] ?? 0} vivos · '
              '${nacimiento['dead_kits'] ?? 0} muertos',
        ));
      }
    }
    for (final monta in controller.montasRecientes.take(5)) {
      final fecha = _parseFecha(monta['fecha_monta']);
      if (fecha != null) {
        eventos.add(_Evento(
          fecha: fecha,
          tipo: 'Monta',
          detalle: '${monta['chapeta_coneja'] ?? 'Sin ID'} · '
              '${monta['estado'] ?? 'Sin estado'}',
        ));
      }
    }
    eventos.sort((a, b) => b.fecha.compareTo(a.fecha));
    final recientes = eventos.take(10).toList();
    if (recientes.isEmpty) return _simpleMessage('Sin registros de actividad.');

    return pw.Table(
      border: pw.TableBorder.all(color: _grisBorde, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _grisEncabezado),
          children: [
            _cell('FECHA', header: true),
            _cell('EVENTO', header: true),
            _cell('DETALLE', header: true),
          ],
        ),
        for (final evento in recientes)
          pw.TableRow(children: [
            _cell(_fechaCorta(evento.fecha)),
            _cell(evento.tipo),
            _cell(evento.detalle),
          ]),
      ],
    );
  }

  pw.Widget _buildObservacionesYFirmas() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 3; i++)
            pw.Container(
              height: 25,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _grisBorde, width: 0.5),
                ),
              ),
            ),
          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.only(top: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                ),
              ),
              child: pw.Text(
                'Firma Responsable',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      );

  pw.Widget _simpleMessage(String text) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _grisBorde, width: 0.5),
        ),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      );

  pw.Widget _cell(
    String text, {
    bool header = false,
    bool bold = false,
    PdfColor? color,
    PdfColor? background,
  }) =>
      pw.Container(
        color: background,
        padding: const pw.EdgeInsets.all(5),
        alignment: header ? pw.Alignment.center : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: header ? 9 : 10,
            fontWeight:
                header || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      );

  pw.Widget _buildFooter({
    required String fecha,
    required int pagina,
    required int totalPaginas,
  }) =>
      pw.Column(
        children: [
          pw.Divider(color: _grisBorde, thickness: 0.6),
          pw.Text(
            'Reporte generado por CUNITECH · $fecha · '
            'Página $pagina de $totalPaginas',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      );

  String _fechaIso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DateTime? _parseFecha(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _fechaCorta(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  String _nombreMes(int mes) => const [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ][mes - 1];
}

class _DatosReporte {
  final int totalConejos;
  final int reproductorasEnCiclo;
  final int gestantes;
  final int alertas;
  final int montas;
  final int preneces;
  final int partos;
  final int vivos;
  final int muertos;
  final int adoptados;
  final double fertilidad;
  final double supervivencia;
  final double prolificidad;

  const _DatosReporte({
    required this.totalConejos,
    required this.reproductorasEnCiclo,
    required this.gestantes,
    required this.alertas,
    required this.montas,
    required this.preneces,
    required this.partos,
    required this.vivos,
    required this.muertos,
    required this.adoptados,
    required this.fertilidad,
    required this.supervivencia,
    required this.prolificidad,
  });
}

class _Evento {
  final DateTime fecha;
  final String tipo;
  final String detalle;

  const _Evento({
    required this.fecha,
    required this.tipo,
    required this.detalle,
  });
}
