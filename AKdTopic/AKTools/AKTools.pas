//=============================================================================
//******************************************************* Редакция 3.9 ********
//
//               AKTools - библиотека вспомогательных функций.
//                 приложение к AKdTopic (www.akhome.da.ru)
//
//               Copyright(c), Александр Крамаренко. 1999-2000
//
//*****************************************************************************
//=============================================================================
// Вы можете использовать части этой библиотеки без какого-либо упоминания
// моих авторских прав. Некоторые процедуры вовсе не претендуют на звание
// "самый качественный код 2000ого года", а некоторые и вовсе сделаны как
// заплатки. Так что перед использованием просмотрите соответсвующую процедуру
// на предмет пригодности для ваших задач.
//=============================================================================
// Список основных вопросов :
//    1> Как сделать поиск по фразе ? (WordsIsNear)
//    2> Как получить серийный номер винчестера ? (GetComputerID)
//    3> Как узнать имя корневого узла у конкретного TTreeNode ? (GetNodeFrom)
//    4> Как зарегистрировать DLL ? (RegisterDLL)
//    5> Как отдать время системе из консольного приложения ?
//       (ConsoleProcessMessages)
//    6> Как сделать диалог, всплывающий после нажатия некоторой
//       комбинации клавиш ? (CopyrightChecker)
//    7> Как вызвать диалог выбора фолдера ?
//    8> Как сделать полупрозрачное окно в Windows2000? (SetWindowTransp)
//    9> Как сохранить экран в jpeg ? (Sceern2Jpg)
//   10> Как наиболее просто сделать мультиязыковую поддержку своему
//       приложению ? (TLanguageLoader). Смотрите AKdTopic#46
//   11> Как получить список процессов/узнать информацию о них
//       (GetProcessInfo и др.)
//   12> Как сделать переменную, доступную из разных приложений. (TChannel)
//==============================================================================

unit AKTools;

interface

uses Windows, SysUtils, Classes, ShlObj, Messages, Dialogs, Controls,
     ComCtrls, Graphics, jpeg, TypInfo, IniFiles, TlHelp32;

const
  csCryptFirst = 28;
  csCryptSecond = 235;
  csCryptHeader = '';

// Control adv messages
  TV_FIRST          = $1100;
  TVM_ENSUREVISIBLE = TV_FIRST + 20;

// Guid'ы, не определенные в стандартных дельфовых модулях.
  IID_IOleContainer:TGUID = '{0000011B-0000-0000-C000-000000000046}';
  IID_IOleCommandTarget:TGUID = '{b722bccb-4e68-101b-a2bc-00aa00404770}';
  CGID_MSHTML:TGUID = '{DE4BA900-59CA-11CF-9592-444553540000}';

type

  EFileMappingError = class(Exception);
  ECryptError = class(Exception);

  TChars = set of char;

  EChannel = class(Exception);
  TChannel = class(TObject)
   // Класс предназначеный для упрощения обмена данными между приложениями.
   // Для установки канала достаточно вызвать конструктор, в который
   // передать имя канала; место для помещения данных и Len - длину
   // данных:
   //---------------------------------------------------------------------------
   //   var str: PWordArray;
   //   begin
   //    with TChannel.Create('myChannel', str, 10*SizeOf(Word)) do
   //     try
   //      str^[0] := 55;
   //      Caption := IntToStr(Str^[0]);
   //    finally
   //     Free;
   //   end;
   //---------------------------------------------------------------------------
     fChannelName : String;
     fFMObject : Integer;
     fFMMem : Pointer;
     fFMLen : Integer;
    private
     procedure Close;
    public
     procedure Clean;
     constructor Create(Channel:String; var Data; Len:Integer);
     destructor Destroy; override;
   end;

  // Родительский класс для списков
  // Подразумевает, что все элементы - не Pointer, а TObject
  TObjectList = class(TList)
  private
    procedure CheckObject(AObject: TObject);
  public
    procedure Clear; override;
    function Add(AObject: TObject): integer;
    procedure Delete(Index: integer);
    procedure Remove(AObject: TObject);
    procedure Insert(Index: Integer; AObject: TObject);
  end;

  // Получает список всех вложенных файлов в директории Dir с маской Mask
  TCustomTreeFileList = class(TObject)
    private
     FDir : String;
     FMask : String;
     procedure FindRecurse(Folder:String; Mask:String);
     procedure FindFiles(Folder:String; Mask:String);

    protected
     // Перекройте этот метод, для получения информации о найденных файлах.
     procedure _Process(FileName:String); virtual; abstract;

     procedure Process(FileName:String);
    public
     constructor Create(dir:String; mask:String);
     destructor Destroy; override;

     procedure ProcessFind;
   end;

  // Работает с History - Списком
  TCustomHistoryList = class(TObject)
    private
     FHList : TStringList;
     FPosition : Integer;
    public
     constructor Create;
     destructor Destroy; override;

     procedure Clear;

     procedure AddHistory(Str:String); virtual;
     function GetHistory: String; virtual;
     function goBack:Boolean;
     function goForward:Boolean;

     function Stack:String;
     property Position: Integer read FPosition;
   end;

  // Класс для работы с FileMapping
  TFileMapping = class(TObject)
   private
    FPtr : Pointer;
    FSz : Integer;
    hFile, hMapFile : THandle;

    procedure Finalize;
   public
    constructor Create(fn:String);
    destructor Destroy; override;

    property Data: Pointer read FPtr;
    property Size: Integer read FSz;
   end;

  // Класс для интернационализации приложения
  TLanguageLoader = class(TObject)
   private
    FSectionComp: TComponent;
    procedure LoadStringProperties(Component: TComponent);
    function GetCaption(Name:string):string;
   public
    FIni: TIniFile;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(Component: TComponent; LangFileName: string);
   end;


