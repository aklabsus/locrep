// AKTools akFileUtils unit.
//         ������, ���������� ������� �� ������ � �������.
//=============================================================================

unit akFileUtils;

interface

uses Classes, SysUtils, Windows;

type
  //----------------------------------------------------------------------------
  // �������� ������ ���� ��������� ������ � ���������� Dir � ������ Mask

  TCustomTreeFileList = class(TObject)
  private
    FDir: string;
    FMask: string;
    fStopIt: boolean;
    procedure FindRecurse(Folder: string; Mask: string);
    procedure FindFiles(Folder: string; Mask: string);

  protected
     // ���������� ���� �����, ��� ��������� ���������� � ��������� ������.
    procedure _Process(FileName: string); virtual;

    // ���� ������� "false", �� ������� ������ �����������:
    function _Process2(FileName: string): Boolean; virtual;

    procedure Process(FileName: string);
  public
    constructor Create(dir: string; mask: string);
    destructor Destroy; override;

    procedure ProcessFind;
  end;

  // ���� �� ��������� N-��� (� ����) ����, �������������� �����:
function FindFile(stfolder: string; Mask: string): string;

 // ���������� ����� ������ � ��������� ������ � ��������� �������� � ����
 // ��� ������������.
function GetFilesCount(dir, mask: string): Integer;

 // ���������� ��� ����� ��� ����������
function GetFileNameWOExt(fn: string): string;

 // ��������� "\" � ����� ����������, ���� ��� �����
function GetDirectory(St: string): string;

 // ���������� ���� � Program Files
function GetProgramFilesDir: string;

 // ������� �� ����� FName ���� CurFolder
function TrimPathToRelative(CurFolder, FName: string): string;

 // ������� ����� ����� �� ����� �����
function GetRelativeDirectory(St: string): string;

 // ���������� ������ ���� � ����� �� ��� �������������� ����
function CompletePath(fn, CurDir: string): string;

 // ������� �� ������ d1 ��� ������� "\" � "/", �.�. ��
 // ������ "c:\\\\/tools\\txt" ������� ������� "c:\tools\txt"
function RepairPathName(d1: string): string;

 // ���������� ��� ����� ����� �������������� ��������
function GetPrevFolder(path: string): string;

 // ���������� ���� � �����, ��������������� � unix-������ (�.�. ����� ����������
 // � ������ �������: "/")
function FileNameToUnix(path: string): string;

 // ���������� ��� ����, ��������� ������� ���� �
 // ������ "\", "/".
function CompareDirectoryes(d1, d2: string): Boolean;

 // ������� ����, ���� ������� �� ����������
procedure CreateFileIfNotExists(fn: string);

 // �������� ���� ����� �������, ��� �� �� ����� ����������� ����� �������
 // Hidden, � ������ ����� ����������� ���������� ����������.
procedure CopyFileHidden(src, targ: string);

 // �������� ��� ���������� ����� (��� ����������)  (Dmitry Kudinov)
function CreateTempFileName: string;

 // ���������� ���������� ��� ����� � ������ Mask ��� ���������� Dir.
 // � ����� ������ �������������� ������ "#", ���������� � �������� ����������
 // ���������� �������� ���������������.
function MakeUniqueFileName(Dir: string; Mask: string = 'Untitled-#'): string;

 // ���������� true - ���� fn ������ �� ��� �����. ���� �� ������ ���������� �
 // ftp:// ��� http://, �� ������� ��� ��� � �������� false.
function IsFileName(fn: string): Boolean;

 // ���������� ��� � ����������� ����������� (���� ��� ����):
 // �.�. �� http://www.aklabs.com/mycool.php?test=34&ar=34 ��������� ������
 // http://www.aklabs.com/mycool.php
function RemoveUrlParameters(url: string): string;

 // ����� ������ � ���� �� �����:
procedure SaveStrToFile(fn, str: string);


// ���������� ��������� ����:
// Folder - ��� CSIDL
function GetSystemPath(Folder: Integer): string;

// ���������� ������� Application Data:
function GetAppDataFolder(AppName: string): string;
function GetMyDocFolder: string;

// ���������� ������ � ������ �����, ��������� ������ �����������.
function MoveDir(const FromDir, ToDir: string): Boolean;

// ��������� ������ �� ���� ��� �� ������
function IsFileLocked(fn: string): boolean;

implementation

uses ShellApi, ShlObj, ActiveX;

resourcestring
  exWrongMask = 'MakeUniqueFileName: Wrong mask "%s"';

// ================== GETFilesCount ===============================

