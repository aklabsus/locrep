// AKTools akGraph unit.
//         Модуль, содержащий функции по работе с графикой.
//=============================================================================

unit akGraph;

interface

uses Windows, SysUtils, Graphics, jpeg, Classes;

type
  TAlignment = (taLeftJustify, taRightJustify, taCenter);
  TVertAlignment = (vaTopJustify, vaCenter, vaBottomJustify);

  COLOR16 = Word;

  PTriVertex = ^TTriVertex;
  _TRIVERTEX = packed record
    x: Longint;
    y: Longint;
    Red: COLOR16;
    Green: COLOR16;
    Blue: COLOR16;
    Alpha: COLOR16;
  end;
  TTriVertex = _TRIVERTEX;
  TRIVERTEX = _TRIVERTEX;

{ - Градиентное заполнение. }
function GradientFill(DC: HDC; var p2: TTriVertex;
  p3: ULONG; p4: Pointer; p5, p6: ULONG): BOOL;

procedure GradientRect(DC: HDC; const Rect: TRect;
  StartColor, EndColor: TColor; HorizDir: Boolean);

procedure EffectATriangle(hndl: THandle; r: TRect; br: TColor);
procedure EffectARect(hndl: THandle; r: TRect; br: TColor; tcl: TColor= clWhite);
procedure GradientTriangle(DC: HDC; const Rect: TRect; StartColor, EndColor: TColor);

  // Возвращает размер картинки (Dmitry Kudinov)
procedure GetBitmapSize(Bitmap: HBitmap; var Size: TSize);

  // Выводит в DC битмэп (Dmitry Kudinov)
procedure DrawImage(DC: HDC; Bitmap: HBitmap; Size: TSize; X, Y: integer; IsTransparent: boolean = false);

  // (Dmitry Kudinov)
procedure DrawTitleImage(DC: HDC; Bitmap: HBitmap; R: TRect; Width, Height: integer);

  // Рисует кнопку (Dmitry Kudinov)
procedure DrawButton(DC: HDC; R: TRect);

 // Сохраняет указнную область экрана в JPEG.
function Screen2Jpeg(R: TRect): TJpegImage;

 // Рисует текст, выровненный указанным образом
procedure DrawTextWrap(DC: HDC; const Text: string; ClipRect: TRect;
  HAlign: TAlignment; VAlign: TVertAlignment; Trans: boolean);

function TextToLinesDC(DC: HDC; const Text: string; MaxLen: integer): string;
function TextSizeDC(DC: HDC; const Text: string): TSize;

function MakeRect(x, y, x1, y1: Integer): TRect;

// возвращает цвет org после альфаблендинга на указанный AlphaLevel.
function ModifyAColor(org, trg: TColor; alpha: Integer): Integer;

implementation

uses akMisc, akStrUtils, akDataUtils, StrUtils;

var GradFillLib: THandle;

procedure GradientTriangle(DC: HDC; const Rect: TRect;
  StartColor, EndColor: TColor);
var
  vert: array[0..2] of TRIVERTEX;
  gRect: GRADIENT_TRIANGLE;

const
  Direction: array[Boolean] of DWORD =
  (GRADIENT_FILL_RECT_V, GRADIENT_FILL_RECT_H);
begin
  vert[0].x := Rect.Left;
  vert[0].y := Rect.Top;
  vert[0].Red := GetRValue(StartColor) shl 8;
  vert[0].Green := GetGValue(StartColor) shl 8;
  vert[0].Blue := GetBValue(StartColor) shl 8;
  vert[0].Alpha := $0000;

  vert[1].x := Rect.Right;
  vert[1].y := Rect.Top;
  vert[1].Red := GetRValue(StartColor) shl 8;
  vert[1].Green := GetGValue(StartColor) shl 8;
  vert[1].Blue := GetBValue(StartColor) shl 8;
  vert[1].Alpha := $0000;

  vert[2].x := Rect.Right;
  vert[2].y := Rect.Bottom;
  vert[2].Red := GetRValue(EndColor) shl 8;
  vert[2].Green := GetGValue(EndColor) shl 8;
  vert[2].Blue := GetBValue(EndColor) shl 8;
  vert[2].Alpha := $0000;

  gRect.Vertex1 := 0;
  gRect.Vertex2 := 1;
  gRect.Vertex3 := 2;

  GradientFill(DC, vert[0], 3, @gRect, 1, GRADIENT_FILL_TRIANGLE);
