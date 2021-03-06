// AKTools akDataUtils unit.
//         ������, ���������� ������� �� ������ � ���������� �������.
//=============================================================================

unit akDataUtils;

interface

uses SysUtils, Classes, Windows;

// ���������� ���������� ����� �������� ������� � ������� �������� ��������
// Data. ���� ������ �������� �� �������, �� �������� -1.
function DataInArray(Data: Integer; Arr: array of Integer): Integer; overload;
function DataInArray(Data: Boolean; Arr: array of Boolean): Integer; overload;
function DataInArray(Data: Double; Arr: array of Double): Integer; overload;
function DataInArray(Data: string; Arr: array of string; IgnoreCase: Boolean): Integer; overload;
function DataInArray(Data: string; Arr: TStrings; IgnoreCase: Boolean): Integer; overload;
function DataInArray(Data: Pointer; Arr: TList): Integer; overload;

// ���������� �����, ���������� � ����� first-last � value.
function GetBits(value: Integer; first, last: Byte): DWORD;

// ������� CRC32 ��������� ������.
function GetStringCRC(Str: string; UseZero: Boolean = true): Cardinal;

// ���� �������� ����� ������� ������ v1, ����� - v2
function iifs(Expr: boolean; v1, v2: Integer): Integer; overload;
function iifs(Expr: boolean; v1, v2: string): string; overload;
function iifs(Expr: boolean; v1, v2: Boolean): Boolean; overload;
function iif(Expr: boolean; v1, v2: variant): variant;

// ���������� �������� ���� ����������. ���������� :
//  ������������� ����� - ���� a ������ b
//                 ���� - ��� ����
//  ������������� ����� - a ������ b
function UniCompare(val1, val2: string): Integer; overload;
function UniCompare(val1, val2: TDateTime): Integer; overload;
function UniCompare(val1, val2: Integer): Integer; overload;



implementation

const CRC32Polynomial = $EDB88320;
var crc_32_tab: array[byte] of longword;

function DataInArray(Data: string; Arr: array of string; IgnoreCase: Boolean): Integer;
var i: Integer;
begin
  Result := -1;
  for i := Low(Arr) to High(Arr) do
    if ((IgnoreCase) and (AnsiCompareText(Data, Arr[i]) = 0)) or
      ((not IgnoreCase) and (AnsiCompareStr(Data, Arr[i]) = 0)) then
    begin
      Result := i;
      Break;
    end;
end;

function DataInArray(Data: Integer; Arr: array of Integer): Integer;
var i: Integer;
begin
  Result := -1;
  for i := Low(Arr) to High(Arr) do
    if (Data = Arr[i]) then
    begin
      Result := i;
      Break;
    end;
end;

function DataInArray(Data: Boolean; Arr: array of Boolean): Integer;
var i: Integer;
begin
  Result := -1;
  for i := Low(Arr) to High(Arr) do
    if (Data = Arr[i]) then
    begin
      Result := i;
      Break;
    end;
end;

function DataInArray(Data: Double; Arr: array of Double): Integer;
var i: Integer;
begin
  Result := -1;
  for i := Low(Arr) to High(Arr) do
    if (Data = Arr[i]) then
    begin
      Result := i;
      Break;
    end;
end;

function DataInArray(Data: string; Arr: TStrings; IgnoreCase: Boolean): Integer; overload;
var i: Integer;
begin
  Result := -1;
  for i := 0 to Arr.Count - 1 do
    if ((AnsiCompareText(Arr[i], Data) = 0) and (IgnoreCase)) or
      ((CompareStr(Arr[i], Data) = 0) and (not IgnoreCase)) then
    begin
      Result := i;
      Break;
    end;
end;

function DataInArray(Data: Pointer; Arr: TList): Integer; overload;
var i: Integer;
begin
  Result := -1;
  for i := 0 to Arr.Count - 1 do
    if (Arr[i] = Data) then begin
      Result := i;
      Break;
    end;
end;

function GetBits(value: Integer; first, last: Byte): DWORD;
var f, l: Integer;
  a1, a2: DWord;
begin
  l := last; f := first;
  if f < 0 then f := 0;
  if l > 31 then l := 31;
  a1 := (value shr (f));
  a2 := a1 shl (31 - (l - f));
  Result := a2 shr (31 - (l - f))
end;

procedure BuildCRC32Table;
{* (c) Burnashov Alexander alexburn@metrocom.ru *}
var i, j: byte; crc: longword;
begin
  for i := 0 to 255 do
  begin
    crc := i;
    for j := 8 downto 1 do
      if (crc and 1) <> 0 then
        crc := (crc shr 1) xor CRC32Polynomial
      else
        crc := crc shr 1;
    crc_32_tab[i] := crc;
  end;
end;

function UpdC32(octet: BYTE; crc: Cardinal): Cardinal;
begin
  Result := crc_32_tab[BYTE(crc xor Cardinal(octet))] xor
    ((crc shr 8) and $00FFFFFF)
end;

function GetStringCRC(Str: string; UseZero: Boolean): Cardinal;
const FirstRun: Boolean = true;
type TAr = array[0..3] of byte;
var
  l, crc: Cardinal;
  counter: SmallInt;
  ar: TAr absolute crc;
  am: TAr absolute l;
begin
  if FirstRun then
  begin
    BuildCRC32Table;
    FirstRun := False;
  end;

  crc := $FFFFFFFF;
  for counter := 1 to Length(Str) do
    crc := UpdC32(Byte(Str[counter]), crc);

  am[0] := ar[3]; am[1] := ar[2]; am[2] := ar[1]; am[3] := ar[0];
  Result := l;

  if (Result = 0) and (not UseZero) then Result := 1;
end;

function iif(Expr: boolean; v1, v2: variant): variant;
begin
  if Expr then
    Result := v1
  else
    Result := v2;
end;

function iifs(Expr: boolean; v1, v2: Integer): Integer; overload;
begin
  if Expr then
    Result := v1
  else
    Result := v2;
end;

function iifs(Expr: boolean; v1, v2: string): string; overload;
begin
  if Expr then
    Result := v1
  else
    Result := v2;
end;

function iifs(Expr: boolean; v1, v2: Boolean): Boolean; overload;
begin
  if Expr then
    Result := v1
  else
    Result := v2;
end;

function UniCompare(val1, val2: string): Integer; overload;
begin
  Result := CompareText(val1, val2);
end;

function UniCompare(val1, val2: TDateTime): Integer; overload;
begin
  Result := 0;
  if val1 = val2 then Result := 0;
  if val1 > val2 then Result := 1;
  if val1 < val2 then Result := -1;
end;

function UniCompare(val1, val2: Integer): Integer; overload;
begin
  Result := 0;
  if val1 = val2 then Result := 0;
  if val1 > val2 then Result := 1;
  if val1 < val2 then Result := -1;
end;


end.

