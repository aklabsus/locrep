(*==========================================================================*
 | unitEXGraphics                                                           |
 |                                                                          |
 | Provides extended cursor and icon graphic objects that support 256       |
 | colors, etc.                                                             |
 |                                                                          |
 | Version  Date        By    Description                                   |
 | -------  ----------  ----  --------------------------------------------- |
 | 2.0      23/2/2000   CPWW  Original                                      |
 *==========================================================================*)

unit unitEXGraphics;

interface

uses Windows, Sysutils, Classes, Graphics, clipbrd, commctrl, controls;

type

//=============================================================================
// TIconHeader resource structure - corresponds to NEWHEADER in MSDN and contains
// the details for a Icon or Cursor group resource
TIconHeader = packed record
  wReserved : word;
  wType  : word;       // 1 for icons
  wCount : word;       // Number of components
end;
PIconHeader = ^TIconHeader;

//=============================================================================
// TExIconImage class - Shared image structure for icons & cursors
TExIconImage = class (TSharedImage)
  FHandle: HICON;
  FMemoryImage: TCustomMemoryStream;
protected
  procedure FreeHandle; override;
public
  destructor Destroy; override;
end;

//=============================================================================
// TIconCursor class - Base graphic class for TExIcon & TExCursor
TIconCursor = class (TGraphic)
private
  FIcon: TIcon;
  FImage: TExIconImage;
  fPixelFormat : TPixelFormat;
  fWidth, fHeight : Integer;
  fPalette : HPALETTE;
  fBitmapOffset : DWORD;    // 0 for icons.  4 for cursors.
  fHotspot : DWORD;         // Icons don't have hotspots!, but it's easier to
                            // put it here

  function GetHandle: HICON;
  procedure NewImage(NewHandle: HICON; NewImage: TMemoryStream);
  procedure SetHandle(const Value: HICON);
  procedure SetPixelFormat(const Value: TPixelFormat);
  function GetPixelFormat: TPixelFormat;
  function GetColorCount: Integer;
  function GetBitsPerPixel: Integer;
  function GetIcon: TIcon;
protected
  procedure HandleNeeded; virtual; abstract;
  procedure ImageNeeded; virtual; abstract;
  function GetEmpty: Boolean; override;
  function GetWidth : Integer; override;
  function GetHeight : Integer; override;
  procedure SetWidth (value : Integer); override;
  procedure SetHeight (value : Integer); override;
  procedure Draw(ACanvas: TCanvas; const Rect: TRect); override;
  function GetPalette : HPALETTE; override;

public
  constructor Create; override;
  destructor Destroy; override;
  procedure Assign (source : TPersistent); override;
  procedure LoadFromClipboardFormat(AFormat: Word; AData: THandle; APalette: HPALETTE); override;
  procedure LoadFromStream(Stream: TStream); override;
  function ReleaseHandle: HICON;
  procedure SaveToClipboardFormat(var Format: Word; var Data: THandle; var APalette: HPALETTE); override;
  procedure SaveToStream(Stream: TStream); override;
  property Handle: HICON read GetHandle write SetHandle;
  property PixelFormat : TPixelFormat read GetPixelFormat write SetPixelFormat;
  property ColorCount : Integer read GetColorCount;
  property BitsPerPixel : Integer read GetBitsPerPixel;
  property Icon: TIcon read GetIcon;
end;

//=============================================================================
// TExIcon class
TExIcon = class (TIconCursor)
protected
  procedure HandleNeeded; override;
  procedure ImageNeeded; override;
public
  constructor Create; override;
end;

//=============================================================================
// TExCursor class
TExCursor = class (TIconCursor)
private
  function GetHotspot: DWORD;
  procedure SetHotspot(const Value: DWORD);
protected
  procedure HandleNeeded; override;
  procedure ImageNeeded; override;
public
  constructor Create; override;
  property Hotspot : DWORD read GetHotspot write SetHotspot;
end;

var
  SystemPalette256 : HPALETTE;
  SystemPalette2 : HPALETTE;

type
  TReal = single;
  EColorError = exception;

const
  HLSMAX = 240;

function CreateDIBPalette (const bmi : TBitmapInfo) : HPalette;
function CreateMappedBitmap (source : TBitmap; palette : HPALETTE; hiPixelFormat : TPixelFormat) : TBitmap;
procedure AssignBitmapFromIconCursor (dst : TBitmap; src : TIconCursor; transparentColor : TColor);
procedure AssignIconCursorFromBitmap (dst : TIconCursor; source : TBitmap; palette : HPALETTE; transparentColor : TColor);
procedure iHLSToRGB (hue, lum, sat : Integer; var r, g, b : Integer);

implementation

resourceString
  rstInvalidIcon        = 'Invalid Icon or Cursor';
  rstInvalidBitmap      = 'Invalid Bitmap';
  rstInvalidPixelFormat = 'Pixel Format Not Valid for Icons or Cursors';
  rstNoClipboardSupport = 'Clipboard not supported for Icons or Cursors';
  rstCantResize         = 'Can''t resize Icons or Cursors';
  rstCantReformat       = 'Can''t change PixelFormat for Icons or Cursors';

(*----------------------------------------------------------------------------*
 | procedure InitializeBitmapInfoHeader ()                                    |
 |                                                                            |
 | Stolen from graphics.pas                                                   |
 *----------------------------------------------------------------------------*)
procedure InitializeBitmapInfoHeader(Bitmap: HBITMAP; var BI: TBitmapInfoHeader;
  Colors: Integer);
var
  DS: TDIBSection;
  Bytes: Integer;
begin
  DS.dsbmih.biSize := 0;
  Bytes := GetObject(Bitmap, SizeOf(DS), @DS);
  if Bytes = 0 then raise EInvalidGraphic.Create (rstInvalidBitmap)
  else if (Bytes >= (sizeof(DS.dsbm) + sizeof(DS.dsbmih))) and
    (DS.dsbmih.biSize >= DWORD(sizeof(DS.dsbmih))) then
    BI := DS.dsbmih
  else
  begin
    FillChar(BI, sizeof(BI), 0);
    with BI, DS.dsbm do
    begin
      biSize := SizeOf(BI);
      biWidth := bmWidth;
      biHeight := bmHeight;
    end;
  end;
  case Colors of
    1,2: BI.biBitCount := 1;
    3..16   :
      begin
        BI.biBitCount := 4;
        BI.biClrUsed := Colors
      end;
    17..256 :
      begin
        BI.biBitCount := 8;
        BI.biClrUsed := Colors
      end;
  else
    BI.biBitCount := DS.dsbm.bmBitsPixel * DS.dsbm.bmPlanes;
  end;
  BI.biPlanes := 1;
  if BI.biClrImportant > BI.biClrUsed then
    BI.biClrImportant := BI.biClrUsed;
  if BI.biSizeImage = 0 then
    BI.biSizeImage := BytesPerScanLine(BI.biWidth, BI.biBitCount, 32) * Abs(BI.biHeight);
