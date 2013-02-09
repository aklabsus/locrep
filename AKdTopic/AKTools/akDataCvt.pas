// AKTools akDataCvt unit.
//         Модуль, содержащий функции по преобразованию формата данных.
//=============================================================================

unit akDataCvt;

interface

uses SysUtils, Windows, Graphics, akSysCover;


resourcestring
  exRectCoordWrong = 'Unable to convert ''%s'' in TRECT';
  exPointCoordWrong = 'Unable to convert ''%s'' in TPOINT';
  exFontStrWrong = 'Unable to convert ''%s'' in TFONT';
  exColorStrWrong = 'Unable to convert ''%s'' in TCOLOR';
  exIntArrayWrong = 'Unable to convert ''%s'' in Array[%d..%d] of Integer';

const
  MAXCHARSET = 41;
  IECharSets: array[0..MAXCHARSET, 0..1] of string =
  (
    ('Arabic (ASMO 708)', 'ASMO-708'),
    ('Arabic (ISO)', 'iso-8859-6'),
    ('Arabic (Windows)', 'windows-1256'),
    ('Baltic (ISO)', 'iso-8859-4'),
    ('Baltic (Windows)', 'windows-1257'),
    ('Central European (ISO)', 'iso-8859-2'),
    ('Central European (Windows)', 'windows-1250'),
    ('Cyrillic (ISO)', 'iso-8859-5'),
    ('Cyrillic (KOI8-R)', 'koi8-r'),
    ('Cyrillic (KOI8-U)', 'koi8-u'),
    ('Cyrillic (Windows)', 'windows-1251'),
    ('German (IA5)', 'x-IA5-German'),
    ('Greek (ISO)', 'iso-8859-7'),
    ('Greek (Windows)', 'windows-1253'),
    ('Hebrew (ISO-Logical)', 'iso-8859-8-i'),
    ('Hebrew (Windows)', 'windows-1255'),
    ('ISCII Assamese', 'x-iscii-as'),
    ('ISCII Bengali', 'x-iscii-be'),
    ('ISCII Devanagari', 'x-iscii-de'),
    ('ISCII Gujarathi', 'x-iscii-gu'),
    ('ISCII Kannada', 'x-iscii-ka'),
    ('ISCII Malayalam', 'x-iscii-ma'),
    ('Japanese (EUC)', 'euc-jp'),
    ('Japanese (JIS)', 'iso-2022-jp'),
    ('Japanese (Shift-JIS)', 'shift_jis'),
    ('Korean', 'ks_c_5601-1987'),
    ('Korean (EUC)', 'euc-kr'),
    ('Korean (ISO)', 'iso-2022-kr'),
    ('Korean (Johab)', 'Johab'),
    ('Latin 3 (ISO)', 'iso-8859-3'),
    ('Latin 9 (ISO)', 'iso-8859-15'),
    ('Norwegian (IA5)', 'x-IA5-Norwegian'),
    ('OEM United States', 'IBM437'),
    ('Swedish (IA5)', 'x-IA5-Swedish'),
    ('Thai (Windows)', 'windows-874'),
    ('Turkish (ISO)', 'iso-8859-9'),
    ('Turkish (Windows)', 'windows-1254'),
    ('US-ASCII', 'us-ascii'),
    ('Vietnamese (Windows)', 'windows-1258'),
    ('Western European (IA5)', 'x-IA5'),
    ('Western European (ISO)', 'iso-8859-1'),
    ('Western European (Windows)', 'Windows-1252')
    );

const MaxColors = 17;
  MaxSpColors = 24;
  INT_TRUE = 1;
  INT_FALSE = 0;

// Названия цветов.
const CColorNames: array[0..MaxColors] of string =
  ('Black', 'Maroon', 'Green', 'Olive', 'Navy', 'Purple', 'Teal', 'Gray',
    'Silver', 'Red', 'Lime', 'Yellow', 'Blue', 'Fuchsia', 'Aqua', 'LtGray',
    'DkGray', 'White');

