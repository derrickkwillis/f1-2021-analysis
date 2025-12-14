/* 
The query extract the lap times for all drivers in all Grand Prix, while also showing measures of variation to show level of lap consistency.
The query shows standard deviation, but also shows coefficient of variation to account for DNFs where lap coutns are lower.
Outliers such as laps involving safety cars, pit stops, etc. were removed using the WHERE that excludes laps that are more than 2 standard 
deviations slower than the driver's average lap time in a race.*/

CREATE OR REPLACE VIEW lap_statistics_2021 AS
WITH lap_times_wo_driver AS (
    SELECT
        races.raceid,
        races.name,
        races.date,
        lap_times.driverid,
        lap_times.lap,
        lap_times.time,
        lap_times.milliseconds
    FROM races
    INNER JOIN lap_times
        ON races.raceid = lap_times.raceid
    WHERE races.year = 2021
),

lap_stats AS (
    SELECT
        *,
        AVG(milliseconds) OVER (
            PARTITION BY raceid, driverid
        ) AS avg_lap_time_ms,
        STDDEV(milliseconds) OVER (
            PARTITION BY raceid, driverid
        ) AS lap_stddev_ms,
        MAX(lap) OVER (
            PARTITION BY raceid, driverid
        ) AS max_lap
    FROM lap_times_wo_driver
)

SELECT
    lap_stats.raceid,
    lap_stats.name,
    lap_stats.date,
    drivers.forename,
    drivers.surname,
    lap_stats.lap,
    lap_stats.time,
    lap_stats.milliseconds AS time_in_milliseconds,
    lap_stats.avg_lap_time_ms,
    lap_stats.lap_stddev_ms,
    lap_stats.lap_stddev_ms / lap_stats.avg_lap_time_ms AS lap_cv
FROM lap_stats
INNER JOIN drivers
    ON lap_stats.driverid = drivers.driverid
WHERE
    lap_stats.milliseconds
        <= lap_stats.avg_lap_time_ms + 2 * lap_stats.lap_stddev_ms
    AND lap_stats.lap > 1
    AND lap_stats.lap < lap_stats.max_lap
ORDER BY
    lap_stats.raceid,
    lap_cv,
    lap_stats.lap;

/*
One row per driver per race to provide insight to each driver's level of consistency per race.
*/

CREATE OR REPLACE VIEW driver_consistency_with_constructor_2021 AS
WITH driver_consistency_2021 AS(
    SELECT 
        raceid, 
        name, 
        forename, 
        surname, 
        COUNT(lap) AS lap_count, 
        MIN(avg_lap_time_ms) AS avg_lap_time_ms, 
        MIN(lap_stddev_ms) AS lap_stddeV_ms, MIN(lap_cv) AS lap_cv
    FROM lap_statistics_2021
    GROUP BY raceid, name, forename, surname
    HAVING COUNT(lap) >= 40
    ORDER BY name, MIN(lap_cv)
)

SELECT 
    dc.raceid,
    dc.name,
    dc.forename,
    dc.surname,
    dc.lap_count,
    dc.avg_lap_time_ms,
    dc.lap_stddeV_ms,
    dc.lap_cv,
    r.constructorid,
    c.name AS constructor_name
FROM driver_consistency_2021 AS dc
JOIN results AS r
    ON dc.raceid = r.raceid
    AND dc.forename = (SELECT forename FROM drivers WHERE driverid = r.driverid)
    AND dc.surname = (SELECT surname FROM drivers WHERE driverid = r.driverid)
JOIN constructors AS c
    ON r.constructorid = c.constructorid;

/*Teammate comparison*/

SELECT 
    dc1.name AS race,
    dc1.surname AS driver1_name, 
    dc1.avg_lap_time_ms AS driver1_avg_lap_ms,
    dc1.lap_stddev_ms AS driver1_avg_stddev_ms,
    dc1.lap_cv AS driver1_lap_cv,
    dc2.name AS race,
    dc2.surname AS driver2_name, 
    dc2.avg_lap_time_ms AS driver2_avg_lap_ms,
    dc2.lap_stddev_ms AS driver2_avg_stddev_ms,
    dc2.lap_cv AS driver2_lap_cv
FROM driver_consistency_with_constructor_2021 dc1 
    INNER JOIN driver_consistency_with_constructor_2021 dc2
    ON dc1.raceid = dc2.raceid
        AND dc1.constructorid = dc2.constructorid
        AND dc1.forename || ' ' || dc1.surname < dc2.forename || ' ' || dc2.surname

