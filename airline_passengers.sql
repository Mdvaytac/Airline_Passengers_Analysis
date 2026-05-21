--1. Calculate the average of wifi, food_and_drink, seat_comfort, and inflight_entertainment
--for Business, Eco, and Eco Plus classes. Sort the result by wifi_avg in descending order.

SELECT
    Class,
    ROUND(AVG(`Inflight wifi service`),2) AS wifi_avg,
    ROUND(AVG(`Food and drink`),2) AS food_avg,
    ROUND(AVG(`Seat comfort`),2) AS seat_comfort_avg,
    ROUND(AVG(`Inflight entertainment`),2) AS entertainment_avg
FROM airine_passengers
GROUP BY Class
ORDER BY wifi_avg DESC;

--2. Split Departure_Delay_in_Minutes into 4 groups:
--"0 min", "1–30 min", "31–60 min", "60+ min".
--For each group, calculate the satisfaction percentage.

SELECT
    CASE
        WHEN `Departure Delay in Minutes` = 0 THEN '0 min'
        WHEN `Departure Delay in Minutes` BETWEEN 1 AND 30 THEN '1-30 min'
        WHEN `Departure Delay in Minutes` BETWEEN 31 AND 60 THEN '31-60 min'
        ELSE '60+ min'
    END AS delay_group,

    COUNT(*) AS total_passengers,

    SUM(
        CASE
            WHEN satisfaction = 'satisfied' THEN 1
            ELSE 0
        END
    ) AS satisfied_count,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN satisfaction = 'satisfied' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS satisfied_percentage

FROM airine_passengers
GROUP BY delay_group
ORDER BY satisfied_percentage DESC;

--3. Split Age into 10-year intervals (18–27, 28–37, 38–47, 48–57, 58+).
--For each group, show satisfied count, dissatisfied count, and satisfaction percentage.

SELECT
    CASE
        WHEN Age BETWEEN 18 AND 27 THEN '18-27'
        WHEN Age BETWEEN 28 AND 37 THEN '28-37'
        WHEN Age BETWEEN 38 AND 47 THEN '38-47'
        WHEN Age BETWEEN 48 AND 57 THEN '48-57'
        ELSE '58+'
    END AS age_group,

    SUM(
        CASE
            WHEN satisfaction = 'satisfied' THEN 1
            ELSE 0
        END
    ) AS satisfied_count,

    SUM(
        CASE
            WHEN satisfaction = 'neutral or dissatisfied' THEN 1
            ELSE 0
        END
    ) AS dissatisfied_count,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN satisfaction = 'satisfied' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS satisfied_percentage

FROM airine_passengers
GROUP BY age_group
ORDER BY age_group;

SELECT MIN(Age), MAX(Age) FROM airine_passengers;

--4. Calculate the average of 6 key service columns for Loyal vs Disloyal customers.

SELECT
    `Customer Type`,

    ROUND(AVG(`Inflight wifi service`),2) AS wifi_avg,
    ROUND(AVG(`Food and drink`),2) AS food_avg,
    ROUND(AVG(`Seat comfort`),2) AS seat_comfort_avg,
    ROUND(AVG(`Inflight entertainment`),2) AS entertainment_avg,
    ROUND(AVG(`On-board service`),2) AS onboard_service_avg,
    ROUND(AVG(`Cleanliness`),2) AS cleanliness_avg

FROM airine_passengers
GROUP BY `Customer Type`;

--5. Calculate satisfaction percentage for combinations of Gender and Type of Travel.
--Should return 4 rows.

SELECT
    Gender,
    `Type of Travel`,

    COUNT(*) AS total_passengers,

    SUM(
        CASE
            WHEN satisfaction = 'satisfied' THEN 1
            ELSE 0
        END
    ) AS satisfied_count,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN satisfaction = 'satisfied' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS satisfied_percentage

FROM airine_passengers
GROUP BY Gender, `Type of Travel`
ORDER BY Gender, `Type of Travel`;

--6. Split Flight_Distance into 3 groups:
--Short (<500 km), Medium (500–1500 km), Long (>1500 km).
--For each group, show satisfaction rate and average delay.

SELECT
    CASE
        WHEN `Flight Distance` < 500 THEN 'Short'
        WHEN `Flight Distance` BETWEEN 500 AND 1500 THEN 'Medium'
        ELSE 'Long'
    END AS distance_group,

    COUNT(*) AS total_passengers,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN satisfaction = 'satisfied' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS satisfied_percentage,

    ROUND(AVG(`Departure Delay in Minutes`),2) AS avg_departure_delay,
    ROUND(AVG(`Arrival Delay in Minutes`),2) AS avg_arrival_delay

FROM airine_passengers
GROUP BY distance_group
ORDER BY avg_departure_delay DESC;

--7. Split Online boarding score into groups:
--1–2 (Low), 3 (Medium), 4–5 (High).
--For each group, calculate satisfaction percentage.

