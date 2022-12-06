{*******************************************************************************
 Matthieu LAURENT
 unité
*******************************************************************************}
unit uExeInfo;

interface

uses Windows, sysutils;

type
 TExeInfo = packed record
   Filled           : Boolean;
   FileName         : string;
   CompanyName      : string;
   FileDescription  : string;
   FileVersion      : string;
   InternalName     : string;
   LegalCopyright   : string;
   OriginalFilename : string;
   ProductName      : string;
   ProductVersion   : string;
  end;



var ExeInfo : TExeInfo;


function GetVersionInfo(FileName, InfoName : string) : string;
function GetExeInfo(aFileName : string; var aInfo : TExeInfo) : boolean;


implementation

////////////////////////////////////////////////////////////////////////////////
function GetVersionInfo(FileName, InfoName : string) : string;
const EngBrit = '040904E4'; // LocaleId
var BufSize, Len : cardinal;
    Buf, Info : PChar;
    SubBlock : string;
    DataLen  : UInt;
    LangPtr  : Pointer;
begin
  Result := '';
  BufSize := 0;
  BufSize := GetFileVersionInfoSize(PChar(FileName), BufSize);
  if BufSize > 0 then
  begin
    Buf := AllocMem(BufSize);
    GetFileVersionInfo(PChar(FileName), 0, BufSize, Buf);

    if VerQueryValue(Buf,'\VarFileInfo\Translation',LangPtr, DataLen) then
      SubBlock := Format('\StringFileInfo\%0.4x%0.4x\%s'#0,[LoWord(LongInt(LangPtr^)), HiWord(LongInt(LangPtr^)), InfoName]);

    if VerQueryValue(Buf, PChar(SubBlock), Pointer(Info), Len) then
    begin
      if Length(Info) > 0 then
      Result := Info;
    end;

    FreeMem(Buf, BufSize);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function GetExeInfo(aFileName : string; var aInfo : TExeInfo) : boolean;
begin
  Result         := False;
  aInfo.Filled   := false;
  aInfo.FileName := '';

  if not FileExists(aFileName) then exit;

  aInfo.Filled           := True;
  aInfo.FileName         := aFileName;
  aInfo.CompanyName      := GetVersionInfo(aFileName, 'CompanyName');
  aInfo.FileDescription  := GetVersionInfo(aFileName, 'FileDescription');
  aInfo.FileVersion      := GetVersionInfo(aFileName, 'FileVersion');
  aInfo.InternalName     := GetVersionInfo(aFileName, 'InternalName');
  aInfo.LegalCopyright   := GetVersionInfo(aFileName, 'LegalCopyright');
  aInfo.OriginalFilename := GetVersionInfo(aFileName, 'OriginalFilename');
  aInfo.ProductName      := GetVersionInfo(aFileName, 'ProductName');
  aInfo.ProductVersion   := GetVersionInfo(aFileName, 'ProductVersion');
  Result := True;
end;

initialization

 // récupérer les informations du programe lui-même :
  GetExeInfo(ParamStr(0), ExeInfo);

finalization


end.
