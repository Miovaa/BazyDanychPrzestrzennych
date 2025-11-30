-- Ładowanie danych rastrowych
-- 1) Ładowanie wysokości - ładowanie rastru przy użyciu pliku .sql
"C:\Program Files\PostgreSQL\18\bin\raster2pgsql.exe" -s 3763 -N -32767 -t 100x100 -I -C -M -d "C:\Users\maris\Desktop\Uczelnia\Cwiczenia6\PostGIS raster - dane\srtm_1arc_v3.tif" rasters.dem > "C:\Users\maris\Desktop\Uczelnia\Cwiczenia6\PostGIS raster - dane\dem.sql"
-- 2) Ładowanie wysokości - ładowanie rastru bezpośrednio do bazy
"C:\Program Files\PostgreSQL\18\bin\raster2pgsql.exe" -s 3763 -N -32767 -t 100x100 -I -C -M -d "C:\Users\maris\Desktop\Uczelnia\Cwiczenia6\PostGIS raster - dane\srtm_1arc_v3.tif" rasters.dem | psql -d Rasters_data -h localhost -U postgres -p 5432

-- ZAŁADOWAŁO SIĘ!!!!!
SELECT count(*) FROM rasters.dem;

-- 3) Ładowanie wysokości - załadowanie danych landsat 8 o wielkości kafelka 128x128 bezpośrednio do bazy danych
"C:\Program Files\PostgreSQL\18\bin\raster2pgsql.exe" -s 3763 -N -32767 -t 128x128 -I -C -M -d "C:\Users\maris\Desktop\Uczelnia\Cwiczenia6\PostGIS raster - dane\Landsat8_L1TP_RGBN.tif" rasters.landsat8 | psql -d Rasters_data -h localhost -U postgres -p 5432

-- ZAŁADOWAŁO SIĘ!!!!!
SELECT count(*) FROM rasters.landsat8;

-- Tworzenie rastrów z istniejących rastrów i interakcja z wektorami
-- 1) Przecięcie rastra z wektorem
CREATE TABLE schema_name.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

SELECT * FROM schema_name.intersects

-- 2) dodanie serial primary key:
alter table schema_name.intersects
add column rid SERIAL PRIMARY KEY;

-- 3) utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON schema_name.intersects
USING gist (ST_ConvexHull(rast));

-- 4) dodanie raster constraints
-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('schema_name'::name,
'intersects'::name,'rast'::name);

-- Obcinanie rastra na podstawie wektora
CREATE TABLE schema_name.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

-- Połączenie wielu kafelków w jeden raster
CREATE TABLE schema_name.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

-- Tworzenie rastrów z wektorów (rastrowanie) 
-- 1) ST_AsRaster
CREATE TABLE schema_name.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- 2) ST_Union
DROP TABLE schema_name.porto_parishes; --> drop table porto_parishes first
CREATE TABLE schema_name.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- 3) ST_Tile
DROP TABLE schema_name.porto_parishes; --> drop table porto_parishes first
CREATE TABLE schema_name.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- Konwertowanie rastrów na wektory (wektoryzowanie)
-- 1) ST_Intersection
CREATE TABLE schema_name.intersection AS
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- 2) ST_DumpAsPolygons
CREATE TABLE schema_name.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(
ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Analiza rastrów
-- 1) ST_Band
CREATE TABLE schema_name.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

-- 2) ST_Clip
CREATE TABLE schema_name.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- 3) ST_Slope
CREATE TABLE schema_name.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM schema_name.paranhos_dem AS a;

-- 4) ST_Reclass
CREATE TABLE schema_name.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM schema_name.paranhos_slope AS a;

-- 5) ST_SummaryStats
SELECT st_summarystats(a.rast) AS stats
FROM schema_name.paranhos_dem AS a;

-- 6) ST_SummaryStats oraz ST_Union
SELECT st_summarystats(ST_Union(a.rast))
FROM schema_name.paranhos_dem AS a;

-- 7) ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM schema_name.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

-- 8) ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

-- 9) ST_Value
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

-- Topographic Position Index (TPI)
-- 1) ST_TPI
CREATE TABLE schema_name.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;

-- Tworzenie indeksu przestrzennego
CREATE INDEX idx_tpi30_rast_gist ON schema_name.tpi30
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów:
SELECT AddRasterConstraints('schema_name'::name,
'tpi30'::name,'rast'::name);

-- ZADANIE 
-- Przetwarzanie poprzedniego zapytania może potrwać dłużej niż minutę, a niektóre zapytania mogą
-- potrwać zbyt długo. W celu skrócenia czasu przetwarzania czasami można ograniczyć obszar
-- zainteresowania i obliczyć mniejszy region. Dostosuj zapytanie z przykładu 10, aby przetwarzać tylko
-- gminę Porto. Musisz użyć ST_Intersects, sprawdź Przykład 1 - ST_Intersects w celach informacyjnych.
-- Porównaj różne czasy przetwarzania. Na koniec sprawdź wynik w QGIS.

CREATE TABLE schema_name.tpi30_porto AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

-- Dodanie indeksu przestrzennego:
CREATE INDEX idx_tpi30_porto_rast_gist ON schema_name.tpi30_porto
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów:
SELECT AddRasterConstraints('schema_name'::name,
'tpi30_porto'::name,'rast'::name);

-- Algebra map
-- 1) Wyrażenie Algebry Map
CREATE TABLE schema_name.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

-- Poniższe zapytanie utworzy indeks przestrzenny na wcześniej stworzonej tabeli:
CREATE INDEX idx_porto_ndvi_rast_gist ON schema_name.porto_ndvi
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów
ELECT AddRasterConstraints('schema_name'::name,
'porto_ndvi'::name,'rast'::name);

-- 2) Funkcja zwrotna
CREATE OR REPLACE FUNCTION schema_name.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug
purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

-- Wywołanie funkcji
CREATE TABLE schema_name.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'schema_name.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
) AS rast
FROM r;

-- Dodanie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi2_rast_gist ON schema_name.porto_ndvi2
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów
SELECT AddRasterConstraints('schema_name'::name,
'porto_ndvi2'::name,'rast'::name);

-- Funkcje TPI
-- 1) ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM schema_name.porto_ndvi;

-- 2) ST_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM schema_name.porto_ndvi;

-- 3) Zapisywanie danych na dysku za pomocą dużego obiektu (large object, lo)
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM schema_name.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'G:\myraster.tiff') --> Save the file in a place
where the user postgres have access. In windows a flash drive usualy works
fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

-- 4) Użycie GDAL
gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9
PG:"host=localhost port=5432 dbname=postgis_raster user=postgres
password=postgis schema=schema_name table=porto_ndvi mode=2"
porto_ndvi.tiff

-- Publikowanie danych za pomocą MapServer
-- 1) Mapfile
MAP
NAME 'map'
SIZE 800 650
STATUS ON
EXTENT -58968 145487 30916 206234
UNITS METERS
WEB
METADATA
'wms_title' 'Terrain wms'
'wms_srs' 'EPSG:3763 EPSG:4326 EPSG:3857'
'wms_enable_request' '*'
'wms_onlineresource'
'http://54.37.13.53/mapservices/srtm'
END
END
PROJECTION
'init=epsg:3763'
END
LAYER
NAME srtm
TYPE raster
STATUS OFF
DATA "PG:host=localhost port=5432 dbname='postgis_raster'
user='sasig' password='postgis' schema='rasters' table='dem' mode='2'"
PROCESSING "SCALE=AUTO"
PROCESSING "NODATA=-32767"
OFFSITE 0 0 0
METADATA
'wms_title' 'srtm'
END
END
END