# tSQLt_TestHelperScripter
- Script a SQL Server table or view to a DataBuilder TestHelper.
- The object needs to be deployed to a SQL Server you can query.

## Sample - One File per Object
Add all of these to your SSDT sqlproj (right click, Add > Existing Item). Easier to add new objects on the fly, but more fussy overall.
```powershell
#get your list of objects. This assumes you did so as a list of files without schema name (hence the use of $_.BaseName).
$targetObjects | .\tSQLt_TestHelperScripter.ps1 -Server 'ServerNameWhereObjectIsDeployed' -Database 'DatabaseWhereObjectIsDeployed' -SchemaToPopulate 'SchemaWhereObjectIsDeployed' -ObjectToPopulate $_.BaseName -OutputDirectory "Full\Path\To\Your\Database\Project\And\The\Place\You\Want\Your\Stored\Procedures\"
```

## Sample - One File with all Object
Add this one file to your SSDT sqlproj one time (right click, Add > Existing Item). To update your list of Data Builders, you need to re-run this for ALL of them, but you don't need to do the Add > Existing Item thing every time.
```powershell
#get your list of objects. This assumes you did so as a list of files without schema name (hence the use of $_.BaseName).
$OutputDirectory = "Full\Path\To\Your\Database\Project\And\The\Place\You\Want\Your\Stored\Procedure\";
Get-ChildItem $OutputDirectory -Filter "*AllDataBuilders.sql" | Remove-Item;
$targetObjects | .\tSQLt_TestHelperScripter.ps1 -Server 'ServerNameWhereObjectIsDeployed' -Database 'DatabaseWhereObjectIsDeployed' -SchemaToPopulate 'SchemaWhereObjectIsDeployed' -ObjectToPopulate $_.BaseName -OutputDirectory $OutputDirectory -Append

```
