unit uDWJSONInterface;

{$I uRESTDW.inc}

interface

Uses
 SysUtils, Classes,{$IFNDEF FPC}{$IF Defined(HAS_FMX)}system.json,{$ELSE}
                    uDWJSON,{$IFEND}{$ELSE}fpjson, jsonparser,{$ENDIF}Variants;

Type
 TElementType = (etObject, etArray, etString, etNumeric, etBoolean);

Type
 TJSONBaseClass = Class
End;

Type
 TJSONBaseObjectClass = Class
 Private
  vJSONObject : TJSONBaseClass;
  Function  GetObject : TJSONObject;
  Procedure SetObject(Value : TJSONObject);
 Public
  Constructor Create;
  Destructor  Destroy;Override;
  Property    JSONObject : TJSONObject Read GetObject Write SetObject;
End;

Type
 TJSONBaseArrayClass = Class
 Private
  vJSONObject : TJSONBaseClass;
  Function  GetObject : TJSONArray;
  Procedure SetObject(Value : TJSONArray);
 Public
  Constructor Create;
  Destructor  Destroy;Override;
  Property    JSONObject : TJSONArray Read GetObject Write SetObject;
End;

Type
 TDWJSONPair = Packed Record
  Name,
  Value : String;
End;

Type
 TDWJSONBase = Class(TJSONBaseObjectClass)
 Private
 Public
  Constructor Create(ParentJSON : TJSONBaseClass);
  Destructor Destroy; Override;
  Function PairCount   : Integer;
End;

Type
 TDWJSONValue = Class(TDWJSONBase)
 Private
  Function  GetPair(Index : Integer) : TDWJSONPair;
  Procedure PutPair(Index : Integer;
                    Value : TDWJSONPair);
 Public
  Property Pair[Index  : Integer] : TDWJSONPair Read GetPair Write PutPair;
End;

Type
 TDWJSONArray = Class(TJSONBaseArrayClass)
 Public
  Function ElementCount : Integer;
  Function GetObject(Index : Integer) : TDWJSONBase;
  Function ToJSON : String;
  Constructor Create;
  Destructor Destroy;Override;
End;

Type
 TDWJSONObject = Class(TJSONBaseObjectClass)
 Private
  Function  GetPair(Index   : Integer) : TDWJSONPair;
  Procedure PutPair(Index   : Integer;
                    Item    : TDWJSONPair);
 Public
  Constructor Create(JSONValue : String);Overload;
  Destructor  Destroy;Override;
  Function    PairCount : Integer;
  Function    ToJSON : String;
  Function    ClassType : TClass;
  Function OpenArray(key : String)    : TDWJSONArray;Overload;
  Function OpenArray(Index : Integer) : TDWJSONArray;Overload;
  Property Pairs[Index  : Integer] : TDWJSONPair Read GetPair Write PutPair;
End;

implementation

Function removestr(Astr: string; Asubstr: string):string;
Begin
 result:= stringreplace(Astr,Asubstr,'',[rfReplaceAll, rfIgnoreCase]);
End;

{$IF Defined(HAS_FMX)}
Function GetElementJSON(bArray : TJSONObject; Value : String) : String;
Var
 I : Integer;
 aJSONObject : TJSONObject;
Begin
 Result := '';
 For I := 0 To bArray.Count -1 do
  Begin
   aJSONObject := TJSONObject.ParseJSONValue(bArray.Get(I).ToJSON) as TJSONObject;
   If Uppercase(Value) = Uppercase(removestr(aJSONObject.Pairs[0].JsonString.Value, '"')) Then
    Begin
     Result := aJSONObject.Pairs[0].JsonValue.ToJSON;
     Break;
    End;
   FreeAndNil(aJSONObject);
  End;
End;
{$IFEND}

