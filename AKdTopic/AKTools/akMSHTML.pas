unit akMSHTML;
interface

uses Classes, MSHTML, shdocvw, BigIni;

type
  THTMLConfigManager = class
  private
    fParamList: TStringList;
    fIniParams: TStringList;
    fFile: string;
    fParam: TWebBrowser;
    FProcessMode: Integer;

    procedure SetParametersOfSelect(const Doc: IHTMLDocument2; FromSL: TStringList);
    procedure SetParametersOfInput(const Doc: IHTMLDocument2; FromSL: TStringList);
    procedure GetParametersOfSelect(const Doc: IHTMLDocument2; OutSL: TStringList);
    procedure GetParametersOfInput(const Doc: IHTMLDocument2; OutSL: TStringList);
    procedure SetProcessMode(const Value: Integer);

  public
    constructor Create(Param: TWebBrowser);
    destructor Destroy; override;

    // ≈сли 0 - работаем в режиме дл€ chm2web (var должен быть в начале всех
    // названий переменных и т.п. . ≈сли 1 - берем все ID элементов как есть.
    property ProcessMode: Integer read FProcessMode write SetProcessMode;

    // ¬озвращает значени€ всех полей. ћожно использовать дл€ определени€
    // изменилось поле или нет.
    procedure GetVariables(const doc: IHTMLDocument2; const arr: TStrings);

    procedure LoadFromFile(fl: string);
    procedure SaveToFile(fn: string);

    procedure FillFormsFromIni;
    procedure FillFormsFromList(list: TStringList);


    procedure Clear;

    property WebControl: TWebBrowser read fParam write fParam;
    property CurrentFile: string read fFile;

    function GetParameters: string;
    procedure SetParameters(vals: string);
  end;

implementation

uses SysUtils;