// ********************* Работа с именами файлов *******************************

 // Возвращает имя файла без расширения
 function GetFileNameWOExt(fn:String):String;

 // Добавляет "\" к имени директории, если это нужно
 function GetDirectory(St:string):String;

 // Удаляет букву диска от имени файла
 function GetRelativeDirectory(St:string):String;

 // Возвращает полный путь к файлу по его относительному пути
 function CompletePath(fn, CurDir:String):String;

 // Удаляет из строки d1 все двойные "\" и "/", т.е. из
 // строки "c:\\\\/tools\\txt" функция сделает "c:\tools\txt"
 function RepairPathName(d1:String):String;

 // Сравнивает два пути, игнорируя регистр букв и
 // лишние "\", "/".
 function CompareDirectoryes(d1, d2: String):Boolean;

// *********************** Работа со строками **********************************

 // Возвращает сегмент с порядковым номером N (считая с нуля),
 // Если сегмента с номером N нет, то функция вернет SegSep.
 //  Например, если Str = "tos\pax\file\dir\sux\sux.htm", SegSep = "\", а
 //  N = 2, то резултатом будет строка "sux".
 function GetRightSegment(N: Integer; Str: String; SegSep:Char):String;
 function GetLeftSegment(N: Integer; Str: String; SegSep:Char):String;

 // Криптует строку Str
 function CryptString(Str:String):String;

 // Дешифрует криптованную строку Str
 function UnCryptString(Str:String):String;

 // Проверяет, что в строке нет символов с кодом больше #127
 function IsLat(Str:String):boolean;

 // Преобразует OEM->ANSI
 function StrOEMToANSI(St:String):String;

 // Преобразует ANSI->OEM
 function StrANSItoOEM(St:String):String;

 // Возвращает строку, разделенную по словам
 procedure GetStrWords(St:String; List:TStringList; latonly: boolean = true);

 // Возвращает true, если слова, перечисленные через пробел
 // в Words находятся в строке St, причем расстояние между
 // ними не более 10 символов (использовать для поиска по фразе)
 function WordsIsNear(St:String; Words:String):boolean;

 function WordsIn(St: String; Words:String):boolean;

 // Удаляет указанные символы из строки
 function TrimIn(St:string; rchars: TChars): String;

 // Перобразует текст в строку, путем удаления из него всех символов #13, #10,
 // #9 (если необходимо добавляет "пробел").
 function TextToLine(St:string): String;

 // Возвращает инициалы имени, указанного в Name
 function GetNameLT(Name:String):String;

 // Возвращает позицию первого символа, отличного от Ch.
 // В StartFrom указывается с какого символа начинать проверку
 // Если символа с кодом отличным от ch не найдено, то возвращается 0.
 function NotCharPos(St:String; ch:Char; StartFrom:Integer = 1):Integer;

 // Возвращает строку, в которой все символы c1 заменены на
 // c2. (работает много быстрее StringReplace)
 function ReplaceChar(st: String; c1, c2: char):String;

 // Разбивает строку на подстроки, длина каждой из которых
 // не превышает len символов. Разбивка производится только
 // на стыках слов, однако если слово слишком длинное, то оно
 // разобьется "как есть". Строки отделяются друг от друга
 // последовательностью символов #13#10. first и next указывают
 // отступы с левого края в первой и следующих строках.
 function WordWrapStr(st:String; len:Integer; first: Integer = 0; next:Integer = 0):String;

// **************************** Работа с файлами *******************************

 // Создает файл, если таковой не существует
 procedure CreateFileIfNotExists(fn: String);


// ************************ Системная информация *******************************

 // Возвращает число, идентифицирующее данный компьютер
 function GetComputerID:Integer;

// ******************* Функции для облегчения работы с контролами **************

//------------------------ TTreeView ----------------------------
 // Возвращает предка (в том числе и дальнего) объекта obj,
 // у которого родителем является childOf. Возвращает nil,
 // если такого предка нет.
 function GetNodeFrom(obj, childOf: TTreeNode):TTreeNode;

//--------------------- TListBox, TComboBox ---------------------
 // Если строка Str существует в List, то возвращается ее порядковый номер,
 // иначе  --   -1.  Если Text = true, то поиск строки ведется без учета
 // регистра букв.
 function GetIndexOfStr(List: TStrings; Str: String; Text:Boolean = true):Integer;


// ************************** Работа с числами *********************************
 // Шифрует число
 function CryptInteger(ID:Integer):Integer;

 // Дешифрует число
 function UnCryptInteger(ID:Integer):Integer;

// **************************** Системные функции ******************************

 // Если reg = true, то функция регистрирует DLL, в противном случае - удаляет
 // информацию о ней из реестра.
 procedure RegisterDLL(fn:String; Reg: boolean = true);

 // Возвращает имя системной директории
 function GetSystemDir:String;

 // Аналог Application.ProcessMessages
 procedure ConsoleProcessMessages;

 // Делает окно hndl полупрозрачным. Perc - уровень прозрачности
 // в процентах (1-100). Только для Win2k.
 procedure SetWindowTransp(hndl: THandle; Perc: byte);

 // Сохраняет указнную область экрана в JPEG.
 function Screen2Jpeg(R: TRect): TJpegImage;

 // возвращает список процессов - NT4 unsupported
 procedure GetProcessList(List: TStrings);

 // возвращает список моудлей - NT4 unsupported
 procedure GetModuleList(List: TStrings);

 // Возвращает информацию о процессе ProcessID
 procedure GetProcessInfo(ProcessID:DWord; var Path: String);

