-- I use DROP then CREATE instead of CREATE OR REPLACE
-- in case the function signature changes
DROP FUNCTION IF EXISTS insert_sample_p;
CREATE FUNCTION insert_sample_p (
    input_message VARCHAR
)
RETURNS INT AS $$
DECLARE
    sample_id INT;
BEGIN
    INSERT INTO sample (
        message
    )
    VALUES (
        input_message
    )
    RETURNING id INTO sample_id;

    RETURN sample_id;
END; $$
LANGUAGE 'plpgsql'
SECURITY DEFINER
SET search_path = public, pg_temp;

REVOKE ALL PRIVILEGES ON FUNCTION insert_sample_p(input_mesasge VARCHAR)
FROM public;

GRANT EXECUTE ON FUNCTION insert_sample_p(input_message VARCHAR)
TO sample_application;
