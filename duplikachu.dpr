program duplikachu;

uses
  Vcl.Forms,
  main in 'main.pas' {MainForm},
  uSelectFolder in '..\_commun\uSelectFolder.pas',
  uDuplicateFinder in 'uDuplicateFinder.pas',
  uLog in '..\spylog\uLog.pas',
  Vcl.Themes,
  Vcl.Styles,
  uExeInfo in '..\_commun\uExeInfo.pas';

{$R *.res}

begin
  Application.Title := 'Duplikachu';
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
