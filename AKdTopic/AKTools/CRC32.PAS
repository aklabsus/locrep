// Copyright 1999-2000 powered by Alexander Kramarenko
// Copyright 1992-1994 by Mark May
// Converted to Turbo Pascal (tm) V4.0 March, 1988 by J.R.Louvau
// Copyright (C) 1986 Gary S. Brown.

unit crc32;

interface
function GetStringCRC(Str: string): Cardinal;

implementation

const CRC32Polynomial = $EDB88320;
var crc_32_tab: array[byte] of longword;

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
  Result := crc_32_tab[BYTE(crc xor Cardinal(octet))] xor ((crc shr 8) and $00FFFFFF)
end;

function GetStringCRC(Str: string): Cardinal;
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

  am[0] := ar[3];
  am[1] := ar[2];
  am[2] := ar[1];
  am[3] := ar[0];

  Result := l;
end;

end.