// Названия стандартных системных цветов
const CSpColorNames: array[0..MaxSpColors] of string =
  ('ScrollBar', 'Background', 'ActiveCaption', 'InactiveCaption', 'Menu',
    'Window', 'WindowFrame', 'MenuText', 'WindowText', 'CaptionText',
    'ActiveBorder', 'InactiveBorder', 'AppWorkSpace', 'Highlight',
    'HighlightText', 'BtnFace', 'BtnShadow', 'GrayText', 'BtnText',
    'InactiveCaptionText', 'BtnHighlight', '3DDkShadow', '3DLight', 'InfoText',
    'InfoBk');

// Значения цветов
const CColorValues: array[0..MaxColors] of TColor =
  (clBlack, clMaroon, clGreen, clOlive, clNavy, clPurple, clTeal, clGray,
    clSilver, clRed, clLime, clYellow, clBlue, clFuchsia, clAqua, clLtGray,
    clDkGray, clWhite);

// Значения стандартных системных цветов
const CSpColorValues: array[0..MaxSpColors] of TColor =
  (clScrollBar, clBackground, clActiveCaption, clInactiveCaption, clMenu,
    clWindow, clWindowFrame, clMenuText, clWindowText, clCaptionText,
    clActiveBorder, clInactiveBorder, clAppWorkSpace, clHighlight,
    clHighlightText, clBtnFace, clBtnShadow, clGrayText, clBtnText,
    clInactiveCaptionText, clBtnHighlight, cl3DDkShadow, cl3DLight, clInfoText,
    clInfoBk);

type
  TGradient = record
    fromc: TColor; // source color
    toc: TColor; // target color
    hor: boolean; // horisontal gradient
    aqua: boolean; // стиль градиента
  end;

////////////////////////////////////////////////////////////////////////////////

function FriendlyIECodePageToCodePage(friendlynm: string): string;
function IECodePageToFriendlyCodePage(cp: string): string;

 // Преобразует строку вида "10,5,20,30" в TRECT
function StrToTRECT(str: string; Sep: char = ','): TRect;
function TRECTToStr(rect: TRect; Sep: char = ','): string;

 // Преобразует строку вида "10,51" в TPOINT
function StrToTPOINT(str: string; Sep: char = ','): TPoint;

 // Преобразует строку вида "font_name,BIU,Size,Color" в TFONT
procedure StrToTFONT(str: string; const Font: TFont; Sep: char = ',');

 // Преобразует строку вида "Black" или "#FFFFFF"(Цвет в RGB) в TCOLOR.
 // Возможные строковые значения смотрите в CSpColorNames и CColorNames.
function StrToTCOLOR(str: string): TColor;

 // Преобразует строку вида "Black:#FF2A44:v:g" или "Black:#FF2A44:h:a" в градиент.
 // h - horizontal
 // v - vertical
 // g - gradient
 // a - aqua
function StrToGradient(str: string): TGradient;

 // Преобразует массив в строку, разделяя элементы запятыми
function ArrayToStr(const ar: array of Integer): string; overload;
function ArrayToStr(const ar: array of string): string; overload;

 // Возвращает дату преобразованную в строку. Если даты нет (=0), то вернется def.
function DateTimeToStrDef(dt: TDateTime; def: string = ''): string;
function StrToDateTimeDef(str: string; def: TDateTime = 0): TDateTime;

 // Преобразует строку в массив интеджеров.
 // ar - указатель на массив
 // max - максимальное количество элементов массива (Count-1)
procedure StrToArray(str: string; ar: PIntArray; max: Integer); overload;

 // возвращает порядковый номер (с нуля) записи с мнимальным порядковым номером
function MinOfArray(const Args: array of integer): Integer;

// Преобразует время, указанное в секундах, в строку типа 124:23:45
// (часы:минуты:секунды)
function SecToHoursDgt(sec: Integer; ShowSecs: Boolean = true): string;

// Преобразует TColor в Color для html:
function ToHTMLColor(tcol: TColor): string;


// Работает с датой в unix-формате
const
  FirstOfYear1970 = 25569; // EncodeDate(1970, 1, 1);
