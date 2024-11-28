-- For part 1: Shows the number of lessons given per month during a specified year.
SELECT 
    TO_CHAR(time, 'Mon') AS "Month",
    COUNT(*) AS "Total",
    SUM(CASE WHEN lesson_id IN (SELECT lesson_id FROM individual_lesson) THEN 1 ELSE 0 END) AS "Individual",
    SUM(CASE WHEN lesson_id IN (SELECT lesson_id FROM group_lesson) THEN 1 ELSE 0 END) AS "Group",
    SUM(CASE WHEN lesson_id IN (SELECT lesson_id FROM ensemble) THEN 1 ELSE 0 END) AS "Ensemble"
FROM lesson
WHERE EXTRACT(YEAR FROM time) = 2024
GROUP BY TO_CHAR(time, 'Mon'), EXTRACT(MONTH FROM time)
ORDER BY EXTRACT(MONTH FROM time);











-- For part 2: Shows how many students there are with 0 siblings, 1 sibling, or with 2 siblings. 
SELECT 
    sibling_count AS "Number of siblings",
    COUNT(*) AS "Number of students"
FROM (
    SELECT 
        sibling_id,
        COUNT(person_id) - 1 AS sibling_count -- Subtract 1 to represent the number of siblings
    FROM student
    GROUP BY sibling_id
)
WHERE sibling_count BETWEEN 0 AND 2
GROUP BY sibling_count
ORDER BY sibling_count ASC;










-- For part 3: 

--      Materialized view: For every lesson, shows the person_id and instructor_id for the instructor giving the lesson as well as the time the lesson was taking place.
DROP VIEW IF EXISTS person_instructor;
CREATE VIEW person_instructor AS 
(
    SELECT 
        person_id,
        instructor.instructor_id, 
        lesson.time
    FROM 
        instructor
    INNER JOIN 
        lesson
    ON
        lesson.instructor_id = instructor.instructor_id
);


--      Lists IDs and names (first name, last name) of all instructors who have given lessons this month, as well as the number of lessons they've taught that month.
SELECT 
    ps.instructor_id,
    p.first_name,
    p.last_name,
    COUNT(ps.instructor_id)
FROM
    person p,
	person_instructor ps
WHERE
    p.person_id = ps.person_id
AND
	EXTRACT(YEAR FROM ps.time) = EXTRACT(YEAR FROM CURRENT_DATE)
		AND 
	EXTRACT (MONTH FROM ps.time) = EXTRACT (MONTH FROM CURRENT_DATE)
GROUP BY
    ps.instructor_id, p.first_name, p.last_name;











-- Task 4: 

--      Materialized view: For each ensemble lesson, lists the time, the genre, the max allowed students and the lesson ID.
DROP VIEW IF EXISTS ensemble_lessons;
CREATE VIEW ensemble_lessons AS 
(
    SELECT
        l.time AS "Time",
        t.target_genre AS "Genre",
        e.max_student AS "Max",
        e.lesson_id AS "LessonID"
    FROM
        lesson AS l
    INNER JOIN ensemble AS e
        ON l.lesson_id = e.lesson_id  -- Get only all lesson_ids that are for ensemble lessons
    INNER JOIN target_genre AS t
        ON e.lesson_id = t.lesson_id  -- For getting all genres
    ORDER BY "LessonID" ASC
);

--      Lists the day, genre and how many seats are available for all ensembles held during next week.
SELECT 
    TO_CHAR(el."Time", 'Dy') AS "Day",  -- If lesson is on a friday, it prints "Fri" etc...
    el."Genre",
    CASE
        WHEN COUNT(s.person_id) = el."Max" THEN 'No Seats'  
            -- If the number of students attending is equal to the max allowed...
        WHEN el."Max" - COUNT(s.person_id) BETWEEN 1 AND 2 THEN '1 or 2 Seats'
            -- If the number of students attending is 1 or 2 from the max allowed...
        ELSE 'Many Seats'
    END AS "Number of Free Seats"
FROM 
    ensemble_lessons AS el
INNER JOIN student_lesson AS s
    ON el."LessonID" = s.lesson_id  -- Only lesson_ids for ensemble lessons are used
WHERE 
    el."Time" >= CURRENT_DATE 
    AND el."Time" < CURRENT_DATE + INTERVAL '1 week'
        -- Only lessons that are for next week.
GROUP BY
    el."Time", el."Genre", el."Max"
ORDER BY 
    el."Time" ASC;











-- BONUS: Part 4 without using a materialized view
-- (We did this first, but then thought it would be easier to understand if we use a view)
SELECT 
    TO_CHAR(l.time, 'Dy') AS "Day",
    t.target_genre AS "Genre",
    CASE 
        WHEN COUNT(s.person_id) = e.max_student THEN 'No Seats'
        WHEN e.max_student - COUNT(s.person_id) BETWEEN 1 AND 2 THEN '1 or 2 Seats'
        ELSE 'Many Seats'
    END AS "Number of Free Seats"
FROM 
    lesson AS l
INNER JOIN ensemble AS e
    ON l.lesson_id = e.lesson_id
INNER JOIN target_genre AS t
    ON e.lesson_id = t.lesson_id
LEFT JOIN student_lesson AS s
    ON s.lesson_id = l.lesson_id
WHERE 
    l.time >= CURRENT_DATE 
    AND l.time < CURRENT_DATE + INTERVAL '1 week'
GROUP BY 
    l.time, t.target_genre, e.max_student
ORDER BY 
    l.time;



-- BONUS: Part 3 without using a materialized view
-- (Same thing)
SELECT 
    subquery.instructor_id,
    person.first_name,
    person.last_name,
    COUNT(subquery.instructor_id)
FROM
    person,
    (
        SELECT 
            person_id,
            instructor.instructor_id
        FROM 
            instructor
        INNER JOIN 
            lesson
        ON
            lesson.instructor_id = instructor.instructor_id
        WHERE 
            EXTRACT(YEAR FROM lesson.time) = 2024 
                AND 
            EXTRACT (MONTH FROM lesson.time) = 11
    ) AS subquery
WHERE
    person.person_id = subquery.person_id
GROUP BY
    subquery.instructor_id, person.first_name, person.last_name;