// AKTools akLogUtils unit.
//         Модуль, содержащий функции по работе с логами.
//=============================================================================

unit akLogUtils;

interface

uses SysUtils, Classes;

// типы журналируемых событий
const
  LOG_ERROR = 0;
  LOG_WARNING = 1;
  LOG_INFORM = 2;
  LOG_SUCCESS = 3;
  LOG_FAILURE = 4;
  LOG_REPORT = 5;

type
  TReportItem = class(TCollectionItem)
  private
    fDate: TDateTime;
    fDesc: string;
  public
    property RpDate: TDateTime read fDate write fDate;
    property RpDesc: string read fDesc write fDesc;

    procedure SetItem(Desc: string);
  end;

   // Коллекция строк рапорта
  TRepCollection = class(TCollection)
  protected
    function GetItem(Index: Integer): TReportItem;
    procedure SetItem(Index: Integer; const Value: TReportItem);
  public
    constructor Create;
    destructor Destroy; override;
    function Add: TReportItem;
    function FindItemID(ID: Integer): TReportItem;
    function Insert(Index: Integer): TReportItem;
    property Items[Index: Integer]: TReportItem read GetItem write SetItem; default;
  end;

   // Класс для работы с файловыми логами.
   // Рекомендуется создавать при старте программы и удалять по выходу из нее.
  TFileLog = class(TObject)
  private
    fName: string;
    fLineTimeFmt: string;
    fLineSep: string;
    fDateLineFormat: string;
    fAttribChars: string;
    fCreateLineFmt: string;
    fRunAppMessage: string;

    fRecentlyRun: Boolean;
    fPrevDate: TDateTime;
    fLogDisabled: Boolean;
    function MakeLogStr(wType: Integer; Desc: string): string;
  protected
    procedure AfterCreate;
  public
    constructor Create(fn: string);
    destructor Destroy; override;

    procedure ReportEvent(wType: Integer; Desc: string);
    procedure ReportEventFmt(wType: Integer; Desc: string; arr: array of const);

    procedure GetReportLines(lines: TRepCollection);

    property LogDisabled: Boolean read fLogDisabled write fLogDisabled;

  published
    property CreateLineFormat: string read fCreateLineFmt write fCreateLineFmt;
    property ShortTimeFormat: string read fLineTimeFmt write fLineTimeFmt;
    property LineSep: string read fLineSep write fLineSep;
    property DateLineFormat: string read fDateLineFormat write fDateLineFormat;
    property AttribChars: string read fAttribChars write fAttribChars;
    property RunAppMessage: string read fRunAppMessage write fRunAppMessage;
  end;

procedure LogClearTimer();
procedure AddLineToLog(fn, str: string; benchmark:integer=0);


implementation

uses windows, akFileUtils;

var benchmark_timer:DWORD;

procedure LogClearTimer();
begin
  benchmark_timer := GetTickCount;
end;

procedure AddLineToLog(fn, str: string; benchmark:integer);
var f: TextFile;
    duration: DWORD;
    display: boolean;
begin
  if benchmark_timer = 0 then LogClearTimer();
  duration := GetTickCount - benchmark_timer;
  if (benchmark>0) then begin
    display := duration>benchmark;
  end else
    display := true;
  benchmark_timer := GetTickCount;

  if not display then exit;

  CreateFileIfNotExists(fn);
  AssignFile(f, fn);
  try
    Append(f);
    if (benchmark>0) then Write(f, duration: 5, '] ');
    Write(f, DateTimeToStr(Now): 20, '  ', str);
    Writeln(f);
  finally
    Closefile(f);
  end;
end;

//==============================================================================
//******************************************************************************
// TFileLog
//******************************************************************************
//==============================================================================

procedure TFileLog.AfterCreate;
begin
  ReportEvent(0, '');
end;