function DateTimeToUnix(ADate: TDateTime): LongInt;
function UnixToDateTime(Atime: LongInt): TDateTime;
function UnixIsZeroDate(ADate: TDateTime): Boolean;

// Конвертирует строку в дату и наоборот. Не зависит от настроек даты в системе
function DateTimeToStrFixed(dt: TDateTime): string;
function StrToDateTimeFixed(str: string): TDateTime;


// Преобразует строку Accented Symbols в нормальную
function AccStrToNormal(str: string): string;

//------------------------------------------------------------------------------
var
  Time_ZoneC: Integer;
  shsFmtDay, shsFmtHr, shsFmtMin, shsFmtSec: string;
  shsFmtMode: Integer; // Указывает уровень подробности вывода.
    // Например, если здесь указано  4, то будет выводится "2 дня 10 час",
    // а если 3, то "58 час 12 мин"... и т.п.

 // Преобразует число секунд в годы, дни, часы и т.п., используя
 // правила форматирование из переменных shs*.
{!}function SecToHoursStr(sec: Integer; ShowSecs: Boolean = true): string;

 // Устанавливает стандартные правила форматирования для SecToHoursStr.
procedure DefaultShsFormat;

implementation

uses akStrUtils, akDataUtils, Classes;

function FriendlyIECodePageToCodePage(friendlynm: string): string;
var i: Integer;
begin
  Result := '';
  for i := 0 to MAXCHARSET do
    if AnsiCompareText(IECharSets[i, 0], friendlynm) = 0 then begin
      Result := IECharSets[i, 1];
      break;
    end;
end;

function IECodePageToFriendlyCodePage(cp: string): string;
var i: Integer;
begin
  Result := '';
  for i := 0 to MAXCHARSET do
    if AnsiCompareText(IECharSets[i, 1], cp) = 0 then begin
      Result := IECharSets[i, 0];
      break;
    end;
end;

function DateTimeToStrFixed(dt: TDateTime): string;
var y, m, d, h, n, s, z: Word;
begin
  DecodeDate(dt, y, m, d);
  DecodeTime(dt, h, n, s, z);
  Result := Format('%2.2d/%2.2d/%2.4d %2.2d:%2.2d:%2.2d:%3.3d', [m, d, y, h, n, s, z]);
end;

function StrToDateTimeFixed(str: string): TDateTime;
var
  y, m, d, h, n, s, z: Integer;
begin
  m := StrToIntDef(Copy(str, 1, 2), 1);
  d := StrToIntDef(Copy(str, 4, 2), 1);
  y := StrToIntDef(Copy(str, 7, 4), 1);

  h := StrToIntDef(Copy(str, 12, 2), 0);
  n := StrToIntDef(Copy(str, 15, 2), 0);
  s := StrToIntDef(Copy(str, 18, 2), 0);
  z := StrToIntDef(Copy(str, 21, 3), 0);

  Result := EncodeDate(y, m, d) + EncodeTime(h, n, s, z);
end;


function DateTimeToUnix(ADate: TDateTime): LongInt;
var Hour, Min, Sec, MSec: Word;
begin
  if (ADate = 0) or (ADate < FirstOfYear1970) then
  begin
    Result := 0; exit;
  end;
  DecodeTime(ADate, Hour, Min, Sec, MSec);
  Result :=
    TRUNC(ADate - FirstOfYear1970) * SecsPerDay + (((Hour - 1) * 60) + Min) * 60 + Sec + Time_ZoneC;
end;

function UnixToDateTime(Atime: LongInt): TDateTime;
begin
  Result := FirstOfYear1970 + ((ATime - Time_ZoneC + 3600) / SecsPerDay);
end;

function UnixIsZeroDate(ADate: TDateTime): Boolean;
begin
  Result := DateTimeToUnix(ADate) = 0;
end;

function DateTimeToStrDef(dt: TDateTime; def: string): string;
begin
  Result := iifs((dt = 0) or (UnixIsZeroDate(dt)), def, DateTimeToStr(dt));
end;

function StrToDateTimeDef(str: string; def: TDateTime = 0): TDateTime;
begin
  try
    Result := StrToDateTime(str);
  except
    Result := def;
  end;
