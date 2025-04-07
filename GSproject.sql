----Queries used in Translation (for 1 Table)
SET CLIENT_ENCODING TO 'UTF8';

--psql
\copy airportpoly TO 'C:/Users/saiye/Desktop/studieeee/SQL/JAPANESEEEE STUFF/Translations/airport.csv' DELIMITER ',' CSV HEADER

TRUNCATE TABLE airportpoly;

Alter Table airportpoly add column english TEXT;
--psql
\copy airportpoly FROM 'C:/Users/saiye/Desktop/studieeee/SQL/JAPANESEEEE STUFF/Translations/translated_airport.csv' DELIMITER ',' CSV HEADER;

Select * from airportpoly

UPDATE airportpoly
SET english = NULL
WHERE english = '#VALUE!';
--Similarly for other tables also

--01 Proximity analysis
--nearest railway line from Sakura
SELECT
    cb.name,s.id,s.english,ST_Distance(ST_Transform(cb.ptgeom, 3857), 
	ST_Transform(s.lngeom, 3857))/1000 AS distance_km
FROM
   cherry AS cb
CROSS JOIN LATERAL ( --Learnt New Query 
    SELECT
        s.id,s.english,s.lngeom
    FROM
        railway AS s
    ORDER BY
        cb.ptgeom <-> s.lngeom
    LIMIT 1
) AS s;

--nearest airport from Sakura
SELECT
    cb.name,s.id,s.english,ST_Distance(ST_Transform(cb.ptgeom, 3857), 
	ST_Transform(s.polygeom, 3857))/1000 AS distance_km
FROM
   cherry AS cb
CROSS JOIN LATERAL ( 
    SELECT
        s.id,s.english,s.polygeom
    FROM
        airportpoly AS s
    ORDER BY
        cb.ptgeom <-> s.polygeom
    LIMIT 1
) AS s;

--centroid for park polygon
-- for heatmaps
ALTER TABLE parks ADD COLUMN centroid geometry(Point, 4326);
UPDATE parks
SET centroid = ST_Centroid(polygeom);

Create or replace View Park_Centroids as
Select centroid from parks

--02 Proximity analysis
--nearest railway line from firework
SELECT
    cb.name,s.id,s.english,ST_Distance(ST_Transform(cb.ptgeom, 3857), 
	ST_Transform(s.lngeom, 3857))/1000 AS distance_km
FROM
   firework AS cb
CROSS JOIN LATERAL ( 
    SELECT
        s.id,s.english,s.lngeom
    FROM
        railway AS s
		where s.english is not NULL
    ORDER BY
        cb.ptgeom <-> s.lngeom
    LIMIT 1
) AS s;
--nearest airport from fireworks
SELECT
    cb.name,s.id,s.english,ST_Distance(ST_Transform(cb.ptgeom, 3857), 
	ST_Transform(s.polygeom, 3857))/1000 AS distance_km
FROM
   firework AS cb
CROSS JOIN LATERAL ( 
    SELECT
        s.id,s.english,s.polygeom
    FROM
        airportpoly AS s
    ORDER BY
        cb.ptgeom <-> s.polygeom
    LIMIT 1
) AS s;

SELECT * from railway

--centroid for beaches polygon 
-- for heatmaps
ALTER TABLE beachpoly ADD COLUMN centroid geometry(Point, 4326);
UPDATE beachpoly
SET centroid = ST_Centroid(polygeom);

Create or replace View beach_Centroids as
Select centroid from beachpoly

--03 Proximity analysis
--nearest railway line from skiing site
SELECT
    cb.english,s.id,s.english,ST_Distance(ST_Transform(cb.ptgeom, 3857),
	ST_Transform(s.lngeom, 3857))/1000 AS distance_km
FROM
   skiing AS cb
CROSS JOIN LATERAL ( --Learnt New Query 
    SELECT
        s.id,s.english,s.lngeom
    FROM
        railway AS s
		where s.english is not NULL
    ORDER BY
        cb.ptgeom <-> s.lngeom
    LIMIT 1
) AS s;
--nearest airport from skiing site
SELECT
    cb.english,s.id,s.english,ST_Distance(ST_Transform(cb.ptgeom, 3857), 
	ST_Transform(s.polygeom, 3857))/1000 AS distance_km
FROM
   skiing AS cb
CROSS JOIN LATERAL ( 
    SELECT
        s.id,s.english,s.polygeom
    FROM
        airportpoly AS s
    ORDER BY
        cb.ptgeom <-> s.polygeom
    LIMIT 1
) AS s;

SELECT * from skiing




--Travel Networks
--Railway and Airport Accessibility
-- Centroids for airports
CREATE TABLE airport_centroids AS
SELECT ogc_fid, ST_Centroid(polygeom) AS geom
FROM airportpoly;

-- Centroids for railways
CREATE TABLE railway_centroids AS
SELECT ogc_fid, ST_Centroid(lngeom) AS geom
FROM railway;


-- Count airport centroids within each region
Alter table japan add column airport_count REAL DEFAULT 0.0
Alter table japan add column railway_count REAL DEFAULT 0.0

WITH AirportCounts AS (
  SELECT Polys.ogc_fid, COUNT(Airports.ogc_fid) AS airport_count
  FROM japan AS Polys
  LEFT JOIN airport_centroids AS Airports
  ON ST_Contains(Polys.polygeom, Airports.geom)
  GROUP BY Polys.ogc_fid
)
UPDATE japan
SET airport_count = AirportCounts.airport_count
FROM AirportCounts
WHERE japan.ogc_fid = AirportCounts.ogc_fid;

-- Count railway centroids within each region
WITH RailwayCounts AS (
  SELECT Polys.ogc_fid, COUNT(Railways.ogc_fid) AS railway_count
  FROM japan AS Polys
  LEFT JOIN railway_centroids AS Railways
  ON ST_Contains(Polys.polygeom, Railways.geom)
  GROUP BY Polys.ogc_fid
)
UPDATE japan
SET railway_count = RailwayCounts.railway_count
FROM RailwayCounts
WHERE japan.ogc_fid = RailwayCounts.ogc_fid;

ALTER TABLE japan ADD COLUMN airport_density DOUBLE PRECISION;
ALTER TABLE japan ADD COLUMN railway_density DOUBLE PRECISION;

-- Calculate airport density
UPDATE japan
SET airport_density = airport_count / (ST_Area(ST_Transform(polygeom, 3857)) / 1000000);

-- Calculate railway density
UPDATE japan
SET railway_density = railway_count / (ST_Area(ST_Transform(polygeom, 3857)) / 1000000);



