// AKTools.  akSysСover unit.
//           Модуль, содержащий обертки системных функций.
//=============================================================================

unit akSysCover;

interface

uses FileUtil, Windows, Classes{$IFNDEF NOFORMS}, forms, graphics, controls{$ENDIF}, Sysutils;

resourcestring
  exUnableOpen = 'Unable to open target: "%s"';

const
  ExtendedKeys: set of Byte = [// incomplete list
  VK_INSERT, VK_DELETE, VK_HOME, VK_END, VK_PRIOR, VK_NEXT,
    VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN, VK_NUMLOCK
    ];

  CM_RES_SOURCE = false;
  CM_RES_DEST = true;

type
  PDWordArray = ^TDWordArray;
  TDWordArray = array[0..8192] of DWord;

  TIntArray = array[0..8192] of Integer;
  PIntArray = ^TIntArray;

  TDriveState = (DS_NO_DISK, DS_UNFORMATTED_DISK, DS_EMPTY_DISK,
    DS_DISK_WITH_FILES);

// Возвращает True, если даты одинаковы
function IsDateEqual(date1, date2: TDateTime): boolean;

function WinExecAndWait32V2(FileName: string; Visibility: integer): DWORD;

// Регистрирует системный хот-кей, пользуясь TShortCut
function RegisterShortCut(hWnd: HWND; id: Integer; key: TShortCut): Boolean;

// Возвращает описание ошибки по ее Win32-коду
function GetErrorByCode(ercode: DWORD): string;

// Возвращает хандл указанного процесса.
// После окончания работы с хандлом его необходимо закрыть функцией
// CloseHandle
function GetProcessHandle(ProcessID: DWORD): THandle;

// Возвращает то, что написано на кнопке в таскбаре указанного приложения
function GetProcessTitleByID(ProcessID: DWORD; var hndl: THandle): string;

{$IFNDEF NOFORMS}
// Возвращает маленькую и большую иконку к указанному файлу
// Если SmallIcon/LargeIcon установить в nil, то соотествующая иконка извлекаться не будет.
function ExtractIconForFile(Filen: string; SmallIcon, LargeIcon: TIcon): Boolean;

// Аналог ExtractIconForFile, но иконку извлекает по ProcessID
function ExtractIconForProcessID(ProcessID: THandle; SmallIcon, LargeIcon: TIcon): Boolean;
{$ENDIF}

// Возвращает уникальный идентификатор указанного процесса
function GetUniqueProcessName(fn: string): string;

// Возвращает строку с полной информацией об OS.
function GetOSInfo: string;

// Возвращает имя процесса ProcessID.
procedure GetProcessInfo(ProcessID: DWord; var Path: string; ReturnWithPath: Boolean = false);

// Делает окно hndl полупрозрачным. Perc - уровень прозрачности
// в процентах (1-100). Только для Win2k.
procedure SetWindowTransp(hndl: THandle; Perc: byte);

// Возвращает имя системной директории
function GetSystemDir: string;

// Аналог Application.ProcessMessages
procedure ConsoleProcessMessages;

// Если reg = true, то функция регистрирует DLL, в противном случае - удаляет
// информацию о ней из реестра.
procedure RegisterDLL(fn: string; Reg: boolean = true);

// Возвращает время компиляции проекта
function GetBuildTime: TDateTime;

// Отключает анимацию (выезжающие списки, менюшки и т.п.)
procedure EnableAnimation(anim: Boolean; msg: Integer = SPI_SETANIMATION);

// Возвращает true, если сейчас анимация включена.
function GetAnimationState(msg: Integer = SPI_GETANIMATION): Boolean;

// Восстанавливает системное значение анимации.
procedure RestoreAnimation;
procedure StoreAnimation;

// Посылает окно выше всех во всех операционках:
function SetForegroundWindowSp(hWnd: THandle): Boolean;

// Число, привязанное к компьютеру
function GetComputerID: Integer;

// Возвращает класс окна
function GetWindowClass(hwnd: THandle): string;

// Возвращает кэпшин окна
function GetWindowCaption(hwnd: THandle): string;

// Возвращает хандл MDIClient'а окна hwnd. Если это не MDI-окно, то вернется 0.
function GetMDIFormHandle(hwnd: THandle): THandle;

// Возвращает хандл активного MDIChild'а от MDIClient'а hwnd
function GetActiveMDIChildHandle(client: THandle): THandle;

// Возвращает хандл активного окна. Если это MDI-форма, то вернется хандл активного чаилда.
function GetActiveWindowEx(OnlyMDI: Boolean = false): THandle;

// Возвращает true, если левая кнопка мыши нажата
function IsLMButtonPressed: Boolean;

// Возвращает true, если правая кнопка мыши нажата
function IsRMButtonPressed: Boolean;


// Копирует файл. Если он уже существует и имеет другой регистр букв, то он
// удаляется и создается по новой.
// Если в src указать маску, то будут скопированы все файлы, соответствующие
// маске в каталог trg
procedure CopyFileCase(src: string; trg: string);
function ForceDirectoriesCase(Dir: string): Boolean;

procedure TryOpenUrl(url: string; showerr: Boolean = true);
function EncodeHtml(const S: string): string;

// Запускает программу prg с параметром ShortFileName(fn) через Shell Execute
procedure OpenFileIn(prog: string; fn: string);

// Запускает программу prg с параметром fn через Shell Execute
procedure ExecuteApp(prog: string; param: string);

// Возвращает версию InternetExplorer (если она выше либо равна 4.0)
function GetIEVersion(var major, minor: Integer): string;

// Уничтожает объект, а затем присваивает ему значение nil
procedure SafeFreeAndNil(var Obj);

// Читает/пишет одну переменную в реестр
procedure StoreParamsInReg(SoftwareKey, SoftwareSubKey: string; const Vl: Variant; ParamName: string = 'Default');
function RestoreParamsFromReg(SoftwareKey, SoftwareSubKey: string; const Def: Variant; ParamName: string = 'Default'): Variant;

// Возвращает 1, если скринсэйвер выполняется.
//            0, если не выполняется
//           -1, если неизвестно
function IsScreenSaverRunning: Integer;

// Если при использовании ConsoleProcessMessages эта переменная
// установилась в true, то нужно выходить из приложения.
var TerminateApp: Boolean;
  MenuAnimationOn, ComboboxAnimationOn, AnimationOn: Boolean;

// Эмулирует нажатие кнопок
procedure SimulateKeyDown(Key: byte);
procedure SimulateKeyUp(Key: byte);
procedure SimulateKeystroke(Key: byte);
procedure SimulateStringEnter(str: string);

