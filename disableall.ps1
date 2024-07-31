# Disabled account destination
$destinationOU = "OU=Disabled Accounts,DC=THTOV,DC=viennamail,DC=viennava,DC=gov"

# Grabs users who were determined to be unneeded
$removedUsers = Get-Content -Path .\"inconsistent_users.json" -Raw | ConvertFrom-Json

# Iterates through list to move each user into the disabled user destination and disables the users
foreach ($item in $removedUsers) {

    # Puts Last and First names into vars
    $fullName = $item.Name
    $lastName, $firstName = $fullName -split ',\s+'

    $user = Get-ADUser -Filter "Name -like'*$($lastName)*$($firstName)*'"
    Set-ADUser -Identity $user -Enabled $false
    Move-ADObject -Identity $user -TargetPath $destinationOU
}