SELECT
    CASE
        WHEN `Online boarding` BETWEEN 1 AND 2 THEN 'Low'
        WHEN `Online boarding` = 3 THEN 'Medium'
        WHEN `Online boarding` BETWEEN 4 AND 5 THEN 'High'
    END AS boarding_group,

    COUNT(*) AS total_passengers,

    SUM(
        CASE
            WHEN satisfaction = 'satisfied' THEN 1
            ELSE 0
        END
    ) AS satisfied_count,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN satisfaction = 'satisfied' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS satisfied_percentage

FROM airine_passengers
GROUP BY boarding_group
ORDER BY satisfied_percentage DESC;


--8. Show the number of rows for each combination of:
--Gate location and Departure/Arrival time convenience.
--Return TOP 10 most frequent combinations.

SELECT
    `Gate location`,
    `Departure/Arrival time convenient`,
    COUNT(*) AS total_rows

FROM airine_passengers

GROUP BY
    `Gate location`,
    `Departure/Arrival time convenient`

ORDER BY total_rows DESC
LIMIT 10;


--9. Calculate average Flight Distance per Class using a window function.
--Tag passengers who fly 50%+ above their class average as "Frequent Flyer".
--Show satisfaction rate for these passengers by Class.

WITH base AS (
    SELECT
        Class,
        `Flight Distance`,
        satisfaction,
        AVG(`Flight Distance`) OVER (PARTITION BY Class) AS avg_distance_by_class
    FROM airine_passengers
),

tagged AS (
    SELECT
        *,
        CASE
            WHEN `Flight Distance` > 1.5 * avg_distance_by_class THEN 'Frequent Flyer'
            ELSE 'Other'
        END AS flyer_type
    FROM base
)

SELECT
    Class,

    COUNT(*) AS total_frequent_flyers,

    SUM(
        CASE
            WHEN satisfaction = 'satisfied' THEN 1
            ELSE 0
        END
    ) AS satisfied_count,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN satisfaction = 'satisfied' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS satisfied_percentage

FROM tagged
WHERE flyer_type = 'Frequent Flyer'
GROUP BY Class
ORDER BY satisfied_percentage DESC;


--10. Compare satisfaction impact of service ratings:
--For each service, compare satisfaction rate between high scores (4–5) and low scores (1–2).
--Find the service with the highest impact difference.

WITH service_flags AS (
    SELECT
        satisfaction,

        CASE WHEN `Inflight wifi service` BETWEEN 4 AND 5 THEN 'high'
             WHEN `Inflight wifi service` BETWEEN 1 AND 2 THEN 'low' END AS wifi_grp,

        CASE WHEN `Food and drink` BETWEEN 4 AND 5 THEN 'high'
             WHEN `Food and drink` BETWEEN 1 AND 2 THEN 'low' END AS food_grp,

        CASE WHEN `Seat comfort` BETWEEN 4 AND 5 THEN 'high'
             WHEN `Seat comfort` BETWEEN 1 AND 2 THEN 'low' END AS seat_grp,

        CASE WHEN `Inflight entertainment` BETWEEN 4 AND 5 THEN 'high'
             WHEN `Inflight entertainment` BETWEEN 1 AND 2 THEN 'low' END AS entertainment_grp,

        CASE WHEN `On-board service` BETWEEN 4 AND 5 THEN 'high'
             WHEN `On-board service` BETWEEN 1 AND 2 THEN 'low' END AS onboard_grp,

        CASE WHEN `Cleanliness` BETWEEN 4 AND 5 THEN 'high'
             WHEN `Cleanliness` BETWEEN 1 AND 2 THEN 'low' END AS clean_grp
    FROM airine_passengers
),

agg AS (
    SELECT
        'wifi' AS service,
        wifi_grp AS grp,
        COUNT(*) AS total,
        SUM(CASE WHEN satisfaction = 'satisfied' THEN 1 ELSE 0 END) AS sat
    FROM service_flags
    WHERE wifi_grp IS NOT NULL
    GROUP BY wifi_grp

    UNION ALL

    SELECT
        'food',
        food_grp,
        COUNT(*),
        SUM(CASE WHEN satisfaction = 'satisfied' THEN 1 ELSE 0 END)
    FROM service_flags
    WHERE food_grp IS NOT NULL
    GROUP BY food_grp

    UNION ALL

    SELECT
        'seat',
        seat_grp,
        COUNT(*),
        SUM(CASE WHEN satisfaction = 'satisfied' THEN 1 ELSE 0 END)
    FROM service_flags
    WHERE seat_grp IS NOT NULL
    GROUP BY seat_grp

    UNION ALL

    SELECT
        'entertainment',
        entertainment_grp,
        COUNT(*),
        SUM(CASE WHEN satisfaction = 'satisfied' THEN 1 ELSE 0 END)
    FROM service_flags
    WHERE entertainment_grp IS NOT NULL
    GROUP BY entertainment_grp

    UNION ALL

    SELECT
        'onboard',
        onboard_grp,
        COUNT(*),
        SUM(CASE WHEN satisfaction = 'satisfied' THEN 1 ELSE 0 END)
    FROM service_flags
    WHERE onboard_grp IS NOT NULL
    GROUP BY onboard_grp

    UNION ALL

    SELECT
        'cleanliness',
        clean_grp,
        COUNT(*),
        SUM(CASE WHEN satisfaction = 'satisfied' THEN 1 ELSE 0 END)
    FROM service_flags
    WHERE clean_grp IS NOT NULL
    GROUP BY clean_grp
),

