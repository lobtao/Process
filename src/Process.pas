unit Process;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Generics.Collections;

type
  IProcess = interface
    function GetProcessHandle(): THandle;
    function GetThreadHandle(): THandle;
    function GetProcessId(): Cardinal;
    function GetThreadId(): Cardinal;

    function WaitForInputIdle(milliseconds: Cardinal): Cardinal;
    function WaitForExit(milliseconds: Cardinal): Cardinal;

    property ProcessHandle: THandle  read GetProcessHandle;
    property ThreadHandle:  THandle  read GetThreadHandle;
    property ProcessId:     Cardinal read GetProcessId;
    property ThreadId:      Cardinal read GetThreadId;
  end;

  IProcessBuilder = interface;

  IStartUpInfoBuilder = interface
    function Flags(flags: Cardinal): IStartUpInfoBuilder;
    function ShowWindow(showWindow: Word): IStartUpInfoBuilder;

    function Build(): IProcessBuilder;
  end;

  ICommandLineArgsBuilder = interface
    function Arg(name: string; value: string = ''): ICommandLineArgsBuilder;
    function Build(): IProcessBuilder;
  end;

  IProcessBuilder = interface
    function Name(name: string): IProcessBuilder;
    function CommandLineArgs(): ICommandLineArgsBuilder;
    function InheritHandles(inheritHandles: boolean): IProcessBuilder;
    function Flags(flags: Cardinal): IProcessBuilder;
    function Directory(directory: string): IProcessBuilder;
    function StartInfo(): IStartUpInfoBuilder;

    function TryStart(out process: IProcess): boolean;
  end;

  TProcess = class(TInterfacedObject, IProcess)
  strict private
    fProcessHandle: THandle;
    fThreadHandle: THandle;
    fProcessId: Cardinal;
    fThreadId: Cardinal;

    fAutoCloseHandles: boolean;
  protected
    function GetProcessHandle(): THandle;
    function GetThreadHandle(): THandle;
    function GetProcessId(): Cardinal;
    function GetThreadId(): Cardinal;

    function WaitForInputIdle(milliseconds: Cardinal): Cardinal;
    function WaitForExit(milliseconds: Cardinal): Cardinal;

    constructor Create(processInfo: TProcessInformation; autoCloseHandles: boolean);
    destructor Destroy(); override;
  public
    class function New(autoCloseHandles: boolean = True): IProcessBuilder; overload;
    class function New(appName: string; autoCloseHandles: boolean = True): IProcessBuilder; overload;
  end;

implementation

type
  TProcessBuilder = class;

  TStartUpInfoBuilder = class(TInterfacedObject, IStartUpInfoBuilder)
  strict private
    fProcessBuilder: TProcessBuilder;
  protected
    function Flags(flags: Cardinal): IStartUpInfoBuilder;
    function ShowWindow(showWindow: Word): IStartUpInfoBuilder;
    function Build(): IProcessBuilder;
  public
    constructor Create(processBuilder: TProcessBuilder);
  end;

  TCommandLineArgsBuilder = class(TInterfacedObject, ICommandLineArgsBuilder)
  strict private
    fProcessBuilder: TProcessBuilder;
  protected
    function Arg(name: string; value: string = ''): ICommandLineArgsBuilder;
    function Build(): IProcessBuilder;
  public
    constructor Create(processBuilder: TProcessBuilder);
  end;

  TProcessBuilder = class(TInterfacedObject, IProcessBuilder)
  strict private
    fAppName: string;
    fInheritHandles: boolean;
    fFlags: Cardinal;
    fDirectory: string;

    fAutoCloseHandles: boolean;

    function CommandLineArgsToString(): string;
  protected
    fCommandLineArgs: TDictionary<string, string>;
    fStartInfo: TStartUpInfo;

    function Name(name: string): IProcessBuilder;
    function CommandLineArgs(): ICommandLineArgsBuilder;
    function InheritHandles(inheritHandles: boolean): IProcessBuilder;
    function Flags(flags: Cardinal): IProcessBuilder;
    function Directory(directory: string): IProcessBuilder;
    function StartInfo(): IStartUpInfoBuilder;

    function TryStart(out process: IProcess): boolean;
  public
    constructor Create(autoCloseHandles: boolean);
    destructor Destroy(); override;
  end;

function ToPWideChar(s: string): PWideChar;
begin
  Result := PWideChar(WideString(s));
end;

function ToPWideCharOrNull(s: string): PWideChar;
begin
  if string.IsNullOrEmpty(s) then
    Exit(nil);
  Result := ToPWideChar(s);
end;

{ TProcess }

constructor TProcess.Create(processInfo: TProcessInformation; autoCloseHandles: boolean);
begin
  with processInfo do
  begin
    fProcessHandle := hProcess;
    fThreadHandle  := hThread;
    fProcessId := dwProcessId;
    fThreadId  := dwThreadId;
  end;
end;

