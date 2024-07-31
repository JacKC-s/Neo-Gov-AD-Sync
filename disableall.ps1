# Disabled account destination
$destinationOU = "OU=Disabled Accounts,DC=Example,DC=Example,DC=Example,DC=org"

# Grabs users who were determined to be unneeded
$removedUsers = Get-Content -Path .\"inconsistent_users.json" -Raw | ConvertFrom-Json

# Iterates through list to move each user into the disabled user destination and disables the users
for ($i = 0; $i -lt $removedUsers.Count; $i++) {

    # Puts Last and First names into vars
    $fullName = $removedUsers[$i]
    $lastName, $firstName = $fullName -split ',\s+'

    $user = Get-ADUser -Filter "Name -like'*$($lastName)*$($firstName)*'"
    Set-ADUser -Identity $user -Enabled $false
    Move-ADObject -Identity $user -TargetPath $destinationOU
}