Function sfdx-help{sfdx force:doc:commands:list}

Function sfdx-add-org(){
	$ORGALIAS = Read-Host -Prompt "`nALIAS FOR THE ORG"
	$TYPE = Read-Host -Prompt "`nProduction or Sandbox (p/s)"
	if($TYPE -eq "p"){
		sfdx force:auth:web:login -a $ORGALIAS
	} else {
		sfdx force:auth:web:login -a $ORGALIAS -r https://test.salesforce.com/
	}
}

Function sfdx-orgs{sfdx force:org:list}

Function sfdx-soql() {
	$ORGALIAS = Read-Host -Prompt "`nWHICH ORG/ALIAS?"

	$CONTINUE = "y"
	while($CONTINUE -eq "y"){
		$QUERY = Read-Host -Prompt "`nQUERY"
		Write-Host("")
		sfdx force:data:soql:query -u $ORGALIAS -q $QUERY
		
		$EXPORT = Read-Host -Prompt "`nEXPORT (y/n/m) (yes/no/more)?"
		if(($EXPORT -eq "y") -or ($EXPORT -eq "yes")) {
			sfdx force:data:soql:query -u $ORGALIAS -q $QUERY -r csv > export.csv
			Write-host("Exported to export.csv")
		} elseif (($EXPORT -eq "m") -or ($EXPORT -eq "more")) {
			$FILENAME = Read-Host -Prompt "`nFILENAME (with the trailing .csv)"
			sfdx force:data:soql:query -u $ORGALIAS -q $QUERY -r csv > $FILENAME
			Write-host("Exported to " + $FILENAME)
		}
		else {}

		$CONTINUE = Read-Host -Prompt "`nCONTINUE (y/n)"
	}
	Write-Host("Exiting...`n")
}

Function sfdx-open($alias)
	{sfdx force:org:open -u $alias}

Function open-csv($file)
	{Import-Csv $file |Out-GridView}