// ****************************** Математика ***********************************
 // Вычисляет расстояние между двумя точками
 function DistOf(px,py, p1x,p1y :Integer):Integer;

// ****************************** Диалоги **************************************

 // Вызывает диалог выбора фолдера
 function GetLocaleFolder(Title: string): string;

 // Показывает диалог копирайтов после набора слова "ISDEVELOPEDBY".
 // Поместите эту функцию в обработчик ApplicationMessages.OnMessage
 function CopyrightChecker(var Msg: tagMSG; Prj:String):Boolean;

//##############################################################################
//##############################################################################

 // Эта переменная содержит текст, выводимый функцией CopyrightChecker.
var CprText: String;

// Если при использовании ConsoleProcessMessages эта переменная
// установилась в true, то нужно выходить из приложения.
var TerminateApp : Boolean;

const
  WS_EX_LAYERED = $80000;
  LWA_COLORKEY = 1;
  LWA_ALPHA    = 2;

type
  TSetLayeredWindowAttributes = function(
            hwnd : HWND;         // handle to the layered window
            crKey : TColor;     // specifies the color key
            bAlpha : byte;       // value for the blend function
            dwFlags : DWORD       // action
            ): BOOL; stdcall;

implementation

//******************************************************************************
//==============================================================================
// Процедуры и функции
//==============================================================================
//******************************************************************************

function GetIndexOfStr(List: TStrings; Str: String; Text:Boolean = true):Integer;
var i : Integer;
begin
  Result := -1;
  for i := 0 to List.Count-1 do
   begin
    if ((AnsiCompareText(List[i], Str) = 0) and (Text)) or
       ((CompareStr(List[i], Str) = 0) and (not Text)) then
     begin
      Result := i;
      Break;
     end;
   end;
end;

function GetProcessHandle(ProcessID: DWORD): THandle;
begin
  Result := OpenProcess(PROCESS_ALL_ACCESS, True, ProcessID);
end;

procedure GetProcessList(List: TStrings);
var
  I: Integer;
  hSnapshoot: THandle;
  pe32: TProcessEntry32;
begin
  List.Clear;
  hSnapshoot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

  if (hSnapshoot = 0) then
      Exit;
  pe32.dwSize := SizeOf(TProcessEntry32);
  if (Process32First(hSnapshoot, pe32)) then
  repeat
    I := List.Add(Format('%x, %x: %s',
      [pe32.th32ProcessID, pe32.th32ParentProcessID, pe32.szExeFile]));
    List.Objects[I] := Pointer(pe32.th32ProcessID);
  until not Process32Next(hSnapshoot, pe32);

  CloseHandle (hSnapshoot);
end;

procedure GetModuleList(List: TStrings);
var
  I: Integer;
  hSnapshoot: THandle;
  me32: TModuleEntry32;
begin
  List.Clear;
  hSnapshoot := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, 0);
  if (hSnapshoot = 0) then
      Exit;
  me32.dwSize := SizeOf(TModuleEntry32);
  if (Module32First(hSnapshoot, me32)) then
  repeat
    I := List.Add(me32.szModule);
    List.Objects[I] := Pointer(me32.th32ModuleID);
  until not Module32Next(hSnapshoot, me32);

  CloseHandle (hSnapshoot);
end;

procedure GetProcessInfo(ProcessID:DWord; var Path: String);
type
 TNTQuerySystemInformation = function (a:LongInt; b:PChar; c:longInt; d:longInt): longInt; stdcall;
 ThreadInfo = record
  ftCreationTime : FILETIME;
  dwUnknown1 : DWORD;
  dwStartAddress : DWORD;
  dwOwningPID : DWORD;
  dwThreadID : DWORD;
  dwCurrentPriority : DWORD;
  dwBasePriority : DWORD;
  dwContextSwitches : DWORD;
  dwThreadState : DWORD;
  dwUnknown2 : DWORD;
  dwUnknown3 : DWORD;
  dwUnknown4 : DWORD;
  dwUnknown5 : DWORD;
  dwUnknown6 : DWORD;
  dwUnknown7 : DWORD;
 End ;

 PProcessInfo = ^TProcessInfo ;
 TProcessInfo = record
  dwOffset:            DWORD;
  dwThreadCount:       DWORD;
  dwUnkown1:           array[0..5] of DWORD;
  ftCreationTime:      FILETIME ;
  dwUnkown2:           DWORD;
  dwUnkown3:           DWORD;
  dwUnkown4:           DWORD;
  dwUnkown5:           DWORD;
  dwUnkown6:           DWORD;
  pszProcessName:      PWideChar;
  dwBasePriority:      DWORD;
  dwProcessID:         DWORD;
  dwParentProcessID:   DWORD;
  dwHandleCount:       DWORD;
  dwUnkown7:           DWORD;
  dwUnkown8:           DWORD;
  dwVirtualBytesPeak:  DWORD;
  dwVirtualBytes:      DWORD;
  dwPageFaults:        DWORD;
  dwWorkingSetPeak:    DWORD;
  dwWorkingSet:        DWORD;
  dwUnkown9:           DWORD;
  dwPagedPool:         DWORD;
  dwUnkown10:          DWORD;
  dwNonPagedPool :     DWORD;
  dwPageFileBytesPeak: DWORD;
  dwPageFileBytes:     DWORD;
  dwPrivateBytes:      DWORD;
  dwUnkown11:          DWORD;
  dwUnkown12:          DWORD;
  dwUnkown13:          DWORD;
  dwUnkown14:          DWORD;
  Ati : array [0..1] of ThreadInfo;
