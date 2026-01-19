-- Primary SQL Server initialization script
-- Creates database, replication login, and configures for transactional replication

USE master;
GO

-- Create the main database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'mydb')
BEGIN
    CREATE DATABASE mydb;
    PRINT 'Database mydb created successfully';
END
GO

-- Enable the database for replication
USE mydb;
GO

-- Create replication login
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'replicator')
BEGIN
    CREATE LOGIN replicator WITH PASSWORD = N'Replicator123!';
    PRINT 'Login replicator created successfully';
END
GO

-- Create user in mydb for replicator
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'replicator')
BEGIN
    CREATE USER replicator FOR LOGIN replicator;
    PRINT 'User replicator created in mydb';
END
GO

-- Grant necessary permissions for replication
ALTER SERVER ROLE sysadmin ADD MEMBER replicator;
GO

-- Enable SQL Server Agent (required for replication)
-- Note: SQL Server Agent is enabled by default in Developer edition

-- Configure the distribution database on primary (acts as its own distributor)
USE master;
GO

-- Check if distribution is already configured
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'distribution')
BEGIN
    EXEC sp_adddistributor @distributor = N'mssql-primary', @password = N'';
    EXEC sp_adddistributiondb @database = N'distribution', @security_mode = 0;
    PRINT 'Distribution configured successfully';
END
GO

-- Configure the publisher
EXEC sp_adddistpublisher
    @publisher = N'mssql-primary',
    @distribution_db = N'distribution',
    @working_directory = N'/var/opt/mssql/data',
    @security_mode = 0;
GO

-- Enable the database for publishing
USE mydb;
GO

EXEC sp_replicationdboption
    @dbname = N'mydb',
    @optname = N'publish',
    @value = N'true';
GO

PRINT 'Primary replication setup completed successfully!';
GO
