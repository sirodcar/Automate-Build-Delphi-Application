unit uBuildHelper;

interface

uses
  System.SysUtils,
  System.IOUtils,
  uTypes,
  uProcessRunner;

type
  TBuildHelper = class
  private
    class function QuoteIfNeeded(const AValue: string): string; static;
    class function NormalizeFolder(const AFolder: string): string; static;
    class function BuildEnvironmentResetCommand: string; static;
    class function BuildMSBuildProperties(
      const AConfig, APlatform: string;
      const ADcuOutput, AExeOutput: string;
      const AMajor, AMinor, ARelease, ABuild: Integer
    ): string; static;
  public
    class function BuildProject(
      const ADelphi: TDelphiInstallInfo;
      const ADProjFile, AConfig, APlatform: string;
      const ADcuOutput, AExeOutput: string;
      const AMajor, AMinor, ARelease, ABuild: Integer
    ): TProcessResult;
  end;

implementation

class function TBuildHelper.QuoteIfNeeded(const AValue: string): string;
begin
  if Pos(' ', AValue) > 0 then
    Result := '"' + AValue + '"'
  else
    Result := AValue;
end;

class function TBuildHelper.NormalizeFolder(const AFolder: string): string;
begin
  Result := Trim(AFolder);
  if Result <> '' then
    Result := ExcludeTrailingPathDelimiter(Result);
end;

class function TBuildHelper.BuildEnvironmentResetCommand: string;
begin
  Result :=
    'set BDS=' +
    ' && set BDSBIN=' +
    ' && set BDSCOMMONDIR=' +
    ' && set BDSINCLUDE=' +
    ' && set BDSLIB=' +
    ' && set FrameworkDir=' +
    ' && set FrameworkVersion=' +
    ' && set FrameworkSDKDir=' +
    ' && set PLATFORM=' +
    ' && set Platform=' +
    ' && set LANGDIR=';
end;

class function TBuildHelper.BuildMSBuildProperties(
  const AConfig, APlatform: string;
  const ADcuOutput, AExeOutput: string;
  const AMajor, AMinor, ARelease, ABuild: Integer
): string;
var
  LDcuOut: string;
  LExeOut: string;
begin
  Result := '';

  Result := Result + ' /p:Config=' + QuoteIfNeeded(AConfig);
  Result := Result + ' /p:Platform=' + QuoteIfNeeded(APlatform);

  Result := Result + Format(
    ' /p:VerInfo_MajorVer=%d /p:VerInfo_MinorVer=%d /p:VerInfo_Release=%d /p:VerInfo_Build=%d',
    [AMajor, AMinor, ARelease, ABuild]
  );

  Result := Result + ' /p:VerInfo_Keys=true';
  Result := Result + ' /p:VerInfo_IncludeVerInfo=true';

  LDcuOut := NormalizeFolder(ADcuOutput);
  if LDcuOut <> '' then
  begin
    ForceDirectories(LDcuOut);
    Result := Result + ' /p:DCC_DcuOutput=' + QuoteIfNeeded(LDcuOut);
    Result := Result + ' /p:DCC_ObjOutput=' + QuoteIfNeeded(LDcuOut);
  end;

  LExeOut := NormalizeFolder(AExeOutput);
  if LExeOut <> '' then
  begin
    ForceDirectories(LExeOut);
    Result := Result + ' /p:DCC_ExeOutput=' + QuoteIfNeeded(LExeOut);
    Result := Result + ' /p:FinalOutputDir=' + QuoteIfNeeded(LExeOut + PathDelim);
  end;
end;

class function TBuildHelper.BuildProject(
  const ADelphi: TDelphiInstallInfo;
  const ADProjFile, AConfig, APlatform: string;
  const ADcuOutput, AExeOutput: string;
  const AMajor, AMinor, ARelease, ABuild: Integer
): TProcessResult;
var
  LWorkingDir: string;
  LProps: string;
  LCmd: string;
  LProjectFile: string;
begin
  if ADelphi = nil then
    raise Exception.Create('Delphi installation is not selected');

  LProjectFile := Trim(ADProjFile);

  if LProjectFile = '' then
    raise Exception.Create('Project file is not specified');

  if not FileExists(LProjectFile) then
    raise Exception.Create('Project file not found: ' + LProjectFile);

  if Trim(AConfig) = '' then
    raise Exception.Create('Build config is not specified');

  if Trim(APlatform) = '' then
    raise Exception.Create('Build platform is not specified');

  if not FileExists(ADelphi.RsVarsBat) then
    raise Exception.Create('rsvars.bat not found: ' + ADelphi.RsVarsBat);

  LWorkingDir := ExtractFilePath(LProjectFile);

  LProps := BuildMSBuildProperties(
    AConfig,
    APlatform,
    ADcuOutput,
    AExeOutput,
    AMajor,
    AMinor,
    ARelease,
    ABuild
  );

  LCmd :=
    BuildEnvironmentResetCommand +
    ' && call ' + QuoteIfNeeded(ADelphi.RsVarsBat) +
    ' && echo ===== DELPHI ENV =====' +
    ' && echo BDS=%BDS%' +
    ' && echo BDSLIB=%BDSLIB%' +
    ' && echo FrameworkDir=%FrameworkDir%' +
    ' && echo FrameworkVersion=%FrameworkVersion%' +
    ' && echo ===== CHECKS =====' +
    ' && dir "%BDSLIB%\Win32\release\System.dcu"' +
    ' && dir "%BDSLIB%\Win32\debug\System.dcu"' +
    ' && echo ===== BUILD START =====' +
    ' && "%FrameworkDir%%FrameworkVersion%MSBuild.exe" ' +
    QuoteIfNeeded(LProjectFile) +
    ' /t:Clean;Build' +
    LProps;

  Result := TProcessRunner.Run(LCmd, LWorkingDir);
end;

end.