end;

procedure EffectARect(hndl: THandle; r: TRect; br: TColor; tcl: TColor);
var hgh: Integer;
begin
  hgh := Trunc((R.Bottom-r.Top)/3);
  GradientRect(hndl, Rect(r.Left, R.Top, R.Right, r.Top + hgh),
    ModifyAColor(br, tcl, 250), ModifyAColor(br, tcl, 120), false);
  GradientRect(hndl, Rect(R.Left, r.Top + hgh, R.Right, R.Bottom),
    br, ModifyAColor(br, tcl, 220), false);
end;

procedure EffectATriangle(hndl: THandle; r: TRect; br: TColor);
var ex1,ex2: Integer;
begin
  GradientTriangle(hndl, Rect(r.Left, R.Top, R.Right, R.Bottom),
    ModifyAColor(br, clWhite, 250), br);

  if R.Left<R.Right then begin
    ex1 := R.Left+trunc(abs(R.Right-R.Left)/3);
    ex2 := R.Right;
  end else begin
    ex1 := R.Left-trunc(abs(R.Right-R.Left)/3);
    ex2 := R.Right;
  end;

  GradientTriangle(hndl, Rect(ex1, Trunc(r.Bottom / 3), ex2, R.Bottom),
    br, ModifyAColor(br, clWhite, 220));
end;

function ModifyAColor(org, trg: TColor; alpha: Integer): Integer;
var i, j: integer;
  AlphaLevel: Integer;
  Color: TColor;
  SrcRValue, SrcGValue, SrcBValue: Integer;
  DstRValue, DstGValue, DstBValue: Integer;
begin
  SrcRValue := GetRValue(trg) * alpha;
  SrcGValue := GetGValue(trg) * alpha;
  SrcBValue := GetBValue(trg) * alpha;

  DstRValue := (SrcRValue + GetRValue(org) * (256 - alpha)) div 256;
  DstGValue := (SrcGValue + GetGValue(org) * (256 - alpha)) div 256;
  DstBValue := (SrcBValue + GetBValue(org) * (256 - alpha)) div 256;
  Result := RGB(DstRValue, DstGValue, DstBValue);
end;

function MakeRect(x, y, x1, y1: Integer): TRect;
begin
  with Result do
  begin
    Left := x;
    Top := y;
    Right := x1;
    Bottom := y1;
  end;
end;

function Screen2Jpeg(R: TRect): TJpegImage;
var
  B: TBitmap;
  DC: HDC;
begin
  DC := GetDC(GetDesktopWindow);
  try
    B := TBitmap.Create;
    try
      B.Width := R.Right - R.Left;
      B.Height := R.Bottom - R.Top;
      BitBlt(B.Canvas.Handle, 0, 0, B.Width, B.Height, DC,
        R.Left, R.Top, SRCCOPY);
      Result := TJPegImage.Create;
      Result.Assign(B);
    finally
      b.Free;
    end;
  finally
    ReleaseDC(GetDesktopWindow, DC);
  end;
end;

procedure GetBitmapSize(Bitmap: HBitmap; var Size: TSize);
var
  BMP: Windows.TBitmap;
begin
  Size.cx := 0; Size.cy := 0;
  if Bitmap <> 0 then
  begin
    if GetObject(Bitmap, SizeOf(Windows.TBitmap), @BMP) = SizeOf(Windows.TBitmap) then
    begin
      Size.cx := BMP.bmWidth; Size.cy := BMP.bmHeight;
    end;
  end;
