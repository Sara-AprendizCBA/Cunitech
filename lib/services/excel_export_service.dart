import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/reportes_controller.dart';
import '../models/meta_mensual.dart';

class ExcelExportService {
  final _supabase = Supabase.instance.client;

  static final _headerStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('#FF8B5A2B'),
    fontColorHex: ExcelColor.white,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FF6B4F3A')),
    bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FF6B4F3A')),
    leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FF6B4F3A')),
    rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FF6B4F3A')),
  );

  static final _titleStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('#FFF0EDE9'),
    fontColorHex: ExcelColor.fromHexString('#FF6B4F3A'),
    bold: true,
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
    bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
    leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
    rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
  );

  static final _dataStyle = CellStyle(
    fontColorHex: ExcelColor.black,
    verticalAlign: VerticalAlign.Center,
    topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
    bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
    leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
    rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
  );

  static final _dataCenterStyle = CellStyle(
    fontColorHex: ExcelColor.black,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
    bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
    leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
    rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFCCCCCC')),
  );

  Future<void> exportarReporte({
    required ReportesController controller,
    required String nombreCriadero,
  }) async {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month);
    final inicioMesSiguiente = DateTime(ahora.year, ahora.month + 1);
    final datos = await _cargarDatos(controller, inicioMes, inicioMesSiguiente);

    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, 'Reporte');
    }
    final sheet = excel['Reporte'];

    var row = 0;
    row = _writeInfo(sheet, row, nombreCriadero, ahora);
    row++;
    row = _writeResumen(sheet, row, datos);
    row++;
    row = _writeDesempeno(sheet, row, datos, controller);
    row++;
    row = _writeMetas(sheet, row, controller);
    row++;
    row = _writeInventario(sheet, row, datos);
    row++;
    row = _writeEventos(sheet, row, controller);

    _setColumnWidths(sheet, [22, 22, 16, 18, 18, 16]);

    final bytes = excel.encode();
    if (bytes == null) throw StateError('No se pudo generar el archivo Excel.');

    final marca = DateFormat('yyyy-MM-dd_HHmm').format(ahora);
    await FileSaver.instance.saveFile(
      name: 'reporte_cunitech_$marca',
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  int _writeInfo(Sheet sheet, int row, String nombreCriadero, DateTime ahora) {
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(ahora);
    final periodo = '${_nombreMes(ahora.month)} ${ahora.year}';
    final responsable = _nombreResponsable();
    final info = [
      ['CUNITECH - Reporte General', nombreCriadero],
      ['Fecha de generación', fecha],
      ['Responsable', responsable],
      ['Período', periodo],
    ];
    for (var i = 0; i < info.length; i++) {
      _setCell(sheet, row + i, 0, info[i][0], i == 0 ? _headerStyle : _titleStyle);
      _setCell(sheet, row + i, 1, info[i][1], _dataStyle);
      for (var c = 2; c < 6; c++) {
        _setCell(sheet, row + i, c, '', _dataStyle);
      }
    }
    return row + info.length;
  }

  int _writeResumen(Sheet sheet, int row, _DatosReporte datos) {
    _setSectionTitle(sheet, row, 'RESUMEN DEL CRIADERO');
    row++;
    final headers = ['Total conejos', 'Reproductoras en ciclo', 'Gestantes', 'Alertas'];
    final values = [
      datos.totalConejos,
      datos.reproductorasEnCiclo,
      datos.gestantes,
      datos.alertas,
    ];
    for (var c = 0; c < headers.length; c++) {
      _setCell(sheet, row, c, headers[c], _headerStyle);
    }
    for (var c = headers.length; c < 6; c++) {
      _setCell(sheet, row, c, '', _headerStyle);
    }
    row++;
    for (var c = 0; c < values.length; c++) {
      _setCell(sheet, row, c, values[c], _dataCenterStyle);
    }
    for (var c = values.length; c < 6; c++) {
      _setCell(sheet, row, c, '', _dataCenterStyle);
    }
    return row + 1;
  }

  int _writeDesempeno(Sheet sheet, int row, _DatosReporte datos, ReportesController controller) {
    _setSectionTitle(sheet, row, 'DESEMPEÑO REPRODUCTIVO DEL MES');
    row++;
    final headers = ['Indicador', 'Valor', 'Meta'];
    for (var c = 0; c < headers.length; c++) {
      _setCell(sheet, row, c, headers[c], _headerStyle);
    }
    for (var c = headers.length; c < 6; c++) {
      _setCell(sheet, row, c, '', _headerStyle);
    }
    row++;

    final metas = {for (final meta in controller.metasMes) meta.kpi: meta};
    final filas = <List<String>>[
      ['Montas realizadas', '${datos.montas}', '-'],
      ['Preñeces confirmadas', '${datos.preneces} (${datos.fertilidad.toStringAsFixed(0)}%)', '-'],
      ['Partos registrados', '${datos.partos}', '-'],
      ['Gazapos vivos', '${datos.vivos}', '-'],
      ['Gazapos muertos', '${datos.muertos}', '-'],
      ['Prolificidad', '${datos.prolificidad.toStringAsFixed(1)} gaz/par', _metaObjetivo(metas['prolificidad'])],
      ['Supervivencia', '${datos.supervivencia.toStringAsFixed(0)}%', _metaObjetivo(metas['supervivencia'])],
      ['Tasa de fertilidad', '${datos.fertilidad.toStringAsFixed(0)}%', _metaObjetivo(metas['fertilidad'])],
    ];

    for (final fila in filas) {
      for (var c = 0; c < fila.length; c++) {
        _setCell(sheet, row, c, fila[c], c == 0 ? _dataStyle : _dataCenterStyle);
      }
      for (var c = fila.length; c < 6; c++) {
        _setCell(sheet, row, c, '', _dataCenterStyle);
      }
      row++;
    }
    return row;
  }

  int _writeMetas(Sheet sheet, int row, ReportesController controller) {
    _setSectionTitle(sheet, row, 'METAS DEL MES');
    row++;
    final metas = controller.metasMes;
    final headers = ['KPI', 'Actual', 'Meta', 'Diferencia', 'Estado'];
    for (var c = 0; c < headers.length; c++) {
      _setCell(sheet, row, c, headers[c], _headerStyle);
    }
    _setCell(sheet, row, 5, '', _headerStyle);
    row++;

    if (metas.isEmpty) {
      _setCell(sheet, row, 0, 'Sin metas configuradas para este mes.', _dataStyle);
      for (var c = 1; c < 6; c++) {
        _setCell(sheet, row, c, '', _dataStyle);
      }
      return row + 1;
    }

    for (final meta in metas) {
      final actual = controller.valoresActualesKpi[meta.kpi] ?? 0;
      final diferencia = actual - meta.valorObjetivo;
      final valores = [
        meta.kpiLabel,
        '${actual.toStringAsFixed(1)} ${meta.unidad}',
        '${meta.valorObjetivo.toStringAsFixed(1)} ${meta.unidad}',
        '${diferencia >= 0 ? '+' : ''}${diferencia.toStringAsFixed(1)}',
        controller.estadoMeta(meta),
      ];
      for (var c = 0; c < valores.length; c++) {
        _setCell(sheet, row, c, valores[c], c == 0 ? _dataStyle : _dataCenterStyle);
      }
      _setCell(sheet, row, 5, '', _dataCenterStyle);
      row++;
    }
    return row;
  }

  int _writeInventario(Sheet sheet, int row, _DatosReporte datos) {
    _setSectionTitle(sheet, row, 'INVENTARIO GENERAL DE CONEJOS');
    row++;
    final headers = ['ID', 'Raza', 'Sexo', 'Estado', 'Reprod.', 'Peso'];
    for (var c = 0; c < headers.length; c++) {
      _setCell(sheet, row, c, headers[c], _headerStyle);
    }
    row++;

    if (datos.inventario.isEmpty) {
      _setCell(sheet, row, 0, 'No hay conejos registrados.', _dataStyle);
      for (var c = 1; c < 6; c++) {
        _setCell(sheet, row, c, '', _dataStyle);
      }
      return row + 1;
    }

    for (final conejo in datos.inventario) {
      final valores = [conejo.id, conejo.raza, conejo.sexo, conejo.estado, conejo.reproductivo, conejo.peso];
      for (var c = 0; c < valores.length; c++) {
        _setCell(sheet, row, c, valores[c], c == 0 ? _dataStyle : _dataCenterStyle);
      }
      row++;
    }
    return row;
  }

  int _writeEventos(Sheet sheet, int row, ReportesController controller) {
    _setSectionTitle(sheet, row, 'ÚLTIMOS EVENTOS REGISTRADOS');
    row++;
    final headers = ['Fecha', 'Evento', 'Detalle'];
    for (var c = 0; c < headers.length; c++) {
      _setCell(sheet, row, c, headers[c], _headerStyle);
    }
    for (var c = headers.length; c < 6; c++) {
      _setCell(sheet, row, c, '', _headerStyle);
    }
    row++;

    final eventos = <_Evento>[];
    for (final nacimiento in controller.nacimientosRecientes.take(5)) {
      final fecha = DateTime.tryParse(nacimiento['birth_date']?.toString() ?? '');
      if (fecha != null) {
        eventos.add(_Evento(
          fecha: fecha,
          tipo: 'Nacimiento',
          detalle: '${nacimiento['chapeta_madre'] ?? 'Sin ID'} · ${nacimiento['live_kits'] ?? 0} vivos · ${nacimiento['dead_kits'] ?? 0} muertos',
        ));
      }
    }
    for (final monta in controller.montasRecientes.take(5)) {
      final fecha = DateTime.tryParse(monta['fecha_monta']?.toString() ?? '');
      if (fecha != null) {
        eventos.add(_Evento(
          fecha: fecha,
          tipo: 'Monta',
          detalle: '${monta['chapeta_coneja'] ?? 'Sin ID'} · ${monta['estado'] ?? 'Sin estado'}',
        ));
      }
    }
    eventos.sort((a, b) => b.fecha.compareTo(a.fecha));
    final recientes = eventos.take(10).toList();

    if (recientes.isEmpty) {
      _setCell(sheet, row, 0, 'Sin registros de actividad.', _dataStyle);
      for (var c = 1; c < 6; c++) {
        _setCell(sheet, row, c, '', _dataStyle);
      }
      return row + 1;
    }

    for (final evento in recientes) {
      _setCell(sheet, row, 0, DateFormat('dd/MM/yyyy').format(evento.fecha), _dataCenterStyle);
      _setCell(sheet, row, 1, evento.tipo, _dataCenterStyle);
      _setCell(sheet, row, 2, evento.detalle, _dataStyle);
      for (var c = 3; c < 6; c++) {
        _setCell(sheet, row, c, '', _dataStyle);
      }
      row++;
    }
    return row;
  }

  void _setSectionTitle(Sheet sheet, int row, String title) {
    _setCell(sheet, row, 0, title, _headerStyle);
    for (var c = 1; c < 6; c++) {
      _setCell(sheet, row, c, '', _headerStyle);
    }
  }

  void _setCell(Sheet sheet, int row, int col, Object value, CellStyle style) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = switch (value) {
      int v => IntCellValue(v),
      double v => DoubleCellValue(v),
      _ => TextCellValue(value.toString()),
    };
    cell.cellStyle = style;
  }

  void _setColumnWidths(Sheet sheet, List<double> widths) {
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  String _metaObjetivo(MetaMensual? meta) {
    if (meta == null) return '-';
    return '${meta.valorObjetivo.toStringAsFixed(1)} ${meta.unidad}';
  }

  String _nombreResponsable() {
    final user = _supabase.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final nombre = metadata['full_name'] ?? metadata['name'] ?? metadata['display_name'];
    if (nombre is String && nombre.trim().isNotEmpty) return nombre.trim();
    final correo = user?.email;
    if (correo != null && correo.contains('@')) return correo.split('@').first;
    return 'Admin';
  }

  Future<_DatosReporte> _cargarDatos(
    ReportesController controller,
    DateTime inicioMes,
    DateTime inicioMesSiguiente,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('No hay un usuario autenticado para generar el reporte.');
    }
    final inicio = _fechaIso(inicioMes);
    final fin = _fechaIso(inicioMesSiguiente);

    final montas = await _supabase
        .from('reproduccion')
        .select('id_reproduccion')
        .gte('fecha_monta', inicio)
        .lt('fecha_monta', fin);
    final preneces = await _supabase
        .from('reproduccion')
        .select('id_reproduccion')
        .inFilter('estado', ['Gestante', 'Lactante', 'Destete'])
        .gte('fecha_monta', inicio)
        .lt('fecha_monta', fin);
    final partos = await _supabase
        .from('births')
        .select('live_kits, dead_kits, adopted_kits, litter_size')
        .gte('birth_date', inicio)
        .lt('birth_date', fin);
    final reproductoras = await _supabase
        .from('conejo')
        .select('id_conejo')
        .eq('genero', 'Hembra')
        .inFilter('reproductive_status', ['Servida', 'Gestante', 'Lactante', 'Destete']);
    final gestantes = await _supabase
        .from('conejo')
        .select('id_conejo')
        .eq('genero', 'Hembra')
        .eq('reproductive_status', 'Gestante');
    final alertas = await _supabase
        .from('conejo')
        .select('id_conejo')
        .inFilter('estado', ['En tratamiento', 'Enfermo']);
    final inventarioRows = await _supabase
        .from('conejo')
        .select('id_conejo, chapeta, raza, genero, estado, peso, reproductive_status')
        .order('chapeta')
        .limit(60);

    var vivos = 0;
    var muertos = 0;
    final listaPartos = (partos as List).cast<Map<String, dynamic>>();
    for (final parto in listaPartos) {
      vivos += (parto['live_kits'] as num?)?.toInt() ?? 0;
      muertos += (parto['dead_kits'] as num?)?.toInt() ?? 0;
    }

    final cantidadMontas = (montas as List).length;
    final cantidadPreneces = (preneces as List).length;
    final fertilidad = cantidadMontas == 0 ? 0.0 : cantidadPreneces / cantidadMontas * 100;
    final supervivencia = vivos + muertos == 0 ? 0.0 : vivos / (vivos + muertos) * 100;
    final prolificidad = listaPartos.isEmpty ? 0.0 : vivos / listaPartos.length;

    final inventario = <_ConejoInventario>[];
    for (final row in inventarioRows) {
      final mapa = (row as Map).cast<String, dynamic>();
      final estado = (mapa['estado'] as String? ?? 'Saludable').trim();
      final peso = (mapa['peso'] as num?)?.toDouble();
      inventario.add(_ConejoInventario(
        id: (mapa['chapeta'] as String? ?? 'Sin ID').trim(),
        raza: (mapa['raza'] as String? ?? '-').trim(),
        sexo: (mapa['genero'] as String? ?? '-').trim(),
        estado: estado,
        reproductivo: (mapa['reproductive_status'] as String? ?? '-').trim(),
        peso: peso == null || peso <= 0 ? '-' : '${peso.toStringAsFixed(1)} kg',
      ));
    }

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
      fertilidad: fertilidad,
      supervivencia: supervivencia,
      prolificidad: prolificidad,
      inventario: inventario,
    );
  }

  String _fechaIso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _nombreMes(int mes) => const [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
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
  final double fertilidad;
  final double supervivencia;
  final double prolificidad;
  final List<_ConejoInventario> inventario;

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
    required this.fertilidad,
    required this.supervivencia,
    required this.prolificidad,
    required this.inventario,
  });
}

class _ConejoInventario {
  final String id;
  final String raza;
  final String sexo;
  final String estado;
  final String reproductivo;
  final String peso;

  const _ConejoInventario({
    required this.id,
    required this.raza,
    required this.sexo,
    required this.estado,
    required this.reproductivo,
    required this.peso,
  });
}

class _Evento {
  final DateTime fecha;
  final String tipo;
  final String detalle;

  const _Evento({required this.fecha, required this.tipo, required this.detalle});
}
