CREATE USER read_only WITH ENCRYPTED PASSWORD '${READ_ONLY_PASSWORD}';
GRANT CONNECT ON DATABASE ${DATABASE_NAME} to read_only;

-- Grant select privileges to read_only user for existing tables and sequences
GRANT USAGE ON SCHEMA public TO read_only;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public to read_only;

-- Set default privileges to grant select to read_only for any new tables created
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO read_only;
