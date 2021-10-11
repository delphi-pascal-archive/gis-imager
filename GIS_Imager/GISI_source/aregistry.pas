{*******************************************************}
{                                                       }
{       Borland Delphi Visual Component Library         }
{                                                       }
{       Copyright (c) 1995,98 Inprise Corporation       }
{                                                       }
{*******************************************************}
//(one may call it:) major changes by -=Assarbad [GoP]=-

unit aRegistry;
interface
{
****************************************************************
****************************************************************
***        Copyright (c) 2000 by -=Assarbad [GoP]=-          ***
***                  see COPYRIGHT.TXT                       ***
***       ____________                 ___________           ***
***      /\   ________\               /\   _____  \          ***
***     /  \  \       /    __________/  \  \    \  \         ***
***     \   \  \   __/___ /\   _____  \  \  \____\  \        ***
***      \   \  \ /\___  \  \  \    \  \  \   _______\       ***
***       \   \  \ /   \  \  \  \    \  \  \  \      /       ***
***        \   \  \_____\  \  \  \____\  \  \  \____/        ***
***         \   \___________\  \__________\  \__\            ***
***          \  /           /  /          /  /  /            ***
***           \/___________/ \/__________/ \/__/             ***
***                                                          ***
***  May the source be with you, stranger ... :-)            ***
***                                                          ***
***  Greets from -=Assarbad [GoP]=- ...                      ***
***  [for questions/proposals drop a mail at "satinav@i.am"] ***
*****************************************ASCII by Assa [GoP]****
****************************************************************
version 1.2
}
uses Windows;
{$D-,L-,O+,Q-,R-,Y-}

const
  R=KEY_READ;
  W=KEY_WRITE;
  RW=(KEY_READ or KEY_WRITE);


type

  TRegKeyInfo = record
    NumSubKeys: Integer;
    MaxSubKeyLen: Integer;
    NumValues: Integer;
    MaxValueLen: Integer;
    MaxDataLen: Integer;
    FileTime: TFileTime;
  end;

  ATStrings=array of string;

  TRegDataType = (rdUnknown, rdString, rdExpandString, rdInteger, rdBinary);

  TRegDataInfo = record
    RegData: TRegDataType;
    DataSize: Integer;
  end;

  TRegistry = class(TObject)
  private
    FAccess: DWORD;
    FCurrentKey: HKEY;
    FRootKey: HKEY;
    FLazyWrite: Boolean;
    FCurrentPath: string;
    FCloseRootKey: Boolean;
    procedure SetRootKey(Value: HKEY);
  protected
    procedure ChangeKey(Value: HKey; const Path: string);
    function GetBaseKey(Relative: Boolean): HKey;
    function GetData(const Name: string; Buffer: Pointer;
      BufSize: Integer; var RegData: TRegDataType): Integer;
    function GetKey(const Key: string): HKEY;
    procedure PutData(const Name: string; Buffer: Pointer; BufSize: Integer; RegData: TRegDataType);
    procedure SetCurrentKey(Value: HKEY);
  public
    constructor Create;
    destructor Destroy; override;
    procedure CloseKey;
    function CreateKey(const Key: string): Boolean;
    function DeleteKey(const Key: string): Boolean;
    function DeleteValue(const Name: string): Boolean;
    function GetDataInfo(const ValueName: string; var Value: TRegDataInfo): Boolean;
    function GetDataSize(const ValueName: string): Integer;
    function GetDataType(const ValueName: string): TRegDataType;
    function GetKeyInfo(var Value: TRegKeyInfo): Boolean;
    procedure GetKeyNames(Strings:  ATStrings);
    procedure GetValueNames(var Strings: ATStrings);
    function HasSubKeys: Boolean;
    function KeyExists(const Key: string): Boolean;
    function LoadKey(const Key, FileName: string): Boolean;
    procedure MoveKey(const OldName, NewName: string; Delete: Boolean);
    function OpenKey(const Key: string; CanCreate: Boolean; Access:DWORD): Boolean;
    function ReadCurrency(const Name: string): Currency;
    function ReadBinaryData(const Name: string; var Buffer; BufSize: Integer): Integer;
    function ReadBool(const Name: string): Boolean;
    function ReadDate(const Name: string): TDateTime;
    function ReadDateTime(const Name: string): TDateTime;
    function ReadFloat(const Name: string): Double;
    function ReadInteger(const Name: string): Integer;
    function ReadString(const Name: string): string;
    function ReadTime(const Name: string): TDateTime;
    function RegistryConnect(const UNCName: string): Boolean;
    procedure RenameValue(const OldName, NewName: string);
    function ReplaceKey(const Key, FileName, BackUpFileName: string): Boolean;
    function RestoreKey(const Key, FileName: string): Boolean;
    function SaveKey(const Key, FileName: string): Boolean;
    function UnLoadKey(const Key: string): Boolean;
    function ValueExists(const Name: string): Boolean;
    procedure WriteCurrency(const Name: string; Value: Currency);
    procedure WriteBinaryData(const Name: string; var Buffer; BufSize: Integer);
    procedure WriteBool(const Name: string; Value: Boolean);
    procedure WriteDate(const Name: string; Value: TDateTime);
    procedure WriteDateTime(const Name: string; Value: TDateTime);
    procedure WriteFloat(const Name: string; Value: Double);
    procedure WriteInteger(const Name: string; Value: Integer);
    procedure WriteString(const Name, Value: string);
    procedure WriteExpandString(const Name, Value: string);
    procedure WriteTime(const Name: string; Value: TDateTime);
    property CurrentKey: HKEY read FCurrentKey;
    property CurrentPath: string read FCurrentPath;
    property LazyWrite: Boolean read FLazyWrite write FLazyWrite;
    property RootKey: HKEY read FRootKey write SetRootKey;
  end;

