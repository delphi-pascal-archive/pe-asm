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

.import
import	Kernel32.dll WriteFile
import	Kernel32.dll GetStdHandle
import Kernel32.dll ExitProcess

.var

record two_strings
	string s1 "This string have three parts:"
	string s2 "s1, s2"
	string somename "and s3."
end

byte STD_INPUT_HANDLE 0xf5
dword count 0x00000000


.code

push ^STD_INPUT_HANDLE
call getstdhandle

push 0x00        // lpOverlapped 
push @count      // lpNumberOfBytesWritten
push ^length(two_strings) // nNumberOfBytesToWrite
push @two_strings        // lpBuffer
push eax         // hFile
call writefile

push 0x00
call ExitProcess