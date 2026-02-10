-- Configuración de vistas para publicar en GeoServer
-- Requiere:
-- 1) Tabla asalto(id, descripcion, persona_id, geom geometry(Point,4326))
-- 2) Tablas de OpenStreetMap importadas en PostGIS:
--    osm_roads(geom geometry(LineString,4326), name text, highway text)
--    osm_places(geom geometry(Point,4326), name text, place text, amenity text, tourism text, shop text)

CREATE SCHEMA IF NOT EXISTS geoserver;

-- Límite urbano aproximado de Riobamba (EPSG:4326)
-- xmin, ymin, xmax, ymax
-- -78.7040, -1.7030, -78.5930, -1.6160

CREATE OR REPLACE VIEW geoserver.v_riobamba_calles AS
SELECT
  ROW_NUMBER() OVER () AS fid,
  name,
  highway,
  geom
FROM osm_roads
WHERE
  highway IS NOT NULL
  AND geom && ST_MakeEnvelope(-78.7040, -1.7030, -78.5930, -1.6160, 4326);

CREATE OR REPLACE VIEW geoserver.v_riobamba_lugares AS
SELECT
  ROW_NUMBER() OVER () AS fid,
  COALESCE(name, 'Sin nombre') AS nombre,
  place,
  amenity,
  tourism,
  shop,
  geom
FROM osm_places
WHERE
  (place IS NOT NULL OR amenity IS NOT NULL OR tourism IS NOT NULL OR shop IS NOT NULL)
  AND geom && ST_MakeEnvelope(-78.7040, -1.7030, -78.5930, -1.6160, 4326);

CREATE OR REPLACE VIEW geoserver.v_puntos_asalto AS
SELECT
  id AS fid,
  descripcion,
  persona_id,
  geom
FROM asalto
WHERE geom IS NOT NULL;

-- Índices recomendados si las tablas base no los tienen
CREATE INDEX IF NOT EXISTS idx_osm_roads_geom ON osm_roads USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_osm_places_geom ON osm_places USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_asalto_geom ON asalto USING GIST (geom);
