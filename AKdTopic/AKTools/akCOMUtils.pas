// AkTools akCOMUtils unit.
//         ������, ���������� �������� � COM/OLE.
//=============================================================================

unit akCOMUtils;

interface

uses Windows;

const
// Guid'�, �� ������������ � ����������� ��������� �������.
  IID_IOleContainer: TGUID = '{0000011B-0000-0000-C000-000000000046}';
  IID_IOleCommandTarget: TGUID = '{b722bccb-4e68-101b-a2bc-00aa00404770}';
  CGID_MSHTML: TGUID = '{DE4BA900-59CA-11CF-9592-444553540000}';


// GUID �� ���������������
function IsGUIDEmpty(const GUID: TGUID): Boolean;

// ������� GUID
procedure EmptyGUID(var GUID: TGUID);

// ���������� ��������� ������������� OleVariant. ���� ��� Null - ������ ������
// ������
function OStr(str: OleVariant): String;

implementation

uses ActiveX, SysUtils;

function OStr(str: OleVariant): String;
begin
   if str = Null then
     Result := ''
   else
     Result := str;
end;

function IsGUIDEmpty(const GUID: TGUID): Boolean;
var st: TGUID;
begin
  EmptyGUID(st);
  Result := CompareMem(@st, @GUID, SizeOf(st));
end;

procedure EmptyGUID(var GUID: TGUID);
begin
  ZeroMemory(@GUID, SizeOf(GUID));
end;

end.