constructor TFileLog.Create(fn: string);
var dir: string;
begin
  fLogDisabled := false;
  CreateLineFormat := '  hh:mm | ======================[ dd.mmmm.yyyy ]====================';
  DateLineFormat := '  hh:mm | --------------------- [ dd.mmmm.yyyy ] -------------------';
  ShortTimeFormat := ' hh:mm';
  RunAppMessage := ' ########## Application started ##########';
  LineSep := ' | ';
  AttribChars := '!* >! ';
  GetDir(0, dir);
  fRecentlyRun := True;
  fName := CompletePath(fn, dir);
//  AfterCreate;
end;

destructor TFileLog.Destroy;
begin
  inherited;

end;

procedure TFileLog.GetReportLines(lines: TRepCollection);
var f: TextFile;
  ln: string;
  repps: Integer;
  ritem: TReportItem;
  RepSt: string;
  RepStLen: Integer;
begin
  try
    lines.Clear;
    if not FileExists(fName) then exit;
    AssignFile(f, fName);
    Reset(f);
    while not EOF(f) do
    begin
      Readln(f, ln);

      RepSt := LineSep + '<REP ';
      RepStLen := Length(RepSt);
      repps := Pos(RepSt, ln);
      if (repps <> 0) and (repps < 20) then
      begin
        ritem := lines.Add;
        ritem.RpDate := StrToDateTime(Copy(ln, repps + RepStLen,
          Pos('>', ln) - repps - RepStLen));

        ritem.RpDesc := Copy(ln, Pos('>', ln) + 1, MaxInt);
      end;
    end;
    CloseFile(f);
  except {}
  end;
end;

function TFileLog.MakeLogStr(wType: Integer; Desc: string): string;
var rp, dt: string;
begin
  Result := '';
  if Desc = '' then
    Exit;

  if Date <> fPrevDate then
  begin
    Result := FormatDateTime(DateLineFormat, Now) + #13#10;
  end;

  dt := FormatDateTime(ShortTimeFormat, Now);
  if wType = LOG_REPORT then
    rp := '<REP ' + DateTimeToStr(Now) + '> '
  else
    rp := '';

  Result := Result + Copy(AttribChars, wType + 1, 1) + dt + LineSep + rp + Desc;
  fPrevDate := Date;
end;

procedure TFileLog.ReportEvent(wType: Integer; Desc: string);
var f: TextFile;
begin
  if LogDisabled then exit;

  try
    AssignFile(f, fName);
    if FileExists(fName) then
      Append(f)
    else
    begin
      Rewrite(f);
      fPrevDate := Date;
      Writeln(f, FormatDateTime(CreateLineFormat, Now));
    end;
    Writeln(f, MakeLogStr(wType, Desc));

    if fRecentlyRun then
    begin
      Writeln(f, MakeLogStr(LOG_INFORM, ''));
      Writeln(f, MakeLogStr(LOG_INFORM, RunAppMessage));
      fRecentlyRun := False;
    end;

    CloseFile(f);
  except {}
  end;
end;

procedure TFileLog.ReportEventFmt(wType: Integer; Desc: string;
  arr: array of const);
begin
  ReportEvent(wType, Format(Desc, Arr));
end;

//==============================================================================
//******************************************************************************
// TReportItem
//******************************************************************************
//==============================================================================

procedure TReportItem.SetItem(Desc: string);
begin
  fDate := Now;
  fDesc := Desc;
end;

{ TRepCollection }

function TRepCollection.Add: TReportItem;
begin
  Result := TReportItem(inherited Add);
end;

constructor TRepCollection.Create;
begin
  inherited Create(TReportItem);
end;

destructor TRepCollection.Destroy;
begin
  inherited;
end;

function TRepCollection.FindItemID(ID: Integer): TReportItem;
begin
  Result := TReportItem(inherited FindItemID(ID));
end;

function TRepCollection.GetItem(Index: Integer): TReportItem;
begin
  Result := TReportItem(inherited GetItem(Index));
end;

function TRepCollection.Insert(Index: Integer): TReportItem;
begin
  Result := TReportItem(inherited Insert(Index));
end;

procedure TRepCollection.SetItem(Index: Integer; const Value: TReportItem);
begin
  inherited SetItem(Index, Value);
end;

initialization
  benchmark_timer := 0;
end.