end;


function MinOfArray(const Args: array of integer): Integer;
var i: Integer;
  minval: Integer;
begin
  Result := -1;
  minval := maxint;
  for i := 0 to High(Args) do
  begin
    if minval > Args[i] then
    begin
      minval := Args[i];
      Result := i;
    end;
  end;
end;

function ArrayToStr(const ar: array of string): string; overload;
var i: Integer;
begin
  Result := '';
  with TStringList.Create do
  try
    for i := Low(ar) to High(ar) do
      Add(ar[i]);
    Result := CommaText;
  finally
    Free;
  end;
end;

procedure StrToArray(str: string; ar: PIntArray; max: Integer); overload;
var i: Integer;
begin
  with TStringList.Create do
  try
    CommaText := str;
    for i := 0 to max do
      if i > Count - 1 then
        ar^[i] := 0
      else
        ar^[i] := StrToIntDef(Strings[i], 0);
  finally
    Free;
  end;
end;

function ArrayToStr(const ar: array of Integer): string; overload;
var i: Integer;
begin
  Result := '';
  for i := Low(ar) to High(ar) do
  begin
    Result := Result + IntToStr(ar[i]);
    if i <> High(ar) then
      Result := Result + ',';
  end;
end;

procedure DefaultShsFormat;
begin
  shsFmtDay := ' %d day';
  shsFmtHr := ' %d h';
  shsFmtMin := ' %d min';
  shsFmtSec := ' %d sec';
  shsFmtMode := 3;
end;

function SecToHoursStr(sec: Integer; ShowSecs: Boolean = true): string;
var d, h, m, s: integer;
  td, th, tm, ts: Integer;
begin
  Result := '';

  s := sec;
  if shsFmtMode >= 4 then
    td := Trunc(s / 24 / 60 / 60)
  else
    td := 0;

  d := td;
  th := Trunc(s / 60 / 60); h := th - td * 24;
  tm := Trunc(s / 60); m := tm - th * 60;
  ts := s; s := ts - tm * 60;
  if not ShowSecs then s := 0;

  if shsFmtMode >= 4 then
    if d <> 0 then result := result + Format(shsFmtDay, [d]);
  if h <> 0 then result := result + Format(shsFmtHr, [h]);
  if (m <> 0) and (d = 0) then result := result + Format(shsFmtMin, [m]);
  if (s <> 0) and (d = 0) and (h = 0) then result := result + Format(shsFmtSec, [s]);

  if result = '' then result := Format(shsFmtSec, [0]);
  result := Trim(Result);
end;

function SecToHoursDgt(sec: Integer; ShowSecs: Boolean = true): string;
var th, tm, ts, h, m, s: Integer;
begin
  s := sec;
  th := Trunc(s / 60 / 60); h := th;
  tm := Trunc(s / 60); m := tm - th * 60;
  ts := s; s := ts - tm * 60;
  if not ShowSecs then s := 0;

  Result := Format('%d:%.2d', [h, m]);
  if ShowSecs then Result := Format('%s:%.2d', [Result, s]);
end;

function StrToTRECT(str: string; Sep: char = ','): TRect;
var i: Integer;
  res, st: string;
begin
  st := TrimIn(str, [' ', '(', ')', '[', ']']);
  try
    for i := 0 to 3 do
    begin
      Res := GetLeftSegment(i, St, Sep);
      if Res <> Sep then
      begin
        case i of
          0: Result.Left := StrToInt(Res);
          1: Result.Top := StrToInt(Res);
          2: Result.Right := StrToInt(Res);
          3: Result.Bottom := StrToInt(Res);
        end;
      end
      else
        raise EConvertError.Create('Str uncomplete');
    end;
  except
    raise EConvertError.CreateFmt(exRectCoordWrong, [Str]);
  end;
end;

function StrToTPOINT(str: string; Sep: char = ','): TPoint;
var i: Integer;
  res, st: string;
