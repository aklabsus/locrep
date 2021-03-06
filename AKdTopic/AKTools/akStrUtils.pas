// AKTools.  akStrUtils unit.
//           ������, ���������� ������� �� ������ �� ��������.
//=============================================================================
unit akStrUtils;

interface

uses Classes, SysUtils, Windows;

type
  TChars = set of char;
  ECryptError = class(Exception);

// *********************** ������ �� �������� **********************************

// ��������� � ������ Org ������ add. �������� ������� org := org + add;
procedure FastAddString(var Org: string; add: string);

 // ���������� ������� � ���������� ������� N (������ � ����),
 // ���� �������� � ������� N ���, �� ������� ������ SegSep.
 //  ��������, ���� Str = "tos\pax\file\dir\sux\sux.htm", SegSep = "\", �
 //  N = 2, �� ���������� ����� ������ "sux".
function GetRightSegment(N: Integer; Str: string; SegSep: Char): string;
function GetLeftSegment(N: Integer; Str: string; SegSep: Char): string;

 // �������� ������ Str
function CryptString(Str: string): string;

 // ��������� ������������ ������ Str
function UnCryptString(Str: string): string;

 // ���������, ��� � ������ ��� �������� � ����� ������ #127
function IsLat(Str: string): boolean;

 // ����������� OEM->ANSI
function StrOEMToANSI(St: string): string;

 // ����������� ANSI->OEM
function StrANSItoOEM(St: string): string;

 // ���������� ������, ����������� �� ������
procedure GetStrWords(St: string; List: TStringList; latonly: boolean = true);

 // ���������� true, ���� �����, ������������� ����� ������
 // � Words ��������� � ������ St, ������ ���������� �����
 // ���� �� ����� 10 �������� (������������ ��� ������ �� �����)
function WordsIsNear(St: string; Words: string): boolean;

 // ���������, ��� ��� �����, ������������� ����� ������ � Words ����������
 // � ������ St.
function WordsIn(St: string; Words: string): boolean;

 // ������� ��������� ������� �� ������
function TrimIn(St: string; rchars: TChars): string;

 // ����������� ����� � ������, ����� �������� �� ���� ���� �������� #13, #10,
 // #9 (���� ���������� ��������� "������").
function TextToLine(St: string): string;

 // ���������� �������� �����, ���������� � Name
function GetNameLT(Name: string): string;

 // ���������� ������� ������� �������, ��������� �� Ch.
 // � StartFrom ����������� � ������ ������� �������� ��������
 // ���� ������� � ����� �������� �� ch �� �������, �� ������������ 0.
function NotCharPos(St: string; ch: Char; StartFrom: Integer = 1): Integer;

 // ���������� ������, � ������� ��� ������� c1 �������� ��
 // c2. (�������� ����� ������� StringReplace)
function ReplaceChar(st: string; c1, c2: char): string;

 // ��������� ������ �� ���������, ����� ������ �� �������
 // �� ��������� len ��������. �������� ������������ ������
 // �� ������ ����, ������ ���� ����� ������� �������, �� ���
 // ���������� "��� ����". ������ ���������� ���� �� �����
 // ������������������� �������� #13#10. first � next ���������
 // ������� � ������ ���� � ������ � ��������� �������.
function WordWrapStr(st: string; len: Integer; first: Integer = 0; next: Integer = 0): string;

 // ���������� ������� N�� (������� � ����) ��������� SubStr � ������ S
 // ���� ������� �� ����������, �� �������� 0. (�������� ���� ������ ������)
function PosR(Substr: string; S: string; N: Integer = 0; IgnoreCase: Boolean = false; from: Integer = 0): Integer;
function PosL(StartFrom: Integer; Substr: string; S: string; N: Integer = 0; IgnoreCase: Boolean = false): Integer;

  // ���������� �������� ������, ���� Src = ""
function CodeEmptyString(src: string): string;

  // ������ �������� EmptyQtString ��������:
function DecodeEmptyString(src: string): string;


 // ��������� �� �����
function IsWild(InputStr, Wilds: string; IgnoreCase: Boolean): Boolean;

 // ���������� ��������� :
 //  Wilds ����� ��������� ��������� ����������� ������� :
 //    ? - ����� ������
 //    * - ����� ������������������ ��������
 //    | - ���������� "���"
