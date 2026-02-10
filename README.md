# GIS_INV_F

Configuración rápida para visualizar en **GeoServer** el mapa urbano de Riobamba con:
- **Calles**
- **Lugares (POI)**
- **Puntos de asalto** reportados desde la app/API

## 1) Requisitos

- PostgreSQL + PostGIS
- GeoServer (2.22+ recomendado)
- Base de datos `Riobamba` con tabla `asalto` (ya usada por `api/index.js`)
- Datos OSM importados en PostGIS en dos tablas:
  - `osm_roads` (líneas de calles)
  - `osm_places` (puntos de lugares)

> Si aún no tienes `osm_roads` y `osm_places`, puedes importarlas desde un GeoJSON/OSM exportado de Riobamba usando `ogr2ogr`.

## 2) Crear vistas para GeoServer

Ejecuta el script:

```bash
psql -U postgres -d Riobamba -f geoserver/sql/riobamba_capas.sql
```

Este script crea:
- `geoserver.v_riobamba_calles`
- `geoserver.v_riobamba_lugares`
- `geoserver.v_puntos_asalto`

## 3) Publicar capas en GeoServer

1. Entra a GeoServer (`http://localhost:8080/geoserver`).
2. Crea un **Workspace**: `riobamba`.
3. Crea un **Store** tipo PostGIS apuntando a la BD `Riobamba`.
4. Publica estas capas desde el esquema `geoserver`:
   - `v_riobamba_calles`
   - `v_riobamba_lugares`
   - `v_puntos_asalto`
5. Para cada capa, en *Coordinate Reference Systems* usa `EPSG:4326`.

## 4) Aplicar estilos SLD

En GeoServer > **Styles**, crea/importa:
- `geoserver/styles/calles_riobamba.sld`
- `geoserver/styles/lugares_riobamba.sld`
- `geoserver/styles/puntos_asalto.sld`

Asigna:
- `v_riobamba_calles` → `calles_riobamba`
- `v_riobamba_lugares` → `lugares_riobamba`
- `v_puntos_asalto` → `puntos_asalto`

## 5) Orden recomendado de visualización

1. `v_riobamba_calles` (abajo)
2. `v_riobamba_lugares`
3. `v_puntos_asalto` (arriba, en rojo)

Con este orden se visualiza el mapa urbano de Riobamba con calles/lugares y se destacan los puntos de asalto.

## API de asaltos

La API que inserta puntos en `asalto` está en:
- `api/index.js` endpoint `POST /asalto`

Cada nuevo reporte queda disponible automáticamente en la capa `v_puntos_asalto` publicada en GeoServer.
