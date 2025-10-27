CREATE EXTENSION postgis;

-- 1) Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana pomiędzy 2018 a 2019)
WITH new_buildings AS (
	SELECT kb2019.* FROM kar_buildings_2019 kb2019
	LEFT JOIN kar_buildings_2018 kb2018 ON ST_Equals(kb2019.geom, kb2018.geom)
	WHERE kb2018.geom IS NULL
),

-- 2) Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub 
-- wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii

-- Nowe poi
new_poi AS (
	SELECT poi2019.* FROM kar_poi_table_2019 poi2019
	LEFT JOIN kar_poi_table_2018 poi2018 ON ST_Equals(poi2019.geom, poi2018.geom)
	WHERE poi2018.geom IS NULL
)

-- w promieniu 500m
SELECT npoi."POI_NAME", COUNT(*) AS poi_count
FROM new_poi npoi
JOIN new_buildings nb ON ST_DWithin(npoi.geom, nb.geom, 500)
GROUP BY npoi."POI_NAME"
ORDER BY poi_count DESC;

-- 3) Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
-- T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini
CREATE TABLE streets_reprojected AS
	SELECT 
		*, 
		ST_Transform(geom, 3068) AS geom_reprojected  
	FROM kar_streets_2019; 

ALTER TABLE streets_reprojected
	DROP COLUMN geom

SELECT * FROM streets_reprojected;
DROP TABLE streets_reprojected;

-- 4) Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej
CREATE TABLE input_points (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255),
	geom geometry(Point, 4326)
);

INSERT INTO input_points(name, geom) VALUES
	('A', ST_SetSRID(ST_MakePoint(8.36093, 49.03174), 4326)),
	('B', ST_SetSRID(ST_MakePoint(8.39876, 49.00644), 4326));

SELECT * FROM input_points;
DROP TABLE input_points;

-- 5) Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych DHDN.Berlin/Cassini
ALTER TABLE input_points
	ALTER COLUMN geom TYPE geometry(Point, 3068)
	USING ST_Transform(geom, 3068)

SELECT * FROM input_points;

-- 6) Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej
-- z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj
-- reprojekcji geometrii, aby była zgodna z resztą tabel.
WITH line_from_points AS (
	SELECT ST_MakeLine(geom) AS geom_line
	FROM input_points
),

streets_node_reprojected AS (
	SELECT
		*,
		ST_Transform(geom, 3068) AS geom_reprojected
	FROM kar_street_node_2019
)

SELECT *
FROM streets_node_reprojected n, line_from_points l
WHERE ST_DWithin(n.geom_reprojected, l.geom_line, 200);

-- 7) Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
-- w odległości 300 m od parków (LAND_USE_A)
SELECT COUNT(DISTINCT p.id) AS counted
FROM kar_poi_table_2019 p
JOIN "kar_land_use_A_2019" l
	ON ST_DWithin(
		ST_Transform(p.geom, 3068),
		ST_Transform(l.geom, 3068),
		300
	)
WHERE p."TYPE" = 'Sporting Goods Store' 
AND l."TYPE" = 'Park (City/County)';

-- 8) Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz
-- znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’
CREATE TABLE T2019_KAR_BRIDGES AS
	SELECT
		r.id AS railway_id,
		w.id AS water_id,
		ST_Intersection(
			ST_Transform(r.geom, 3068),
			ST_Transform(w.geom, 3068)
		) AS geom
	FROM kar_railways_2019 r
	JOIN kar_water_lines_2019 w
	ON ST_Intersects(ST_Transform(r.geom, 3068), ST_Transform(w.geom, 3068));

SELECT * FROM t2019_kar_bridges;