end;

(*----------------------------------------------------------------------------*
 | procedure InternalGetDIBSizes ()                                           |
 |                                                                            |
 | Stolen from graphics.pas                                                   |
 *----------------------------------------------------------------------------*)
procedure InternalGetDIBSizes(Bitmap: HBITMAP; var InfoHeaderSize: DWORD;
  var ImageSize: DWORD; Colors: Integer);
var
  BI: TBitmapInfoHeader;
begin
  InitializeBitmapInfoHeader(Bitmap, BI, Colors);
  if BI.biBitCount > 8 then
  begin
    InfoHeaderSize := SizeOf(TBitmapInfoHeader);
    if (BI.biCompression and BI_BITFIELDS) <> 0 then
      Inc(InfoHeaderSize, 12);
  end
  else
    if BI.biClrUsed = 0 then
      InfoHeaderSize := SizeOf(TBitmapInfoHeader) +
        SizeOf(TRGBQuad) * (1 shl BI.biBitCount)
    else
      InfoHeaderSize := SizeOf(TBitmapInfoHeader) +
        SizeOf(TRGBQuad) * BI.biClrUsed;
  ImageSize := BI.biSizeImage;
end;

(*----------------------------------------------------------------------------*
 | procedure InternalGetDIB ()                                                |
 |                                                                            |
 | Stolen from graphics.pas                                                   |
 *----------------------------------------------------------------------------*)
function InternalGetDIB(Bitmap: HBITMAP; Palette: HPALETTE;
  var BitmapInfo; var Bits; Colors: Integer): Boolean;
var
  OldPal: HPALETTE;
  DC: HDC;
begin
  InitializeBitmapInfoHeader(Bitmap, TBitmapInfoHeader(BitmapInfo), Colors);
  OldPal := 0;
  DC := CreateCompatibleDC(0);
  try
    if Palette <> 0 then
    begin
      OldPal := SelectPalette(DC, Palette, False);
      RealizePalette(DC);
    end;
    Result := GetDIBits(DC, Bitmap, 0, TBitmapInfoHeader(BitmapInfo).biHeight, @Bits,
      TBitmapInfo(BitmapInfo), DIB_RGB_COLORS) <> 0;
  finally
    if OldPal <> 0 then SelectPalette(DC, OldPal, False);
    DeleteDC(DC);
  end;
end;


(*----------------------------------------------------------------------------*
 | procedure CreateDIBPalette ()                                              |
 |                                                                            |
 | Create the palette from bitmap resource info.                              |
 *----------------------------------------------------------------------------*)
function CreateDIBPalette (const bmi : TBitmapInfo) : HPalette;
var
  lpPal : PLogPalette;
  i : Integer;
  numColors : Integer;
begin
  result := 0;

  if bmi.bmiHeader.biBitCount <= 8 then
    NumColors := 1 shl bmi.bmiHeader.biBitCount
  else
    NumColors := 0;  // No palette needed for 24 BPP DIB

  if bmi.bmiHeader.biClrUsed > 0 then
    NumColors := bmi.bmiHeader.biClrUsed;  // Use biClrUsed

  if NumColors > 0 then
  begin
    if NumColors = 1 then
      result := CopyPalette (SystemPalette2)
    else
    begin
      GetMem (lpPal, sizeof (TLogPalette) + sizeof (TPaletteEntry) * NumColors);
      try
        lpPal^.palVersion    := $300;
        lpPal^.palNumEntries := NumColors;

  {$R-}
        for i := 0 to NumColors -1 do
        begin
          lpPal^.palPalEntry[i].peRed  := bmi.bmiColors [i].rgbRed;
          lpPal^.palPalEntry[i].peGreen  := bmi.bmiColors[i].rgbGreen;
          lpPal^.palPalEntry[i].peBlue  := bmi.bmiColors[i].rgbBlue;
          lpPal^.palPalEntry[i].peFlags := 0 //bmi.bmiColors[i].rgbReserved;
        end;
  {$R+}
        result :=  CreatePalette (lpPal^)
      finally
        FreeMem (lpPal)
      end
    end
  end
end;

(*----------------------------------------------------------------------------*
 | procedure ReadIcon ()                                                      |
 |                                                                            |
 | Creates an HIcon and a HPalette from a icon resource stream.               |
 *----------------------------------------------------------------------------*)
procedure ReadIcon(Stream: TStream; var Icon: HICON; var palette : HPALETTE; isIcon : boolean);
var
  buffer : PByte;
  info : PBitmapInfoHeader;
  size, offset : DWORD;
begin
  size := stream.Size - stream.Position;

  if IsIcon then        // Cursor resources have DWORD hotspot before the BitmapInfo
    offset := 0
  else
    offset := sizeof (DWORD);

  if size > sizeof (TBitmapInfoHeader) + offset then
  begin
    GetMem (buffer, stream.Size - stream.Position);
    try
      stream.ReadBuffer (buffer^, stream.Size - stream.Position);

      info := PBitmapInfoHeader (PChar (buffer) + offset);

      icon := CreateIconFromResourceEx (buffer, size, isIcon, $00030000, info^.biWidth, info^.biHeight div 2, LR_DEFAULTCOLOR);

(*
      dc := GetDC (HWND_DESKTOP);
      try
        DrawIconEx (dc, 0, 0, icon, info^.biWidth, info^.biHeight div 2, 0, 0, DI_NORMAL)
      finally
        ReleaseDC (0, dc)
      end;
*)

      if icon = 0 then raise EInvalidGraphic.Create (rstInvalidIcon);
      palette := CreateDIBPalette (PBitmapInfo (PChar (buffer) + offset)^);
    finally
      FreeMem (buffer)
    end
  end
end;


(*----------------------------------------------------------------------------*
 | procedure WriteIcon ()                                                     |
 |                                                                            |
 | Write an icon to a stream.  Pass in the color count, rather than getting   |
 | it from the color bitmap - the chances are we already know it.             |
 *----------------------------------------------------------------------------*)
procedure WriteIcon(Stream: TStream; Icon: HICON; colors : Integer; isIcon : boolean);
var
  IconInfo: TIconInfo;
  MonoInfoSize, ColorInfoSize: DWORD;
  MonoBitsSize, ColorBitsSize: DWORD;
  MonoInfo, MonoBits, ColorInfo, ColorBits: Pointer;
  cursorHotspot : DWORD;