// Функи для сохранения/чтения информации в стерим/память:
function SaveStrToMem(const Ptr: Pointer; const str: string): Pointer;
function ReadStrFromMem(const Ptr: Pointer; out ResPtr: Pointer): string;

function CopyMem(const Destination: Pointer; const Source: Pointer; Length: DWORD; ReturnDestPtr: Boolean = true): Pointer;
function ReadMem(const Destination: Pointer; const Source: Pointer; Length: DWORD): Pointer;
function WriteMem(const Destination: Pointer; const Source: Pointer; Length: DWORD): Pointer;

function SizeOfStrMem(Str: string): Integer;
////////////////////////////////////////////////

function notBool(bool: Boolean): Boolean;


procedure ListLocalDrives(Strings: TStringList);

// Грузит иконку из ресурса resname
// Если запущены из Win2k/XP то также пытается загрузить иконку из ресурса
// resnameXP
function LoadImageXP(hInst: LongWord; resname: string; sizeX, sizeY: Integer): HIcon;
function DrawIconXP(posx, posy: Integer; resname: string; where: TCanvas; sizeX, sizeY: Integer): Boolean;



// Tooltips:
procedure ShowBalloonTip(Control: TWinControl; Icon: integer; Title: pchar;
  Text: PWideChar;
  BackCL, TextCL: TColor);



type

  EFileMappingError = class(Exception);

  //---------------------------------------------------------------------------
  // Класс предназначеный для упрощения обмена данными между приложениями.

  EChannel = class(Exception);

  TChannel = class(TObject)
    fChannelName: string;
    //    fMemory: THandle;
    fFMObject: Integer;
    fFMMem: Pointer;
    fFMLen: Integer;
  private
    procedure Close;
  public
    procedure Clean;
    constructor Create(Channel: string; var Data; Len: Integer);
    destructor Destroy; override;
  end;

  //---------------------------------------------------------------------------
  // Класс предназначеный для работы с файлами, отображенными на память.
  TFileMapping = class(TObject)
  private
    FPtr: Pointer;
    FSz: Integer;
    hFile, hMapFile: THandle;

    procedure Finalize;
  public
    constructor Create(fn: string);
    destructor Destroy; override;

    property Data: Pointer read FPtr;
    property Size: Integer read FSz;
  end;

  // Создает список всех окон процесса, указанного в DetectNow.
  TProcessWindows = class
  private
    hForProc: THandle; // Хандл процесса, по которому строим список окон
    fResultList: TStringList; // сюда запишутся все найденный онка процесса hForProc
  public
    procedure Clear;

    constructor Create;
    destructor Destroy; override;

    // Возвращает список окон, принаддежащих процессу forProc
    // Поле object на самом деле имеет тип THandle и содержит хандлы соответсвующих окон
    function DetectNow(forProc: THandle): TStringList;
  end;


implementation

uses TlHelp32, psapi, ShellAPI, Messages, akDataUtils, Menus, FileCtrl,
  Registry, akStrUtils, rxVerInf, akFileUtils, rxShell;

const
  WS_EX_LAYERED = $80000;
  LWA_COLORKEY = 1;
  LWA_ALPHA = 2;

type
  TSetLayeredWindowAttributes = function(
    hwnd: HWND; // handle to the layered window
    crKey: Integer; // specifies the color key
    bAlpha: byte; // value for the blend function
    dwFlags: DWORD // action
    ): BOOL; stdcall;

type
  TgptInfo = record
    procID: DWORD;
    hndl: THandle;
    buff: string;
  end;

function EncodeHtml(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    if (Ord(S[I]) in [33..36, 39..42, 48..57, 64..90, 97..122]) then
      Result := Result + S[I]
    else
      Result := Result + '%' + IntToHex(Ord(S[I]), 2);
end;

function IsDateEqual(date1, date2: TDateTime): boolean;
var d1, m1, y1, d2, m2, y2: word;
begin
  DecodeDate(date1, d1, m1, y1);
  DecodeDate(date2, d2, m2, y2);
  Result := (d1 = d2) and (m1 = m2) and (y1 = y2);
end;

function RegisterShortCut(hWnd: HWND; id: Integer; key: TShortCut): Boolean;
var vk: Word;
  fsModifiers: Integer;
  shift: TShiftState;
begin
  ShortCutToKey(key, vk, Shift);

  fsModifiers := 0;
  if ssShift in shift then fsModifiers := fsModifiers or MOD_SHIFT;
  if ssAlt in shift then fsModifiers := fsModifiers or MOD_ALT;
  if ssCtrl in shift then fsModifiers := fsModifiers or MOD_CONTROL;

   Result := RegisterHotKey(hwnd, id, fsModifiers, vk);
end;

procedure SafeFreeAndNil(var Obj);
var
  P: TObject;
begin
  P := TObject(Obj);
  P.Free;
  TObject(Obj) := nil; // clear the reference after destroying the object
end;

function SizeOfStrMem(Str: string): Integer;
begin
  Result := Length(Str) + 4;
end;

function ReadMem(const Destination: Pointer; const Source: Pointer; Length: DWORD): Pointer;
begin
  Result := CopyMem(Destination, Source, Length, CM_RES_SOURCE);
end;

function WriteMem(const Destination: Pointer; const Source: Pointer; Length: DWORD): Pointer;
begin
  Result := CopyMem(Destination, Source, Length, CM_RES_DEST);
end;

function CopyMem(const Destination: Pointer; const Source: Pointer; Length: DWORD; ReturnDestPtr: Boolean): Pointer;
begin
  CopyMemory(Destination, Source, Length);
  if ReturnDestPtr then
    Result := Pointer(DWORD(Destination) + Length)
  else
    Result := Pointer(DWORD(Source) + Length);
end;

function SaveStrToMem(const Ptr: Pointer; const str: string): Pointer;
var len: Integer;
  lptr: Pointer;
begin
  len := Length(str);
  lptr := CopyMem(Ptr, @len, 4);
  Result := CopyMem(lptr, @(str[1]), len);
end;

function ReadStrFromMem(const Ptr: Pointer; out ResPtr: Pointer): string;
var len: Integer;
  lptr: Pointer;
begin
  lptr := CopyMem(@len, Ptr, 4, CM_RES_SOURCE);
  SetLength(Result, len);
  ResPtr := CopyMem(@(Result[1]), lptr, len, CM_RES_SOURCE);
end;

function GetErrorByCode(ercode: DWORD): string;
var
  szMsgBuff: PChar;

  function MAKELANGID(p, s: Word): Word;
  begin
    Result := (s shl 10) or p;
  end;

begin
  szMsgBuff := nil;
      // Default system message handling
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ALLOCATE_BUFFER,
    nil, ercode, MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL),
    @szMsgBuff, 0, nil);
