Function my-commands() {
	Write-Host("")
	Write-Host("sfdx-help" + "`t`tSFDX Help commands")
	Write-Host("sfdx-add-org" + "`t`tAdd Salesforce org (sandbox/prod)")
	Write-Host("sfdx-orgs" + "`t`tView all added Salesforce orgs")
	Write-Host("sfdx-soql" + "`t`tRun SOQL queries in a Salesforce org")
	Write-Host("sfdx-open(<alias>)" + "`tOpen your instance in Web Browser")
	Write-Host("open-csv(<filename>)" + "`tOpen the specified CSV file in Powershell viewer")
	Write-Host("sfdx-search-user" + "`tSearch for a Salesforce user across orgs")

	Write-Host("")
}

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

Function sfdx-search-user() {
	$CONTINUE = "y"
	while($CONTINUE -eq "y"){
		Write-Host("===============================================")
		$USERNAME = Read-Host -Prompt "`n:::::USERNAME (with/without the domain)"
		$ACTIVE = ""
		$INACTIVE = ""
		$USERHASH = @{}

		Write-Host -NoNewline ("Searching") -ForegroundColor Gray

		if(-not [string]::IsNullOrEmpty($USERNAME)) {
			$ORGLIST = "tis", "tis-part", "tis-c2", "tis-c2c", "tis-uat"

			foreach($ORG in $ORGLIST) {
				Write-Host -NoNewline (".") -ForegroundColor Gray
				$RESULT = sfdx force:data:soql:query -q "SELECT Id, IsActive, Username, FirstName, LastName FROM User WHERE Username LIKE '%$USERNAME%'" -u $ORG
				if($RESULT.Count -gt 1) {
					foreach($ROW in $RESULT) {
						if($ROW.StartsWith("005")) {
							$DATA = -split $ROW
							if($DATA[1] -eq "true") {
								$ACTIVE += "ORG: " + $ORG + "`t" + $DATA[3] + " " + $DATA[4] + " (" + $DATA[0] + ")`t" + $DATA[2] + "`n"
								$USER = $DATA[2].Substring(0, $DATA[2].IndexOf("@"))
								if(-not ($USERHASH.ContainsKey($USER))){
									$USERHASH[$USER] = $ORG
								} else {
                                    $ORGLIST = $USERHASH.$USER
                                    $ORGLIST += ", " + $ORG
                                    $USERHASH[$USER] = $ORGLIST
                                }
							}
							else {
								$INACTIVE += "ORG: " + $ORG + "`t" + $DATA[2] + " " + $DATA[3] + " (" + $DATA[0] + ")`t" + $DATA[1] + "`n"
							}
						}
					}
				}
				else {}
			}
			Write-Host("Done") -ForegroundColor Green
			
			# Print Active Users
			if(-not [string]::IsNullOrEmpty($ACTIVE)) {
				# Print Count
				Write-Host("")
				Write-Host([string[]]$USERHASH.Count + " active users found.") -ForegroundColor Green

                foreach($h in $USERHASH.GetEnumerator()) {
                    Write-Host "$($h.Name)`t--`t$($h.Value)"
                }
				
				Write-Host("`nACTIVE USERS FOUND") -ForegroundColor Yellow
				Write-Host($ACTIVE)
			} else {
				Write-Host("`nNo active users found.") -ForegroundColor Red
			}

			# Pring inactive users
			if(-not [string]::IsNullOrEmpty($INACTIVE)) {
				Write-Host("`nINACTIVE USERS FOUND") -ForegroundColor Yellow
				Write-Host($INACTIVE)
			} else {
				Write-Host("`nNo inactive users found.") -ForegroundColor Red
			}
		}
		else {
			Write-Host("You need to provide a username. Please try again.") -ForegroundColor Red
		}
		$CONTINUE = Read-Host -Prompt "`nCONTINUE (y/n)"
	}
}
