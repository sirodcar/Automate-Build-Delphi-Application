unit MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  Xml.XMLDoc,
  Xml.XMLIntf,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.FileCtrl,
  Vcl.Samples.Spin,
  uTypes;

type
  TVersionInfo = record
    Major: Integer;
    Minor: Integer;
    Release: Integer;
    Build: Integer;
    class function Create(AMajor, AMinor, ARelease, ABuild: Integer): TVersionInfo; static;
    function ToText: string;
  end;

  TfrmMain = class(TForm)
    lblGitUrl: TLabel;
    edtGitUrl: TEdit;
    lblBaseFolder: TLabel;
    edtBaseFolder: TEdit;
    btnBrowseBaseFolder: TButton;
    lblRepoFolder: TLabel;
    edtRepoFolder: TEdit;
    btnBrowseRepoFolder: TButton;
    lblDelphi: TLabel;
    cmbDelphi: TComboBox;
    btnReloadDelphi: TButton;
    lblProjects: TLabel;
    cmbProjects: TComboBox;
    lblConfig: TLabel;
    cmbConfig: TComboBox;
    lblPlatform: TLabel;
    cmbPlatform: TComboBox;
    lblDcuOutput: TLabel;
    edtDcuOutput: TEdit;
    btnBrowseDcuOutput: TButton;
    lblExeOutput: TLabel;
    edtExeOutput: TEdit;
    btnBrowseExeOutput: TButton;
    lblCurrentVersion: TLabel;
    edtCurrentVersion: TEdit;
    lblNewVersion: TLabel;
    lblMajor: TLabel;
    lblMinor: TLabel;
    lblRelease: TLabel;
    lblBuild: TLabel;
    spnMajor: TSpinEdit;
    spnMinor: TSpinEdit;
    spnRelease: TSpinEdit;
    spnBuild: TSpinEdit;
    btnClone: TButton;
    btnPull: TButton;
    btnScanProjects: TButton;
    btnBuild: TButton;
    memLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnReloadDelphiClick(Sender: TObject);
    procedure btnBrowseBaseFolderClick(Sender: TObject);
    procedure btnBrowseRepoFolderClick(Sender: TObject);
    procedure btnBrowseDcuOutputClick(Sender: TObject);
    procedure btnBrowseExeOutputClick(Sender: TObject);
    procedure btnCloneClick(Sender: TObject);
    procedure btnPullClick(Sender: TObject);
    procedure btnScanProjectsClick(Sender: TObject);
    procedure btnBuildClick(Sender: TObject);
    procedure cmbProjectsChange(Sender: TObject);
  private
    FDelphiList: TObjectList<TDelphiInstallInfo>;
    procedure Log(const AMsg: string);
    procedure LoadDelphiVersions;
    procedure FillDelphiCombo;
    function GetSelectedDelphi: TDelphiInstallInfo;
    function GetSelectedProject: string;
    procedure ScanProjects;
    function ReadProjectVersion(const ADProjFile: string; out AVersion: TVersionInfo): Boolean;
    procedure LoadProjectVersionToUI;
    function GetUIVersion: TVersionInfo;
    procedure SetUIVersion(const AVersion: TVersionInfo);
    function CompareVersion(const ALeft, ARight: TVersionInfo): Integer;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  uDelphiDetector,
  uGitHelper,
  uProjectScanner,
  uBuildHelper,
  uProcessRunner,
  uProjectCleaner;

{ TVersionInfo }

class function TVersionInfo.Create(AMajor, AMinor, ARelease,
  ABuild: Integer): TVersionInfo;
begin
  Result.Major := AMajor;
  Result.Minor := AMinor;
  Result.Release := ARelease;
  Result.Build := ABuild;
end;

