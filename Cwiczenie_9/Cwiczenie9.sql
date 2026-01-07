-- Załadowanie rozszerzeń
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

SELECT * FROM exports;

-- Scalenie rastrów
CREATE TABLE merged_raster AS
    SELECT ST_UNION(rastr)
FROM exports;