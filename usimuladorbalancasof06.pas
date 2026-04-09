unit uSimuladorBalancaSOF06;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls;

type

  { TfrmSimuladorBalancaoSOF06 }

  TfrmSimuladorBalancaoSOF06 = class(TForm)
    btnAtivarServidorBalanca: TBitBtn;
    ListBox1: TListBox;
    procedure btnAtivarServidorBalancaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject); override;
  private
    FPorta: Integer;
    FIntervalo: Integer; // em milissegundos
    FSocket: TTCPBlockSocket;
    function GerarPesoSOF06: string;
  public

  end;

var
  frmSimuladorBalancaoSOF06: TfrmSimuladorBalancaoSOF06;

implementation

{$R *.lfm}

{ TfrmSimuladorBalancaoSOF06 }

procedure TfrmSimuladorBalancaoSOF06.btnAtivarServidorBalancaClick(Sender: TObject);
var
  Cliente: TSocket;
  ClienteSock: TTCPBlockSocket;
begin
  FSocket := TTCPBlockSocket.Create;
    try
      FSocket.CreateSocket;
      FSocket.SetLinger(True, 10);
      FSocket.Bind('0.0.0.0', IntToStr(FPorta));
      FSocket.Listen;

      WriteLn('Servidor TCP iniciado na porta ', FPorta);

      while not Terminated do
      begin
        if FSocket.CanRead(100) then
        begin
          Cliente := FSocket.Accept;
          if Cliente >= 0 then
          begin
            ClienteSock := TTCPBlockSocket.Create;
            ClienteSock.Socket := Cliente;
            try
              WriteLn('Cliente conectado: ', ClienteSock.GetRemoteSinIP);
              while (not Terminated) and (ClienteSock.LastError = 0) do
              begin
                ClienteSock.SendString(GerarPesoSOF06);
                Sleep(FIntervalo);
              end;
            finally
              ClienteSock.Free;
              WriteLn('Cliente desconectado.');
            end;
          end;
        end;
      end;
    finally
      FSocket.Free;
    end;
end;

procedure TfrmSimuladorBalancaoSOF06.FormCreate(Sender: TObject);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FPorta := 5000;
  FIntervalo := 1;
  Randomize;
end;

procedure TfrmSimuladorBalancaoSOF06.FormDestroy(Sender: TObject);
begin
  inherited Destroy;
end;

function TfrmSimuladorBalancaoSOF06.GerarPesoSOF06: string;
var
  peso: Double;
  pesoStr: string;
begin
  // Simula um peso aleatório entre 0 e 30000 kg
  peso := Random(30000) + Random; // inclui casas decimais
  // Formato SOF06 típico: STX + peso(6 dígitos) + CRLF
  // Aqui vamos simular: <STX>PPPPPP<CR><LF>
  pesoStr := Format('%06.0f', [peso]); // sem casas decimais
  Result := #2 + pesoStr + #13#10; // STX= #2
end;

end.