final AS (
    SELECT
        service,
        MAX(CASE WHEN grp = 'high' THEN 1.0 * sat / total END) AS high_sat,
        MAX(CASE WHEN grp = 'low' THEN 1.0 * sat / total END) AS low_sat,
        MAX(CASE WHEN grp = 'high' THEN 1.0 * sat / total END)
        - MAX(CASE WHEN grp = 'low' THEN 1.0 * sat / total END) AS impact_diff
    FROM agg
    GROUP BY service
)

SELECT *
FROM final
ORDER BY impact_diff DESC
LIMIT 1;

--11. Compare dissatisfaction rates using UNION ALL:
--Passengers with Departure Delay > 30 min AND average service score < 3
--vs overall passengers.

WITH base AS (
    SELECT
        satisfaction,

        (
            `Inflight wifi service` +
            `Departure/Arrival time convenient` +
            `Ease of Online booking` +
            `Gate location` +
            `Food and drink` +
            `Online boarding` +
            `Seat comfort` +
            `Inflight entertainment` +
            `On-board service` +
            `Cleanliness`
        ) / 10.0 AS avg_service_score,

        `Departure Delay in Minutes` AS dep_delay
    FROM airine_passengers
),

segment AS (
    SELECT
        CASE
            WHEN dep_delay > 30 AND avg_service_score < 3 THEN 'Target Segment'
            ELSE 'Others'
        END AS grp,
        satisfaction
    FROM base
),

agg AS (
    SELECT
        grp,
        COUNT(*) AS total,
        SUM(CASE WHEN satisfaction = 'neutral or dissatisfied' THEN 1 ELSE 0 END) AS dissatisfied_count
    FROM segment
    GROUP BY grp
)

SELECT
    grp,
    total,
    dissatisfied_count,
    ROUND(100.0 * dissatisfied_count / total, 2) AS dissatisfied_percentage
FROM agg

UNION ALL

SELECT
    'Overall' AS grp,
    COUNT(*) AS total,
    SUM(CASE WHEN satisfaction = 'neutral or dissatisfied' THEN 1 ELSE 0 END) AS dissatisfied_count,
    ROUND(
        100.0 * SUM(CASE WHEN satisfaction = 'neutral or dissatisfied' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS dissatisfied_percentage
FROM airine_passengers;


--12. Rank passengers within each Class based on their average service score.
--Show top 20 passengers per Class using RANK().

WITH base AS (
    SELECT
        id,
        Class,

        (
            `Inflight wifi service` +
            `Departure/Arrival time convenient` +
            `Ease of Online booking` +
            `Gate location` +
            `Food and drink` +
            `Online boarding` +
            `Seat comfort` +
            `Inflight entertainment` +
            `On-board service` +
            `Cleanliness`
        ) / 10.0 AS avg_service_score
    FROM airine_passengers
),

ranked AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY Class
            ORDER BY avg_service_score DESC
        ) AS rnk
    FROM base
)

SELECT
    id,
    Class,
    avg_service_score,
    rnk
FROM ranked
WHERE rnk <= 20
ORDER BY Class, rnk;


--13. Calculate difference in departure delay compared to previous row using LAG().
--Group into: >20 min, 1–20 min, and <=0 min difference, then compare satisfaction rates.

WITH base AS (
    SELECT
        id,
        satisfaction,
        `Departure Delay in Minutes`,
        LAG(`Departure Delay in Minutes`) OVER (ORDER BY id) AS prev_delay
    FROM airine_passengers
),

diff_calc AS (
    SELECT
        *,
        (`Departure Delay in Minutes` - prev_delay) AS delay_diff,

        CASE
            WHEN prev_delay IS NULL THEN 'first_row'
            WHEN (`Departure Delay in Minutes` - prev_delay) > 20 THEN '>20'
            WHEN (`Departure Delay in Minutes` - prev_delay) BETWEEN 1 AND 20 THEN '1-20'
            ELSE '<=0'
        END AS diff_group
    FROM base
),

agg AS (
    SELECT
        diff_group,
        COUNT(*) AS total,
        SUM(CASE WHEN satisfaction = 'satisfied' THEN 1 ELSE 0 END) AS satisfied_count
    FROM diff_calc
    WHERE diff_group <> 'first_row'
    GROUP BY diff_group
)

SELECT
    diff_group,
    total,
    satisfied_count,
    ROUND(100.0 * satisfied_count / total, 2) AS satisfied_percentage
FROM agg
ORDER BY diff_group;
