-- Załadowanie danych do bazy
raster2pgsql -I -C -M -d "C:\ścieżka\do\rastrów\data\*" public.uk_250k | psql -d Rasters_data -h localhost -U postgres -p 5432

-- Sprawdzenie danych
SELECT COUNT(*) FROM uk_250k; 

-- 3) Stworzenie mozaiki i wyeksportowanie GeoTIFF

-- Eksport mozaiki (w CMD)
cd "sciezka do folderu"
gdal_translate PG:"dbname=Rasters_data user=postgres password=xxx schema=public table=uk_250k_mosaic" uk_250k_mosaic.tif

-- Sprawdzenie mozaiki (w CMD)
gdalbuildvrt uk_250k_mosaic.vrt "C:\ścieżka\do\rastrów\*.tif"

gdal_translate -of GTiff uk_250k_mosaic.vrt uk_250k_mosaic.tif

-- Załadowanie do bazy danych
raster2pgsql -s 27700 -N 9999 -t 1000x1000 "uk_250k_mosaic.tif" public.uk_250k_mosaic | psql -d Rasters_data -h localhost -U postgres -p 5432
SELECT COUNT(*) FROM uk_250k_mosaic; --896 wyników

-- 4) Pobranie danych z OS Open Stock Zoomstack
SELECT * FROM "OS_Open_Zoomstack — national_parks";

CREATE TABLE lake_district AS
	SELECT *
	FROM "OS_Open_Zoomstack — national_parks"
	WHERE id=7

SELECT * FROM lake_district;

-- 6) Utwórz nową tabelę o nazwie uk_lake_district, do której zaimportujesz mapy rastrowe
-- z punktu 1., które zostaną przycięte do granic parku narodowego Lake District.
CREATE TABLE uk_lake_district AS
SELECT ST_Clip(rast, 1, geom, true) AS rast
FROM uk_250k_mosaic, lake_district;

SELECT * FROM uk_lake_district;
	
