unit uProjectCleaner;

interface

uses
  System.SysUtils,
  System.Classes;

type
  TProjectCleanerResult = record
    Success: Boolean;
    DeletedFolders: TStringList;
    DeletedFiles: TStringList;
    Errors: TStringList;
    class function Create: TProjectCleanerResult; static;
    procedure Init;
    procedure Done;
  end;

  TProjectCleaner = class
  private
    class procedure DeleteMatchingFiles(
      const ARootFolder: string;
      const APatterns: array of string;
      const ADeletedFiles, AErrors: TStrings
    ); static;

    class procedure DeleteNamedFolders(
      const ARootFolder: string;
      const AFolderNames: array of string;
      const ADeletedFolders, AErrors: TStrings
    ); static;

    class procedure FindFoldersByName(
      const ARootFolder, ATargetFolderName: string;
      const AResults: TStrings
    ); static;

    class procedure FindFilesByPattern(
      const ARootFolder, APattern: string;
      const AResults: TStrings
    ); static;

    class procedure SafeDeleteFile(
      const AFileName: string;
      const ADeletedFiles, AErrors: TStrings
    ); static;

    class procedure SafeDeleteFolder(
      const AFolderName: string;
      const ADeletedFolders, AErrors: TStrings
    ); static;

  public
    class function CleanProjectFolder(const AFolder: string): TProjectCleanerResult; static;
    class function CleanRepoFolder(const AFolder: string): TProjectCleanerResult; static;
  end;

implementation

uses
  System.IOUtils;

function CompareStringsByLengthDesc(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := Length(List[Index2]) - Length(List[Index1]);
end;

{ TProjectCleanerResult }

class function TProjectCleanerResult.Create: TProjectCleanerResult;
begin
  Result.Init;
end;

procedure TProjectCleanerResult.Init;
begin
  Success := True;
  DeletedFolders := TStringList.Create;
  DeletedFiles := TStringList.Create;
  Errors := TStringList.Create;
end;

procedure TProjectCleanerResult.Done;
begin
  FreeAndNil(DeletedFolders);
  FreeAndNil(DeletedFiles);
  FreeAndNil(Errors);
end;

{ TProjectCleaner }

class procedure TProjectCleaner.FindFoldersByName(const ARootFolder,
  ATargetFolderName: string; const AResults: TStrings);
var
  LDirectories: TArray<string>;
  LDir: string;
begin
  if not DirectoryExists(ARootFolder) then
    Exit;

  LDirectories := TDirectory.GetDirectories(ARootFolder, '*', TSearchOption.soAllDirectories);

  for LDir in LDirectories do
  begin
    if SameText(ExtractFileName(ExcludeTrailingPathDelimiter(LDir)), ATargetFolderName) then
      AResults.Add(LDir);
  end;
end;

class procedure TProjectCleaner.FindFilesByPattern(const ARootFolder,
  APattern: string; const AResults: TStrings);
var
  LFiles: TArray<string>;
  LFile: string;
begin
  if not DirectoryExists(ARootFolder) then
    Exit;

  LFiles := TDirectory.GetFiles(ARootFolder, APattern, TSearchOption.soAllDirectories);

  for LFile in LFiles do
    AResults.Add(LFile);
end;

class procedure TProjectCleaner.SafeDeleteFile(const AFileName: string;
  const ADeletedFiles, AErrors: TStrings);
begin
  try
    if FileExists(AFileName) then
    begin
      TFile.SetAttributes(AFileName, []);
      TFile.Delete(AFileName);
      ADeletedFiles.Add(AFileName);
    end;
  except
    on E: Exception do
      AErrors.Add(Format('File delete failed: %s | %s', [AFileName, E.Message]));
  end;
end;

class procedure TProjectCleaner.SafeDeleteFolder(const AFolderName: string;
  const ADeletedFolders, AErrors: TStrings);
begin
  try
    if DirectoryExists(AFolderName) then
    begin
      TDirectory.Delete(AFolderName, True);
      ADeletedFolders.Add(AFolderName);
    end;
  except
    on E: Exception do
      AErrors.Add(Format('Folder delete failed: %s | %s', [AFolderName, E.Message]));
  end;
end;

class procedure TProjectCleaner.DeleteMatchingFiles(const ARootFolder: string;
  const APatterns: array of string; const ADeletedFiles, AErrors: TStrings);
var
  LPattern: string;
  LFiles: TStringList;
  I: Integer;
begin
  LFiles := TStringList.Create;
  try
    LFiles.Sorted := False;
    LFiles.Duplicates := dupIgnore;

    for LPattern in APatterns do
      FindFilesByPattern(ARootFolder, LPattern, LFiles);

    for I := 0 to LFiles.Count - 1 do
      SafeDeleteFile(LFiles[I], ADeletedFiles, AErrors);
  finally
    LFiles.Free;
  end;
end;

class procedure TProjectCleaner.DeleteNamedFolders(const ARootFolder: string;
  const AFolderNames: array of string; const ADeletedFolders, AErrors: TStrings);
var
  LFolderName: string;
  LFolders: TStringList;
  I: Integer;
begin
  LFolders := TStringList.Create;
  try
    LFolders.Sorted := False;
    LFolders.Duplicates := dupIgnore;

    for LFolderName in AFolderNames do
      FindFoldersByName(ARootFolder, LFolderName, LFolders);

    LFolders.CustomSort(CompareStringsByLengthDesc);

    for I := 0 to LFolders.Count - 1 do
      SafeDeleteFolder(LFolders[I], ADeletedFolders, AErrors);
  finally
    LFolders.Free;
  end;
end;

class function TProjectCleaner.CleanProjectFolder(
  const AFolder: string): TProjectCleanerResult;
begin
  Result := TProjectCleanerResult.Create;

  if Trim(AFolder) = '' then
  begin
    Result.Success := False;
    Result.Errors.Add('Project folder is empty');
    Exit;
  end;

  if not DirectoryExists(AFolder) then
  begin
    Result.Success := False;
    Result.Errors.Add('Project folder does not exist: ' + AFolder);
    Exit;
  end;

  DeleteNamedFolders(
    AFolder,
    ['Win32', 'Win64', '__history', '__recovery'],
    Result.DeletedFolders,
    Result.Errors
  );

  DeleteMatchingFiles(
    AFolder,
    ['*.dcu', '*.obj', '*.dcpil', '*.identcache', '*.local', '*.stat'],
    Result.DeletedFiles,
    Result.Errors
  );

  Result.Success := Result.Errors.Count = 0;
end;

class function TProjectCleaner.CleanRepoFolder(
  const AFolder: string): TProjectCleanerResult;
begin
  Result := TProjectCleanerResult.Create;

  if Trim(AFolder) = '' then
  begin
    Result.Success := False;
    Result.Errors.Add('Repository folder is empty');
    Exit;
  end;

  if not DirectoryExists(AFolder) then
  begin
    Result.Success := False;
    Result.Errors.Add('Repository folder does not exist: ' + AFolder);
    Exit;
  end;

  DeleteNamedFolders(
    AFolder,
    ['Win32', 'Win64', '__history', '__recovery'],
    Result.DeletedFolders,
    Result.Errors
  );

  DeleteMatchingFiles(
    AFolder,
    ['*.dcu', '*.obj', '*.dcpil', '*.identcache', '*.local', '*.stat'],
    Result.DeletedFiles,
    Result.Errors
  );

  Result.Success := Result.Errors.Count = 0;
end;

end.
