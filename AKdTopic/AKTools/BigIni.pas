{ -------------------------------------------------------------------------- }
{ BigIni.PAS							    eh990418 }
{ Version 3.05								     }
{    Delphi 3/4 Version                                                      }
{    for a Delphi 1/2 version, please see homepage url below                 }
{ Unit to read/write *.ini files even greater than 64 kB		     }
{ (till today, the KERNEL.DLL and KERNEL32.DLL do it NOT).		     }

{ (c) Edy Hinzen 1996-1999 - Freeware					     }
{ Mailto:Edy@Hinzen.de	               (thanks for the resonance yet!)	     }
{ http://www.Hinzen.de                 (where you find the latest version)   }

{ -------------------------------------------------------------------------- }
{ The TBigIniFile object is designed to work like TIniFile from the Borland  }
{ unit called IniFiles. 						     }
{ Opposite to the Borland-routines, these are declared virtual! 	     }
{ Please note that no exception-handling is coded here. 		     }
{ The following procedures/functions were added:			     }
{    procedure FlushFile	      write data to disk		     }
{    procedure ReadAll		      copy entire contents to TStrings-object}
{    procedure AppendFromFile         appends from other *.ini               }
{    property  SectionNames						     }
{ -------------------------------------------------------------------------- }
{ The TBiggerIniFile object is a child object with some functions that came  }
{ in handy at my projects:						     }
{    property  TextBufferSize                                                }
{    procedure WriteSectionValues(const aSection: string; const aStrings: TStrings);}
{	       analog to ReadSectionValues, replace/write all lines from     }
{	       aStrings into specified section				     }
{    procedure ReadNumberedList(const Section: string;			     }
{				aStrings: TStrings;			     }
{				Deflt: String); 			     }
{    procedure WriteNumberedList(const Section: string; 		     }
{				aStrings: TStrings);			     }
{    function	ReadColor(const aSection, aKey: string;                      }
{                         aDefault: TColor): TColor;                         }
{    procedure	WriteColor(const aSection, aKey: string;                     }
{                          aValue: TColor); virtual;                         }
{ -------------------------------------------------------------------------- }
{ The TAppIniFile object is a child again.				     }
{ It's constructor create has no parameters. The filename is the application's}
{  exename with with extension '.ini' (instead of '.exe).                    }
{    constructor Create;						     }
{ -------------------------------------------------------------------------- }

{ ========================================================================== }
{   This program is distributed in the hope that it will be useful,	     }
{   but WITHOUT ANY WARRANTY; without even the implied warranty of	     }
{   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.		     }
{ ========================================================================== }

{ Programmer's note:                                                         }
{ Okay, this is NOT the fastest code of the world... (the kernel-functions   }
{ xxxxPrivateProfileString aren't, either!). I wrote it as a subproject of   }
{ my EditCdPlayer.EXE which never seems to become finished ...		     }
{ Meanwhile, I hope that Microsoft will write new KERNEL routines.	     }

{ Version history							     }
{ 1.10 faster read by replaceing TStringlist with simple ReadLn instructions }
{      improved FindItemIndex by storing last results			     }
{ 1.20 Ignore duplicate sections					     }
{      improved (for this use) TStringList child TSectionList		     }
{ 1.21 fixed 1.20 bug in case of empty file				     }
{ 1.22 added ReadNumberedList and WriteNumberedList			     }
{ 1.23 Delphi 1.0 backward compatibility e.g. local class TStringList        }
{ 1.24 added AppendFromFile                                                  }
{ 2.00 Changed compare-routines of aSection Parameters to AnsiCompareText    }
{      to handle case insensitive search in languages with special chars;    }
{      some efforts to increase speed                                        }
{      * new web and e-mail address *                                        }
{ 2.01 implemented modifications/suggestions from Gyula M�sz�ros,            }
{      Budapest, Hungary - 100263.1465@compuserve.com                        }
{procedure TIniFile.ReadSections(aStrings: TStrings);                         }
{    - The extra 16K file buffer is removeable                               }
{      see property TextBufferSize                                           }
{    - comment lines (beginning with ';') can be ignored                     }
{      set property FlagDropCommentLines to True                             }
{    - invalid lines (which do not contain an '=' sign) can be ignored       }
{      set property FlagFilterOutInvalid to True                             }
{    - white spaces around the '='-sign can be dropped                       }
{      set property FlagDropWhiteSpace to True                               }
{    - surrounding single or double apostrophes from keys can be dropped     }
{      set property FlagDropApostrophes to True                              }
{ 2.01 (continued)                                                           }
{      property SectionNames is now part of TBigIni (instead of TBiggerIni   }
{      added procedure ReadSections (seems new in Delphi 3)                  }
{ 2.02 fixed WriteNumberedList bug                                           }
{      added DeleteKey                                                       }
{      changed Pos() calls to AnsiPos()                                      }
{ 2.03 minor corrections                                                     }
{ 2.04 new flag FlagTrimRight                                                }
{      set it true to strip off white spaces at end of line                  }
{ 2.05 fixed bug in EraseSection                                             }
{ 2.06 For Win32 apps, TAppIniFile now creates ini-filename in correct mixed }
{      case                                                                  }
{      added HasChanged-check routine in WriteNumberedList                   }
{ 2.07 added note [1] and [2]                                                }
{      used new function ListIdentical instead of property named text within }
{      WriteNumberedList for backward-compatibility                          }
{ 3.01 fixed another bug in EraseSection (variable FPrevSectionIndex)        }
{ 3.02 dropped some $IFDEFS related to prior (Delphi 1/2) compatibility code }
{ 3.03 added ReadColor / WriteColor                                          }
{ 3.04 added notice about incombatibility with TMemIniFile.ReadSectionValues }
{ 3.05 fixed TTextBufferSize vs. IniBufferSize bug                           }
{ -------------------------------------------------------------------------- }
{ -------------------------------------------------------------------------- }
{ Question: how can I set these properties _before_ the file is opened?      }
{ Answer: call create with empty filename, look at this sample:              }
{       myIniFile := TBigIniFile.Create('');                                 }
{       myIniFile.FlagDropCommentLines := True;                              }
{       myIniFile.FileName := ('my.ini');                                    }
{........................................................................... }
{ Question: how can I write comment lines into the file?                     }
{ Answer: like this:                                                         }
{       tempStringList := TStringList.Create;                                }
{       tempStringList.Add('; this is a comment line.');                     }
{       BiggerIniFile.WriteSectionValues('important note',TempStringList);   }
{       BiggerIniFile.FlushFile;                                             }
{       tempStringList.Free;                                                 }
{ -------------------------------------------------------------------------- }

unit BigIni;

interface


uses classes, Windows, SysUtils, Forms, Graphics;

const
  IniTextBufferSize = $7000;
                     {Note [1]: don't use more than $7FFFF - it's an integer}
  {count keyword}
  cIniCount = 'Count';

type
  TEraseSectionCallback = function(const sectionName: string; const sl1, sl2: TStringList): Boolean of object;

  TSectionList = class(TStringList)
  private
    FPrevIndex: Integer;
    function GetValue(const name: string): string;
    procedure SetValue(const name, Value: string);
    function IndexOfName(const name: string): Integer;
  public
    constructor Create;
    function IndexOf(const S: AnsiString): Integer; override;
    function EraseDuplicates(callBackProc: TEraseSectionCallback): Boolean;
    function GetSectionItems(index: Integer): TStringList;
    property SectionItems[index: Integer]: TStringList read GetSectionItems;
    { redefines values }
    property Values[const name: string]: string read GetValue write SetValue;
  end;

  TBigIniFile = class(TObject)
  private
    FFileName: string;
    FHasChanged: Boolean;
    FSectionList: TSectionList;
    FPrevSectionIndex: Integer;
    FEraseSectionCallback: TEraseSectionCallback;
    FTextBufferSize: Integer;
    FFlagDropCommentLines, {set false to keep lines starting with ';'}
      FFlagFilterOutInvalid, {set false to keep lines without '='      }
      FFlagDropWhiteSpace, {set false to keep white space around '='}
      FFlagDropApostrophes, {set false to keep apostrophes around key }
      FFlagTrimRight: Boolean; {set false to keep white space at end of line}

    function FindItemIndex(const aSection, aKey: string; CreateNew: Boolean;
      var FoundStringList: TStringList): Integer;
    procedure SetFileName(const aName: string);
    procedure ClearSectionList;
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;
    function ReadString(const aSection, aKey, aDefault: string): string; virtual;
    procedure WriteString(const aSection, aKey, aValue: string); virtual;
    function ReadInteger(const aSection, aKey: string; aDefault: Longint): Longint; virtual;
    procedure WriteInteger(const aSection, aKey: string; aValue: Longint); virtual;
    function ReadBool(const aSection, aKey: string; aDefault: Boolean): Boolean; virtual;
    procedure WriteBool(const aSection, aKey: string; aValue: Boolean); virtual;
    procedure ReadSection(const aSection: string; aStrings: TStrings); virtual;
    procedure ReadSections(aStrings: TStrings); virtual;
    procedure ReadSectionValues(const aSection: string; aStrings: TStrings); virtual;
    procedure EraseSection(const aSection: string); virtual;
    procedure DeleteKey(const aSection, aKey: string); virtual;
    procedure ReadAll(aStrings: TStrings); virtual;
    procedure FlushFile; virtual;
    procedure AppendFromFile(const aName: string); virtual;
    property SectionNames: TSectionList read FSectionList;
    property FileName: string read FFileName write SetFileName;
    property EraseSectionCallback: TEraseSectionCallback read FEraseSectionCallback write FEraseSectionCallback;
    property FlagDropCommentLines: Boolean read FFlagDropCommentLines write FFlagDropCommentLines;
    property FlagFilterOutInvalid: Boolean read FFlagFilterOutInvalid write FFlagFilterOutInvalid;
    property FlagDropWhiteSpace: Boolean read FFlagDropWhiteSpace write FFlagDropWhiteSpace;
    property FlagDropApostrophes: Boolean read FFlagDropApostrophes write FFlagDropApostrophes;
    property FlagTrimRight: Boolean read FFlagTrimRight write FFlagTrimRight;
  end;

  TBiggerIniFile = class(TBigIniFile)
  public
    property HasChanged: Boolean read FHasChanged write FHasChanged;
    property TextBufferSize: Integer read FTextBufferSize write FTextBufferSize;
    procedure WriteSectionValues(const aSection: string; const aStrings: TStrings);
    procedure ReadNumberedList(const Section: string;
      aStrings: TStrings;
      Deflt: string);
    procedure WriteNumberedList(const Section: string;
      aStrings: TStrings);
    function ReadColor(const aSection,
      aKey: string;
      aDefault: TColor): TColor; virtual;
    procedure WriteColor(const aSection,
      aKey: string;
      aValue: TColor); virtual;
  end;

  TAppIniFile = class(TBiggerIniFile)
    constructor Create;
  end;

{ -------------------------------------------------------------------------- }
implementation
{ -------------------------------------------------------------------------- }
{........................................................................... }
{ classless functions/procedures			                     }
{........................................................................... }

function max(a, b: Integer): Integer;
begin
  if a > b then result := a
  else result := b;
end;

//------------------------------------------------------------------------------
// check if two StringLists contain identical STRINGS
//------------------------------------------------------------------------------

function ListIdentical(l1, l2: TStringList): Boolean;
var
  ix: Integer;
begin
  result := False;
  if l1.count = l2.count then
  begin
    for ix := 0 to l1.count - 1 do
    begin
      if (l1[ix] <> l2[ix]) then Exit;
    end;
    result := True;
  end;
end;

{........................................................................... }
{ class TSectionList							     }
{........................................................................... }

{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ create new instance							     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

constructor TSectionList.Create;
begin
  inherited Create;
  FPrevIndex := 0;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ access to property SectionItems					     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

function TSectionList.GetSectionItems(index: Integer): TStringList;
begin
  result := TStringList(Objects[index]);
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ erase duplicate entries   					             }
{ results TRUE if changes were made                                          }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

function TSectionList.EraseDuplicates(callBackProc: TEraseSectionCallback): Boolean;
var
  slDuplicateTracking: TStringList;
  idxToDelete,
    ixLow,
    ixHigh,
    ix: Integer;

  { swap two integer variables }
  procedure SwapInt(var a, b: Integer);
  var
    c: Integer;
  begin
    c := a;
    a := b;
    b := c;
  end;
begin
  result := False; { no changes made yet }

  if count > 1 then
  begin
    slDuplicateTracking := TStringList.Create;
    slDuplicateTracking.Assign(Self);
    { store current position in the objects field: }
    for ix := 0 to slDuplicateTracking.count - 1 do slDuplicateTracking.Objects[ix] := Pointer(ix);
    { sort the list to find out duplicates }
    slDuplicateTracking.Sort;
    ixLow := 0;
    for ix := 1 to slDuplicateTracking.count - 1 do
    begin
      if (AnsiCompareText(slDuplicateTracking.STRINGS[ixLow],
        slDuplicateTracking.STRINGS[ix]) <> 0) then
      begin
        ixLow := ix;
      end else
      begin
        ixHigh := ix;
        { find the previous entry (with lower integer number) }
        if Integer(slDuplicateTracking.Objects[ixLow]) >
          Integer(slDuplicateTracking.Objects[ixHigh]) then SwapInt(ixHigh, ixLow);

        if Assigned(callBackProc) then
        begin
          { ask callback/user wether to delete the higher (=true)
            or the lower one (=false)}
          if not callBackProc(slDuplicateTracking.STRINGS[ix],
            SectionItems[Integer(slDuplicateTracking.Objects[ixLow])],
            SectionItems[Integer(slDuplicateTracking.Objects[ixHigh])])
          then SwapInt(ixHigh, ixLow);
        end;
        idxToDelete := Integer(slDuplicateTracking.Objects[ixHigh]);

        { clear associated object and mark it as unassigned }
        SectionItems[idxToDelete].Clear;
        Objects[idxToDelete] := nil;
        result := True; { list had been changed }
      end {if};
    end {for};

    ix := 0;
    while ix < count do
    begin
      if Objects[ix] = nil then Delete(ix)
      else Inc(ix);
    end;
    slDuplicateTracking.free;
  end {if};

end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ search string 							     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

function TSectionList.IndexOf(const S: AnsiString): Integer;
var
  ix,
    LastIX: Integer;
  { This routine doesn't search from the first item each time,
    but from the last successful item. It is likely that the
    next item is to be found downward. }
begin
  result := -1;
  if count = 0 then Exit;

  LastIX := FPrevIndex;
  { Search from last successful point to the end: }
  for ix := LastIX to count - 1 do
  begin
    if (AnsiCompareText(Get(ix), S) = 0) then begin
      result := ix;
      FPrevIndex := ix;
      Exit;
    end;
  end;
  { Not found yet? Search from beginning to last successful point: }
  for ix := 0 to LastIX - 1 do
  begin
    if (AnsiCompareText(Get(ix), S) = 0) then begin
      result := ix;
      FPrevIndex := ix;
      Exit;
    end;
  end;
end;

{........................................................................... }
{ class TBigIniFile							     }
{........................................................................... }

{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ create new instance							     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

constructor TBigIniFile.Create(const FileName: string);
begin
  FSectionList := TSectionList.Create;
  FTextBufferSize := IniTextBufferSize; { you may set to zero to switch off }
  FFlagDropCommentLines := False; { change this defaults if needed }
  FFlagFilterOutInvalid := False;
  FFlagDropWhiteSpace := False;
  FFlagDropApostrophes := False;
  FFlagTrimRight := False;
  FFileName := '';
  FPrevSectionIndex := 0;
  FEraseSectionCallback := nil;
  SetFileName(FileName);
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ destructor								     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

destructor TBigIniFile.Destroy;
begin
  FlushFile;
  ClearSectionList;
  FSectionList.free;
  inherited Destroy;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ clean up								     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.ClearSectionList;
var
  ixSections: Integer;
begin
  with FSectionList do
  begin
    for ixSections := 0 to count - 1 do
    begin
      SectionItems[ixSections].free;
    end;
    Clear;
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ Append from File						             }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.AppendFromFile(const aName: string);
var
  CurrStringList: TStringList;
  CurrSectionName: string;
  lpTextBuffer: Pointer;
  Source: TextFile;
  OneLine: string;
  LL: Integer;
  LastPos,
    EqPos: Integer;
  nospace: Boolean;
begin
  CurrStringList := nil;
  lpTextBuffer := nil; {only to avoid compiler warnings}
  FPrevSectionIndex := 0;
  if FileExists(aName) then
  begin
    AssignFile(Source, aName);
    if FTextBufferSize > 0 then
    begin
      GetMem(lpTextBuffer, FTextBufferSize);
      SetTextBuf(Source, lpTextBuffer^, FTextBufferSize);
    end;
    Reset(Source);
    while not Eof(Source) do
    begin
      ReadLn(Source, OneLine);
      if OneLine = #$1A {EOF} then OneLine := '';
      { drop lines with leading ';' : }
      if FFlagDropCommentLines then if OneLine <> '' then if (OneLine[1] = ';') then OneLine := '';
      { drop lines without '=' }
      if OneLine <> '' then begin
        LL := Length(OneLine);
        if (OneLine[1] = '[') and (OneLine[LL] = ']') then
        begin
          CurrSectionName := Copy(OneLine, 2, LL - 2);
          CurrStringList := TStringList.Create;
          FSectionList.AddObject(CurrSectionName, CurrStringList);
        end
        else begin
          if FFlagDropWhiteSpace then
          begin
            nospace := False;
            repeat
              { delete white space left to equal sign }
              EqPos := AnsiPos('=', OneLine);
              if EqPos > 1 then begin
                if OneLine[EqPos - 1] in [' ', #9] then
                  Delete(OneLine, EqPos - 1, 1)
                else
                  nospace := True;
              end
              else
                nospace := True;
            until nospace;
            nospace := False;
            EqPos := AnsiPos('=', OneLine);
            if EqPos > 1 then begin
              repeat
                { delete white space right to equal sign }
                if EqPos < Length(OneLine) then begin
                  if OneLine[EqPos + 1] in [' ', #9] then
                    Delete(OneLine, EqPos + 1, 1)
                  else
                    nospace := True;
                end
                else
                  nospace := True;
              until nospace;
            end;
          end; {FFlagDropWhiteSpace}
          if FFlagDropApostrophes then
          begin
            EqPos := AnsiPos('=', OneLine);
            if EqPos > 1 then begin
              LL := Length(OneLine);
              { filter out the apostrophes }
              if EqPos < LL - 1 then begin
                if (OneLine[EqPos + 1] = OneLine[LL]) and (OneLine[LL] in ['"', #39]) then
                begin
                  Delete(OneLine, LL, 1);
                  Delete(OneLine, EqPos + 1, 1);
                end;
              end;
            end;
          end; {FFlagDropApostrophes}
          if FFlagTrimRight then
          begin
            LastPos := Length(OneLine);
            while ((LastPos > 0) and (OneLine[LastPos] < #33)) do Dec(LastPos);
            OneLine := Copy(OneLine, 1, LastPos);
          end; {FFlagTrimRight}
          if (not FFlagFilterOutInvalid) or (AnsiPos('=', OneLine) > 0) then
          begin
            if Assigned(CurrStringList) then CurrStringList.Add(OneLine);
          end;
        end;
      end;
    end;

    if FSectionList.EraseDuplicates(FEraseSectionCallback) then FHasChanged := True;

    Close(Source);
    if FTextBufferSize > 0 then
    begin
      FreeMem(lpTextBuffer, FTextBufferSize);
    end;
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ Set or change FileName						     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.SetFileName(const aName: string);
begin
  FlushFile;
  ClearSectionList;
  FFileName := aName;
  if aName <> '' then AppendFromFile(aName);
  FHasChanged := False;
end;

{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ find item in specified section					     }
{ depending on CreateNew-flag, the section is created, if not existing	     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

function TBigIniFile.FindItemIndex(const aSection, aKey: string; CreateNew: Boolean;
  var FoundStringList: TStringList): Integer;
var
  SectionIndex: Integer;
  LastIX: Integer;
begin
  SectionIndex := -1;

  if FSectionList.count > 0 then
  begin
    LastIX := FPrevSectionIndex - 1;
    if LastIX < 0 then LastIX := FSectionList.count - 1;
    while (AnsiCompareText(aSection, FSectionList[FPrevSectionIndex]) <> 0)
      and (FPrevSectionIndex <> LastIX) do
    begin
      Inc(FPrevSectionIndex);
      if FPrevSectionIndex = FSectionList.count then FPrevSectionIndex := 0;
    end;
    if AnsiCompareText(aSection, FSectionList[FPrevSectionIndex]) = 0 then
    begin
      SectionIndex := FPrevSectionIndex;
    end;
  end;

  if SectionIndex = -1 then
  begin
    if CreateNew then begin
      FoundStringList := TStringList.Create;
      FPrevSectionIndex := FSectionList.AddObject(aSection, FoundStringList);
    end
    else begin
      FoundStringList := nil;
    end;
    result := -1;
  end
  else begin
    FoundStringList := FSectionList.SectionItems[SectionIndex];
    result := FoundStringList.IndexOfName(aKey);
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ the basic function: return single string				     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

function TBigIniFile.ReadString(const aSection, aKey, aDefault: string): string;
var
  ItemIndex: Integer;
  CurrStringList: TStringList;
begin
  ItemIndex := FindItemIndex(aSection, aKey, False, CurrStringList);
  if ItemIndex = -1 then
  begin
    result := aDefault
  end
  else begin
    result := CurrStringList.Values[aKey];
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ here is the one to write the string					     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.WriteString(const aSection, aKey, aValue: string);
var
  ItemIndex: Integer;
  CurrStringList: TStringList;
  newLine: string;
begin
  if aKey = '' then
  begin
    {behaviour of WritePrivateProfileString: if all parameters are null strings,
     the file is flushed to disk. Otherwise, if key name is a null string,
     the entire Section is to be deleted}
    if (aSection = '') and (aValue = '') then FlushFile
    else EraseSection(aSection);
  end
  else begin
    newLine := aKey + '=' + aValue;
    ItemIndex := FindItemIndex(aSection, aKey, True, CurrStringList);
    if ItemIndex = -1 then begin
      CurrStringList.Add(newLine);
      FHasChanged := True;
    end
    else begin
      if (CurrStringList[ItemIndex] <> newLine) then
      begin
        FHasChanged := True;
        CurrStringList[ItemIndex] := newLine;
      end;
    end;
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ read integer value							     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

function TBigIniFile.ReadInteger(const aSection, aKey: string;
  aDefault: Longint): Longint;
var
  IStr: string;
begin
  IStr := ReadString(aSection, aKey, '');
  if CompareText(Copy(IStr, 1, 2), '0x') = 0 then
    IStr := '$' + Copy(IStr, 3, 255);
  result := StrToIntDef(IStr, aDefault);
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ Yes, you gessed right: this procedure writes an integer value 	     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.WriteInteger(const aSection, aKey: string; aValue: Longint);
begin
  WriteString(aSection, aKey, IntToStr(aValue));
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ read boolean value							     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

function TBigIniFile.ReadBool(const aSection, aKey: string;
  aDefault: Boolean): Boolean;
begin
  result := ReadInteger(aSection, aKey, Ord(aDefault)) <> 0;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ write boolean value							     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.WriteBool(const aSection, aKey: string; aValue: Boolean);
const
  BoolText: array[Boolean] of string[1] = ('0', '1');
begin
  WriteString(aSection, aKey, BoolText[aValue]);
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ read entire section (hoho, only the item names)			     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.ReadSection(const aSection: string; aStrings: TStrings);
var
  SectionIndex: Integer;
  CurrStringList: TStringList;
  ix: Integer;
begin
  SectionIndex := FSectionList.IndexOf(aSection);
  if SectionIndex <> -1 then
  begin
    CurrStringList := FSectionList.SectionItems[SectionIndex];
    for ix := 0 to CurrStringList.count - 1 do
    begin
      aStrings.Add(CurrStringList.Names[ix]);
    end;
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ copy all section names to TStrings object				     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.ReadSections(aStrings: TStrings);
begin
  aStrings.Assign(SectionNames);
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ read entire section							     }
{ this was one of the hardest tasks...	 :))				     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.ReadSectionValues(const aSection: string; aStrings: TStrings);
var
  SectionIndex: Integer;
begin
  SectionIndex := FSectionList.IndexOf(aSection);
  if SectionIndex <> -1 then
  begin
    {note that the TIniFile model does NOT clear the target-Strings
    That's why my procedure doesn't either}
    {3.04 notice: please note that TMemIniFile.ReadSectionValues
    from the Delphi 4.0 file inifiles.pas _does_ clear the strings
    where TIniFile.ReadSectionValues of the same file _does_not_)
    }
    aStrings.AddStrings(FSectionList.SectionItems[SectionIndex]);
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ copy all 'lines' to TStrings-object                                        }
{ Note [2]: under Delphi 1, ReadAll may cause errors when a TMemo.Lines      }
{      array is destination and source is greater than 64 KB                 }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.ReadAll(aStrings: TStrings);
var
  ixSections: Integer;
  CurrStringList: TStringList;
begin
  with FSectionList do
  begin
    for ixSections := 0 to count - 1 do
    begin
      CurrStringList := SectionItems[ixSections];
      if CurrStringList.count > 0 then
      begin
        aStrings.Add('[' + STRINGS[ixSections] + ']');
        aStrings.AddStrings(CurrStringList);
        aStrings.Add('');
      end;
    end;
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ flush (save) data to disk						     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.FlushFile;
var
  CurrStringList: TStringList;
  lpTextBuffer: Pointer;
  Destin: TextFile;
  ix,
    ixSections: Integer;
begin
  lpTextBuffer := nil; {only to avoid compiler warnings}
  if FHasChanged then
  begin
    if FFileName <> '' then
    begin
      AssignFile(Destin, FFileName);
      if FTextBufferSize > 0 then
      begin
        GetMem(lpTextBuffer, FTextBufferSize);
        SetTextBuf(Destin, lpTextBuffer^, FTextBufferSize);
      end;
      Rewrite(Destin);

      with FSectionList do
      begin
        for ixSections := 0 to count - 1 do
        begin
          CurrStringList := SectionItems[ixSections];
          if CurrStringList.count > 0 then
          begin
            WriteLn(Destin, '[', STRINGS[ixSections], ']');
            for ix := 0 to CurrStringList.count - 1 do
            begin
              WriteLn(Destin, CurrStringList[ix]);
            end;
            WriteLn(Destin);
          end;
        end;
      end;

      Close(Destin);
      if FTextBufferSize > 0 then
      begin
        FreeMem(lpTextBuffer, FTextBufferSize);
      end;
    end;
    FHasChanged := False;
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ erase specified section						     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.EraseSection(const aSection: string);
var
  SectionIndex: Integer;
begin
  SectionIndex := FSectionList.IndexOf(aSection);
  if SectionIndex <> -1 then
  begin
    FSectionList.SectionItems[SectionIndex].free;
    FSectionList.Delete(SectionIndex);
    FSectionList.FPrevIndex := 0;
    FHasChanged := True;
    if FPrevSectionIndex >= FSectionList.count then FPrevSectionIndex := 0;
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ remove a single key							     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBigIniFile.DeleteKey(const aSection, aKey: string);
var
  ItemIndex: Integer;
  CurrStringList: TStringList;
begin
  ItemIndex := FindItemIndex(aSection, aKey, True, CurrStringList);
  if ItemIndex > -1 then begin
    FHasChanged := True;
    CurrStringList.Delete(ItemIndex);
  end;
end;

{........................................................................... }
{ class TBiggerIniFile							     }
{........................................................................... }

{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ write/replace complete section					     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBiggerIniFile.WriteSectionValues(const aSection: string; const aStrings: TStrings);
var
  SectionIndex: Integer;
  FoundStringList: TStringList;
  ix: Integer;
begin
  SectionIndex := FSectionList.IndexOf(aSection);
  if SectionIndex = -1 then
  begin
    { create new section }
    FoundStringList := TStringList.Create;
    FSectionList.AddObject(aSection, FoundStringList);
    FoundStringList.AddStrings(aStrings);
    FHasChanged := True;
  end
  else begin
    { compare existing section }
    FoundStringList := FSectionList.SectionItems[SectionIndex];
    if FoundStringList.count <> aStrings.count then
    begin
      { if count differs, replace complete section }
      FoundStringList.Clear;
      FoundStringList.AddStrings(aStrings);
      FHasChanged := True;
    end
    else begin
      { compare line by line }
      for ix := 0 to FoundStringList.count - 1 do
      begin
        if FoundStringList[ix] <> aStrings[ix] then
        begin
          FoundStringList[ix] := aStrings[ix];
          FHasChanged := True;
        end;
      end;
    end;
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ read a numbered list  		                                     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBiggerIniFile.ReadNumberedList(const Section: string;
  aStrings: TStrings;
  Deflt: string);
var
  maxEntries: Integer;
  ix: Integer;
begin
  maxEntries := ReadInteger(Section, cIniCount, 0);
  for ix := 1 to maxEntries do begin
    aStrings.Add(ReadString(Section, IntToStr(ix), Deflt));
  end;
end;
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ write a numbered list (TStrings contents)				     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBiggerIniFile.WriteNumberedList(const Section: string;
  aStrings: TStrings);
var
  prevCount,
    ix: Integer;
  prevHasChanged: Boolean;
  oldSectionValues,
    newSectionValues: TStringList;
begin
  oldSectionValues := TStringList.Create;
  newSectionValues := TStringList.Create;
  { store previous entries }
  ReadSectionValues(Section, oldSectionValues);

  prevCount := ReadInteger(Section, cIniCount, 0);
  WriteInteger(Section, cIniCount, aStrings.count);
  prevHasChanged := HasChanged;

  { remove all previous lines to get new ones together }
  for ix := 0 to prevCount - 1 do begin
    DeleteKey(Section, IntToStr(ix + 1));
  end;
  for ix := 0 to aStrings.count - 1 do begin
    WriteString(Section, IntToStr(ix + 1), aStrings[ix]);
  end;

  { check if entries really had changed }
  if not prevHasChanged then
  begin
    { read new entries and compare with old }
    ReadSectionValues(Section, newSectionValues);
    HasChanged := not ListIdentical(newSectionValues, oldSectionValues);
  end;
  oldSectionValues.free;
  newSectionValues.free;
end;

{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ read a TColor value stored as hex-string				     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

function TBiggerIniFile.ReadColor(const aSection, aKey: string; aDefault: TColor): TColor;
begin
  ReadColor := StrToInt('$' + ReadString(aSection, aKey, IntToHex(aDefault, 8)));
end;

{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }
{ write TColor as hex-string in the form 00bbggrr	                     }
{. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . }

procedure TBiggerIniFile.WriteColor(const aSection, aKey: string; aValue: TColor);
begin
  WriteString(aSection, aKey, IntToHex(aValue, 8));
end;

{........................................................................... }
{ class TAppIniFile							     }
{........................................................................... }
{ Application.ExeName returns a result in uppercase letters only             }
{ The following FindFirst construct returns the mixed case name              }

constructor TAppIniFile.Create;
var
  thePath,
    theExeName: string;
  theSearchRec: TSearchRec;
begin
  theExeName := Application.ExeName;
  thePath := ExtractFilePath(theExeName);
  if FindFirst(theExeName, faAnyFile, theSearchRec) = 0 then
  begin
    theExeName := thePath + theSearchRec.name;
  end;
  FindClose(theSearchRec);
  inherited Create(ChangeFileExt(theExeName, '.ini'));
end;

// some experiences trying to improve access ... (beta)

function TSectionList.GetValue(const name: string): string;
var
  I: Integer;
begin
  I := IndexOfName(name);
  if I >= 0 then
    result := Copy(Get(I), Length(name) + 2, MaxInt) else
    result := '';
end;

procedure TSectionList.SetValue(const name, Value: string);
var
  I: Integer;
begin
  I := IndexOfName(name);
  if Value <> '' then
  begin
    if I < 0 then I := Add('');
    Put(I, name + '=' + Value);
  end else
  begin
    if I >= 0 then Delete(I);
  end;
end;

function TSectionList.IndexOfName(const name: string): Integer;
var
  P: Integer;
  s1,
    s2: AnsiString;
begin
  s2 := name; //l2 := Length(s2);
  for result := 0 to GetCount - 1 do
  begin
    s1 := Get(result);
    P := AnsiPos('=', s1);
    SetLength(s1, P - 1);
    if (P <> 0) and (
      CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE,
      PChar(s1), -1,
      PChar(s2), -1)
      = 2) then Exit;
  end;
  result := -1;
end;

end.

