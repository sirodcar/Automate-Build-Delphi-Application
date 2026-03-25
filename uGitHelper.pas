unit uGitHelper;

interface

uses
  System.SysUtils,
  System.IOUtils,
  uProcessRunner;

type
  TGitHelper = class
  public
    class function CloneRepository(const AGitUrl, ATargetFolder: string): TProcessResult;
    class function PullRepository(const ARepoFolder: string): TProcessResult;
    class function ExtractRepoFolderName(const AGitUrl: string): string;
  end;

implementation

class function TGitHelper.CloneRepository(const AGitUrl,
  ATargetFolder: string): TProcessResult;
var
  LCmd: string;
begin
  if not TDirectory.Exists(ATargetFolder) then
    TDirectory.CreateDirectory(ATargetFolder);

  LCmd := Format('git clone "%s"', [AGitUrl]);
  Result := TProcessRunner.Run(LCmd, ATargetFolder);
end;

class function TGitHelper.ExtractRepoFolderName(const AGitUrl: string): string;
begin
  Result := AGitUrl.Trim;
  Result := Result.Replace('/', '\');
  Result := Result.Substring(Result.LastDelimiter('\') + 1);
  if Result.EndsWith('.git', True) then
    Result := Result.Substring(0, Result.Length - 4);
end;

class function TGitHelper.PullRepository(
  const ARepoFolder: string): TProcessResult;
begin
  Result := TProcessRunner.Run('git pull', ARepoFolder);
end;

end.