begin
  GetIconInfo(Icon, IconInfo);
  cursorHotspot := MAKELONG (IconInfo.xHotspot, IconInfo.yHotspot);
  try
    InternalGetDIBSizes(IconInfo.hbmMask, MonoInfoSize, MonoBitsSize, 2);
    InternalGetDIBSizes(IconInfo.hbmColor, ColorInfoSize, ColorBitsSize, colors);

    MonoInfo := nil;
    MonoBits := nil;
    ColorInfo := nil;
    ColorBits := nil;
    try
      MonoInfo := AllocMem(MonoInfoSize);
      MonoBits := AllocMem(MonoBitsSize);
      ColorInfo := AllocMem(ColorInfoSize);
      ColorBits := AllocMem(ColorBitsSize);
      InternalGetDIB(IconInfo.hbmMask, 0, MonoInfo^, MonoBits^, 2);
      InternalGetDIB(IconInfo.hbmColor, 0, ColorInfo^, ColorBits^, colors);

      with PBitmapInfoHeader(ColorInfo)^ do
        Inc(biHeight, biHeight); { color height includes mono bits }

      if not isIcon then
        Stream.Write (cursorHotspot, sizeof (cursorHotspot));

      Stream.Write(ColorInfo^, ColorInfoSize);
      Stream.Write(ColorBits^, ColorBitsSize);
      Stream.Write(MonoBits^, MonoBitsSize);
    finally
      FreeMem(ColorInfo, ColorInfoSize);
      FreeMem(ColorBits, ColorBitsSize);
      FreeMem(MonoInfo, MonoInfoSize);
      FreeMem(MonoBits, MonoBitsSize);
    end;
  finally
    DeleteObject(IconInfo.hbmColor);
    DeleteObject(IconInfo.hbmMask);
  end
end;


(*----------------------------------------------------------------------------*
 | procedure AssignBitmapFromIconCursor                                       |
 |                                                                            |
 | Copy an icon to a bitmap.  Where the icon is transparent, set the bitmap   |
 | to 'transparentColor'                                                      |
 *----------------------------------------------------------------------------*)
procedure AssignBitmapFromIconCursor (dst : TBitmap; src : TIconCursor; transparentColor : TColor);
var
  r : TRect;
begin
  dst.Assign (Nil);
  dst.Width := src.Width;
  dst.Height := src.Height;
  dst.PixelFormat := pfDevice;

  with dst.Canvas do
  begin
    brush.Color := GetNearestColor (Handle, transparentColor);
    r := Rect (0, 0, dst.Width, dst.Height);
    FillRect (r);
    Draw (0, 0, src)
  end
end;

(*----------------------------------------------------------------------------*
 | procedure MaskBitmapBits                                                   |
 |                                                                            |
 | Kinda like MaskBlt - but without the bugs.                                 |
 *----------------------------------------------------------------------------*)
procedure MaskBitmapBits (bits : PChar; pixelFormat : TPixelFormat; mask : PChar; width, height : DWORD; palette : HPalette);
var
  bpScanline, maskbpScanline : Integer;
  bitsPerPixel, i, j : Integer;
  maskbp, bitbp : byte;
  maskp, bitp : PChar;
  maskPixel : boolean;
  maskByte: dword;
  maskU : UINT;
  maskColor : byte;
  maskColorByte : byte;
begin
                                       // Get 'black' color index.  This is usually 0
                                       // but some people play jokes...

  if palette <> 0 then
  begin
    maskU := GetNearestPaletteIndex (palette, RGB (0, 0, 0));
    if maskU = CLR_INVALID then
      raiseLastWin32Error;

    maskColor := maskU
  end
  else
    maskColor := 0;

  case PixelFormat of                  // Get bits per pixel
    pf1Bit : bitsPerPixel := 1;
    pf4Bit : bitsPerPixel := 4;
    pf8Bit : bitsPerPixel := 8;
    pf15Bit,
    pf16Bit : bitsPerPixel := 16;
    pf24Bit : bitsPerPixel := 24;
    pf32Bit : bitsPerPixel := 32;
    else
      raise EInvalidGraphic.Create (rstInvalidPixelFormat);
  end;

                                       // Get byte count for mask and bitmap
                                       // scanline.  Can be weird because of padding.
  bpScanline := BytesPerScanLine(width, bitsPerPixel, 32);
  maskbpScanline := BytesPerScanline (width, 1, 32);

  maskByte := $ffffffff;                     // Set constant values for 8bpp masks
  maskColorByte := maskColor;

  for i := 0 to height - 1 do          // Go thru each scanline...
  begin

    maskbp := 0;                       // Bit offset in current mask byte
    bitbp := 0;                        // Bit offset in current bitmap byte
    maskp := mask;                     // Pointer to current mask byte
    bitp := bits;                      // Pointer to current bitmap byte;

    for j := 0 to width - 1 do         // Go thru each pixel
    begin
                                       // Pixel should be masked?
      maskPixel := (byte (maskp^) and ($80 shr maskbp)) <> 0;
      if maskPixel then
      begin
        case bitsPerPixel of
          1, 4, 8 :
            begin
              case bitsPerPixel of           // Calculate bit mask and 'black' color bits
                1 :
                  begin
                    maskByte := $80 shr bitbp;
                    maskColorByte := maskColor shl (7 - bitbp);
                  end;

                4 :
                  begin
                    maskByte := $f0 shr bitbp;
                    maskColorByte := maskColor shl (4 - bitbp)
                  end
              end;
                                             // Apply the mask
              bitp^ := char ((byte (bitp^) and (not maskByte)) or maskColorByte);
            end;

          15, 16 :
            PWORD (bitp)^ := 0;

          24 :
            begin
              PWORD (bitp)^ := 0;
              PBYTE (bitp + sizeof (WORD))^ := 0
            end;

          32 :
            PDWORD (bitp)^ := 0
        end
      end;

      Inc (maskbp);                    // Next mask bit
      if maskbp = 8 then
      begin
        maskbp := 0;
        Inc (maskp)                    // Next mask byte
      end;

      Inc (bitbp, bitsPerPixel);       // Next bitmap bit(s)
      while bitbp >= 8 do
      begin
        Dec (bitbp, 8);
        Inc (bitp)                     // Next bitmap byte
      end
    end;

    Inc (mask, maskbpScanline);        // Set mask for start of next line
    Inc (bits, bpScanLine)             // Set bits to start of next line
  end
end;

(*----------------------------------------------------------------------------*
 | procedure CreateMappedBitmap                                               |
 |                                                                            |
 | Copy a bitmap and apply a palette.                                         |
 *----------------------------------------------------------------------------*)
