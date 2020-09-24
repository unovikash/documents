Write-Host("sfdx-help" + "`t`tSalesforce Commands List")
Write-Host("sfdx-help-all" + "`t`tSFDX Commands List")
Write-Host("")

Function sfdx-help() {
	Write-Host("")
	Write-Host("sfdx-help" + "`t`tSalesforce Commands List")
	Write-Host("sfdx-help-all" + "`t`tSFDX Commands List")
	Write-Host("sfdx-add-org" + "`t`tAdd Salesforce org (sandbox/prod)")
	Write-Host("sfdx-orgs" + "`t`tView all added Salesforce orgs")
	Write-Host("sfdx-soql" + "`t`tRun SOQL queries in a Salesforce org")
	Write-Host("sfdx-open" + "`tOpen your instance in Web Browser")
	Write-Host("open-csv(<filename>)" + "`tOpen the specified CSV file in Powershell viewer")
	Write-Host("sfdx-search-user" + "`tSearch for a Salesforce user across orgs")
	Write-Host("sfdx-record-update" + "`tUpdate a record in Salesforce")
	Write-Host("sfdx-enr-recon" + "`tReconciliation Report for Enrollments by Year")

	Write-Host("")
}

Function sfdx-help-all{sfdx force:doc:commands:list}

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
	$QUERY = Read-Host -Prompt "`nQUERY"
	$QUERYHISTORY = $QUERY
	$STATE = "run"

	while($true){	
		if($STATE -eq "run") {
			Write-Host("")
			sfdx force:data:soql:query -u $ORGALIAS -q $QUERY
		}

		Write-Host("`n")
		$OPTION = Read-Host -Prompt "1 Run Again`n2 Export`n3 Another Query`n4 History`n5 Exit`n`nOPTION"

		if ($OPTION -eq "1") {
			$STATE = "run"
			continue
		}
		elseif ($OPTION -eq "2") {
			$FILENAME = Read-Host -Prompt "`nFILENAME (example - accounts.csv)"
			sfdx force:data:soql:query -u $ORGALIAS -q $QUERY -r csv > $FILENAME
			Write-host("Exported to " + $FILENAME)
			$STATE = "no-run"
		}
		elseif ($OPTION -eq "4") {
			Write-host("`nSOQL HISTORY") -ForegroundColor Yellow
			Write-Host("============") -ForegroundColor Yellow
			Write-host($QUERYHISTORY) -ForegroundColor Gray
			$STATE = "no-run"
		}
		elseif ($OPTION -eq "5") {
			break;
		}
		else {
			$QUERY = Read-Host -Prompt "`nQUERY"
			$STATE = "run"
			$QUERYHISTORY += "`n" + $QUERY
		}
	}
	Write-Host("`nExiting...`n")
}

Function sfdx-open() {
		$alias = Read-Host -Prompt "`nWHICH ORG/ALIAS (tis/tis-part/...)?"
		sfdx force:org:open -u $alias
	}

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
			$ORGLIST = "tis", "tis-part", "tis-c2", "tis-uat"

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

Function sfdx-record-update(){
	$ORG = Read-Host -Prompt "`nORG"
	$OBJECT = Read-Host -Prompt "OBJECT"
	$ID = Read-Host -Prompt "ID"
	$UPDATE = Read-Host -Prompt "UPDATE (?)"

	if(($UPDATE -eq "help") -or ($UPDATE -eq "?")) {
		Write-Host("`nAdd the values to be updated in the form <field API name>=<'New Value'>. You can skip the single quote if there's no space. You can chain multiple fields separated by space. Example -")
		Write-Host("`tName='John Doe' Email=johndoe@something.com") -ForegroundColor Yellow
		$UPDATE = Read-Host -Prompt "`nUPDATE"
	}

	sfdx force:data:record:update -s $OBJECT -i $ID -v "$UPDATE" -u $ORG
}

Function sfdx-enr-recon() {
	$ORGALIAS = "tis"
	$YEAR = Read-Host -Prompt "`nYEAR"
	$QUERY = "SELECT Confirmation_Number__c, Policy_Status__c, Purchase_Date_Year__c FROM Enrollments__c " + 
				"WHERE Record_Status__c='Enrollment' AND Purchase_Date__c<TODAY AND Purchase_Date_Year__c='$YEAR'"
	
	Write-host("Processing...")
	sfdx force:data:soql:query -u $ORGALIAS -q $QUERY -r csv > $YEAR-policy-SF.csv
	Write-host("`nExported!") -ForegroundColor Green
}
