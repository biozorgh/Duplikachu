{///////////////////////////////////////////////////////////////////////////////


 ┌─ TDuplicateFinderThread
 └─ TSearchFilesList
      ├─ TFilesList
      │    ├─ TFileInfo
      │    ├─ TFileInfo
      │    ├─ TFileInfo
      │    └─ ...
      ├─ TFilesList
      │    ├─ TFileInfo
      │    └─ ...
      ├─ TFilesList
      ├─ TFilesList
      └─ ...


///////////////////////////////////////////////////////////////////////////////}
unit uDuplicateFinder;

interface

uses Windows, SysUtils, Classes, ShellAPI, uLog;

const
  FIRSTDATA_LENGTH = 10000; // on compare sur FIRSTDATA_LENGTH premiers octets

type
  TArrayOfByte = array of byte;

type
  TFileInfo = class
  private
    fFileName : string;
    fFullPath : string;
    fFirstData : TArrayOfByte;
    fSize : int64;
    function fGetExists : boolean;
    function fGetFirstDataLength : integer;
  public
    property FileName  : string read fFileName write fFileName;
    property FullPath  : string read fFullPath write fFullPath;
    property FirstData : TArrayOfByte read fFirstData write fFirstData;
    property Size : int64 read fSize write fSize;
    property Exists : boolean read fGetExists;
    property FirstDataLength : integer read fGetFirstDataLength;
    destructor Destroy; override;
    function ReadFirstData : integer;
  end;


type
  TFilesList = class(TList)
  private
    fData : Pointer;
    function Get(Index: Integer): TFileInfo;
  public
    property Data : Pointer read fData write fData;
    property Items[Index: Integer]: TFileInfo read Get; default;
    constructor Create(FileInfo : TFileInfo);
    destructor Destroy; override;
    function Add(Value: TFileInfo): Integer;
    procedure Clear; override;
    function FindFullFileName(FileName : string) : TFileInfo;
  end;


type
  TSearchFilesList = class(TList)
  private
    fInProgress      : boolean;
    fFileCount       : int64;
    fFolderCount     : int64;
    fDuplicateSize   : int64;
    fDuplicateFiles  : int64;
    function Get(Index: Integer): TFilesList;
  public
    property InProgress       : boolean         read fInProgress;
    property FileCount        : int64           read fFileCount;
    property FolderCount      : int64           read fFolderCount;
    property DuplicateSize    : int64           read fDuplicateSize;
    property DuplicateFiles   : int64           read fDuplicateFiles;
    property Items[Index: Integer]: TFilesList read Get; default;
    constructor Create();
    destructor Destroy; override;
    function Add(Value: TFilesList): Integer;
    procedure Clear; override;
    function FindFilesList(FileName : string) : TFilesList;
  end;


type
 TDuplicateFinderThread = class;
 TNotifyFinderEvent = procedure(Sender: TDuplicateFinderThread) of object;
 TNotifyExecuteCountEvent = procedure(Sender: TDuplicateFinderThread; Count : integer) of object;
 TNotifyCancelEvent = procedure(Sender: TDuplicateFinderThread; var Cancel : boolean) of object;
 TNotifyFindEvent = procedure(Sender: TDuplicateFinderThread; FullPath : string) of object;
 TNotifyFindDuplicateEvent = procedure(Sender: TDuplicateFinderThread; FilesList : TFilesList; FileInfo : TFileInfo) of object;


  TDuplicateFinderThread = class(TThread)
  private
    fTick            : cardinal;
    fSearchFilesList : TSearchFilesList;
    // paramètres d'évennement :
    fCancel     : boolean;
    fFolderPath : string;
    fFindFolder : string;
    fFindFile   : string;
    fFilesList  : TFilesList;
    fFileInfo   : TFileInfo;
    // évennements :
    fOnBegin         : TNotifyFinderEvent;
    fOnFindFolder    : TNotifyFindEvent;
    fOnFindFile      : TNotifyFindEvent;
    fOnFindDuplicate : TNotifyFindDuplicateEvent;
    fOnCancel        : TNotifyCancelEvent;
    fOnEnd           : TNotifyFinderEvent;
    // procédure privée :
    procedure OnTerminateProcedure(Sender : TObject);
    procedure RecurseFindFile(FolderPath : string);
  protected
    procedure Execute; override;
    procedure DoBegin;
    procedure DoFindFolder;
    procedure DoFindFile;
    procedure DoFindDuplicate;
    procedure DoCancel;
    procedure DoEnd;
  public
    property Tick            : cardinal                  read fTick;
    property FolderPath      : string                    read fFolderPath;
    property Cancel          : boolean                   read fCancel;
    property OnBegin         : TNotifyFinderEvent        read fOnBegin         write fOnBegin;
    property OnFindFolder    : TNotifyFindEvent          read fOnFindFolder    write fOnFindFolder;
    property OnFindFile      : TNotifyFindEvent          read fOnFindFile      write fOnFindFile;
    property OnFindDuplicate : TNotifyFindDuplicateEvent read fOnFindDuplicate write fOnFindDuplicate;
    property OnCancel        : TNotifyCancelEvent        read fOnCancel        write fOnCancel;
    property OnEnd           : TNotifyFinderEvent        read fOnEnd           write fOnEnd;
    constructor Create(FolderPath : string; SearchFilesList : TSearchFilesList); overload;
    destructor Destroy; override;
    function CreateFileInfo(FullFileName : string): TFileInfo;
  end;

function GetShellIcon(aFileName : string): THandle;
function MyFileExists(FileName: String): Boolean;
function SizeToStr(Sz: int64): String;

implementation


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
function GetShellIcon(aFileName : string): THandle;
var FileInfo: TSHFileInfo;
    Flags: integer;
begin
  // Récupération de l'icône
  FillMemory(@FileInfo,SizeOf(TSHFileInfo),0);
  Flags := SHGFI_ICON + SHGFI_TYPENAME + SHGFI_USEFILEATTRIBUTES + SHGFI_SMALLICON;
  SHGetFileInfo(
    PChar('*' + ExtractFileExt(aFileName)),
    //0,
    FILE_ATTRIBUTE_NORMAL,
    FileInfo,
    SizeOf(FileInfo),
    Flags);
  Result := FileInfo.hIcon;
end;

////////////////////////////////////////////////////////////////////////////////
function MyFileExists(FileName: String): Boolean;
var  dwAttr:     LongWord;
begin
  dwAttr:=GetFileAttributes(PChar(FileName));
  result:=((dwAttr and FILE_ATTRIBUTE_DIRECTORY) = 0) and (dwAttr <> $FFFFFFFF);
end;

////////////////////////////////////////////////////////////////////////////////
function MyGetFileSize(const FileName: string): Int64;
var AttributeData: TWin32FileAttributeData;
begin
  if GetFileAttributesEx(PChar(FileName), GetFileExInfoStandard, @AttributeData) then
  begin
    Int64Rec(Result).Lo := AttributeData.nFileSizeLow;
    Int64Rec(Result).Hi := AttributeData.nFileSizeHigh;
  end
  else
    Result := -1;
end;

////////////////////////////////////////////////////////////////////////////////
function ReadFileFirstData(FileName : string; DataCount : int64; var Bytes : TArrayOfByte) : int64;
var //MemoryStream : TMemoryStream;
    aFileSize : int64;
    ArraySize : int64;
    F: file of Byte;
begin
  Result := 0;
  SetLength(Bytes, 0);
  aFileSize := MyGetFileSize(FileName);
  if aFileSize > 0 then
  begin
    //LogToSpy(Format('FileName: %s (%d)', [FileName, aFileSize]));
    if aFileSize < DataCount then ArraySize := aFileSize
    else  ArraySize := DataCount;

    try
      AssignFile(F, FileName);
      FileMode := fmOpenRead;
      Reset(F);
      SetLength(Bytes, ArraySize);
      //MemoryStream := TMemoryStream.Create;
      //MemoryStream.LoadFromFile(FileName);
      BlockRead(F, Bytes[0], ArraySize);
      //MemoryStream.Read(Bytes[0], ArraySize);
      //MemoryStream.Free;
    finally
      CloseFile(F);
    end;

    Result := ArraySize;
  end;
end;



////////////////////////////////////////////////////////////////////////////////
function SizeToStr(Sz: int64): String;
Resourcestring
  strMinSize = '0 octets';
  strKo = '%s Ko'; // Kilobyte
  strMo = '%s Mo'; // Megabyte
  strGo = '%s Go'; // Gigabyte
  strOct = '%s octets';
Const
  cstFloatFmt = '#.#0';
  cstOneKo = 1024;
  cstOneMo = cstOneKo * 1024;
  cstOneGo = cstOneMo * 1024;
Begin
  Result := strMinSize;
  If (Sz = 0) Then
    Exit;
  If (Sz <= cstOneKo) Then
  Begin
    Result := Format(strOct, [FormatFloat(cstFloatFmt, Sz)]);
    Exit;
  End;
  If (Sz <= cstOneMo) Then
  Begin
    Result := Format(strKo, [FormatFloat(cstFloatFmt, Sz / cstOneKo)]);
    Exit;
  End;
  If (Sz <= cstOneGo) Then
  Begin
    Result := Format(strMo, [FormatFloat(cstFloatFmt, Sz / (cstOneMo))]);
    Exit;
  End;
  Result := Format(strGo, [FormatFloat(cstFloatFmt, Sz / (cstOneGo))]);
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
destructor TFileInfo.Destroy;
begin
 SetLength(fFirstData, 0);
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////
function TFileInfo.ReadFirstData : integer;
begin
  Result := ReadFileFirstData(fFullPath, FIRSTDATA_LENGTH, fFirstData);
end;


////////////////////////////////////////////////////////////////////////////////
function TFileInfo.fGetExists : boolean;
begin
  result := MyFileExists(fFullPath);
end;

////////////////////////////////////////////////////////////////////////////////
function TFileInfo.fGetFirstDataLength : integer;
begin
  Result := Length(fFirstData);
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
constructor TFilesList.Create(FileInfo : TFileInfo);
begin
  inherited Create;
  fData := nil;
  if Assigned(FileInfo) then
    Add(FileInfo);
end;

////////////////////////////////////////////////////////////////////////////////
destructor TFilesList.Destroy;
begin
  Clear;
  inherited;
end;

////////////////////////////////////////////////////////////////////////////////
function TFilesList.Add(Value : TFileInfo): Integer;
begin
  Result := inherited Add(Value);
end;


////////////////////////////////////////////////////////////////////////////////
function TFilesList.Get(Index : Integer): TFileInfo;
begin
  Result := TFileInfo(inherited Get(Index));
end;


////////////////////////////////////////////////////////////////////////////////
procedure TFilesList.Clear;
var i: Integer;
    FileInfo : TFileInfo;
begin
  if count > 0 then
  begin
    for i := 0 to Count - 1 do
    begin
      FileInfo := TFileInfo(Items[i]);
      FileInfo.Free;
    end;
  end;

  inherited Clear;
end;

////////////////////////////////////////////////////////////////////////////////
function TFilesList.FindFullFileName(FileName : string) : TFileInfo;
var i : integer;
begin
  Result := nil;
  if count > 0 then
    for i := 0 to Count - 1 do
      if CompareStr(FileName, Items[i].FullPath) = 0 then
        Result := Items[i];

end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
constructor TSearchFilesList.Create();
begin
  inherited Create;
  fInProgress     := False;
  fFileCount      := 0;
  fFolderCount    := 0;
  fDuplicateSize  := 0;
  fDuplicateFiles := 0;
end;

////////////////////////////////////////////////////////////////////////////////
destructor TSearchFilesList.Destroy;
begin
  Clear;
  inherited;
end;

////////////////////////////////////////////////////////////////////////////////
function TSearchFilesList.Add(Value: TFilesList): Integer;
begin
  Result := inherited Add(Value);
end;

////////////////////////////////////////////////////////////////////////////////
function TSearchFilesList.Get(Index: Integer): TFilesList;
begin
  Result := TFilesList(inherited Get(Index));
end;


////////////////////////////////////////////////////////////////////////////////
procedure TSearchFilesList.Clear;
var i: Integer;
    FilesList : TFilesList;
begin
  if count > 0 then
  begin
    for i := 0 to Count - 1 do
    begin
      FilesList := TFilesList(Items[i]);
      FilesList.Free;
    end;
  end;

  fFileCount      := 0;
  fFolderCount    := 0;
  fDuplicateSize  := 0;
  fDuplicateFiles := 0;
  inherited Clear;
end;


////////////////////////////////////////////////////////////////////////////////
function TSearchFilesList.FindFilesList(FileName : string) : TFilesList;
var i : integer;
    FilesList : TFilesList;
    Size : int64;
    Bytes : TArrayOfByte;
    FileInfoZero : TFileInfo;
    CompareSize : int64;
    //TickSearch : cardinal;
begin
  Result := nil;
  //TickSearch := GetTickCount();
  if Count > 0 then
  for i := 0 to Count - 1 do
  begin
    FilesList := Get(i);
    if FilesList.Count > 0 then
    begin
      // cherhcer une liste de fichier avec le même nom
      // comparer avec le fichier d'index 0
      FileInfoZero := FilesList.Items[0];
      // on commence avec le nom
      if CompareStr(ExtractFileName(FileName), FileInfoZero.FileName) = 0 then
      begin
        // comparer avec la taille :
        Size := MyGetFileSize(FileName);
        if Size = FileInfoZero.fSize then
        begin
          // taille à zero :
          if Size = 0 then
          begin
            // la liste existe déjà,
            Result := FilesList;
            // pas de test de contenu,
            break;
          end;
          // comparer le contenu (le début) :
          CompareSize := ReadFileFirstData(FileName, FIRSTDATA_LENGTH, Bytes);
          if CompareMem(Bytes, FileInfoZero.fFirstData, CompareSize) then
          begin
            Result := FilesList;
            break;
          end;
        end;
      end;
    end;
  end;
  //LogToSpy(Format('FindFilesList Count:%d searchtime:%dms', [Count, GetTickCount - TickSearch]));
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
constructor TDuplicateFinderThread.Create(FolderPath : string; SearchFilesList : TSearchFilesList);
begin
  inherited Create(True); // suspended (call resume()/Start() )
  FreeOnTerminate := True;
  Priority := tpLowest;
  // evennements :
  fOnBegin := nil;
  fOnCancel := nil;
  fOnEnd := nil;
  OnTerminate := OnTerminateProcedure;  // pas utilisée
  // variables
  fCancel     := false;
  fFolderPath := '';
  fFindFolder := '';
  fFindFile   := '';
  fFilesList  := nil;
  fFileInfo   := nil;
  fCancel     := False;
  fFolderPath := FolderPath;
  fSearchFilesList := SearchFilesList;
  fSearchFilesList.fFileCount   := 0;
  fSearchFilesList.fFolderCount := 0;
end;

////////////////////////////////////////////////////////////////////////////////
destructor TDuplicateFinderThread.Destroy;
begin
 // ne pas libérer les données (on s'en sert peut-être ailleurs).
 // détruire le Thread normalement :
 inherited Destroy;
end;


////////////////////////////////////////////////////////////////////////////////
procedure TDuplicateFinderThread.OnTerminateProcedure(Sender: TObject);
begin
  // fin
end;


////////////////////////////////////////////////////////////////////////////////
function TDuplicateFinderThread.CreateFileInfo(FullFileName : string): TFileInfo;
var FileInfo : TFileInfo;
begin
  FileInfo := TFileInfo.Create;
  FileInfo.fFileName := ExtractFileName(FullFileName);
  FileInfo.fFullPath := FullFileName;
  FileInfo.fSize := MyGetFileSize(FullFileName);
  // lire les premiers octets
  FileInfo.ReadFirstData;
  // retourner l'objet créé :
  Result := FileInfo;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TDuplicateFinderThread.RecurseFindFile(FolderPath : string);
var searchResult : TSearchRec;
    fSearchDir : string;
    fSearchName : string;
    aDir : string;
    FileInfo : TFileInfo;
    TickFindFile, DeltaTick : cardinal;
begin
  // dossier d'exploration :
  aDir := IncludeTrailingPathDelimiter(FolderPath);
  aDir := StringReplace(aDir, '\\', '\', [rfReplaceAll, rfIgnoreCase]);
  if FindFirst(aDir + '*', faAnyFile, searchResult) = 0 then
  begin
    // scan du premier dossier (on le compte) :
    fSearchFilesList.fFolderCount := fSearchFilesList.fFolderCount + 1;
    // boucle d'énumération de fichier dans le dossier :
    repeat
      // vérifier le Cancel
      Synchronize(DoCancel);
      // on sort de la boucle
      if fCancel then break;

      if (searchResult.Name <> '.') and (searchResult.Name <> '..') then
      begin
        // mise à jour du dossier d'exploration :
        fSearchDir   := aDir + searchResult.Name;   // chemin complet
        fSearchName  := searchResult.Name;          // nom du dossier/fichier seul


        if (searchResult.attr and faDirectory) = faDirectory then
        begin
          // s'il s'agit d'un dossier
          fSearchFilesList.fFolderCount := fSearchFilesList.fFolderCount + 1;
          // déclencher l'evennement :
          fFindFolder := fSearchDir;
          Synchronize(DoFindFolder);
          // récursivité :
          RecurseFindFile(fSearchDir);
        end
        else
        begin
          // s'il s'agit d'un fichier

          TickFindFile := GetTickCount();

          fSearchFilesList.fFileCount := fSearchFilesList.fFileCount + 1;
          // Déclencher l'evennement :
          fFindFile := fSearchDir;
          Synchronize(DoFindFile);
          // le fichier existe-t-il déjà dans une liste ? tester les duplicats :
          fFilesList := fSearchFilesList.FindFilesList(fSearchDir);
          if Assigned(fFilesList) then
          begin
            // le même fichier est-il déja listé (même emplacement, même nom) dans la liste ?
            FileInfo := fFilesList.FindFullFileName(fSearchDir);
            if not Assigned(FileInfo) then
            begin
              // le même fichier n'exite pas déjà, on peut le rajouter :
              // fichier dupliqué (on rajoute à la liste des fichier identiques) :
              fFileInfo := CreateFileInfo(fSearchDir);
              // taille des fichiers duplicata :
              fSearchFilesList.fDuplicateSize := fSearchFilesList.fDuplicateSize + fFileInfo.fSize;
              // si un seul fichier déjà dans la liste
              if fFilesList.Count = 1 then
                // il s'agit d'un duplica (on ne compte pas les autres, même s'il y en a plus+)
                fSearchFilesList.fDuplicateFiles := fSearchFilesList.fDuplicateFiles + 1;
              // le rajouter à la liste :
              fFilesList.Add(fFileInfo);
              // évennement duplicat :
              Synchronize(DoFindDuplicate);
            end;
          end
          else
          begin
            // pas de liste trouvée :
            // créer une nouvelle info de fichier :
            fFileInfo  := CreateFileInfo(fSearchDir);
            // créer une nouvelle list avec ce fichier
            fFilesList := TFilesList.Create(fFileInfo);
            // ajouter cette nouvelle liste à la liste de recherche de liste :
            fSearchFilesList.Add(fFilesList);
          end;

          // log :
          DeltaTick := GetTickCount() - TickFindFile;
          if DeltaTick > 31 then
            LogToSpy(Format('RecurseFindFile count:%5d %5dms %s', [fSearchFilesList.Count, DeltaTick, fSearchName]))
          //else LogToSpy(Format('RecurseFindFile count:%d %dms', [fSearchFilesList.Count, DeltaTick]));
        end
      end;
    SwitchToThread;


    until (FindNext(searchResult) <> 0) or fCancel;
    FindClose(searchResult);
  end;

end;


////////////////////////////////////////////////////////////////////////////////
procedure TDuplicateFinderThread.Execute;
begin
  // evennement de démarrage :
  Synchronize(DoBegin);
  // progression en cours
  fSearchFilesList.fInProgress := True;
  // démarrer le compteur :
  fTick := GetTickCount();
  // lancer la recherche :
  RecurseFindFile(fFolderPath);
  // rendre la main eu thread principal :
  SwitchToThread;
  // fin de progression :
  fSearchFilesList.fInProgress := False;
  // évennement de fin :
  Synchronize(DoEnd);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TDuplicateFinderThread.DoBegin;
begin
  // évennement de démarrage :
  if Assigned(fOnBegin) then fOnBegin(Self);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TDuplicateFinderThread.DoFindFolder;
begin
  // si l'evennement est assigné on l'éxécute (avec les paramètres) :
  if Assigned(fOnFindFolder) then fOnFindFolder(Self, fFindFolder);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TDuplicateFinderThread.DoFindFile;
begin
  // si l'evennement est assigné on l'éxécute (avec les paramètres) :
  if Assigned(fOnFindFile) then fOnFindFile(Self, fFindFile);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TDuplicateFinderThread.DoFindDuplicate;
begin
  // si l'evennement est assigné on l'éxécute (avec les paramètres) :
  if Assigned(fOnFindDuplicate) then fOnFindDuplicate(Self, fFilesList, fFileInfo);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TDuplicateFinderThread.DoCancel;
begin
  // si l'evennement est assigné on l'éxécute (avec les paramètres) :
  if Assigned(fOnCancel) then fOnCancel(Self, fCancel);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TDuplicateFinderThread.DoEnd;
begin
  // évennement :
  if Assigned(fOnEnd) then fOnEnd(Self);
end;

end.
