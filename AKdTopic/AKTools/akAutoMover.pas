unit akAutoMover;

interface

uses
  Classes, Menus, Windows, Controls, Forms;

const
  VM_MENUITEM = 0;
  VM_TOCLOSE = 1;
  VM_CONTROL = 2;

type
  TAutoMover = class(TThread)
  private
    FMenuItem: TMenuItem;
    FMode: Integer;
    FTargetForm: TForm;
    FTargetControl: TControl;
    procedure SetMenuItem(const Value: TMenuItem);
    procedure SetMode(const Value: Integer);
    procedure SetTargetForm(const Value: TForm);
    procedure SetTargetControl(const Value: TControl);
    { Private declarations }

  private
    prevX: Integer;
    prevY: Integer;

  protected
    procedure Execute; override;

    procedure MoveMouseToMenuItem(target: TMenuItem);
    procedure MoveMouseToAnyMenuItem(target: TMenuItem);
    procedure MoveMouseToClose(target: TForm);
    procedure MoveMouseToControl(target: TControl);

    procedure PressLeftButton;
    procedure MoveMouseToPos(toPos: TPoint);

    property MenuItem: TMenuItem read FMenuItem write SetMenuItem;
    property TargetForm: TForm read FTargetForm write SetTargetForm;
    property TargetControl: TControl read FTargetControl write SetTargetControl;
  public
    property Mode: Integer read FMode write SetMode;

    procedure ExecuteMenuItem(mn: TMenuItem);
    procedure ExecuteCloseForm(fm: TForm);
    procedure ExecuteControl(cnt: TControl);
  end;

implementation

uses akMisc, akDataUtils;

{ TAutoMover }

procedure TAutoMover.Execute;
begin
  case Mode of
    VM_MENUITEM: MoveMouseToAnyMenuItem(MenuItem);
    VM_TOCLOSE: MoveMouseToClose(TargetForm);
    VM_CONTROL: MoveMouseToControl(TargetControl);
  end;
end;

procedure TAutoMover.MoveMouseToMenuItem(target: TMenuItem);
var toPos: TPoint;
  rc: TRect;
begin
  GetMenuItemRect(TWinControl(target.Owner).Handle, target.Parent.Handle, target.MenuIndex, rc);

  toPos.X := iifs(prevX = 0, rc.Left + 20, prevX + 20);
  toPos.Y := rc.Top + 8;

//  if prevX <> 0 then
//    prevX := rc.Left
//  else
  prevX := rc.Left;

  prevY := rc.Top;

  MoveMouseToPos(toPos);
  PressLeftButton;
end;

procedure TAutoMover.MoveMouseToAnyMenuItem(target: TMenuItem);
var i: Integer;
  par: TList;
  l: TMenuItem;
begin
  prevX := 0; prevY := 0;
  par := TList.Create;
  try
    l := target;
    while Assigned(l) do
      begin
        par.Add(l);
        l := l.Parent;
      end;
    par.Delete(par.Count - 1);

    for i := par.Count - 1 downto 0 do
      MoveMouseToMenuItem(par[i]);

  finally
    par.Free;
  end;
end;

procedure TAutoMover.PressLeftButton;
begin
  mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
  Sleep(100);
  mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
  Sleep(300);
end;

procedure TAutoMover.MoveMouseToPos(toPos: TPoint);
var
  p: TPoint;
  r: TRect;
  dst: Integer;
  ps: TPoint;
begin
  repeat
    GetCursorPos(ps);
    r := Rect(ps.x, ps.y, toPos.x, toPos.y); dst := DistOf(r);
    p := MovePointTo(r, 5);
    SetCursorPos(p.x, p.y);
    Sleep(10);
    if dst < 5 then dst := 0;
  until dst <= 0;
end;

procedure TAutoMover.SetMenuItem(const Value: TMenuItem);
begin
  FMenuItem := Value;
end;

procedure TAutoMover.ExecuteMenuItem(mn: TMenuItem);
begin
  Mode := VM_MENUITEM;
  MenuItem := mn;
  Resume;
end;

procedure TAutoMover.SetMode(const Value: Integer);
begin
  FMode := Value;
end;

procedure TAutoMover.MoveMouseToClose(target: TForm);
var toPos: TPoint;
begin
  with target do
    begin
      toPos.X := Left + Width - 15;
      toPos.Y := Top + 15;
    end;

  MoveMouseToPos(toPos);
  PressLeftButton;
end;

procedure TAutoMover.SetTargetForm(const Value: TForm);
begin
  FTargetForm := Value;
end;

procedure TAutoMover.ExecuteCloseForm(fm: TForm);
begin
  Mode := VM_TOCLOSE;
  TargetForm := fm;
  Resume;
end;

procedure TAutoMover.MoveMouseToControl(target: TControl);
var toPos: TPoint;
  rc: TRect;
begin
  with target do
    begin
      rc := ClientRect;
      toPos.X := rc.Left + Round(ClientWidth / 2);
      toPos.Y := rc.Top + Round(ClientHeight / 2);
      toPos := ClientToScreen(toPos);
    end;

  MoveMouseToPos(toPos);
  PressLeftButton;
end;

procedure TAutoMover.SetTargetControl(const Value: TControl);
begin
  FTargetControl := Value;
end;

procedure TAutoMover.ExecuteControl(cnt: TControl);
begin
  Mode := VM_CONTROL;
  TargetControl := cnt;
  Resume;
end;

end.

