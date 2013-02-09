unit akShell;

interface

uses Windows, ShlObj;

const
  BIF_NEWDIALOGSTYLE = $0040;

  CSIDL_APPDATA      = $001A;  


//------------------------------------------------------------------------------
// Работа с системными каталогами ==============================================

// Возвращает путь к каталогу "Автозагрузка"
function GetStartupFolder: string;

// Возврашает "True", если в автозагрузке есть линк с именем LinkName
function IsInStartup(LinkName: string): Boolean;

// Открывате htm-хелп
procedure OpenHelp(filen, page: string);

// Если SetIt=true, то функа создает линк с именем LinkName к файлу Filename.
// Если SetIt=false, то линк удаляется.
procedure SetStartup(Filename, LinkName: string; SetIt: Boolean);

// Позволяет выбрать фолдер
function SelectDir(hndl: THandle; TitleName: string; var folder: string; mode: Integer = CSIDL_DRIVES): Boolean;

implementation

uses Registry, ActiveX, comobj, SysUtils, ShellApi;

procedure OpenHelp(filen, page: string);
var resCd: Integer;
  pg: string;
begin
  resCd := 0;
  if page <> '' then pg := '::' + page else pg := '';
  if FileExists(filen) then
    resCd := ShellExecute(0, 'open', 'hh.exe',
      PChar(ExtractShortPathName(filen) + pg), nil, SW_SHOW);
  if resCd <= 32 then
    raise Exception.CreateFmt('Unable to open help file %s', [filen]);
end;

function GetStartupFolder: string;
var
  pidl: PItemIdList;
  Buffer: array[0..MAX_PATH] of Char;
begin
  OleCheck(SHGetSpecialFolderLocation(0, CSIDL_STARTUP, pidl));
  try
    if SHGetPathFromIDList(pidl, Buffer) then
      Result := Buffer;
  finally
    CoTaskMemFree(pidl);
  end;
end;

function IsInStartup(LinkName: string): Boolean;
var
  WideFile: WideString;
begin
  WideFile := GetStartupFolder + '\' + LinkName + '.lnk';
  Result := FileExists(WideFile);
end;

procedure SetStartup(Filename, LinkName: string; SetIt: Boolean);
var
  MyObject: IUnknown;
  MySLink: IShellLink;
  MyPFile: IPersistFile;
  WideFile: WideString;
begin
  WideFile := GetStartupFolder + '\' + LinkName + '.lnk';
  if fileexists(WideFile) then DeleteFile(WideFile);

  if SetIt then
  begin
    MyObject := CreateComObject(CLSID_ShellLink);
    MySLink := MyObject as IShellLink;
    MyPFile := MyObject as IPersistFile;
    with MySLink do
    begin
      SetPath(PChar(FileName));
      SetWorkingDirectory(PChar(ExtractFilePath(FileName)));
    end;
    MyPFile.Save(PWChar(WideFile), False);
  end;
end;


procedure BrowseCallbackProc(handle: hwnd; Msg: integer; lParam: integer; lpData: Integer); stdcall;
begin
  if Msg = BFFM_INITIALIZED then
    SendMessage(handle, BFFM_SETSELECTION, 1, lpData);
end;

function SelectDir(hndl: THandle; TitleName: string; var folder: string; mode: Integer): Boolean;
var
  lpItemID: PItemIDList;
  BrowseInfo: TBrowseInfo;
  DisplayName: array[0..MAX_PATH] of char;
  TempPath: array[0..MAX_PATH] of char;
  ppIdl: PItemIdList;
begin
  Result := false;
  OleInitialize(nil);
  try
    SHGetSpecialFolderLocation(hndl, mode, ppIdl);

    FillChar(BrowseInfo, sizeof(TBrowseInfo), #0);
    BrowseInfo.pidlRoot := ppIdl;
    BrowseInfo.hwndOwner := hndl;
    BrowseInfo.pszDisplayName := @DisplayName;
    BrowseInfo.lpszTitle := PChar(TitleName);
    BrowseInfo.lParam := Integer(PChar(folder));
    BrowseInfo.lpfn := @BrowseCallbackProc;
    BrowseInfo.ulFlags := BIF_RETURNONLYFSDIRS or BIF_NEWDIALOGSTYLE;
    lpItemID := SHBrowseForFolder(BrowseInfo);
    if lpItemId <> nil then begin
      SHGetPathFromIDList(lpItemID, TempPath);
      Result := true;
      folder := TempPath;
      GlobalFreePtr(lpItemID);
    end;
  finally
    OleUninitialize();
  end;
end;

end.

