program DelphiGitHubBuilder;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  uTypes in 'uTypes.pas',
  uDelphiDetector in 'uDelphiDetector.pas',
  uProcessRunner in 'uProcessRunner.pas',
  uGitHelper in 'uGitHelper.pas',
  uBuildHelper in 'uBuildHelper.pas',
  uProjectScanner in 'uProjectScanner.pas',
  uProjectCleaner in 'uProjectCleaner.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Delphi GitHub Builder';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
