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
import Kernel32.dll WriteFile
import Kernel32.dll GetStdHandle
import Kernel32.dll ExitProcess
import User32.dll MessageBoxA

.var
string s1 "This is a HELLO.ASM test message:"
string s2 "Congratulations! Hidden message!"
string message "12345 Hello world! Comment out JMP 0x17 in HELLO.ASM to see hidden message"
byte STD_INPUT_HANDLE 0xf5
dword count 0x00000000
dummy wow
dword MB_ICONASTERISK 0x00000040
string s3 "shit"


dword test_len 0x00000005
dword hFile 0x00000000

.code

push ^STD_INPUT_HANDLE
call getstdhandle
mov ^hFile, eax


push 0x00        // lpOverlapped 
push @count      // lpNumberOfBytesWritten
mov eax, ^test_len // nNumberOfBytesToWrite
push eax
//push ^length(s1) 
push @message       // lpBuffer
mov eax, ^hFile
push eax
call writefile

// comment out this jmp instruction to see hidden message:
jmp 0x00000017

jmp label2
push ^MB_ICONASTERISK // uType
push @s1              // lpCaption
push @s2              // lpText
push 0x00             // hWnd
call messageboxA

:label2

push ^MB_ICONASTERISK // uType
push @s1              // lpCaption
push @message         // lpText
push 0x00             // hWnd
call messageboxA     

push 0x00
call ExitProcess