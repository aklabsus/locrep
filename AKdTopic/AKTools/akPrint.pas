unit akPrint;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, tntclasses, jclunicode;

type
  THeaderFooterProc =
    procedure(aCanvas: TCanvas; aPageCount: Integer;
    aTextrect: TRect; var continue: bytebool) of object;

   { Prototype for a callback method that PrintString will call
     when it is time to print a header or footer on a page. The
     parameters that will be passed to the callback are:
     aCanvas   : the canvas to output on
     aPageCount: page number of the current page, counting from 1
     aTextRect : output rectangle that should be used. This will be
                 the area available between non-printable margin and
                 top or bottom margin, in device units (dots). Output
                 is not restricted to this area, though.
     continue  : will be passed in as True. If the callback sets it
                 to false the print job will be aborted. }

function PrintStrings(lines: TTNTStrings;
  const leftmargin, rightmargin,
  topmargin, bottommargin: Single;
//  const linesPerInch: single;
  aFont: TFont;
  measureonly: bytebool;
  OnPrintheader,
  OnPrintfooter: THeaderFooterProc): Integer;


implementation

uses Printers;

{+------------------------------------------------------------
 | Function PrintStrings
 |
 | Parameters :
 |   lines:
 |     contains the text to print, already formatted into
 |     lines of suitable length. No additional wordwrapping
 |     will be done by this routine and also no text clipping
 |     on the right margin!
 |   leftmargin, topmargin, rightmargin, bottommargin:
 |     define the print area. Unit is inches, the margins are
 |     measured from the edge of the paper, not the printable
 |     area, and are positive values! The margin will be adjusted
 |     if it lies outside the printable area.
 |   linesPerInch:
 |     used to calculate the line spacing independent of font
 |     size.
 |   aFont:
 |     font to use for printout, must not be Nil.
 |   measureonly:
 |     If true the routine will only count pages and not produce any
 |     output on the printer. Set this parameter to false to actually
 |     print the text.
 |   OnPrintheader:
 |     can be Nil. Callback that will be called after a new page has
 |     been started but before any text has been output on that page.
 |     The callback should be used to print a header and/or a watermark
 |     on the page.
 |   OnPrintfooter:
 |     can be Nil. Callback that will be called after all text for one
 |     page has been printed, before a new page is started. The  callback
 |     should be used to print a footer on the page.
 | Returns:
 |   number of pages printed. If the job has been aborted the return
 |   value will be 0.
 | Description:
 |   Uses the Canvas.TextOut function to perform text output in
 |   the rectangle defined by the margins. The text can span
 |   multiple pages.
 | Nomenclature:
 |   Paper coordinates are relative to the upper left corner of the
 |   physical page, canvas coordinates (as used by Delphis  Printer.Canvas)
 |   are relative to the upper left corner of the printable area. The
 |   printorigin variable below holds the origin of the canvas  coordinate
 |   system in paper coordinates. Units for both systems are printer
 |   dots, the printers device unit, the unit for resolution is dots
 |   per inch (dpi).
 | Error Conditions:
 |   A valid font is required. Margins that are outside the printable
 |   area will be corrected, invalid margins will raise an EPrinter
 |   exception.
 | Created: 13.05.99 by P. Below
 +------------------------------------------------------------}

function PrintStrings(lines: TTNTStrings;
  const leftmargin, rightmargin,
  topmargin, bottommargin: Single;
//  const linesPerInch: single;
  aFont: TFont;
  measureonly: bytebool;
  OnPrintheader,
  OnPrintfooter: THeaderFooterProc): Integer;
var
  continuePrint: bytebool; { continue/abort flag for callbacks }
  pagecount: Integer; { number of current page }
  textrect: TRect; { output area, in canvas coordinates }
  headerrect: TRect; { area for header, in canvas coordinates }
  footerrect: TRect; { area for footes, in canvas coordinates }
