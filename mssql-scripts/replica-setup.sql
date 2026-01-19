-- Replica SQL Server initialization script
-- Creates database and configures as subscriber for transactional replication

USE master;
GO

-- Create the main database if it doesn't exist (will receive replicated data)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'mydb')
BEGIN
    CREATE DATABASE mydb;
    PRINT 'Database mydb created successfully';
END
GO

-- Create replication login (same as primary for consistency)
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'replicator')
BEGIN
    CREATE LOGIN replicator WITH PASSWORD = N'Replicator123!';
    PRINT 'Login replicator created successfully';
END
GO

-- Create user in mydb for replicator
USE mydb;
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'replicator')
BEGIN
    CREATE USER replicator FOR LOGIN replicator;
    PRINT 'User replicator created in mydb';
END
GO

-- Grant necessary permissions
ALTER SERVER ROLE sysadmin ADD MEMBER replicator;
GO

-- Create a linked server to the primary for querying if needed
USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.servers WHERE name = N'mssql-primary')
BEGIN
    EXEC sp_addlinkedserver
        @server = N'mssql-primary',
        @srvproduct = N'',
        @provider = N'SQLNCLI',
        @datasrc = N'mssql-primary';

    EXEC sp_addlinkedsrvlogin
        @rmtsrvname = N'mssql-primary',
        @useself = N'false',
        @locallogin = NULL,
        @rmtuser = N'sa',
        @rmtpassword = N'Admin123!';

    PRINT 'Linked server to primary created successfully';
END
GO

PRINT 'Replica setup completed successfully!';
PRINT 'To complete replication, create publications on primary and subscriptions on this replica.';
GO
