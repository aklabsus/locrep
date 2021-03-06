// AKTools akMisc unit.
//         ������, ���������� �������, �� �������� � ������ ������ AKTools
//=============================================================================

unit akMisc;

interface

uses Windows;

type
  TDatePart = (dpDay, dpMonth, dpYear);


 // ������� �����
function CryptInteger(ID: Integer): Integer;

 // ��������� �����
function UnCryptInteger(ID: Integer): Integer;

 // ��������� ���������� ����� ����� �������
function DistOf(px, py, p1x, p1y: Integer): Integer; overload;
function DistOfEx(px, py, p1x, p1y: Integer): Extended;

function DistOf(ps: TRect): Integer; overload;

 // ���������� ���������� �����, ������������ �����
 // �� �������� �� px,py �� ����������� � p1x, p1y
 // �� dr ��������.
function MovePointTo(px, py, p1x, p1y: Integer; dr: Integer): TPoint; overload;
function MovePointTo(ps: TRect; dr: Integer): TPoint; overload;

 // ���������� ����� ���� � ������
function DaysInMonth(Month, Year: Integer): Integer;

 // ���������� ���� ������ ������� ������
function GetWeekStart(cur: TDateTime): TDateTime;

 // ���������� ����� 1-7, ����������� ����� ��� ������ � �������� ��� ����������
function GetFirstDayOfWeek: Integer;

 // ���������� ����� ������
function WeekNumber(ADay: TDateTime): Integer;

 // ���������� ������ �������
function WidthOf(R: TRect): Integer;

 // ���������� ������ �������
function HeightOf(R: TRect): Integer;

 // ���������� ����� �������� d1-d2 �������� � �������� d4-d4
function GetIntDiff(d1, d2: Integer; d3, d4: Integer): Integer;

 // ���������� ����� �������� ������� d1-d2 �������� � �������� d3-d4
function GetTimeDiff(d1, d2: TDateTime; d3, d4: TDateTime): TDateTime;

implementation



uses SysUtils, Classes, Math, akDataUtils;



function GetFirstDayOfWeek: Integer;
var m: Integer;
  s: string;
begin
  SetLength(s, 10);
  m := GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_IFIRSTDAYOFWEEK, @(s[1]), 9);
  SetLength(s, m);
  Result := StrToIntDef(s, 0) + 1;
end;

function GetWeekStart(cur: TDateTime): TDateTime;
var dow: Integer;
begin
  dow := DayOfWeek(cur); {������� ���� ������ - 1(sun)..7(sat)}
  if GetFirstDayOfWeek = 1 {� ����� } then
    if dow = 1 then dow := 7 else dec(dow);

  Result := Trunc(cur - dow + 1);
end;

function MovePointTo(px, py, p1x, p1y: Integer; dr: Integer): TPoint;
var
  p: TRect;
  dst, en: Extended;
  tp: Integer;
begin
  Result.X := px; Result.Y := py;
  p := Rect(px, py, p1x, p1y);

  dst := DistOfEx(p.Left, p.Top, p.Right, p.Bottom);
  if dst = 0 then exit;

  en := ArcSin((p.Right - p.Left) / dst);
  tp := iifs(p.Top > p.Bottom, 1, -1);

  with Result do
  begin
    x := p.Left + Round(dr * sin(en));
    y := p.Top - tp * Round(dr * cos(en));
  end;
end;

function MovePointTo(ps: TRect; dr: Integer): TPoint;
begin
  with ps do
    Result := MovePointTo(Left, Top, Right, Bottom, dr);
end;

function CryptInteger(ID: Integer): Integer;
type TBytes = array[0..3] of byte;
var _src, _res: Integer;
  src: TBytes absolute _src;
  dst: TBytes absolute _res;
begin
  _src := ID;
  dst[0] := src[3] xor 9;
  dst[1] := src[0] xor 155;
  dst[2] := src[1] xor 65;
  dst[3] := src[2] xor 215;
  Result := _res;
end;

function UnCryptInteger(ID: Integer): Integer;
type TBytes = array[0..3] of byte;
var _src, _res: Integer;
  src: TBytes absolute _src;
  dst: TBytes absolute _res;
begin
  _src := ID;
  dst[0] := src[1] xor 155;
  dst[1] := src[2] xor 65;
  dst[2] := src[3] xor 215;
  dst[3] := src[0] xor 9;
  Result := _res;
end;

function DistOf(px, py, p1x, p1y: Integer): Integer;
begin
  Result := Round(DistOfEx(px, py, p1x, p1y));
end;

function DistOf(ps: TRect): Integer;
begin
  with ps do
    Result := DistOf(Left, Top, Right, Bottom);
end;

function DistOfEx(px, py, p1x, p1y: Integer): Extended;
var kat1, kat2: Integer;
begin
  kat1 := abs(px - p1x);
  kat2 := abs(py - p1y);
  Result := sqrt(sqr(kat1) + sqr(kat2));
end;

function DaysInMonth(Month, Year: Integer): Integer;
begin
  case Month of
    1, 3, 5, 7, 8, 10, 12: Result := 31;
    2:
      if (Year mod 4 = 0) and ((Year mod 100 <> 0) or (Year mod 400 = 0)) then
        Result := 29
      else
        Result := 28;
    4, 6, 9, 11: Result := 30;
  else
    Result := 0;
  end;
end;

function WidthOf(R: TRect): Integer;
begin
  Result := R.Right - R.Left;
end;

function HeightOf(R: TRect): Integer;
begin
  Result := R.Bottom - R.Top;
end;

function GetIntDiff(d1, d2: Integer; d3, d4: Integer): Integer;
var left, right: Integer;
begin
  if d1 > d3 then
    left := d1
  else
    left := d3;
  if d2 < d4 then
    right := d2
  else
    right := d4;

  Result := right - left;
  if Result < 0 then Result := 0;
end;

function GetTimeDiff(d1, d2: TDateTime; d3, d4: TDateTime): TDateTime;
var left, right: TDateTime;
begin
  if d1 > d3 then
    left := d1
  else
    left := d3;
  if d2 < d4 then
    right := d2
  else
    right := d4;

  Result := right - left;
  if Result < 0 then Result := 0;
end;

function WeekNumber(ADay: TDateTime): Integer;
var
  Year, Month, Day: Word;
  WeekDay: integer;
  DumDay: TDateTime;
  diff, diff2: integer;
begin
  DumDay := ADay;
  DecodeDate(DumDay, Year, Month, Day);
  DumDay := EncodeDate(Year, 1, 1); { first day of year }
  WeekDay := DayOfWeek(DumDay);
  if (WeekDay < 6) and (Weekday > 1) then { monday -> thursday }
    DumDay := DumDay - WeekDay + 2
  else
  begin
    if WeekDay > 5 then
      DumDay := DumDay - WeekDay + 9;
    if WeekDay = 1 then
      DumDay := DumDay + 1;
  end; { DumDay points to monday in week number one }
  diff := Trunc(ADay - DumDay);
  if diff < 0 then
  begin
    Result := WeekNumber(ADay - 7) + 1; { last week of previous year }
    Exit;
  end;
  DumDay := EncodeDate(Year, 12, 31); { last day of year }
  WeekDay := DayOfWeek(DumDay);
  diff2 := Trunc(DumDay - ADay);
  if (diff2 < 3) and { one of last three days of year }
    (WeekDay > 1) and (WeekDay < 5) and { monday -> wednesday }
    (WeekDay > diff2 + 1) then
  begin
    Result := 1; { first week of next year }
    Exit;
  end;
  result := diff div 7 + 1;
end;

end.