function IsWildEx(InputStr: string; Wilds: string; IgnoreCase: Boolean): Boolean;

 // ������� ���� ���������, ����������� ������ "from" � ������ S �����
 // ������������ SepStart � SepEnd � �������� � ���� ��������� ���
 // OldPattern �� NewPattern. ���� OldPattern = "*", �� ����� ���������
 // ��������� �� NewPattern.
function StringReplaceIn(from: Integer; const S, SepStart, SepEnd, OldPattern,
  NewPattern: string; Flags: TReplaceFlags; RemoveSeps: Boolean = true;
  InsertNew: Boolean = false): string;


  // ������� ������� ������ � InStr ������ FindStr �� ReplaceStr
function FastStringReplace(InStr: string; FindStr, ReplaceStr: string): string;

 // ��������������� ��� ������� � ����� ������ 33 � "/", "\" � %xx
function UrlEncode(url: string): string;

type

  TStringsCounterData = record
    Str: string[200];
    Hash: LongWord;
    Count: Integer;
    Data: Integer;
  end;

  PStringsCounterData = ^TStringsCounterData;

  // ������� TStringList, �������� �������� �� �����������, � � Data �������� ����������
  // ����������� ����� � ������ �������.  ����������� ������ Add ��� ���������� ������
  TStringsCounterList = class(TList)
  private
    function GetCounts(Index: Integer): Integer;
    procedure SetCounts(Index: Integer; const Value: Integer);
    function GetItems(Index: Integer): PStringsCounterData;
  public
    destructor Destroy; override;

    function IndexOf(const S: string): Integer;

    function Add(const S: string; Data: Integer; IncCount: Integer = 1): Integer;
    property Counts[Index: Integer]: Integer read GetCounts write SetCounts;
    property Items[Index: Integer]: PStringsCounterData read GetItems; default;
    procedure Clear; override;

    procedure SortByCounts;
  end;


  TStringBtwInfo = record
    PosStart: Integer; // ������� ������� ���������� � ������
    PosEnd: Integer; // ������� ������ ���������� ����������
    TotalLen: Integer; // ����� ����� ������, ����������� � ���������� (������ � ����)
    SepString: string; // ���������� ���� ����������� ������.
    Params: string; // ���� useparams = true, �� ���� �������� ��, ��� ���� �������
                    // � ��������� ���� ����� ":" ("%project:3s%" - "3s").
    SearchOk: Boolean; // ������ ��������� ����� ����� ������ ���� SearchOk = true
  end;

  // ���������� ���������, ������������ ������ from � ������������� �����
  // ������������ SepStart � SepEnd.  (<td>mytext</td>, ������ "mytext")
  // ���� SepEnd �� ������, �� �� ��������� ������ SepStart
function GetStringBetween(from: Integer; str: string; SepStart: string; SepEnd: string = ''): TStringBtwInfo;

procedure PrepareTextToXML(var buffer: string);

function NormalizeXML(str: string): string;

var
  csCryptFirst,
    csCryptSecond: Integer;
  csCryptHeader: string;

implementation

uses akDataUtils;

