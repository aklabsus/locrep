// AKTools akVCLUtils unit.
//         Модуль, помогающий работать с VCL.
//=============================================================================

unit akVCLUtils;

interface

uses SysUtils, Windows, comctrls, Graphics, Classes, Controls, akMisc,
  Forms, Messages, MultiMon, ShellAPI, bigini;

const
  WM_REQUESTUPDATE = WM_USER + 87;

type
  TTreeStore = record
    Path: string;
    Data: Pointer;
    Expands: array of string;
    ItmIndex: Integer;
    TopInd: Integer;
  end;

  TFocusStore = record
    Itm: Integer;
    Data: Pointer;
  end;

// =============================================================================
  // Класс для интернационализации приложения
  TLanguageLoader = class(TObject)
  private
    FSectionComp: TComponent;
    FIni: TBigIniFile;
    fEngLanguage: TLanguageLoader;
    fReplaceWith: String;
    fReplaceFrom: String;
    procedure LoadStringProperties(Component: TComponent);
    function GetCaption(Name: string): string;
  public
    property ReplaceFrom: String read fReplaceFrom write fReplaceFrom;
    property ReplaceWith: String read fReplaceWith write fReplaceWith;

    property EngLanguage: TLanguageLoader read fEngLanguage write fEngLanguage;

    property Ini: TBigIniFile read fIni;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(Component: TComponent; LangFileName: string);
    function GetVariable(VarSec, Name: string; loaddefault: Boolean = true): string;
  end;

// =============================================================================
  // Измененный TCollectionItem : умеет сохранять ссылки с элемента на элемент
  // с помощью GUID'ов и восстанавливать их :

// ========================== TREFRESHER =======================================
  TRefresherProc = procedure(const lpar, rpar: DWORD);
  TRefresher = class;

  TRefMsgWindow = class(TWinControl)
  private
    fRFR: TRefresher;
    fRun: Boolean;
    procedure WMREQUESTUPDATE(var msg: TMessage); message WM_REQUESTUPDATE;
  public
    constructor Create(const rfr: TRefresher); reintroduce;
  end;

  TRefresherRec = class(TCollectionItem)
  private
    fproc: TRefresherProc;
    flpar: DWORD;
    frpar: DWORD;
  public
    property Proc: TRefresherProc read fProc write fProc;
    property LPar: DWORD read flPar write flPar;
    property RPar: DWORD read frPar write frPar;
  end;

  // Класс занимается вызовом любой процедуры вида TRefresherProc, причем
  // даже если 100 раз подряд вызвать метод Request(RefreshData), то реально функция
  // Request вызовется только один раз и только тогда когда приложение начнет
  // обрабатывать события.  Иными словами метод очень полезен для обновления
  // каких-либо данных на форме.
  TRefresher = class
  private
    fProcs: TCollection;
    fMsgWin: TRefMsgWindow;
  public
    property ProcsList: TCollection read fProcs;
    procedure CancelRequests;

    function IndexOf(proc: TRefresherProc): Integer;

    constructor Create;
    destructor Destroy; override;

    // Возваращет true, если процедура уже стоит на очереди выполнения
    function AllreadyRequested(proc: TRefresherProc): Boolean;

    // Ставит процедуру proc в очередь на выполнение.
    procedure Request(proc: TRefresherProc; const lpar: DWORD = 0; const rpar: DWORD = 0);
  end;
//==============================================================================


  { TVCLThread }
  TVCLThread = class(TThread)
  private
    function GetExceptRaised: boolean;
  protected
    fObject: TObject;
    fExcept: TObject;
    fOnException: TExceptionEvent;
    procedure Execute; override;
    procedure DoExcept;
    procedure SafeExecute; virtual; abstract; // THIS ONE SHOULD BE OVERRIDED
                                              // rather than Execute method
  public
    procedure Synchronize(Method: TThreadMethod); 
    property ReturnValue;
    property Terminated;
    property ExceptRaised: boolean read GetExceptRaised;
    property Obj: TObject read fObject;
    property OnException: TExceptionEvent read fOnException write fOnException;
    constructor Create(AObject: TObject; APriority: TThreadPriority = tpNormal; Suspended: Boolean = false);
  end;


  // Показывает стандартный хинт над текущим контролом.
procedure UpdateHint;

// Устанавливаем всем дочерним объектам ForObj с Tag = cTag cвойство Enable
// в cEnable.
procedure EnableStateByTag(cTag: Integer; cEnable: Boolean; ForObj: TWinControl);

procedure VisibleStateByTag(cTag: Integer; cEnable: Boolean; ForObj: TWinControl);

//======== Функции, помогающие работать с TTreeView и TListView ================

// Совмещает заголовки Header Control и ListView (ширину подгоняет)
procedure AlignHeaderAndListView(const HC: THeaderControl; const LV: TListView);

// Растягивает колонку ColumnID на максимально возможную ширину.
procedure MakeLVFullWidth(const ColumnID: Integer; const LV: TListView);

 // Возвращает предка (в том числе и дальнего) объекта obj,
 // у которого родителем является childOf. Возвращает nil,
 // если такого предка нет.
function GetNodeFrom(obj, childOf: TTreeNode): TTreeNode;

// Возвращает узел деревовидной структуры, путь к которой указан в Path.
// Элементы пути разделяются символом "\".
function GetNodeByPath(Path: string; Nodes: TTreeNodes; Data: Pointer = nil; CheckData: Boolean = false): TTreeNode;

