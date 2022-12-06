unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus,
  uSelectFolder, uDuplicateFinder, uLog, ShellApi, uExeInfo,
  Vcl.ComCtrls, Vcl.ExtCtrls, System.ImageList, Vcl.ImgList;

type
  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    MenuFile: TMenuItem;
    MenuQuit: TMenuItem;
    N1: TMenuItem;
    MenuSearch: TMenuItem;
    LVFile: TListView;
    SBar: TStatusBar;
    LVFolder: TListView;
    Splitter: TSplitter;
    MenuReplica: TMenuItem;
    MenuRefresh: TMenuItem;
    MenuDelete: TMenuItem;
    MenuOpen: TMenuItem;
    MenuOpenFolder: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    ImageList: TImageList;
    MenuClearSearch: TMenuItem;
    MenuCancel: TMenuItem;
    MenuHelp: TMenuItem;
    MenuAbout: TMenuItem;
    procedure MenuQuitClick(Sender: TObject);
    procedure MenuSearchClick(Sender: TObject);
    procedure MenuCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LVFileColumnClick(Sender: TObject; Column: TListColumn);
    procedure LVFileCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure LVFolderDblClick(Sender: TObject);
    procedure LVFileSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure MenuOpenFolderClick(Sender: TObject);
    procedure MenuDeleteClick(Sender: TObject);
    procedure LVFolderCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure LVFolderCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure LVFolderKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MenuClearSearchClick(Sender: TObject);
    procedure LVFileDblClick(Sender: TObject);
    procedure LVFolderSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuAboutClick(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
     CancelTask : boolean;
     SearchFilesList : TSearchFilesList;
     LastColumnClick : integer;
     Tick : cardinal;
     procedure DFTBegin(Sender: TDuplicateFinderThread);
     procedure DFTFindFolder(Sender: TDuplicateFinderThread; FullPath : string);
     procedure DFTFindFile(Sender: TDuplicateFinderThread; FullPath : string);
     procedure DFTFindDuplicate(Sender: TDuplicateFinderThread; FilesList : TFilesList; FileInfo : TFileInfo);
     procedure DFTCancel(Sender: TDuplicateFinderThread; var Cancel : boolean);
     procedure DFTEnd(Sender: TDuplicateFinderThread);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.FormCreate(Sender: TObject);
begin
  Application.Title := 'Duplikachu';
  Caption := 'Duplikachu v' + GetVersionInfo(ParamStr(0), 'FileVersion') + ' - matthieulaurent.fr';
  LogToSpy('TMainForm.FormCreate');
  // créer la liste de recherche :
  SearchFilesList := TSearchFilesList.Create;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // libérer la liste de recherche :
  SearchFilesList.Free;

  LogToSpy('TMainForm.FormDestroy');
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.MenuAboutClick(Sender: TObject);
var str : string;
begin
  str := 'Duplikachu v' + GetVersionInfo(ParamStr(0), 'FileVersion') + #13#10 +
         'matthieulaurent.fr';
  // A propos :
  MessageBox(Self.Handle, PChar(str), 'A propos', MB_OK + MB_ICONINFORMATION);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.MenuCancelClick(Sender: TObject);
var str : string;
begin
  // message si la recherche est en cours :
  if SearchFilesList.InProgress then
    str := 'La recherche est en cours mais elle peut être arrêtée.' + #13#10;
  // afficher le messagebox de confirmation
  if MessageBox(Handle, PChar('Voulez-vous arrêter la recherche ?' + #13#10 + str + 'La liste de fichiers déjà inspéctés sera conservée.'), 'Arrêter la recherche ?', MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES then
    CancelTask := True;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.MenuClearSearchClick(Sender: TObject);
begin
  if MessageBox(Handle, PChar('Voulez-vous effacer la recherche ?' + #13#10 + 'Les listes des fichiers répliqués et des fichiers en cache seront vidées.'), 'Effacer la recherche ?', MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES then
  begin
    LVFile.Clear;
    LVFolder.Clear;
    SearchFilesList.Clear;
    SBar.Panels.Items[0].Text := '';
    SBar.Panels.Items[1].Text := '';
    SBar.Panels.Items[2].Text := '';
  end;

end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.MenuDeleteClick(Sender: TObject);
var i : integer;
begin
  if MessageBox(Handle, PChar('Voulez-vous supprimer les fichiers sélectionnés ?' + #13#10 + 'Attention, il seront définitivement effacés.'), 'Supprimer les fichiers ?', MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES then
  begin
    if LVFolder.SelCount > 0 then
      for i := 0 to LVFolder.Items.Count - 1 do
      begin
        if LVFolder.Items.Item[i].Selected then
          if not DeleteFile(LVFolder.Items.Item[i].Caption) then
            ShowMessage(SysErrorMessage(GetLastError))
      end;
    // refait le listView :
    LVFileSelectItem(LVFile, LVFile.Selected, LVFile.Selected.Selected);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.MenuOpenClick(Sender: TObject);
var i : integer;
begin
  if LVFolder.SelCount > 0 then
    for i := 0 to LVFolder.Items.Count - 1 do
    begin
      if LVFolder.Items.Item[i].Selected then
        if ShellExecute(Handle,'open',PChar(LVFolder.Items.Item[i].Caption),nil,nil,SW_SHOWNORMAL) <= 32 then ShowMessage(SysErrorMessage(GetLastError));
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.MenuOpenFolderClick(Sender: TObject);
var i : integer;
begin
  if LVFolder.SelCount > 0 then
    for i := 0 to LVFolder.Items.Count - 1 do
    begin
      if LVFolder.Items.Item[i].Selected then
        if ShellExecute(Handle, 'open', PChar('explorer.exe'), PChar('/select,"' + LVFolder.Items.Item[i].Caption + '"'), nil, SW_SHOWNORMAL) <= 32 then ShowMessage(SysErrorMessage(GetLastError));
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.MenuQuitClick(Sender: TObject);
begin
  Close;
end;



////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.MenuSearchClick(Sender: TObject);
var SearchFolder : string;
begin
  SearchFolder := 'C:\Users\matthieu\Desktop\Duplica'; // ##############
  if SelectFolder('Choisir le lecteur ou le dossier à inspecter pour l''analyse. La recherche de réplique de fichiers s''ajoute à l''éventuelle recherche précedente.', '', SearchFolder, self.Handle, false) then
  begin
    CancelTask := False;
    SBar.Panels.Items[0].Text := '';
    SBar.Panels.Items[1].Text := '';
    with TDuplicateFinderThread.Create(SearchFolder, SearchFilesList) do
    begin
     OnBegin         := DFTBegin;
     OnFindFolder    := DFTFindFolder;
     OnFindFile      := DFTFindFile;
     OnFindDuplicate := DFTFindDuplicate;
     OnCancel        := DFTCancel;
     OnEnd           := DFTEnd;
     // démarrer le thread (anciennement Resume())
     Start();
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.LVFileColumnClick(Sender: TObject; Column: TListColumn);
begin
  Column.Tag := 1 - Column.Tag;
  LastColumnClick := Column.Index;

  // faire le tri :
  LVFile.SortType := stNone;
  LVFile.SortType := stData;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.LVFileCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
var f1, f2 : TFilesList;
begin
  inherited;
  if (not assigned(Item1.Data)) OR (not assigned(Item2.Data)) then exit;

  f1 := TFilesList(Item1.Data);
  f2 := TFilesList(Item2.Data);

  case LastColumnClick of
   0 : begin // tri nom du fichier (de l'item) :
         Compare := CompareStr(item1.Caption, item2.Caption);
       end;
   1 : begin // taille
         Compare :=  f1.Items[0].Size - f2.Items[0].Size;
       end;
   2 : begin // type
        Compare := CompareStr(Item1.SubItems.Strings[1], Item2.SubItems.Strings[1]);
        // si identique : tri nom du fichier (de l'item) :
        if Compare = 0 then Compare :=  CompareStr(item1.Caption, item2.Caption);
       end;
   3 : begin // occurence
        Compare := f1.Count - f2.count;
       end;
  end;

  // tri par taille :
  if Compare = 0 then Compare :=  f1.Items[0].Size - f2.Items[0].Size;
  // tri par occurence :
  if Compare = 0 then Compare :=  f1.Count - f2.count;

  // on inverse le tri selon le clic de colonne
  if TListView(Sender).Columns.Items[LastColumnClick].Tag = 1 then
    Compare := - Compare;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.LVFileDblClick(Sender: TObject);
var Title: array[0..255] of WideChar;
    str : string;
begin
  str := Format('window:%d / application:%d / MainForm:%d', [self.Handle, application.Handle, application.MainFormHandle]);

  if GetWindowText(self.Handle, Title, 255) <> 0 then
    LogToSpy(Format('MainForm.Title OK string : %s (%s)', [Title, str]))
  else
    LogToSpy(Format('Title Error (%s)', [str]));

  if GetWindowText(Application.Handle, Title, 255) <> 0 then
    LogToSpy(Format('MainForm.Title OK string : %s (%s)', [Title, str]))
  else
    LogToSpy(Format('Title Error (%s)', [str]));

end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.LVFileSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var FilesList : TFilesList;
    i : integer;
    ListItem : TListItem;
    aIcon : TIcon;
    IconIndex : integer;
begin
  if LVFile.SelCount = 1 then
  begin
    if Selected then
    begin
      if Assigned(LVFile.Selected.Data) then
      begin
        LVFolder.Items.BeginUpdate;
        LVFolder.Clear;
        FilesList := TFilesList(LVFile.Selected.Data);
        for i := 0 to FilesList.Count - 1 do
        begin
          ListItem := LVFolder.Items.Add;
          ListItem.Caption := FilesList.Items[i].FullPath;
          ListItem.Data := FilesList.Items[i];
          // creer l'icone :
          IconIndex := -1;
          if assigned(LVFile.SmallImages) then
          begin
            aIcon := TIcon.Create;
            aIcon.Handle := GetShellIcon(FilesList.Items[i].FullPath);
            IconIndex := LVFile.SmallImages.AddIcon(aIcon);
            aIcon.Free;
          end;
          ListItem.ImageIndex := IconIndex;
        end;
        LVFolder.Items.EndUpdate;
      end;
    end
    else
      LVFolder.Clear;
  end
  else
    LVFolder.Clear;

  MenuRefresh.Enabled := LVFile.SelCount = 1;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.LVFolderCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  Compare := CompareStr(Item1.Caption, Item2.Caption);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.LVFolderCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var FileInfo : TFileInfo;
begin
  if not Assigned(Item) then exit;

  FileInfo := TFileInfo(item.Data);
  // mettre en gris (si pas selectionné)
  if not (cdsSelected in state) then
  begin
    if not FileInfo.Exists then
    begin
      // reprendre la couleur de fond du TListVie
      Sender.Canvas.Brush.Color := TListView(Sender).Color;
      Sender.Canvas.Font.Color := RGB(192, 192, 192);
    end;
  end;

  DefaultDraw := True;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.LVFolderDblClick(Sender: TObject);
begin
  if Assigned(LVFolder.Selected) then
    if ShellExecute(Handle,'open',PChar(LVFolder.Selected.Caption),nil,nil,SW_SHOWNORMAL) <= 32 then ShowMessage(SysErrorMessage(GetLastError));
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.LVFolderKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('A'))  then LVFolder.SelectAll;
  if (Key = VK_DELETE) then if LVFolder.Selcount > 0 then MenuDelete.Click;
  if (Key = VK_F5)     then if LVFolder.Selcount = 1 then LVFileSelectItem(LVFile, LVFile.Selected, LVFile.Selected.Selected);
  if (Key = VK_RETURN) then if LVFolder.Selcount = 1 then MenuOpen.Click;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.LVFolderSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  MenuOpen.Enabled       := LVFolder.SelCount > 0;
  MenuOpenFolder.Enabled := LVFolder.SelCount > 0;
  MenuDelete.Enabled     := LVFolder.SelCount > 0;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.DFTBegin(Sender: TDuplicateFinderThread);
begin

  Tick := GetTickCount();
  MenuCancel.Enabled := True;
  MenuClearSearch.Enabled := False;
  Cursor := crAppStart;
  LogToSpy('DFTBegin');
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.DFTFindFolder(Sender: TDuplicateFinderThread; FullPath : string);
begin
  SBar.Panels.Items[2].Text := FullPath;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.DFTFindFile(Sender: TDuplicateFinderThread; FullPath : string);
begin
  // fichier en cours d'inpection, on ne fait rien
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.DFTFindDuplicate(Sender: TDuplicateFinderThread; FilesList : TFilesList; FileInfo : TFileInfo);
var ListItem : TListItem;
    aIcon : TIcon;
    IconIndex : integer;
begin
  //LogToSpy(Format('FindDuplicate %s (x%d)', [FileInfo.FileName, FilesList.Count]));

  LVFile.Items.BeginUpdate;
  if Assigned(FilesList.Data) then
  begin
    ListItem := TListItem(FilesList.Data);
    ListItem.SubItems.Strings[2] := Format('%d', [FilesList.Count]);
  end
  else
  begin
    ListItem := LVFile.Items.Add;
    ListItem.Caption := FileInfo.FileName;
    ListItem.SubItems.Add(Format('%.0n', [FileInfo.Size + 0.0]));
    ListItem.SubItems.Add(UpperCase(ExtractFileExt(FileInfo.FileName)));
    ListItem.SubItems.Add(Format('%d', [FilesList.Count]));
    // creer l'icone :
    IconIndex := -1;
    if assigned(LVFile.SmallImages) then
    begin
      aIcon := TIcon.Create;
      aIcon.Handle := GetShellIcon(FileInfo.FullPath);
      IconIndex := LVFile.SmallImages.AddIcon(aIcon);
      aIcon.Free;
    end;
    ListItem.ImageIndex := IconIndex;

    // référence croisées :
    ListItem.Data := FilesList;
    FilesList.Data := ListItem;
  end;
  LVFile.Items.EndUpdate;

  // mise à jour des infos :
  SBar.Panels.BeginUpdate;
  SBar.Panels.Items[0].Text := Format('%.0n répliques ', [SearchFilesList.DuplicateFiles + 0.0]);
  SBar.Panels.Items[1].Text := Format('%.0n octets répliqués ', [SearchFilesList.DuplicateSize + 0.0]);
  SBar.Panels.EndUpdate;

end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.DFTCancel(Sender: TDuplicateFinderThread; var Cancel : boolean);
begin
  // répondre à la demande de cancel :
  Cancel := CancelTask;
  // log :
  if Cancel then
    LogToSpy('DFTCancel');
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.DFTEnd(Sender: TDuplicateFinderThread);
begin
  Cursor := crDefault;
  // afficher les resultats
  SBar.Panels.Items[2].Text := Format(' %d noms de fichier dans %s', [SearchFilesList.Count, TDuplicateFinderThread(Sender).FolderPath]);
    // faire le tri :
  LVFile.SortType := stNone;
  LVFile.SortType := stData;
  // menu
  MenuCancel.Enabled := False;
  MenuClearSearch.Enabled := True;
  // message de résultats de recherche :
  MessageBox(
    Self.Handle,
    PChar(
      Format('L''opération de recherche s''est terminée en %d seconde(s).', [(GetTickCount - Sender.Tick) div 1000]) + #13#10#13#10 +
      Format('Dossier inspecté : %s',           [Sender.FolderPath]) + #13#10 +
      Format('%d premiers octets comparés',     [FIRSTDATA_LENGTH]) + #13#10#13#10 +
      Format('%d nouveaux dossiers inspéctés,', [SearchFilesList.FolderCount]) + #13#10 +
      Format('%d nouveaux fichiers inspéctés,', [SearchFilesList.FileCount]) + #13#10 +
      Format('%d fichiers en cache,',           [SearchFilesList.Count]) + #13#10#13#10 +
      Format('%d répliques identiques,',        [SearchFilesList.DuplicateFiles]) + #13#10 +
      Format('%.0n octets répliqués.',          [SearchFilesList.DuplicateSize + 0.0])
    ),
    'Opération terminée',
    MB_OK + MB_ICONINFORMATION
  );
  LogToSpy('DFTEnd');
end;

end.
