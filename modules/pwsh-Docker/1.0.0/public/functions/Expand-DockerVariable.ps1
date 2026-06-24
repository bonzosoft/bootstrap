function Expand-DockerVariable {
    [CmdletBinding()]
    [OutputType([string])]

    param (
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    begin {

    }

    process {
        if (-not ($Content.Trim() -like "^#")) {
            $Content = $Content.Replace('[[SERVERNAME]]',         $Script:Context.Hostname)
            $Content = $Content.Replace('[[DATADIR]]',            $Script:Context.StateDir.FullName) # <-------------------------
            $Content = $Content.Replace('[[STATEDIR]]',           $Script:Context.StateDir.FullName)
            $Content = $Content.Replace('[[LFSTORAGEDIR]]',       $Script:Context.LFStorageDir.FullName)
            $Content = $Content.Replace('[[DOMAIN]]',             $Script:Context.Domain)
            $Content = $Content.Replace('[[PROJECTNAME]]',        $Script:Context.ProjectName)
            $Content = $Content.Replace('[[PUID]]',               $Script:Context.Docker.PUID)
            $Content = $Content.Replace('[[PGID]]',               $Script:Context.Docker.PGID)
            $Content = $Content.Replace('[[SOCKETPROXY_PGID]]',   $Script:Context.Docker.DockerPGID)
            $Content = $Content.Replace('[[ADMIN_USER]]',         $Script:Context.Admin.Name)
            $Content = $Content.Replace('[[ADMIN_PASS]]',         (ConvertFrom-SecureString -SecureString $Script:Context.Admin.Password -AsPlainText))
            $Content = $Content.Replace('[[ADMIN_EMAIL]]',        $Script:Context.Admin.Email)
            $Content = $Content.Replace('[[SMTP_RELAY_HOST]]',    $Script:Context.Smtp.Relay.Host)
            $Content = $Content.Replace('[[SMTP_RELAY_PORT]]',    $Script:Context.Smtp.Relay.Port)
            $Content = $Content.Replace('[[SMTP_RELAY_USER]]',    $Script:Context.Smtp.Relay.Name)
            $Content = $Content.Replace('[[SMTP_RELAY_PASS]]',    (ConvertFrom-SecureString -SecureString $Script:Context.Smtp.Relay.Password -AsPlainText))
            $Content = $Content.Replace('[[SMTP_PROVIDER_HOST]]', $Script:Context.Smtp.Provider.Host)
            $Content = $Content.Replace('[[SMTP_PROVIDER_PORT]]', $Script:Context.Smtp.Provider.Port)
            $Content = $Content.Replace('[[SMTP_PROVIDER_USER]]', $Script:Context.Smtp.Provider.Name)
            $Content = $Content.Replace('[[SMTP_PROVIDER_PASS]]', (ConvertFrom-SecureString -SecureString $Script:Context.Smtp.Provider.Password -AsPlainText))            
        }
    }

    end {
        Write-Output $Content
    }
}