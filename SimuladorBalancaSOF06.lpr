program SimuladorBalancaSOF06;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, blcksock, synsock, synautil;

type
  TBalancaTCP = class(TThread)
  private
    FPorta: Integer;
    FIntervalo: Integer; // em milissegundos
    FSocket: TTCPBlockSocket;
    function GerarPesoSOF06: string;
  protected
    procedure Execute; override;
  public
    constructor Create(APorta, AIntervalo: Integer);
    destructor Destroy; override;
  end;

{ TBalancaTCP }

function TBalancaTCP.GerarPesoSOF06: string;
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

procedure TBalancaTCP.Execute;
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

constructor TBalancaTCP.Create(APorta, AIntervalo: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FPorta := APorta;
  FIntervalo := AIntervalo;
  Randomize;
end;

destructor TBalancaTCP.Destroy;
begin
  inherited Destroy;
end;

var
  Servidor: TBalancaTCP;
begin
  try
    // Porta 5000, intervalo de 1 segundo
    Servidor := TBalancaTCP.Create(5000, 1000);
    WriteLn('Pressione ENTER para encerrar...');
    ReadLn;
    Servidor.Terminate;
    Sleep(500);
  except
    on E: Exception do
      WriteLn('Erro: ', E.Message);
  end;
end.
