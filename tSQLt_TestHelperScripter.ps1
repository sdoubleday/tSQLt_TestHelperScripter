PARAM(

 [Parameter(Mandatory= $false)][String]$Server = "(localdb)\ProjectsV13"
,[Parameter(Mandatory= $true)][String]$Database
,[Parameter(Mandatory= $true)][String]$SchemaToPopulate
,[Parameter(Mandatory= $true)][String]$ObjectToPopulate
,[Parameter(Mandatory= $false)][String]$DataBuilderSchema = 'TestHelpers'
,[Parameter(Mandatory= $false)][String]$DataBuilderObjectName = "DataBuilder_$($SchemaToPopulate)_$($ObjectToPopulate)"
,[ValidateNotNullorEmpty()][ValidateScript({
             IF (Test-Path -PathType Container -Path $_ ) 
                 {$True}
             ELSE {
                 Throw "$_ is not a Directory."
             } 
         })][String]$OutputDirectory = ".\$($Database)\$($DataBuilderSchema)\Stored Procedures\"

)

$OutputFileName = "$OutputDirectory\$DataBuilderObjectName.sql";

#https://www.sqlshack.com/connecting-powershell-to-sql-server/

$sqlConn = New-Object System.Data.SqlClient.SqlConnection;
$sqlConn.ConnectionString = “Server=$Server;Integrated Security=true;Initial Catalog=$Database”;
$sqlConn.Open();


$sqlcmd = New-Object System.Data.SqlClient.SqlCommand;
$sqlcmd.Connection = $sqlConn
$query = @"
SELECT 'CREATE PROCEDURE [$DataBuilderSchema].[$DataBuilderObjectName]'
UNION ALL
SELECT
CASE WHEN Ordinal_Position = 1 THEN ' ' ELSE ',' END +
'@'+REPLACE(REPLACE(column_name,' ','_'),'.','_')+' ' + 
        data_type + case data_type
            when 'sql_variant' then ''
            when 'text' then ''
            when 'ntext' then ''
            when 'xml' then ''
            when 'decimal' then '(' + cast(numeric_precision as varchar) + ', ' + cast(numeric_scale as varchar) + ')'
            else coalesce('('+case when character_maximum_length = -1 then 'MAX' else cast(character_maximum_length as varchar) end +')','') end
			+ ' = NULL'
			AS ParameterDeclaration
 FROM Information_Schema.COLUMNS
	   WHERE TABLE_NAME LIKE '$ObjectToPopulate'
	   AND TABLE_SCHEMA LIKE '$SchemaToPopulate'
       AND DATA_TYPE NOT LIKE 'rowversion'
       AND DATA_TYPE NOT LIKE 'timestamp'
UNION ALL
SELECT DISTINCT 'AS 
IF OBJECT_ID(''tempdb..[#$DataBuilderObjectName]'') IS NOT NULL
BEGIN
	DROP TABLE [#$DataBuilderObjectName];
END
SELECT TOP 0 '
UNION ALL
SELECT CASE WHEN Ordinal_Position = 1 THEN ' ' ELSE ',' END +
'['+column_name+']' AS InsertIntoList 
 FROM Information_Schema.COLUMNS
	   WHERE TABLE_NAME LIKE '$ObjectToPopulate'
	   AND TABLE_SCHEMA LIKE '$SchemaToPopulate'
       AND DATA_TYPE NOT LIKE 'rowversion'
       AND DATA_TYPE NOT LIKE 'timestamp'
UNION ALL
SELECT ' INTO [#$DataBuilderObjectName] FROM [$SchemaToPopulate].[$ObjectToPopulate];
INSERT INTO [#$DataBuilderObjectName]('
UNION ALL
SELECT CASE WHEN Ordinal_Position = 1 THEN ' ' ELSE ',' END +
'['+column_name+']' AS InsertIntoList 
 FROM Information_Schema.COLUMNS
	   WHERE TABLE_NAME LIKE '$ObjectToPopulate'
	   AND TABLE_SCHEMA LIKE '$SchemaToPopulate'
       AND DATA_TYPE NOT LIKE 'rowversion'
       AND DATA_TYPE NOT LIKE 'timestamp'
UNION ALL
SELECT ') SELECT'
UNION ALL
SELECT
CASE WHEN Ordinal_Position = 1 THEN ' ' ELSE ',' END +
'@'+REPLACE(column_name,' ','_')
AS SelectClause
       FROM Information_Schema.COLUMNS
	   WHERE TABLE_NAME LIKE '$ObjectToPopulate'
	   AND TABLE_SCHEMA LIKE '$SchemaToPopulate'
       AND DATA_TYPE NOT LIKE 'rowversion'
       AND DATA_TYPE NOT LIKE 'timestamp'
UNION ALL
SELECT ';
DECLARE @sql NVARCHAR(MAX) = N''INSERT INTO [$SchemaToPopulate].[$ObjectToPopulate] (
'
UNION ALL
SELECT CASE WHEN Ordinal_Position = 1 THEN ' ' ELSE ',' END +
'['+column_name+']' AS InsertIntoList 
 FROM Information_Schema.COLUMNS
	   WHERE TABLE_NAME LIKE '$ObjectToPopulate'
	   AND TABLE_SCHEMA LIKE '$SchemaToPopulate'
       AND DATA_TYPE NOT LIKE 'rowversion'
       AND DATA_TYPE NOT LIKE 'timestamp'
UNION ALL
SELECT '
) SELECT '
UNION ALL
SELECT CASE WHEN Ordinal_Position = 1 THEN ' ' ELSE ',' END +
'['+column_name+']' AS InsertIntoList 
 FROM Information_Schema.COLUMNS
	   WHERE TABLE_NAME LIKE '$ObjectToPopulate'
	   AND TABLE_SCHEMA LIKE '$SchemaToPopulate'
       AND DATA_TYPE NOT LIKE 'rowversion'
       AND DATA_TYPE NOT LIKE 'timestamp'
UNION ALL
SELECT ' FROM [#$DataBuilderObjectName];'';
EXECUTE sp_executesql @sql;
RETURN 0'
UNION ALL
SELECT ''
"@;

$sqlcmd.CommandText = $query;

$adp = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd;

$data = New-Object System.Data.DataSet;
$adp.Fill($data) | Out-Null;

#Overwrite placeholder.
New-Item -ItemType File -Force $OutputFileName | Out-Null;

$data.Tables[0] | Select-Object -ExpandProperty Column1 | Out-String | Add-Content -Path $OutputFileName -Encoding UTF8; 

$sqlConn.Close();

Get-ChildItem $OutputFileName;