//  end;
  if szMsgBuff <> nil then
  begin
    Result := StrPas(szMsgBuff);
    LocalFree(HLOCAL(szMsgBuff));
  end else Result := '';
end;

function GetUniqueProcessName(fn: string): string;
var
  cmp: string;
//  hndl: THandle;
  vi: TVersionInfo;
begin
{   GetProcessInfo(prc, pn, true);
   GetProcessTitleByID(prc, hndl);                       jo07--


   cls := GetWindowClass(hndl);
   if Copy(cls, 1, 4) = 'Afx:' then
     cls := 'Dynamic';}


  cmp := '';
  vi := TVersionInfo.Create(fn);
  try
    cmp := vi.CompanyName + ',' + vi.ProductName;
  finally
    vi.Free;
  end;

  Result := Format('%s:%s', [IntToHex(GetStringCrc(cmp), 8),
    GetFileNameWOExt(ExtractFileName(fn))]);
end;

procedure SimulateKeyDown(Key: byte);
var
  flags: DWORD;
begin
  if Key in ExtendedKeys then flags := KEYEVENTF_EXTENDEDKEY else flags := 0;
  keybd_event(Key, MapVirtualKey(Key, 0), flags, 0);
end;

procedure SimulateKeyUp(Key: byte);
var
  flags: DWORD;
begin
  if Key in ExtendedKeys then flags := KEYEVENTF_EXTENDEDKEY else flags := 0;
  keybd_event(Key, MapVirtualKey(Key, 0), KEYEVENTF_KEYUP or flags, 0);
end;

procedure SimulateKeystroke(Key: byte);
var
  flags: DWORD;
  scancode: BYTE;
begin
  if Key in ExtendedKeys then flags := KEYEVENTF_EXTENDEDKEY else flags := 0;
  scancode := MapVirtualKey(Key, 0);
  keybd_event(Key,
    scancode,
    flags,
    0);
  keybd_event(Key,
    scancode,
    KEYEVENTF_KEYUP or flags,
    0);
end;

procedure SimulateStringEnter(str: string);
var i: Integer;
  shift: Boolean;
  c: Char;
begin
  for i := 1 to Length(str) do begin
    c := str[i]; shift := c = '$';
    if shift then begin SimulateKeyDown(VK_SHIFT); end;
    SimulateKeystroke(Ord(str[i]));
    if shift then SimulateKeyUp(VK_SHIFT);
  end;
end;

function gptEnumProc(WinHandle: HWnd; Param: LongInt): Boolean; stdcall;
var gptinfo: ^TgptInfo;
  prc: DWORD;
  bf: array[0..127] of Char;
begin
  gptinfo := Pointer(Param); Result := True;

  if IsWindowVisible(WinHandle) and // -Hевидимые окна
    (GetWindow(WinHandle, gw_Owner) = 0) and // -Дочерние окна
    (GetWindowText(WinHandle, bf, 128) <> 0) // -Окна без заголовков
    then begin
    GetWindowThreadProcessId(WinHandle, @prc);
    if (prc = gptInfo^.ProcID) then begin
      gptinfo^.buff := string(bf);
      gptinfo^.hndl := WinHandle;
      Result := FALSE;
    end;
  end;
end;

function GetProcessTitleByID(ProcessID: DWORD; var hndl: THandle): string;
var gptinf: TgptInfo;
begin
  Result := ''; gptInf.ProcID := ProcessID;
  gptInf.buff := '';
  gptInf.hndl := 0;

  EnumWindows(@gptEnumProc, Integer(@gptInf));
  Result := gptInf.buff;
  hndl := gptInf.hndl;
end;

function ForceDirectoriesCase(Dir: string): Boolean;
var sucs: Boolean;
begin
  Result := True;
  if Length(Dir) = 0 then
    raise Exception.Create('Error creating folder');
  Dir := ExcludeTrailingBackslash(Dir);
  if (Length(Dir) < 3) or DirectoryExists(Dir)
    or (ExtractFilePath(Dir) = Dir) then begin
    if DirectoryExists(Dir) then
      RenameFile(Dir, Dir);
    Exit; // avoid 'xyz:\' problem.
  end;

  sucs := CreateDir(Dir);
  Result := ForceDirectoriesCase(ExtractFilePath(Dir)) and sucs;
end;

procedure CopyFileCase(src: string; trg: string);

  procedure _CopyFileCase(src: string; trg: string);
  begin
    if FileExists(trg) then
      DeleteFile(PChar(trg));
    FileUtil.CopyFile(src, trg, nil);
  end;

var
  isMask: Boolean;
  srcpth, trgpth: string;
  sr: TSearchRec;
  res: Integer;
begin
  isMask := (Pos('*', src) <> 0) or (Pos('?', src) <> 0);
  if not isMask then begin
    _CopyFileCase(src, trg);
  end else begin
    srcpth := GetDirectory(ExtractFilePath(src));
    trgpth := GetDirectory(trg);
    res := FindFirst(src, faArchive, sr);
    while res = 0 do begin
      _CopyFileCase(srcpth + sr.Name, trgpth + sr.Name);
      res := FindNext(sr);
    end;
    FindClose(sr);
  end;
end;


{$IFNDEF NOFORMS}

function ExtractIconForFile(Filen: string; SmallIcon, LargeIcon: TIcon): Boolean;
var largei: HIcon;
  smalli: HIcon;
  icn: Integer;
begin
  icn := ExtractIconEx(PChar(FileN), 0, largei, smalli, 1);
  if icn <> 0 then begin
    Result := True;
    if not Assigned(SmallIcon) then
      DestroyIcon(smalli)
    else begin
      if not SmallIcon.Empty then begin
        DestroyIcon(SmallIcon.Handle);
        SmallIcon.ReleaseHandle;
      end;
      SmallIcon.Handle := smalli;
    end;
    if not Assigned(LargeIcon) then
      DestroyIcon(largei)
    else begin
      if not LargeIcon.Empty then begin
        DestroyIcon(LargeIcon.Handle);
        LargeIcon.ReleaseHandle;
      end;
      LargeIcon.Handle := largei;
    end;
  end else begin
    Result := False;
  end;
end;

function ExtractIconForProcessID(ProcessID: THandle; SmallIcon, LargeIcon: TIcon): Boolean;
var pn: string;
begin
  GetProcessInfo(ProcessID, pn, true);
  if pn <> '' then begin
    Result := ExtractIconForFile(pn, SmallIcon, LargeIcon);
  end else Result := false;
