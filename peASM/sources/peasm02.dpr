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

program peasm02;

{$APPTYPE CONSOLE}

uses
  my_asm,mystrtool;

begin

RenderExeHeaders;

UpdateSection0($200);

if trim(paramstr(1))='' then
 begin
  writeln('peasm.exe [source.asm] [output.exe]');
 end else
  begin
   RenderCode2(paramstr(1));
   MakeEXE(paramstr(2));
  end;

end.
