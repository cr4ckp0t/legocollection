<#
Generate Lego Collection Table

Copyright 2022 Adam Koch

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
IN THE SOFTWARE.
#>

if (!(Test-Path -Path ".\apikey.txt")) {
    Write-Error "You must create a txt file with your API key called apikey.txt."
    Exit
}
elseif (!(Test-Path -Path ".\credentials.txt")) {
    Write-Error "You must create a txt file with your Brickset credentials separated by a pipe (|) called credentials.txt."
    Exit
}

if (Test-Path -Path ".\owned.md") {
    Remove-Item -Path ".\owned.md"
}

if (Test-Path -Path ".\wanted.md") {
    Remove-Item -Path ".\wanted.md"
}

if (Test-Path -Path ".\minifigs.md") {
    Remove-Item -Path ".\minifigs.md"
}

Write-Host "Connecting to Brickset. . ." -ForegroundColor Yellow
Import-Module -Name "Brickset"
$credsContent = Get-Content -Path ".\credentials.txt"
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($credsContent.Split("|"))[0], (ConvertTo-SecureString -String (($credsContent.Split("|"))[1]) -AsPlainText -Force)
Connect-Brickset -APIKey (Get-Content -Path ".\apikey.txt") -Credential $creds | Out-Null

$totalOwnedPieces = 0
$totalOwnedMinifigs = 0
$averageYearTotal = 0
$ownedLegoSets = @()
$ownedMinifigs = @()

Get-BricksetSetOwned -OrderBy Name | ForEach-Object {
    $totalOwnedPieces += ($_.pieces * $_.collection.qtyOwned)
    $averageYearTotal += $_.year

    if ($null -eq $_.minifigs) {
        $minifigs = "0"
    }
    else {
        $minifigs = $_.minifigs
        $totalOwnedMinifigs += $_.minifigs
    }
    $ownedLegoSets += @{
        "name"        = ($_.name.trim() -replace 'â ', '- ');
        "bricksetUri" = $_.bricksetURL;
        "thumbnail"   = $_.image.thumbnailURL;
        "number"      = $_.number;
        "year"        = $_.year;
        "pieces"      = $_.pieces * $_.collection.qtyOwned;
        "minifigs"    = $minifigs;
    }
    Write-Host ("Adding {0} to the owned collection. . ." -f ($_.name.trim() -replace 'â ', '- ')) -ForegroundColor Yellow
}

Get-BricksetMinifigCollectionOwned | ForEach-Object {
    $ownedMinifigs += @{
        "name"          = ($_.name.trim() -replace 'â ', '- ');
        "minifigNumber" = $_.minifigNumber.ToUpper();
        "bricksetUri"   = ("https://brickset.com/minifigs/{0}" -f $_.minifigNumber);
        "category"      = $_.category;
        "ownedLoose"    = $_.ownedLoose;
        "ownedInSets"   = $_.ownedInSets;
    }
}

# add the output markdown to for the tables
Add-Content -Path ".\owned.md" -Value "| Name | ID | Released | Pieces | Minifigs |"
Add-Content -Path ".\owned.md" -Value "| :---- | :----: | :----: | :----: | :----: |"
Add-Content -Path ".\minifigs.md" -Value "| Name | ID | From Sets | Loose |"
Add-Content -Path ".\minifigs.md" -Value "| :---- | :----: | :----: | :----: |"

Write-Host ("Outputting {0} sets in the owned collection. . ." -f $ownedLegoSets.Count) -ForegroundColor Yellow
$linkString = '| <a class="imagehover" href="{0}" target="_blank">{1}<img class="legopic" src="{2}"></a> | <a href="https://www.lego.com/en-us/product/{3}" target="_blank">{4}</a> | {5} | {6} | {7} |'
$ownedLegoSets | Sort-Object { $_.name } | ForEach-Object {
    Add-Content -Path ".\owned.md" -Value ($linkString -f ($_.bricksetUri, $_.name, $_.thumbnail, $_.number, $_.number, $_.year, $_.pieces, $_.minifigs))
    #Add-Content -Path ".\owned.md" -Value ('| <img src="{0}" alt="{1}" height="50" width="50" />&nbsp;&nbsp;[{2}]({3}) | {4} | {5} | {6} | {7} |' -f ($_.thumbnail, $_.name, ($_.name.trim() -replace 'â ', "- "), $_.bricksetURL, $_.number, $_.year, $_.pieces, $_.minifigs)) 
}
$averageYear = [math]::Round($averageYearTotal / $ownedLegoSets.Count)
Add-Content -Path ".\owned.md" -Value ("| **Totals:** | **{0}** | **{1}*** | **{2}** | **{3}** |" -f ($ownedLegoSets.Count, $averageYear, $totalOwnedPieces, $totalOwnedMinifigs))

Write-Host ("Outputting {0} minifigs in the collection. . ." -f $ownedMinifigs.Count) -ForegroundColor Yellow
$minifigString = '| <a href="{0}" target="_blank">{1}</a> | {2} | {3} | {4} |'
$ownedMinifigs | Sort-Object { $_.name } | ForEach-Object {
    Add-Content -Path ".\minifigs.md" -Value ($minifigString -f ($_.bricksetUri, $_.name, $_.minifigNumber, $_.ownedInSets, $_.ownedLoose))
}

Write-Host "Done!" -ForegroundColor Green