Function TDWJSONObject.OpenArray(key : String) : TDWJSONArray;
{$IF Defined(HAS_FMX)}
Var
 vEIndex     : Integer;
 aJSONObject : TJSONObject;
 aJSONArray  : Tjsonarray;
{$IFEND}
Begin
 Result := TDWJSONArray.Create;
 {$IFNDEF FPC}
  {$IF Defined(HAS_FMX)}
   If TJSONObject(JSONObject).classname = 'TJSONObject' Then
    Begin
     aJSONObject        := TJSONObject.ParseJSONValue(TJSONObject(JSONObject).ToJSON) as TJSONObject;
     aJSONArray         := TJSONObject.ParseJSONValue(TJSONObject(aJSONObject).Get(Key).JsonValue.ToJSON) as TJSONArray;
     Result.vJSONObject := TJSONBaseClass(aJSONArray);
     FreeAndNil(aJSONObject);
    End
   Else
    Begin
     aJSONArray         := TJSONObject.ParseJSONValue(GetElementJSON(TJSONObject(JSONObject), Key)) as TJSONArray;
     Result.vJSONObject := TJSONBaseClass(aJSONArray); // (Key).ToJSON) as TJSONArray);
    End;
  {$ELSE}
   Result.vJSONObject := TJSONBaseClass(JSONObject.getJSONArray(key));
  {$IFEND}
 {$ELSE}
  Result.vJSONObject := TJSONBaseClass(TJSONObject(JSONObject).Arrays[key]);
 {$ENDIF}
End;

Function TDWJSONObject.OpenArray(Index : Integer) : TDWJSONArray;
{$IF Defined(HAS_FMX)}
Var
 vEIndex     : Integer;
 aJSONObject : TJSONObject;
 aJSONArray  : Tjsonarray;
{$IFEND}
Begin
 Result := TDWJSONArray.Create;
 {$IFNDEF FPC}
  {$IF Defined(HAS_FMX)}
   If TJSONObject(JSONObject).classname = 'TJSONObject' Then
    Begin
     aJSONObject        := TJSONObject.ParseJSONValue(TJSONObject(JSONObject).ToJSON) as TJSONObject;
     aJSONArray         := TJSONObject.ParseJSONValue(TJSONObject(aJSONObject).Pairs[Index].JsonValue.ToJSON) as TJSONArray;
     Result.vJSONObject := TJSONBaseClass(aJSONArray);
     FreeAndNil(aJSONObject);
    End
   Else
    Begin
     aJSONArray         := TJSONObject.ParseJSONValue(TJSONObject(aJSONObject).Pairs[Index].JsonValue.ToJSON) as TJSONArray;
     Result.vJSONObject := TJSONBaseClass(aJSONArray); // (Key).ToJSON) as TJSONArray);
    End;
  {$ELSE}
   If TJSONObject(JSONObject).classname = 'TJSONObject' Then
    Result.vJSONObject := TJSONBaseClass(TJSONObject(vJSONObject).opt(TJSONObject(vJSONObject).names.get(Index).toString))
   Else If TJSONObject(JSONObject).classname = 'TJSONArray' Then
    Result.vJSONObject := TJSONBaseClass(TJSONArray(vJSONObject).get(Index));
  {$IFEND}
 {$ELSE}
  If TJSONObject(JSONObject).classname = 'TJSONObject' Then
   Result.vJSONObject := TJSONBaseClass(TJSONObject(vJSONObject).Items[Index].toString)
  Else If TJSONObject(JSONObject).classname = 'TJSONArray' Then
   Result.vJSONObject := TJSONBaseClass(TJSONArray(vJSONObject).Items[Index]);
 {$ENDIF}
End;

Constructor TDWJSONArray.Create;
Begin
 Inherited Create;
End;

Destructor TDWJSONArray.Destroy;
Begin
 inherited;
End;

Function TDWJSONArray.ElementCount : Integer;
Begin
 {$IFNDEF FPC}
  {$IF Defined(HAS_FMX)}
   Result := TJSONArray(vJSONObject).Size;
  {$ELSE}
   If TJSONObject(vJSONObject).classname = 'TJSONObject' Then
    Result := TJSONObject(vJSONObject).names.length
   Else
    Result := TJSONArray(vJSONObject).length;
  {$IFEND}
 {$ELSE}
 If TJSONObject(vJSONObject).classname = 'TJSONObject' Then
    Result := TJSONObject(vJSONObject).Count
  Else
   Result := TJSONArray(vJSONObject).Count;
 {$ENDIF}
End;

Function TDWJSONArray.GetObject(Index: Integer): TDWJSONBase;
Var
{$IF Defined(HAS_FMX)}
 aJSONObject : TJSONArray;
 aJSONValue  : TJSONValue;
{$IFEND}
 vClassName : String;
