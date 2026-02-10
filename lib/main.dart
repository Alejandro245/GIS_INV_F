import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ================= CONFIG API =================
const String personaUrl =
    "https://katabolically-tuberculate-karen.ngrok-free.dev/persona";

const String asaltoUrl =
    "https://katabolically-tuberculate-karen.ngrok-free.dev/asalto";

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

  // ===== OBTENER UBICACIÓN REAL (ANDROID 12 OK) =====
  Future<Position?> obtenerUbicacionReal() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return null;
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print("❌ ERROR GPS REAL: $e");
      return null;
    }
  }

  // ===== REPORTAR ASALTO (CORREGIDO) =====
  Future<void> reportarAsalto(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Obteniendo ubicación GPS...')),
    );

    final position = await obtenerUbicacionReal();

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener ubicación')),
      );
      return;
    }

    // ===== JSON DINÁMICO (CLAVE PARA ANDROID 12) =====
    final Map<String, dynamic> body = {
      "descripcion": "Asalto reportado desde Flutter",
      "lat": position.latitude,
      "lng": position.longitude,
    };

    if (personaRegistrada != null) {
      body["persona_id"] = personaRegistrada!["id"];
    }

    print("📦 JSON ENVIADO: $body");

    try {
      final response = await http.post(
        Uri.parse(asaltoUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("📨 STATUS: ${response.statusCode}");
      print("📨 BODY: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Error backend");
      }
    } catch (e) {
      print("🔥 ERROR POST: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error enviando asalto')),
      );
      return;
    }

    // ===== LLAMADA DE EMERGENCIA =====
    final String telefono = personaRegistrada == null
        ? numeroEmergenciaDefecto
        : personaRegistrada!["emergencia"];

    final Uri dialUri = Uri(
      scheme: 'tel',
      path: telefono,
    );

    await launchUrl(
      dialUri,
      mode: LaunchMode.externalApplication,
    );
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
                style: TextStyle(fontSize: 22, color: Colors.white),
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
    if (edadController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(personaUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "cedula": cedulaController.text,
          "nombres": nombresController.text,
          "apellidos": apellidosController.text,
          "genero": generoSeleccionado,
          "edad": int.parse(edadController.text),
          "celular": celularController.text,
          "contacto_emergencia": emergenciaController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        personaRegistrada = {
          "id": data["persona_id"],
          "emergencia": emergenciaController.text,
        };
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error registrando persona')),
      );
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
