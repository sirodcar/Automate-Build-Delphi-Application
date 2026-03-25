unit uTypes;

interface

uses
  System.SysUtils;

type
  TDelphiInstallInfo = class
  private
    FVersionKey: string;
    FDisplayName: string;
    FRootDir: string;
    FBdsExe: string;
    FRsVarsBat: string;
    FMSBuildExe: string;
  public
    property VersionKey: string read FVersionKey write FVersionKey;
    property DisplayName: string read FDisplayName write FDisplayName;
    property RootDir: string read FRootDir write FRootDir;
    property BdsExe: string read FBdsExe write FBdsExe;
    property RsVarsBat: string read FRsVarsBat write FRsVarsBat;
    property MSBuildExe: string read FMSBuildExe write FMSBuildExe;

    function ToDisplayText: string;
  end;

implementation

function TDelphiInstallInfo.ToDisplayText: string;
begin
  Result := Format('%s [%s] - %s', [DisplayName, VersionKey, RootDir]);
end;

end.