End;

var
  hSnapshoot: THandle;
  pe32: TProcessEntry32;
  NTQuerySystemInformation : TNTQuerySystemInformation;

  hLib, Cur : DWORD;
  Ptr  : Pointer;
  PrcInfo : PProcessInfo;
  Buf   : array [1..20480] of char;
begin
  Path := '';

  hSnapshoot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (hSnapshoot = 0) then
   begin
    hLib := LoadLibrary('ntdll.dll');
    if hLib <> 0 then
     begin
      NTQuerySystemInformation := GetProcAddress(hLib, 'NtQuerySystemInformation');
      NTQuerySystemInformation(5, @Buf, 20480, 0);
      Cur := 1; Ptr := @Buf[Cur];
      PrcInfo := Ptr;
      repeat
        Inc(Cur, PrcInfo.dwOffset);
        Ptr := Addr(Buf[Cur]);
        PrcInfo := Ptr;
        if PrcInfo^.dwProcessID = ProcessID then
         begin
          Path := PrcInfo^.pszProcessName;
          Break;
         end;
      until PrcInfo.dwOffset=0;
      CloseHandle(hLib);
     end;
    Exit;
   end;

  pe32.dwSize := SizeOf(TProcessEntry32);
  if (Process32First(hSnapshoot, pe32)) then
  repeat
    if pe32.th32ProcessID = ProcessID then
    begin
      Path := pe32.szExeFile;
      Break;
    end;
  until not Process32Next(hSnapshoot, pe32);

  CloseHandle (hSnapshoot);
end;

function GetFileNameWOExt(fn:String):String;
begin
  Result := Copy(fn, 1, Length(fn)-Length(ExtractFileExt(fn)));
end;

function WordsIn(St: String; Words:String):boolean;
var sl :TStringList;
    i: Integer;
    lw1, lw2 : String;
begin
  Result := True;
  if Trim(Words) = '' then begin Result := True; exit; end;

  sl := TStringList.Create;
  try
   lw2 := AnsiLowerCase(st);
   GetStrWords(Words, sl, false);
   for i := 0 to sl.Count-1 do
    begin
     lw1 := AnsiLowerCase(sl[i]);
     if Pos(lw1, lw2) = 0 then
      begin
       Result := False;
       break;
      end;
    end;
  finally
   FreeAndNil(sl);
  end;
end;

function WordWrapStr;
var i : Integer;
    ln, crStart, crLastSp, crlen : Integer;
    sta:String;
begin
  Result := StringOfChar(' ', first);
  crLastSp := Len;
  crlen := 0; crStart := 1; ln := 0;
  for i := 1 to Length(st) do
   begin
    inc(crLen);
    if (crLen > len+1) or (i = Length(st)) then
     begin
      if i = Length(st) then crLastSp := MaxInt;
      inc(ln);
      if ln > 1 then Sta := StringOfChar(' ', next)
                else Sta := '';
      Result := Result + Sta + Trim(Copy(st, crStart, crLastSp));
      if i <> Length(st) then Result := Result + #13#10;
      crLen := i - (crStart + crLastSp);
      crStart := crStart + crLastSp;
      crLastSp := Len;
     end
    else
    if (st[i] in [' ']) then
      begin
       crLastSp := crLen;
      end;
   end;
end;

function ReplaceChar(st: String; c1, c2: char):String;
var i : Integer;
begin
  Result := st;
  for i := 1 to Length(st) do
   if Result[i] = c1 then
    Result[i] := c2;
end;

function RepairPathName(d1:String):String;
var i,p : Integer;
    prevCh :Char;
