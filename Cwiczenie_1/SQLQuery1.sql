-- 1. Stworzenie bazy danych
CREATE DATABASE firma;
-- 2. Użycie tej bazy
USE firma;

-- 3. Stworzenie schematu
CREATE SCHEMA ksiegowosc;

-- 4. Tabela pracownicy
CREATE TABLE ksiegowosc.pracownicy (
	id_pracownika INT PRIMARY KEY,
	imie VARCHAR(25),
	nazwisko VARCHAR(30),
	adres VARCHAR(50),
	telefon VARCHAR(20)
);

-- 5. Tabela godziny
CREATE TABLE ksiegowosc.godziny (
	id_godziny int PRIMARY KEY,
	[data] date, 
	liczba_godzin int,
	id_pracownika int FOREIGN KEY REFERENCES ksiegowosc.pracownicy(id_pracownika)
);

-- 6. Tabela pensja
CREATE TABLE ksiegowosc.pensja (
	id_pensji int PRIMARY KEY,
	stanowisko varchar(20),
	kwota decimal(10,2)
);

-- 7. Tabela premia
CREATE TABLE ksiegowosc.premia (
	id_premii int PRIMARY KEY,
	rodzaj varchar(20),
	kwota decimal(10,2)
);

-- 8. Tabela wynagrodzenie
CREATE TABLE ksiegowosc.wynagrodzenie (
	id_wynagrodzenia int PRIMARY KEY,
	"data" date,
	id_pracownika int FOREIGN KEY REFERENCES ksiegowosc.pracownicy(id_pracownika),
	id_godziny int FOREIGN KEY REFERENCES ksiegowosc.godziny(id_godziny),
	id_pensji int FOREIGN KEY REFERENCES ksiegowosc.pensja(id_pensji),
	id_premii int FOREIGN KEY REFERENCES ksiegowosc.premia(id_premii)
);

-- Tabela pracownicy:
INSERT INTO ksiegowosc.pracownicy VALUES
(1, 'Anna', 'Kowalska', 'ul. Długa 1, Warszawa', '500123123'),
(2, 'Jan', 'Nowak', 'ul. Krótka 3, Kraków', '501111222'),
(3, 'Ewa', 'Wiśniewska', 'ul. Leśna 7, Gdańsk', '502222333'),
(4, 'Tomasz', 'Zieliński', 'ul. Polna 2, Łódź', '503333444'),
(5, 'Karolina', 'Wójcik', 'ul. Kwiatowa 5, Poznań', '504444555'),
(6, 'Marek', 'Kamiński', 'ul. Wąska 9, Wrocław', '505555666'),
(7, 'Monika', 'Lewandowska', 'ul. Jasna 6, Lublin', '506666777'),
(8, 'Paweł', 'Dąbrowski', 'ul. Szeroka 4, Szczecin', '507777888'),
(9, 'Agnieszka', 'Krawczyk', 'ul. Zaciszna 3, Rzeszów', '508888999'),
(10, 'Rafał', 'Piotrowski', 'ul. Spokojna 2, Białystok', '509999000');

-- Tabela godziny
INSERT INTO ksiegowosc.godziny VALUES
(1, '2025-10-01', 90, 1),
(2, '2025-10-15', 80, 1),     
(3, '2025-10-01', 100, 2),
(4, '2025-10-15', 50, 2),     
(5, '2025-10-01', 100, 3),
(6, '2025-10-15', 80, 3),     
(7, '2025-10-01', 60, 4),
(8, '2025-10-01', 60, 5),
(9, '2025-10-01', 50, 6),
(10, '2025-10-01', 60, 7);

-- Tabela pensja
INSERT INTO ksiegowosc.pensja VALUES
(1, 'Księgowy', 4500.00),       
(2, 'Asystent', 2800.00),       
(3, 'Manager', 7000.00),
(4, 'Specjalista', 5000.00),
(5, 'Analityk', 1800.00),       
(6, 'Praktykant', 1100.00),     
(7, 'Kierownik', 6500.00),
(8, 'Sekretarka', 3000.00),     
(9, 'HR', 4200.00),
(10, 'IT', 6000.00);


