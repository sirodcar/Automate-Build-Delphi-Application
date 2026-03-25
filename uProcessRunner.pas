unit uProcessRunner;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes;

type
  TProcessResult = record
    Success: Boolean;
    ExitCode: Cardinal;
    Output: string;
  end;

  TProcessRunner = class
  public
    class function Run(const ACommandLine, AWorkingDir: string): TProcessResult;
  end;

implementation

class function TProcessRunner.Run(const ACommandLine,
  AWorkingDir: string): TProcessResult;
var
  LSA: TSecurityAttributes;
  LStdOutRead: THandle;
  LStdOutWrite: THandle;
  LSI: TStartupInfo;
  LPI: TProcessInformation;
  LBuffer: array[0..4095] of AnsiChar;
  LBytesRead: DWORD;
  LCmd: string;
  LExitCode: DWORD;
  LChunk: AnsiString;
begin
  Result.Success := False;
  Result.ExitCode := Cardinal(-1);
  Result.Output := '';

  FillChar(LSA, SizeOf(LSA), 0);
  LSA.nLength := SizeOf(LSA);
  LSA.bInheritHandle := True;

  LStdOutRead := 0;
  LStdOutWrite := 0;

  if not CreatePipe(LStdOutRead, LStdOutWrite, @LSA, 0) then
    RaiseLastOSError;

  try
    SetHandleInformation(LStdOutRead, HANDLE_FLAG_INHERIT, 0);

    FillChar(LSI, SizeOf(LSI), 0);
    LSI.cb := SizeOf(LSI);
    LSI.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    LSI.wShowWindow := SW_HIDE;
    LSI.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    LSI.hStdOutput := LStdOutWrite;
    LSI.hStdError := LStdOutWrite;

    FillChar(LPI, SizeOf(LPI), 0);

    LCmd := 'cmd.exe /C ' + ACommandLine;

    if not CreateProcess(
      nil,
      PChar(LCmd),
      nil,
      nil,
      True,
      CREATE_NO_WINDOW,
      nil,
      PChar(AWorkingDir),
      LSI,
      LPI
    ) then
      RaiseLastOSError;

    CloseHandle(LStdOutWrite);
    LStdOutWrite := 0;

    try
      repeat
        LBytesRead := 0;
        if ReadFile(LStdOutRead, LBuffer, SizeOf(LBuffer) - 1, LBytesRead, nil) and
           (LBytesRead > 0) then
        begin
          LBuffer[LBytesRead] := #0;
          LChunk := AnsiString(LBuffer);
          Result.Output := Result.Output + string(LChunk);
        end
        else
        begin
          if WaitForSingleObject(LPI.hProcess, 50) = WAIT_OBJECT_0 then
            Break;
        end;
      until False;

      WaitForSingleObject(LPI.hProcess, INFINITE);
      GetExitCodeProcess(LPI.hProcess, LExitCode);

      Result.ExitCode := LExitCode;
      Result.Success := (LExitCode = 0);
    finally
      CloseHandle(LPI.hThread);
      CloseHandle(LPI.hProcess);
    end;
  finally
    if LStdOutWrite <> 0 then
      CloseHandle(LStdOutWrite);
    if LStdOutRead <> 0 then
      CloseHandle(LStdOutRead);
  end;
end;

end.