Begin
 Result := TDWJSONBase.Create(vJSONObject);
 If (UpperCase(TJSONObject(vJSONObject).ClassName) = UpperCase('TJSONArray')) Then
  Begin
   {$IFNDEF FPC}
    {$IF Defined(HAS_FMX)}
     aJSONValue         := TJSONObject.ParseJSONValue(TJSONObject(JSONObject).Get(Index).ToJSON);
     If aJSONValue is TJSONObject Then
      Result.vJSONObject := TJSONBaseClass(aJSONValue as Tjsonobject)
     Else
      Result.vJSONObject := TJSONBaseClass(aJSONValue);
    {$ELSE}
     Result.vJSONObject := TJSONBaseClass(TJSONArray(vJSONObject).optJSONArray(Index));
     If Result.vJSONObject = Nil then
      Result.vJSONObject := TJSONBaseClass(TJSONArray(vJSONObject).opt(Index));
    {$IFEND}
   {$ELSE}
    If TJSONArray(vJSONObject).Count > 0 Then
     Begin
      Result.vJSONObject := Nil;
      vClassName         := TJSONObject(vJSONObject).Items[index].ClassName;
      If UpperCase(vClassName) = UpperCase('TJSONArray') Then
       Result.vJSONObject := TJSONBaseClass(TJSONArray(vJSONObject).Items[Index])
      Else If UpperCase(vClassName) = UpperCase('TJSONObject') Then
       Result.vJSONObject := TJSONBaseClass(TJSONObject(TJSONArray(vJSONObject).Items[Index]))
      Else If UpperCase(vClassName) <> UpperCase('TJSONNull') Then
       Result.vJSONObject := TJSONBaseClass(TJSONString(TJSONObject(vJSONObject).Items[index]))
      Else
       Result.vJSONObject := TJSONBaseClass(TJSONNull(TJSONObject(vJSONObject).Items[index]));
     End;
   {$ENDIF}
  End
 Else If (UpperCase(TJSONObject(vJSONObject).ClassName) = UpperCase('TJSONObject')) Then
  Begin
   {$IFNDEF FPC}
    {$IF Defined(HAS_FMX)}
     Result.vJSONObject := TJSONBaseClass(TJSONObject.ParseJSONValue(TJSONObject(vJSONObject).Get(Index).JsonValue.ToJson) as TJSONArray);
    {$ELSE}
     Result.vJSONObject := TJSONBaseClass(TJSONObject(vJSONObject).opt(TJSONObject(vJSONObject).names.get(Index).toString));
    {$IFEND}
   {$ELSE}
    Result.vJSONObject := TJSONBaseClass(TJSONObject(vJSONObject).Items[Index]);
   {$ENDIF}
  End
 Else
  Result.vJSONObject := TJSONBaseClass(TJSONObject(vJSONObject));
End;

Function TDWJSONArray.ToJSON : String;
Begin
 Result := TJSONObject(Self).ToString;
End;

Constructor TDWJSONObject.Create(JSONValue : String);
{$IFDEF FPC}
Var
 JSONData : TJSONData;
{$ENDIF}
Begin
 Inherited Create;
 If JSONValue <> '' Then
  Begin
   {$IFNDEF FPC}
    {$IF Defined(HAS_FMX)}
     If JSONValue[1] = '[' then
      vJSONObject := TJSONBaseClass(TJSONObject.ParseJSONValue(JSONValue) as TJsonArray)
     Else
      vJSONObject := TJSONBaseClass(TJSONObject.ParseJSONValue(JSONValue) as TJsonObject);
    {$ELSE}
     If JSONValue[1] = '[' then
      vJSONObject := TJSONBaseClass(TJSONArray.Create(JSONValue))
     Else
      vJSONObject := TJSONBaseClass(TJSONObject.Create(JSONValue));
    {$IFEND}
   {$ELSE}
    JSONData := GetJSON(JSONValue);
    If JSONValue[1] = '[' then
     vJSONObject := TJSONBaseClass(TJSONArray(JSONData))
    Else
     vJSONObject := TJSONBaseClass(TJSONObject(JSONData));
   {$ENDIF}
  End;
End;

Destructor TDWJSONObject.Destroy;
Begin
 FreeAndNil(TJSONBaseClass(vJSONObject));
 Inherited;