-- Tabela premia
INSERT INTO ksiegowosc.premia VALUES
(1, 'Brak', 0.00),
(2, 'Świąteczna', 500.00),
(3, 'Uz uznaniowa', 300.00),
(4, 'Roczna', 1000.00),
(5, 'Projektowa', 700.00),
(6, 'Brak', 0.00),
(7, 'Specjalna', 800.00),
(8, 'Motywacyjna', 400.00),
(9, 'Za nadgodziny', 350.00),
(10, 'Brak', 0.00);

-- Tabela wynagrodzenie
INSERT INTO ksiegowosc.wynagrodzenie VALUES
(1, '2025-10-01', 1, 1, 1, 2),  
(2, '2025-10-01', 2, 2, 2, 1),  
(3, '2025-10-01', 3, 3, 3, 4),  
(4, '2025-10-01', 4, 4, 4, 1),  
(5, '2025-10-01', 5, 5, 5, 5),  
(6, '2025-10-01', 6, 6, 6, 1),  
(7, '2025-10-01', 7, 7, 7, 7),
(8, '2025-10-01', 8, 8, 8, 6),
(9, '2025-10-01', 9, 9, 9, 9),
(10, '2025-10-01', 10, 10, 10, 1);

-- Sprawdzenie poprawnosci
SELECT * FROM ksiegowosc.godziny

-- #######################################################
--a) Wyświetl tylko id pracownika oraz jego nazwisko.
SELECT id_pracownika, nazwisko FROM ksiegowosc.pracownicy

--b) Wyświetl id pracowników, których płaca jest większa niż 1000.
SELECT DISTINCT w.id_pracownika 
FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja p ON w.id_pensji = p.id_pensji
WHERE p.kwota > 1000

--c) Wyświetl id pracowników nieposiadających premii, których płaca jest większa niż 2000.
SELECT DISTINCT w.id_pracownika
FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja p ON w.id_pensji = p.id_pensji
WHERE p.kwota > 2000
  AND (w.id_premii = 1 OR w.id_premii IS NULL);

--d) Wyświetl pracowników, których pierwsza litera imienia zaczyna się na literę ‘J’.
SELECT *
FROM ksiegowosc.pracownicy
WHERE imie LIKE 'J%';

--e) Wyświetl pracowników, których nazwisko zawiera literę ‘n’ oraz imię kończy się na literę ‘a’.
SELECT *
FROM ksiegowosc.pracownicy
WHERE imie LIKE '%a' AND nazwisko LIKE '%n%';

--f) Wyświetl imię i nazwisko pracowników oraz liczbę ich nadgodzin, przyjmując, iż standardowy czas pracy to 160h miesięcznie.
SELECT p.imie, p.nazwisko, SUM(g.liczba_godzin) - 160 AS nadgodziny
FROM ksiegowosc.pracownicy p
JOIN ksiegowosc.godziny g ON p.id_pracownika = g.id_pracownika
GROUP BY 
	p.imie,
	p.nazwisko,
	YEAR(g.data),
	MONTH(g.data)
HAVING SUM(g.liczba_godzin) > 160
ORDER BY p.nazwisko, p.imie

--g) Wyświetl imię i nazwisko pracowników, których pensja zawiera się w przedziale 1500 – 3000 PLN.
SELECT p.imie, p.nazwisko
FROM ksiegowosc.pracownicy p
JOIN ksiegowosc.wynagrodzenie w ON w.id_pracownika = p.id_pracownika
JOIN ksiegowosc.pensja pe ON pe.id_pensji = w.id_pensji
WHERE pe.kwota BETWEEN 1500 AND 3000