function TVersionInfo.ToText: string;
begin
  Result := Format('%d.%d.%d.%d', [Major, Minor, Release, Build]);
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FDelphiList := TObjectList<TDelphiInstallInfo>.Create(True);

  cmbConfig.Items.Clear;
  cmbConfig.Items.Add('Debug');
  cmbConfig.Items.Add('Release');
  cmbConfig.ItemIndex := 1;

  cmbPlatform.Items.Clear;
  cmbPlatform.Items.Add('Win32');
  cmbPlatform.Items.Add('Win64');
  cmbPlatform.ItemIndex := 0;

  edtBaseFolder.Text := IncludeTrailingPathDelimiter(GetCurrentDir) + 'repos';
  edtDcuOutput.Text := IncludeTrailingPathDelimiter(GetCurrentDir) + 'build\dcu';
  edtExeOutput.Text := IncludeTrailingPathDelimiter(GetCurrentDir) + 'build\bin';

  edtCurrentVersion.ReadOnly := True;
  edtCurrentVersion.Text := '';

  spnMajor.MinValue := 0;
  spnMajor.MaxValue := 65535;
  spnMinor.MinValue := 0;
  spnMinor.MaxValue := 65535;
  spnRelease.MinValue := 0;
  spnRelease.MaxValue := 65535;
  spnBuild.MinValue := 0;
  spnBuild.MaxValue := 65535;

  spnMajor.Value := 1;
  spnMinor.Value := 0;
  spnRelease.Value := 0;
  spnBuild.Value := 0;

  Log('Application started');
  LoadDelphiVersions;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FDelphiList.Free;
end;

procedure TfrmMain.Log(const AMsg: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AMsg);
end;

procedure TfrmMain.LoadDelphiVersions;
begin
  Log('Scanning installed Delphi versions...');
  TDelphiDetector.LoadInstalledDelphi(FDelphiList);
  FillDelphiCombo;

  if cmbDelphi.Items.Count > 0 then
    Log(Format('Found %d Delphi installation(s)', [cmbDelphi.Items.Count]))
  else
    Log('No Delphi installations found');
end;

procedure TfrmMain.FillDelphiCombo;
var
  LItem: TDelphiInstallInfo;
begin
  cmbDelphi.Items.Clear;

  for LItem in FDelphiList do
    cmbDelphi.Items.AddObject(LItem.ToDisplayText, LItem);

  if cmbDelphi.Items.Count > 0 then
    cmbDelphi.ItemIndex := 0;
end;

function TfrmMain.GetSelectedDelphi: TDelphiInstallInfo;
begin
  Result := nil;
  if cmbDelphi.ItemIndex >= 0 then
    Result := TDelphiInstallInfo(cmbDelphi.Items.Objects[cmbDelphi.ItemIndex]);
end;

function TfrmMain.GetSelectedProject: string;
begin
  Result := '';
  if cmbProjects.ItemIndex >= 0 then
    Result := cmbProjects.Items[cmbProjects.ItemIndex];
end;

procedure TfrmMain.btnReloadDelphiClick(Sender: TObject);
begin
  LoadDelphiVersions;
end;

procedure TfrmMain.btnBrowseBaseFolderClick(Sender: TObject);
var
  LDir: string;
begin
  LDir := edtBaseFolder.Text;
  if SelectDirectory('Select base folder', '', LDir) then
    edtBaseFolder.Text := LDir;
end;

procedure TfrmMain.btnBrowseRepoFolderClick(Sender: TObject);
var
  LDir: string;
begin
  LDir := edtRepoFolder.Text;
  if SelectDirectory('Select repository folder', '', LDir) then
    edtRepoFolder.Text := LDir;
end;

procedure TfrmMain.btnBrowseDcuOutputClick(Sender: TObject);
var
  LDir: string;
begin
  LDir := edtDcuOutput.Text;
  if SelectDirectory('Select DCU output folder', '', LDir) then
    edtDcuOutput.Text := LDir;
end;

procedure TfrmMain.btnBrowseExeOutputClick(Sender: TObject);
var
  LDir: string;
begin
  LDir := edtExeOutput.Text;
  if SelectDirectory('Select EXE output folder', '', LDir) then
    edtExeOutput.Text := LDir;
