import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// ================= PERSONA REGISTRADA EN MEMORIA =================
Map<String, dynamic>? personaRegistrada;

// Número de emergencia por defecto (ECU 911)
const String numeroEmergenciaDefecto = "911";

void main() {
  runApp(const MyApp());
}

// ================= APP PRINCIPAL =================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Seguridad Riobamba',
      home: const HomePage(),
    );
  }
}

// ================= PANTALLA PRINCIPAL =================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // FUNCIÓN DEL BOTÓN DE PÁNICO
  Future<void> reportarAsalto() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('GPS desactivado');
      return;
    }

    // Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Permiso de ubicación denegado');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Permiso denegado permanentemente');
      return;
    }

    // Obtener ubicación
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    debugPrint("Latitud: ${position.latitude}");
    debugPrint("Longitud: ${position.longitude}");

    // 📞 Elegir número de llamada
    String telefonoLlamada;

    if (personaRegistrada == null) {
      // No registrado → número por defecto
      telefonoLlamada = numeroEmergenciaDefecto;
      debugPrint('Llamada a emergencia por defecto');
    } else {
      // Registrado → contacto de emergencia
      telefonoLlamada = personaRegistrada!['emergencia'];
      debugPrint('Llamada a contacto registrado');
    }

    final Uri tel = Uri.parse("tel:$telefonoLlamada");
    await launchUrl(tel);
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
            // BOTÓN DE PÁNICO (SIEMPRE ACTIVO)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(40),
              ),
              onPressed: reportarAsalto,
              child: const Text(
                'REPORTAR ASALTO',
                style: TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(height: 20),

            // BOTÓN REGISTRO
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistroPersonaPage(),
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

// ================= PANTALLA REGISTRO PERSONA =================
class RegistroPersonaPage extends StatefulWidget {
  const RegistroPersonaPage({super.key});

  @override
  State<RegistroPersonaPage> createState() => _RegistroPersonaPageState();
}

class _RegistroPersonaPageState extends State<RegistroPersonaPage> {
  final TextEditingController cedulaController = TextEditingController();
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  String generoSeleccionado = 'M';
  final TextEditingController edadController = TextEditingController();
  final TextEditingController celularController = TextEditingController();
  final TextEditingController emergenciaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Persona'),
      ),
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
            const Text(
              'Género',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text('Masculino'),
              value: 'M',
              groupValue: generoSeleccionado,
              onChanged: (value) {
                setState(() {
                  generoSeleccionado = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Femenino'),
              value: 'F',
              groupValue: generoSeleccionado,
              onChanged: (value) {
                setState(() {
                  generoSeleccionado = value!;
                });
              },
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
              onPressed: () {
                personaRegistrada = {
                  "cedula": cedulaController.text,
                  "nombres": nombresController.text,
                  "apellidos": apellidosController.text,
                  "genero": generoSeleccionado,
                  "edad": edadController.text,
                  "celular": celularController.text,
                  "emergencia": emergenciaController.text,
                };

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Persona registrada correctamente')),
                );

                Navigator.pop(context);
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }
}