destructor TProcess.Destroy;
begin
  if fAutoCloseHandles then
  begin
    CloseHandle(fProcessHandle);
    CloseHandle(fThreadHandle);
  end;
  inherited;
end;

function TProcess.GetProcessHandle: THandle;
begin
  Result := fProcessHandle;
end;

function TProcess.GetThreadHandle: THandle;
begin
  Result := fThreadHandle;
end;

function TProcess.GetProcessId: Cardinal;
begin
  Result := fProcessId;
end;

function TProcess.GetThreadId: Cardinal;
begin
  Result := fThreadId;
end;

class function TProcess.New(autoCloseHandles: boolean): IProcessBuilder;
begin
  Result := TProcessBuilder.Create(autoCloseHandles);
end;

class function TProcess.New(appName: string; autoCloseHandles: boolean): IProcessBuilder;
begin
  Result := New(autoCloseHandles).Name(appName);
end;

function TProcess.WaitForInputIdle(milliseconds: Cardinal): Cardinal;
begin
  Result := Winapi.Windows.WaitForInputIdle(fProcessHandle, milliseconds);
end;

function TProcess.WaitForExit(milliseconds: Cardinal): Cardinal;
begin
  Result := WaitForSingleObject(fProcessHandle, milliseconds);
end;

{ TProcessStartInfoBuilder }

constructor TStartUpInfoBuilder.Create(processBuilder: TProcessBuilder);
begin
  fProcessBuilder := processBuilder;
end;

function TStartUpInfoBuilder.Flags(
  flags: Cardinal): IStartUpInfoBuilder;
begin
  fProcessBuilder.fStartInfo.dwFlags := flags;
  Result := Self;
end;

function TStartUpInfoBuilder.ShowWindow(showWindow: Word): IStartUpInfoBuilder;
begin
  fProcessBuilder.fStartInfo.wShowWindow := showWindow;
  Result := Self;
end;

function TStartUpInfoBuilder.Build: IProcessBuilder;
begin
  Result := fProcessBuilder;
end;

{ TCommandLineArgsBuilder }

constructor TCommandLineArgsBuilder.Create(processBuilder: TProcessBuilder);
begin
  fProcessBuilder := processBuilder;
end;

function TCommandLineArgsBuilder.Arg(name, value: string): ICommandLineArgsBuilder;
begin
  fProcessBuilder.fCommandLineArgs.AddOrSetValue(name, value);
  Result := Self;
end;

function TCommandLineArgsBuilder.Build: IProcessBuilder;
begin
  Result := fProcessBuilder;
end;

{ TProcessBuilder }

constructor TProcessBuilder.Create(autoCloseHandles: boolean);
begin
  fAutoCloseHandles := autoCloseHandles;
  fCommandLineArgs  := TDictionary<string, string>.Create();
  fInheritHandles   := False;
  fDirectory        := '';
  fStartInfo.cb     := SizeOf(TStartupInfo);
end;

destructor TProcessBuilder.Destroy;
begin
  fCommandLineArgs.Free();
  inherited;
end;

function TProcessBuilder.Name(name: string): IProcessBuilder;
begin
  fAppName := name;
  Result := Self;
end;

function TProcessBuilder.CommandLineArgs: ICommandLineArgsBuilder;
begin
  Result := TCommandLineArgsBuilder.Create(Self);
end;

function TProcessBuilder.Flags(flags: Cardinal): IProcessBuilder;
begin
  fFlags := flags;
  Result := Self;
end;

function TProcessBuilder.InheritHandles(
  inheritHandles: boolean): IProcessBuilder;
begin
  fInheritHandles := inheritHandles;
  Result := Self;
end;

function TProcessBuilder.Directory(directory: string): IProcessBuilder;
begin
  fDirectory := directory;
  Result := Self;
end;

function TProcessBuilder.StartInfo: IStartUpInfoBuilder;
begin
  Result := TStartUpInfoBuilder.Create(Self);
end;

function TProcessBuilder.TryStart(out process: IProcess): boolean;
var
  processInfo: TProcessInformation;
begin
  Result := CreateProcess(
    ToPWideChar(fAppName),
    ToPWideChar(CommandLineArgsToString()),
    nil{ProcessAttributes},
    nil{ThreadAtrributes},
    fInheritHandles,
    fFlags,
    nil{environment},
    ToPWideCharOrNull(fDirectory),
    fStartInfo,
    processInfo);

  if result then
    process := TProcess.Create(processInfo, fAutoCloseHandles)
  else
    Writeln(GetLastError());
end;

function TProcessBuilder.CommandLineArgsToString: string;
var
  arg: TPair<string, string>;
  args: string;
begin
  for arg in fCommandLineArgs do
  begin
    args := args + ' ' + arg.Key;
    if not arg.Value.IsEmpty() then
      args := args + '="' + arg.Value + '"';
  end;
  Result := args.Trim();
end;

end.
