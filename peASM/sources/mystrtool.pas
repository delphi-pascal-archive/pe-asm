unit mystrtool;

interface

uses windows;

function IntToStr(Num : Integer) : String;  // using SysUtils increase file size by 100K
function IntToHex(Value: Integer; Digits: Integer): string;
function Trim(const S: string): string;
function GETDATE2:string;
function GETTIME2(d,d2:string):string;

function hextoint(what:string):integer;
function getWord(S:string; n:integer; DL:string=' '):string;
function getWordCount(S:string; DL:string=' '):integer;

function getbit16(num:word; bit:byte):boolean;
procedure SetBit16(var AWord: word; ABit: byte; AState: boolean = true);
function strbit16(num:word):string;
function strbit8(num:byte):string;

function UpperCase(const S: string): string;
function LowerCase(const S: string): string;

implementation

function UpperLower(const S:string; upper:boolean):string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    case upper of
     true: if (Ch >= 'a') and (Ch <= 'z') then Dec(Ch, 32);
     false: if (Ch >= 'A') and (Ch <= 'Z') then Inc(Ch, 32);
    end;

    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;


function UpperCase(const S: string): string;
begin
 result:=UpperLower(s,true)
end;

function LowerCase(const S: string): string;
begin
 result:=UpperLower(s,false)
end;


function IntToHex(Value: Integer; Digits: Integer): string;
var i:integer;
var b:byte;
var s1,s2:string;
begin
s1:='';
for i := 0 to Digits-1 do
 begin
  b:=(value shr (i*4)) and $f;
  if b<10 then s2:=inttostr(b) else
   case b of
    10:s2:='a';
    11:s2:='b';
    12:s2:='c';
    13:s2:='d';
    14:s2:='e';
    15:s2:='f';
   end;
 s1:=s2+s1;
 end;

result:=s1;
end;


function Trim(const S: string): string;
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= ' ') do Inc(I);
  if I > L then Result := '' else
  begin
    while S[L] <= ' ' do Dec(L);
    Result := Copy(S, I, L - I + 1);
  end;
end;


function IntToStr(Num : Integer) : String;  // using SysUtils increase file size by 100K
begin
  Str(Num, result);
end;



function GETDATE2:string;
var tme:SYSTEMTIME;
begin
GETLOCALTIME(tme);
result:=IntToStr(tme.wYear)+'-'+
               IntToStr(tme.wMonth)+'-'+
               IntToStr(tme.wDay);


end;

function GETTIME2(d,d2:string):string;
var tme:SYSTEMTIME;
begin
GETLOCALTIME(tme);
result:=IntToStr(tme.wHour)+d+
                 IntToStr(tme.wMinute)+d+
                 IntToStr(tme.wSecond){+d2+
                 IntToStr(tme.wMilliseconds)};
end;


function getbit16(num:word; bit:byte):boolean;
begin
 if ((num shr bit) and 1)=1 then result:=true
  else result:=false;
end;


procedure SetBit16(var AWord: word; ABit: byte; AState: boolean = true);
var zresult:integer;
begin
  if AState then
    zResult := AWord or (1 shl ABit)
  else
    zResult := AWord and (not (1 shl ABit));
AWord:=zResult;
end;

function strbit16(num:word):string;
var tempstr:string;
i:integer;
begin
 tempstr:='';
 for i:=15 downto 0 do
  if getbit16(num, i) then tempstr:=tempstr+' 1'
   else  tempstr:=tempstr+' 0';
result:=tempstr;
end;

function strbit8(num:byte):string;
var tempstr:string;
i:integer;
begin
 tempstr:='';
 for i:=7 downto 0 do
  if getbit16(word(num), i) then tempstr:=tempstr+' 1'
   else  tempstr:=tempstr+' 0';
result:=tempstr;
end;




function hextoint(what:string):integer;
  var Buffer: array[0..255] of Char;
  var i,cte:integer;
  var tempRes:integer;
const  Convert: array['0'..'f'] of SmallInt =
    ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1,
     -1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,10,11,12,13,14,15);
begin
  tempRes:=0;
//showmessage(inttostr(length(What) div 2{+ integer(boolean(length(what)/2>length(what) div 2))}));
//  cte:=HexToBin(PChar(What), Buffer, length(What) div 2+ integer(boolean(length(what)/2>length(what) div 2)));
cte:=length(what);

//  showmessage(inttostr(tempres));
  for i:=0 to cte-1 do
   begin
//  showmessage(inttostr(tempres));
  tempRes:=tempRes+((Convert[what[i+1]]) shl (4*(cte-1-i)));
//  showmessage(inttostr(tempres));
   end;

  result:=tempRes;

end;




function getWord(S:string; n:integer; DL:string=' '):string;
var ns,fnd:string;
    a,i:integer;
begin
ns:=s+DL;
for i:=1 to n do
 begin
  a:=pos(dl,ns);
  if a>0 then
   begin
    fnd:=copy(ns,1,a-1);

    delete(ns,1,a{}+length(dl)-1{});

   end;
 end;
result:=fnd;

end;

function getWordCount(S:string; DL:string=' '):integer;
var ns:string;
var i,b:integer;
begin

 ns:=s+DL;
 b:=0;
 for i:=1 to length(ns) do
  if ns[i]=DL then inc(b);

if trim(s)='' then b:=0;
 

 result:=b;
end;

end.
