import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ================= CONFIG API =================
const String apiBaseUrl = "http://10.0.2.2:3000";

// ================= PERSONA REGISTRADA =================
Map<String, dynamic>? personaRegistrada;

// Número de emergencia por defecto
const String numeroEmergenciaDefecto = "911";

void main() {
  runApp(const MyApp());
}

// ================= APP =================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// ================= HOME =================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> reportarAsalto(BuildContext context) async {
    print("🟡 INICIANDO REPORTE DE ASALTO");

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("🔴 GPS DESACTIVADO");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    print("📍 LAT: ${position.latitude}");
    print("📍 LNG: ${position.longitude}");

    // Enviar asalto a la API
    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/asalto"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "descripcion": "Asalto reportado desde Flutter",
          "persona_id": personaRegistrada?["id"],
          "lat": position.latitude,
          "lng": position.longitude,
        }),
      );

      print("🟢 ASALTO STATUS: ${response.statusCode}");
    } catch (e) {
      print("🔥 ERROR HTTP ASALTO: $e");
    }

    // Llamada telefónica
    String telefono = personaRegistrada == null
        ? numeroEmergenciaDefecto
        : personaRegistrada!["emergencia"];

    await launchUrl(Uri.parse("tel:$telefono"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Botón de Pánico'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(40),
              ),
              onPressed: () => reportarAsalto(context),
              child: const Text(
                'REPORTAR ASALTO',
                style: TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegistroPersonaPage(),
                  ),
                );
              },
              child: const Text('REGISTRARSE'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= REGISTRO PERSONA =================
class RegistroPersonaPage extends StatefulWidget {
  const RegistroPersonaPage({super.key});

  @override
  State<RegistroPersonaPage> createState() => _RegistroPersonaPageState();
}

class _RegistroPersonaPageState extends State<RegistroPersonaPage> {
  final cedulaController = TextEditingController();
  final nombresController = TextEditingController();
  final apellidosController = TextEditingController();
  final edadController = TextEditingController();
  final celularController = TextEditingController();
  final emergenciaController = TextEditingController();

  String generoSeleccionado = 'M';

  Future<void> guardarPersona() async {
    print("🟡 ENVIANDO PERSONA A LA API");

    if (edadController.text.isEmpty) {
      print("🔴 EDAD VACÍA");
      return;
    }

    int edad;
    try {
      edad = int.parse(edadController.text);
    } catch (e) {
      print("🔴 EDAD NO NUMÉRICA");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/persona"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "cedula": cedulaController.text,
          "nombres": nombresController.text,
          "apellidos": apellidosController.text,
          "genero": generoSeleccionado,
          "edad": edad,
          "celular": celularController.text,
          "contacto_emergencia": emergenciaController.text,
        }),
      );

      print("🟢 PERSONA STATUS: ${response.statusCode}");
      print("🟢 BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        personaRegistrada = {
          "id": data["persona_id"],
          "emergencia": emergenciaController.text,
        };

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Persona registrada en la BD')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      print("🔥 ERROR HTTP PERSONA: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Persona')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: cedulaController,
              decoration: const InputDecoration(labelText: 'Cédula'),
            ),
            TextField(
              controller: nombresController,
              decoration: const InputDecoration(labelText: 'Nombres'),
            ),
            TextField(
              controller: apellidosController,
              decoration: const InputDecoration(labelText: 'Apellidos'),
            ),
            const SizedBox(height: 10),
            const Text('Género',
                style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile(
              title: const Text('Masculino'),
              value: 'M',
              groupValue: generoSeleccionado,
              onChanged: (v) => setState(() => generoSeleccionado = v!),
            ),
            RadioListTile(
              title: const Text('Femenino'),
              value: 'F',
              groupValue: generoSeleccionado,
              onChanged: (v) => setState(() => generoSeleccionado = v!),
            ),
            TextField(
              controller: edadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Edad'),
            ),
            TextField(
              controller: celularController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Celular'),
            ),
            TextField(
              controller: emergenciaController,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Contacto de Emergencia'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: guardarPersona,
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }
}