function NormalizeXML(str: string): string;
begin
  Result := FastStringReplace(str, '<', '&lt;');
  Result := FastStringReplace(Result, '>', '&gt;');
  Result := FastStringReplace(Result, '&', '&amp;');
  Result := FastStringReplace(Result, '''', '&apos;');
  Result := FastStringReplace(Result, '"', '&quot;');
end;

function FastStringReplace(InStr: string; FindStr, ReplaceStr: string): string;
var
  LenFindStr, LenReplaceStr, LenInStr: integer;
  PtrInStr, PtrOutStr, // pointers to incremental reading and writing
    PInStr, POutStr: PChar; // pointer to start of output string
  Res: Integer;
begin
  if (FindStr = '') or (InStr = '') then begin
    Result := InStr;
    exit;
  end;

  Result := '';

  LenInStr := Length(InStr);
  LenFindStr := Length(FindStr);
  LenReplaceStr := Length(ReplaceStr);
  Res := 0;
  PInStr := PChar(InStr);
  PtrInStr := PInStr;
  {find number of occurences to allocate output memory in one chunk}
  while PtrInStr < (PInStr + LenInStr) do begin
    if StrLIComp(PtrInStr, PChar(FindStr), LenFindStr) = 0 then
      inc(Res);
    inc(PtrInStr);
  end;
  {reset pointer}
  PtrInStr := PInStr;
  {allocate the output memory - calculating what is needed}
  GetMem(POutStr, Length(InStr) + (Res * (LenReplaceStr - LenFindStr)) + 1);
  try
  {find and replace the strings}
    PtrOutStr := POutStr;
    while PtrInStr < (PInStr + LenInStr) do begin
      if (StrLIComp(PtrInStr, PChar(FindStr), LenFindStr) = 0) then begin
        if (LenReplaceStr > 0) then begin
          StrLCopy(PtrOutStr, PChar(ReplaceStr), LenReplaceStr);
          inc(PtrOutStr, LenReplaceStr); // increment output pointer
        end;
        inc(PtrInStr, LenFindStr); // increment input pointer
      end else begin
      {write one char to the output string}
        StrLCopy(PtrOutStr, PtrInStr, 1); // copy character
        inc(PtrInStr);
        inc(PtrOutStr);
      end;
    end;
    {copy the output string memory to the provided output string}
    Result := StrPas(POutStr);
  finally
    FreeMem(POutStr);
  end;
end;

procedure PrepareTextToXML(var buffer: string);
var i: Integer;
begin
  for i := 1 to Length(Buffer) do
    if (Buffer[i] in [#0..#32, #10, #13, '&', '"']) then
      Buffer[i] := #32;
end;

procedure FastAddString(var Org: string; add: string);
var addln, orgln: Integer;
begin
  orgln := Length(org);
  addln := Length(add);
  SetLength(Org, Length(Org) + addln);
  Move(add[1], Org[orgln + 1], addln);
end;

function GetStringBetween(from: Integer; str: string; SepStart: string; SepEnd: string): TStringBtwInfo;
var i, ps: Integer;
  sepen: string;
begin
  with Result do
  begin
    SearchOk := false;
    posStart := PosL(from, SepStart, str);
    if posStart = 0 then exit;

    if SepEnd = '' then SepEn := SepStart else SepEn := SepEnd;
    posEnd := PosL(posStart + Length(SepStart), SepEn, str);
    if posEnd = 0 then exit;

    ps := posStart + Length(SepStart);
    SepString := Copy(str, ps, posEnd - ps);
    i := Pos(':', SepString);
    if i = 0 then
      Params := ''
    else
    begin
      Params := Copy(SepString, i + 1, maxInt);
      SepString := Copy(SepString, 1, i - 1);
    end;

    TotalLen := posEnd - ps + Length(SepStart) + Length(SepEn);

    SearchOk := True;
  end;
end;

function StringReplaceIn(from: Integer; const S, SepStart, SepEnd, OldPattern,
  NewPattern: string; Flags: TReplaceFlags; RemoveSeps: Boolean = true;
  InsertNew: Boolean = false): string;
var SPs, EPs: Integer;
  old, newStr: string;

begin
  Result := S;
  SPs := PosL(from, SepStart, S, 0, rfIgnoreCase in Flags);
  if SPs = 0 then exit;
  SPs := SPs + Length(SepStart);
  EPs := PosL(SPs, SepEnd, S, 0, rfIgnoreCase in Flags);
  if EPs = 0 then exit;

  if OldPattern <> '*' then
    newStr := StringReplace(Copy(S, SPs, EPs - SPs), OldPattern, NewPattern, Flags)
  else
    if NewPattern = '*' then
      newStr := Copy(S, SPs, EPs - SPs)
    else
      newStr := NewPattern;

  // ���� �� ����� ������� ����������, �� ��������� �� � ������.
  if not RemoveSeps then newStr := SepStart + newStr + SepEnd;

  // ���� ��������� ����� ������, �� ��������� ������ � "old".
  if InsertNew then
    old := SepStart + Copy(S, SPs, EPs - SPs) + SepEnd
  else
    old := '';

  Result := Copy(S, 1, SPs - Length(SepStart) - 1) + old +
    newStr +
    Copy(S, EPs + Length(SepEnd), MaxInt);
end;

function IsWild(InputStr, Wilds: string; IgnoreCase: Boolean): Boolean;

  function FindPart(const HelpWilds, InputStr: string): Integer;
  var
    I, J: Integer;
    Diff: Integer;
  begin
    I := Pos('?', HelpWilds);
    if I = 0 then
    begin
     { if no '?' in HelpWilds }
      Result := Pos(HelpWilds, InputStr);
      Exit;
    end;
   { '?' in HelpWilds }
    Diff := Length(InputStr) - Length(HelpWilds);
    if Diff < 0 then
    begin
      Result := 0;
      Exit;
    end;
   { now move HelpWilds over InputStr }
    for I := 0 to Diff do
    begin
      for J := 1 to Length(HelpWilds) do
      begin
        if (InputStr[I + J] = HelpWilds[J]) or
          (HelpWilds[J] = '?') then
        begin
          if J = Length(HelpWilds) then
          begin
            Result := I + 1;
            Exit;
          end;
        end
        else
          Break;
      end;
    end;
    Result := 0;
  end;

  function SearchNext(var Wilds: string): Integer;
 { looking for next *, returns position and string until position }
  begin
    Result := Pos('*', Wilds);
    if Result > 0 then Wilds := Copy(Wilds, 1, Result - 1);
  end;

var
  CWild, CInputWord: Integer; { counter for positions }
  I, LenHelpWilds: Integer;
  MaxInputWord, MaxWilds: Integer; { Length of InputStr and Wilds }
  HelpWilds: string;
begin
  if Wilds = InputStr then
  begin
    Result := True;
    Exit;
  end;
  repeat { delete '**', because '**' = '*' }
    I := Pos('**', Wilds);
    if I > 0 then
      Wilds := Copy(Wilds, 1, I - 1) + '*' + Copy(Wilds, I + 2, MaxInt);
  until I = 0;
  if Wilds = '*' then
  begin { for fast end, if Wilds only '*' }
    Result := True;
    Exit;
  end;
  MaxInputWord := Length(InputStr);
  MaxWilds := Length(Wilds);
  if IgnoreCase then
  begin { upcase all letters }
    InputStr := AnsiUpperCase(InputStr);
    Wilds := AnsiUpperCase(Wilds);
  end;
  if (MaxWilds = 0) or (MaxInputWord = 0) then
  begin
    Result := False;
    Exit;
  end;
  CInputWord := 1;
  CWild := 1;
  Result := True;
  repeat
    if InputStr[CInputWord] = Wilds[CWild] then
    begin { equal letters }
      { goto next letter }
      Inc(CWild);
      Inc(CInputWord);
      Continue;
    end;
    if Wilds[CWild] = '?' then
    begin { equal to '?' }
      { goto next letter }
      Inc(CWild);
      Inc(CInputWord);
      Continue;
    end;
    if Wilds[CWild] = '*' then
    begin { handling of '*' }
      HelpWilds := Copy(Wilds, CWild + 1, MaxWilds);
      I := SearchNext(HelpWilds);
      LenHelpWilds := Length(HelpWilds);
      if I = 0 then
      begin
        { no '*' in the rest, compare the ends }
        if HelpWilds = '' then Exit; { '*' is the last letter }
        { check the rest for equal Length and no '?' }
        for I := 0 to LenHelpWilds - 1 do
        begin
          if (HelpWilds[LenHelpWilds - I] <> InputStr[MaxInputWord - I]) and
            (HelpWilds[LenHelpWilds - I] <> '?') then
          begin
            Result := False;
            Exit;
          end;
        end;
        Exit;
      end;
      { handle all to the next '*' }
      Inc(CWild, 1 + LenHelpWilds);
      I := FindPart(HelpWilds, Copy(InputStr, CInputWord, MaxInt));
      if I = 0 then
      begin
        Result := False;
        Exit;
      end;
      CInputWord := I + LenHelpWilds;
      Continue;
    end;
    Result := False;
    Exit;
  until (CInputWord > MaxInputWord) or (CWild > MaxWilds);
  { no completed evaluation }
  if CInputWord <= MaxInputWord then Result := False;
  if (CWild <= MaxWilds) and (Wilds[MaxWilds] <> '*') then Result := False;
end;

function IsWildEx(InputStr: string; Wilds: string; IgnoreCase: Boolean): Boolean;
var i: Integer;
  seg: string;
begin
  Result := False;

  for i := 0 to maxInt do
  begin
    Seg := GetLeftSegment(i, Wilds, '|');
    if Seg = '|' then break;

    if IsWild(InputStr, Seg, IgnoreCase) then
    begin
      Result := True;
      break;
    end;
  end;
end;

function GetRightSegment(N: Integer; Str: string; SegSep: Char): string;
var i: Integer;
  ResPos, SecPos, SecN: Integer;
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
        ResPos := i + 1; // ����� SegSep
        break;
      end;
      SecPos := i - 1; // ������ SegSep
      Inc(SecN);
    end;
  end;

  if (ResPos = -1) and (N = SecN) then
    ResPos := 1;

  if ResPos = -1 then
    Result := SegSep
  else
    Result := Copy(Str, ResPos, SecPos - ResPos + 1);
end;

function GetLeftSegment(N: Integer; Str: string; SegSep: Char): string;
var i: Integer;
  ResPos, SecPos, SecN: Integer;
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
        ResPos := i - 1; // ����� SegSep
        break;
      end;
      SecPos := i + 1; // ������ SegSep
      Inc(SecN);
    end;
  end;

  if (ResPos = -1) and (N = SecN) then
    ResPos := Length(Str);

  if ResPos = -1 then
    Result := SegSep
  else
    Result := Copy(Str, SecPos, ResPos - SecPos + 1);
end;

function CryptString(Str: string): string;
var i, clen: Integer;
begin
  clen := Length(csCryptHeader);
  SetLength(Result, Length(Str) + clen);
  Move(csCryptHeader[1], Result[1], clen);
  for i := 1 to Length(Str) do
  begin
    if i mod 2 = 0 then
      Result[i + clen] := Chr(Ord(Str[i]) xor csCryptSecond)
    else
      Result[i + clen] := Chr(Ord(Str[i]) xor csCryptFirst);
  end;
end;

function UnCryptString(Str: string): string;
var i, clen: Integer;
begin
  clen := Length(csCryptHeader);
  SetLength(Result, Length(Str) - clen);
  if Copy(Str, 1, clen) <> csCryptHeader then
    raise ECryptError.Create('UnCryptString failed');

  for i := 1 to Length(Str) - clen do
  begin
    if (i) mod 2 = 0 then
      Result[i] := Chr(Ord(Str[i + clen]) xor csCryptSecond)
    else
      Result[i] := Chr(Ord(Str[i + clen]) xor csCryptFirst);
  end;
end;

function IsLat(Str: string): boolean;
var i: Integer;
begin
  Result := True;
  for i := 1 to Length(Str) do
    if Str[i] > #127 then
    begin
      Result := False;
      exit;
    end;
end;

function StrOEMToANSI(St: string): string;
begin
  Result := '';
  if st = '' then exit;
  SetLength(Result, Length(St));
  OemToChar(PChar(St), PChar(Result));
end;

function StrANSItoOEM(St: string): string;
begin
  Result := '';
  if st = '' then exit;
  SetLength(Result, Length(St));
  CharToOEM(PChar(St), PChar(Result));
end;

function CodeEmptyString(src: string): string;
begin
  Result := Trim(src);
  if Result = '' then
    Result := '!null!value';
end;

function DecodeEmptyString(src: string): string;
begin
  Result := Trim(src);
  if Result = '!null!value' then
    Result := '';
end;

procedure GetStrWords(St: string; List: TStringList; latonly: boolean = true);
var i: Integer;
  Start: Integer;
  Wrd: string;
  str: string;
begin
  List.Clear; str := st + ' ';
  Wrd := ''; Start := 1;
  for i := 1 to Length(str) do
  begin
    if str[i] in [#13, #10, #9, #32..#64, #91..#96, #123..#191] then
    begin
      Wrd := Trim(Copy(str, Start, i - Start));
      if ((not IsLat(Wrd)) or (not latonly)) and (Wrd <> '') then
        List.Add(Wrd);
      Start := i + 1;
    end;
  end;
end;

// ���������� true, ���� ����� wrds 100% ������������.
// ���������� false, ���� ����� ���� �� �������, �� ������ �����
//  ��� ����������. ������ ������ ����� ����� ������������ � Res.
//  ���� Res = 0, �� ����� 100% ����������� � ������.

function FirstWordsIsNear(St: string; wrds: TStringList; var Res: Integer): Boolean;
var prevLen, prev, psr, w: Integer;
  tt: string;
begin
  Res := 0; Result := True;
  if Wrds.Count = 0 then
    exit;
  prevLen := 0; Prev := 0;
  tt := CharLower(PChar(st));
  for w := 0 to Wrds.Count - 1 do
  begin
    psr := Pos(wrds[w], tt);
    if w = 0 then
    begin
      Res := psr;
      prev := psr;
      FillChar(tt[1], psr, #32);
    end;
    if (psr = 0) or (psr - prev - prevLen > 10) then
    begin
      Result := False;
      Break;
    end;
    prev := psr;
    prevLen := Length(wrds[w]);
  end;
end;

function WordsIsNear(St: string; Words: string): boolean;
var sl: TStringList;
  Offset, psf: Integer;
  str: string;
begin
  Result := False;
  if Trim(Words) = '' then
  begin Result := True; exit;
  end;

  sl := TStringList.Create;
  try
    psf := 0; Offset := 1;
    GetStrWords(AnsiLowerCase(Words), sl, false);
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
    sl.Free;
  end;
end;

function TrimIn(St: string; rchars: TChars): string;
var f, s: Integer;
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

function TextToLine(St: string): string;
var f, s: Integer;
  PrevDeleted: boolean;
begin
  SetLength(Result, Length(St));
  s := 0; PrevDeleted := False;
  for f := 1 to Length(St) do
  begin
    if not (St[f] in [#13, #10, #9]) then
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

function GetNameLT(Name: string): string;
var p, l, i: Integer;
begin
  Result := Copy(Name, 1, 1); // ������ ������
  p := Pos(' ', Name); // ������ ����� ������� �������
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

function NotCharPos(St: string; ch: Char; StartFrom: Integer = 1): Integer;
var i: Integer;
begin
  Result := 0;
  for i := StartFrom to Length(st) do
    if st[i] <> ch then
    begin
      Result := i;
      Break;
    end;
end;

function WordWrapStr;
var i: Integer;
  ln, crStart, crLastSp, crlen: Integer;
  sta: string;
begin
  Result := StringOfChar(' ', first);
  crLastSp := Len;
  crlen := 0; crStart := 1; ln := 0;
  for i := 1 to Length(st) do
  begin
    inc(crLen);
    if (crLen > len + 1) or (i = Length(st)) then
    begin
      if i = Length(st) then crLastSp := MaxInt;
      inc(ln);
      if ln > 1 then
        Sta := StringOfChar(' ', next)
      else
        Sta := '';
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

function WordsIn(St: string; Words: string): boolean;
var sl: TStringList;
  i: Integer;
  lw1, lw2: string;
begin
  Result := True;
  if Trim(Words) = '' then
  begin Result := True; exit;
  end;

  sl := TStringList.Create;
  try
    lw2 := AnsiLowerCase(st);
    GetStrWords(Words, sl, false);
    for i := 0 to sl.Count - 1 do
    begin
      lw1 := AnsiLowerCase(sl[i]);
      if Pos(lw1, lw2) = 0 then
      begin
        Result := False;
        break;
      end;
    end;
  finally
    sl.Free;
  end;
end;

function ReplaceChar(st: string; c1, c2: char): string;
var i: Integer;
begin
  Result := st;
  for i := 1 to Length(st) do
    if Result[i] = c1 then
      Result[i] := c2;
end;

function PosL(StartFrom: Integer; Substr: string; S: string; N: Integer = 0; IgnoreCase: Boolean = false): Integer;
var i, slen, okcnt, sfrom: Integer;
begin
  okcnt := 0; Result := 0;
  slen := Length(SubStr);
  if slen = 0 then exit;
  sfrom := iifs(StartFrom <= 0, 1, StartFrom);
  for i := sfrom to Length(s) do begin
    if ((IgnoreCase) and ((upcase(s[i]) = upcase(SubStr[1])) and (CompareText(Copy(s, i, slen), SubStr) = 0))) or
      ((not IgnoreCase) and ((s[i] = SubStr[1]) and (CompareStr(Copy(s, i, slen), SubStr) = 0))) then
      inc(okcnt);
    if okcnt = N + 1 then
    begin
      Result := i;
      break;
    end;
  end;
end;

function PosR(Substr: string; S: string; N: Integer; IgnoreCase: Boolean; from: Integer): Integer;
var fr, i, slen, okcnt: Integer;
begin
  okcnt := 0; Result := 0;
  slen := Length(SubStr);
  if slen = 0 then exit;
  if from = 0 then fr := Length(s) else fr := from;
  if fr > Length(s) then fr := Length(s);
  for i := fr downto 1 do
  begin
    if ((IgnoreCase) and ((upcase(s[i]) = upcase(SubStr[1])) and (CompareText(Copy(s, i, slen), SubStr) = 0))) or
      ((not IgnoreCase) and ((s[i] = SubStr[1]) and (CompareStr(Copy(s, i, slen), SubStr) = 0))) then
{    if ((IgnoreCase) and (AnsiCompareText(Copy(s, i, slen), SubStr) = 0)) or
      ((not IgnoreCase) and (AnsiCompareStr(Copy(s, i, slen), SubStr) = 0)) then}
      inc(okcnt);
    if okcnt = N + 1 then
    begin
      Result := i;
      break;
    end;
  end;
end;

function PosRP(Substr: string; S: string; from: Integer; IgnoreCase: Boolean = false): Integer;
var fr, i, slen {, okcnt}: Integer;

begin
  {okcnt := 0;}Result := 0;
  slen := Length(SubStr);
  if from > Length(s) then fr := from else fr := Length(s);
  for i := fr downto 1 do
  begin
    if ((IgnoreCase) and (AnsiCompareText(Copy(s, i, slen), SubStr) = 0)) or
      ((not IgnoreCase) and (AnsiCompareStr(Copy(s, i, slen), SubStr) = 0)) then
//      inc(okcnt);
    begin
      Result := i;
      break;
    end;
  end;
end;



{ TStringsCounterList }

function TStringsCounterList.Add(const S: string; Data: Integer; IncCount: Integer): Integer;
var fnd: Integer;
  ptr: PStringsCounterData;
begin
  fnd := IndexOf(s);
  if fnd = -1 then begin
    New(ptr);
    ptr^.Hash := GetStringCRC(s, false);
    ptr^.Count := IncCount;
    ptr^.Str := S;
    ptr^.Data := Data;
    inherited Add(ptr);
  end
  else begin
    Counts[fnd] := Counts[fnd] + IncCount;
  end;
  Result := fnd;
end;

procedure TStringsCounterList.Clear;
var i: Integer;
begin
  for i := 0 to Count - 1 do
    Dispose(PStringsCounterData(Items[i]));
  inherited;
end;

destructor TStringsCounterList.Destroy;
begin
  Clear;
  inherited;
end;

function TStringsCounterList.GetCounts(Index: Integer): Integer;
begin
  Result := Items[Index]^.Count;
end;

function TStringsCounterList.GetItems(Index: Integer): PStringsCounterData;
begin
  Result := inherited Items[Index];
end;

function TStringsCounterList.IndexOf(const S: string): Integer;
var i: Integer;
  sh: LongWord;
  dt: PStringsCounterData;
begin
  Result := -1;

  sh := GetStringCRC(S, false);
  for i := 0 to Count - 1 do begin
    dt := PStringsCounterData(Items[i]);
    if (dt^.Hash = sh) and (dt^.Str = S) then begin
        // ����� ������:
      Result := i;
      break;
    end;
  end;
end;

procedure TStringsCounterList.SetCounts(Index: Integer;
  const Value: Integer);
begin
  PStringsCounterData(Items[Index])^.Count := Value;
end;


function CompareFunc(Item1, Item2: Pointer): Integer;
var Cnt1, Cnt2: Integer;
begin
  Cnt1 := PStringsCounterData(Item1)^.Count;
  Cnt2 := PStringsCounterData(Item2)^.Count;

  if Cnt1 < Cnt2 then Result := -1
  else if Cnt1 > Cnt2 then Result := 1
  else Result := 0;
end;

procedure TStringsCounterList.SortByCounts;
begin
  Sort(CompareFunc);
end;


function UrlEncode(url: string): string;
var i, ps: Integer;
  ch: string;
begin
  SetLength(result, Length(url) * 3); ps := 1;
  for i := 1 to Length(url) do begin
    if url[i] in [#0..#32, '/', '\'] then begin
      ch := '%' + IntToHex(Ord(url[i]), 2);
      Move(ch[1], result[ps], 3);
      inc(ps, 3);
    end else begin
      result[ps] := url[i];
      inc(ps);
    end;
  end;
  SetLength(Result, ps - 1);

end;

initialization
  csCryptFirst := 28;
  csCryptSecond := 235;
  csCryptHeader := '';
end.

