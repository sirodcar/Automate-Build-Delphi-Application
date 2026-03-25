unit uProjectScanner;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils;

type
  TProjectScanner = class
  public
    class procedure FindDProjFiles(const AFolder: string; const AList: TStrings);
    class function FindFirstDProj(const AFolder: string): string;
  end;

implementation

class function TProjectScanner.FindFirstDProj(const AFolder: string): string;
var
  LFiles: TArray<string>;
begin
  Result := '';

  if not TDirectory.Exists(AFolder) then
    Exit;

  LFiles := TDirectory.GetFiles(AFolder, '*.dproj', TSearchOption.soAllDirectories);
  if Length(LFiles) > 0 then
    Result := LFiles[0];
end;

class procedure TProjectScanner.FindDProjFiles(const AFolder: string;
  const AList: TStrings);
var
  LFiles: TArray<string>;
  LFile: string;
begin
  AList.Clear;

  if not TDirectory.Exists(AFolder) then
    Exit;

  LFiles := TDirectory.GetFiles(AFolder, '*.dproj', TSearchOption.soAllDirectories);

  for LFile in LFiles do
    AList.Add(LFile);
end;

end.