// Возвращает узел деревовидной структуры путь которой указан в Path. Если
// ноды не существует, то они создаются и этим нодам указывается иконка Icn
function ForceNodesByPath(Path: string; Nodes: TTreeNodes; Icn: Integer): TTreeNode;

// Возвращает путь к элементу "Node" (по Caption).
function GetNodePath(Node: TTreeNode): string;

// Возвращает список "детей" детей элемента childOf деревовидной структуры
// Nodes. Результат - список указателей на элементы типа TTreeNode.
// Процедура не очищает перед своей работой список childs, так что если
// Вам нужно - очищайте его самостоятельно.
procedure GetNodeChilds(Nodes: TTreeNodes; childOf: TTreeNode; childs: TList);

// Возвращает указатель на элемент TListItem, заголовок которого - cap.
function GetItemByCaption(Items: TListItems; cap: string; IgnoreCase: Boolean): TListItem; overload;
function GetItemByCaption(Items: TStrings; cap: string; IgnoreCase: Boolean): Integer; overload;

// Возвращает указатель на элемент TListItem, в данных которго хранится dat
//function GetItemByData(Items: TElTreeItems; dat: Pointer): TElTreeItem; overload;
function GetItemByData(Items: TListItems; dat: Pointer): TListItem; overload;
function GetItemByData(Items: TStrings; dat: Pointer): Integer; overload;
function GetItemByData(Items: TTreeNodes; dat: Pointer): TTreeNode; overload;

// Окошку на передний план высовывает
procedure MakeWinForeground(Handle: THandle);

// Удаляет всех парентов указанного элемента, если у них нет ни одного потомка
// кроме указанного.
procedure RemoveParentsTree(del: TTreeNode);

// Снимает выделение с TListView
procedure ClearListViewSelection(ListView: TListView);
procedure StoreListViewSelection(Items: TListItems; var SV: TTreeStore);
procedure RestoreListViewSelection(Items: TListItems; var SV: TTreeStore; posbydata: Boolean = false);

procedure StoreFocusedItem(const List: TStrings; const focused: Integer; var storein: TFocusStore);
function RestoreFocusedItem(const List: TStrings; var storein: TFocusStore): Integer;

// Сохраянет информацию о выделенном элементе
procedure StoreSelTree(tv: TTreeView; var SV: TTreeStore);

// Восстанавливает информацию о выделенном элементе
procedure RestoreSelTree(tv: TTreeView; var SV: TTreeStore);

//============================ Разное ==========================================

// Копирует файл из ресурсов на диск.
procedure CopyFileFromRes(ResName: string; outfile: string);

// Возвращает рабочую область указанного монитора
function GetMonWorkRect(mon: TMonitor): TRect;

// Изменяет указанной форме кординаты на координаты мыши, при этом следя за тем,
// чтобы форма не вылезла за пределы экрана:
procedure WindowPosFromCursor(Form: TCustomForm; AlignTo: TControl = nil);

// Сохраняет/загружает картинки ImageList.
procedure ImageList_ReadData(ImageList: TImageList; Stream: TStream);
procedure ImageList_WriteData(ImageList: TImageList; Stream: TStream);

// Стыкует форму frm с краем экрана.
procedure AlignWindowPos(const frm: TForm);

// Возвращает true, еесли элемент el не встречается в списке list
function CheckForUniq(el: Pointer; list: TList): Integer; overload;
function CheckForUniq(el: Pointer; list: TTreeNodes): Integer; overload;
function CheckForUniq(el: string; list: TStrings): Integer; overload;

// Сохраняет и читает строку из стрима.
// формат записи таков : [длина строки (2 байта)]строка.
procedure SaveStringToStream(St: string; Stream: TStream);
function ReadStringFromStream(Stream: TStream): string;

// Добавляет к дате указанное число лет/месяцев/дней
function DateAdd(Part: TDatePart; Value: Integer; const Date: TDate): TDate;

// Показывает диалог копирайтов после набора слова "ISDEVELOPEDBY".
// Поместите эту функцию в обработчик ApplicationMessages.OnMessage
function CopyrightChecker(var Msg: tagMSG; Prj: string): Boolean;

// Сохраняет позицию окна в ключее реестра, указанном в StoreKey
procedure StoreFormsPosition(Form: TForm);

// Загружает позицию окна в ключее реестра, указанном в StoreKey
procedure RestoreFormsPosition(Form: TForm);

// Посылает сообщение Message всем окнами приложения
procedure SendAppMessage(Msg: Integer; wPar: WPARAM; lPar: LPARAM; SendTo: TClass = nil);

// Возвращает первый выделенный элемент (аналогично TListView.Selected)
function GetSelectedItem(Itm: TListItems): TListItem;

// Делает чтобы хинты показывались даже у инактивных окон.
procedure HackHint;

// Возвращает true, если к указанному краю (ABE_LEFT, ABE_TOP, ABE_BOTTOM, AB_RIGHT)
// указанного монитора  пристыкован любой AppBar. В authide вернется True, если
// этот AppBar имеет атрибут "Auto Hide".
function AppBarExists(const Mon: TMonitor; const edge: Integer; var authide: Boolean): Boolean;

// Эта переменная содержит текст, выводимый функцией CopyrightChecker.
var CprText: string;

  // Путь к ключу реестра текущей программы.
  StoreKey: string;
  StoreRoot: HKEY;

