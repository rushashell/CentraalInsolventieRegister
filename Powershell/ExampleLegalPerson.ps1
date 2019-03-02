#requires -Version 3.0
Import-Module $PSScriptRoot\CentraalInsolventieRegister

# Create a new session with required CSRF tokens
$Session = New-RechtspraakSession

# Request information about a specific natural person
$Result = Search-RechtspraakRechtspersoon -RechtspraakSession $Session -Kvk 12345678

# If we have found a result, we add details to it.
If ($Result.aantalResultaten -ge 1)
{
    Foreach($Item in $Result.items)
    {
        $Details = Get-RechtspraakPublicatieDetail -RechtspraakSession $Session -PublicationId $Item.publicatiekenmerk
        Add-Member -InputObject $Item -NotePropertyName "Details" -NotePropertyValue $Details -Force
        Start-Sleep -Seconds 1
    }
}

# Output result
$Result