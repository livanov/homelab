#!/usr/bin/env bash

shopt -s nullglob

echo "Waiting for Database ... "

while (true)
do
    /opt/mssql-tools/bin/sqlcmd \
        -S mssql \
        -U sa \
        -P ${SA_PASSWORD} \
        -d master \
        -Q "SELECT 1" \
        -l 1 \
        -o /dev/null
    if [ $? -eq 0 ]
    then
        break
    fi
done

echo "DONE"

mdfsToIgnore="master model msdbdata tempdb"
for mdfFile in /var/opt/mssql/data/*.mdf
do
    dbName=$(basename $mdfFile .mdf)
    if echo $mdfsToIgnore | grep -w -q $dbName
    then
        continue
    fi

    ldfFile="/var/opt/mssql/data/${dbName}_log.ldf"

    query="
        IF NOT EXISTS (
            SELECT 1
            FROM sys.master_files mf
                INNER JOIN sys.databases db ON db.database_id = mf.database_id
            WHERE physical_name = '$mdfFile'
        )
        BEGIN
            CREATE DATABASE InvoicePro_default ON
                (FILENAME = '$mdfFile'),
                (FILENAME = '$ldfFile')
            FOR ATTACH;
        END"
    
    /opt/mssql-tools/bin/sqlcmd \
        -S mssql \
        -U sa \
        -P ${SA_PASSWORD} \
        -d master \
        -Q "$query" \
        -o /dev/null

    echo "ATTACHED $dbName"
done

for sqlInitFile in /init_scripts/*.sql
do
    /opt/mssql-tools/bin/sqlcmd \
        -S mssql \
        -U sa \
        -P ${SA_PASSWORD} \
        -d master \
        -i "$query"

    echo "EXECUTED $sqlInitFile"
done

echo "Startup script FINISHED"