type
  TFileCountTreeFileList = class(TCustomTreeFileList)
  private
    fFileCount: Integer;
    procedure _Process(FileName: string); override;
  public
    constructor Create(dir: string; mask: string);
  end;

function GetFilesCount(dir, mask: string): Integer;
begin
  with TFileCountTreeFileList.Create(dir, mask) do
  try
    ProcessFind;
    Result := fFileCount;
  finally
    Free;
  end;
end;

// ================== GETFilesCount ===============================


function RemoveUrlParameters(url: string): string;
var ps, ln: Integer;
begin
  ps := Pos('?', url);
  if ps > 0 then
    ln := ps - 1
  else
    ln := maxint;

  Result := Copy(url, 1, ln);
end;

function IsFileName(fn: string): Boolean;
begin
  Result := (lowercase(Copy(Trim(fn), 1, 7)) <> 'mailto:') and
    (pos('://', fn) = 0) and (fn <> '');
end;


function FileNameToUnix(path: string): string;
var i: Integer;
begin
  Result := path;
  for i := 1 to Length(Result) do
    if Result[i] = '\' then Result[i] := '/';
end;

 // ���������� ��� ����� ����� �������������� ��������

function GetPrevFolder(path: string): string;
var
  npath: string;
begin
  npath := RepairPathName(path);
  if Copy(npath, length(npath), 1) = '\' then
    npath := Copy(npath, 1, length(npath) - 1);

  Result := ExtractFilePath(npath);
end;

function GetProgramFilesDirByKeyStr(KeyStr: string): string;
var
  dwKeySize: DWORD;
  Key: HKEY;
  dwType: DWORD;
begin
  if RegOpenKeyEx(HKEY_LOCAL_MACHINE, PChar(KeyStr), 0, KEY_READ, Key) = ERROR_SUCCESS then
  try
    RegQueryValueEx(Key, 'ProgramFilesDir', nil, @dwType, nil, @dwKeySize);
    if (dwType in [REG_SZ, REG_EXPAND_SZ]) and (dwKeySize > 0) then
    begin
      SetLength(Result, dwKeySize);
      RegQueryValueEx(Key, 'ProgramFilesDir', nil, @dwType, PByte(PChar(Result)), @dwKeySize);
    end
    else
    begin
      RegQueryValueEx(Key, 'ProgramFilesPath', nil, @dwType, nil, @dwKeySize);
      if (dwType in [REG_SZ, REG_EXPAND_SZ]) and (dwKeySize > 0) then
      begin
        SetLength(Result, dwKeySize);
        RegQueryValueEx(Key, 'ProgramFilesPath', nil, @dwType, PByte(PChar(Result)), @dwKeySize);
      end;
    end;
  finally
    RegCloseKey(Key);
  end;
end;

function GetProgramFilesDir: string;
const
  DefaultProgramFilesDir = '%SystemDrive%\Program Files';
var
  FolderName: string;
  dwStrSize: DWORD;
begin
  if Win32Platform = VER_PLATFORM_WIN32_NT then
    FolderName := GetProgramFilesDirByKeyStr('Software\Microsoft\Windows NT\CurrentVersion');
  if Length(FolderName) = 0 then
    FolderName := GetProgramFilesDirByKeyStr('Software\Microsoft\Windows\CurrentVersion');
  if Length(FolderName) = 0 then
    FolderName := DefaultProgramFilesDir;
  dwStrSize := ExpandEnvironmentStrings(PChar(FolderName), nil, 0);
  SetLength(Result, dwStrSize);
  ExpandEnvironmentStrings(PChar(FolderName), PChar(Result), dwStrSize);

  Result := Trim(Result);
end;

function GetFileNameWOExt(fn: string): string;
begin
  Result := Trim(Copy(fn, 1, Length(fn) - Length(ExtractFileExt(fn))));
end;

