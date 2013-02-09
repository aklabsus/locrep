// AKTools akCustomProject unit.
//         Ѕазовый модуль дл€ VCL-проектов.
//=============================================================================


////////////////////////////////////////////////////////////////////////////////
//   ћодуль проектов                                //   by Dmitry Kudinov    //
// ѕроект есть ветвь реестра с запис€ми о настройке программы. ѕроект состоит
// из отдельных папок (folders). Ёти папки инкупсулированы в классы.
// TCustomProjectFolder €вл€етс€ предком этих классов. ƒл€ того, чтобы создать
// ветвь проекта необходимо перекрыть класс TCustomProjectFolder и сделать две
// вещи:
//   - вынести все свойства, которые необходимы сохранить, в раздел published.
//     ¬ процедуре сохранени€ этих свойств установить свойство Modify = true,
//     а значени€ по умолчанию установить в конструкторе
//   - перекрыть виртуальную функцию GetFolderName, котора€ должна возвращать
//     им€ ветки реестра. Ёто им€ €вл€етс€ относительным путем от пути основного
//     проекта (который задаетс€ в классе TProjectManager)
//    ласс TProjectManager представл€ет собой список проектов приложени€.
// »нициализаци€ этого списка заключаетс€ в указании пути к реестру, к тором
// будут хранитьс€ все папки приложени€. ѕеременна€ этого класса одна на прилоение.
// ѕомещать потомок TCustomProjectFolder в TProjectManager не нужно, т.к. он
// туда помещаетс€ в конструкторе.
// $Id: UCustomProject.pas,v 1.1.1.1 2000/03/29 11:04:04 dima Exp $
////////////////////////////////////////////////////////////////////////////////
unit akCustomProject;

interface

uses Windows, SysUtils, Classes, Registry, TypInfo, Forms, ExtCtrls;

type

  TPlacementCallbackProc = procedure(Registry: TRegistry) of object;

  // ѕредок всех проектов - одна папка из настроек реестра
  TCustomProjectFolder = class(TPersistent)
  private
    FModify: boolean;
    FLoading: boolean;
    procedure WriteRegistryInfo(Instance: TPersistent; ARegistry: TRegistry);
    procedure ReadRegistryInfo(Instance: TPersistent; ARegistry: TRegistry);
  protected
    function GetFolderName: string; virtual; abstract;
    procedure AfterWriting(ARegistry: TRegistry); virtual;
    procedure AfterReading(ARegistry: TRegistry); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    property Modify: boolean read FModify write FModify;
    property Loading: boolean read FLoading;
  end;

  // —писок папок проекта
  TProjectManager = class(TList)
  private
    FPath: string;
    procedure SetPath(const Value: string);
  public
    destructor Destroy; override;
    procedure Clear; override;
    procedure WriteFolders;
    procedure ReadFolders;
    procedure WriteFormPlacement(Form: TForm; Proc: TPlacementCallbackProc = nil);
    procedure ReadFormPlacement(Form: TForm; Proc: TPlacementCallbackProc = nil);
    property Path: string read FPath write SetPath;
  end;

var
  ProjectManager: TProjectManager;

implementation

////////////////////////////////////////////////////////////////////////////////
// =============================================================================
// TCustomProjectFolder
// =============================================================================
////////////////////////////////////////////////////////////////////////////////

procedure TCustomProjectFolder.AfterReading(ARegistry: TRegistry);
begin
end;

procedure TCustomProjectFolder.AfterWriting(ARegistry: TRegistry);
begin
end;

constructor TCustomProjectFolder.Create;
begin
  FModify := false;
  ProjectManager.Add(Self);
  FLoading := false;
end;

destructor TCustomProjectFolder.Destroy;
begin
  ProjectManager.Remove(Self);
  inherited;
end;

procedure TCustomProjectFolder.ReadRegistryInfo(Instance: TPersistent; ARegistry: TRegistry);
var
  PropertyCount, i, IntValue: integer;
  PL: PPropList;
  StrValue, OldPath: string;
  FloatValue: double;
