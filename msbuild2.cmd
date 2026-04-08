@echo OFF

IF EXIST "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\amd64\Msbuild.exe" (

   SET MSBUILDEXE="C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\amd64\Msbuild.exe"

) ELSE IF EXIST "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\amd64\Msbuild.exe" (

   SET MSBUILDEXE="C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\amd64\Msbuild.exe"

) ELSE IF EXIST "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\amd64\Msbuild.exe" (

   SET MSBUILDEXE="C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\amd64\Msbuild.exe"

) ELSE (
   SET MSBUILDEXE="msbuild.exe"
)

%MSBUILDEXE% %*