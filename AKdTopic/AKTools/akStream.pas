unit akStream;

interface

uses Classes;

type
  // =============================================================================
  // Ёлемент коллекции, поддерживающий сохранение/чтение разных версий
  TVersionedCollectionItem = class(TCollectionItem)
  private
    fSecVersion: WORD;
  protected
    property SecVersion: WORD read fSecVersion write fSecVersion;
  public
    procedure SaveToStreamVer(Stream: TStream; const ver:Integer); virtual; abstract;
    procedure LoadFromStreamVer(Stream: TStream; const ver:Integer); virtual; abstract;

    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Clear; virtual; abstract;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SaveToStream(Stream: TStream); virtual;
  end;

  TVersionedCollectionItemClass = class of TVersionedCollectionItem;

  // =============================================================================
  // Rоллекциz, поддерживающа€ сохранение/чтение разных версий
  TVersionedCollection = class(TCollection)
  private
    fSecVersion: WORD;
  protected
    property SecVersion: WORD read fSecVersion write fSecVersion;
  public
    procedure SaveToStreamVer(Stream: TStream; const ver:Integer); virtual; abstract;
    procedure LoadFromStreamVer(Stream: TStream; const ver:Integer); virtual; abstract;

    constructor Create(ItemClass: TVersionedCollectionItemClass);
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);
  end;

  // =============================================================================
  // »змененный TCollectionItem : умеет сохран€ть ссылки с элемента на элемент
  // с помощью GUID'ов и восстанавливать их :
  TSafeCollectionItem = class(TCollectionItem)
  private
    fParentGUID: TGUID;
    fGUID: TGUID;
    fParentPtr: TSafeCollectionItem; // содержит указатель на Parent, если PtrValid
    fParentPtrValid: Boolean;

    procedure AssignGUID;
    procedure SetParent(const Value: TSafeCollectionItem);
    function GetParent: TSafeCollectionItem;
  protected
    property GUID: TGUID read fGUID;
    property ParentGUID: TGUID read fParentGUID;
    procedure Clear; virtual;

    // —охран€ет/загружает информацию о парентах из стрима
    procedure SaveToStream(stream: TStream); virtual;
    procedure LoadFromStream(stream: TStream); virtual;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    // —брасывает информацию о всех пр€мых ссылках на элементы парент-элементы.
    // —ледует сбрасывать при любых операци€х, измен€ющих структуру иерархии.
    procedure ClearPointers;

    // Interface
    property Parent: TSafeCollectionItem read GetParent write SetParent;
  end;

// —охран€ет и читает строку из стрима.
// формат записи таков : [длина строки (2 байта)]строка.
procedure SaveStringToStream(St: string; Stream: TStream);
function ReadStringFromStream(Stream: TStream): string;


implementation

uses akComUtils, ActiveX, Windows;

procedure SaveStringToStream(St: string; Stream: TStream);
var len: Word;
  leng, dlen: DWORD;
begin
  with Stream do
    if Length(st) > (High(Word) - 1) then
    begin
      len := High(Word);
      WriteBuffer(len, SizeOf(Word)); // если длина строки больше 65k, то
      dlen := Length(st); // пишем первыми двум€ байтами $FFFF, а
      WriteBuffer(dlen, SizeOf(DWORD)); // следующими четыерем€ - длину
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


{ TVersionedCollectionItem }

constructor TVersionedCollectionItem.Create(Collection: TCollection);
begin
  inherited;
end;

destructor TVersionedCollectionItem.Destroy;
begin
  inherited;
end;

procedure TVersionedCollectionItem.LoadFromStream(Stream: TStream);
begin
  Clear;
  with Stream do
  begin
    ReadBuffer(fSecVersion, SizeOf(fSecVersion));
    LoadFromStreamVer(stream, fSecVersion);
  end;
end;

procedure TVersionedCollectionItem.SaveToStream(Stream: TStream);
begin
  with Stream do
  begin
    WriteBuffer(fSecVersion, SizeOf(fSecVersion));
    SaveToStreamVer(stream, fSecVersion);
  end;
end;


{ TVersionedCollection }

procedure TVersionedCollection.Clear;
var i : Integer;
begin
  for i := 0 to Count-1 do begin
    TVersionedCollectionItem(Items[i]).Clear;
  end;
end;

constructor TVersionedCollection.Create(ItemClass: TVersionedCollectionItemClass);
begin
  inherited Create(ItemClass);
  Clear;
end;

destructor TVersionedCollection.Destroy;
begin
  inherited;
end;

procedure TVersionedCollection.LoadFromStream(Stream: TStream);
var i : Integer;
begin
  Clear;
  with Stream do
  begin
    ReadBuffer(fSecVersion, SizeOf(fSecVersion));
    LoadFromStreamVer(Stream, fSecVersion);
    for i := 0 to Count-1 do
      TVersionedCollectionItem(Items[i]).LoadFromStreamVer(Stream, fSecVersion);
  end;
end;

procedure TVersionedCollection.SaveToStream(Stream: TStream);
var i : Integer;
begin
  with Stream do
  begin
    WriteBuffer(fSecVersion, SizeOf(fSecVersion));
    SaveToStreamVer(Stream, fSecVersion);
    for i := 0 to Count-1 do
      TVersionedCollectionItem(Items[i]).SaveToStreamVer(Stream, fSecVersion);
  end;
end;

{ TSafeCollectionItem }

procedure TSafeCollectionItem.AssignGUID;
begin
  if IsGUIDEmpty(fGUID) then
    CoCreateGUID(fGUID);
end;

procedure TSafeCollectionItem.Clear;
begin
  EmptyGUID(fParentGUID);
  EmptyGUID(fGUID);
  ClearPointers;
  AssignGUID;
end;

procedure TSafeCollectionItem.ClearPointers;
begin
  fParentPtrValid := false;
  fParentPtr := nil;
end;

constructor TSafeCollectionItem.Create(Collection: TCollection);
begin
  inherited;
  Clear;
end;

destructor TSafeCollectionItem.Destroy;
begin
  inherited;
end;

function TSafeCollectionItem.GetParent: TSafeCollectionItem;
var i: Integer;
  ti: TSafeCollectionItem;
begin
  if fParentPtrValid then
    Result := fParentPtr
  else
  begin
    Result := nil;
    fParentPtrValid := true;
    for i := 0 to  Collection.Count - 1 do
    begin
      ti := TSafeCollectionItem(Collection.Items[i]);
      if IsEqualGUID(ParentGUID,  ti.GUID) then
      begin
        fParentPtr := ti;
        Result := ti;
        Break;
      end;
    end;
  end;
end;

procedure TSafeCollectionItem.LoadFromStream(stream: TStream);
begin
  Stream.ReadBuffer(fGUID, SizeOf(fGUID));
  Stream.ReadBuffer(fParentGUID, SizeOf(fParentGUID));
  ClearPointers;
end;

procedure TSafeCollectionItem.SaveToStream(stream: TStream);
begin
  Stream.WriteBuffer(fGUID, SizeOf(fGUID));
  Stream.WriteBuffer(fParentGUID, SizeOf(fParentGUID));
end;

procedure TSafeCollectionItem.SetParent(const Value: TSafeCollectionItem);
begin
  Value.AssignGUID;
  fParentGUID := Value.GUID;
  ClearPointers;
end;


end.