end;
{$ENDIF}


function IsScreenSaverRunning: Integer;
var runs: Boolean;
begin
  // Проверяем только если это Win98/Win2k и более поздние версии :
  if (((Win32Platform = VER_PLATFORM_WIN32_WINDOWS) and (Win32MinorVersion > 0)) or
    ((Win32Platform = VER_PLATFORM_WIN32_NT) and (win32MajorVersion >= 5))) and
    SystemParametersInfo(SPI_GETSCREENSAVERRUNNING, 0, @runs, 0) then begin
    if runs then Result := 1 else Result := 0;
  end
  else result := -1;
end;

function RestoreParamsFromReg(SoftwareKey, SoftwareSubKey: string; const Def: Variant; ParamName: string = 'Default'): Variant;
var reg: TRegIniFile;
begin
  reg := TRegIniFile.Create(SoftwareKey);
  with reg do
  try
    case VarType(Def) of
      varBoolean: Result := ReadBool(SoftwareSubKey, ParamName, Def);
      varString: Result := ReadString(SoftwareSubKey, ParamName, Def);
      varInteger: Result := ReadInteger(SoftwareSubKey, ParamName, Def);
    else
      raise EVariantError.Create('Unknown variant type');
    end;
  finally
    Free;
  end;
end;

procedure StoreParamsInReg(SoftwareKey, SoftwareSubKey: string; const Vl: Variant; ParamName: string);
var reg: TRegIniFile;
begin
  reg := TRegIniFile.Create(SoftwareKey);
  with reg do
  try
    case TVarData(Vl).VType of
      varBoolean: WriteBool(SoftwareSubKey, ParamName, Vl);
      varString: WriteString(SoftwareSubKey, ParamName, Vl);
      varInteger: WriteInteger(SoftwareSubKey, ParamName, Vl);
    else
      raise EVariantError.Create('Unknown variant type');
    end;
  finally
    Free;
  end;
end;


function GetOSInfo: string;
var
  Platform: string;
  winver, BuildNumber: Integer;
  ver: string;
begin
  Platform := 'Windows';
  winver := win32MajorVersion * 10 + Win32MinorVersion;
  case Win32Platform of
    VER_PLATFORM_WIN32_WINDOWS:
      begin
        if Win32MinorVersion = 0 then Platform := 'Windows 95';
        if Win32MinorVersion > 0 then platform := 'Windows 98';
        BuildNumber := Win32BuildNumber and $0000FFFF;
        if BuildNumber = 3000 then Platform := 'Windows ME';
      end;
    VER_PLATFORM_WIN32_NT:
      begin
        Platform := 'Windows NT';
        if winver >= 50 then Platform := 'Windows 2000';
        if winver >= 51 then Platform := 'Windows XP';
        if winver >= 60 then Platform := 'Windows Vista';
        BuildNumber := Win32BuildNumber;
      end;
  else
    begin
      Platform := 'Windows';
      BuildNumber := 0;
    end;
  end;

  if (Win32Platform = VER_PLATFORM_WIN32_WINDOWS) or
    (Win32Platform = VER_PLATFORM_WIN32_NT) then
  begin
    if (Win32Platform = VER_PLATFORM_WIN32_NT) and (winver >= 50) then
      ver := ''
    else
      ver := Format(' %d.%d', [Win32MajorVersion, Win32MinorVersion]);

    if Trim(Win32CSDVersion) = '' then
      Result := Format('%s%s (Build %d)', [Platform, ver, BuildNumber])
    else
      Result := Format('%s%s (Build %d: %s)', [Platform, ver, BuildNumber, Win32CSDVersion]);
  end
  else
    Result := Format('%s %d.%d', [Platform, Win32MajorVersion,
      Win32MinorVersion])
end;

function GetIEVersion(var major, minor: Integer): string;
begin
  Result := '';
  with TRegistry.Create do
  try
    Access := KEY_QUERY_VALUE;
    RootKey := HKEY_LOCAL_MACHINE;
    OpenKey('\Software\Microsoft\Internet Explorer', False);
    Result := ReadString('Version');
  finally
    CloseKey;
    Free;
  end;

  major := StrToIntDef(GetLeftSegment(0, Result, '.'), 0);
  minor := StrToIntDef(GetLeftSegment(1, Result, '.'), 0);
end;

function IsLMButtonPressed: Boolean;
var virtKey: Integer;
begin
  if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
    virtKey := VK_RBUTTON
  else
    virtKey := VK_LBUTTON;

  Result := GetAsyncKeyState(virtKey) <> 0;
end;

function IsRMButtonPressed: Boolean;
var virtKey: Integer;
begin
  if GetSystemMetrics(SM_SWAPBUTTON) = 0 then
    virtKey := VK_RBUTTON
  else
    virtKey := VK_LBUTTON;

  Result := GetAsyncKeyState(virtKey) <> 0;
end;

function GetComputerID: Integer;
var
  VolumeSerialNumber: DWORD;
  MaximumComponentLength: DWORD;
  FileSystemFlags: DWORD;
begin
  GetVolumeInformation('C:\',
    nil,
    0,
    @VolumeSerialNumber,
    MaximumComponentLength,
    FileSystemFlags,
    nil,
    0);
  Result := VolumeSerialNumber;
end;

function GetProcessHandle(ProcessID: DWORD): THandle;
begin
  Result := OpenProcess(PROCESS_ALL_ACCESS, True, ProcessID);
end;

procedure GetProcessInfo(ProcessID: DWord; var Path: string; ReturnWithPath: Boolean);
var
  hSnapshoot: THandle;
  pe32: TProcessEntry32;
  cbNeeded: Dword;
  hMod: HModule;
  hProcess: THandle;
  ModName: array[0..255] of char;
begin
  Path := '';

  if Win32Platform = VER_PLATFORM_WIN32_NT then // Мы в NT, используем PSAPI :
  begin
    hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, ProcessID);
    if Boolean(hProcess) then
    try
      if EnumProcessModules(hProcess, @hMod, SizeOf(hMod), cbNeeded) then
      begin
        GetModuleFileNameEx(hProcess, hMod, ModName, SizeOf(ModName));
        Path := ModName;
      end
      else
        Path := IntToStr(GetLastError);
    finally
      CloseHandle(hProcess);
    end;
  end
  else // Мы в Win9x, используем TOOLHLP :
  begin
    hSnapshoot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    begin
      pe32.dwSize := SizeOf(TProcessEntry32);
      if (Process32First(hSnapshoot, pe32)) then
        repeat
          if pe32.th32ProcessID = ProcessID then
          begin
            Path := pe32.szExeFile;
            Break;
          end;
        until not Process32Next(hSnapshoot, pe32);
      CloseHandle(hSnapshoot);
    end;
  end;

  Path := lowercase(Path);
  if not ReturnWithPath then Path := ExtractFileName(Path);