function CreateMappedBitmap (source : TBitmap; palette : HPALETTE; hiPixelFormat : TPixelFormat) : TBitmap;
var
  colorCount : word;
begin
  result := TBitmap.Create;
  if palette <> 0 then
  begin
    result.Width := source.Width;
    result.Height := source.Height;

    if GetObject (palette, sizeof (colorCount), @colorCount) = 0 then
      RaiseLastWin32Error;

    case colorCount of
      1..2    : result.PixelFormat := pf1Bit;
      3..16   : result.PixelFormat := pf4Bit;
      17..256 : result.PixelFormat := pf8Bit;
      else
        result.PixelFormat := source.PixelFormat
    end;

    result.Palette := CopyPalette (palette);
    result.Canvas.Draw (0, 0, source);
  end
  else
  begin
    result.PixelFormat := hiPixelFormat;
    result.Height := source.Height;
    result.Width := source.Width;
    result.Canvas.Draw (0, 0, source);
  end
end;


(*----------------------------------------------------------------------------*
 | procedure AssignIconCursorFromBitmap                                       |
 |                                                                            |
 | Copy a bitmap to an icon using the correct palette.  Where the bitmap      |
 | matches the transparent color,                                             |
 | make the icon transparent.                                                 |
 *----------------------------------------------------------------------------*)
procedure AssignIconCursorFromBitmap (dst : TIconCursor; source : TBitmap; palette : HPALETTE; transparentColor : TColor);
var
  maskBmp : TBitmap;
  infoHeaderSize, imageSize : DWORD;
  maskInfoHeaderSize, maskImageSize : DWORD;
  maskInfo, maskBits : PChar;
  strm : TMemoryStream;
  offset : DWORD;
  src : TBitmap;

begin
  src := Nil;

  maskBmp := TBitmap.Create;

  try
    src := CreateMappedBitmap (source, palette, dst.PixelFormat);

    maskBmp.Assign (source);             // Get mask bitmap - White where the transparent color

    maskBmp.Mask (transparentColor);  // occurs, otherwise blck.
    maskBmp.PixelFormat := pf1Bit;
                                      // Get size for mask bits buffer
    GetDibSizes (maskBmp.Handle, maskInfoHeaderSize, maskImageSize);

    GetMem (maskBits, maskImageSize); // Allocate mask buffers
    GetMem (maskInfo, maskInfoHeaderSize);
    try
                                      // Get mask bits
      GetDib (maskBmp.Handle, 0, maskInfo^, maskBits^);

                                      // Get size for color bits buffer
      GetDibSizes (src.Handle, infoHeaderSize, imageSize);

                                      // Create a memory stream to assemble the icon image
      strm := TMemoryStream.Create;
      try
        if dst is TExCursor then
          offset := sizeof (DWORD)
        else
          offset := 0;
        strm.Size := infoHeaderSize + imageSize + maskImageSize + offset;

        GetDib (src.Handle, src.Palette, (PChar (strm.Memory) + offset)^, (PChar (strm.Memory) + infoHeaderSize + offset)^);
                                       // Get the bitmap header, palette & bits, then

        try
          with src do
            MaskBitmapBits (PChar (strm.Memory) + infoHeaderSize + offset, PixelFormat, maskBits, Width, Height, Palette)

        except
        end;
                                       // Apply the mask to the bitmap bits.  We can't use BitBlt (.. SrcAnd) because
                                       // of PRB Q149585

        Move (maskBits^, (PChar (strm.Memory) + infoHeaderSize + imageSize + offset)^, maskImageSize);
                                       // Tag on the mask.  We now have the correct icon bits

        with PBitmapInfo (PChar (strm.Memory) + offset)^.bmiHeader do
          biHeight := biHeight * 2;    // Adjust height for 'funky icon height' thing

        if dst is TExCursor then
          PDWORD (strm.Memory)^ := TExCursor (dst).Hotspot;

        dst.LoadFromStream (strm);
      finally
        strm.Free
      end
    finally
      FreeMem (maskInfo);
      FreeMem (maskBits);
    end
  finally
    maskBmp.Free;
    src.Free;
  end
end;

(*----------------------------------------------------------------------------*
 | procedure StrechDrawIcon                                                   |
 |                                                                            |
 | Why not use DrawIconEx??  Because it doesn't work.  This is from Joe Hecht |
 *----------------------------------------------------------------------------*)
procedure StretchDrawIcon(DC : HDC;
                          IconHandle : HIcon;
                          x : integer;
                          y : integer;
                          Width : integer;
                          Height : integer);
var
 IconInfo : TIconInfo;
 bmMaskInfo : Windows.TBitmap;
 maskDC : HDC;
 OldTextColor : TColor;
 OldBkColor : TColor;
 oldMaskBm : HBitmap;

  procedure DrawMonoIcon;
  var
    bmMaskInfobmHeightdiv2 : Integer;
  begin
    bmMaskInfobmHeightdiv2 := bmMaskInfo.bmHeight div 2;
    StretchBlt(DC, x, y, Width, Height, maskDC, 0, 0, bmMaskInfo.bmWidth, bmMaskInfobmHeightdiv2, SRCAND);
    StretchBlt(DC, x, y, Width, Height, maskDC, 0, bmMaskInfobmHeightdiv2, bmMaskInfo.bmWidth, bmMaskInfobmHeightdiv2, SRCINVERT)
  end;

  procedure DrawColorIcon;
  var
    bmColorInfo : Windows.TBitmap;
    colorDC : HDC;
    oldColorBm : HBITMAP;

  begin
    if (IconInfo.hbmColor <> 0) then
    begin
      GetObject(IconInfo.hbmColor, sizeof(bmColorInfo), @bmColorInfo);
      colorDC := CreateCompatibleDc(0);
      if colorDC <> 0 then
      try
        oldColorBm := SelectObject(colorDC, IconInfo.hbmColor);
        try
          TransparentStretchBlt (DC, x, y, Width, Height, colorDC, 0, 0, bmColorInfo.bmWidth, bmColorInfo.bmHeight, maskDC, 0, 0);
        finally
          SelectObject (colorDC, oldColorBm)
        end
      finally
        DeleteDC (colorDC)
      end
    end
  end;

