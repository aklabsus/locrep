unit akTotalLogView;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, akTotalLog,
  StdCtrls, XPCtrls, ExtCtrls, ComCtrls;

type
  TfTotalLogView = class(TForm)
    re: TRichEdit;
    fp: TXPFlatPanel;
    xb: TXPButton;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure fpResize(Sender: TObject);
  private
    { Private declarations }
    flg: TTotalLog;
  public
    constructor Create(lg: TTotalLog);
    destructor Destroy; override;

    procedure Execute;
  end;

var
  fTotalLogView: TfTotalLogView;

implementation

{$R *.DFM}

{ TfTotalLogView }

constructor TfTotalLogView.Create(lg: TTotalLog);
begin
  inherited Create(nil);
  flg := lg;
end;

destructor TfTotalLogView.Destroy;
begin
  inherited;
end;

procedure TfTotalLogView.Execute;
begin
  re.Lines.LoadFromFile(flg.FileName);
  ShowModal;
end;

procedure TfTotalLogView.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if key = #27 then close;
end;

procedure TfTotalLogView.fpResize(Sender: TObject);
begin
  xb.Left := fp.Width - xb.Width - 10;
end;

end.
