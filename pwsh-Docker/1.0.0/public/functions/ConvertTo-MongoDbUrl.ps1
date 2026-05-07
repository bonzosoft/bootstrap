function ConvertTo-MongoDbUrl {
    [CmdletBinding()]
    [OutputType([string])]

    param(
        [Parameter()]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Hostname = "db",

        [Parameter()]
        [string]$Port = 27017,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$User,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [securestring]$Password,

        [Parameter()]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Source = "admin"
    )

    Write-Output "mongodb://$User`:$Password@$Hostname`:$Port/$Name?authSource=$Source"
}