end;

procedure TfrmMain.btnCloneClick(Sender: TObject);
var
  LGitUrl: string;
  LBaseFolder: string;
  LResult: TProcessResult;
  LRepoName: string;
  LRepoFolder: string;
begin
  LGitUrl := Trim(edtGitUrl.Text);
  LBaseFolder := Trim(edtBaseFolder.Text);

  if LGitUrl = '' then
    raise Exception.Create('Please enter GitHub URL');

  if LBaseFolder = '' then
    raise Exception.Create('Please enter base folder');

  if not TDirectory.Exists(LBaseFolder) then
    TDirectory.CreateDirectory(LBaseFolder);

  LRepoName := TGitHelper.ExtractRepoFolderName(LGitUrl);
  LRepoFolder := IncludeTrailingPathDelimiter(LBaseFolder) + LRepoName;

  if TDirectory.Exists(LRepoFolder) then
  begin
    if MessageDlg(
      'Repository folder already exists:' + sLineBreak +
      LRepoFolder + sLineBreak + sLineBreak +
      'Do you want to delete it and re-clone?',
      mtConfirmation,
      [mbYes, mbNo],
      0
    ) <> mrYes then
    begin
      Log('Clone cancelled by user');
      Exit;
    end;

    Log('Deleting existing folder: ' + LRepoFolder);
    try
      TDirectory.Delete(LRepoFolder, True);
      Log('Folder deleted');
    except
      on E: Exception do
      begin
        Log('Failed to delete folder: ' + E.Message);
        Exit;
      end;
    end;
  end;

  Log('Cloning repository...');
  Log('URL: ' + LGitUrl);
  Log('Base folder: ' + LBaseFolder);

  LResult := TGitHelper.CloneRepository(LGitUrl, LBaseFolder);

  if LResult.Success then
  begin
    Log('Clone successful');
    if Trim(LResult.Output) <> '' then
      Log(LResult.Output);

    edtRepoFolder.Text := LRepoFolder;
    ScanProjects;
  end
  else
  begin
    Log('Clone failed. ExitCode=' + LResult.ExitCode.ToString);
    if Trim(LResult.Output) <> '' then
      Log(LResult.Output);
  end;
end;

procedure TfrmMain.btnPullClick(Sender: TObject);
var
  LRepoFolder: string;
  LResult: TProcessResult;
begin
  LRepoFolder := Trim(edtRepoFolder.Text);

  if LRepoFolder = '' then
    raise Exception.Create('Please select repository folder');

  if not TDirectory.Exists(LRepoFolder) then
    raise Exception.Create('Repository folder does not exist');

  Log('Running git pull...');
  LResult := TGitHelper.PullRepository(LRepoFolder);

  if LResult.Success then
  begin
    Log('Pull successful');
    if Trim(LResult.Output) <> '' then
      Log(LResult.Output);
    ScanProjects;
  end
  else
  begin
    Log('Pull failed. ExitCode=' + LResult.ExitCode.ToString);
    if Trim(LResult.Output) <> '' then
      Log(LResult.Output);
  end;
end;

procedure TfrmMain.btnScanProjectsClick(Sender: TObject);
begin
  ScanProjects;
end;

procedure TfrmMain.ScanProjects;
begin
  cmbProjects.Items.Clear;
  edtCurrentVersion.Text := '';

  if Trim(edtRepoFolder.Text) = '' then
    Exit;

  Log('Scanning for .dproj files...');
  TProjectScanner.FindDProjFiles(edtRepoFolder.Text, cmbProjects.Items);

  if cmbProjects.Items.Count > 0 then
  begin
    cmbProjects.ItemIndex := 0;
    Log(Format('Found %d project(s)', [cmbProjects.Items.Count]));
    LoadProjectVersionToUI;
  end
  else
    Log('No .dproj files found');
end;

procedure TfrmMain.cmbProjectsChange(Sender: TObject);
begin
  LoadProjectVersionToUI;
