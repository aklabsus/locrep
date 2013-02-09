unit akTotalLog;

interface

uses Windows, SysUtils;

type
  ELoggedAssertion = class(Exception);

  TTotalLog = class
  private
    fIsLogging: Boolean;
    fFileName: string;
    fIsDetailed: Boolean;

  protected
    procedure logdirect(str: string);
    function IsDetailedLog(fn: string): boolean;

  public
    property IsLogging: Boolean read fIsLogging;
    property IsDetailed: Boolean read fIsDetailed;
    property FileName: string read fFileName;

    constructor Create(createlog: Boolean); overload;
    constructor Create(fFileN: string; createlog: Boolean); overload;
    destructor Destroy; override;

    procedure logf(id: LongWord; const form: string; const Args: array of const);
    procedure log(id: LongWord; const str: string; comment: string = '');
    procedure logd(id: LongWord; const str: string; comment: string = '');
    procedure lassert(id: LongWord; exp: Boolean; comment: string = ''; raiseEx: Boolean = true);

    function IsBadStr(id: LongWord; Str: PChar; Max: Integer; comment: string): Boolean;
    function IsBadRPtr(id: LongWord; Str: Pointer; Size: Integer; comment: string): Boolean;
    function IsBadWPtr(id: LongWord; Str: Pointer; Size: Integer; comment: string): Boolean;

    procedure ShowLog;
  end;

var lg: TTotalLog;

implementation

uses comobj, akFileUtils, akTotalLogView;

{ TTotalLog }

constructor TTotalLog.Create(fFileN: string; createlog: Boolean);
begin
  inherited Create;
  fFileName := fFileN;
  if createlog then CreateFileIfNotExists(fFileName);
  fIsLogging := FileExists(fFileName);
  fIsDetailed := IsDetailedLog(fFileName);
end;

constructor TTotalLog.Create(createlog: Boolean);
var Buffer: array[0..260] of Char;
begin
  inherited Create;
  SetString(fFileName, Buffer, GetModuleFileName(HInstance, Buffer, SizeOf(Buffer)));
  fFileName := GetFileNameWOExt(fFileName) + '.log';
  if createlog then CreateFileIfNotExists(fFileName);
  fIsLogging := FileExists(fFileName);
  fIsDetailed := IsDetailedLog(fFileName);
end;

destructor TTotalLog.Destroy;
begin
  inherited;
end;

function TTotalLog.IsBadRPtr(id: LongWord; Str: Pointer; Size: Integer; comment: string): Boolean;
begin
  if (not Assigned(Self)) or (not IsLogging) then exit;

  Result := IsBadReadPtr(Str, Size);
  if Result then begin
    logd(id, 'The read pointer is not valid', comment);
    raise ELoggedAssertion.Create('The read pointer is not valid (' + comment + ')');
  end;
end;

function TTotalLog.IsBadStr(id: LongWord; Str: PChar; Max: Integer; comment: string): Boolean;
begin
  if (not Assigned(Self)) or (not IsLogging) then exit;

  Result := IsBadStringPtr(Str, Max);
  if Result then
    logd(id, 'The string pointer is not valid', comment);
end;

function TTotalLog.IsBadWPtr(id: LongWord; Str: Pointer; Size: Integer; comment: string): Boolean;
begin
  if (not Assigned(Self)) or (not IsLogging) then exit;

  Result := IsBadWritePtr(Str, Size);
  if Result then begin
    logd(id, 'The write pointer is not valid', comment);
    raise ELoggedAssertion.Create('The write pointer is not valid (' + comment + ')');
  end;
end;

function TTotalLog.IsDetailedLog(fn: string): Boolean;
var f: TextFile;
  s: string;
begin
  if not FileExists(fn) then Result := false;

  AssignFile(f, fn);
  Reset(f);
  try
    Readln(f, s);
    Result := lowercase(s) = 'detailed';
  finally
    Closefile(f);
  end;
end;

procedure TTotalLog.lassert(id: LongWord; exp: Boolean; comment: string; raiseEx: Boolean);
begin
  if (not Assigned(Self)) or (not IsLogging) then exit;

  if not exp then begin
    logd(id, 'Assertion failed', comment);
    if raiseEx then
      raise ELoggedAssertion.Create('Assertion failed (' + comment + ')');
  end;
end;

procedure TTotalLog.log(id: LongWord; const str: string; comment: string);
begin
  if IsDetailed then
    logd(id, str, comment);
end;

procedure TTotalLog.logd(id: LongWord; const str: string; comment: string);
var addon, st: string;
begin
  if (not Assigned(Self)) or (not IsLogging) then exit;

  if comment <> '' then
    st := Format(' [%s]', [comment])
  else
    st := '';

  if IsDetailed then
    addon := IntToHex(id, 8) + ' : '
  else
    addon := '';
    
  logdirect(FormatDateTime('mm.dd.yy hh":"mm ":" ', Now) + addon + str + st);
end;

procedure TTotalLog.logdirect(str: string);
var f: Textfile;
begin
  if (not Assigned(Self)) or (not IsLogging) then exit;

  try
    AssignFile(f, FileName);
    Append(f);
    try
      Writeln(f, str);
    finally
      Closefile(f);
    end;
  except {} end;
end;

procedure TTotalLog.logf(id: LongWord; const form: string; const Args: array of const);
begin
  logd(id, Format(form, Args));
end;

procedure TTotalLog.ShowLog;
var ftl: TfTotalLogView;
begin
  ftl := TfTotalLogView.Create(Self);
  try
    ftl.Execute;
  finally
    ftl.Free;
  end;
end;

end.

