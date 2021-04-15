if (!(Test-Path -Path ".\apikey.txt")) {
    Write-Error "You must create a txt file with your API key called apikey.txt."
    Exit
}
elseif (!(Test-Path -Path ".\credentials.txt")) {
    Write-Error "You must create a txt file with your Brickset credentials separated by a pipe (|) called credentials.txt."
    Exit
}

if (Test-Path -Path ".\output.md") {
    Remove-Item -Path ".\output.md"
}

Import-Module -Name "Brickset"
$credsContent = Get-Content -Path ".\credentials.txt"
$username = ($credsContent.Split("|"))[0]
$password = ConvertTo-SecureString -String (($credsContent.Split("|"))[1]) -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password
Connect-Brickset -APIKey (Get-Content -Path ".\apikey.txt") -Credential $creds | Out-Null

$totalSets = 0
$totalPieces = 0
$totalMinifigs = 0

Add-Content -Path ".\output.md" -Value "| Name | ID | Released | Pieces | Minifigs |"
Add-Content -Path ".\output.md" -Value "| :---- | :----: | :----: | :----: | :----: |"

Get-BricksetSetOwned -OrderBy Name | ForEach-Object {
    $totalSets++
    $totalPieces += $_.pieces

    if ($null -eq $_.minifigs) {
        $minifigs = 0
    }
    else {
        $minifigs = $_.minifigs
        $totalMinifigs += $_.minifigs
    }
    Add-Content -Path ".\output.md" -Value ("| [{0}]({1}) | {2} | {3} | {4} | {5} |" -f ($_.name, $_.bricksetURL, $_.number, $_.year, $_.pieces, $minifigs)) 
}

Add-Content -Path ".\output.md" -Value ("| **Totals:** | **{0}** |  | **{1}** | **{2}** |" -f ($totalSets, $totalPieces, $totalMinifigs))