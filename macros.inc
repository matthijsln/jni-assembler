; NASM utility macros
; Copyright (C) Matthijs Laan <matthijsln@xs4all.nl>, February 10th 2002

%ifndef __MACROS_INC
%define __MACROS_INC

; import a function from a Microsoft .lib
; example: __stdcall_dllimport	MessageBoxA, 4	; 4 dword parameters
%macro __stdcall_dllimport 2
  %assign __stdcall_dllimport_x (%2) * 4
  do__stdcall_dllimport %1, __stdcall_dllimport_x
%endmacro

%macro do__stdcall_dllimport 2
  extern __imp__%1@%2
  %define %1 __imp__%1@%2
%endmacro

; invoke a stdcall (right to left) function
%macro invoke 1-*
; %1	ptr to function
; [%2+]	args
  %rep %0-1
    %rotate -1
    push %1
  %endrep
  %rotate -1
  call dword [%1]
%endmacro

; invoke a stdcall interface method
%macro invokeintf 2-*
; %1	vtable ptr (reg)
; %2 	vtable offset (reg/const)
; %3	object ptr
; [%3+] args
; right to left stdcall
  %rep %0-2
    %rotate -1
    push %1
  %endrep
  %rotate -2
  call dword [%1 + %2]
%endmacro  

; define a string and the end and size of it
%macro string 2+
%1		db	%2
%1_end:
%1_size		equ	%1_end - %1
%endmacro

%endif; __MACROS_INC