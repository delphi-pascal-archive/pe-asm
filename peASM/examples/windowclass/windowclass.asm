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
import Kernel32.dll GetModuleHandleA

import User32.dll CreateWindowExA
import User32.dll ShowWindow
import User32.dll GetMessageA
import User32.dll DispatchMessageA
import User32.dll TranslateMessage
import User32.dll DefWindowProcA
import User32.dll RegisterClassExA

.var

record msg
	dword hwnd   0x00000000
	dword code   0x00000000
	dword wparam 0x00000000
	dword lparam 0x00000000
	dword time   0x00000000
	dword mousex 0x00000000
	dword mousey 0x00000000
end

string class_name "OpenGL"
string window_name "My window!"

record wndclassex
	dword size    0x00000030
	dword style   0x00000000
	dword wndproc 0x00000000
	dword extrac  0x00000000
	dword extraw  0x00000000
	dword hinst   0x00000000
	dword hico    0x00000000
	dword hcurs   0x00000000
	dword bgnd    0x00000000
	dword pmenu   0x00000000
	dword pclass  0x00000000
	dword hicosm  0x00000000
end

.code

push 0x00
call GetModuleHandleA

mov ^wndclassex.hinst, eax

mov eax, ^DefWindowProcA
mov ^wndclassex.wndproc, eax

mov eax, @class_name
mov ^wndclassex.pclass, eax

push @wndclassex
call RegisterClassExA 

mov eax,^wndclassex.hinst
push 0x00
push eax
push 0x00
push 0x00
push 0x70 // w
push 0x70 // h
push 0x00 // y
push 0x00 // x
push 0x10CF0000
push @window_name
push @class_name
push 0x00 // ext style

call CreateWindowExA

push 0x00000005
push eax
call ShowWindow

:mainloop
push 0x00
push 0x00
push 0x00
push @msg.hwnd
call GetMessageA

push @msg.hwnd
call TranslateMessage

push @msg.hwnd
call DispatchMessageA
jmp mainloop        

push 0x00
call ExitProcess
call DefWindowProcA