begin  // StretchDrawIcon
  if GetIconInfo (IconHandle, IconInfo) then
  try
    if IconInfo.hbmMask <> 0 then
    begin
      OldTextColor := SetTextColor(DC, RGB (0, 0, 0));
      OldBkColor := SetBkColor(DC, RGB (255, 255, 255));

      GetObject(IconInfo.hbmMask, sizeof(bmMaskInfo), @bmMaskInfo);

      try
        maskDC := CreateCompatibleDC (0);

        if maskDC <> 0 then
        try
          oldMaskbm := SelectObject(maskDC, IconInfo.hbmMask);

          try
            if ((bmMaskInfo.bmBitsPixel * bmMaskInfo.bmPlanes = 1) and (IconInfo.hbmColor = 0)) then
              DrawMonoIcon
            else
              DrawColorIcon
          finally
            SelectObject (maskDC, oldMaskBm)
          end
        finally
          DeleteDC (maskDC)
        end
      finally
        SetTextColor(DC, OldTextColor);
        SetBkColor(DC, OldBkColor)
      end
    end
  finally
    if IconInfo.hbmMask <> 0 then DeleteObject (IconInfo.hbmMask);
    if IconInfo.hbmColor <> 0 then DeleteObject (IconInfo.hbmColor)
  end
end;

(*----------------------------------------------------------------------------*
 | function Create256ColorPalette;                                            |
 |                                                                            |
 | Does what it says on the tin..                                             |
 *----------------------------------------------------------------------------*)
function Create256ColorPalette : HPALETTE;
var
  dc : HDC;
  caps : Integer;
  logPalette : PLOGPALETTE;
  i : Integer;
  c : Integer;

const
  palColors256 : array [0..255] of TColor = (
    $000000, $000080, $008000, $008080, $800000, $800080, $808000, $C0C0C0,
    $5088B0, $B0C8E0, $00002C, $000056, $000087, $0000C0, $002C00, $002C2C,
    $002C56, $002C87, $002CC0, $002CFF, $005600, $00562C, $005656, $005687,
    $0056C0, $0056FF, $008700, $00872C, $008756, $008787, $0087C0, $0087FF,
    $00C000, $00C02C, $00C056, $00C087, $00C0C0, $00C0FF, $00FF2C, $00FF56,
    $00FF87, $00FFC0, $2C0000, $2C002C, $2C0056, $2C0087, $2C00C0, $2C00FF,
    $2C2C00, $2C2C2C, $2C2C56, $2C2C87, $2C2CC0, $2C2CFF, $2C5600, $2C562C,
    $2C5656, $2C5687, $2C56C0, $2C56FF, $2C8700, $2C872C, $2C8756, $2C8787,
    $2C87C0, $2C87FF, $2CC000, $2CC02C, $2CC056, $2CC087, $2CC0C0, $2CC0FF,
    $2CFF00, $2CFF2C, $2CFF56, $2CFF87, $2CFFC0, $2CFFFF, $560000, $56002C,
    $560056, $560087, $5600C0, $5600FF, $562C00, $562C2C, $562C56, $562C87,
    $562CC0, $562CFF, $565600, $56562C, $565656, $565687, $5656C0, $5656FF,
    $568700, $56872C, $568756, $568787, $5687C0, $5687FF, $56C000, $56C02C,
    $56C056, $56C087, $56C0C0, $56C0FF, $56FF00, $56FF2C, $56FF56, $56FF87,
    $56FFC0, $56FFFF, $870000, $87002C, $870056, $870087, $8700C0, $8700FF,
    $872C00, $872C2C, $872C56, $872C87, $872CC0, $872CFF, $875600, $87562C,
    $875656, $875687, $8756C0, $8756FF, $878700, $87872C, $878756, $878787,
    $8787C0, $8787FF, $87C000, $87C02C, $87C056, $87C087, $87C0C0, $87C0FF,
    $87FF00, $87FF2C, $87FF56, $87FF87, $87FFC0, $87FFFF, $C00000, $C0002C,
    $C00056, $C00087, $C000C0, $C000FF, $C02C00, $C02C2C, $C02C56, $C02C87,
    $C02CC0, $C02CFF, $C05600, $C0562C, $C05656, $C05687, $C056C0, $C056FF,
    $C08700, $C0872C, $C08756, $C08787, $C087C0, $C087FF, $C0C000, $C0C02C,
    $C0C056, $C0C087, $C0C0FF, $C0FF00, $C0FF2C, $C0FF56, $C0FF87, $C0FFC0,
    $C0FFFF, $FF002C, $FF0056, $FF0087, $FF00C0, $FF2C00, $FF2C2C, $FF2C56,
    $FF2C87, $FF2CC0, $FF2CFF, $FF5600, $FF562C, $FF5656, $FF5687, $FF56C0,
    $FF56FF, $FF8700, $FF872C, $FF8756, $FF8787, $FF87C0, $FF87FF, $FFC000,
    $FFC02C, $FFC056, $FFC087, $FFC0C0, $FFC0FF, $FFFF2C, $FFFF56, $FFFF87,
    $FFFFC0, $111111, $181818, $1E1E1E, $252525, $343434, $3C3C3C, $444444,
    $4D4D4D, $5F5F5F, $696969, $727272, $7D7D7D, $929292, $9D9D9D, $A8A8A8,
    $B4B4B4, $CCCCCC, $D8D8D8, $E5E5E5, $F2F2F2, $556DFF, $AA6DFF, $FF6DFF,
    $0092FF, $5592FF, $AA92FF, $FF92FF, $00B6FF, $55B6FF, $D8E4F0, $A4A0A0,
    $808080, $0000FF, $00FF00, $00FFFF, $FF0000, $FF00FF, $FFFF00, $FFFFFF);

begin
  logPalette := Nil;
  dc := GetDC (0);
  try
    GetMem (logPalette, sizeof (logPalette) + 256 * sizeof (PALETTEENTRY));
    logPalette^.palVersion := $300;
    logPalette^.palNumEntries := 256;
    caps := GetDeviceCaps (dc, RASTERCAPS);
    if ((caps and RC_PALETTE) <> 0) and (GetSystemPaletteEntries (dc, 0, 256, logPalette^.palPalEntry) = 256) then
      result := CreatePalette (logPalette^)
    else
    begin

{$R-}
      for i := 0 to 255 do
        with logPalette^.palPalEntry [i] do
        begin
          c := palColors256 [i];

          peRed := c and $ff;
          peGreen := c shr 8 and $ff;
          peBlue :=  c shr 16 and $ff
        end;                          

{$R+}
      result := CreatePalette (logPalette^);
    end

  finally
    ReleaseDC (0, dc);
    if Assigned (logPalette) then
      FreeMem (logPalette)
  end
end;

(*----------------------------------------------------------------------------*
 | function Create2ColorPalette;                                              |
 |                                                                            |
 | Does what it says on the tin..                                             |
 *----------------------------------------------------------------------------*)
function Create2ColorPalette : HPALETTE;
const
  palColors2 : array [0..1] of TColor = ($000000, $ffffff);
var
  logPalette : PLogPalette;
  i, c : Integer;