begin
  with ARegistry do
  begin
    PL := nil;
    try
      PropertyCount := GetTypeData(Instance.ClassInfo).PropCount;
      GetMem(PL, PropertyCount * SizeOf(PPropInfo));
      GetPropInfos(Instance.ClassInfo, PL);
      for i := 0 to PropertyCount - 1 do
      begin
        if Integer(PL[i]^.StoredProc) = 1 then
        begin
          case PL[i]^.PropType^.Kind of
            tkInteger, tkEnumeration:
              begin
                try
                  IntValue := ReadInteger(PL^[i].Name);
                  SetOrdProp(Instance, PL^[i], IntValue);
                except
                  IntValue := GetOrdProp(Instance, PL^[i]);
                  WriteInteger(PL^[i].Name, IntValue);
                end;
              end;
            tkString, tkLString:
              begin
                StrValue := ReadString(PL^[i].Name);
                if StrValue <> '' then
                begin
                  SetStrProp(Instance, PL^[i], StrValue);
                end
                else
                begin
                  StrValue := GetStrProp(Instance, PL^[i]);
                  WriteString(PL^[i].Name, StrValue);
                end;
              end;
            tkFloat:
              begin
                try
                  FloatValue := ReadFloat(PL^[i].Name);
                  SetFloatProp(Instance, PL^[i], FloatValue);
                except
                  FloatValue := GetFloatProp(Instance, PL^[i]);
                  WriteFloat(PL^[i].Name, FloatValue);
                end;
              end;
            tkSet:
              begin
                try
                  StrValue := ReadString(PL^[i].Name);
                  SetSetProp(Instance, PL^[i], '[' + StrValue + ']');
                except
                  StrValue := GetSetProp(Instance, PL^[i]);
                  WriteString(PL^[i].Name, StrValue);
                end;
              end;
            tkClass:
              begin
                OldPath := '\' + CurrentPath;
                try
                  OpenKey(OldPath + '\' + PL^[i].Name, false);
                  ReadRegistryInfo(TPersistent(GetObjectProp(Instance, PL^[i])), ARegistry);
                finally
                  OpenKey(OldPath, false);
                end;
              end;
          end;
        end;
      end;
    finally
      if PL <> nil then FreeMem(PL);
    end;
  end;
end;

procedure TCustomProjectFolder.WriteRegistryInfo(Instance: TPersistent; ARegistry: TRegistry);
var
  PropertyCount, i: integer;
  PL: PPropList;
  OldPath: string;
begin
  PL := nil;
  with ARegistry do
  begin
    try
      PropertyCount := GetTypeData(Instance.ClassInfo).PropCount;
      GetMem(PL, PropertyCount * SizeOf(PPropInfo));
      GetPropInfos(Instance.ClassInfo, PL);
      for i := 0 to PropertyCount - 1 do
      begin
        if Integer(PL[i]^.StoredProc) = 1 then
        begin
          case PL[i]^.PropType^.Kind of
            tkInteger, tkEnumeration: WriteInteger(PL^[i].Name, GetOrdProp(Instance, PL^[i]));
            tkString, tkLString: WriteString(PL^[i].Name, GetStrProp(Instance, PL^[i]));
            tkFloat: WriteFloat(PL^[i].Name, GetFloatProp(Instance, PL^[i]));
            tkSet: WriteString(PL^[i].Name, GetSetProp(Instance, PL^[i]));
            tkClass:
              begin
                OldPath := '\' + CurrentPath;
                try
                  OpenKey(OldPath + '\' + PL^[i].Name, true);
                  WriteRegistryInfo(TPersistent(GetObjectProp(Instance, PL^[i])), ARegistry);
                finally
                  OpenKey(OldPath, false);
                end;
              end;
          end;
        end;
      end;
      FModify := false;
    finally
      if PL <> nil then FreeMem(PL);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// =============================================================================
// TProjectManager
// =============================================================================
////////////////////////////////////////////////////////////////////////////////

procedure TProjectManager.Clear;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    TCustomProjectFolder(Items[i]).Free;
  inherited Clear;
end;

destructor TProjectManager.Destroy;
begin
  WriteFolders;
  inherited;
end;

procedure TProjectManager.ReadFormPlacement(Form: TForm; Proc: TPlacementCallbackProc);
var
  WP: TWindowPlacement;
  Reg: TRegistry;
begin
  if FPath = '' then exit;
  Reg := TRegistry.Create;
  with Reg do
  begin
    try
      RootKey := HKEY_CURRENT_USER;
      OpenKey(Path + 'Forms\' + Form.ClassName, true);
      try
        ReadBinaryData('Placement', WP, SizeOf(TWindowPlacement));
        if WP.showCmd = SW_MAXIMIZE then
          Form.WindowState := wsMaximized
        else
          SetWindowPlacement(Form.Handle, @WP);
      except
      end;
      if Assigned(Proc) then Proc(Reg);
    finally
      Free;
    end;
  end;
end;

procedure TProjectManager.ReadFolders;
var
  i: integer;
  Registry: TRegistry;
begin
  if FPath = '' then exit;
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    for i := 0 to Count - 1 do
    begin
      with TCustomProjectFolder(Items[i]) do
      begin
        FLoading := true;
        try
          Registry.OpenKey(FPath + GetFolderName, true);
          ReadRegistryInfo(TCustomProjectFolder(Items[i]), Registry);
          AfterReading(Registry);
        finally
          FLoading := false;
        end;
      end;
    end;
  finally
    Registry.Free;
  end;
end;

procedure TProjectManager.SetPath(const Value: string);
begin
  if FPath <> Value then
  begin
    FPath := Value;
    if FPath[Length(FPath)] <> '\' then FPath := FPath + '\';
  end;
end;

procedure TProjectManager.WriteFolders;
var
  i: integer;
  Registry: TRegistry;
begin
  if FPath = '' then exit;
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    for i := 0 to Count - 1 do
    begin
      with TCustomProjectFolder(Items[i]) do
      begin
        if FModify then
        begin
          Registry.OpenKey(FPath + GetFolderName, true);
          WriteRegistryInfo(TCustomProjectFolder(Items[i]), Registry);
          AfterWriting(Registry);
        end;
      end;
    end;
  finally
    Registry.Free;
  end;
end;

procedure TProjectManager.WriteFormPlacement(Form: TForm; Proc: TPlacementCallbackProc);
var
  WP: TWindowPlacement;
  Reg: TRegistry;
begin
  if FPath = '' then exit;
  Reg := TRegistry.Create;
  with Reg do
  begin
    try
      RootKey := HKEY_CURRENT_USER;
      OpenKey(Path + 'Forms\' + Form.ClassName, true);
      try
        GetWindowPlacement(Form.Handle, @WP);
        WriteBinaryData('Placement', WP, SizeOf(TWindowPlacement));
      except
      end;
      if Assigned(Proc) then Proc(Reg);
    finally
      Free;
    end;
  end;
end;

initialization

  ProjectManager := TProjectManager.Create;

finalization

  ProjectManager.Free;

end.
