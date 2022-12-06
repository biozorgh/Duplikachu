{*******************************************************************************
  Matthieu LAURENT
 unité
*******************************************************************************}
unit uSelectFolder;

interface

uses
  Windows, ShellApi, ShlObj, Activex;

function SelectFolder(const Caption: string; const Root: WideString; var Directory: string; Owner: HWND; CreateFolderOption : boolean): Boolean;

implementation

////////////////////////////////////////////////////////////////////////////////
function SelectDirCB(Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer
stdcall;
begin
  if (uMsg = BFFM_INITIALIZED) and (lpData <> 0) then
    SendMessage(Wnd, BFFM_SETSELECTION, Integer(True), lpdata);
  Result := 0;
end;

////////////////////////////////////////////////////////////////////////////////
function SelectFolder(const Caption: string; const Root: WideString; var Directory: string; Owner: HWND; CreateFolderOption : boolean): Boolean;
var
  BrowseInfo: TBrowseInfo;
  Buffer: PChar;
  RootItemIDList, ItemIDList: PItemIDList;
  ShellMalloc: IMalloc;
  IDesktopFolder: IShellFolder;
  Eaten, Flags: LongWord;
begin
  Result := False;
  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
  if (ShGetMalloc(ShellMalloc) = S_OK) and (ShellMalloc <> nil) then
  begin
    Buffer := ShellMalloc.Alloc(MAX_PATH);
    try
      SHGetDesktopFolder(IDesktopFolder);
      if Root = '' then
        RootItemIDList := nil
      else
        IDesktopFolder.ParseDisplayName(Owner, nil, POleStr(Root), Eaten, RootItemIDList, Flags);
      with BrowseInfo do
      begin
        hwndOwner := Owner;
        pidlRoot := RootItemIDList;
        pszDisplayName := Buffer;
        lpszTitle := PChar(Caption);
        ulFlags := BIF_RETURNONLYFSDIRS + BIF_NEWDIALOGSTYLE + BIF_DONTGOBELOWDOMAIN + BIF_STATUSTEXT;
        {
        if CreateFolderOption then
         //ulFlags := ulFlags + BIF_NEWDIALOGSTYLE + BIF_EDITBOX;
         ulFlags := ulFlags + BIF_NEWDIALOGSTYLE + $0100; //BIF_UAHINT;
         // http://msdn.microsoft.com/en-us/library/windows/desktop/bb773205%28v=vs.85%29.aspx
        } 
        lpfn := SelectDirCB;
        lparam := Integer(PChar(Directory));
      end;
      ItemIDList := ShBrowseForFolder(BrowseInfo);
      Result :=  ItemIDList <> nil;
      if Result then
      begin
        ShGetPathFromIDList(ItemIDList, Buffer);
        ShellMalloc.Free(ItemIDList);
        Directory := Buffer;
      end;
    finally
      ShellMalloc.Free(Buffer);
    end;
  end;
end;

end.