begin
  st := TrimIn(str, [' ', '(', ')', '[', ']']);
  try
    for i := 0 to 1 do
    begin
      Res := GetLeftSegment(i, St, Sep);
      if Res <> Sep then
      begin
        case i of
          0: Result.x := StrToInt(Res);
          1: Result.y := StrToInt(Res);
        end;
      end
      else
        raise EConvertError.Create('Str uncomplete');
    end;
  except
    raise EConvertError.CreateFmt(exPointCoordWrong, [Str]);
  end;
end;

procedure StrToTFONT(str: string; const Font: TFont; Sep: char = ',');
var i: Integer;
  res, st: string;
begin
  st := TrimIn(str, [' ', '(', ')', '[', ']']);
  try
    for i := 0 to 3 do
    begin
      Res := GetLeftSegment(i, St, Sep);
      if Res <> Sep then
      begin
        case i of
          0: Font.Name := Res;
          1:
            begin
              Font.Style := [];
              if Pos('B', Res) <> 0 then Font.Style := Font.Style + [fsBold];
              if Pos('I', Res) <> 0 then Font.Style := Font.Style + [fsItalic];
              if Pos('U', Res) <> 0 then Font.Style := Font.Style + [fsUnderline];
            end;
          2: Font.Height := -StrToInt(Res);
          3: Font.Color := StrToTCOLOR(Res);
        end;
      end
      else
        raise EConvertError.Create('Str uncomplete');
    end;
  except
    raise EConvertError.CreateFmt(exFontStrWrong, [Str]);
  end;
end;

function StrToGradient(str: string): TGradient;
var tmp: string;
begin
  Result.fromc := StrToTCOLOR(GetLeftSegment(0, str, ':'));
  tmp := GetLeftSegment(1, str, ':');
  if tmp = ':' then
    Result.toc := Result.fromc
  else
    Result.toc := StrToTCOLOR(tmp);
  tmp := UpperCase(GetLeftSegment(2, str, ':'));
  Result.hor := (tmp = 'H') or (tmp = ':');
  tmp := UpperCase(GetLeftSegment(3, str, ':'));
  Result.aqua := (tmp <> 'G');
end;

function StrToTCOLOR(str: string): TColor;
var el: Integer;
  st: string;
  R, G, B: Byte;
begin
  Result := clNone;

  try
    st := Trim(str);
    if Pos('#', st) = 1 then
    begin
      R := StrToInt('$' + Copy(st, 2, 2));
      G := StrToInt('$' + Copy(st, 4, 2));
      B := StrToInt('$' + Copy(st, 6, 2));
      Result := RGB(R, G, B);
    end
    else
    begin
      el := DataInArray(st, CColorNames, true);
      if el <> -1 then
        Result := CColorValues[el];
      if el = -1 then
      begin
        el := DataInArray(st, CSpColorNames, true);
        if el <> -1 then
          Result := CSpColorValues[el];
      end;
      if el = -1 then
        raise EConvertError.Create('Str uncomplete');
    end;
  except
    ///raise EConvertError.CreateFmt(exColorStrWrong, [Str]);
  end;
end;

function TRECTToStr(rect: TRect; Sep: char = ','): string;
begin
  with Rect do
    Result := Format('%d' + sep + '%d' + sep + '%d' + sep + '%d', [Left, Top, Right, Bottom]);
end;