begin
  Result := d1; p := 0; prevCh := #0;
  for i := 1 to Length(d1) do
   begin
    inc(p);
    Result[p] := d1[i];
    if d1[i] = '/' then Result[p] := '\';
    if d1[i] in ['\', '/'] then
     if PrevCh in ['\', '/'] then
      dec(p);
    PrevCh := d1[i];
   end;
  SetLength(Result, p);
end;

function CompareDirectoryes(d1, d2: String):Boolean;
begin
  Result := AnsiCompareText(GetDirectory(RepairPathName(d1)),
                            GetDirectory(RepairPathName(d2))) = 0;
end;

function GetNodeFrom(obj, childOf: TTreeNode):TTreeNode;
var ct, prevct : TTreeNode;
begin
  ct := obj;
  repeat
   prevct := ct;
   ct := ct.Parent;
  until (not Assigned(ct)) or (ct = childOf);

  if (childOf <> nil) and (not Assigned(ct)) then
   Result := nil
  else
   Result := prevCt;
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
  while ConsoleProcessMessage(Msg) do {loop};
end;

function GetDirectory(St:string):String;
begin
  Result := St;
  if Length(st) > 0 then
   if not (st[Length(st)] in ['\', '/']) then
    Result := Result + '\';
end;

function GetRelativeDirectory(St:string):String;
var ps : Integer;
begin
  ps := Pos(':', St);
  if ps = 0 then Result := St
            else Result := Copy(st, ps+1, Length(st)-ps);
end;

function GetRightSegment(N: Integer; Str: String; SegSep:Char):String;
var i : Integer;
    ResPos, SecPos, SecN : Integer;
begin
  SecN := 0;
  ResPos := -1;
  SecPos := Length(Str);

  for i := Length(Str) downto 1 do
   begin
    if (Str[i] = SegSep) then
     begin
      if SecN = N then
       begin
        ResPos := i+1; // левый SegSep
        break;
       end;
      SecPos := i-1;  // правый SegSep
      Inc(SecN);
     end;
   end;

  if (ResPos = -1) and (N = SecN) then
   ResPos := 1;

  if ResPos = -1 then
   Result := SegSep
  else
   Result := Copy(Str, ResPos, SecPos-ResPos+1);
end;

function GetLeftSegment(N: Integer; Str: String; SegSep:Char):String;
var i : Integer;
    ResPos, SecPos, SecN : Integer;
begin

  SecN := 0;
  ResPos := -1;
  SecPos := 1;

  for i := 1 to Length(Str) do
   begin
    if Str[i] = SegSep then
     begin
      if SecN = N then
       begin
        ResPos := i-1; // левый SegSep
        break;
       end;
      SecPos := i+1;  // правый SegSep
      Inc(SecN);
     end;
   end;

  if (ResPos = -1) and (N = SecN) then
   ResPos := Length(Str);

  if ResPos = -1 then
   Result := SegSep
  else
   Result := Copy(Str, SecPos, ResPos-SecPos+1);
end;

function CompletePath(fn, CurDir:String):String;
var LastDir : String;
    St : String;
begin
  St := Copy(ExtractFileDrive(CurDir), 1, 1);
  if Length(St) <> 1 then
   raise EConvertError.Create('CompletePath failed');

  GetDir(0, LastDir);
  ChDir(CurDir);
  Result := ExpandFileName(fn);
  ChDir(LastDir);
end;

function CryptString(Str:String):String;
var i,clen : Integer;
begin
  clen := Length(csCryptHeader);
  SetLength(Result, Length(Str)+clen);
  Move(csCryptHeader[1], Result[1], clen);
  For i := 1 to Length(Str) do
   begin
    if i mod 2 = 0 then
     Result[i+clen] := Chr(Ord(Str[i]) xor csCryptSecond)
    else
     Result[i+clen] := Chr(Ord(Str[i]) xor csCryptFirst);
   end;
end;

function UnCryptString(Str:String):String;
var i, clen : Integer;
begin
  clen := Length(csCryptHeader);
  SetLength(Result, Length(Str)-clen);
  if Copy(Str, 1, clen) <> csCryptHeader then
   raise ECryptError.Create('UnCryptString failed');

  For i := 1 to Length(Str)-clen do
   begin
    if (i) mod 2 = 0 then
     Result[i] := Chr(Ord(Str[i+clen]) xor csCryptSecond)
    else
     Result[i] := Chr(Ord(Str[i+clen]) xor csCryptFirst);
   end;
end;

procedure CreateFileIfNotExists(fn: String);
begin
  if not FileExists(fn) then
   with TFileStream.Create(fn, fmCreate or fmShareDenyNone) do
    Free;
end;

function IsLat(Str:String):boolean;
var i : Integer;
begin
   Result := True;
   for i := 1 to Length(Str) do
    if Str[i] > #127 then
     begin
      Result := False;
      exit;
     end;
end;

function StrOEMToANSI(St:String):String;
begin
  Result := '';
  if st = '' then exit;
  SetLength(Result, Length(St));
  OemToChar(PChar(St), PChar(Result));
end;

function StrANSItoOEM(St:String):String;
begin
  Result := '';
  if st = '' then exit;
  SetLength(Result, Length(St));
  CharToOEM(PChar(St), PChar(Result));
end;

procedure GetStrWords(St:String; List:TStringList; latonly: boolean = true);
var i : Integer;
    Start : Integer;
    Wrd : String;
    str: String;
begin
  List.Clear; str := st + ' ';
  Wrd := ''; Start := 1;
  for i := 1 to Length(str) do
   begin
    if str[i] in [#13, #10, #9, #32..#64, #91..#96, #123..#191] then
     begin
      Wrd := Trim(Copy(str, Start, i-Start));
      if ((not IsLat(Wrd)) or (not latonly)) and (Wrd <> '') then
       List.Add(Wrd);
      Start := i+1;
     end;
    end;
end;

function GetComputerID:Integer;
var
  VolumeSerialNumber : DWORD;
  MaximumComponentLength : DWORD;
  FileSystemFlags : DWORD;
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

function CryptInteger(ID:Integer):Integer;
type TBytes= Array[0..3] of byte;
var _src, _res : Integer;
    src : TBytes absolute _src;
    dst : TBytes absolute _res;
begin
    _src := ID;
    dst[0] := src[3] xor 9;
    dst[1] := src[0] xor 155;
    dst[2] := src[1] xor 65;
    dst[3] := src[2] xor 215;
    Result := _res;
end;

function UnCryptInteger(ID:Integer):Integer;
type TBytes= Array[0..3] of byte;
var _src, _res : Integer;
    src : TBytes absolute _src;
    dst : TBytes absolute _res;
begin
   _src := ID;
   dst[0] := src[1] xor 155;
   dst[1] := src[2] xor 65;
   dst[2] := src[3] xor 215;
   dst[3] := src[0] xor 9;
   Result := _res;
end;

// Возвращает true, если фраза wrds 100% присутствует.
// Возвращает false, если фраза пока не найдена, но первое слово
//  уже обнаружено. Первый символ этого слова возвращается в Res.
//  Если Res = 0, то фраза 100% отсутствует в строке.
function FirstWordsIsNear(St: String; wrds: TStringList; var Res:Integer):Boolean;
var prevLen, prev, psr, w: Integer;
    tt : String;
begin
   Res := 0; Result := True;
   if Wrds.Count = 0 then
    exit;
   prevLen := 0; Prev := 0;
   tt := CharLower(PChar(st));
   for w := 0 to Wrds.Count-1 do
    begin
     psr := Pos(wrds[w], tt);
     if w = 0 then begin
      Res := psr;
      prev := psr;
      FillChar(tt[1], psr, #32);
      end;
     if (psr = 0) or (psr-prev-prevLen > 10) then
      begin
       Result := False;
       Break;
      end;
     prev := psr;
     prevLen := Length(wrds[w]);
    end;
end;

function WordsIsNear(St:String; Words:String):boolean;
var sl :TStringList;
    Offset, psf: Integer;
    str: String;
begin
  Result := False;
  if Trim(Words) = '' then begin Result := True; exit; end;

  sl := TStringList.Create;
  try
   psf := 0; Offset := 1;
   GetStrWords(Words, sl, false);
   repeat
    str := Copy(st, offset, maxint);
    if FirstWordsIsNear(str, sl, psf) then
     begin
      Result := True;
      break;
     end;
    inc(offset, psf);
   until (str = '') or (psf = 0);
  finally
   FreeAndNil(sl);
  end;
end;

function TrimIn(St:string; rchars: TChars): String;
var f,s : Integer;
begin
  SetLength(Result, Length(St));
  s := 0;
  for f := 1 to Length(St) do
   begin
    if not (St[f] in rchars) then
     begin
      inc(s);
      Result[s] := st[f];
     end;
   end;
  SetLength(Result, s);
end;

function TextToLine(St:string): String;
var f,s : Integer;
    PrevDeleted : boolean;
begin
  SetLength(Result, Length(St));
  s := 0; PrevDeleted := False;
  for f := 1 to Length(St) do
   begin
    if not (St[f] in [#13,#10,#9]) then
     begin
      inc(s);
      Result[s] := st[f];
      PrevDeleted := False;
     end
    else
     begin
      if not PrevDeleted then
       begin
        inc(s);
        Result[s] := ' ';
       end;
      PrevDeleted := True;
     end;
   end;
  SetLength(Result, s);
end;

procedure RegisterDLL(fn: String; Reg: boolean = true);
type TRegProc = function : HResult; stdcall;
var LibHandle : THandle;
    ProcName: String;
    RegProc: TRegProc;
begin
  if Reg then ProcName := 'DllRegisterServer'
         else ProcName := 'DllUnregisterServer';

  LibHandle := LoadLibrary(PChar(FN));
  if LibHandle = 0 then raise Exception.CreateFmt('Failed to load "%s"', [FN]);
  try
    @RegProc := GetProcAddress(LibHandle, PChar(ProcName));
    if @RegProc = Nil then
      raise Exception.CreateFmt('%s procedure not found in "%s"', [ProcName, FN]);
    if RegProc <> 0 then
      raise Exception.CreateFmt('Call to %s failed in "%s"', [ProcName, FN]);
  finally
    FreeLibrary(LibHandle);
  end;
end;

function GetSystemDir:String;
begin
  SetLength(Result, 1024);
  SetLength(Result, GetSystemDirectory(PChar(Result), Length(Result)));
end;

function GetNameLT(Name:String):String;
var p,l,i : Integer;
begin
  Result := Copy(Name, 1, 1); // первый символ
  p := Pos(' ', Name); // символ после первого пробела
  if p <> 0 then
   Result := Result + Copy(Name, p + 1, 1);
  l := p;
  for i := Length(Name) downto 1 do
   if Name[i] = ' ' then
    begin
     l := i;
     break;
    end;
  if p <> l then Result := Result + Copy(Name, l + 1, 1);
end;

function NotCharPos(St:String; ch:Char; StartFrom:Integer = 1):Integer;
var i : Integer;
begin
  Result := 0;
  for i := StartFrom to Length(st) do
   if st[i] <> ch then
    begin
     Result := i;
     Break;
    end;
end;

function GetLocaleFolder(Title: string): string;
var
  BI: TBrowseInfo;
  PIDL: PItemIDList;
  Path: array[0..MAX_PATH-1] of Char;
  ResPIDL: PItemIDList;
  i: integer;
begin
  Result := '';
  SHGetSpecialFolderLocation(0, CSIDL_DRIVES, PIDL);
  FilLChar(BI, Sizeof(BI), 0);
  with BI do begin
    hwndOwner := 0;
    lpszTitle := PChar(Title);
    ulFlags := BIF_RETURNONLYFSDIRS;
    pidlRoot := PIDL;
  end;
  resPIDL := SHBrowseForFolder(BI);
  if Assigned(resPIDL) then begin
    SHGetPathFromIDList(ResPIDL, @Path[0]);
    i := 0; while Path[i] <> #0 do inc(i);
    SetLength(Result, i); Move(Path, Result[1], i);
  end;
end;

function CopyrightChecker(var Msg: tagMSG; Prj:String):Boolean;
const Copyr:String = 'ISDEVELOPEDBY';
      Ps: Integer = 1;
var Key : Char;
begin
     Result := False;
     if Msg.message = WM_KEYUP then
      begin
       Key := Char(Msg.wParam);
       if Key = Copyr[ps] then
        begin
         if ps > 11 then
          MessageBeep(0);
         if ps = Length(Copyr) then
          begin
           ShowMessage(Prj + ' : ' + CprText);
           Result := True;
          end;
          inc(ps);
        end
       else
        ps := 1;
      end;
end;

function DistOf(px,py, p1x,p1y :Integer):Integer;
var kat1, kat2 : Integer;
begin
   kat1 := abs(px - p1x);
   kat2 := abs(py - p1y);
   Result := Round(sqrt(sqr(kat1) + sqr(kat2)));
end;

function Screen2Jpeg(R: TRect): TJpegImage;
var
  B: TBitmap;
  DC: HDC;
begin
  DC:= GetDC(GetDesktopWindow);
  try
    B:= TBitmap.Create;
    try
      B.Width:=R.Right-R.Left;
      B.Height:= R.Bottom-R.Top;
      BitBlt(B.Canvas.Handle, 0, 0, B.Width, B.Height, DC,
       R.Left, R.Top, SRCCOPY);
      Result:= TJPegImage.Create;
      Result.Assign(B);
    finally
      FreeAndNil(B);
    end;
  finally
    ReleaseDC(GetDesktopWindow, DC);
  end;
end;

procedure SetWindowTransp(hndl: THandle; Perc: byte);
var mh: THandle;
    SetLayeredWindowAttributes : TSetLayeredWindowAttributes;
begin
 if Perc <> 100 then
  begin
   mh := GetModuleHandle('user32.dll');
   @SetLayeredWindowAttributes := GetProcAddress(mh, 'SetLayeredWindowAttributes');
   if @SetLayeredWindowAttributes <> nil then
   begin
     SetWindowLong(hndl, GWL_EXSTYLE, GetWindowLong(hndl, GWL_EXSTYLE) or WS_EX_LAYERED);
     SetLayeredWindowAttributes(hndl, 0, Round(Perc/100*255), LWA_ALPHA);
    end;
  end;
end;

//******************************************************************************
//==============================================================================
// TCustomTreeFileList
//==============================================================================
//******************************************************************************

constructor TCustomTreeFileList.Create(dir, mask: String);
begin
   FDir := GetDirectory(dir);
   FMask := mask;
end;

destructor TCustomTreeFileList.Destroy;
begin
  inherited;
end;

procedure TCustomTreeFileList.FindFiles(Folder, Mask: String);
var di : TSearchRec;
    Res : Integer;
begin
   Res := FindFirst(Folder+Mask, faAnyFile, di);
   while Res = 0 do
    begin
     if not ((di.Attr and faDirectory) = faDirectory) then
      Process(GetDirectory(Folder)+di.Name);
     Res := FindNext(di);
    end;
   FindClose(di);
end;

procedure TCustomTreeFileList.FindRecurse(Folder, Mask: String);
var di : TSearchRec;
    Res : Integer;
    Fldr : String;
begin
  Res := FindFirst(Folder+'*.*', faAnyFile, di);
  while Res = 0 do
   begin
    if (di.Name <> '.') and (di.Name <> '..') and ((di.Attr and faDirectory) = faDirectory) then
     begin
      Fldr := GetDirectory(Folder+di.Name);
      FindFiles(Fldr, Mask);
      FindRecurse(Fldr, Mask);
     end;

    Res := FindNext(di);
   end;
  FindClose(di);
end;

procedure TCustomTreeFileList.Process(FileName: String);
begin
  _Process(FileName);
end;

procedure TCustomTreeFileList.ProcessFind;
begin
  FindFiles(FDir, FMask);
  FindRecurse(FDir, FMask);
end;

//******************************************************************************
//==============================================================================
// TCustomHistoryList
//==============================================================================
//******************************************************************************

procedure TCustomHistoryList.AddHistory(Str: String);
var i : Integer;
begin
  for i := FHList.Count-1 downto 0 do
   if FHList[i] = Str then
    begin
     while FHList.Count-1 >= i do
      FHList.Delete(i);
     break;
    end;

  FHList.Add(Str);
  FPosition := FHList.Count-1;
end;

procedure TCustomHistoryList.Clear;
begin
  FHList.Clear;
  FPosition := -1;
end;

constructor TCustomHistoryList.Create;
begin
  FHList := TStringList.Create;
  Clear;
end;

destructor TCustomHistoryList.Destroy;
begin
  inherited;
  FreeAndNil(FHList);
end;

function TCustomHistoryList.GetHistory: String;
begin
  if (FPosition >= 0) and (FPosition <= FHList.Count-1) then
   Result := FHList[FPosition]
  else
   Result := '';
end;

function TCustomHistoryList.goBack: Boolean;
begin
  dec(FPosition);
  Result := (FPosition >= 0);
  if FPosition < 0 then inc(FPosition);
end;

function TCustomHistoryList.goForward: Boolean;
begin
  inc(FPosition);
  Result := (FPosition <= FHList.Count-1);
  if FPosition > FHList.Count-1 then
   dec(FPosition);
end;

function TCustomHistoryList.Stack: String;
begin
  Result := FHList.Text;
end;

//******************************************************************************
//==============================================================================
// TFileMapping
//==============================================================================
//******************************************************************************

constructor TFileMapping.Create(fn: String);
begin
   FPtr := nil;
   hMapFile := 0;
   hFile := 0;

   try
    hFile := CreateFile(PChar(fn), GENERIC_READ,  FILE_SHARE_READ or FILE_SHARE_WRITE,  nil, OPEN_EXISTING, 0, 0);
    if (hFile = 0) then
     raise EFileMappingError.CreateFmt('Could not open file "%s"', [fn]);
    FSz := GetFileSize(hFile, nil);
    hMapFile := CreateFileMapping(hFile, nil, PAGE_READONLY, 0, 0, nil);
    if (hMapFile = 0) then
     raise EFileMappingError.Create('Could not create file-mapping object.');
    FPtr := MapViewOfFile(hMapFile, FILE_MAP_READ,  0, 0, 0);
    if (FPtr = nil) then
     raise EFileMappingError.Create('Could not map view of file.');
   except
    on EFileMappingError do begin Finalize; raise; end
    else raise;
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
// TLanguageLoader
//==============================================================================
//******************************************************************************

constructor TLanguageLoader.Create;
begin
   FIni := nil;
   FSectionComp := nil;
end;

destructor TLanguageLoader.Destroy;
begin
  inherited;
end;

function TLanguageLoader.GetCaption(Name: string): string;
var ps:Integer;
begin
  if not Assigned(FSectionComp) then
   Result := '-error-'
  else
   begin
    ps := Pos('_', FSectionComp.Name)-1;
    if ps < 0 then ps := 255;
    Result := FIni.ReadString(Copy(FSectionComp.Name, 1, ps), Name, 'no-value');
   end;
end;

procedure TLanguageLoader.LoadFromFile(Component: TComponent; LangFileName: string);
begin
 FIni := TIniFile.Create(GetDirectory(ExtractFilePath(ParamStr(0)))+LangFileName);
 with FIni do
  try
   FSectionComp := Component;
   LoadStringProperties(Component);
  finally
   Free;
  end;
end;

procedure TLanguageLoader.LoadStringProperties(Component: TComponent);
var
 Count, I: Integer;
 Info: PTypeInfo;
 Data: PTypeData;
 PropList: PPropList;
 Str: string;
begin
  if (not Assigned(FSectionComp)) or (not Assigned(FIni)) then exit;

  Info := Component.ClassInfo;
  Data := GetTypeData(Info);
  { Allocate memory to hold the property information. }
  GetMem(PropList, Data^.PropCount * SizeOf(PPropInfo));
  try
    Count := GetPropList(Info,[tkString, tkLString, tkWString], PropList);
    for I := 0 to Count-1 do
    begin
      { get the string property value }
      Str := GetStrProp(Component, PropList[I]);
      { Если значение проперти началось с "[" - то это имя ресyрса,
       иначе просто значение проперти}
      if (Length(Str) > 1) and (Str[1] = '[') then
      begin
        { Загрyжаем значение}
        Str := StringReplace(GetCaption(Copy(Str,2,Length(Str)-2)), '\n', #10, [rfReplaceAll]);
        if Str <> '' then
        {Если оное есть то yстанавливаем его}
          SetStrProp(Component, PropList[I], Str);
      end;
    end;
  finally
    FreeMem(PropList, Data^.PropCount * SizeOf(PPropInfo));
  end;
  {Загрyжаем для всех "детей" компонента рекyрсией}
  for I := 0 to Component.ComponentCount-1 do
    LoadStringProperties(Component.Components[I]);
end;

//******************************************************************************
//==============================================================================
// TObjectList
//==============================================================================
//******************************************************************************

function TObjectList.Add(AObject: TObject): integer;
begin
  CheckObject(AObject);
  Result := inherited Add(AObject);
end;

procedure TObjectList.CheckObject(AObject: TObject);
begin
  if not (AObject is TObject) then raise Exception.Create('Expected object type');
end;

procedure TObjectList.Clear;
var
  i: integer;
begin
  for i:=0 to Count-1 do TObject(Items[i]).Free;
  inherited;
end;

procedure TObjectList.Delete(Index: integer);
begin
  TObject(Items[Index]).Free;
  inherited Delete(Index);
end;

procedure TObjectList.Insert(Index: Integer; AObject: TObject);
begin
  CheckObject(AObject);
  inherited Insert(Index, AObject);
end;

procedure TObjectList.Remove(AObject: TObject);
begin
  FreeAndNil(AObject);
  inherited Remove(AObject);
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
   fChannelName := '';
end;

constructor TChannel.Create(Channel: String; var Data; Len:Integer);
begin
  Pointer(Data) := nil;
  fFMLen := Len; fChannelName := Channel;
  fFMObject := CreateFileMapping($FFFFFFFF,  nil, PAGE_READWRITE,
                                 0,  fFMLen, PChar(Channel));

  if (fFMObject = INVALID_HANDLE_VALUE) then
   raise EChannel.Create('Impossible create a channel.');

  fFMMem := MapViewOfFile(fFMObject, FILE_MAP_ALL_ACCESS, 0,  0,  0 );
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
  inherited;
  Close;
end;

//##############################################################################
initialization
 TerminateApp := False;
 CprText := 'Александр Крамаренко'#10+
            '(GroupStudio@mail.ru, 2:5019/10.99@fidonet)'#10+
            'Смоленск, Россия, 2000г'#10#10+
            '"ISDEVELOPEDBY" - ключевое слово для отображения этого окна.';
end.