begin
  GetMem (logPalette, sizeof (logPalette) + 2 * sizeof (PALETTEENTRY));

  try
    logPalette^.palVersion := $300;
    logPalette^.palNumEntries := 2;
{$R-}
    for i := 0 to 1 do
      with logPalette^.palPalEntry [i] do
      begin
        c := palColors2 [i];

        peRed := c and $ff;
        peGreen := c shr 8 and $ff;
        peBlue :=  c shr 16 and $ff
      end;
{$R+}
    result := CreatePalette (logPalette^);
  finally
    FreeMem (logPalette)
  end
end;

{ TIconCursor }

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.Assign                                               |
 |                                                                            |
 | Assign one from another.                                                   |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.Assign(source: TPersistent);
begin
  if source is TIconCursor then
  begin
    if Source <> nil then
    begin
      TIconCursor(Source).FImage.Reference;
      FImage.Release;
      FImage := TIconCursor(Source).FImage;
      fPixelFormat := TIconCursor (source).fPixelFormat;
      fWidth := TIconCursor (source).fWidth;
      fHeight := TIconCursor (source).fHeight;
      fHotspot := TIconCursor (source).fHotspot;
      if fPalette <> 0 then
      begin
        DeleteObject (fPalette);
        fPalette := 0
      end
    end else
      NewImage(0, nil);
    Changed(Self);
    Exit;
  end;
  inherited Assign (source)
end;

(*----------------------------------------------------------------------------*
 | constructor TIconCursor.Create                                             |
 *----------------------------------------------------------------------------*)
constructor TIconCursor.Create;
begin
  inherited Create;
  FImage := TExIconImage.Create;
  FIcon := TIcon.Create;
  FImage.Reference;
end;

(*----------------------------------------------------------------------------*
 | destructor TIconCursor.Destroy;                                            |
 *----------------------------------------------------------------------------*)
destructor TIconCursor.Destroy;
begin
  FIcon.Free;
  FImage.Release;
  if FPalette <> 0 then
    DeleteObject (FPalette);
  inherited Destroy
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.Draw ()                                              |
 |                                                                            |
 | Draw the icon/cursor on a canvas.  Stretch it to the rect.                 |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.Draw(ACanvas: TCanvas; const Rect: TRect);
begin
  with rect do
    if fPalette <> 0 then
      StretchDrawIcon (ACanvas.Handle, handle, left, top, right, bottom)
    else
      DrawIconEx (ACanvas.Handle, left, top, handle, right - left + 1, bottom - top + 1, 0, 0, DI_NORMAL)  
end;

(*----------------------------------------------------------------------------*
 | function TIconCursor.GetColorCount                                         |
 |                                                                            |
 | Get the color count                                                        |
 *----------------------------------------------------------------------------*)
function TIconCursor.GetColorCount: Integer;
begin
  result := 1 shl BitsPerPixel
end;

(*----------------------------------------------------------------------------*
 | function TIconCursor.GetEmpty                                              |
 |                                                                            |
 | Returns true if we don't have a memory image or a handle.                  |
 *----------------------------------------------------------------------------*)
function TIconCursor.GetEmpty: Boolean;
begin
  with FImage do
    Result := (FHandle = 0) and (FMemoryImage = nil);
end;

(*----------------------------------------------------------------------------*
 | function TIconCursor.GetHandle                                             |
 |                                                                            |
 | Return the icons handle.  Create one if necessary (ie. if we've only got   |
 | a memory image.                                                            |
 *----------------------------------------------------------------------------*)
function TIconCursor.GetHandle: HICON;
begin
  HandleNeeded;
  Result := FImage.FHandle;
end;

(*----------------------------------------------------------------------------*
 | function TIconCursor.GetHeight                                             |
 |                                                                            |
 | Get the height.                                                            |
 *----------------------------------------------------------------------------*)
function TIconCursor.GetHeight: Integer;
begin
  HandleNeeded;
  result := fHeight;
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.                                                     |
 |                                                                            |
 | Get the Palette.                                                           |
 *----------------------------------------------------------------------------*)
function TIconCursor.GetPalette: HPALETTE;
begin
  if fPalette = 0 then
  begin
    ImageNeeded;
    fPalette := CreateDIBPalette (PBitmapInfo (PChar (FImage.FMemoryImage.Memory) + fBitmapOffset)^);
  end;

  result := fPalette
end;

(*----------------------------------------------------------------------------*
 | function TIconCursor.GetPitsPerPixel                                       |
 |                                                                            |
 | Get bpp.                                                                   |
 *----------------------------------------------------------------------------*)
function TIconCursor.GetBitsPerPixel: Integer;
begin
  case PixelFormat of
    pf1Bit : result := 1;
    pf4Bit : result := 4;
    pf8Bit : result := 8;
    pf15Bit,
    pf16Bit : result := 16;
    pf24Bit : result := 24;
    pf32Bit : result := 32;
    else
      raise EInvalidGraphic.Create (rstInvalidPixelFormat);
  end
end;

(*----------------------------------------------------------------------------*
 | function TIconCursor.GetPixelFormat                                        |
 |                                                                            |
 | Get the pixel format.                                                      |
 *----------------------------------------------------------------------------*)
function TIconCursor.GetPixelFormat: TPixelFormat;
begin
  HandleNeeded;
  result := fPixelFormat
end;

(*----------------------------------------------------------------------------*
 | function TIconCursor.GetWidth                                              |
 |                                                                            |
 | Get the width.                                                             |
 *----------------------------------------------------------------------------*)
function TIconCursor.GetWidth: Integer;
begin
  HandleNeeded;
  result := fWidth;
end;


(*----------------------------------------------------------------------------*
 | procedure TIconCursor.LoadFromClipboardFormat                              |
 |                                                                            |
 | Load from clipboard format.  Not supported.                                |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.LoadFromClipboardFormat(AFormat: Word; AData: THandle;
  APalette: HPALETTE);
begin
  raise EInvalidGraphic.Create (rstNoClipboardSupport);
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.LoadFromStream                                       |
 |                                                                            |
 | Load the icon from a resource stream.                                      |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.LoadFromStream(Stream: TStream);
var
  Image: TMemoryStream;
begin
  Image := TMemoryStream.Create;
  try
    Image.SetSize(Stream.Size - Stream.Position);
    Stream.ReadBuffer(Image.Memory^, Image.Size);
    NewImage(0, Image);
  except
    Image.Free;
    raise;
  end;
  Changed(Self);
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.NewImage                                             |
 |                                                                            |
 | Change the icon.                                                           |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.NewImage(NewHandle: HICON; NewImage: TMemoryStream);
var
  Image: TExIconImage;
begin
  Image := TExIconImage.Create;
  try
    Image.FHandle := NewHandle;
    Image.FMemoryImage := NewImage;
  except
    Image.Free;
    raise;
  end;
  Image.Reference;
  FImage.Release;
  FImage := Image;
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.ReleaseHandle                                        |
 |                                                                            |
 | Release the handle.                                                        |
 *----------------------------------------------------------------------------*)