End;

Function TDWJSONObject.GetPair(Index   : Integer) : TDWJSONPair;
Var
 vElementName,
 vClassName : String;
 {$IF Defined(HAS_FMX)}
 aJSONObject : TJSONObject;
 {$IFEND}
Begin
  vClassName  := TJSONObject(vJSONObject).ClassName;
 {$IFNDEF FPC}
  {$IF Defined(HAS_FMX)}
   If (UpperCase(vClassName) = UpperCase('TDWJSONObject')) Or
      (UpperCase(vClassName) = UpperCase('TJSONObject'))   Or
      (UpperCase(vClassName) = UpperCase('TDWJSONBase'))  Then
    Begin
     If vClassName <> '_String' Then
      Begin
       If (TJSONObject(vJSONObject).Count > index) Then
        Begin
         Result.Name      := removestr(TJSONObject(vJSONObject).Pairs[index].JsonString.Value, '"');
         Result.Value     := TJSONObject(vJSONObject).Pairs[index].JsonValue.Value;//removestr(TJSONObject(vJSONObject).Pairs[index].JsonValue.tostring, '"');
        End;
      End
     Else
      Result.Value      := TJSONObject(vJSONObject).Pairs[index].JsonValue.Value;//removestr(TJSONObject(vJSONObject).Pairs[index].JsonValue.tostring, '"');
    End
   Else If UpperCase(vClassName) = UpperCase('TJSONArray') Then
    Begin
     aJSONObject := TJSONObject.ParseJSONValue(TJSONObject(vJSONObject).Get(index).toJson) as TJSONObject;
     Result.Name        := removestr(aJSONObject.Pairs[index].JsonString.Value, '"');
     Result.Value       := removestr(aJSONObject.Pairs[index].JsonValue.tostring, '"');
     FreeAndNil(aJSONObject);
    End
   Else
    Begin
     Result.Name        := '';
     Result.Value       := TJSONValue(vJSONObject).Value;
     If Result.Value = '' Then
      Result.Value       := removestr(TJSONObject(vJSONObject).ToJson, '"');
    End;
  {$ELSE}
   If (UpperCase(vClassName) = UpperCase('TDWJSONObject')) Or
      (UpperCase(vClassName) = UpperCase('TJSONObject'))   Or
      (UpperCase(vClassName) = UpperCase('TDWJSONBase'))  Then
    Begin
     If vClassName <> '_String' Then
      Begin
       If TJSONObject(vJSONObject).names.length > 0 Then
        Begin
         If (TJSONObject(vJSONObject).names.length > index) Then
          Begin
           Result.Name        := TJSONObject(vJSONObject).names.get(index).toString;
           Result.Value       := TJSONObject(vJSONObject).get(Result.Name).toString;
          End;
        End
       Else
        Result.Value       := TJSONObject(vJSONObject).toString;
      End
     Else
      Result.Value       := TJSONObject(vJSONObject).toString;
    End
   Else If UpperCase(vClassName) = UpperCase('TJSONArray') Then
    Begin
     Result.Name        := TJSONArray(vJSONObject).get(Index).toString;
     Result.Value       := TJSONArray(vJSONObject).opt(Index).toString;
    End
   Else
    Result.Value       := TJSONObject(vJSONObject).toString;
  {$IFEND}
 {$ELSE}
  If (UpperCase(vClassName) = UpperCase('TDWJSONObject')) Or
     (UpperCase(vClassName) = UpperCase('TJSONObject'))   Or
     (UpperCase(vClassName) = UpperCase('TDWJSONBase'))  Then
   Begin
    If vClassName <> '_String' Then
     Begin
      If (TJSONObject(vJSONObject).Count > index) Then
       Begin
        vElementName       := TJSONObject(vJSONObject).Names[index];
        Result.Name        := vElementName;
        vClassName         := TJSONObject(vJSONObject).Items[index].ClassName;
        If UpperCase(vClassName) = UpperCase('TJSONArray') Then
         Result.Value       := TJSONArray(TJSONObject(vJSONObject).Items[index]).AsJSON
        Else If UpperCase(vClassName) = UpperCase('TJSONObject') Then
         Begin
          Result.Value      := TJSONObject(vJSONObject).Items[index].AsJSON;
          If Result.Value = '{}' Then
           Result.Value     := '';
         End
        Else If UpperCase(vClassName) <> UpperCase('TJSONNull') Then
         Result.Value       := TJSONObject(vJSONObject).Items[index].AsString
        Else
         Result.Value       := '';
       End;
     End
    Else
     Result.Value       := TJSONObject(vJSONObject).Value;
   End
  Else If UpperCase(vClassName) = UpperCase('TJSONArray') Then
   Begin
