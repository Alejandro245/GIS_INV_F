const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
app.use(cors());
app.use(express.json());

// ================= CONEXIÓN A POSTGRESQL =================
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'Riobamba',
  password: '1234',
  port: 5432,
});

// ================= PRUEBA DE API =================
app.get('/', (req, res) => {
  res.send('API Riobamba funcionando');
});

// ================= REGISTRAR PERSONA =================
app.post('/persona', async (req, res) => {
  try {
    const {
      cedula,
      nombres,
      apellidos,
      genero,
      edad,
      celular,
      contacto_emergencia,
    } = req.body;

    const result = await pool.query(
      `INSERT INTO persona
       (cedula, nombres, apellidos, genero, edad, celular, contacto_emergencia)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING id`,
      [cedula, nombres, apellidos, genero, edad, celular, contacto_emergencia]
    );

    res.status(201).json({ persona_id: result.rows[0].id });
  } catch (error) {
    console.error("🔥 ERROR /persona:", error);
    res.status(500).json({ error: 'Error al registrar persona' });
  }
});

// ================= REGISTRAR ASALTO (CORREGIDO) =================
app.post('/asalto', async (req, res) => {
  console.log("📥 POST /asalto recibido");
  console.log("📦 BODY:", req.body);

  try {
    const { descripcion, lat, lng } = req.body;
    let { persona_id } = req.body;

    // ===== VALIDACIONES BÁSICAS =====
    if (!descripcion || lat === undefined || lng === undefined) {
      return res.status(400).json({
        error: "descripcion, lat y lng son obligatorios"
      });
    }

    // ===== NORMALIZAR persona_id =====
    if (persona_id === undefined || persona_id === null) {
      persona_id = null;
    }

    console.log("📍 Datos normalizados:", {
      descripcion,
      persona_id,
      lat,
      lng
    });

    const result = await pool.query(
      `INSERT INTO asalto (descripcion, persona_id, geom)
       VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326))
       RETURNING id`,
      [descripcion, persona_id, lng, lat]
    );

    console.log("✅ ASALTO INSERTADO, ID:", result.rows[0].id);

    res.status(201).json({
      ok: true,
      asalto_id: result.rows[0].id
    });

  } catch (error) {
    console.error("🔥 ERROR REAL EN /asalto:", error);
    res.status(500).json({
      error: error.message,
      detail: error.detail
    });
  }
});

// ================= INICIAR SERVIDOR =================
app.listen(3000, () => {
  console.log('API corriendo en http://localhost:3000');
});
