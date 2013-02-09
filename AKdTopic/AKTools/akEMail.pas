unit akEMail;

interface

uses Windows;

resourcestring
  exMailClientErr = 'Unable to open mail client (%d).'#$0A'Message to "%s" was not created.';

// Показывает диаложик отправки сообщения
function DlgSendEmail(const RecipName, RecipAddress, Subject, Text: string; ShortText: string = ''; showErr: Boolean = false): Boolean;

function SendEmail(const RecipName, RecipAddress, Subject, Text, Attachment: string): Boolean;

implementation

uses Mapi, Forms, SysUtils, akDataUtils, akSysCover;

function SendEmail(const RecipName, RecipAddress, Subject, Text, Attachment: string): Boolean;
var
  MapiMessage: TMapiMessage;
  MapiFileDesc: TMapiFileDesc;
  MapiRecipDesc: TMapiRecipDesc;
begin
  with MapiRecipDesc do
    begin
      ulReserved := 0;
      ulRecipClass := MAPI_TO;
      lpszName := PChar(RecipName);
      lpszAddress := PChar(RecipAddress);
      ulEIDSize := 0;
      lpEntryID := nil;
    end;
  with MapiFileDesc do
    begin
      ulReserved:= 0;
      flFlags:= 0;
      nPosition:= 0;
      lpszPathName:= PChar(Attachment);
      lpszFileName:= nil;
      lpFileType:= nil;
    end;
  with MapiMessage do
    begin
      ulReserved := 0;
      lpszSubject := PChar(Subject);
      lpszNoteText := PChar(Text);
      lpszMessageType := nil;
      lpszDateReceived := nil;
      lpszConversationID := nil;
      flFlags := 0;
      lpOriginator := nil;
      nRecipCount := 1;
      lpRecips := @MapiRecipDesc;
      if length(Attachment) > 0 then
        begin
          nFileCount:= 1;
          lpFiles := @MapiFileDesc;
        end
      else
        begin
          nFileCount:= 0;
          lpFiles:= nil;
        end;
    end;
  Result:= MapiSendMail(0, 0, MapiMessage, MAPI_LOGON_UI or
   MAPI_NEW_SESSION, 0) = SUCCESS_SUCCESS;
end;


function DlgSendEmail(const RecipName, RecipAddress, Subject, Text: string; ShortText: string; showErr: Boolean): Boolean;
var
  MapiMessage: TMapiMessage;
  MapiRecipDesc: TMapiRecipDesc;
  i: integer;
  per: DWORD;
  msg, txt: string;
begin
  txt := iifs(ShortText = '', Text, ShortText);

  ZeroMemory(@MapiRecipDesc, SizeOf(MapiRecipDesc));
  ZeroMemory(@MapiMessage, SizeOf(MapiMessage));

  with MapiRecipDesc do
    begin
      ulRecipClass := MAPI_TO;
      lpszName := PChar(RecipName);
      lpszAddress := PChar(RecipAddress);
    end;
  with MapiMessage do
    begin
      lpszSubject := PChar(Subject);
      lpszNoteText := PChar(Text);
      nRecipCount := 1;
      lpRecips := @MapiRecipDesc;
    end;


  per := GetTickCount;
  i := MapiSendMail(0, Application.Handle, MapiMessage, MAPI_DIALOG or MAPI_LOGON_UI or
    MAPI_NEW_SESSION, 0); result := i = SUCCESS_SUCCESS;

  if (i = MAPI_USER_ABORT) and (GetTickCount - per <= 1000) then
    begin
      msg := format('mailto:%s?subject=%s&body=%s', [RecipAddress, Subject, txt]);
      msg := StringReplace(msg, ' ', '%20', [rfReplaceAll]);
      msg := StringReplace(msg, #$0A, '%0A', [rfReplaceAll]);
      msg := StringReplace(msg, #$0D, '%0D', [rfReplaceAll]);
      TryOpenUrl(msg);
    end
  else
    if (showErr) and (not Result) then
      MessageBox(0, PChar(Format(exMailClientErr, [i, RecipName])), 'Error', MB_OK or MB_ICONERROR);
end;



end.