function StrLen(Str: PChar): Cardinal; assembler;
function frmt(mformat:string;args:array of POINTER):string;

implementation
var OSVI:TOSVersionInfo;

const
  regerr = 'Error while handling registry functions.';
  Title = 'Application error';

function frmt(mformat:string;args:array of POINTER):string;
var bla:pchar;
begin
     getmem(bla,100000);
     wvsprintf(bla,pchar(mformat),pchar(@args));
     result:=string(bla);
     freemem(bla,100000);
end;

//export from sysutils.pas
function StrLen(Str: PChar): Cardinal; assembler;
asm
        MOV     EDX,EDI
        MOV     EDI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        MOV     EAX,0FFFFFFFEH
        SUB     EAX,ECX
        MOV     EDI,EDX
end;

function AllocMem(Size: Cardinal): Pointer;
begin
  GetMem(Result, Size);
  FillChar(Result^, Size, 0);
end;

procedure errmsg(msg:string);
begin
     MessageBox(0, pchar(msg), pchar(Title), MB_OK or MB_ICONSTOP or MB_TASKMODAL);
end;

{procedure ReadError(const Name: string);
begin
end;}

function IsRelative(const Value: string): Boolean;
begin
  Result := not ((Value <> '') and (Value[1] = '\'));
end;

function RegDataToDataType(Value: TRegDataType): Integer;
begin
  case Value of
    rdString: Result := REG_SZ;
    rdExpandString: Result := REG_EXPAND_SZ;
    rdInteger: Result := REG_DWORD;
    rdBinary: Result := REG_BINARY;
  else
    Result := REG_NONE;
  end;
end;

function DataTypeToRegData(Value: Integer): TRegDataType;
begin
  if Value = REG_SZ then Result := rdString
  else if Value = REG_EXPAND_SZ then Result := rdExpandString
  else if Value = REG_DWORD then Result := rdInteger
  else if Value = REG_BINARY then Result := rdBinary
  else Result := rdUnknown;
end;

constructor TRegistry.Create;
begin
  RootKey := HKEY_CURRENT_USER;
  LazyWrite := True;
end;

destructor TRegistry.Destroy;
begin
  CloseKey;
  inherited;
end;

procedure TRegistry.CloseKey;
begin
  if CurrentKey <> 0 then
  begin
    if LazyWrite then
      RegCloseKey(CurrentKey) else
      RegFlushKey(CurrentKey);
    FAccess:=0;
    FCurrentKey := 0;
    FCurrentPath := '';
  end;
end;

procedure TRegistry.SetRootKey(Value: HKEY);
begin
  if RootKey <> Value then
  begin
    if FCloseRootKey then
    begin
      RegCloseKey(RootKey);
      FCloseRootKey := False;
    end;
    FRootKey := Value;
    CloseKey;
  end;
end;

procedure TRegistry.ChangeKey(Value: HKey; const Path: string);
begin
  CloseKey;
  FCurrentKey := Value;
  FCurrentPath := Path;
end;

function TRegistry.GetBaseKey(Relative: Boolean): HKey;
begin
  if (CurrentKey = 0) or not Relative then
    Result := RootKey else
    Result := CurrentKey;
end;

procedure TRegistry.SetCurrentKey(Value: HKEY);
begin
  FCurrentKey := Value;
end;

function TRegistry.CreateKey(const Key: string): Boolean;
var
  TempKey: HKey;
  S: string;
  Disposition: Integer;
  Relative: Boolean;
begin
  TempKey := 0;
  S := Key;
  Relative := IsRelative(S);
  if not Relative then Delete(S, 1, 1);
  Result := RegCreateKeyEx(GetBaseKey(Relative), PChar(S), 0, nil,
    REG_OPTION_NON_VOLATILE, RW, nil, TempKey, @Disposition) = ERROR_SUCCESS;
  if Result then RegCloseKey(TempKey)
     else errmsg(regerr);
end;

function TRegistry.OpenKey(const Key: String; Cancreate: boolean; Access:DWORD): Boolean;
var
  TempKey: HKey;
  S: string;
  Disposition: Integer;
  Relative: Boolean;
begin
  S := Key;
  Relative := IsRelative(S);

  if not Relative then Delete(S, 1, 1);
  FAccess:=Access;
  TempKey := 0;
  if not CanCreate or (S = '') then
  begin
    Result := RegOpenKeyEx(GetBaseKey(Relative), PChar(S), 0,
      FAccess, TempKey) = ERROR_SUCCESS;
  end else
    Result := RegCreateKeyEx(GetBaseKey(Relative), PChar(S), 0, nil,
      REG_OPTION_NON_VOLATILE, FAccess, nil, TempKey, @Disposition) = ERROR_SUCCESS;
  if Result then
  begin
    if (CurrentKey <> 0) and Relative then S := CurrentPath + '\' + S;
    ChangeKey(TempKey, S);
  end;
end;

function TRegistry.DeleteKey(const Key: string): Boolean;
var
  Len: DWORD;
  I: Integer;
  Relative: Boolean;
  S, KeyName: string;
  OldKey, DeleteKey: HKEY;
  Info: TRegKeyInfo;
begin
  S := Key;
  Relative := IsRelative(S);
  if not Relative then Delete(S, 1, 1);
  OldKey := CurrentKey;
  DeleteKey := GetKey(Key);
  if DeleteKey <> 0 then
  try
    SetCurrentKey(DeleteKey);
    if GetKeyInfo(Info) then
    begin
      SetString(KeyName, nil, Info.MaxSubKeyLen + 1);
      for I := Info.NumSubKeys - 1 downto 0 do
      begin
        Len := Info.MaxSubKeyLen + 1;
        if RegEnumKeyEx(DeleteKey, DWORD(I), PChar(KeyName), Len, nil, nil, nil,
          nil) = ERROR_SUCCESS then
          Self.DeleteKey(PChar(KeyName));
      end;
    end;
  finally
    SetCurrentKey(OldKey);
    RegCloseKey(DeleteKey);
  end;
  Result := RegDeleteKey(GetBaseKey(Relative), PChar(S)) = ERROR_SUCCESS;
end;

function TRegistry.DeleteValue(const Name: string): Boolean;
begin
  Result := RegDeleteValue(CurrentKey, PChar(Name)) = ERROR_SUCCESS;
end;

function TRegistry.GetKeyInfo(var Value: TRegKeyInfo): Boolean;
begin
  FillChar(Value, SizeOf(TRegKeyInfo), 0);
  Result := RegQueryInfoKey(CurrentKey, nil, nil, nil, @Value.NumSubKeys,
    @Value.MaxSubKeyLen, nil, @Value.NumValues, @Value.MaxValueLen,
    @Value.MaxDataLen, nil, @Value.FileTime) = ERROR_SUCCESS;
  OSVI.dwOSVersionInfoSize:=SizeOf(OSVersionInfo);
  GetVersionEx(OSVI);
  if (GetSystemMetrics(SM_DBCSENABLED)<>0) and (OSVI.dwPlatformId = VER_PLATFORM_WIN32_NT) then
    with Value do begin
      Inc(MaxSubKeyLen, MaxSubKeyLen);
      Inc(MaxValueLen, MaxValueLen);
    end;
end;

procedure TRegistry.GetKeyNames(Strings: ATStrings);
var
  Len: DWORD;
  I: Integer;
  Info: TRegKeyInfo;
  S: string;
begin
  setlength(strings,0);
  if GetKeyInfo(Info) then
  begin
    SetString(S, nil, Info.MaxSubKeyLen + 1);
    for I := 0 to Info.NumSubKeys - 1 do
    begin
      Len := Info.MaxSubKeyLen + 1;
      RegEnumKeyEx(CurrentKey, I, PChar(S), Len, nil, nil, nil, nil);
      if Pchar(s)<>nil then begin
         setlength(strings,length(strings)+1);
         strings[length(strings)-1]:=string(pchar(s));
      end;
    end;
  end;
end;

procedure TRegistry.GetValueNames(var Strings: ATStrings);
var
  Len: DWORD;
  I: Integer;
  Info: TRegKeyInfo;
  S: string;
begin
  setlength(strings,0);
  if GetKeyInfo(Info) then
  begin
    SetString(S, nil, Info.MaxValueLen + 1);
    for I := 0 to Info.NumValues - 1 do
    begin
      Len := Info.MaxValueLen + 1;
      RegEnumValue(CurrentKey, I, PChar(S), Len, nil, nil, nil, nil);
      if Pchar(s)<>nil then begin
         setlength(strings,length(strings)+1);
         strings[length(strings)-1]:=string(pchar(s));
      end;
    end;
  end;
end;

function TRegistry.GetDataInfo(const ValueName: string; var Value: TRegDataInfo): Boolean;
var
  DataType: Integer;
begin
  FillChar(Value, SizeOf(TRegDataInfo), 0);
  Result := RegQueryValueEx(CurrentKey, PChar(ValueName), nil, @DataType, nil,
    @Value.DataSize) = ERROR_SUCCESS;
  Value.RegData := DataTypeToRegData(DataType);
end;

function TRegistry.GetDataSize(const ValueName: string): Integer;
var
  Info: TRegDataInfo;
begin
  if GetDataInfo(ValueName, Info) then
    Result := Info.DataSize else
    Result := -1;
end;

function TRegistry.GetDataType(const ValueName: string): TRegDataType;
var
  Info: TRegDataInfo;
begin
  if GetDataInfo(ValueName, Info) then
    Result := Info.RegData else
    Result := rdUnknown;
end;

procedure TRegistry.WriteString(const Name, Value: string);
begin
  PutData(Name, PChar(Value), Length(Value)+1, rdString);
end;

procedure TRegistry.WriteExpandString(const Name, Value: string);
begin
  PutData(Name, PChar(Value), Length(Value)+1, rdExpandString);
end;

function TRegistry.ReadString(const Name: string): string;
var
  Len: Integer;
  RegData: TRegDataType;
begin
  Len := GetDataSize(Name);
  if Len > 0 then
  begin
    SetString(Result, nil, Len);
    GetData(Name, PChar(Result), Len, RegData);
    if (RegData = rdString) or (RegData = rdExpandString) then
      SetLength(Result, StrLen(PChar(Result)))
    else errmsg(regerr);
  end
  else Result := '';
end;

procedure TRegistry.WriteInteger(const Name: string; Value: Integer);
begin
  PutData(Name, @Value, SizeOf(Integer), rdInteger);
end;

function TRegistry.ReadInteger(const Name: string): Integer;
var
  RegData: TRegDataType;
begin
  GetData(Name, @Result, SizeOf(Integer), RegData);
  if RegData <> rdInteger then errmsg(regerr);
end;

procedure TRegistry.WriteBool(const Name: string; Value: Boolean);
begin
  WriteInteger(Name, Ord(Value));
end;

function TRegistry.ReadBool(const Name: string): Boolean;
begin
  Result := ReadInteger(Name) <> 0;
end;

procedure TRegistry.WriteFloat(const Name: string; Value: Double);
begin
  PutData(Name, @Value, SizeOf(Double), rdBinary);
end;

function TRegistry.ReadFloat(const Name: string): Double;
var
  Len: Integer;
  RegData: TRegDataType;
begin
  Len := GetData(Name, @Result, SizeOf(Double), RegData);
  if (RegData <> rdBinary) or (Len <> SizeOf(Double)) then
    errmsg(regerr);
end;

procedure TRegistry.WriteCurrency(const Name: string; Value: Currency);
begin
  PutData(Name, @Value, SizeOf(Currency), rdBinary);
end;

function TRegistry.ReadCurrency(const Name: string): Currency;
var
  Len: Integer;
  RegData: TRegDataType;
begin
  Len := GetData(Name, @Result, SizeOf(Currency), RegData);
  if (RegData <> rdBinary) or (Len <> SizeOf(Currency)) then
    errmsg(regerr);
end;

procedure TRegistry.WriteDateTime(const Name: string; Value: TDateTime);
begin
  PutData(Name, @Value, SizeOf(TDateTime), rdBinary);
end;

function TRegistry.ReadDateTime(const Name: string): TDateTime;
var
  Len: Integer;
  RegData: TRegDataType;
begin
  Len := GetData(Name, @Result, SizeOf(TDateTime), RegData);
  if (RegData <> rdBinary) or (Len <> SizeOf(TDateTime)) then
    errmsg(regerr);
end;

procedure TRegistry.WriteDate(const Name: string; Value: TDateTime);
begin
  WriteDateTime(Name, Value);
end;

function TRegistry.ReadDate(const Name: string): TDateTime;
begin
  Result := ReadDateTime(Name);
end;

procedure TRegistry.WriteTime(const Name: string; Value: TDateTime);
begin
  WriteDateTime(Name, Value);
end;

function TRegistry.ReadTime(const Name: string): TDateTime;
begin
  Result := ReadDateTime(Name);
end;

procedure TRegistry.WriteBinaryData(const Name: string; var Buffer; BufSize: Integer);
begin
  PutData(Name, @Buffer, BufSize, rdBinary);
end;

function TRegistry.ReadBinaryData(const Name: string; var Buffer; BufSize: Integer): Integer;
var
  RegData: TRegDataType;
  Info: TRegDataInfo;
begin
  if GetDataInfo(Name, Info) then
  begin
    Result := Info.DataSize;
    RegData := Info.RegData;
    if ((RegData = rdBinary) or (RegData = rdUnknown)) and (Result <= BufSize) then
      GetData(Name, @Buffer, Result, RegData)
    else errmsg(regerr);
  end else
    Result := 0;
end;

procedure TRegistry.PutData(const Name: string; Buffer: Pointer;
  BufSize: Integer; RegData: TRegDataType);
var
  DataType: Integer;
begin
  DataType := RegDataToDataType(RegData);
  if RegSetValueEx(CurrentKey, PChar(Name), 0, DataType, Buffer,
    BufSize) <> ERROR_SUCCESS then
             errmsg(regerr);
end;

function TRegistry.GetData(const Name: string; Buffer: Pointer;
  BufSize: Integer; var RegData: TRegDataType): Integer;
var
  DataType: Integer;
begin
  DataType := REG_NONE;
  if RegQueryValueEx(CurrentKey, PChar(Name), nil, @DataType, PByte(Buffer),
    @BufSize) <> ERROR_SUCCESS then
              errmsg(regerr);
  Result := BufSize;
  RegData := DataTypeToRegData(DataType);
end;

function TRegistry.HasSubKeys: Boolean;
var
  Info: TRegKeyInfo;
begin
  Result := GetKeyInfo(Info) and (Info.NumSubKeys > 0);
end;

function TRegistry.ValueExists(const Name: string): Boolean;
var
  Info: TRegDataInfo;
begin
  Result := GetDataInfo(Name, Info);
end;

function TRegistry.GetKey(const Key: string): HKEY;
var
  S: string;
  Relative: Boolean;
begin
  S := Key;
  Relative := IsRelative(S);
  if not Relative then Delete(S, 1, 1);
  Result := 0;
  RegOpenKeyEx(GetBaseKey(Relative), PChar(S), 0,
    KEY_ALL_ACCESS, Result);
end;

function TRegistry.RegistryConnect(const UNCName: string): Boolean;
var
  TempKey: HKEY;
begin
  Result := RegConnectRegistry(PChar(UNCname), RootKey, TempKey) = ERROR_SUCCESS;
  if Result then
  begin
    RootKey := TempKey;
    FCloseRootKey := True;
  end;
end;

function TRegistry.LoadKey(const Key, FileName: string): Boolean;
var
  S: string;
begin
  S := Key;
  if not IsRelative(S) then Delete(S, 1, 1);
  Result := RegLoadKey(RootKey, PChar(S), PChar(FileName)) = ERROR_SUCCESS;
end;

function TRegistry.UnLoadKey(const Key: string): Boolean;
var
  S: string;
begin
  S := Key;
  if not IsRelative(S) then Delete(S, 1, 1);
  Result := RegUnLoadKey(RootKey, PChar(S)) = ERROR_SUCCESS;
end;

function TRegistry.RestoreKey(const Key, FileName: string): Boolean;
var
  RestoreKey: HKEY;
begin
  Result := False;
  RestoreKey := GetKey(Key);
  if RestoreKey <> 0 then
  try
    Result := RegRestoreKey(RestoreKey, PChar(FileName), 0) = ERROR_SUCCESS;
  finally
    RegCloseKey(RestoreKey);
  end;
end;

function TRegistry.ReplaceKey(const Key, FileName, BackUpFileName: string): Boolean;
var
  S: string;
  Relative: Boolean;
begin
  S := Key;
  Relative := IsRelative(S);
  if not Relative then Delete(S, 1, 1);
  Result := RegReplaceKey(GetBaseKey(Relative), PChar(S),
    PChar(FileName), PChar(BackUpFileName)) = ERROR_SUCCESS;
end;

function TRegistry.SaveKey(const Key, FileName: string): Boolean;
var
  SaveKey: HKEY;
begin
  Result := False;
  SaveKey := GetKey(Key);
  if SaveKey <> 0 then
  try
    Result := RegSaveKey(SaveKey, PChar(FileName), nil) = ERROR_SUCCESS;
  finally
    RegCloseKey(SaveKey);
  end;
end;

function TRegistry.KeyExists(const Key: string): Boolean;
var
  TempKey: HKEY;
begin
  TempKey := GetKey(Key);
  if TempKey <> 0 then RegCloseKey(TempKey);
  Result := TempKey <> 0;
end;

procedure TRegistry.RenameValue(const OldName, NewName: string);
var
  Len: Integer;
  RegData: TRegDataType;
  Buffer: PChar;
begin
  if ValueExists(OldName) and not ValueExists(NewName) then
  begin
    Len := GetDataSize(OldName);
    if Len > 0 then
    begin
      Buffer := AllocMem(Len);
      try
        Len := GetData(OldName, Buffer, Len, RegData);
        DeleteValue(OldName);
        PutData(NewName, Buffer, Len, RegData);
      finally
        FreeMem(Buffer);
      end;
    end;
  end;
end;

procedure TRegistry.MoveKey(const OldName, NewName: string; Delete: Boolean);
var
  SrcKey, DestKey: HKEY;

  procedure MoveValue(SrcKey, DestKey: HKEY; const Name: string);
  var
    Len: Integer;
    OldKey, PrevKey: HKEY;
    Buffer: PChar;
    RegData: TRegDataType;
  begin
    OldKey := CurrentKey;
    SetCurrentKey(SrcKey);
    try
      Len := GetDataSize(Name);
      if Len > 0 then
      begin
        Buffer := AllocMem(Len);
        try
          Len := GetData(Name, Buffer, Len, RegData);
          PrevKey := CurrentKey;
          SetCurrentKey(DestKey);
          try
            PutData(Name, Buffer, Len, RegData);
          finally
            SetCurrentKey(PrevKey);
          end;
        finally
          FreeMem(Buffer);
        end;
      end;
    finally
      SetCurrentKey(OldKey);
    end;
  end;

  procedure CopyValues(SrcKey, DestKey: HKEY);
  var
    Len: DWORD;
    I: Integer;
    KeyInfo: TRegKeyInfo;
    S: string;
    OldKey: HKEY;
  begin
    OldKey := CurrentKey;
    SetCurrentKey(SrcKey);
    try
      if GetKeyInfo(KeyInfo) then
      begin
        MoveValue(SrcKey, DestKey, '');
        SetString(S, nil, KeyInfo.MaxValueLen + 1);
        for I := 0 to KeyInfo.NumValues - 1 do
        begin
          Len := KeyInfo.MaxValueLen + 1;
          if RegEnumValue(SrcKey, I, PChar(S), Len, nil, nil, nil, nil) = ERROR_SUCCESS then
            MoveValue(SrcKey, DestKey, PChar(S));
        end;
      end;
    finally
      SetCurrentKey(OldKey);
    end;
  end;

  procedure CopyKeys(SrcKey, DestKey: HKEY);
  var
    Len: DWORD;
    I: Integer;
    Info: TRegKeyInfo;
    S: string;
    OldKey, PrevKey, NewSrc, NewDest: HKEY;
  begin
    OldKey := CurrentKey;
    SetCurrentKey(SrcKey);
    try
      if GetKeyInfo(Info) then
      begin
        SetString(S, nil, Info.MaxSubKeyLen + 1);
        for I := 0 to Info.NumSubKeys - 1 do
        begin
          Len := Info.MaxSubKeyLen + 1;
          if RegEnumKeyEx(SrcKey, I, PChar(S), Len, nil, nil, nil, nil) = ERROR_SUCCESS then
          begin
            NewSrc := GetKey(PChar(S));
            if NewSrc <> 0 then
            try
              PrevKey := CurrentKey;
              SetCurrentKey(DestKey);
              try
                CreateKey(PChar(S));
                NewDest := GetKey(PChar(S));
                try
                  CopyValues(NewSrc, NewDest);
                  CopyKeys(NewSrc, NewDest);
                finally
                  RegCloseKey(NewDest);
                end;
              finally
                SetCurrentKey(PrevKey);
              end;
            finally
              RegCloseKey(NewSrc);
            end;
          end;
        end;
      end;
    finally
      SetCurrentKey(OldKey);
    end;
  end;

begin
  if KeyExists(OldName) and not KeyExists(NewName) then
  begin
    SrcKey := GetKey(OldName);
    if SrcKey <> 0 then
    try
      CreateKey(NewName);
      DestKey := GetKey(NewName);
      if DestKey <> 0 then
      try
        CopyValues(SrcKey, DestKey);
        CopyKeys(SrcKey, DestKey);
        if Delete then DeleteKey(OldName);
      finally
        RegCloseKey(DestKey);
      end;
    finally
      RegCloseKey(SrcKey);
    end;
  end;
end;

end.