end;

procedure DrawImage(DC: HDC; Bitmap: HBitmap; Size: TSize; X, Y: integer; IsTransparent: boolean);
var
  CompDC: HDC;
  Save: THandle;
begin
  CompDC := CreateCompatibleDC(DC);
  Save := SelectObject(CompDC, Bitmap);
  if not IsTransparent then
  begin
    BitBlt(DC, X, Y, Size.cx, Size.cy, CompDC, 0, 0, SRCCOPY);
  end
  else
  begin
  end;
  SelectObject(CompDC, Save);
  DeleteDC(CompDC);
end;

procedure DrawTitleImage(DC: HDC; Bitmap: HBitmap; R: TRect; Width, Height: integer);
var
  CompDC: HDC;
  Save: THandle;
  i, j, _x, _y: integer;
begin
  if (Width = 0) or (Height = 0) then exit;
  _x := (R.Right - R.Left) div Width + 1;
  _y := (R.Bottom - R.Top) div Height + 1;
  with R do
    IntersectClipRect(DC, Left, Top, Right, Bottom);
  CompDC := CreateCompatibleDC(DC);
  Save := SelectObject(CompDC, Bitmap);
  for i := 0 to _x - 1 do
    for j := 0 to _y - 1 do
      BitBlt(DC, R.Left + i * Width, R.Top + j * Height, R.Right - R.Left + 1, R.Bottom - R.Top + 1, CompDC, 0, 0, SRCCOPY);
  SelectObject(CompDC, Save);
  ExcludeClipRect(DC, 0, 0, 0, 0);
  DeleteDC(CompDC);
end;


procedure DrawButton(DC: HDC; R: TRect);
var
  OldBrush: HBrush;
  OldPen: HPen;
begin
  with R do
  begin
    OldBrush := SelectObject(DC, GetStockObject(LTGRAY_BRUSH));
    OldPen := SelectObject(DC, CreatePen(PS_SOLID, 1, clLtGray));
    try
      Rectangle(DC, Left, Top, Right, Bottom);
      dec(R.Right); dec(R.Bottom); inc(R.Left);
      MoveToEx(DC, Left, Bottom, nil);
      LineTo(DC, Right, Bottom);
      LineTo(DC, Right, Top);
      SelectObject(DC, CreatePen(ps_Solid, 1, clDkGray));
      MoveToEx(DC, Left + 1, Bottom - 1, nil);
      LineTo(DC, Right - 1, Bottom - 1);
      LineTo(DC, Right - 1, Top + 1);
      DeleteObject(SelectObject(DC, GetStockObject(WHITE_PEN)));
      MoveToEx(DC, Left + 1, Bottom - 2, nil);
      LineTo(DC, Left + 1, Top + 1);
      LineTo(DC, Right - 2, Top + 1);
    finally
      SelectObject(DC, OldBrush);
      SelectObject(DC, OldPen);
    end;
  end;
end;


procedure DrawTextWrap(DC: HDC; const Text: string; ClipRect: TRect;
  HAlign: TAlignment; VAlign: TVertAlignment; Trans: boolean);
const
  HorzAl: array[TAlignment] of integer = (DT_LEFT, DT_RIGHT, DT_CENTER);
var
  s: string;
  dy: integer;
