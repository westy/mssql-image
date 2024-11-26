# escape=`
ARG IMAGENAME=framework/runtime:4.8   # Other options I use are framework/aspnet:4.8 if want web support, or sdk:8.0 for .NET 8
ARG BASE
FROM mcr.microsoft.com/dotnet/$IMAGENAME-windowsservercore-$BASE

ARG DEV_ISO= `
    EXP_EXE= `
    CU= `
    VERSION=`
    TYPE=`
    DEV_INSTANCENAME=MSSQLSERVER `
    SQL_COLLATION_NAME=SQL_Latin1_General_CP1_CI_AS
ENV DEV_ISO=$DEV_ISO `
    EXP_EXE=$EXP_EXE `
    CU=$CU `
    VERSION=$VERSION `
    DEV_INSTANCENAME=$DEV_INSTANCENAME `
    SQL_COLLATION_NAME=$SQL_COLLATION_NAME `
    sa_password="_" `
    attach_dbs="[]" `
    accept_eula="_" `
    sa_password_path="C:\ProgramData\Docker\secrets\sa-password" `
    before_startup="C:\before-startup" `
    after_startup="C:\after-startup"

LABEL org.opencontainers.image.authors="Martyn West, Tobias Fenster"
LABEL org.opencontainers.image.source="https://github.com/westy/mssql-image"
LABEL org.opencontainers.image.description="An unofficial, unsupported and in no way connected to Microsoft container image for MS SQL Server"
LABEL org.opencontainers.image.version=$VERSION-$TYPE

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
USER ContainerAdministrator

RUN Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; `
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));

RUN choco install -y --no-progress 7zip

# Only install sqlpackage if framework version
RUN IF NOT $IMAGENAME == "sdk:8.0" choco install -y --no-progress sqlpackage

RUN Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1; `
    refreshenv;

RUN if (-not [string]::IsNullOrEmpty($env:DEV_ISO)) { `
        Invoke-WebRequest -UseBasicParsing -Uri $env:DEV_ISO -OutFile c:\SQLServer.iso; `
        mkdir c:\installer; `
        7z x -y -oc:\installer .\SQLServer.iso; `
        .\installer\setup.exe /q /ACTION=Install /INSTANCENAME=$env:DEV_INSTANCENAME /SQLCOLLATION=$env:SQL_COLLATION_NAME /FEATURES=SQLEngine,IS /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS; `
        remove-item c:\SQLServer.iso -ErrorAction SilentlyContinue; `
        remove-item -recurse -force c:\installer -ErrorAction SilentlyContinue; `
    }

RUN if (-not [string]::IsNullOrEmpty($env:EXP_EXE)) { `
        Invoke-WebRequest -UseBasicParsing -Uri $env:EXP_EXE -OutFile c:\SQLServerExpress.exe; `
        Start-Process -Wait -FilePath .\SQLServerExpress.exe -ArgumentList /qs, /x:installer ; `
        .\installer\setup.exe /q /ACTION=Install /INSTANCENAME=SQLEXPRESS /SQLCOLLATION=$env:SQL_COLLATION_NAME /FEATURES=SQLEngine,IS /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS; `
        remove-item c:\SQLServerExpress.exe -ErrorAction SilentlyContinue; `
        remove-item -recurse -force c:\installer -ErrorAction SilentlyContinue; `
    }

# Blow the cache from this point
RUN New-Guid > cache_killer.guid.txt

RUN if ($env:DEV_INSTANCENAME -eq 'MSSQLSERVER') { `
        $SqlServiceName = 'MSSQLSERVER'; `
    } else { `
        $SqlServiceName = 'MSSQL$' + $env:DEV_INSTANCENAME; `
    } `
    if ($env:TYPE -eq 'exp') { `
        $SqlServiceName = 'MSSQL$SQLEXPRESS'; `
    } `
    While (!(Get-Service $SqlServiceName -ErrorAction SilentlyContinue)) { Start-Sleep -Seconds 1 }; `
    Stop-Service $SqlServiceName -ErrorAction SilentlyContinue; `
    $databaseFolder = 'c:\databases'; `
    mkdir $databaseFolder; `
    $SqlWriterServiceName = 'SQLWriter'; `
    $SqlBrowserServiceName = 'SQLBrowser'; `
    Set-Service $SqlServiceName -startuptype automatic ; `
    Set-Service $SqlWriterServiceName -startuptype manual ; `
    Stop-Service $SqlWriterServiceName; `
    Set-Service $SqlBrowserServiceName -startuptype manual ; `
    Stop-Service $SqlBrowserServiceName; `
    if ($env:DEV_INSTANCENAME -eq 'MSSQLSERVER') { `
        $SqlTelemetryName = 'SQLTELEMETRY'; `
    } else { `
        $SqlTelemetryName = 'SQLTELEMETRY$' + $env:DEV_INSTANCENAME; `
    } `
    if ($env:TYPE -eq 'exp') { `
        $SqlTelemetryName = 'SQLTELEMETRY$SQLEXPRESS'; `
    } `
    Set-Service $SqlTelemetryName -startuptype manual ; `
    Stop-Service $SqlTelemetryName; `
    $version = [System.Version]::Parse($env:VERSION); `
    $id = ('mssql' + $version.Major + '.' + $env:DEV_INSTANCENAME); `
    if ($env:TYPE -eq 'exp') { `
        $id = ('mssql' + $version.Major + '.SQLEXPRESS'); `
    } `
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver\supersocketnetlib\tcp\ipall') -name tcpdynamicports -value '' ; `
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver\supersocketnetlib\tcp\ipall') -name tcpdynamicports -value '' ; `
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver\supersocketnetlib\tcp\ipall') -name tcpport -value 1433 ; `
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver') -name LoginMode -value 2; `
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver') -name DefaultData -value $databaseFolder; `
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver') -name DefaultLog -value $databaseFolder;

RUN if (-not [string]::IsNullOrEmpty($env:CU)) { `
        $ProgressPreference = 'SilentlyContinue'; `
        Write-Host ('Install CU from ' + $env:CU) ; `
        Invoke-WebRequest -UseBasicParsing -Uri $env:CU -OutFile c:\SQLServer-cu.exe ; `
        .\SQLServer-cu.exe /q /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances ; `
        Start-Sleep -Seconds (6*60) ; `
        $try = 0; `
        while ($try -lt 20) { `
            try { `
                $var = sqlcmd -Q 'select SERVERPROPERTY(''productversion'') as version' -W -m 1 | ConvertFrom-Csv | Select-Object -Skip 1 ; `
                if ($var.version[0] -eq $env:VERSION) { `
                    Write-Host ('Patch done, found expected version ' + $var.version[0]) ; `
                    $try = 21 ; `
                } else { `
                    Write-Host ('Patch seems to be ongoing, found version ' + $var.version[0] + ', try ' + $try) ; `
                } `
            } catch { `
                Write-Host 'Something unexpected happened, try' $try ; `
                Write-Host $_.ScriptStackTrace ; `
            } finally { `
                if ($try -lt 20) { `
                    Start-Sleep -Seconds 60 ; `
                } `
                $try++ ; `
            } `
        } `
        if ($try -eq 20) { `
            Write-Error 'Patch failed' `
        } else { `
            Write-Host 'Successfully patched!' `
        } `
    } `
    remove-item c:\SQLServer-cu.exe -ErrorAction SilentlyContinue;

WORKDIR c:\scripts
COPY .\start.ps1 c:\scripts\

CMD .\start.ps1