implementation

uses Dialogs, akFileUtils, TypInfo, akStrUtils, Registry, akDataCvt,
  AppUtils, akSysCover, akCOMUtils, ActiveX, CommCtrl, stdctrls, olectrls;



procedure CopyFileFromRes(ResName: string; outfile: string);
var rs: TResourceStream;
begin
  if FileExists(outfile) then
    DeleteFile(PChar(outfile));

  rs := TResourceStream.Create(hInstance, ResName, RT_RCDATA);
  try
    rs.SaveToFile(outfile);
  finally
    rs.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////
// TVCLThread
////////////////////////////////////////////////////////////////////////

constructor TVCLThread.Create(AObject: TObject; APriority: TThreadPriority; Suspended: Boolean);
begin
  Priority := APriority;
  inherited Create(Suspended);
  fObject := AObject;
  FreeOnTerminate := true;
end;

function TVCLThread.GetExceptRaised: boolean;
begin
  Result := fExcept <> nil;
end;

procedure TVCLThread.DoExcept;
begin
  if Assigned(fOnException) then fOnException(Self, Exception(fExcept))
  else
    if fExcept is Exception then begin
      if not (fExcept is EAbort) then
        Application.ShowException(Exception(fExcept));
    end else
      SysUtils.ShowException(fExcept, ExceptAddr);
end;

procedure TVCLThread.Execute;
begin
  try
    SafeExecute;
  except
    fExcept := ExceptObject;
    Synchronize(DoExcept);
  end;
end;


procedure ImageList_WriteData(ImageList: TImageList; Stream: TStream);
var
  SA: TStreamAdapter;
begin
  SA := TStreamAdapter.Create(Stream);
  try
    if not ImageList_Write(ImageList.Handle, SA) then
      raise EWriteError.Create('Failed to write ImageList data to stream');
  finally
    SA.Free;
  end;
end;

procedure ImageList_ReadData(ImageList: TImageList; Stream: TStream);
var
  SA: TStreamAdapter;
begin
  SA := TStreamAdapter.Create(Stream);
  try
    ImageList.Handle := ImageList_Read(SA);
    if ImageList.Handle = 0 then
      raise EReadError.Create('Failed to read ImageList data from stream');
  finally
    SA.Free;
  end;
end;