function GetDirectory(St: string): string;
begin
  Result := St;
  if Length(st) > 0 then
    if not (st[Length(st)] in ['\', '/', ':']) then
      Result := Trim(Result) + '\';
end;

function TrimPathToRelative(CurFolder, FName: string): string;
var cfr, fnr: string;
begin
  cfr := GetDirectory(RepairPathName(CurFolder));
  fnr := RepairPathName(FName);

  if AnsiCompareText(Copy(fnr, 1, Length(cfr)), cfr) = 0 then
    Result := Copy(fnr, Length(cfr) + 1, maxint)
  else
    Result := ExtractFileName(FName);
end;

function GetRelativeDirectory(St: string): string;
var ps: Integer;
begin
  ps := Pos(':', St);
  if ps = 0 then
    Result := St
  else
    Result := Copy(st, ps + 1, Length(st) - ps);
end;

function CompletePath(fn, CurDir: string): string;
var LastDir: string;
begin
 { St := Copy(ExtractFileDrive(CurDir), 1, 1);
  if Length(St) <> 1 then
    raise EConvertError.Create('CompletePath failed');   }

  GetDir(0, LastDir);
  ChDir(CurDir);
  Result := ExpandFileName(fn);
  ChDir(LastDir);
end;

function RepairPathName(d1: string): string;
var i, p: Integer;
  prevCh: Char;
begin
  Result := d1; p := 0; prevCh := #0;
  for i := 1 to Length(d1) do
  begin
    inc(p);
    Result[p] := d1[i];
    if d1[i] = '/' then Result[p] := '\';
    if (d1[i] in ['\', '/']) and (i > 2) then
      if (PrevCh in ['\', '/']) then
        dec(p);

    PrevCh := d1[i];
  end;
  SetLength(Result, p);
end;

function CompareDirectoryes(d1, d2: string): Boolean;
begin
  Result := AnsiCompareText(GetDirectory(RepairPathName(d1)),
    GetDirectory(RepairPathName(d2))) = 0;
end;

procedure CreateFileIfNotExists(fn: string);
begin
  if not FileExists(fn) then
    with TFileStream.Create(fn, fmCreate or fmShareDenyNone) do
      Free;
end;


//******************************************************************************
//==============================================================================
// TCustomTreeFileList
//==============================================================================
//******************************************************************************

constructor TCustomTreeFileList.Create(dir, mask: string);
begin
  FDir := GetDirectory(dir);
  FMask := mask;
end;

destructor TCustomTreeFileList.Destroy;
begin
  inherited;
end;

procedure TCustomTreeFileList.FindFiles(Folder, Mask: string);
var di: TSearchRec;
  Res: Integer;
begin
  Res := FindFirst(Folder + Mask, faAnyFile, di);
  while Res = 0 do
  begin
    if not ((di.Attr and faDirectory) = faDirectory) then begin
      Process(GetDirectory(Folder) + di.Name);
      if fStopIt then break;
    end;
    Res := FindNext(di);
  end;
  sysUtils.FindClose(di);
end;

procedure TCustomTreeFileList.FindRecurse(Folder, Mask: string);
var di: TSearchRec;
  Res: Integer;
  Fldr: string;
begin
  Res := FindFirst(Folder + '*.*', faAnyFile, di);
  while Res = 0 do
  begin
    if (di.Name <> '.') and (di.Name <> '..') and ((di.Attr and faDirectory) = faDirectory) then
    begin
      Fldr := GetDirectory(Folder + di.Name);
      FindFiles(Fldr, Mask);
      if fStopIt then break;
      FindRecurse(Fldr, Mask);
    end;

    Res := FindNext(di);
  end;
  SysUtils.FindClose(di);
end;

procedure TCustomTreeFileList.Process(FileName: string);
begin
  _Process(FileName);
  if not _Process2(FileName) then
    fStopIt := true;
end;

procedure TCustomTreeFileList.ProcessFind;
begin
  fStopIt := false;
  FindFiles(FDir, FMask);
  FindRecurse(FDir, FMask);
end;

function CreateTempFileName: string;
var
  a: integer;
  Hour, Min, Sec, MSec: word;
begin
  DecodeTime(Time, Hour, Min, Sec, MSec);
  a := MSec + Sec * 100 + Min * 10000 + Hour * 1000000;
  Result := IntToHex(a, 8);
end;

function MakeUniqueFileName(Dir: string; Mask: string = 'Untitled-#'): string;
var i: Integer;
  dr, fn: string;
begin
  if Pos('#', Mask) = -1 then
    raise Exception.CreateFmt(exWrongMask, [Mask]);

  dr := GetDirectory(Dir);
  for i := 1 to MaxInt do
  begin
    fn := StringReplace(Mask, '#', IntToStr(i), []);
    if not FileExists(dr + fn) then
    begin
      Result := fn;
      Break;
    end;
  end;
end;

{ TFileCountTreeFileList }

procedure TFileCountTreeFileList._Process(FileName: string);
begin
  inc(fFileCount);
end;

constructor TFileCountTreeFileList.Create(dir, mask: string);
begin
  inherited Create(dir, mask);
  fFileCount := 0;
end;


function GetSystemPath(Folder: Integer): string;
var
  PIDL: PItemIDList;
  Path: LPSTR;
  AMalloc: IMalloc;
begin
  Path := StrAlloc(MAX_PATH);
  SHGetSpecialFolderLocation(0, Folder, PIDL);
  if SHGetPathFromIDList(PIDL, Path) then
    Result := Path
  else
    Result := '';
  SHGetMalloc(AMalloc);
  AMalloc.Free(PIDL);
  StrDispose(Path);
end;

function GetAppDataFolder(AppName: string): string;
begin
  Result := GetSystemPath(CSIDL_APPDATA);
  if Result = '' then
    Result := GetDirectory(ExtractFilePath(ParamStr(0))) + 'AppData\'
  else
    Result := GetDirectory(Result) + AppName;
end;

function GetMyDocFolder: string;
begin
  Result := GetSystemPath(CSIDL_PERSONAL);
  Result := GetDirectory(Result);
end;


function MoveDir(const FromDir, ToDir: string): Boolean;
var
  SH: SHFILEOPSTRUCT;
begin
  FillChar(SH, SizeOf(SH), 0);
  with SH do
  begin
    Wnd := 0;
    wFunc := FO_MOVE;
    pFrom := PChar(GetDirectory(FromDir) + '*' + #0);
    pTo := PChar(ToDir + #0);
    fFlags := FOF_NOCONFIRMMKDIR;
                {or FOF_NOCONFIRMATION}
                {or FOF_NOCONFIRMMKDIR}
                {or FOF_RENAMEONCOLLISION}
                {or FOF_SILENT};
  end;
  Result := SHFileOperation(SH) = 0;
  if Result then
    RemoveDirectory(PChar(FromDir));
end;

// ===============FindFile============================
type
  TFileFindTreeFileList = class(TCustomTreeFileList)
  private
    fFileNum: Integer;
    fFileNme: string;
    fCurFile: Integer;
    function _Process2(FileName: string): Boolean; override;
  public
    property FileNme: string read fFileNme write fFileNme;
    property FileNum: Integer read fFileNum write fFileNum;
    constructor Create(dir: string; mask: string);
  end;


function FindFile(stfolder: string; Mask: string): string;
begin
  Result := '';
  with TFileFindTreeFileList.Create(stfolder, mask) do
  try
    ProcessFind;
    Result := FileNme;
  finally
    Free;
  end;
end;

{ TFileFindTreeFileList }

function TFileFindTreeFileList._Process2(FileName: string): Boolean;
begin
  Result := True;
  if FileNum = fCurFile then begin
    FileNme := FileName;
    Result := false;
  end;
  inc(fCurFile);
end;

constructor TFileFindTreeFileList.Create(dir, mask: string);
begin
  inherited;
  FileNum := 0;
  FileNme := '';
  fCurFile := 0;
end;

procedure TCustomTreeFileList._Process(FileName: string);
begin
   {}
end;

function TCustomTreeFileList._Process2(FileName: string): Boolean;
begin
  Result := true;
end;


procedure CopyFileHidden(src, targ: string);
var fhand: THandle;
  buf: string;
  attr: Integer;
  rdsize: DWORD;
  res: Boolean;
begin
  with TFileStream.Create(src, fmOpenRead) do
  try
    SetLength(buf, Size);
    ReadBuffer(buf[1], Length(buf));
  finally
    Free;
  end;
  attr := FileGetAttr(src);

  fhand := CreateFile(PChar(targ), GENERIC_WRITE, 0, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_HIDDEN, 0);
  if fhand = INVALID_HANDLE_VALUE then
    raise EInOutError.CreateFmt('Unable to create file %s', [targ])
  else begin
    try
      res := WriteFile(fhand, buf[1], Length(buf), rdsize, nil);
      if (not res) or (Length(buf) <> Integer(rdsize)) then
        raise EInOutError.CreateFmt('File write error (%s).', [targ]);
    finally
      CloseHandle(fhand);
    end;
  end;

  if FileSetAttr(PChar(targ), attr) <> 0 then
    raise Exception.CreateFmt('Unable to change file attribute (%s)', [targ]);
end;

function IsFileLocked(fn: string): boolean;
var hnd: THandle;
  err: Integer;
begin
  Result := False;
  hnd := CreateFile(PChar(fn), GENERIC_READ, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if hnd = INVALID_HANDLE_VALUE then begin
    err := GetLastError;
    Result := err <> 0;
  end else
    CloseHandle(hnd);
end;

procedure SaveStrToFile(fn, str: string);
var f: TFileStream;
begin
  f := TFileStream.CreatE(fn, fmCreate);
  try
    f.WriteBuffer(str[1], Length(str));
  finally
    f.Free;
  end;
end;



end.

