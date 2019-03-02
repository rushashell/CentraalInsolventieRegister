<#  
    .SYNOPSIS
      Use this module to aquire information from the dutch 'centraal insolventie register' service.

    .DESCRIPTION
      This script was written to demonstrate how you can use powershell to aquire information from 
      the dutch 'centraal insolventie register' service. It should be used for educational purposes 
      only.
    .LEGAL
      This script is written for educational purposes ONLY! Use it at your 
      own risk! 

#>

<#  
    .SYNOPSIS
      Aquire a new session to the 'centraal insolventie register' service

    .DESCRIPTION
      Use this function to aquire a new session object that is needed to 
      request information from the 'centraal insolventie register' service.
#>
Function New-RechtspraakSession
{
    $Url = "https://insolventies.rechtspraak.nl/#!/zoeken/index"
    $Response = Invoke-WebRequest $Url -SessionVariable Ws
    $RequestVerificationToken = ($Response.InputFields | Where { $_.Name -eq "__RequestVerificationToken" }).value
    
    $CookieValue = $Ws.Cookies.GetCookies($Url)["__RequestVerificationToken"]
    Return New-Object PsObject -Property @{ RequestVerificationToken = $RequestVerificationToken; Cookie = $CookieValue }
}

<#  
    .SYNOPSIS
      Search for a particular natural person within the 'centraal insolventie register' service.

    .DESCRIPTION
      Use this function to search within the 'centraal insolventie register' for a particular natural person.
#>
Function Search-RechtspraakNatuurlijkPersoon 
{
    Param (
        [Parameter(Mandatory=$true)]
        [PsObject] $RechtspraakSession, 
        
        [Parameter(ParameterSetName="Method1", Mandatory=$true)]
        [Parameter(ParameterSetName="Method3", Mandatory=$true)]
        [Parameter(ParameterSetName="Method4", Mandatory=$true)]
        [String] $BirthDate,

        [Parameter(ParameterSetName="Method1", Mandatory=$true)]
        [Parameter(ParameterSetName="Method2", Mandatory=$true)]
        [String] $Initials,

        [Parameter(ParameterSetName="Method1", Mandatory=$true)]
        [Parameter(ParameterSetName="Method2", Mandatory=$true)]
        [Parameter(ParameterSetName="Method4", Mandatory=$true)]
        [String] $LastName, 

        [Parameter(ParameterSetName="Method2", Mandatory=$true)]
        [Parameter(ParameterSetName="Method3", Mandatory=$true)]
        [String] $Zipcode,

        [Parameter(ParameterSetName="Method2", Mandatory=$true)]
        [Parameter(ParameterSetName="Method3", Mandatory=$true)]
        [Int32] $HouseNumber
    )

    $ApiUrl = "https://insolventies.rechtspraak.nl/Services/WebInsolventieService/ZoekOpNatuurlijkPersoon"
    $ContentType = "application/json"
    $Method = 'POST'

    Switch($PSCmdLet.ParameterSetName.ToUpper())
    {
        "METHOD1" { $Body = '{"model":"{\"voorvoegsel\":\"' + $Initials + '\",\"achternaam\":\"' + $LastName + '\",\"geboortedatum\":\"' + $BirthDate + '\"}"}' }
        "METHOD2" { $Body = '{"model":"{\"voorvoegsel\":\"' + $Initials + '\",\"achternaam\":\"' + $LastName + '\",\"postcode\":\"' + $Zipcode + '\",\"huisnummer\":\"' + $HouseNumber + '\"}"}' } 
        "METHOD3" { $Body = '{"model":"{\"geboortedatum\":\"' + $BirthDate + '\",\"postcode\":\"' + $Zipcode + '\",\"huisnummer\":\"' + $HouseNumber + '\"}"}' }
        "METHOD4" { $Body = '{"model":"{\"geboortedatum\":\"' + $BirthDate + '\",\"achternaam\":\"' + $LastName + '\"}"}' }
    }

    $WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $WebSession.Cookies.Add($RechtspraakSession.Cookie)

    $Headers = @{
        '__RequestVerificationToken' = $RechtspraakSession.RequestVerificationToken;
        'Referer' = "https://insolventies.rechtspraak.nl/";
        'Origin' = "https://insolventies.rechtspraak.nl/";
    }

    $Properties = @{
        Uri         = $ApiUrl
        Headers     = $Headers
        ContentType = $ContentType
        Method      = $Method
        WebSession  = $WebSession
        Body        = $Body
    }

    $Response = Invoke-RestMethod @Properties -ErrorAction Stop
    $Response.result.model
}

