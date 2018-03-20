# Process
Simple wrapper for CreateProcess function

# Example
```delphi
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
```