begin
  s := TextToLinesDC(DC, Text, WidthOf(ClipRect));
  dy := (HeightOf(ClipRect) - (TextSizeDC(DC, s).cy * WordCount(s, [#13]))) div 2;
  if dy < 0 then dy := 0;
  case VAlign of
    vaTopJustify: ;
    vaCenter:
      begin
        inc(ClipRect.Top, dy); dec(ClipRect.Bottom, dy);
      end;
    vaBottomJustify:
      inc(ClipRect.Top, dy * 2);
  end;
  if Trans then
    SetBkMode(DC, TRANSPARENT)
  else
    SetBkMode(DC, OPAQUE);
  DrawText(DC, PChar(s), length(s), ClipRect, HorzAl[HAlign]);
end;

function TextToLinesDC(DC: HDC; const Text: string; MaxLen: integer): string;
var
  i: integer;
  s, w, CurStr: string;
begin
  Result := ''; s := ''; CurStr := '';
  for i := 1 to WordCount(Text, [' ']) do
  begin
    w := ExtractWord(i, Text, [' ']);
    s := CurStr + iif(length(CurStr) > 0, ' ', '') + w;
    if length(CurStr) > 0 then
      if TextSizeDC(DC, s).cx > MaxLen then
      begin
        if length(Result) > 0 then Result := Result + #13#10;
        Result := Result + CurStr;
        CurStr := w;
        continue;
      end;
    CurStr := s;
  end;
  if length(CurStr) > 0 then
  begin
    if length(Result) > 0 then Result := Result + #13#10;
    Result := Result + CurStr;
  end;
end;

function TextSizeDC(DC: HDC; const Text: string): TSize;
begin
  GetTextExtentPoint32(DC, PChar(Text), length(Text), Result);
end;

procedure GradientRect(DC: HDC; const Rect: TRect;
  StartColor, EndColor: TColor; HorizDir: Boolean);
var
  vert: array[0..1] of TRIVERTEX;
  gRect: GRADIENT_RECT;
const
  Direction: array[Boolean] of DWORD =
  (GRADIENT_FILL_RECT_V, GRADIENT_FILL_RECT_H);
begin
  StartColor := ColorToRGB(StartColor);
  EndColor := ColorToRGB(EndColor);


  vert[0].x := Rect.Left;
  vert[0].y := Rect.Top;
  vert[0].Red := GetRValue(StartColor) shl 8;
  vert[0].Green := GetGValue(StartColor) shl 8;
  vert[0].Blue := GetBValue(StartColor) shl 8;
  vert[0].Alpha := $0000;


  vert[1].x := Rect.Right;
  vert[1].y := Rect.Bottom;
  vert[1].Red := GetRValue(EndColor) shl 8;
  vert[1].Green := GetGValue(EndColor) shl 8;
  vert[1].Blue := GetBValue(EndColor) shl 8;
  vert[1].Alpha := $0000;


  gRect.UpperLeft := 0;
  gRect.LowerRight := 1;
  GradientFill(DC, vert[0], 2, @gRect, 1, Direction[HorizDir]);
end;


function GradientFill(DC: HDC; var p2: TTriVertex; p3: ULONG; p4: Pointer; p5, p6: ULONG): BOOL;
type
  Tvert = array[0..1] of TRIVERTEX;
  Pvert = ^Tvert;
const
  GradientFuncAdr: function(DC: HDC; var p2: TTriVertex; p3: ULONG; p4: Pointer; p5, p6: ULONG): BOOL; stdcall = nil;
var
  vert: PVert;
  cl: TColor;
  rct: TRect;
begin
  if GradFillLib = 0 then
    GradFillLib := LoadLibrary('msimg32.dll');
  if (GradFillLib <> 0) and (@GradientFuncAdr = nil) then
    @GradientFuncAdr := GetProcAddress(GradFillLib, 'GradientFill');
  if @GradientFuncAdr <> nil then
    Result := GradientFuncAdr(DC, p2, p3, p4, p5, p6)
  else begin
    vert := @p2;
    cl := RGB(p2.Red shr 8, p2.Green shr 8, p2.Blue shr 8);
    rct := MakeRect(vert^[0].x, vert^[0].y, vert^[1].x, vert^[1].y);

    FillRect(dc, rct, CreateSolidBrush(cl));
  end;
end;


initialization
  GradFillLib := 0;
finalization
  if GradFillLib <> 0 then
    FreeLibrary(GradFillLib);
end.

