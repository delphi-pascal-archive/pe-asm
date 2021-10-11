/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                    my_asm(peasm) v0.2 for win32                     //
//        assembler to x86 machine code compiler written in Delphi     //
//                                                                     //
//                     written by Georgy Moshkin                       //
//                                                                     //
//                                                                     //
//                                                   tmtlib@narod.ru   //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

unit my_asm;

interface

uses windows, mystrtool;

var exe_bytes:array of byte;
var exe_file_addr:dword;

type TParseAgainString=record
                        need_string:string;
                        for_parse_string:string;
                        file_addr:dword;
                       end;

var ParseAgain:array of TParseAgainString;

type TLabel=record
             Name:string;
             Virtual_Addr:DWord;
            end;

var Labels:array of TLabel;

type TVariable=record
                dummySize:DWord;
                VarAddr:DWord;
                VarStr:string;
                Name:string;
               end;

var Variables:array of TVariable;

var record_Index:integer=0;
var record_FileAddr:dword=0;
var record_Inside:boolean=false;


procedure RenderExeHeaders;
procedure UpdateSection0(size:dword);  

procedure ImportFunction(DLLname:string; FunctionName:string);
procedure RenderImport;
procedure MakeEXE(filename:string);

procedure RenderCode2(fname:string);

procedure opcode(s2:string);


procedure xtract(s:string;to_i:integer);
function xparse(s:string; fmt:string):boolean;

var xtracted:array of array of string;

procedure WriteS(value:string);
procedure Write1(value:byte);
procedure Write2(value:word);
procedure Write4(value:dword);

function around(sz,al:integer):integer;
function xstr(idx:integer):string;
procedure add_again_parse(need,again:string;addr:dword);
procedure xcpu(op_s:string; op_p:string);
function xdigitraw(i:integer):string;
function reverse(s:string):string;
function xvalue(k:integer):string;
function xpointer(k{,len}:integer):string;
function xregister(k:integer):byte;
function xdllfunc(k:integer):string;
function xlabel(k:integer{;len:integer}):string;

implementation

var cpu_s:string;
cpu_b:boolean=false;

type TFunction=record
                Name:string;
                Addr:DWORD;
               end;

type TDLL=record
            Name:string;
            Functions:array of TFunction;
           end;

var DLLS:array of TDLL;


var length_VarTotal:dword=0;

var length_ImportTotal:dword=0;

var length_ImportTable:dword=0;
var length_SearchTable:dword=0;
var length_FuncNameTable:dword=0;
var length_DLLnameTable:dword=0;
var length_AddressTable:dword=0;


var offset_AddressTable:dword=0;
var offset_SearchTable:dword=0;
var offset_ImportTable:dword=0;
var offset_DLLnameTable:dword=0;
var offset_FuncNameTable:dword=0;

var offset_file:dword=0;
var offset_memory:dword=0;



var _ImageBase    :DWord;
var _MemAlign     :DWord;
var _FileAlign    :DWord;


procedure SetAddr(addr2:dword);
begin
  exe_file_addr:=addr2;
end;

procedure CheckAddr(nextaddr:word);
var oldaddr:dword;
begin
   if length(exe_bytes)-1<nextaddr then
    begin
     setlength(exe_bytes,length(exe_bytes)+$200);
     oldaddr:=exe_file_addr;
     SetAddr($40+$50);
     Write4((length(exe_bytes) div $200)*$1000);    // file size in memory (?)
     UpdateSection0(length(exe_bytes)-$200);
     exe_file_addr:=oldaddr;
    end;
end;

procedure Write1(value:byte);
var pbyte:^byte;
begin
 CheckAddr(exe_file_addr+sizeof(byte));
 pbyte:=@exe_bytes[exe_file_addr];
 pbyte^:=value;
 inc(exe_file_addr, sizeof(byte));
end;

