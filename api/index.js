const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
app.use(cors());
app.use(express.json());

// CONEXIÓN A POSTGRESQL
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'Riobamba',
  password: '1234',
  port: 5432,
});

// PRUEBA DE API
app.get('/', (req, res) => {
  res.send('API Riobamba funcionando');
});

// REGISTRAR PERSONA
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

    res.json({ persona_id: result.rows[0].id });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al registrar persona' });
  }
});

// REGISTRAR ASALTO
app.post('/asalto', async (req, res) => {
  try {
    const { descripcion, persona_id, lat, lng } = req.body;

    await pool.query(
      `INSERT INTO asalto (descripcion, persona_id, geom)
       VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326))`,
      [descripcion, persona_id, lng, lat]
    );

    res.json({ mensaje: 'Asalto registrado correctamente' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al registrar asalto' });
  }
});

// INICIAR SERVIDOR
app.listen(3000, () => {
  console.log('API corriendo en http://localhost:3000');
});