end;

//******************************************************************************
//==============================================================================
// TChanel
//==============================================================================
//******************************************************************************

procedure TChannel.Clean;
begin
  FillChar(fFMMem^, fFMLen, 0);
end;

procedure TChannel.Close;
begin
  UnMapViewOfFile(fFMMem);
  CloseHandle(fFMObject);
  //  CloseHandle(fMemory);
  fChannelName := '';
end;

constructor TChannel.Create(Channel: string; var Data; Len: Integer);
begin
  Pointer(Data) := nil;
  fFMLen := Len; fChannelName := Channel;

  fFMObject := CreateFileMapping($FFFFFFFF, nil, PAGE_READWRITE,
    0, fFMLen, PChar(Channel));

  if (DWORD(fFMObject) = INVALID_HANDLE_VALUE) then
    raise EChannel.Create('Impossible create a channel.');

  fFMMem := MapViewOfFile(fFMObject, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if GetLastError <> ERROR_ALREADY_EXISTS then Clean;

  if fFMMem = nil then
  begin
    CloseHandle(fFMObject);
    raise EChannel.Create('Impossible map a channel object.');
  end;
  Pointer(Data) := fFMMem;
end;

destructor TChannel.Destroy;
begin
  Close;
  inherited;
end;

function GetWindowClass(hwnd: THandle): string;
var winCls: string;
  buf: array[1..1024] of char;
begin
  SetLength(WinCls, GetClassName(hwnd, @buf, 1024));
  Move(buf[1], WinCls[1], Length(WinCls));
  Result := WinCls;
end;

function GetWindowCaption(hwnd: THandle): string;
var winTit: string;
  buf: array[1..1024] of char;
begin
  if hwnd = 0 then
    Result := ''
  else
  begin
    SetLength(WinTit, GetWindowText(hwnd, @buf, 1024));
    Move(buf[1], WinTit[1], Length(WinTit));
    Result := WinTit;
  end;
end;

//******************************************************************************
//==============================================================================
// TFileMapping
//==============================================================================
//******************************************************************************

constructor TFileMapping.Create(fn: string);
var newfile: Boolean;
begin
  FPtr := nil;
  hMapFile := 0;
  hFile := 0;

  try
    newfile := not FileExists(fn);
    hFile := CreateFile(PChar(fn), GENERIC_WRITE or GENERIC_READ,
      FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_ALWAYS, 0, 0);
    if (hFile = 0) then
      raise EFileMappingError.CreateFmt('Could not open file "%s"', [fn]);
    FSz := GetFileSize(hFile, nil);
    hMapFile := CreateFileMapping(hFile, nil, PAGE_READWRITE, 0, 1024 * 2048, nil);
    if (hMapFile = 0) then
      raise EFileMappingError.CreateFmt('Could not create file-mapping object. %d', [GetLastError]);
    FPtr := MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, 0);
    if (FPtr = nil) then
      raise EFileMappingError.Create('Could not map view of file.')
    else
      if newfile then
        FillChar(fPtr^, 1024 * 2048, 0);
  except
    on EFileMappingError do
    begin Finalize; raise;
    end
  else
    raise;
  end;
end;

destructor TFileMapping.Destroy;
begin
  inherited;
  Finalize;
end;

procedure TFileMapping.Finalize;
begin
  if Assigned(FPtr) then UnMapViewOfFile(FPtr);
  if hMapFile <> 0 then CloseHandle(hMapFile);
  if hFile <> 0 then CloseHandle(hFile);
end;


//******************************************************************************
//==============================================================================
// TProcessWindows
//==============================================================================
//******************************************************************************

function ProcessWindowsEnumProc(hwnd: THandle; lParam: LPARAM): bool; stdcall;
var fProc: THandle;
begin
  Result := true;
  with TProcessWindows(lParam) do
  begin
    GetWindowThreadProcessId(hwnd, @fProc);
    if hForProc = fProc then
      fResultList.AddObject(GetWindowCaption(hwnd), TObject(hwnd));
  end;
end;

procedure TProcessWindows.Clear;
begin
  hForProc := 0;
  fResultList.Clear;
end;

constructor TProcessWindows.Create;
begin
  fResultList := nil;
  fResultList := TStringList.Create;
end;

destructor TProcessWindows.Destroy;
begin
  if Assigned(fResultList) then fResultList.Free;
  inherited;
end;

function TProcessWindows.DetectNow(forProc: THandle): TStringList;
begin
  Clear;
  Result := fResultList;
  hForProc := forProc;

  Result.BeginUpdate;
  try
    EnumWindows(@ProcessWindowsEnumProc, Integer(Self));
  finally
    Result.EndUpdate;
  end;
end;


//==============================================================================

procedure SetWindowTransp(hndl: THandle; Perc: byte);
var mh: THandle;
  SetLayeredWindowAttributes: TSetLayeredWindowAttributes;
  par: Integer;
begin
  if Perc <= 100 then
  begin
    mh := GetModuleHandle('user32.dll');
    @SetLayeredWindowAttributes := GetProcAddress(mh, 'SetLayeredWindowAttributes');
    if @SetLayeredWindowAttributes <> nil then
    begin
      par := GetWindowLong(hndl, GWL_EXSTYLE);
      if perc = 100 then
        par := par and (not WS_EX_LAYERED)
      else
        par := par or WS_EX_LAYERED;

      SetWindowLong(hndl, GWL_EXSTYLE, par);
      if par <> 100 then
        SetLayeredWindowAttributes(hndl, 0, Round(Perc / 100 * 255), LWA_ALPHA);
    end;
  end;
end;

function GetSystemDir: string;
begin
  SetLength(Result, 1024);
  SetLength(Result, GetSystemDirectory(PChar(Result), Length(Result)));
end;

procedure RegisterDLL(fn: string; Reg: boolean = true);
type TRegProc = function: HResult; stdcall;
var LibHandle: THandle;
  ProcName: string;
  RegProc: TRegProc;
begin
  if Reg then
    ProcName := 'DllRegisterServer'
  else
    ProcName := 'DllUnregisterServer';

  LibHandle := LoadLibrary(PChar(FN));
  if LibHandle = 0 then raise Exception.CreateFmt('Failed to load "%s"', [FN]);
  try
    @RegProc := GetProcAddress(LibHandle, PChar(ProcName));
    if @RegProc = nil then
      raise Exception.CreateFmt('%s procedure not found in "%s"', [ProcName, FN]);
    if RegProc <> 0 then
      raise Exception.CreateFmt('Call to %s failed in "%s"', [ProcName, FN]);
  finally
    FreeLibrary(LibHandle);
  end;