function TIconCursor.ReleaseHandle: HICON;
begin
  with FImage do
  begin
    if RefCount > 1 then
      NewImage(CopyIcon(FHandle), nil);

    Result := FHandle;
    FHandle := 0;
  end;
  Changed(Self);
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.SaveToClipboardFormat                                |
 |                                                                            |
 | Not supported.                                                             |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.SaveToClipboardFormat(var Format: Word;
  var Data: THandle; var APalette: HPALETTE);
begin
  raise EInvalidGraphic.Create (rstNoClipboardSupport)
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.SaveToStream                                         |
 |                                                                            |
 | Save to a stream.                                                          |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.SaveToStream(Stream: TStream);
begin
  ImageNeeded;
  with FImage.FMemoryImage do Stream.WriteBuffer(Memory^, Size);
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.SetHandle                                            |
 |                                                                            |
 | Set the image to a new icon handle.                                        |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.SetHandle(const Value: HICON);
var
  iconInfo : TIconInfo;
  BI : TBitmapInfoHeader;
begin
  if GetIconInfo (value, iconInfo) then
  try
    InitializeBitmapInfoHeader (iconInfo.hbmColor, BI, ColorCount);
    fWidth := BI.biWidth;
    fHeight := BI.biHeight;
    fHotspot := MAKELONG (iconInfo.xHotspot, iconInfo.yHotspot);

    NewImage(Value, nil);
    Changed(Self)
  finally
    DeleteObject (iconInfo.hbmMask);
    DeleteObject (iconInfo.hbmColor)
  end
  else
    RaiseLastWin32Error;
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.SetHeight                                            |
 |                                                                            |
 | Set the icon's height.  Must be empty                                      |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.SetHeight(value: Integer);
begin
  if GetEmpty then
    FHeight := value
  else
    raise EInvalidGraphic.Create (rstCantResize);
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.SetPixelFormat                                       |
 |                                                                            |
 | Change the pixel format.  Must be empty                                    |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.SetPixelFormat(const Value: TPixelFormat);
begin
  if value <> fPixelFormat then
  begin
//    if not (value in [pf1Bit, pf4Bit, pf8Bit]) then
    if value = pfCustom then
      raise EInvalidGraphic.Create (rstInvalidPixelFormat);

    if GetEmpty then
      fPixelFormat := Value
    else
      raise EInvalidGraphic.Create (rstCantReformat);
  end
end;

(*----------------------------------------------------------------------------*
 | procedure TIconCursor.SetWidth                                             |
 |                                                                            |
 | Set the icon width.  Must be empty                                         |
 *----------------------------------------------------------------------------*)
procedure TIconCursor.SetWidth(value: Integer);
begin
  if GetEmpty then
    FWidth := value
  else
    raise EInvalidGraphic.Create (rstCantResize);
end;

{ TExIconImage }

(*----------------------------------------------------------------------------*
 | destructor TExIconImage.Destroy                                            |
 *----------------------------------------------------------------------------*)
destructor TExIconImage.Destroy;
begin
  FMemoryImage.Free;
  inherited                     // Which calls FreeHandle if necessary
end;

(*----------------------------------------------------------------------------*
 | procedure TExIconImage.FreeHandle                                          |
 |                                                                            |
 | Free the handle.                                                           |
 *----------------------------------------------------------------------------*)
procedure TExIconImage.FreeHandle;
begin
  if FHandle <> 0 then
    DestroyIcon(FHandle);
  FHandle := 0;
end;

{ TExCursor }

(*----------------------------------------------------------------------------*
 | constructor TExCursor.Create                                               |
 *----------------------------------------------------------------------------*)
constructor TExCursor.Create;
begin
  inherited Create;
  fBitmapOffset := sizeof (DWORD);
  fWidth := GetSystemMetrics (SM_CXCURSOR);
  fHeight := GetSystemMetrics (SM_CYCURSOR);
  fPixelFormat := pf1Bit;
end;

(*----------------------------------------------------------------------------*
 | function TExCursor.GetHotspot                                              |
 |                                                                            |
 | Get the cursor's hotspot.                                                  |
 *----------------------------------------------------------------------------*)
function TExCursor.GetHotspot: DWORD;
begin
  HandleNeeded;
  result := fHotspot
end;

(*----------------------------------------------------------------------------*
 | procedure TExCursor.HandleNeeded                                           |
 |                                                                            |
 | Make sure there's a handle if there's a memory image.                      |
 | If there's no handle or memory image, it's not an error.                   |
 *----------------------------------------------------------------------------*)
procedure TExCursor.HandleNeeded;
var
  info : TBitmapInfoHeader;
  NewHandle: HICON;
begin
  with FImage do
  begin
    if FHandle <> 0 then Exit;
    if FMemoryImage = nil then Exit;

    FMemoryImage.Seek (sizeof (DWORD), soFromBeginning);    // BitmapInfoHeader comes
    FMemoryImage.ReadBuffer (info, sizeof (Info));          // after the DWORD hotspot.
    FMemoryImage.Seek (0, soFromBeginning);

    if fPalette <> 0 then
      DeleteObject (fPalette);

    ReadIcon(FMemoryImage, NewHandle, fPalette, False);

    FWidth := info.biWidth;
    FHeight := info.biHeight div 2;
    FHotspot := PDWORD (FMemoryImage.Memory)^;

    case info.biBitCount of
      1: FPixelFormat := pf1Bit;
      4: FPixelFormat := pf4Bit;
      8: FPixelFormat := pf8Bit;
     16: case info.biCompression of
           BI_RGB : FPixelFormat := pf15Bit;
           BI_BITFIELDS: FPixelFormat := pf16Bit;
         end;
     24: FPixelFormat := pf24Bit;
     32: FPixelFormat := pf32Bit;
    else
      raise EInvalidGraphic.Create (rstInvalidPixelFormat);
    end;

    FHandle := NewHandle;
  end
end;

(*----------------------------------------------------------------------------*
 | procedure TExCursor.ImageNeeded                                            |
 |                                                                            |
 | Make sure there's an image if there's a handle.                            |
 | It's an error if there's neither...                                        |
 *----------------------------------------------------------------------------*)
procedure TExCursor.ImageNeeded;
var
  Image: TMemoryStream;
  colorCount : Integer;
