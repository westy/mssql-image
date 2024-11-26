@echo off

SET DEV_ISO_URL=https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLServer2019-x64-ENU-Dev.iso
SET CU_NUMBER=29
SET CU_URL=https://download.microsoft.com/download/6/e/7/6e72dddf-dfa4-4889-bc3d-e5d3a0fd11ce/SQLServer2019-KB5046365-x64.exe
SET CU_VERSION=15.0.4405.4
SET WINDOWS_BASE=ltsc2022

echo ##################### Building westy/mssql-server:framework-runtime-4.8-CU%CU_NUMBER%-%WINDOWS_BASE%
docker build --isolation=hyperv --build-arg BASE=%WINDOWS_BASE% --build-arg IMAGENAME=framework/runtime:4.8 --build-arg DEV_INSTANCENAME=SQL2019 --build-arg SQL_COLLATION_NAME=Latin1_General_CI_AS --build-arg DEV_ISO=%DEV_ISO_URL% --build-arg CU=%CU_URL% --build-arg VERSION=%CU_VERSION% --build-arg TYPE=dev --pull . -t westy/mssql-server:framework-runtime-4.8-CU%CU_NUMBER%-%WINDOWS_BASE%
docker tag westy/mssql-server:framework-runtime-4.8-CU29-%WINDOWS_BASE% westy/mssql-server:framework-runtime-4.8-latest-%WINDOWS_BASE%

echo ##################### Building westy/mssql-server:framework-aspnet-4.8-CU%CU_NUMBER%-%WINDOWS_BASE%
docker build --isolation=hyperv --build-arg BASE=%WINDOWS_BASE% --build-arg IMAGENAME=framework/aspnet:4.8 --build-arg DEV_INSTANCENAME=SQL2019 --build-arg SQL_COLLATION_NAME=Latin1_General_CI_AS --build-arg DEV_ISO=%DEV_ISO_URL% --build-arg CU=%CU_URL% --build-arg VERSION=%CU_VERSION% --build-arg TYPE=dev --pull . -t westy/mssql-server:framework-aspnet-4.8-CU%CU_NUMBER%-%WINDOWS_BASE%
docker tag westy/mssql-server:framework-aspnet-4.8-CU29-%WINDOWS_BASE% westy/mssql-server:framework-aspnet-4.8-latest-%WINDOWS_BASE%

echo ##################### Building westy/mssql-server:sdk-8.0-CU%CU_NUMBER%-%WINDOWS_BASE%
docker build --isolation=hyperv --build-arg BASE=%WINDOWS_BASE% --build-arg IMAGENAME=sdk:8.0 --build-arg DEV_INSTANCENAME=SQL2019 --build-arg SQL_COLLATION_NAME=Latin1_General_CI_AS --build-arg DEV_ISO=%DEV_ISO_URL% --build-arg CU=%CU_URL% --build-arg VERSION=%CU_VERSION% --build-arg TYPE=dev --pull . -t westy/mssql-server:sdk-8.0-CU%CU_NUMBER%-%WINDOWS_BASE%
docker tag westy/mssql-server:sdk-8.0-CU29-%WINDOWS_BASE% westy/mssql-server:sdk-8.0-latest-%WINDOWS_BASE%

echo ##################### Done! #####################