# MS SQL Server

## Getting Started

```
docker-compose up
```

**When starting for the first time use the `SA_PASSWORD` env variable or database initialization will fail.** Every consequent start of a container
with initialized database server ignores the `SA_PASSWORD` varaible.

#### Settings

|variable|purpose|
|---|---|
|SA_PASSWORD|the password to use for the `sa` user (**ignored if db server already initialized**)|

## Notes

#### Restore from Backup
```
-- first, mount the backup file in the container's data directory

-- this returns the Data and Log partitions of the database and their physical mappings
RESTORE FILELISTONLY
    FROM Disk ='/var/opt/mssql/data/my_db.bak';

-- restores the database with the partitions to the respective new paths
RESTORE DATABASE msys
    FROM DISK = '/var/opt/mssql/data/my_db.bak'
WITH 
    MOVE 'my_db_Data' TO '/var/opt/mssql/data/my_db.mdf',
    MOVE 'my_db_Log' TO '/var/opt/mssql/data/my_db.ldf';
```

#### Create Login for the Server
```
CREATE LOGIN my_username
WITH
    password = 'my_password', 
    check_policy = OFF, -- not to ask for strong password
    default_database = my_db,
    default_language = English; 
```

#### Create User in Database
```
USE my_db;
CREATE USER my_user FOR LOGIN my_username;
EXEC sp_addrolemember 'db_owner', 'my_user';
```
