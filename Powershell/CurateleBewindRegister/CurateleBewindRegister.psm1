<#  
    .SYNOPSIS
      Use this module to aquire information from the dutch 'Curatele- en bewindregister' service.

    .DESCRIPTION
      This script was written to demonstrate how you can use powershell to aquire information from 
      the dutch 'Curatele- en bewindregister' service. It should be used for educational purposes 
      only.
    .LEGAL
      This script is written for educational purposes ONLY! Use it at your 
      own risk! 

#>

<#  
    .SYNOPSIS
      Aquire a new session to the 'Curatele- en bewindregister' service

    .DESCRIPTION
      Use this function to aquire a new session object that is needed to 
      request information from the 'Curatele- en bewindregister' service.
#>
Function New-CurateleBewindSession
{
    $Url = "https://curateleenbewindregister.rechtspraak.nl/"
    $Response = Invoke-WebRequest $Url -SessionVariable Ws
    $ViewState = ($Response.InputFields | Where { $_.Name -eq "__VIEWSTATE" }).value
    $ViewStateGenerator = ($Response.InputFields | Where { $_.Name -eq "__VIEWSTATEGENERATOR" }).value
    $EventValidation = ($Response.InputFields | Where { $_.Name -eq "__EVENTVALIDATION" }).value
    $CookieValue = $Ws.Cookies.GetCookies($Url)["GenericSessionID"]

    Return New-Object PsObject -Property @{ 
        ViewState = $ViewState;
        ViewStateGenerator = $ViewStateGenerator;
        EventValidation = $EventValidation;
        Cookie = $CookieValue
    }
}

<#  
    .SYNOPSIS
      Search for a particular natural person within the 'Curatele- en bewindregister' service.

    .DESCRIPTION
      Use this function to search within the 'Curatele- en bewindregister' for a particular natural person.
#>
Function Search-CurateleBewind
{
    Param (
        [Parameter(Mandatory=$true)]
        [PsObject] $CurateleBewindSession, 
        
        [Parameter(Mandatory=$true)]
        [String] $BirthDate,

        [Parameter(Mandatory=$true)]
        [String] $LastName,

        [Parameter(Mandatory=$false)]
        [String] $Initials
    )

    $ApiUrl = "https://curateleenbewindregister.rechtspraak.nl/"
    $ContentType = "application/x-www-form-urlencoded"
    $Method = 'POST'

    $PostParams = @{
        '__VIEWSTATE' = $CurateleBewindSession.ViewState;
        '__VIEWGENERATOR' = $CurateleBewindSession.ViewGenerator;
        '__EVENTVALIDATION' = $CurateleBewindSession.EventValidation;
        'ctl00$MainContent$SearchAndResultControl$tbxVoorvoegsel' = $Initials;
        'ctl00$MainContent$SearchAndResultControl$tbxAchternaam' = $LastName;
        'ctl00$MainContent$SearchAndResultControl$tbxGeboortedatum' = $BirthDate;
        'ctl00$MainContent$SearchAndResultControl$btnZoeken' = "Zoeken";
    }

    $WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $WebSession.Cookies.Add($CurateleBewindSession.Cookie)

    $Headers = @{
        'Referer' = "https://curateleenbewindregister.rechtspraak.nl/";
        'Origin' = "https://curateleenbewindregister.rechtspraak.nl";
    }

    $Properties = @{
        Uri         = $ApiUrl
        Headers     = $Headers
        ContentType = $ContentType
        Method      = $Method
        WebSession  = $WebSession
        Body        = $PostParams
    }

    $Response = Invoke-WebRequest @Properties -ErrorAction Stop
    $SearchResultsTable = @($Response.ParsedHtml.IHTMLDocument3_getElementById("MainContent_SearchAndResultControl_GridSearchResult"))
    $Results = @()

    $Rows = @($SearchResultsTable.Rows)
    For($x = 1; $x -lt $Rows.Count; $x++)
    {
        $Row = $Rows[$x]
        $Cells = @($Row.Cells)

        $Record = @{
            "Firstnames" = $Cells[0].InnerText;
            "LastName" = $Cells[2].InnerText;
            "BirthDate" = $Cells[3].InnerText;
            "BirthPlace" = $Cells[4].InnerText;
            "Match" = $Cells[5].InnerText;
        }

        $Results += [PSCustomObject] $Record
    }

    [PSCustomObject] $Results
}

Export-ModuleMember -Function 'New-*'
Export-ModuleMember -Function 'Search-*'