function QuoteStrings(str: string): string;
begin
{  int := StrToIntDef(str, -1025);
  if int = -1025 then
    Result := #1 + str + #1
  else
    Result := IntToStr(int);

  Result := StringReplace(Result, ' ', #127, [rfReplaceAll]);
  }
  Result := str;
end;

procedure THTMLConfigManager.Clear;
begin
  fParamList.Clear;
  fFile := '';
end;

constructor THTMLConfigManager.Create(Param: TWebBrowser);
begin
  fParamList := nil; fIniParams := nil; fProcessMode := 0;
  inherited Create;
  fParamList := TStringList.Create;
  fIniParams := TStringList.Create;
  WebControl := Param;
  Clear;
end;

destructor THTMLConfigManager.Destroy;
begin
  if Assigned(fIniParams) then fIniParams.Free;
  if Assigned(fParamList) then fParamList.Free;
  inherited;
end;

function THTMLConfigManager.GetParameters: string;
var
  Doc: IHTMLDocument2;
  i: Integer;
begin
  fParamList.BeginUpdate;
  try
    fParamList.Clear;
    Doc := WebControl.Document as IHTMLDocument2;
    GetParametersOfSelect(Doc, fParamList);
    GetParametersOfInput(Doc, fParamList);
  finally
    fParamList.EndUpdate;
  end;

  Result := StringReplace(fParamList.CommaText, '"', '', [rfReplaceAll]);
  Result := StringReplace(Result, #1, '"', [rfReplaceAll]);
end;

procedure THTMLConfigManager.GetParametersOfInput(const Doc: IHTMLDocument2;
  OutSL: TStringList);
var
  i: Integer;
  ElCol: IHTMLElementCollection;
  Els: IHTMLInputElement;
  nm: string;
begin
  ElCol := Doc.all.tags('input') as IHTMLElementCollection;
  for i := 0 to ElCol.length - 1 do begin
    Els := ElCol.item(i, 0) as IHTMLInputElement;
    nm := Els.name;//(Els as IHTMLElement).getAttribute('name', 0);
    if Copy(nm, 1, 4) = 'cvar' then begin
      if ELs.Checked then
        OutSL.Values[nm] := 'true'
      else
        OutSL.Values[nm] := 'false';
    end else
      OutSL.Values[nm] := QuoteStrings(Els.value);
  end;
end;

procedure THTMLConfigManager.GetParametersOfSelect(const Doc: IHTMLDocument2; OutSL: TStringList);
var
  i, m: Integer;
  ElCol, OpCol: IHTMLElementCollection;
  El: IHTMLElement;
  ElS: IHTMLSelectElement;
  ElO: IHTMLOptionElement;
  nm: string;
begin
  ElCol := Doc.all.tags('select') as IHTMLElementCollection;
  for i := 0 to ElCol.length - 1 do begin
    Els := ElCol.item(i, 0) as IHTMLSelectElement;
    OpCol := ((Els.options as IHTMLElement).all) as IHTMLElementCollection;
    for m := 0 to OpCol.length - 1 do begin
      ElO := (OpCol.item(m, 0) as IHTMLOptionElement);
      if ElO.selected then begin
        nm := Els.name;//getAttribute('name', 0);
        if Copy(nm, 1, 3) = 'var' then begin
          OutSL.Values[nm] := QuoteStrings(ELO.text);
          OutSL.Values['q' + nm] := IntToStr(ELO.index);
        end;
      end;
    end;
  end;
end;

procedure THTMLConfigManager.LoadFromFile(fl: string);
var ini: TBigIniFile;
begin
  fFile := fl;
  ini := TBigIniFile.Create(fFile);
  with ini do
  try
    fIniParams.Clear;
    ReadSectionValues('VAR', fIniParams);
  finally
    Free;
  end;
end;

procedure THTMLConfigManager.SaveToFile(fn: string);
var ini: TBigIniFile;
  i: Integer;
  tmps, nm: string;
  nms: TStringList;
  dc: IHTMLDocument2;
begin
  fFile := fn;
  if fFile = '' then exit;
  ini := TBigIniFile.Create(fFile);
  with ini do
  try
    fIniParams.Clear;

    nms := TStringList.Create;
    try
      dc := WebControl.Document as IHTMLDocument2;
      GetParametersOfSelect(dc, nms);
      GetParametersOfInput(dc, nms);

      for i := 0 to nms.Count - 1 do begin
        nm := nms.Names[i];
        WriteString('VAR', nm, Trim(nms.Values[nm]));
      end;
    finally
      nms.Free;
    end;

    for i := 0 to fIniParams.Count - 1 do begin
      nm := fIniParams.Names[i];
      WriteString('VAR', nm, fIniParams.Values[nm]);
    end;
  finally
    Free;
  end;
end;

procedure THTMLConfigManager.SetParameters(vals: string);
begin

end;

procedure THTMLConfigManager.SetParametersOfInput(
  const Doc: IHTMLDocument2; FromSL: TStringList);
var
  i: Integer;
  ElCol: IHTMLElementCollection;
  Els: IHTMLInputElement;
  nm: string;
begin
  ElCol := Doc.all.tags('input') as IHTMLElementCollection;
  for i := 0 to ElCol.length - 1 do begin
    Els := ElCol.item(i, 0) as IHTMLInputElement;
    nm := Els.name;//lgetAttribute('name', 0);
    if (Copy(nm, 1, 3) = 'var') or (fProcessMode <> 0) then begin
      if FromSL.Values['c' + nm] <> '' then
        Els.checked := FromSL.Values['c' + nm] = 'true'; //'YES';
      if FromSL.Values[nm] <> '' then
        Els.value := FromSL.Values[nm];
    end;
  end;
end;

procedure THTMLConfigManager.SetParametersOfSelect(
  const Doc: IHTMLDocument2; FromSL: TStringList);
var
  i: Integer;
  ElCol, OpCol: IHTMLElementCollection;
  ElS: IHTMLSelectElement;
  ElO: IHTMLOptionElement;
  nm: string;
  ind: Integer;
begin
{$IFDEF ASRT}lg.lassert($3CC82D8B, Assigned(Doc), ''); {$ENDIF}
  ElCol := Doc.all.tags('select') as IHTMLElementCollection;
  for i := 0 to ElCol.length - 1 do begin
    Els := ElCol.item(i, 0) as IHTMLSelectElement;
    nm := Els.name;//getAttribute('name', 0);

    OpCol := ((Els.options as IHTMLElement).all) as IHTMLElementCollection;
    ind := StrToIntDef(FromSL.Values['q' + nm], -1);
    if ind <> -1 then begin
      ElO := (OpCol.item(ind, 0) as IHTMLOptionElement);
      ELO.selected := true;
    end;
  end;


end;

procedure THTMLConfigManager.FillFormsFromIni;
begin
  FillFormsFromList(fIniParams);
end;


procedure THTMLConfigManager.GetVariables(const doc: IHTMLDocument2; const arr: TStrings);
begin
  arr.Clear;

  GetParametersOfSelect(doc, TStringList(arr));
  GetParametersOfInput(doc, TStringList(arr));
end;

procedure THTMLConfigManager.FillFormsFromList(list: TStringList);
var
  dc: IHTMLDocument2;
begin

  dc := WebControl.Document as IHTMLDocument2;
  SetParametersOfSelect(dc, list);
  SetParametersOfInput(dc, list);
end;

procedure THTMLConfigManager.SetProcessMode(const Value: Integer);
begin
  FProcessMode := Value;
end;

end.

