# Collects Json data
$data = Get-Content -Path .\"inconsistent_users.json" -Raw | ConvertFrom-Json 

# Converts Data to JSON
$data | ConvertTo-Json

# Iterates through names in the list
for ($i = 0; $i -lt $data.Count; $i++) {

    # Puts Last and First names into vars
    $fullName = $data[$i].Name
    $lastName, $firstName = $fullName -split ',\s+'

    # Checks if theere is a user that has both first and last name
    if ((Get-ADUser -Filter "Name -like'*$($lastName)*'" | Select-Object DistinguishedName) -and (Get-ADUser -Filter "Name -like'*$($firstName)*'" | Select-Object DistinguishedName)) {

        # Gets the distinguished name from each person in the list
        $dn = Get-ADUser -Filter "Name -like'*$($lastName)*$($firstName)*'" | Select-Object DistinguishedName
        $dn.ToString()

        # Ou Regex Pattern
        $ouPattern = "(OU|DC)=[^,}]+"

        # Select Sting finds patterns
        $ouMatches = $dn | Select-String -Pattern $ouPattern -AllMatches | ForEach-Object { $_.Matches.Value }
        $ouPath = ($ouMatches -join ",")
        
        # Creates disabled account path
        $disabledPath = "OU=Disabled Users," + "$ouPath"

        # Debug
        Write-Host $disabledPath


        if (-not(Get-ADOrganizationalUnit -Filter { DistinguishedName -eq $disabledPath })) {
            New-ADOrganizationalUnit -Name "Disabled Users" -Path $ouPath
        }

        ##---UNTESTED---##
        $user = Get-ADUser -Filter "Name -like'*$($lastName)*$($firstName)*'"
        Move-ADObject -Identity $user -TargetPath $disabledPath
        Set-ADUser -Identity $user -Enabled $false
        ##

    }


    

}