//  lineheight: Integer; { line spacing in dots }
  charheight: Integer; { font height in dots  }
  textstart: Integer; { index of first line to print on
                                  current page, 0-based. }

  { Calculate text output and header/footer rectangles. }
  procedure CalcPrintRects;
  var
    X_resolution: Integer; { horizontal printer resolution, in dpi }
    Y_resolution: Integer; { vertical printer resolution, in dpi }
    pagerect: TRect; { total page, in paper coordinates }
    printorigin: TPoint; { origin of canvas coordinate system in
                                paper coordinates. }

    { Get resolution, paper size and non-printable margin from
      printer driver. }
    procedure GetPrinterParameters;
    begin
      with Printer.Canvas do begin
        X_resolution := GetDeviceCaps(handle, LOGPIXELSX);
        Y_resolution := GetDeviceCaps(handle, LOGPIXELSY);
        printorigin.X := GetDeviceCaps(handle, PHYSICALOFFSETX);
        printorigin.Y := GetDeviceCaps(handle, PHYSICALOFFSETY);
        pagerect.Left := 0;
        pagerect.Right := GetDeviceCaps(handle, PHYSICALWIDTH);
        pagerect.Top := 0;
        pagerect.Bottom := GetDeviceCaps(handle, PHYSICALHEIGHT);
      end; { With }
    end; { GetPrinterParameters }

    { Calculate area between the requested margins, paper-relative.
      Adjust margins if they fall outside the printable area.
      Validate the margins, raise EPrinter exception if no text area
      is left. }
    procedure CalcRects;
    var
      max: Integer;
    begin
      with textrect do begin
          { Figure textrect in paper coordinates }
        left := Round(leftmargin * X_resolution);
        if left < printorigin.x then
          left := printorigin.x;

        top := Round(topmargin * Y_resolution);
        if top < printorigin.y then
          top := printorigin.y;

          { Printer.PageWidth and PageHeight return the size of the
            printable area, we need to add the printorigin to get the
            edge of the printable area in paper coordinates. }
        right := pagerect.right - Round(rightmargin * X_resolution);
        max := Printer.PageWidth + printorigin.X;
        if right > max then
          right := max;

        bottom := pagerect.bottom - Round(bottommargin * Y_resolution);
        max := Printer.PageHeight + printorigin.Y;
        if bottom > max then
          bottom := max;

          { Validate the margins. }
        if (left >= right) or (top >= bottom) then
          raise EPrinter.Create(
            'PrintString: the supplied margins are too large, there ' +
            'is no area to print left on the page.');
      end; { With }

        { Convert textrect to canvas coordinates. }
      OffsetRect(textrect, -printorigin.X, -printorigin.Y);

        { Build header and footer rects. }
      headerrect := Rect(textrect.left, 0,
        textrect.right, textrect.top);
      footerrect := Rect(textrect.left, textrect.bottom,
        textrect.right, Printer.PageHeight);
    end; { CalcRects }

  begin { CalcPrintRects }
    GetPrinterParameters;
    CalcRects;
//    lineheight := round(Y_resolution / linesPerInch);
  end; { CalcPrintRects }

  { Print a page with headers and footers. }
  procedure PrintPage;
    procedure FireHeaderFooterEvent(event: THeaderFooterProc; r: TRect);
    begin
      if Assigned(event) then begin
        event(
          Printer.Canvas,
          pagecount,
          r,
          ContinuePrint);
          { Revert to our font, in case event handler changed
            it. }
        Printer.Canvas.Font := aFont;
      end; { If }
    end; { FireHeaderFooterEvent }

    procedure DoHeader;
    begin
      FireHeaderFooterEvent(OnPrintHeader, headerrect);
    end; { DoHeader }

    procedure DoFooter;
    begin
      FireHeaderFooterEvent(OnPrintFooter, footerrect);
    end; { DoFooter }

    procedure DoPage;
    var
      y: Integer;
      trec: TRect;
      stre, str: widestring;
      thispage: Integer;
      fs: TFontStyles;
      fschanged: bytebool;

    begin
      y := textrect.top; thispage := 0;
      while (textStart < lines.count) and
        (y <= (textrect.bottom - charheight)) do begin
        str := lines[textStart];

        fschanged := false;
        if Copy(str, 1, 5) = '##$>>' then begin
          fschanged := true;
          fs := printer.canvas.Font.Style;
          printer.canvas.Font.Style := [fsBold];
          str := Copy(str, 6, maxint);
        end;

        try
          if WideTrim(str) = '' then stre := 'W' else stre := str;
          trec := Rect(textrect.left, y, textrect.right, textrect.Bottom * 100);
          DrawTextW(printer.canvas.Handle, PWideChar(stre), -1,
            trec, DT_CALCRECT or DT_WORDBREAK);
          if (trec.Bottom <= textrect.Bottom) or (thispage = 0) then begin
            inc(thispage);
            DrawTextW(printer.canvas.Handle, PWideChar(str), -1,
              trec, DT_WORDBREAK);
            Inc(textStart);
            Inc(y, trec.Bottom - trec.Top);
          end else break;
        finally
          if fschanged then
            printer.canvas.Font.Style := fs;
        end;
      end; { While }
    end; { DoPage }

  begin { PrintPage }
    DoHeader;
    if ContinuePrint then begin
      DoPage;
      DoFooter;
      if (textStart < lines.count) and ContinuePrint then begin
        Inc(pagecount);
        Printer.NewPage;
      end; { If }
    end;
  end; { PrintPage }

begin { PrintStrings }
  Assert(Assigned(afont),
    'PrintString: requires a valid aFont parameter!');

  continuePrint := True;
  pagecount := 1;
  textstart := 0;
  Printer.Title := 'Note';
  Printer.BeginDoc;
  try
    CalcPrintRects;
{$IFNDEF WIN32}
        { Fix for Delphi 1 bug. }
    Printer.Canvas.Font.PixelsPerInch := Y_resolution;
{$ENDIF }
    Printer.Canvas.Font := aFont;
    charheight := printer.canvas.TextHeight('Ay');
    while (textstart < lines.count) and ContinuePrint do
      PrintPage;
  finally
    if continuePrint and not measureonly then
      Printer.EndDoc
    else begin
      Printer.Abort;
    end;
  end;

  if continuePrint then
    Result := pagecount
  else
    Result := 0;
end; { PrintStrings }


end.

