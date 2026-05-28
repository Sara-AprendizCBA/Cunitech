import 'package:flutter/material.dart';
import '../../models/birth.dart';
import '../../models/mating.dart';

class BirthRegistrationScreen extends StatefulWidget {
  final Mating? mating; // Opcional: si viene desde una monta

  const BirthRegistrationScreen({super.key, this.mating});

  @override
  State<BirthRegistrationScreen> createState() => _BirthRegistrationScreenState();
}

class _BirthRegistrationScreenState extends State<BirthRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _motherController;
  late TextEditingController _fatherController;
  late TextEditingController _litterSizeController;
  late TextEditingController _avgWeightController;
  late TextEditingController _notesController;

  DateTime _birthDate = DateTime.now();
  int _liveKits = 0;
  int _deadKits = 0;

  @override
  void initState() {
    super.initState();
    _motherController = TextEditingController(text: widget.mating?.doeId ?? '');
    _fatherController = TextEditingController(text: widget.mating?.buckId ?? '');
    _litterSizeController = TextEditingController();
    _avgWeightController = TextEditingController();
    _notesController = TextEditingController();
    _liveKits = widget.mating?.litterSize ?? 0;
  }

  @override
  void dispose() {
    _motherController.dispose();
    _fatherController.dispose();
    _litterSizeController.dispose();
    _avgWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro de Nacimientos"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Datos del Parto", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _motherController,
                decoration: const InputDecoration(labelText: "ID de la Coneja Madre *"),
                validator: (value) => value!.isEmpty ? "Obligatorio" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _fatherController,
                decoration: const InputDecoration(labelText: "ID del Macho (Opcional)"),
              ),
              const SizedBox(height: 16),

              // Fecha del parto
              ListTile(
                title: const Text("Fecha del Parto"),
                subtitle: Text("${_birthDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setState(() => _birthDate = picked);
                },
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _litterSizeController,
                      decoration: const InputDecoration(labelText: "Total Crías"),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? "Obligatorio" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _avgWeightController,
                      decoration: const InputDecoration(labelText: "Peso Promedio (g)"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text("Estado de las Crías", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: _buildCounter("Vivas", _liveKits, (value) => setState(() => _liveKits = value)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCounter("Muertas", _deadKits, (value) => setState(() => _deadKits = value)),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: "Observaciones",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _saveBirth,
                  child: const Text("REGISTRAR NACIMIENTO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => onChanged(value - 1), icon: const Icon(Icons.remove)),
                Text(value.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveBirth() {
    if (_formKey.currentState!.validate()) {
      final newBirth = Birth(
        id: "N-${DateTime.now().millisecondsSinceEpoch}",
        matingId: widget.mating?.id ?? "Manual",
        motherId: _motherController.text,
        fatherId: _fatherController.text.isEmpty ? null : _fatherController.text,
        birthDate: _birthDate,
        litterSize: int.parse(_litterSizeController.text),
        averageWeight: double.tryParse(_avgWeightController.text) ?? 0,
        liveKits: _liveKits,
        deadKits: _deadKits,
        notes: _notesController.text,
      );

      // Aquí iría el guardado real (Riverpod / Database)

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Nacimiento registrado exitosamente!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, newBirth); // Retorna el nacimiento registrado
    }
  }
}