function AccStrToNormal(str: string): string;
const
  CharTable: array[128..255] of string =
  (#128,
    #129,
    #130,
    #131,
    #132,
    #133,
    #134,
    #135,
    #136,
    #137,
    #138,
    #139,
    #140,
    #141,
    #142,
    #143,
    #144,
    #145,
    #146,
    #147,
    #148,
    #149,
    #150,
    #151,
    #152,
    '&trade;',
    #154,
    #155,
    #156,
    #157,
    #158,
    #159,
    '&nbsp;',
    '&iexcl;',
    '&cent;',
    '&pound;',
    '&curren;',
    '&yen;',
    '&brkbar;',
    '&sect;',
    '&die;',
    '&copy;',
    '&ordf;',
    '&laquo;',
    '&not;',
    '&shy;',
    '&reg;',
    '&hibar;',
    '&deg;',
    '&plusmn;',
    '&sup2;',
    '&sup3;',
    '&acute;',
    '&micro;',
    '&para;',
    '&middot;',
    '&cedil;',
    '&sup1;',
    '&ordm;',
    '&raquo;',
    '&frac14;',
    '&frac12;',
    '&frac34;',
    '&iquest;',
    '&Agrave;',
    '&Aacute;',
    '&Acirc;',
    '&Atilde;',
    '&Auml;',
    '&Aring;',
    '&AElig;',
    '&Ccedil;',
    '&Egrave;',
    '&Eacute;',
    '&Ecirc;',
    '&Euml;',
    '&Igrave;',
    '&Iacute;',
    '&Icirc;',
    '&Iuml;',
    '&Dstrok;',
    '&Ntilde;',
    '&Ograve;',
    '&Oacute;',
    '&Ocirc;',
    '&Otilde;',
    '&Ouml;',
    '&times;',
    '&Oslash;',
    '&Ugrave;',
    '&Uacute;',
    '&Ucirc;',
    '&Uuml;',
    '&Yacute;',
    '&THORN;',
    '&szlig;',
    '&agrave;',
    '&aacute;',
    '&acirc;',
    '&atilde;',
    '&auml;',
    '&aring;',
    '&aelig;',
    '&ccedil;',
    '&egrave;',
    '&eacute;',
    '&ecirc;',
    '&euml;',
    '&igrave;',
    '&iacute;',
    '&icirc;',
    '&iuml;',
    '&eth;',
    '&ntilde;',
    '&ograve;',
    '&oacute;',
    '&ocirc;',
    '&otilde;',
    '&ouml;',
    '&divide;',
    '&oslash;',
    '&ugrave;',
    '&uacute;',
    '&ucirc;',
    '&uuml;',
    '&yacute;',
    '&thorn;',
    '&yuml;');

  function AccCharToNormal(acc: string): string;
  var ln, i: Integer;
    cht, ch: string;
    Res: string;

  begin
    Result := '';
    ln := Length(acc);
    if ln <= 1 then begin
      Result := acc;
      exit;
    end else begin
      if (acc[1] = '&') and (acc[ln] = ';') then begin
        ch := Copy(acc, 2, 1);
        Res := '';
        for i := 128 to 255 do begin
          cht := Copy(CharTable[i], 2, 1);
          if (CompareStr(lowercase(CharTable[i]), lowercase(acc)) = 0) then begin
            if (cht = ch) then begin
              Result := chr(i);
              exit;
            end else begin
              Res := chr(i);
            end;
          end;
        end;
        if Res <> '' then begin
          if AnsiLowerCase(ch) = ch then
            Result := AnsiLowerCase(Res)
          else
            Result := AnsiUpperCase(Res);
        end else
          Result := acc;
      end;
    end;

  end;

var
  org, trg, tln, ln: Integer;
  acc: string;
begin
  ln := Length(str);
  SetLength(Result, ln);

  org := 1; trg := 0;

  while org <= ln do begin
    inc(trg);
    if str[org] = '&' then begin
      tln := PosL(org + 1, ';', str);
      if (tln <> 0) and (tln - org <= 10) then begin
        acc := Copy(str, org, tln - org + 1);
        acc := AccCharToNormal(acc);
        CopyMem(@Result[trg], @acc[1], Length(acc));
        inc(trg, Length(acc) - 1);
        org := tln + 1;
        continue;
      end;
    end;

    Result[trg] := str[org];
    inc(org);
  end;

  SetLength(Result, trg);
end;

function ToHTMLColor(tcol: TColor): string;
var
  tmpRGB: TColorRef;
begin
  tmpRGB := ColorToRGB(tcol);
  Result := Format('#%.2x%.2x%.2x',
    [GetRValue(tmpRGB), GetGValue(tmpRGB), GetBValue(tmpRGB)]);
end;

var
  Timezone:  TIME_ZONE_INFORMATION;
initialization
  GetTimeZoneInformation(TimeZone);
  Time_ZoneC := (Timezone.Bias*60);  
  DefaultShsFormat;
end.