begin
  with FImage do
  begin
    if FMemoryImage <> nil then Exit;
    if FHandle = 0 then
      raise EInvalidGraphic.Create (rstInvalidIcon);

    Image := TMemoryStream.Create;
    try
      case pixelFormat of
        pf1Bit : colorCount := 2;
        pf4Bit : colorCount := 16;
        pf8Bit : colorCount := 256;
        else
            colorCount := 0;
      end;

      Image.Seek (0, soFromBeginning);  // leave space for hotspot dword
      WriteIcon(Image, Handle, colorCount, False);

    except
      Image.Free;
      raise;
    end;
    FMemoryImage := Image;
  end;
end;


(*----------------------------------------------------------------------------*
 | procedure TExCursor.SetHotspot                                             |
 |                                                                            |
 | Set the hotspot.  *Doesn't* have to be empty.                              |
 *----------------------------------------------------------------------------*)
procedure TExCursor.SetHotspot(const Value: DWORD);
begin
  if value <> fHotspot then
  begin
    FHotspot := value;
    if not Empty then
    begin
      fHotspot := value;
      ImageNeeded;         // If it's not empty there's either an image or a handle.
                           // Make sure the image is valid

                           // Release the handle.  We want a new one with the new
                           // hotspot.
      if fImage.fHandle <> 0 then
        DeleteObject (ReleaseHandle);

      PDWORD (FImage.FMemoryImage.Memory)^ := Value;
    end
  end
end;

{ TExIcon }

(*----------------------------------------------------------------------------*
 | constructor TExIcon.Create                                                 |
 *----------------------------------------------------------------------------*)
constructor TExIcon.Create;
begin
  inherited Create;
  fWidth := GetSystemMetrics (SM_CXICON);
  fHeight := GetSystemMetrics (SM_CYICON);
  fPixelFormat := pf4Bit;
end;

(*----------------------------------------------------------------------------*
 | procedure TExIcon.HandleNeeded                                             |
 |                                                                            |
 | Make sure there's a handle if there's a memory image.                      |
 | If there's no handle or memory image, it's not an error.                   |
 *----------------------------------------------------------------------------*)
procedure TExIcon.HandleNeeded;
var
  info : TBitmapInfoHeader;
  NewHandle: HICON;
begin
  with FImage do
  begin
    if FHandle <> 0 then Exit;
    if FMemoryImage = nil then Exit;

    FMemoryImage.Seek (0, soFromBeginning);
    FMemoryImage.ReadBuffer (info, sizeof (Info));
    FMemoryImage.Seek (0, soFromBeginning);

    if fPalette <> 0 then
      DeleteObject (fPalette);

    ReadIcon(FMemoryImage, NewHandle, fPalette, True);
    FWidth := info.biWidth;
    FHeight := info.biHeight div 2;

    case info.biBitCount of
      1: FPixelFormat := pf1Bit;
      4: FPixelFormat := pf4Bit;
      8: FPixelFormat := pf8Bit;
     16: case info.biCompression of
           BI_RGB : FPixelFormat := pf15Bit;
           BI_BITFIELDS: FPixelFormat := pf16Bit;
         end;
     24: FPixelFormat := pf24Bit;
     32: FPixelFormat := pf32Bit;
      else
        raise EInvalidGraphic.Create (rstInvalidPixelFormat);
    end;

    FHandle := NewHandle;
  end
end;

(*----------------------------------------------------------------------------*
 | procedure TExCursor.ImageNeeded                                            |
 |                                                                            |
 | Make sure there's an image if there's a handle.                            |
 | It's an error if there's neither...                                        |
 *----------------------------------------------------------------------------*)
procedure TExIcon.ImageNeeded;
var
  Image: TMemoryStream;
  colorCount : Integer;
begin
  with FImage do
  begin
    if FMemoryImage <> nil then Exit;
    if FHandle = 0 then
      raise  EInvalidGraphic.Create (rstInvalidIcon);

    Image := TMemoryStream.Create;
    try
      case pixelFormat of
        pf1Bit : colorCount := 2;
        pf4Bit : colorCount := 16;
        pf8Bit : colorCount := 256;
        else
            colorCount := 0;
      end;

      WriteIcon(Image, Handle, colorCount, True);
    except
      Image.Free;
      raise;
    end;
    FMemoryImage := Image;
  end;
end;

const
  RGBMAX = 255;
  UNDEFINED = HLSMAX * 2 div 3;

function HueToRGB(n1,n2,hue : Integer) : word;
begin
  while hue > hlsmax do
    Dec (hue, HLSMAX);

  while hue < 0 do
    Inc (hue, HLSMAX);

  if hue < HLSMAX div 6 then
    result := ( n1 + (((n2-n1)*hue+(HLSMAX div 12)) div (HLSMAX div 6)) )
  else
    if hue < HLSMAX div 2 then
      result := n2
    else
      if hue < (HLSMAX*2) div 3 then
        result := n1 + (((n2-n1)*(((HLSMAX*2) div 3)-hue)+(HLSMAX div 12)) div (HLSMAX div 6))
      else
        result := n1
end;

procedure iHLSToRGB (hue, lum, sat : Integer; var r, g, b : Integer);
var
  Magic1,Magic2 : Integer;        // calculated magic numbers (really!) */

begin
  if sat = 0 then              // achromatic case */
  begin
    r := (lum * RGBMAX) div HLSMAX;
    g := r;
    b := r;
//    if hue <> UNDEFINED then
//      raise EColorError.Create ('Bad hue value')
  end
  else
  begin
    if lum <= HLSMAX div 2 then
      Magic2 := (lum*(HLSMAX + sat) + (HLSMAX div 2)) div HLSMAX
    else
      Magic2 := lum + sat - ((lum*sat) + (HLSMAX div 2)) div HLSMAX;

    Magic1 := 2*lum-Magic2;

    r := (HueToRGB (Magic1,Magic2,hue+(HLSMAX div 3))*RGBMAX + (HLSMAX div 2)) div HLSMAX;
    g := (HueToRGB (Magic1,Magic2,hue)*RGBMAX + (HLSMAX div 2)) div HLSMAX;
    b := (HueToRGB (Magic1,Magic2,hue-(HLSMAX div 3))*RGBMAX + (HLSMAX div 2)) div HLSMAX;
  end;
end;


function TIconCursor.GetIcon: TIcon;
begin
  Result := FIcon;
  Result.Handle := Handle; 
end;

initialization
  SystemPalette256 := Create256ColorPalette;
  SystemPalette2 := Create2ColorPalette;
finalization
  DeleteObject (SystemPalette2);
  DeleteObject (SystemPalette256);
end.

