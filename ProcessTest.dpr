program ProcessTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Winapi.Windows,
  System.SysUtils,
  Process in 'src\Process.pas';

var
  process: IProcess;
  result: boolean;

begin
  result := TProcess.New('notepad.exe')
    .CommandLineArgs()
      .Arg('input.txt')
      .Build()
    .Flags(NORMAL_PRIORITY_CLASS)
    .StartInfo()
      .Flags(STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK)
      .ShowWindow(SW_SHOWNORMAL)
      .Build()
    .TryStart(process);

  if result then
  begin
    process.WaitForInputIdle(INFINITE);
    Writeln(process.ProcessId);
    process.WaitForExit(INFINITE);
  end;
end.