end;

function ConsoleProcessMessage(var Msg: TMsg): Boolean;
begin
  Result := False;
  if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
  begin
    Result := True;
    if Msg.Message = WM_QUIT then
      TerminateApp := True;
    DispatchMessage(Msg);
  end;
end;

procedure ConsoleProcessMessages;
var
  Msg: TMsg;
begin
  while ConsoleProcessMessage(Msg) do {loop}
    ;
end;

function GetBuildTime: TDateTime;
type
  UShort = Word;
  TImageDosHeader = packed record
    e_magic: UShort; // магическое число
    e_cblp: UShort; // количество байт на последней странице файла
    e_cp: UShort; // количество страниц вфайле
    e_crlc: UShort; // Relocations
    e_cparhdr: UShort; // размер заголовка в параграфах
    e_minalloc: UShort; // Minimum extra paragraphsneeded
    e_maxalloc: UShort; // Maximum extra paragraphsneeded
    e_ss: UShort; // начальное( относительное ) значение регистра SS
    e_sp: UShort; // начальное значениерегистра SP
    e_csum: UShort; // контрольная сумма
    e_ip: UShort; // начальное значение регистра IP
    e_cs: UShort; // начальное( относительное ) значение регистра CS
    e_lfarlc: UShort; // адрес в файле на таблицу переадресации
    e_ovno: UShort; // количество оверлеев
    e_res: array[0..3] of UShort; // Зарезервировано
    e_oemid: UShort; // OEM identifier (for e_oeminfo)
    e_oeminfo: UShort; // OEM information; e_oemid specific
    e_res2: array[0..9] of UShort; // Зарезервировано
    e_lfanew: LongInt; // адрес в файле нового .exeзаголовка
  end;

  TImageResourceDirectory = packed record
    Characteristics: DWord;
    TimeDateStamp: DWord;
    MajorVersion: Word;
    MinorVersion: Word;
    NumberOfNamedEntries: Word;
    NumberOfIdEntries: Word;
    //  IMAGE_RESOURCE_DIRECTORY_ENTRY DirectoryEntries[];
  end;
  PImageResourceDirectory = ^TImageResourceDirectory;

var
  hExeFile: HFile;
  ImageDosHeader: TImageDosHeader;
  Signature: Cardinal;
  ImageFileHeader: TImageFileHeader;
  ImageOptionalHeader: TImageOptionalHeader;
  ImageSectionHeader: TImageSectionHeader;
  ImageResourceDirectory: TImageResourceDirectory;
  Temp: Cardinal;
  i: Integer;