--h) Wyświetl imię i nazwisko pracowników, którzy pracowali w nadgodzinach i nie otrzymali premii.
SELECT DISTINCT p.imie, p.nazwisko
FROM ksiegowosc.pracownicy p
JOIN ksiegowosc.wynagrodzenie w ON p.id_pracownika = w.id_pracownika
JOIN (
    SELECT 
        g.id_pracownika,
        YEAR(g.data) AS rok,
        MONTH(g.data) AS miesiac
    FROM ksiegowosc.godziny g
    GROUP BY g.id_pracownika, YEAR(g.data), MONTH(g.data)
    HAVING SUM(g.liczba_godzin) > 160
) n ON p.id_pracownika = n.id_pracownika
     AND YEAR(w.data) = n.rok
     AND MONTH(w.data) = n.miesiac
WHERE w.id_premii IS NULL OR w.id_premii = 1;

--i) Uszereguj pracowników według pensji.
SELECT p.id_pracownika, p.imie, p.nazwisko, p.adres, p.telefon
FROM ksiegowosc.pracownicy p
JOIN ksiegowosc.wynagrodzenie w ON w.id_pracownika = p.id_pracownika
JOIN ksiegowosc.pensja pe ON pe.id_pensji = w.id_pensji
ORDER BY pe.kwota ASC

--j) Uszereguj pracowników według pensji i premii malejąco.
SELECT p.id_pracownika, p.imie, p.nazwisko, p.adres, p.telefon
FROM ksiegowosc.pracownicy p
JOIN ksiegowosc.wynagrodzenie w ON w.id_pracownika = p.id_pracownika
JOIN ksiegowosc.pensja pe ON pe.id_pensji = w.id_pensji
LEFT JOIN ksiegowosc.premia pr ON pr.id_premii = w.id_premii
ORDER BY pe.kwota DESC, pr.kwota DESC

--k) Zlicz i pogrupuj pracowników według pola ‘stanowisko’.
SELECT pe.stanowisko, COUNT(DISTINCT w.id_pracownika) AS liczba_pracownikow
FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja pe ON pe.id_pensji = w.id_pensji
GROUP BY pe.stanowisko

--l) Policz średnią, minimalną i maksymalną płacę dla stanowiska ‘kierownik’ (jeżeli takiego nie masz, to przyjmij dowolne inne).
SELECT
	AVG(pe.kwota) AS srednia_pensja,
	MIN(pe.kwota) AS minimalna_pensja,
	MAX(pe.kwota) AS maksymalna_pensja
FROM ksiegowosc.pensja pe
WHERE pe.stanowisko = 'kierownik';

--m) Policz sumę wszystkich wynagrodzeń.
SELECT SUM(pe.kwota + ISNULL(pr.kwota,0)) AS suma_wynagrodzen
FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja pe ON pe.id_pensji = w.id_pensji
LEFT JOIN ksiegowosc.premia pr ON pr.id_premii = w.id_premii

--f) Policz sumę wynagrodzeń w ramach danego stanowiska.
SELECT pe.stanowisko, SUM(pe.kwota + ISNULL(pr.kwota,0)) AS suma_wynagrodzen
FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja pe ON pe.id_pensji = w.id_pensji
LEFT JOIN ksiegowosc.premia pr ON pr.id_premii = w.id_premii
GROUP BY pe.stanowisko

--g) Wyznacz liczbę premii przyznanych dla pracowników danego stanowiska.
SELECT pe.stanowisko, COUNT(w.id_premii) AS liczba_premii
FROM ksiegowosc.wynagrodzenie w
JOIN ksiegowosc.pensja pe ON pe.id_pensji = w.id_pensji
WHERE w.id_premii IS NOT NULL
GROUP BY pe.stanowisko

--h) Usuń wszystkich pracowników mających pensję mniejszą niż 1200 zł.
DELETE p
FROM ksiegowosc.pracownicy p
JOIN ksiegowosc.wynagrodzenie w ON w.id_pracownika = p.id_pracownika
JOIN ksiegowosc.pensja pe ON pe.id_pensji = w.id_pensji
WHERE pe.kwota < 1200

-- Usuniecie bazy danych
DELETE FROM ksiegowosc.wynagrodzenie;
DELETE FROM ksiegowosc.godziny;
DELETE FROM ksiegowosc.premia;
DELETE FROM ksiegowosc.pensja;
DELETE FROM ksiegowosc.pracownicy;
