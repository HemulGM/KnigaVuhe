program Knigavuhe;

uses
  System.StartUpCopy,
  FMX.Forms,
  KVU.Main in 'KVU.Main.pas' {FormMain},
  HTML.Parser in '..\#Fork\HTML-Parser\HTML.Parser.pas',
  FMX.BASS.AAC in '..\BazaKnig\FMX.BASS.AAC.pas',
  FMX.BASS in '..\BazaKnig\FMX.BASS.pas',
  {$IFDEF ANDROID}
  FMX.Player.Android in '..\BazaKnig\FMX.Player.Android.pas',
  {$ENDIF }
  {$IFDEF MSWINDOWS}
  FMX.Player.Windows in '..\BazaKnig\FMX.Player.Windows.pas',
  {$ENDIF }
  FMX.Player in '..\BazaKnig\FMX.Player.pas',
  FMX.Player.Shared in '..\BazaKnig\FMX.Player.Shared.pas',
  KVU.Books in 'Classes\KVU.Books.pas',
  KVU.API in 'Classes\KVU.API.pas',
  KVU.Playlist in 'Classes\KVU.Playlist.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