procedure AlignWindowPos(const frm: TForm);
var topleft: TPoint;
begin
  with frm, topleft do
  begin
    x := Left; y := Top;
    if Width > Monitor.Width then Width := Monitor.Width;
    if Height > Monitor.Height then Height := Monitor.Height;
    if Left < Monitor.Left + 30 then x := Monitor.Left;
    if Top < Monitor.Top + 30 then y := Monitor.Top;
    if Left + Width > Monitor.Left + Monitor.Width - 30 then x := Monitor.Left + Monitor.Width - Width;
    if Top + Height > Monitor.Top + Monitor.Height - 30 then y := Monitor.Top + Monitor.Height - Height;
    SetWindowPos(Handle, 0, x, y, 0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
  end;
end;

procedure MakeLVFullWidth(const ColumnID: Integer; const LV: TListView);
var wh, i: Integer;
begin
  with LV do
  begin
    wh := 0;
    for i := 0 to Columns.Count - 1 do
      if i <> ColumnID then inc(wh, Columns[i].Width);

    Columns[ColumnID].Width := ClientWidth - wh;
  end;
end;

procedure AlignHeaderAndListView(const HC: THeaderControl; const LV: TListView);
var i: Integer;
begin
  for i := 0 to LV.Columns.Count - 1 do
    HC.Sections[i].Width := LV.Columns[i].Width;
end;

function AppBarExists(const Mon: TMonitor; const edge: Integer; var authide: Boolean): Boolean;
var
  mi: TMonitorInfo;
  apd: TAppBarData;
  hndl: THandle;
  vis: Boolean;
  toolmon: HMONITOR;
begin
  mi.cbSize := SizeOf(TMonitorInfo);
  MultiMon.GetMonitorInfo(Mon.Handle, @mi);

  apd.cbSize := SizeOf(TAppBarData);
  apd.uEdge := edge;
  apd.hWnd := 0;
  toolmon := 0;
  hndl := SHAppBarMessage(ABM_GETAUTOHIDEBAR, apd);
  if hndl <> 0 then
    toolmon := MultiMon.MonitorFromWindow(hndl, MONITOR_DEFAULTTONULL);


  AutHide := (hndl <> 0) and (toolmon = Mon.Handle); vis := false;
  case edge of
    ABE_BOTTOM: vis := mi.rcWork.Bottom <> Mon.Top + Mon.Height;
    ABE_TOP: vis := mi.rcWork.Top <> Mon.Top;
    ABE_LEFT: vis := mi.rcWork.Left <> Mon.Left;
    ABE_RIGHT: vis := mi.rcWork.Right <> Mon.Left + Mon.Width;
  end;

  Result := (AutHide or vis);
end;


procedure StoreFocusedItem(const List: TStrings; const focused: Integer; var storein: TFocusStore);
begin
  with storein do
  begin
    Data := nil;
    Itm := focused;
    if (focused >= 0) and (focused <= List.Count - 1) then
      Data := List.Objects[focused]
    else
      Data := nil;
  end;
end;

function RestoreFocusedItem(const List: TStrings; var storein: TFocusStore): Integer;
begin
  with storein do
  begin
    Result := -1;
    if Assigned(Data) then
      Result := GetItemByData(List, Data);

    if Result = -1 then
      if (itm >= 0) and (itm <= List.Count - 1) then
        Result := Itm;
  end;
end;


procedure RemoveParentsTree(del: TTreeNode);
var nd: TTreeNode;
begin
  if not Assigned(del) then exit;

  nd := del;
  while true do
  begin
    if Assigned(nd.Parent) and (nd.Parent.Count = 1) then
      nd := nd.Parent
    else
      Break;
  end;

  nd.Delete;
end;

procedure HackHint;
var P: Pointer;
  OldVal: DWORD;
begin
  P := @Forms.ForegroundTask;
  if VirtualProtect(P, 16, PAGE_READWRITE, @OldVal) then
  begin
    asm
      mov  eax, P
      mov  dword ptr [eax], $00C301B0
    end;
    VirtualProtect(P, 16, OldVal, @OldVal);
  end;
end;

function GetSelectedItem(Itm: TListItems): TListItem;
var i: Integer;
begin
  Result := nil;
  for i := 0 to Itm.Count - 1 do
    if Itm[i].Selected then
    begin
      Result := Itm[i];
      Break;
    end;
end;

procedure SendAppMessage(Msg: Integer; wPar: WPARAM; lPar: LPARAM; SendTo: TClass);
var i, m: Integer;
  fm: TForm;
  fr: TFrame;
  q: Integer;
begin
  for i := 0 to Screen.FormCount - 1 do
  begin
    fm := Screen.Forms[i];
    PostMessage(fm.Handle, Msg, wPar, lPar);
//      fm.Perform(Msg, wPar, lPar);
    if Assigned(SendTo) then
    begin
      for m := 0 to fm.ComponentCount - 1 do
      begin
        if (fm.Components[m].ClassType = SendTo) then
          PostMessage(TWinControl(fm.Components[m]).Handle, Msg, wPar, lPar);
                //TWinControl(fm.Components[m]).Perform(Msg, wPar, lPar);
        if (fm.Components[m].ClassParent = TFrame) then
        begin
          fr := TFrame(fm.Components[m]);
          for q := 0 to fr.ComponentCount - 1 do
            if (fr.Components[q].ClassType = SendTo) then
              PostMessage(TWinControl(fr.Components[q]).Handle, Msg, wPar, lPar);
                      //TWinControl(fr.Components[q]).Perform(Msg, wPar, lPar);
        end;
      end;
    end;
  end;
end;

procedure ClearListViewSelection(ListView: TListView);
var i: Integer;
begin
  for i := 0 to ListView.Items.Count - 1 do
    ListView.Items[i].Selected := false;
end;

procedure EnableStateByTag(cTag: Integer; cEnable: Boolean; ForObj: TWinControl);
var i: Integer;
begin
  with ForObj do
    for i := 0 to ComponentCount - 1 do
      if (Components[i].Tag = cTag) {or ((Components[i].GetParentComponent <> nil) and
        (Components[i].GetParentComponent.Tag = cTag))}then begin
        TWinControl(Components[i]).Enabled := cEnable;
      end;
//  Application.ProcessMessages;
end;

procedure VisibleStateByTag(cTag: Integer; cEnable: Boolean; ForObj: TWinControl);
var i: Integer;
begin
  with ForObj do
    for i := 0 to ComponentCount - 1 do
      if Components[i].Tag = cTag then
        TWinControl(Components[i]).Visible := cEnable;
end;

procedure SaveStringToStream(St: string; Stream: TStream);
var len: Word;
  leng, dlen: DWORD;
begin
  with Stream do
    if Length(st) > (High(Word) - 1) then
    begin
      len := High(Word);
      WriteBuffer(len, SizeOf(Word)); // если длина строки больше 65k, то
      dlen := Length(st); // пишем первыми двумя байтами $FFFF, а
      WriteBuffer(dlen, SizeOf(DWORD)); // следующими четыеремя - длину
    end else begin
      len := Length(St);
      WriteBuffer(len, SizeOf(len));
    end;

  leng := Length(st);
  if leng <> 0 then
    Stream.WriteBuffer(St[1], leng);
end;

function ReadStringFromStream(Stream: TStream): string;
var len: Word;
  leng, dlen: DWORD;
begin
  Stream.ReadBuffer(len, SizeOf(len));

  with Stream do
    if len = High(Word) then
    begin
      ReadBuffer(dlen, SizeOf(DWORD));
      leng := dlen;
    end else
      leng := len;

  SetLength(Result, leng);
  Stream.ReadBuffer(Result[1], leng);
end;


procedure UpdateHint;
var gp: TPoint;
  tm: Integer;
begin
  tm := Application.HintPause;
  try
    Application.HintPause := 0;
    GetCursorPos(gp);
    SetCursorPos(-10000, -10000);
    SetCursorPos(gp.x, gp.y);
  finally
    Application.ProcessMessages;
    Application.HintPause := tm;
  end;
end;

function GetNodeFrom(obj, childOf: TTreeNode): TTreeNode;
var ct, prevct: TTreeNode;
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

function CopyrightChecker(var Msg: tagMSG; Prj: string): Boolean;
const Copyr: string = 'ISDEVELOPEDBY';
  Ps: Integer = 1;
var Key: Char;
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

function GetNodeByPath(Path: string; Nodes: TTreeNodes; Data: Pointer = nil; CheckData: Boolean = false): TTreeNode;
var nd, i: Integer;
  seg: string;
  prevNd: TTreeNode;
  SegOk: Integer;
begin
  Result := nil;
  prevNd := nil;
  SegOk := 0;
  for i := 0 to MaxInt do
  begin
    seg := GetLeftSegment(i, Path, '\');
    if seg <> '\' then // Если путь пропарсен еще не весь
    begin
      for nd := 0 to Nodes.Count - 1 do
        if nodes[nd].Parent = prevNd then
          if AnsiCompareText(nodes[nd].Text, seg) = 0 then
          begin
            if GetLeftSegment(i + 1, Path, '\') = '\' then
              if not ((CheckData and (Nodes[nd].Data = Data)) or (not CheckData)) then
                continue;
            prevNd := nodes[nd];
            inc(SegOk);
            Break;
          end;
    end
    else // Если путь полностью пропарсен
    begin
      if (i = SegOk) then Result := PrevNd;
      Break;
    end;
  end;
end;

procedure GetNodeChilds(Nodes: TTreeNodes; childOf: TTreeNode; childs: TList);
var i: Integer;
begin
  for i := 0 to Nodes.Count - 1 do
  begin
    if Nodes[i].Parent = childOf then
    begin
      childs.Add(Nodes[i]);
      GetNodeChilds(Nodes, Nodes[i], childs);
    end;
  end;
end;

function GetItemByCaption(Items: TListItems; cap: string; IgnoreCase: Boolean): TListItem;
var i: Integer;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
    if ((IgnoreCase) and (AnsiCompareText(cap, Items[i].Caption) = 0)) or
      (not IgnoreCase) and (cap = Items[i].Caption) then
    begin
      Result := Items[i];
      Break;
    end;
end;

function GetItemByCaption(Items: TStrings; cap: string; IgnoreCase: Boolean): Integer; overload;
var i: Integer;
begin
  Result := -1;
  for i := 0 to Items.Count - 1 do
    if ((IgnoreCase) and (AnsiCompareText(cap, Items[i]) = 0)) or
      (not IgnoreCase) and (cap = Items[i]) then
    begin
      Result := i;
      Break;
    end;
end;

function GetNodePath(Node: TTreeNode): string;
var nd: TTreeNode;
  ch: string;
begin
  Result := '';
  nd := Node;
  if Assigned(nd) then
    repeat
      if nd.Parent <> nil then
        Ch := '\'
      else
        ch := '';
      Result := ch + nd.Text + Result;
      nd := nd.Parent;
    until nd = nil;
end;

function DateAdd(Part: TDatePart; Value: Integer; const Date: TDate): TDate;
var
  Day, Month, Year: Word;
  MaxDays, NewDay, NewMonth, NewYear: Integer;
begin
  if Part = dpDay then
  begin
    Result := Date + Value;
    Exit;
  end;
  DecodeDate(Date, Year, Month, Day);
  NewDay := Day;
  NewMonth := Month;
  NewYear := Year;
  case Part of
    dpMonth: NewMonth := Month + Value;
    dpYear: NewYear := Year + Value;
  end;
  if NewMonth > 12 then
  begin
    Inc(NewYear, NewMonth div 12);
    NewMonth := NewMonth mod 12;
  end;
  if NewMonth <= 0 then
  begin
    Inc(NewYear, (NewMonth div 12) - 1);
    NewMonth := 12 + NewMonth mod 12;
  end;
  MaxDays := DaysInMonth(NewMonth, NewYear);
  if NewDay > MaxDays then
    NewDay := MaxDays;
  Result := EncodeDate(NewYear, NewMonth, NewDay);
end;


function CheckForUniq(el: Pointer; list: TList): Integer; overload;
begin
  Result := list.IndexOf(el);
end;

function CheckForUniq(el: Pointer; list: TTreeNodes): Integer; overload;
var i: Integer;
begin
  Result := -1;
  for i := 0 to list.Count - 1 do
    if list[i].Data = el then
    begin
      Result := i;
      break;
    end;
end;

function CheckForUniq(el: string; list: TStrings): Integer; overload;
begin
  Result := list.IndexOf(el);
end;

procedure StoreSelTree(tv: TTreeView; var SV: TTreeStore);
var i, cnt: Integer;
  id: TTreeNode;
begin
  tv.Items.BeginUpdate;
//  tv.DoubleBuffered := True;

  id := tv.TopItem;
  if Assigned(id) then
    sv.TopInd := id.AbsoluteIndex
  else
    sv.TopInd := -1;

  SetLength(sv.Expands, tv.Items.Count);
  cnt := 0;
  for i := 0 to tv.Items.Count - 1 do
  begin
    if tv.Items[i].Expanded then
    begin
      sv.Expands[cnt] := GetNodePath(tv.Items[i]);
      inc(cnt);
    end;
  end;
  SetLength(sv.Expands, cnt);

  if Assigned(tv.Selected) then
  begin
    sv.Path := GetNodePath(tv.Selected);
    sv.Data := tv.Selected.Data;
  end
  else
    sv.Path := '';
end;

procedure RestoreSelTree(tv: TTreeView; var SV: TTreeStore);
var nd: TTreeNode;
  i: Integer;
begin
  try
    for i := 0 to Length(sv.Expands) - 1 do
    begin
      nd := GetNodeByPath(sv.Expands[i], tv.Items);
      if Assigned(nd) then
        nd.Expand(false);
    end;

    if sv.Path <> '' then
    begin
      nd := GetNodeByPath(sv.Path, tv.Items {, sv.Data, true});
      if Assigned(nd) then
      begin
        if (sv.TopInd >= 0) and (sv.TopInd <= tv.Items.Count - 1) then
          tv.TopItem := tv.Items[sv.TopInd];
        nd.Selected := true;
        tv.Selected.MakeVisible;
      end;
    end;
  finally
    tv.Items.EndUpdate;
//    tv.DoubleBuffered := False;
  end;
end;

procedure StoreListViewSelection(Items: TListItems; var SV: TTreeStore);
var i, cnt: Integer;
  id: TListItem;
  fc: Integer;
begin
  Items.BeginUpdate;
  try
    id := nil;
    for fc := 0 to Items.Count - 1 do
      if Items[fc].Focused then
      begin id := Items[fc]; break; end;

    if Assigned(id) then
    begin
      sv.ItmIndex := id.Index;
      sv.Data := id.Data;
    end
    else
    begin
      sv.ItmIndex := -1;
      sv.Data := nil;
    end;

  // Сохраняем заголовки выделенных элементов.
    SetLength(sv.Expands, Items.Count);
    cnt := 0;
    for i := 0 to Items.Count - 1 do
    begin
      if Items[i].Selected then
      begin
        sv.Expands[cnt] := Items[i].Caption;
        inc(cnt);
      end;
    end;
    SetLength(sv.Expands, cnt);
  finally
    Items.EndUpdate;
  end;
end;


procedure RestoreListViewSelection(Items: TListItems; var SV: TTreeStore; posbydata: Boolean);
var nd: TListItem;
  i, ind: Integer;
begin
  Items.BeginUpdate;
  try
    nd := nil;
    for i := 0 to Length(sv.Expands) - 1 do
    begin
      if posByData then
        nd := GetItemByData(Items, sv.Data)
      else
        nd := GetItemByCaption(Items, sv.Expands[i], false);
      if Assigned(nd) then
        nd.Selected := true;
    end;

    ind := sv.ItmIndex;
    if ind > Items.Count - 1 then ind := Items.Count - 1;
    if (nd = nil) and (ind >= 0) then nd := Items[ind];

    if Assigned(nd) then
      nd.Focused := true;

    if Assigned(nd) then
      nd.MakeVisible(false);

  finally
    Items.EndUpdate;
  end;
end;

{function GetItemByData(Items: TElTreeItems; dat: Pointer): TElTreeItem;
var i: Integer;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
    if Items[i].Data = dat then
    begin
      Result := Items[i];
      break;
    end;
end;}

function GetItemByData(Items: TListItems; dat: Pointer): TListItem;
var i: Integer;
begin
  Result := nil;
  Items.BeginUpdate;
  try
    for i := 0 to Items.Count - 1 do
      if Items[i].Data = dat then
      begin
        Result := Items[i];
        break;
      end;
  finally
    Items.EndUpdate;
  end;
end;

function GetItemByData(Items: TTreeNodes; dat: Pointer): TTreeNode;
var i: Integer;
begin
  Result := nil;
  Items.BeginUpdate;
  try
    for i := 0 to Items.Count - 1 do
      if Items[i].Data = dat then
      begin
        Result := Items[i];
        break;
      end;
  finally
    Items.EndUpdate;
  end;
end;

function GetItemByData(Items: TStrings; dat: Pointer): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to Items.Count - 1 do
    if Items.Objects[i] = dat then
    begin
      Result := i;
      break;
    end;
end;


//******************************************************************************
//==============================================================================
// TLanguageLoader
//==============================================================================
//******************************************************************************

constructor TLanguageLoader.Create;
begin
  FIni := nil; fEngLanguage := nil;
  FSectionComp := nil;
  FReplaceFrom := '';
  FReplaceWith := '';
  inherited;
end;

destructor TLanguageLoader.Destroy;
begin
  if Assigned(fIni) then SafeFreeAndNil(fIni);
  inherited;
end;

function TLanguageLoader.GetCaption(Name: string): string;
begin
  if not Assigned(FSectionComp) then
    Result := '-error-'
  else
  begin
    Result := GetVariable(Copy(FSectionComp.Name, 1, maxint), Name);
  end;
end;

function TLanguageLoader.GetVariable(VarSec, Name: string; loaddefault: Boolean): string;
var wname, nm: string;
  _varSec, _varName: string;
begin
  wname := StringReplace(Name, '_', '.', [rfReplaceAll]);

  if Copy(wname, 1, 1) = '.' then begin
    // .demo = .global.demo
    // .mysec.demo = .mysec.demo
    nm := GetLeftSegment(2, wname, '.');
    if nm = '.' then nm := '.global' + wname else nm := wname;

    _varSec := GetLeftSegment(1, nm, '.');
    _varName := GetLeftSegment(2, nm, '.');
  end else begin
    _varSec := varSec;
    _varName := wname;
  end;

  if Assigned(FIni) then
    Result := StringReplace(fIni.ReadString(_VarSec, _varName, 'no-value'),
      '\n', #13#10, [rfReplaceAll])
  else
    Result := 'no-value';

  if (loaddefault) and Assigned(fEngLanguage) and (Result = 'no-value') then
    Result := fEngLanguage.GetVariable(VarSec, Name);

  if (ReplaceFrom<>'') then
    Result := StringReplace(Result, ReplaceFrom, ReplaceWith, [rfReplaceAll]);

end;

procedure TLanguageLoader.LoadFromFile(Component: TComponent; LangFileName: string);
begin
  if Assigned(fIni) then SafeFreeAndNil(fIni);

  FIni := TBigIniFile.Create(LangFileName);
  if Assigned(Component) then
    with FIni do begin
      FSectionComp := Component;
      LoadStringProperties(Component);
    end;
end;

procedure TLanguageLoader.LoadStringProperties(Component: TComponent);
var
  Count, I: Integer;
  Info: PTypeInfo;
  Data: PTypeData;
  Inf: PPropInfo;
  PropList: PPropList;
  Str: string;
  lst: TStrings;
  lvc: TListColumns;
  lvh: THeaderSections;
begin
  if (not Assigned(FSectionComp)) or (not Assigned(FIni)) then exit;

  if (Component is TOleControl) then
    exit;

  with Component do
    if (ClassType = TListBox) or (ClassType = TComboBox) then begin
      if ClassType = TListBox then
        lst := TListBox(Component).Items
      else
        lst := TComboBox(Component).Items;

      lst.BeginUpdate;
      try
        for i := 0 to lst.Count - 1 do begin
          Str := lst[i];
          if Copy(str, 1, 1) = '[' then
            lst[i] := GetCaption(Copy(str, 2, Length(str) - 2));
        end;
      finally
        lst.EndUpdate;
      end;
    end;

  with Component do begin
    if (ClassParent = TListView) or (ClassType = TListView) then begin
      lvc := TListView(Component).Columns;
      lvc.BeginUpdate;
      try
        for i := 0 to lvc.Count - 1 do begin
          Str := lvc[i].Caption;
          if Copy(str, 1, 1) = '[' then
            lvc[i].Caption := GetCaption(Copy(str, 2, Length(str) - 2));
        end;
      finally
        lvc.EndUpdate;
      end;
    end;

    if (ClassParent = THeaderControl) or (ClassType = THeaderControl) then begin
      lvh := THeaderControl(Component).Sections;
      lvh.BeginUpdate;
      try
        for i := 0 to lvh.Count - 1 do begin
          Str := lvh[i].Text;
          if Copy(str, 1, 1) = '[' then
            lvh[i].Text := GetCaption(Copy(str, 2, Length(str) - 2));
        end;
      finally
        lvh.EndUpdate;
      end;
    end;
  end;

  Info := Component.ClassInfo;
  Data := GetTypeData(Info);

  { Allocate memory to hold the property information. }
  GetMem(PropList, Data^.PropCount * SizeOf(PPropInfo));
  try
    Count := GetPropList(Info, [tkString, tkLString, tkWString], PropList);

     { Если эта проперть Name'ой зовется и имя начинается с "_" - то это имя ресyрса }
    if (Copy(Component.Name, 1, 1) = '_') then begin
      Inf := GetPropInfo(Info, 'Caption', [tkString, tkLString, tkWString]);
      if Assigned(Inf) then begin
        Str := GetCaption(Copy(Component.Name, 2, MaxInt));
        SetStrProp(Component, Inf, Str);
      end;
    end else begin

      for I := 0 to Count - 1 do
      begin
        { get the string property value }
        Str := GetStrProp(Component, PropList[I]);

        { Если значение проперти началось с "[" - то это имя ресyрса,
         иначе просто значение проперти}
        if (Length(Str) > 1) and (Str[1] = '[') then
        begin
            { Загрyжаем значение}
          Str := GetCaption(Copy(Str, 2, Length(Str) - 2));
          if Str <> '' then
              {Если оное есть то yстанавливаем его  }
            SetStrProp(Component, PropList[I], Str);
        end;
      end;
    end;

  finally
    FreeMem(PropList, Data^.PropCount * SizeOf(PPropInfo));
  end;
  {Загрyжаем для всех "детей" компонента рекyрсией }
  for I := 0 to Component.ComponentCount - 1 do
    LoadStringProperties(Component.Components[I]);
end;


// Сохраняет позицию окна в ключее реестра, указанном в StoreKey

procedure StoreFormsPosition(Form: TForm);
var rg: TRegIniFile;
begin
  rg := TRegIniFile.Create;
  with rg do
  try
    RootKey := StoreRoot;
    WriteFormPlacementReg(Form, rg, GetDirectory(StoreKey) + 'Forms\' + Form.Name);
  finally
    Free;
  end;
end;

// Загружает позицию окна в ключее реестра, указанном в StoreKey

procedure RestoreFormsPosition(Form: TForm);
var rg: TRegIniFile;
begin
  rg := TRegIniFile.Create;
  with rg do
  try
    RootKey := StoreRoot;
    ReadFormPlacementReg(Form, rg, GetDirectory(StoreKey) + 'Forms\' + Form.Name, true, true);
//    if Form.WindowState = wsMaximized then ShowWindow(Form.Handle, SW_MAXIMIZE);
  finally
    Free;
  end;
end;

// Make Foreground window

procedure MakeWinForeground(Handle: THandle);
begin
  StoreAnimation;
  try
    EnableAnimation(false);
    Application.Minimize;
    Application.Restore;
  finally
    RestoreAnimation;
  end;
end;

function ForceNodesByPath(Path: string; Nodes: TTreeNodes; Icn: Integer): TTreeNode;
var i: Integer;
  st, pth: string;
  nd: TTreeNode;
  prev: TTreeNode;
begin
  pth := ''; prev := nil; nd := nil;
  for i := 0 to MaxInt do
  begin
    st := GetLeftSegment(i, Path, '\');
    if st = '\' then break;

    if pth <> '' then pth := pth + '\';
    pth := pth + st;
    nd := GetNodeByPath(pth, Nodes);

    if not Assigned(nd) then
    begin
      nd := Nodes.AddChild(prev, st);
      nd.ImageIndex := Icn;
      nd.SelectedIndex := Icn;
    end;
    prev := nd;
  end;
  Result := nd;
end;

function TRefresher.AllreadyRequested(proc: TRefresherProc): Boolean;
begin
  Result := IndexOf(proc) <> -1;
end;

procedure TRefresher.CancelRequests;
begin
  fProcs.Clear;
end;

constructor TRefresher.Create;
begin
  fProcs := TCollection.Create(TRefresherRec);
  fMsgWin := TRefMsgWindow.Create(Self);
  fMsgWin.ParentWindow := GetDesktopWindow;
end;

destructor TRefresher.Destroy;
begin
  fMsgWin.Free;
  fProcs.Free;
  inherited;
end;

function TRefresher.IndexOf(proc: TRefresherProc): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to fProcs.Count - 1 do
    if Addr(TRefresherRec(fProcs.Items[i]).Proc) = @proc then
    begin
      Result := i;
      Break;
    end;
end;

procedure TRefresher.Request(proc: TRefresherProc; const lpar: DWORD; const rpar: DWORD);
var wnd: THandle;
  al: TRefresherRec;
begin
  if not AllreadyRequested(proc) then
  begin
    al := TRefresherRec(fProcs.Add);
    al.Proc := @proc;
    al.lpar := lpar;
    al.rpar := rpar;
    wnd := fMsgWin.Handle;
    PostMessage(wnd, WM_REQUESTUPDATE, 0, 0);
  end;
end;

{ TMsgWindow }

constructor TRefMsgWindow.Create(const rfr: TRefresher);
begin
  inherited Create(nil);
  fRFR := rfr;
  fRun := false;
  Visible := False;
end;

procedure TRefMsgWindow.WMREQUESTUPDATE(var msg: TMessage);
var rr: TRefresherRec;
begin
  if fRun then exit;

  fRun := True;
  try
    if not Assigned(fRFR) then exit;
    with fRFR do
      while ProcsList.Count > 0 do
      begin
        rr := TRefresherRec(ProcsList.Items[0]);
        rr.Proc(rr.lpar, rr.rpar);
        ProcsList.Delete(0);
      end;
  finally
    fRun := False;
  end;
end;

function GetMonWorkRect(mon: TMonitor): TRect;
var
  MonInfo: TMonitorInfo;
begin
  MonInfo.cbSize := SizeOf(MonInfo);
  GetMonitorInfo(mon.Handle, @MonInfo);
  Result := MonInfo.rcWork;
end;

procedure WindowPosFromCursor(Form: TCustomForm; AlignTo: TControl);
var 
  ps: TPoint;
  l, t: Integer;
  rec: TRect;
  mon: TMonitor;
begin
  ps := Mouse.CursorPos;
  with Form do begin
    if Assigned(AlignTo) then begin
      rec := AlignTo.BoundsRect;
      if Assigned(AlignTo.Parent) then begin
        rec.TopLeft := AlignTo.ClientToScreen(rec.TopLeft);
        rec.BottomRight := AlignTo.ClientToScreen(rec.BottomRight);
      end;

      if not PtInRect(rec, ps) then begin
        ps.x := rec.Left + Round(AlignTo.Width / 2);
        ps.y := rec.Top + Round(AlignTo.Height / 2);
      end;
    end;

    L := ps.x - Round(Width / 2);
    T := ps.y - Round(Height / 2);

    if Assigned(Application.MainForm) then begin
      mon := Application.MainForm.Monitor;
      rec := GetMonWorkRect(mon);

      if L < rec.Left then L := rec.Left + 5;
      if T < rec.Top then T := rec.Top + 5;
      if L + Width > rec.Right then
        L := rec.Right - Width - 5;
      if T + Height > rec.Bottom then
        T := rec.Bottom - Height - 5;
{

      if L < Mon.Left then L := Mon.Left + 5;
      if T < Mon.Top then T := Mon.Top + 5;
      if L + Width > Mon.Left + Mon.Width then
        L := Mon.Left + Mon.Width - Width - 5;
      if T + Height > Mon.Top + Mon.Height then
        T := Mon.Top + Mon.Height - Height - 5;}
    end;

    Left := L;
    Top := T;
  end;
end;


procedure TVCLThread.Synchronize(Method: TThreadMethod);
begin
  inherited Synchronize(Method);
end;

initialization
  StoreKey := 'none';
  StoreRoot := HKEY_CURRENT_USER;
  CprText := 'Александр Крамаренко'#10 +
    '(GroupStudio@mail.ru, 2:5019/10.99@fidonet)'#10 +
    'Смоленск, Россия, 2000г'#10#10 +
    '"ISDEVELOPEDBY" - ключевое слово для отображения этого окна.';
end.