end;

function TfrmMain.ReadProjectVersion(const ADProjFile: string;
  out AVersion: TVersionInfo): Boolean;
var
  LDoc: IXMLDocument;
  LRoot: IXMLNode;
  I, J: Integer;
  LNode: IXMLNode;
  LChild: IXMLNode;
begin
  Result := False;
  AVersion := TVersionInfo.Create(0, 0, 0, 0);

  if not FileExists(ADProjFile) then
    Exit;

  LDoc := TXMLDocument.Create(nil);
  LDoc.Options := [doNodeAutoCreate, doNodeAutoIndent];
  LDoc.LoadFromFile(ADProjFile);
  LDoc.Active := True;

  LRoot := LDoc.DocumentElement;
  if not Assigned(LRoot) then
    Exit;

  for I := 0 to LRoot.ChildNodes.Count - 1 do
  begin
    LNode := LRoot.ChildNodes[I];
    if SameText(LNode.NodeName, 'PropertyGroup') then
    begin
      for J := 0 to LNode.ChildNodes.Count - 1 do
      begin
        LChild := LNode.ChildNodes[J];

        if SameText(LChild.NodeName, 'VerInfo_MajorVer') then
          AVersion.Major := StrToIntDef(Trim(LChild.Text), AVersion.Major)
        else if SameText(LChild.NodeName, 'VerInfo_MinorVer') then
          AVersion.Minor := StrToIntDef(Trim(LChild.Text), AVersion.Minor)
        else if SameText(LChild.NodeName, 'VerInfo_Release') then
          AVersion.Release := StrToIntDef(Trim(LChild.Text), AVersion.Release)
        else if SameText(LChild.NodeName, 'VerInfo_Build') then
          AVersion.Build := StrToIntDef(Trim(LChild.Text), AVersion.Build);
      end;
    end;
  end;

  Result := True;
end;

procedure TfrmMain.LoadProjectVersionToUI;
var
  LDProj: string;
  LVersion: TVersionInfo;
begin
  edtCurrentVersion.Text := '';

  LDProj := GetSelectedProject;
  if LDProj = '' then
    Exit;

  if ReadProjectVersion(LDProj, LVersion) then
  begin
    edtCurrentVersion.Text := LVersion.ToText;
    SetUIVersion(LVersion);
    Log('Project version loaded: ' + LVersion.ToText);
  end
  else
  begin
    edtCurrentVersion.Text := '0.0.0.0';
    SetUIVersion(TVersionInfo.Create(0, 0, 0, 0));
    Log('Could not read version from project file');
  end;
end;

function TfrmMain.GetUIVersion: TVersionInfo;
begin
  Result := TVersionInfo.Create(
    spnMajor.Value,
    spnMinor.Value,
    spnRelease.Value,
    spnBuild.Value
  );
end;

procedure TfrmMain.SetUIVersion(const AVersion: TVersionInfo);
begin
  spnMajor.Value := AVersion.Major;
  spnMinor.Value := AVersion.Minor;
  spnRelease.Value := AVersion.Release;
  spnBuild.Value := AVersion.Build;
end;

function TfrmMain.CompareVersion(const ALeft, ARight: TVersionInfo): Integer;
begin
  if ALeft.Major > ARight.Major then Exit(1)
  else if ALeft.Major < ARight.Major then Exit(-1);

  if ALeft.Minor > ARight.Minor then Exit(1)
  else if ALeft.Minor < ARight.Minor then Exit(-1);

  if ALeft.Release > ARight.Release then Exit(1)
  else if ALeft.Release < ARight.Release then Exit(-1);

  if ALeft.Build > ARight.Build then Exit(1)
  else if ALeft.Build < ARight.Build then Exit(-1);

  Result := 0;
end;

