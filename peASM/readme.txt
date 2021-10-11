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

    
1. Basic file structure

   .import
   import [dllname1] [functionname1]
   import [dllname1] [functionname2]
   import [dllname1] [functionname3]
   import [dllname2] [functionname1]
   import [dllname2] [functionname2]
   ...

   .var
   [type] [name] [value]
   [type] [name] [value]
   [type] [name] [value]
   ...

   .code
   [assembler instructions]
   ...


2. Importing functions from external DLL

   import [dllname] [functionname] 

   example:
   import Kernel32.dll ExitProcess



3. Supported variable types

   string [name] "[text]"
   byte   [name] [value]
   dword  [name] [value]

4. Accessing variables from code

   @somevar - dword pointer to variable
   =length(somevar) - dword size of variable
   =somevar - dword constant

5. Supported instructions

   push 0x00 - push byte
   push 0x00000000 - push dword
   push @somevar - push dword pointer to somevar
   push eax - push EAX register

   call 0x00000000 - call dword address
   call functionname - call function imported from dll

   jmp 0x00000000 - jump near
   jmp labelname - jump to label (not working for forward jumps)

6. Using labels

   :label1 
   push =STD_INPUT_HANDLE
   call getstdhandle

   push 0x00        // lpOverlapped 
   push @count      // lpNumberOfBytesWritten
   push =length(s1) // nNumberOfBytesToWrite
   push @s1         // lpBuffer
   push eax         // hFile
   call writefile
   jmp label1

7. EXE structure

   [DOS HEADER]
   [WIN32 HEADERS]
   [SECTION1]

   Section1:
   [Import tables]
   [Variables]
   [Code]

2010/01/06