procedure Write2(value:word);
var pword:^word;
begin
 CheckAddr(exe_file_addr+sizeof(word));
 pword:=@exe_bytes[exe_file_addr];
 pword^:=value;
 inc(exe_file_addr, sizeof(word));
end;

procedure Write4(value:dword);
var pdword:^dword;
begin
 CheckAddr(exe_file_addr+sizeof(dword));
 pdword:=@exe_bytes[exe_file_addr];
 pdword^:=value;
 inc(exe_file_addr,sizeof(dword));
end;

procedure WriteS(value:string);
var i:integer;
begin
 CheckAddr(exe_file_addr+length(value));
 for i := 1 to length(value) do
   begin
     exe_bytes[exe_file_addr]:=ord(value[i]);
     inc(exe_file_addr);
   end;
end;

          

procedure RenderExeHeaders;
begin

 { --- header-1 (DOS) at $00 --- }
 SetAddr($0);
 WriteS('MZ');  // "MZ" signature

 SetAddr($3C);
 Write4($40); // header-2 position

 { --- header-2 (WIN32-PE) at $40  --- }
 SetAddr($40);
 WriteS('PE'#0#0); // "PE" signature
 Write2($14c);  // i386
 Write2($1);    // number of sections <------------------------------------
 Write4($0);    // date/time
 Write4($0);    // symbol
 Write4($0);    // symbol count
 Write2($E0);   // header-3 size
 Write2($10F);  // flags 10E 10F
 Write2($10B);  // "magic" number
 Write2($0);    // linker version
 Write4($200);  // code size (?)  <------------------------------------
 Write4($200);  // initialized data (?)  <------------------------------------
 Write4($0);    // unitialized data

 Write4($1000); // code entry point position  <------------------------------------

 Write4($1000);    // code offset in memory
 Write4($1000);    // data offset in memory

 Write4($400000);    // image base in memory
 Write4($1000); // memory section aligment
 Write4($200);  // file section aligment
 _ImageBase:=$400000;
 _MemAlign:=$1000;
 _FileAlign:=$200;
 

 Write4($4);    // os version hi  0x4?
 Write4($0);    // image version hi
 Write4($4);    // subsystem version hi
 Write4($0);    // ...

 Write4($2000);    // file size in memory (?) <------------------------------------
 Write4($200);     // all headers size (?)

 Write4($0);     // checksum
 Write2($3);     // 2=window,3=console  <------------------------------------
 Write2($0);     // dll flags
 Write4($1000);  // stack reserved
 Write4($1000);  // stack size
 Write4($10000); // heap reserved
 Write4($0);     // heap size
 Write4($0);     // ...
 Write4($10);    // count


end;


function around(sz,al:integer):integer;
begin
 result:=trunc((sz+(al-1))/al)*al;
end;


procedure UpdateSection0(size:dword);
var memsize,filesize:dword;
begin

filesize:=around(size,$200);
memsize:=(filesize div $200)*$1000;


  SetAddr($40{PE} + $78{tablecat}+$10*8+(8+7*4+2*2)*0);
  WriteS('.code'+#0#0#0);
  Write4(memsize);
  Write4($1000{memoffs});
  Write4(filesize);
  Write4($200{fileoffs});
  Write4($0);
  Write4($0);
  Write2($0);
  write2($0);
  write4($E0000060{flags});
end;






procedure ImportFunction(DLLname:string; FunctionName:string);
var i:integer;
var dllIndex:integer;
begin

 dllIndex:=-1;

 // search dll name
 for i := 0 to length(DLLS) - 1 do
  if trim(DLLS[i].Name)=trim(DLLname) then
   begin
    dllIndex:=i;
    break;
   end;

 // dll name not found - add new dll name
 if dllIndex=-1 then
 begin
  i:=length(DLLS);
  setlength(DLLS,i+1);

  DLLS[i].Name:=DLLname+#0#0;
  dllIndex:=i;
 end;

  // add new function name
 i:=length(DLLS[dllIndex].Functions);
 setlength(DLLS[dllIndex].Functions,i+1);

 DLLS[dllIndex].Functions[i].Name:=#0#0+FunctionName+#0;

end;

var ft:text;

procedure RenderImport;
var i,j:integer;
begin


writeln(ft,'base=',inttohex(_ImageBase,8));
writeln(ft,'memalign=',inttohex(_MemAlign,8));
writeln(ft,'filealign=',inttohex(_FileAlign,8));


offset_memory:=$1000;
offset_file:=$200;



 length_ImportTable:=length(DLLS)*5*sizeof(dword);  {5 dwords}

 for i := 0 to length(DLLS)-1 do
  inc(length_SearchTable, length(DLLS[i].Functions){*2}*sizeof(dword)
                          +{2*}sizeof(dword));

 for i := 0 to length(DLLS)-1 do
  for j := 0 to length(DLLS[i].Functions)-1 do
   inc(length_FuncNameTable,length(DLLS[i].Functions[j].Name));

 for i := 0 to length(DLLS)-1 do
  inc(length_DLLnameTable,length(DLLS[i].Name));

 length_AddressTable:=length_SearchTable;

 // // //

 offset_AddressTable:=0;
 offset_SearchTable:=offset_AddressTable+length_AddressTable;

 offset_DLLNameTable:=offset_SearchTable+length_SearchTable;
 offset_FuncNameTable:=offset_DLLNameTable+length_DLLNameTable;
 offset_ImportTable:=offset_FuncNameTable+length_FuncNameTable;

 length_ImportTotal:=offset_ImportTable+length_ImportTable+5*sizeof(dword); //+5 zero dwords

 writeln(ft,inttohex(offset_AddressTable,8));
 writeln(ft,inttohex(offset_SearchTable,8));
 writeln(ft,inttohex(offset_ImportTable,8));
 writeln(ft,inttohex(offset_DLLNameTable,8));
 writeln(ft,inttohex(offset_FuncNameTable,8));


 // import table address
 SetAddr($40{MZ}+$78{PE}+8{export table});
 Write4(offset_memory+offset_ImportTable);
 writeln(ft,inttohex(offset_memory+offset_ImportTable,8)+'zzz');

 // import table size
 SetAddr($40{MZ}+$78{PE}+8{export table}+4);
 Write4(length_ImportTable);

  writeln(ft,inttohex(length_ImportTable,8)+'zzz');



 for i := 0 to length(DLLS)-1 do
  begin
   // import table
   SetAddr(offset_file + offset_ImportTable);
   write4(offset_memory + offset_SearchTable);
   write4($0);
   write4($0);
   write4(offset_memory + offset_DLLNameTable);
   write4(offset_memory + offset_AddressTable);
   inc(offset_ImportTable, 5*sizeof(dword));

   // dll names table
   SetAddr(offset_file+offset_DLLNameTable);
   WriteS(DLLS[i].Name);
   inc(offset_DLLNameTable, length(DLLS[i].Name));

   for j := 0 to length(DLLS[i].Functions) - 1 do
    begin
     // search table
     SetAddr(offset_file+offset_SearchTable);
     write4(offset_memory + offset_FuncNameTable);
     //write4($0);
     inc(offset_SearchTable, {2*}sizeof(dword));

     // address table
     SetAddr(offset_file+offset_AddressTable);
     write4(offset_memory + offset_FuncNameTable);
     //write4($0);
     DLLS[i].Functions[j].Addr:=_ImageBase+offset_memory+offset_AddressTable;
     writeln(ft,inttohex(DLLS[i].Functions[j].Addr,8)+ DLLS[i].Functions[j].Name);

     inc(offset_AddressTable, {2*}sizeof(dword));

     // functions name table
     SetAddr(offset_file+offset_FuncNameTable);
     WriteS(DLLS[i].Functions[j].Name);
     inc(offset_FuncNameTable, length(DLLS[i].Functions[j].Name));

    end;

     // search table
     SetAddr(offset_file+offset_SearchTable);
     write4($0);
     //write4($0);
     inc(offset_SearchTable, {2*}sizeof(dword));

     // address table
     SetAddr(offset_file+offset_AddressTable);
     write4($0);
     //write4($0);
     inc(offset_AddressTable, {2*}sizeof(dword));


  end;




end;


procedure RenderCode2(fname:string);
var f2:text;
var s:string;
begin
assignfile(f2,fname);
reset(f2);

repeat
 readln(f2,s);
 opcode(s);
until eof(f2);

closefile(f2);
end;





procedure MakeEXE(filename:string);
var f:file;
var i:integer;
begin
 assignfile(f,filename);
 rewrite(f,1);
 for i := 0 to length(exe_bytes) - 1 do
 blockwrite(f,exe_bytes[i],1);
 closefile(f);

 closeFile(ft);
end;

function addr_virtual:dword;
begin
 result:=_ImageBase+{section_offs}+$1000+(exe_file_addr-$200{header})
end;


procedure addlabel(name:string);
var i:integer;
begin
 i:=length(labels);
 setlength(labels,i+1);
 labels[i].Name:=copy(name,2,length(name)-1);
 labels[i].Virtual_Addr:=addr_virtual;
end;

procedure add_variable(name,str_val:string;size,vaddr:dword);
var i:integer;
begin


 i:=length(variables);
 setlength(variables,i+1);

 variables[i].Name:=name;

 // record
 if record_inside then variables[i].Name:=Variables[record_Index].Name
                                         +'.'
                                         +variables[i].Name;



 variables[i].VarAddr:=vaddr;
 variables[i].dummySize:=size;

 i:=length(variables)-1;
 variables[i].VarStr:=str_val;

end;

{
procedure add_dlladdr(name:string;addr:dword);
begin
 i:=length(variables);
 setlength(variables,i+1);
 variables[i].Name:=name;
 variables[i].VarAddr:=addr;
 variables[i].VarStr='0x'+

end;
 }
procedure DLLNAMEStoVAR;
var i,j,k,m:integer;
begin

 // function dummies
 k:=length(DLLS);

 for i := 0 to k - 1 do
  begin
   m:=length(DLLS[i].Functions);
   for j := 0 to m - 1 do
    begin
//     writeln(DLLS[i].Functions[j].Name);
//     writeln(inttohex(DLLS[i].Functions[j].Addr,8));
     Add_variable(trim(DLLS[i].Functions[j].Name),
                  '0x'+inttohex(DLLS[i].Functions[j].Addr,8),
                  sizeof(dword),DLLS[i].Functions[j].Addr);
//     xcpu('',inttohex(DLLS[i].Functions[j].Addr,8));
     //writeln('addr=',inttohex(DLLS[i].Functions[j].Addr,8));
    end;

  end;

end;


procedure RenderVar;
var i,j,k,m:integer;
begin
 length_VarTotal:=0;


 k:=length(variables);
 for i := 0 to k-1 do
  begin
   length_VarTotal:=length_VarTotal+
                    variables[i].dummySize;

     j:=length(variables);
     setlength(variables,j+1);
     variables[j].dummySize:=sizeof(dword);
     variables[j].VarAddr:=addr_virtual;
     variables[j].VarStr:='0x'+inttohex(variables[i].dummySize,8);
     variables[j].Name:='length('+variables[i].Name+')';
     length_VarTotal:=length_VarTotal+sizeof(dword);
  end;


end;

function to_space(c:char; s:string):string;
var i:integer;
var s1:string;
begin
s1:=s;
 for i := 1 to length(s1) do
  if s1[i]=c then s1[i]:=' ';

result:=s1;
end;

function char_in_string(c:char;s:string):boolean;
begin
 result:=boolean(pos(c,s)>0);
end;

// char is SPACE or TAB?
function is_space(c:char):boolean;
begin
 result:=char_in_string(c, ' '+#9+','+'|')
end;

function remove_quotes(s:string):string;
begin
 result:=copy(s,2,length(s)-2)
end;


procedure xtract(s:string;to_i:integer);
var i:integer;
var have_space:boolean;
var in_quote:boolean;
var cnt:integer;
begin

 i:=length(xtracted)-1;
 if to_i>i then setlength(xtracted,to_i+1);

 have_space:=true;
 in_quote:=false;

 cnt:=0;
 setlength(xtracted[to_i],0);

 for i := 1 to length(s) do
  begin
   if (s[i]='/') and (not in_quote) then exit;

   if (s[i]='"') then in_quote:=not in_quote;
   if is_space(s[i]) and (not in_quote) then have_space:=true;
   if not is_space(s[i]) and have_space then
    begin
     have_space:=false;
     inc(cnt);
     setlength(xtracted[to_i],cnt);
     xtracted[to_i][cnt-1]:='';
    end;

   if (not is_space(s[i]))
      or
      (is_space(s[i]) and (in_quote) )
       then xtracted[to_i][cnt-1]:=xtracted[to_i][cnt-1]+s[i];
   end;

end;

procedure increv(s:string);
begin
 cpu_s:=cpu_s+reverse(s);
end;

procedure incstr(s:string);
begin
 cpu_s:=cpu_s+s;
end;

procedure smartparser(fmt_str:string; bin_str:string);
var i:integer;
var s1,s2:string;
var a,b:byte;
begin
if xparse(cpu_s,fmt_str) then
 begin
  xtract(bin_str,2);
  cpu_s:='';
  for i := 0 to length(xtracted[2]) div 2-1 do
   begin
   cpu_b:=true;
    s1:=xtracted[2][i*2];
    s2:=xtracted[2][i*2+1];
//    if s1='bin' then incs(s2);
    if s1='raw' then incREV(xdigitraw(hextoint(s2)));
    if s1='text' then incstr(to_space('~',s2));
    if s1='val' then incstr(xvalue(hextoint(s2)));
    if s1='ptr' then incstr(xpointer(hextoint(s2)));
    if s1='reg' then incstr(chr(xregister(1)));
    if s1='+reg' then
    begin
     a:=hextoint(cpu_s);
     b:=xregister(1);
     cpu_s:=inttohex(a+b,2)
    end;
    if s1='dll' then incREV(xdllfunc(hextoint(s2)));
    if s1='label' then incREV(xlabel(hextoint(s2)));
    



   end;
   

 end;



end;


function xparse(s:string; fmt:string):boolean;
var i,j:integer;
begin
 xtract(s,0);
 xtract(fmt,1);

 result:=false;

 if length(xtracted[0])<>length(xtracted[1]) then exit;

 result:=true;

 for i := 0 to length(xtracted[1]) - 1 do
  begin

   if (length(xtracted[1][i])>1) and
      (length(xtracted[0][i])<>length(xtracted[1][i])) then
    begin
     result:=false;
     exit;
    end;

   for j := 1 to length(xtracted[1][i]) do
   if (xtracted[1][i][j]<>'?') and
      (lowercase(xtracted[1][i][j])<>lowercase(xtracted[0][i][j])) then
       begin
        result:=false;
        exit;
       end;


  end;


end;


function xdigitraw(i:integer):string;
var s1,s2:string;
begin
 s1:=lowercase({xtracted[0][i]}xstr(i));
 s2:=copy(s1,3,length(s1)-2); // 0x
 result:=s2;
end;

function reverse(s:string):string;
var s1,s2:string;
var i:integer;
begin

s2:='';

 for i := 0 to length(s) div 2 - 1 do
  begin
   s1:=copy(s,i*2+1,2);
   s2:=s1+s2;
  end;

//  showmessage(s2);

result:=s2;  

end;

(*
function xdigit(i:integer):string;
var s1,s2:string;
begin
 s1:=lowercase(xstr(i){xtracted[0][i]});
 s2:=copy(s1,3,length(s1)-2); // 0x

 s1:='';
 for i := 0 to (length(s2) div 2)-1 do
  s1:=copy(s2,i*2+1,2)+s1;
 result:=s1;
end;
*)

function xlabel(k:integer{;len:integer}):string;
var i:integer;
var s1:string;
var now_virtual:dword;
begin

now_virtual:=addr_virtual+sizeof(dword){len}+1;


 s1:=lowercase(xstr(k));
 for i := 0 to length(labels) - 1 do
  if s1=lowercase(labels[i].Name) then
   begin
       XTRACTED[0][K]:='0x'+inttohex(Labels[i].Virtual_Addr-now_virtual,8);
       result:=xdigitraw(k);
       exit;


   end;


add_again_parse(':'+xstr(k),cpu_s,exe_file_addr);
result:='00000000';


end;

function xpointer(k{,len}:integer):string;
var i:integer;
var s1:string;
begin
  s1:=lowercase(xstr(k){XTRACTED[0][K]});
  s1:=copy(s1,2,length(s1)-1);  
  for i := 0 to length(variables) - 1 do
   if s1={'@'+}lowercase(variables[i].Name) then
    begin
     XTRACTED[0][K]:='0x'+inttohex(variables[i].VarAddr,8);
     result:=xdigitraw{}(k);
     exit;
    end;
end;

function xvalue(k:integer):string;
var i:integer;
var s1:string;
begin
  s1:=lowercase(xstr(k){XTRACTED[0][K]});
  s1:=copy(s1,2,length(s1)-1);
  for i := 0 to length(variables) - 1 do
   if s1={'^'+}lowercase(variables[i].Name) then
    begin
    // XTRACTED[0][K]:='0x'+inttohex(variables[i].VarAddr,len*2);
     //result:=xdigit(k);
     result:=variables[i].VarStr;
     exit;
    end;

end;

function xdllfunc(k:integer):string;
var i,j:integer;
var s1:string;
begin
  s1:=lowercase(xstr(k){XTRACTED[0][K]});

  for i := 0 to length(DLLS) - 1 do
   for j := 0 to length(DLLS[i].Functions) - 1 do
     if s1=lowercase(trim(DLLS[i].Functions[j].Name)) then
      begin
       XTRACTED[0][K]:='0x'+inttohex(DLLS[i].Functions[j].Addr,8);
       result:=xdigitraw(k);
       exit;
      end;
end;

function xregister(k:integer):byte;
begin
 result:=0;
 if XTRACTED[0][K]='eax' then result:=0;
end;



// FF CB

procedure xcpu(op_s:string; op_p:string);
var i:integer;
var s:string;
begin
 s:=trim(op_s+reverse(op_p));
 write(ft,s,' ');
 for i := 0 to (length(s) div 2)-1 do
  write1(hextoint(copy(s,i*2+1,2)));
  cpu_s:='';
end;

function xstr(idx:integer):string;
begin
 if idx<length(XTRACTED[0]) then
  result:=XTRACTED[0][idx]
   else result:='';
end;

procedure add_again_parse(need,again:string;addr:dword);
var i:integer;
begin
 i:=length(parseagain);
 setlength(parseagain,i+1);
 parseagain[i].need_string:=need;
 parseagain[i].for_parse_string:=again;
 parseagain[i].file_addr:=addr;
end;

procedure check_again_parse;
var i:integer;
var old_addr:dword;
begin

 for i := 0 to length(parseagain) - 1 do
  if cpu_s=parseagain[i].need_string then
   begin
    old_addr:=exe_file_addr;
    exe_file_addr:=parseagain[i].file_addr;
     opcode(parseagain[i].for_parse_string);
    exe_file_addr:=old_addr;
   end; 


end;


procedure opcode(s2:string);
begin

write(ft,inttohex(addr_virtual,8),' ');


cpu_s:=trim(s2);

if xparse(cpu_s, ':') then
 begin
  AddLabel({XTRACTED[0][0]}xstr(0));
  check_again_parse;
  cpu_s:='';
 end;


if xparse(cpu_s,'.import') then cpu_s:='';

// ------------------------------------------- IMPORT --
if xparse(cpu_s, 'import ? ?') then
 begin
   ImportFunction(xstr(1),xstr(2));
   cpu_s:='';
 end;


// ------------------------------------------- .VAR --
if xparse(cpu_s,'.var') then
 begin
  RenderImport;
  SetAddr($200+length_ImportTotal);
  cpu_s:='';

  DLLNAMEStoVAR;
 end;

// ------------------------------------------- record (zero len) --
if xparse(cpu_s,'record ?') then
 begin
  Add_variable(xstr(1),xstr(1),0,addr_virtual);
  record_Index:=length(variables)-1;
  record_FileAddr:=exe_file_addr;
  record_Inside:=true;
  cpu_s:='';
 end;

if xparse(cpu_s,'end') then
 begin
  record_Inside:=false;
  Variables[record_Index].dummySize:=exe_file_addr-record_FileAddr;
  cpu_s:='';
 end;


// ------------------------------------------- byte --
if xparse(cpu_s,'byte ? 0x??') then
 begin
  Add_variable(xstr(1),xstr(2),sizeof(byte),addr_virtual);
  xcpu('',xdigitraw(2));
//  Write1(hextoint(xdigitraw(2)));
 end;

// ------------------------------------------- dword --
if xparse(cpu_s,'dword ? 0x????????') then
 begin
  Add_variable(xstr(1),xstr(2),sizeof(dword),addr_virtual);
  xcpu('',xdigitraw(2));
//  Write4(hextoint(xdigitraw(2)));
 end;


// ------------------------------------------- string --
if xparse(cpu_s,'string ? "') then
 begin
  Add_variable(xstr(1),xstr(2),length(xstr(2))-2+1,addr_virtual);
  WriteS(remove_quotes(xstr(2))+#0);
  cpu_s:='';
 end;


// ------------------------------------------- .CODE --
if xparse(cpu_s,'.code') then
 begin
  RenderVar;
  // code entry point
  SetAddr($40{PE}+$28);
  Write4({sections[_code].memoffs}$1000+length_ImportTotal
                                       +length_VarTotal);

  SetAddr({sections[_code].fileoffs}$200+length_ImportTotal+
                                         length_VarTotal);
  cpu_s:='';
 end;



cpu_b:=false;
smartparser('push ^',             'text|push~ val|1');        // PUSH ^var
smartparser('push @',             'text|push~0x ptr|1');      // PUSH @var
smartparser('push 0x??',          'text|6A raw|1');           // PUSH Imm8 "6A 00"
smartparser('push 0x????????',    'text|68 raw|1');           // PUSH IMM32 "68 00 00 00 00"
smartparser('push ???',           'text|50 +reg|1');          // push r32 "50+reg"
smartparser('call 0x????????',    'text|FF15 raw|1');         // CALL r/m32 "ff 15 00 00 00 00"
smartparser('call ?',             'text|FF15 dll|1');         // CALL r/m32 "ff 15 00 00 00 00"
smartparser('jmp 0x????????',     'text|E9 raw|1');               // JMP
smartparser('jmp ?',              'text|E9 label|1');             // JMP
smartparser('mov ^ eax',          'text|mov~0: ptr|1 text|~eax'); // MOV ^var,eax
smartparser('mov 0:???????? eax', 'text|A3 raw|1');               // MOV ptr,eax
smartparser('mov eax ^',          'text|mov~eax~0: ptr|2');       // MOV eax, ^var
smartparser('mov eax 0:????????', 'text|A1 raw|2');               // MOV eax, ptr


if cpu_b then
xcpu(cpu_s,'');





//if xparse(cpu_s, 'mov eax @') then xcpu(inttohex($B8+xregister(1),2),xpointer(2));


writeln(ft,s2);

end;

begin

 assignFile(ft,'log.txt');
 rewrite(ft);



end.

