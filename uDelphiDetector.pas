unit uDelphiDetector;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.Win.Registry,
  uTypes;

type
  TDelphiDetector = class
  private
    class procedure ScanRegistryRoot(const AList: TObjectList<TDelphiInstallInfo>;
      const ARootKey: HKEY; const ABaseKey: string);
    class function DelphiNameFromVersion(const AVersion: string): string;
    class function ExistsInList(const AList: TObjectList<TDelphiInstallInfo>;
      const ARootDir: string): Boolean;
  public
    class procedure LoadInstalledDelphi(const AList: TObjectList<TDelphiInstallInfo>);
  end;

implementation

class function TDelphiDetector.DelphiNameFromVersion(const AVersion: string): string;
begin
  if SameText(AVersion, '23.0') then
    Result := 'Delphi 12 Athens'
  else if SameText(AVersion, '22.0') then
    Result := 'Delphi 11 Alexandria'
  else if SameText(AVersion, '21.0') then
    Result := 'Delphi 10.4 Sydney'
  else if SameText(AVersion, '20.0') then
    Result := 'Delphi 10.3 Rio'
  else if SameText(AVersion, '19.0') then
    Result := 'Delphi 10.2 Tokyo'
  else if SameText(AVersion, '18.0') then
    Result := 'Delphi 10.1 Berlin'
  else if SameText(AVersion, '17.0') then
    Result := 'Delphi XE8'
  else if SameText(AVersion, '16.0') then
    Result := 'Delphi XE7'
  else if SameText(AVersion, '15.0') then
    Result := 'Delphi XE6'
  else
    Result := 'Delphi / RAD Studio';
end;

class function TDelphiDetector.ExistsInList(
  const AList: TObjectList<TDelphiInstallInfo>;
  const ARootDir: string): Boolean;
var
  LItem: TDelphiInstallInfo;
begin
  Result := False;
  for LItem in AList do
  begin
    if SameText(ExcludeTrailingPathDelimiter(LItem.RootDir),
      ExcludeTrailingPathDelimiter(ARootDir)) then
      Exit(True);
  end;
end;

class procedure TDelphiDetector.LoadInstalledDelphi(
  const AList: TObjectList<TDelphiInstallInfo>);
begin
  AList.Clear;

  ScanRegistryRoot(AList, HKEY_CURRENT_USER, 'Software\Embarcadero\BDS');
  ScanRegistryRoot(AList, HKEY_LOCAL_MACHINE, 'Software\Embarcadero\BDS');

  ScanRegistryRoot(AList, HKEY_CURRENT_USER, 'Software\CodeGear\BDS');
  ScanRegistryRoot(AList, HKEY_LOCAL_MACHINE, 'Software\CodeGear\BDS');

  ScanRegistryRoot(AList, HKEY_CURRENT_USER, 'Software\Borland\BDS');
  ScanRegistryRoot(AList, HKEY_LOCAL_MACHINE, 'Software\Borland\BDS');
end;

class procedure TDelphiDetector.ScanRegistryRoot(
  const AList: TObjectList<TDelphiInstallInfo>;
  const ARootKey: HKEY; const ABaseKey: string);
var
  LReg: TRegistry;
  LKeys: TStringList;
  I: Integer;
  LVersionKey: string;
  LFullKey: string;
  LRootDir: string;
  LBinDir: string;
  LBdsExe: string;
  LRsVarsBat: string;
  LMSBuildExe: string;
  LInfo: TDelphiInstallInfo;
begin
  LReg := TRegistry.Create(KEY_READ);
  LKeys := TStringList.Create;
  try
    LReg.RootKey := ARootKey;

    if not LReg.KeyExists(ABaseKey) then
      Exit;

    if not LReg.OpenKeyReadOnly(ABaseKey) then
      Exit;
    try
      LReg.GetKeyNames(LKeys);
    finally
      LReg.CloseKey;
    end;

    for I := 0 to LKeys.Count - 1 do
    begin
      LVersionKey := LKeys[I];
      LFullKey := ABaseKey + '\' + LVersionKey;

      if not LReg.OpenKeyReadOnly(LFullKey) then
        Continue;
      try
        if LReg.ValueExists('RootDir') then
          LRootDir := Trim(LReg.ReadString('RootDir'))
        else
          LRootDir := '';
      finally
        LReg.CloseKey;
      end;

      if LRootDir = '' then
        Continue;

      if ExistsInList(AList, LRootDir) then
        Continue;

      LBinDir := TPath.Combine(LRootDir, 'bin');
      LBdsExe := TPath.Combine(LBinDir, 'bds.exe');
      LRsVarsBat := TPath.Combine(LBinDir, 'rsvars.bat');
      LMSBuildExe := TPath.Combine(LBinDir, 'msbuild.exe');

      if not FileExists(LBdsExe) then
        Continue;

      LInfo := TDelphiInstallInfo.Create;
      LInfo.VersionKey := LVersionKey;
      LInfo.DisplayName := DelphiNameFromVersion(LVersionKey);
      LInfo.RootDir := IncludeTrailingPathDelimiter(LRootDir);
      LInfo.BdsExe := LBdsExe;
      LInfo.RsVarsBat := LRsVarsBat;
      LInfo.MSBuildExe := LMSBuildExe;

      AList.Add(LInfo);
    end;
  finally
    LKeys.Free;
    LReg.Free;
  end;
end;

end.