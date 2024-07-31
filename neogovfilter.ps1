# Encodeing to base 64 to create API Key
function Encode {
    param([string]$Text)
    $Encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Text))
    return $Encoded
}

# Decode function - if needed for future alterations
function Decode {
    param([string]$Encoded)
    $Decoded = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($Encoded))
    return $Decoded
}

# Gets config.json data
$upd = Get-Content -Path .\"config.json" -Raw | ConvertFrom-Json

# API URL
$url = "https://api.neogov.com/rest/employees?perpage=10000000&pagenumber=1"
$uri = New-Object System.Uri($url)


# Unencoded Creds - Put Creds of an account with NEOGOV Perfrom Access in Config.json #
$unencodedUsername = "$($upd.username)"
$unencodedPassword = "$($upd.password)"

# Formats the API Key
$unformattedAPI = "$($unencodedUsername):$($unencodedPassword)"
$formattedAPI = Encode -Text $unformattedAPI

Write-Host "Api Key: $formattedAPI"
# Generates AuthHeader
$authHeader = "Basic $formattedAPI"
Write-Host "Auth-Header: $authHeader"

$header = @{
    "Content-Type"  = "application/json"
    "Authorization" = "$authHeader"
}

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $header -Method Get
}
catch {
    # Gives proper error message with https request
    Write-Error "Error fetching employees: $_"
    if ($null -ne $_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorText = $reader.ReadToEnd()
        Write-Error "Error details: $errorText"
    }
}

## Gets Active Employees into a JSON Array ##
$data = $response | ConvertTo-Json

$jsonData = @()
for ($i = 0; $i -lt $data.value.Count; $i++) {
    $firstname = $data.value[$i].firstName
    $lastname = $data.value[$i].lastName

    [bool]$activated = $data.value[$i].active

    $manager = $data.value[$i].directmanager.fullname
    $position = $data.value[$i].position.title
    $department = $data.value[$i].department.name
    
    # Custom User Object
    $user = [PSCustomObject]@{
        Name       = "$lastname, $firstname"
        FirstName  = "$($firstname)"
        LastName   = "$($lastname)"
        Manager    = "$($manager)"
        Position   = "$($position)"
        Department = "$($department)"
    }
    if ($activated -eq $true) {
        $jsonData += $user
    }
    
}

$converted = $jsonData | ConvertTo-Json
Write-Host $converted


try {
    # Grabs users from AD
    Get-ADUser -Filter * -Properties EmailAddress, TelephoneNumber, IPPhone, Title, Department, Description `
        -SearchBase (Get-ADRootDSE).defaultNamingContext `
    | Where-Object { 
        # OUs to be ignored
        $_.DistinguishedName -notlike "*OU=Disabled Accounts,*"  ` # Add more OU Filters if needed
        -and $_.Name -notlike "Example Name" ` # Add filters based off of name attribute
        # Add filters based off of First and Last name
        -and ($_.GivenName -ne "First" -and $_.Surname -ne "Last") } `
    | Select-Object Name, EmailAddress, TelephoneNumber, IPPhone, Title, Department, Description `
    | ConvertTo-Json | Set-Content -Path .\"adusers.json"
    # ^^ Converts Data into readable JSON
}
catch {
    Write-Host "Error: Run as Administator" -Foregroundcolor Blue
    throw $_

}


#--------------------Cleaning JSON--------------------#
$precleaned = Get-Content -Path .\"adusers.json" -Raw | ConvertFrom-Json

for ($i = 0; $i -lt $precleaned.Count; $i++) {
    $fullName = $precleaned[$i].Name
    $lastName, $firstName = $fullName -split ',\s+'
    $precleaned[$i].Name = "$lastName, $firstName"
}

$precleaned | ConvertTo-Json | Set-Content -Path .\"adusers.json"


#--------------------Gets List of Users that are inconsistent between the Active Directory and NEOGOV--------------------#

$outdatedUsers = Get-Content -Path .\"adusers.json" -Raw | ConvertFrom-Json 
$updatedUsers = $converted

## Sorting Logic
$outdatedUsersList = [System.Collections.ArrayList]@()
$updatedUsersList = [System.Collections.ArrayList]@()

foreach ($user in $outdatedUsers) {
    $outdatedUsersList.Add($user.Name)
}


foreach ($user in $updatedUsers) {
    $updatedUsersList.Add($user.Name)
}
##

Write-Host "outdatedUsersList count: $($outdatedUsersList.Count)"
Write-Host "updatedUsersList count: $($updatedUsersList.Count)"


# Compiles Removed Users into List
$removedUsers = Compare-Object -ReferenceObject $outdatedUsersList -DifferenceObject $updatedUsersList | 
Where-Object { $_.SideIndicator -eq '<=' } | 
Select-Object -ExpandProperty InputObject

# Puts list into JSON File Format
$removedUsers | ConvertTo-Json | Set-Content -Path .\"inconsistent_users.json"