procedure TfrmMain.btnBuildClick(Sender: TObject);
var
  LDelphi: TDelphiInstallInfo;
  LDProj: string;
  LConfig: string;
  LPlatform: string;
  LDcuOutput: string;
  LExeOutput: string;
  LCurrentVersion: TVersionInfo;
  LNewVersion: TVersionInfo;
  LCompare: Integer;
  LResult: TProcessResult;
  LCleanResult: TProjectCleanerResult;
  I: Integer;
  LProjectFolder: string;
begin
  LDelphi := GetSelectedDelphi;
  if LDelphi = nil then
    raise Exception.Create('Please select Delphi version');

  LDProj := GetSelectedProject;
  if LDProj = '' then
    raise Exception.Create('Please select project file');

  if not ReadProjectVersion(LDProj, LCurrentVersion) then
    raise Exception.Create('Could not read current version from project file');

  LNewVersion := GetUIVersion;
  LCompare := CompareVersion(LNewVersion, LCurrentVersion);

  if LCompare <= 0 then
  begin
    raise Exception.CreateFmt(
      'New version must be higher than current project version.' + sLineBreak +
      'Current: %s' + sLineBreak +
      'Selected: %s',
      [LCurrentVersion.ToText, LNewVersion.ToText]
    );
  end;

  if MessageDlg(
    'Current project version: ' + LCurrentVersion.ToText + sLineBreak +
    'New build version: ' + LNewVersion.ToText + sLineBreak + sLineBreak +
    'Build using the new version?',
    mtConfirmation,
    [mbYes, mbNo],
    0
  ) <> mrYes then
  begin
    Log('Build cancelled by user');
    Exit;
  end;

  LConfig := cmbConfig.Text;
  LPlatform := cmbPlatform.Text;
  LDcuOutput := Trim(edtDcuOutput.Text);
  LExeOutput := Trim(edtExeOutput.Text);

  if LDcuOutput <> '' then
    ForceDirectories(LDcuOutput);

  if LExeOutput <> '' then
    ForceDirectories(LExeOutput);

  LProjectFolder := ExtractFilePath(LDProj);

  Log('Cleaning project output folders...');
  LCleanResult := TProjectCleaner.CleanProjectFolder(LProjectFolder);
  try
    for I := 0 to LCleanResult.DeletedFolders.Count - 1 do
      Log('Deleted folder: ' + LCleanResult.DeletedFolders[I]);

    for I := 0 to LCleanResult.DeletedFiles.Count - 1 do
      Log('Deleted file: ' + LCleanResult.DeletedFiles[I]);

    for I := 0 to LCleanResult.Errors.Count - 1 do
      Log('Clean warning: ' + LCleanResult.Errors[I]);

    if LCleanResult.Success then
      Log('Project clean completed')
    else
      Log('Project clean completed with warnings');
  finally
    LCleanResult.Done;
  end;

  Log('Build started');
  Log('Delphi: ' + LDelphi.DisplayName);
  Log('RootDir: ' + LDelphi.RootDir);
  Log('RsVarsBat: ' + LDelphi.RsVarsBat);
  Log('MSBuildExe: ' + LDelphi.MSBuildExe);
  Log('Project: ' + LDProj);
  Log('Config: ' + LConfig);
  Log('Platform: ' + LPlatform);
  Log('Current Version: ' + LCurrentVersion.ToText);
  Log('New Version: ' + LNewVersion.ToText);
  Log('DCU Output: ' + LDcuOutput);
  Log('EXE Output: ' + LExeOutput);

  LResult := TBuildHelper.BuildProject(
    LDelphi,
    LDProj,
    LConfig,
    LPlatform,
    LDcuOutput,
    LExeOutput,
    LNewVersion.Major,
    LNewVersion.Minor,
    LNewVersion.Release,
    LNewVersion.Build
  );

  if LResult.Success then
  begin
    Log('Build successful');
    if Trim(LResult.Output) <> '' then
      Log(LResult.Output);
  end
  else
  begin
    Log('Build failed. ExitCode=' + LResult.ExitCode.ToString);
    if Trim(LResult.Output) <> '' then
      Log(LResult.Output);
  end;
end;

end.