//    vElementName       := TJSONObject(TJSONArray(vJSONObject).Objects[Index]).Names[0];
//    Result.Name        := vElementName;
    Result.Value       := TJSONObject(TJSONArray(vJSONObject).Objects[Index]).AsJSON;
   End
  Else
   Result.Value       := TJSONObject(vJSONObject).Value;
 {$ENDIF}
End;

Function TDWJSONObject.PairCount: Integer;
Begin
 {$IFNDEF FPC}
  {$IF Defined(HAS_FMX)}
   Result := TJSONObject(vJSONObject).Count;
  {$ELSE}
   If TJSONObject(vJSONObject).classname = 'TJSONObject' Then
    Result := TJSONObject(vJSONObject).names.length
   Else
    Result := TJSONArray(vJSONObject).length;
  {$IFEND}
 {$ELSE}
  If TJSONObject(vJSONObject).classname = 'TJSONObject' Then
   Result := TJSONObject(vJSONObject).Count
  Else
   Result := TJSONArray(vJSONObject).Count;
 {$ENDIF}
End;

Procedure TDWJSONObject.PutPair(Index  : Integer;
                                Item   : TDWJSONPair);
Begin

End;

Function TDWJSONObject.ClassType : TClass;
Begin
 If TJSONObject(vJSONObject).ClassType      = TJSONObject Then
  Result := TDWJSONObject
 Else If TJSONObject(vJSONObject).ClassType = TJSONArray Then
  Result := TDWJSONArray
 Else If TJSONObject(vJSONObject).ClassType = TDWJSONBase Then
  Result := TDWJSONBase
 Else
  Result := TJSONObject(vJSONObject).ClassType;
End;

Function TDWJSONObject.ToJSON : String;
Begin
 Result := TJSONObject(vJSONObject).ToString;
End;

{ TDWJSONValue }

Function TDWJSONValue.GetPair(Index: Integer): TDWJSONPair;
Begin
 Result.Name  := TJSONObject(Self).ToString;
 Result.Value := TJSONObject(Self).ToString;
End;

procedure TDWJSONValue.PutPair(Index: Integer; Value: TDWJSONPair);
begin

end;

constructor TJSONBaseArrayClass.Create;
begin
 inherited;
end;

destructor TJSONBaseArrayClass.Destroy;
begin
  inherited;
end;

Function TJSONBaseArrayClass.GetObject: TJSONArray;
Begin
 Result := TJSONArray(vJSONObject);
End;

procedure TJSONBaseArrayClass.SetObject(Value: TJSONArray);
begin
 vJSONObject := TJSONBaseClass(Value);
end;

{ TJSONBaseObjectClass }

constructor TJSONBaseObjectClass.Create;
begin
 Inherited Create;
end;

destructor TJSONBaseObjectClass.Destroy;
begin
  inherited;
end;

Function TJSONBaseObjectClass.GetObject: TJSONObject;
Begin
 Result := TJSONObject(vJSONObject);
End;

Procedure TJSONBaseObjectClass.SetObject(Value: TJSONObject);
Begin
 vJSONObject := TJSONBaseClass(Value);
End;

{ TDWJSONBase }

constructor TDWJSONBase.Create(ParentJSON : TJSONBaseClass);
begin
 Inherited Create;
 vJSONObject := ParentJSON;
end;

Destructor TDWJSONBase.Destroy;
Begin

  inherited;
End;

function TDWJSONBase.PairCount: Integer;
begin
 {$IFNDEF FPC}
  {$IF Defined(HAS_FMX)}
   Result := TJSONObject(vJSONObject).Count;
  {$ELSE}
   Result := TJSONObject(vJSONObject).names.length;
  {$IFEND}
 {$ELSE}
  Result := TJSONObject(vJSONObject).Count;
 {$ENDIF}
end;

end.