begin
  hExeFile := CreateFile(PChar(ParamStr(0)), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  try
    ReadFile(hExeFile, ImageDosHeader, SizeOf(ImageDosHeader), Temp, nil);
    SetFilePointer(hExeFile, ImageDosHeader.e_lfanew, nil, FILE_BEGIN);
    ReadFile(hExeFile, Signature, SizeOf(Signature), Temp, nil);
    ReadFile(hExeFile, ImageFileHeader, SizeOf(ImageFileHeader), Temp, nil);
    ReadFile(hExeFile, ImageOptionalHeader, SizeOf(ImageOptionalHeader), Temp, nil);
    for i := 0 to ImageFileHeader.NumberOfSections - 1 do
    begin
      ReadFile(hExeFile, ImageSectionHeader, SizeOf(ImageSectionHeader), Temp, nil);
      if StrComp(@ImageSectionHeader.Name, '.rsrc') = 0 then Break;
    end;
    SetFilePointer(hExeFile, ImageSectionHeader.PointerToRawData, nil, FILE_BEGIN);
    ReadFile(hExeFile, ImageResourceDirectory, SizeOf(ImageResourceDirectory), Temp, nil);
  finally
    FileClose(hExeFile);
  end;

  Result := FileDateToDateTime(ImageResourceDirectory.TimeDateStamp);
end;

procedure EnableAnimation(anim: Boolean; msg: Integer = SPI_SETANIMATION);
var an: TAnimationInfo;
begin
  an.cbSize := SizeOf(TAnimationInfo);
  an.iMinAnimate := iifs(anim, 1, 0);
  SystemParametersInfo(msg, SizeOf(an), @an, 0);
end;

function GetAnimationState(msg: Integer = SPI_GETANIMATION): Boolean;
var an: TAnimationInfo;
begin
  an.cbSize := SizeOf(TAnimationInfo);
  if SystemParametersInfo(msg, SizeOf(an), @an, 0) then
    Result := an.iMinAnimate <> 0
  else
    Result := False;
end;

procedure RestoreAnimation;
begin
  EnableAnimation(AnimationOn, SPI_SETANIMATION);
  EnableAnimation(MenuAnimationOn, SPI_SETMENUANIMATION);
  EnableAnimation(ComboboxAnimationOn, SPI_SETCOMBOBOXANIMATION);
end;

procedure StoreAnimation;
begin
  AnimationOn := GetAnimationState(SPI_GETANIMATION);
  MenuAnimationOn := GetAnimationState(SPI_GETMENUANIMATION);
  ComboboxAnimationOn := GetAnimationState(SPI_GETCOMBOBOXANIMATION);
end;

function GetMDIFormHandle_EnumWnd(hwnd: HWND; lParam: LPARAM): bool; stdcall;
var cpm: Integer;
  WinFound: PInteger;
begin
  WinFound := Pointer(lParam);
  Result := WinFound^ = 0;
  if WinFound^ = 0 then
  begin
    cpm := SendMessage(hwnd, WM_MDIGETACTIVE, 0, 0);
    if cpm <> 0 then
    begin
      WinFound^ := hwnd;
      Result := false;
    end {
    else
      EnumChildWindows(hwnd, @GetMDIFormHandle_EnumWnd, lParam)};
  end;
end;

function GetMDIFormHandle(hwnd: THandle): THandle;
const Prev: THandle = 0;
  PrevRes: THandle = 0;
  PrevCap: string = '';
var
  cap: string;
begin
  cap := GetWindowCaption(hwnd);
  if Prev = hwnd then begin
    if (PrevCap = cap) then begin
      Result := PrevRes;
      exit;
    end;
  end;

  Result := 0;
  EnumChildWindows(hwnd, @GetMDIFormHandle_EnumWnd, Integer(@Result));
  Prev := hwnd;
  PrevCap := cap;
  PrevRes := Result;
end;

function GetActiveMDIChildHandle(client: THandle): THandle;
begin
  if Client <> 0 then
    Result := SendMessage(client, WM_MDIGETACTIVE, 0, 0)
  else
    Result := 0;
end;

function GetActiveWindowEx(OnlyMDI: Boolean): THandle;
var fhrg: THandle;
begin
  fhrg := GetForegroundWindow;
  if fhrg = 0 then
    Result := 0
  else
  begin
    Result := GetActiveMDIChildHandle(GetMDIFormHandle(fhrg));
    if (not OnlyMDI) and (Result = 0) then Result := GetForegroundWindow;
  end;
end;

procedure TryOpenUrl(url: string; showerr: Boolean);
var urlow, path: string;
  isurl: Boolean;
  ismail: Boolean;
  res: Integer;
{  Info: TShellExecuteInfo;
  ExitCode: DWORD;}
begin
  urlow := LowerCase(url);


  isurl := pos('://', urlow) <= 6;
  ismail := pos('mailto:', urlow) = 1;

  if isurl or ismail then
    path := url
  else
    path := '"' + ExtractShortPathName(url) + '"';

  res := ShellExecute(0, 'open', PChar(path), nil, nil, SW_NORMAL);
  if (res < 32) and (ShowErr) then
    MessageBox(0, PChar(Format(exUnableOpen, [path])), 'Error', MB_OK or MB_ICONERROR);
end;

procedure OpenFileIn(prog: string; fn: string);
var fle: string;
begin
  fle := '"' + ExtractShortPathName(fn) + '"';

  if ShellExecute(0, 'open', PChar(prog), PChar(fle),
    PChar(ExtractFilePath(fn)), SW_SHOW) < 32 then
    MessageBox(0, PChar(Format(exUnableOpen, [prog])), 'Error', MB_OK or MB_ICONERROR);
end;

procedure ExecuteApp(prog: string; param: string);
begin
  if ShellExecute(0, 'open', PChar(prog), PChar(param), nil, SW_SHOW) < 32 then
    MessageBox(0, PChar(Format(exUnableOpen, [prog])), 'Error', MB_OK or MB_ICONERROR);
end;

function SetForegroundWindowSp(hWnd: THandle): Boolean;
type
  TSendInput = function(cInputs: UINT; var pInputs: TInput; cbSize: Integer): UINT; stdcall;
var
  hUser32: THandle;
  pSendInput: TSendInput;
  Input: TInput;
begin
  FillChar(Input, SizeOf(Input), 0);
  Input.Itype := INPUT_MOUSE;

  Result := False;

  if (not IsWindow(hWnd)) then exit;

  SetForegroundWindow(hWnd);
  if (hWnd = GetForegroundWindow) then begin
    Result := True;
    exit;
  end;

  hUser32 := LoadLibraryEx(PChar('User32.dll'), 0, DONT_RESOLVE_DLL_REFERENCES);
  if (hUser32 = 0) then exit;
  try

    pSendInput := GetProcAddress(hUser32, PChar('SendInput'));
    if Assigned(pSendInput) then pSendInput(1, Input, sizeof(Input));
  finally
    FreeLibrary(hUser32);
  end;

  Result := SetForegroundWindow(hWnd);
  if (IsIconic(hWnd)) then OpenIcon(hWnd);
end;


function LoadImageXP(hInst: LongWord; resname: string; sizeX, sizeY: Integer): HIcon;
var h: HDC;
begin
  Result := 0;

  h := GetDC(0);
  try
    if (Win32Platform = VER_PLATFORM_WIN32_NT) and (win32MajorVersion >= 5) and
      (Win32MinorVersion >= 1) and (GetDeviceCaps(h, BITSPIXEL) >= 16) then
      Result := LoadImage(hInst, PChar(resname + 'XP'), IMAGE_ICON, sizeX, sizeY, 0);
  finally
    ReleaseDC(0, h);
  end;

  if Result = 0 then
    Result := LoadImage(hInst, PChar(resname), IMAGE_ICON, sizeX, sizeY, 0);
end;

function DrawIconXP(posx, posy: Integer; resname: string; where: TCanvas; sizeX, sizeY: Integer): Boolean;
var icn: TIcon;
begin
  Result := False;
  icn := TIcon.Create;
  try
    icn.Handle := LoadImageXP(hInstance, resname, sizeX, sizeY);
    if icn.Handle = 0 then exit;
    where.Draw(posx, posy, icn);
  finally
    icn.Free;
  end;
  Result := True;
end;

function WinExecAndWait32V2(FileName: string; Visibility: integer): DWORD;
  procedure WaitFor(processHandle: THandle);
  var
    msg: TMsg;
    ret: DWORD;
  begin
    repeat
      ret := MsgWaitForMultipleObjects(
        1, { 1 handle to wait on }
        processHandle, { the handle }
        False, { wake on any event }
        INFINITE, { wait without timeout }
        QS_PAINT or { wake on paint messages }
        QS_SENDMESSAGE { or messages from other threads }
        );
      if ret = WAIT_FAILED then Exit; { can do little here }
      if ret = (WAIT_OBJECT_0 + 1) then begin
          { Woke on a message, process paint messages only. Calling
            PeekMessage gets messages send from other threads processed. }
        while PeekMessage(msg, 0, WM_PAINT, WM_PAINT, PM_REMOVE) do
          DispatchMessage(msg);
      end;
    until ret = WAIT_OBJECT_0;
  end; { Waitfor }
var { V1 by Pat Ritchey, V2 by P.Below }
  zAppName: array[0..512] of char;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin { WinExecAndWait32V2 }
  StrPCopy(zAppName, FileName);
  FillChar(StartupInfo, Sizeof(StartupInfo), #0);
  StartupInfo.cb := Sizeof(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := Visibility;
  if not CreateProcess(nil,
    zAppName, { pointer to command line string }
    nil, { pointer to process security attributes }
    nil, { pointer to thread security attributes }
    false, { handle inheritance flag }
    CREATE_NEW_CONSOLE or { creation flags }
    NORMAL_PRIORITY_CLASS,
    nil, { pointer to new environment block }
    nil, { pointer to current directory name }
    StartupInfo, { pointer to STARTUPINFO }
    ProcessInfo) { pointer to PROCESS_INF }
    then
    Result := DWORD(-1) { failed, GetLastError has error code }
  else begin
    Waitfor(ProcessInfo.hProcess);
    GetExitCodeProcess(ProcessInfo.hProcess, Result);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end; { Else }
end; { WinExecAndWait32V2 }


function notBool(bool: Boolean): Boolean;
begin
  if bool then Result := true
  else Result := false;
end;

function DriveState(driveletter: Char): TDriveState;
var
  mask: string[6];
  sRec: TSearchRec;
  oldMode: Cardinal;
  retcode: Integer;
begin
  oldMode := SetErrorMode(SEM_FAILCRITICALERRORS);
  mask := '?:\*.*';
  mask[1] := driveletter;
  retcode := FindFirst(mask, faAnyfile, SRec);
  if retcode = 0 then FindClose(SRec);
  case Abs(retcode) of
    0: Result := DS_DISK_WITH_FILES; { found at least one file }
    18, 2: Result := DS_EMPTY_DISK; { found no files but otherwise ok }
    21, 3: Result := DS_NO_DISK; { DOS ERROR_NOT_READY on WinNT,}
                                   {  ERROR_PATH_NOT_FOUND on Win 3.1 }
  else
    Result := DS_UNFORMATTED_DISK;
  end;
  SetErrorMode(oldMode);
end; { DriveState }

procedure ListLocalDrives(Strings: TStringList);
const BufSize = 256;
var
  Buffer: PChar;
  P: PChar;
  lt: string;
begin
  GetMem(Buffer, BufSize);
  try
    Strings.BeginUpdate;
    try
      Strings.Clear;
      if GetLogicalDriveStrings(BufSize, Buffer) <> 0 then begin
        P := Buffer;
        while P^ <> #0 do begin
          lt := copy(p, 1, 1);
          if Length(lt) > 0 then begin
            if DriveState(lt[1]) = DS_DISK_WITH_FILES then
              Strings.Add(P);
          end;
          Inc(P, StrLen(P) + 1);
        end; //while
      end; //if
    finally
      Strings.EndUpdate;
    end; //try 2
  finally
    FreeMem(Buffer, BufSize);
  end; //try 1
end; //ListDrives



procedure ShowBalloonTip(Control: TWinControl; Icon: integer; Title: pchar;
  Text: PWideChar;
   BackCL, TextCL: TColor);

const
  hWndTip: THandle = 0;

  TOOLTIPS_CLASS = 'tooltips_class32';
  TTS_ALWAYSTIP = $01;
  TTS_NOPREFIX = $02;
  TTS_BALLOON = $40;
  TTF_SUBCLASS = $0010;
  TTF_TRANSPARENT = $0100;
  TTF_CENTERTIP = $0002;
  TTF_TRACK = $0020;
  ICC_WIN95_CLASSES = $000000FF;
  TTM_SETTIPBKCOLOR = $000000FF;
  TTM_SETTIPTEXTCOLOR = $000000FF;

  TTM_SETDELAYTIME = WM_USER + 3;
  TTM_ACTIVATE = WM_USER + 1;
  TTM_ADDTOOL = WM_USER + 50;
  TTM_TRACKACTIVATE = WM_USER + 17;
  TTM_TRACKPOSITION = WM_USER + 18;
  TTM_SETTITLE = WM_USER + 32;
  TTM_SETMAXTIPWIDTH = WM_USER + 24;

  TTDT_AUTOPOP = 2;
  TTDT_INITIAL = 3;


type
  TOOLINFO = packed record
    cbSize: Integer;
    uFlags: Integer;
    hwnd: THandle;
    uId: Integer;
    rect: TRect;
    hinst: THandle;
    lpszText: PWideChar;
    lParam: Integer;
  end;

var
  ti: TOOLINFO;
  hWnd: THandle;
begin
  if (hWndTip <> 0) and (not IsWindow(hWndTip)) then exit;

  hWnd := Control.Handle;
  hWndTip := CreateWindow(TOOLTIPS_CLASS, nil,
    WS_POPUP or TTS_NOPREFIX or TTS_BALLOON or TTS_ALWAYSTIP,
    0, 0, 0, 0, hWnd, 0, HInstance, nil);
  if hWndTip <> 0 then begin
    SetWindowPos(hWndTip, HWND_TOPMOST, 0, 0, 0, 0,
      SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
    ti.cbSize := SizeOf(ti);
    ti.uFlags := TTF_CENTERTIP or TTF_TRANSPARENT or TTF_SUBCLASS;
    ti.hwnd := hWnd;
    ti.lpszText := Text;
    Windows.GetClientRect(hWnd, ti.rect);
    SendMessage(hWndTip, TTM_SETTIPBKCOLOR, BackCL, 0);
    SendMessage(hWndTip, TTM_SETTIPTEXTCOLOR, TextCL, 0);
    SendMessage(hWndTip, TTM_SETMAXTIPWIDTH, 0, 300);
    SendMessage(hWndTip, TTM_SETTITLE, Icon mod 4, Integer(Title));
    SendMessage(hWndTip, TTM_SETDELAYTIME, TTDT_AUTOPOP, 32000);
    SendMessage(hWndTip, TTM_SETDELAYTIME, TTDT_INITIAL, 0);
    SendMessage(hWndTip, TTM_ADDTOOL, 1, Integer(@ti));
  end;


{var
  ti: TOOLINFO;
  hWnd: THandle;
  MyPos: TPoint;
begin
  if hWndTip > 0 then
    DestroyWindow(hWndTip);

  if Control = nil then exit;

  hWnd := Control.Handle;

  hWndTip := CreateWindowEx(WS_EX_TOPMOST, TOOLTIPS_CLASS, nil, TTS_ALWAYSTIP or TTS_BALLOON,
    integer(CW_USEDEFAULT), integer(CW_USEDEFAULT),
    integer(CW_USEDEFAULT), integer(CW_USEDEFAULT),
    hWnd, 0, hInstance, nil);

  if hWndTip <> 0 then
  begin
    ti.cbSize := SizeOf(ti);
    ti.uFlags := TTF_TRACK;
    ti.hwnd := hWnd;
    ti.lpszText := PWideChar(Text);

    Windows.GetClientRect(hWnd, ti.rect);
    SendMessage(hWndTip, TTM_ADDTOOL, 1, Integer(@ti));
    SendMessage(hWndTip, TTM_SETTITLE, Icon mod 4, Integer(Title));

    GetCaretPos(Mypos);
    SendMessage(hWndTip, TTM_TRACKPOSITION, 0, MakelParam(Control.ClientOrigin.X + Mypos.X, Control.ClientOrigin.Y + Control.ClientHeight - Mypos.Y));
//    SendMessage(hWndTip, TTM_TRACKACTIVATE, 1, Integer(@ti));

  end;   }
end;


initialization
  TerminateApp := False;
  StoreAnimation;
finalization
end.

