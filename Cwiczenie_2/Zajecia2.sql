-- Tabela buildings
CREATE TABLE buildings (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255),
	geometry GEOMETRY(POLYGON)
);

-- Tabela roads
CREATE TABLE roads (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255),
	geometry GEOMETRY(LINESTRING)
);

-- Tabela poi (Points of Interest)
CREATE TABLE poi (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255),
	geometry GEOMETRY(POINT)
);


-- Dodanie danych do tabeli (buildings)
INSERT INTO buildings (name, geometry) VALUES
('BuildingA', ST_GeomFromText('POLYGON((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))')),
('BuildingB', ST_GeomFromText('POLYGON((4.5 5, 6 5, 6 7, 4 7, 4.5 5))')),
('BuildingC', ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))')),
('BuildingD', ST_GeomFromText('POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))')),
('BuildingF', ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))'));

-- Dodanie danych do tabeli (roads)
INSERT INTO roads (name, geometry) VALUES
('RoadY', ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)')),
('RoadX', ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)'));

-- Dodanie danych do tabeli (poi)
INSERT INTO poi (name, geometry) VALUES
('G', ST_GeomFromText('POINT(1 3.5)')),
('H', ST_GeomFromText('POINT(5.5 1.5)')),
('I', ST_GeomFromText('POINT(9.5 6)')),
('J', ST_GeomFromText('POINT(6.5 6)')),
('K', ST_GeomFromText('POINT(6 9.5)'));

-- Sprawdzenie
SELECT * FROM poi;

-- ZADANIA

-- a) Wyznacz całkowitą długość dróg w analizowanym mieście.
SELECT SUM(St_Length(geometry)) AS total_length FROM roads;

-- b) Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA.
SELECT 
	ST_AsText(geometry) AS WKT_geometry,
	ST_Area(geometry) AS area,
	ST_Perimeter(geometry) AS perimeter
FROM buildings
WHERE name = 'BuildingA';

-- c) Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.
SELECT
	name,
	ST_Area(geometry) AS area
FROM buildings
ORDER by name ASC;

-- d) Wypisz nazwy i obwody 2 budynków o największej powierzchni.
SELECT
	name,
	ST_Area(geometry) AS area
FROM buildings
ORDER BY area DESC
LIMIT 2;

-- e) Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem K.
SELECT ST_Distance(
	(SELECT geometry FROM buildings WHERE name = 'BuildingC'),
	(SELECT geometry FROM poi WHERE name = 'K')
) AS shortest_path;

-- f) Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej
-- niż 0.5 od budynku BuildingB.
SELECT ST_Area(
	ST_Difference(
	(SELECT geometry FROM buildings WHERE name = 'BuildingC'), 
	ST_Buffer((SELECT geometry FROM buildings WHERE name = 'BuildingB'), 0.5)
	)
) AS area;

-- g) Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi o nazwie RoadX.
SELECT
	name
FROM buildings
WHERE 
	ST_Y(ST_Centroid(geometry)) > (SELECT ST_Y(ST_StartPoint(geometry)) FROM roads WHERE name = 'RoadX'); 
	
-- h) Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych 
-- (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.
SELECT 
	ST_Area(
		ST_SymDifference(
			(SELECT geometry FROM buildings WHERE name = 'BuildingC'),
			ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')
		)
	) AS area;

-- Usunięcie tabel
DROP TABLE buildings;
DROP TABLE roads;
DROP TABLE poi;