<#  
    .SYNOPSIS
      Search for a particular legal person within the 'centraal insolventie register' service.

    .DESCRIPTION
      Use this function to search within the 'centraal insolventie register' for a particular legal person.
#>
Function Search-RechtspraakRechtspersoon
{
    Param (
        [Parameter(Mandatory=$true)]
        [PsObject] $RechtspraakSession, 
        
        [Parameter(ParameterSetName="Method1", Mandatory=$true)]
        [String] $Naam,

        [Parameter(ParameterSetName="Method2", Mandatory=$true)]
        [String] $Kvk,
        
        [Parameter(ParameterSetName="Method3", Mandatory=$true)]
        [String] $Zipcode,

        [Parameter(ParameterSetName="Method3", Mandatory=$true)]
        [Int32] $HouseNumber
    )

    $ApiUrl = "https://insolventies.rechtspraak.nl/Services/WebInsolventieService/ZoekOpRechtspersoon"
    $ContentType = "application/json"
    $Method = 'POST'

    Switch($PSCmdLet.ParameterSetName.ToUpper())
    {
        "METHOD1" { $Body = '{"model":"{\"naam\":\"' + $Naam + '\"}"}' }
        "METHOD2" { $Body = '{"model":"{\"KvKNummer\":\"' + $Kvk + '\"}"}' } 
        "METHOD3" { $Body = '{"model":"{\"postcode\":\"' + $Zipcode + '\",\"huisnummer\":\"' + $HouseNumber + '\"}"}' }
    }

    $WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $WebSession.Cookies.Add($RechtspraakSession.Cookie)

    $Headers = @{
        '__RequestVerificationToken' = $RechtspraakSession.RequestVerificationToken;
        'Referer' = "https://insolventies.rechtspraak.nl/";
        'Origin' = "https://insolventies.rechtspraak.nl/";
    }

    $Properties = @{
        Uri         = $ApiUrl
        Headers     = $Headers
        ContentType = $ContentType
        Method      = $Method
        WebSession  = $WebSession
        Body        = $Body
    }

    $Response = Invoke-RestMethod @Properties -ErrorAction Stop
    $Response.result.model
}

<#  
    .SYNOPSIS
      Get details from the 'centraal insolventie register' about a particular publication.

    .DESCRIPTION
      Use this function to retrieve details from the 'centraal insolventie register' about an particular publication.
#>
Function Get-RechtspraakPublicatieDetail
{
    Param (
        [Parameter(Mandatory=$true)]
        [PsObject] $RechtspraakSession, 

        [Parameter(Mandatory=$true)]
        [String] $PublicationId
    )

    $ApiUrl = "https://insolventies.rechtspraak.nl/Services/WebInsolventieService/haalOp/?id=" + $PublicationId
    $Method = 'GET'

    $WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $WebSession.Cookies.Add($RechtspraakSession.Cookie)

    $Headers = @{
        '__RequestVerificationToken' = $RechtspraakSession.RequestVerificationToken;
        'Referer' = "https://insolventies.rechtspraak.nl/";
        'Origin' = "https://insolventies.rechtspraak.nl/";
    }

    $Properties = @{
        Uri         = $ApiUrl
        Headers     = $Headers
        ContentType = $ContentType
        Method      = $Method
        WebSession  = $WebSession
    }

    $Response = Invoke-RestMethod @Properties -ErrorAction Stop
    $Response.model
}

Export-ModuleMember -Function 'New-*'
Export-ModuleMember -Function 'Search-*'
Export-ModuleMember -Function 'Get-*'