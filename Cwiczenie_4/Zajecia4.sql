-- CREATE EXTENSION postgis;

CREATE TABLE obiekty (
	id SERIAL PRIMARY KEY,
	nazwa TEXT,
	geom GEOMETRY
);

INSERT INTO obiekty (nazwa, geom)
VALUES (
    'obiekt1',
    ST_GeomFromText('COMPOUNDCURVE(
        (0 1, 1 1), 
        CIRCULARSTRING(1 1, 2 0, 3 1), 
        CIRCULARSTRING(3 1, 4 2, 5 1), 
        (5 1, 6 1)
    )')
);

INSERT INTO obiekty (nazwa, geom)
VALUES (
    'obiekt2',
    ST_GeomFromText(
        'CURVEPOLYGON(
            COMPOUNDCURVE(
                (10 6, 14 6),
                CIRCULARSTRING(14 6, 16 4, 14 2),
                CIRCULARSTRING(14 2, 12 0, 10 2),
                (10 2, 10 6)
            ),
            CIRCULARSTRING(13 2, 12 3, 11 2, 12 1, 13 2)
        )'
    )
);

INSERT INTO obiekty (nazwa, geom)
VALUES (
	'obiekt3',
	ST_GeomFromText('POLYGON((7 15, 10 17, 12 13, 7 15))')
);

INSERT INTO obiekty (nazwa, geom)
VALUES (
    'obiekt4',
    ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)')  
);

INSERT INTO obiekty (nazwa, geom)
VALUES (
	'obiekt5',
	ST_Collect(
		ST_MakePoint(30, 30, 59),
		ST_MakePoint(38, 32, 234)
	)
);

INSERT INTO obiekty (nazwa, geom)
VALUES (
	'obiekt6',
	ST_Collect(
		ST_MakeLine(ST_Point(1,1), ST_Point(3,2)),
		ST_MakePoint(4,2)
	)
);

-- 2) Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół
-- najkrótszej linii łączącej obiekt 3 i 4.
SELECT 
	ST_Area(
		ST_Buffer(
			ST_ShortestLine(
				(SELECT geom FROM obiekty WHERE nazwa='obiekt3'),
				(SELECT geom FROM obiekty WHERE nazwa='obiekt4')
			),
			5.0
		)
	) AS pole_powierzchni;

-- 3) Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to
-- zadanie? Zapewnij te warunki.

-- Warunek: Linia musi być zamknięta -> współrzędne początkowe = współrzędne końcowe
UPDATE obiekty
SET 
	geom = ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5, 20 20)')
WHERE 
	nazwa = 'obiekt4';

-- Zamiana z LINESTRING na POLYGON
UPDATE obiekty
SET 
    nazwa = 'obiekt4_POLYGON',
    geom = ST_MakePolygon(geom)
WHERE 
    nazwa = 'obiekt4';

-- 4) W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.
INSERT INTO obiekty (nazwa, geom)
VALUES (
	'obiekt7',
	ST_Collect(
		(SELECT geom FROM obiekty WHERE nazwa='obiekt3'),
		(SELECT geom FROM obiekty WHERE nazwa='obiekt4')
	)
);

-- 5) Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone
-- wokół obiektów nie zawierających łuków.
SELECT 
	SUM(ST_Area(ST_Buffer(geom, 5.0))) AS area_buffor
FROM
	obiekty
WHERE
	ST_HasArc(geom) = FALSE;

	
