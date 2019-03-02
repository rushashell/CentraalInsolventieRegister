#requires -Version 3.0
Import-Module $PSScriptRoot\CurateleBewindRegister

# Create a new session with required ASP.NET VIEW STATE
$Session = New-CurateleBewindSession

# Request information about a specific natural person
$Result = Search-CurateleBewind -CurateleBewindSession $Session -BirthDate "01-01-1990" -LastName "Jansen"

# If we have found a result, we add details to it.
If ($Result -ne $null)
{
    Write-Host "We have an result!" -ForegroundColor Green
    $Result
}