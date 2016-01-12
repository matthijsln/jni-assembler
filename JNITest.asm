; Java Native Interface/NASM example
; Copyright (C) Matthijs Laan <matthijsln@xs4all.nl>, February 10th 2002

; nasmw -f win32 -w+orphan-labels JNITest.asm
; link /dll /def:JNITest.def /out:JNITest.dll /entry:DLLMain /merge:.data=.code /merge:.rdata=.code /merge:.text=.code /align:4096 /section:.code,erw /subsystem:windows JNITest.obj user32.lib ddraw.lib msvcrt.lib kernel32.lib

%include "macros.inc"
%include "jni.inc"

global		_DLLMain
global          Java_JNITest_add, Java_JNITest_callInstanceMethod, Java_JNITest_callStaticMethod
global		Java_JNITest_sumIntArray, Java_JNITest_reverseASCIIString, Java_JNITest_changeStaticField
global		Java_JNITest_changeInstanceField, Java_JNITest_pi, Java_JNITest_sqrt
global		Java_JNITest_haveCPUID, Java_JNITest_vendorID, Java_JNITest_brandString

%define	jnienv	ebp+8
%define this	ebp+12
%define arg1	ebp+16
%define arg2	ebp+20
%define arg3	ebp+24
%define arg4	ebp+28
%define arg5	ebp+32

%define local1 	ebp-4
%define local2 	ebp-8
%define local3 	ebp-12
%define local4 	ebp-16

section .code

;-------------------------------------------------------------------------------

_DLLMain:
		xor	eax, eax
		inc	eax
		ret	0ch

;-------------------------------------------------------------------------------

%define a	arg1
%define b	arg2

Java_JNITest_add:
		enter	0, 0

		mov	eax, [a]
		add	eax, [b]

		leave
		ret	4 * 4			; stdcall calling convention, 4 parameters

;-------------------------------------------------------------------------------

section .data

imethodname	db "instanceCallback", 0
isignature	db "(I)V", 0

section .code

%define obj	arg1

Java_JNITest_callInstanceMethod:
		enter	0, 0

		mov	esi, [jnienv]
		mov	ebx, [esi]		; get the address of the method table

		mov	edi, [obj]

		invokeintf ebx, JNIEnv.GetObjectClass, esi, edi
		invokeintf ebx, JNIEnv.GetMethodID, esi, eax, dword imethodname, dword isignature

		invokeintf ebx, JNIEnv.CallIntMethod, esi, edi, eax, byte 123
		add	esp, 4 * 4		; C calling convention, we pushed 4 parameters
						; (esi, edi, eax, byte 123), so clean up the stack for those

		leave
		ret	3 * 4			; stdcall calling convention, 3 parameters

;-------------------------------------------------------------------------------

section .data

smethodname	db "staticCallback", 0
ssignature	db "(I)V", 0

section .code

%define clazz	arg1

Java_JNITest_callStaticMethod:
		enter	0, 0

		mov	esi, [jnienv]
		mov	ebx, [esi]		; get the address of the method table

		mov	edi, [clazz]

		invokeintf ebx, JNIEnv.GetStaticMethodID, esi, edi, dword smethodname, dword ssignature

		invokeintf ebx, JNIEnv.CallStaticIntMethod, esi, edi, eax, byte 13
		add	esp, 4 * 4		; C calling convention, we pushed 4 parameters
						; (esi, edi, eax, byte 13), so clean up the stack for those

		leave
		ret	3 * 4			; stdcall calling convention, 3 parameters

;-------------------------------------------------------------------------------

%define array	arg1

Java_JNITest_sumIntArray:
		enter	0, 0

		mov	esi, [jnienv]
		mov	ebx, [esi]		; get the address of the method table

		mov	edi, [array]

		invokeintf ebx, JNIEnv.GetArrayLength, esi, edi
		push	eax

		invokeintf ebx, JNIEnv.GetIntArrayElements, esi, edi, byte 0
		mov	edx, eax

		pop	ecx			; array length

		push	eax			; ptr to elements

		xor	eax, eax

		test	ecx, ecx
		jz	short .noelements

.loop:
		add	eax, dword [edx]
		add	edx, 4
		dec	ecx
		jnz	short .loop

.noelements:
		pop	ecx			; ptr to elements

		push	eax			; sum

		; don't copy back changes, because we didn't change them anyway
		invokeintf ebx, JNIEnv.ReleaseIntArrayElements, esi, edi, ecx, byte JNI_ABORT

		pop	eax			; sum

		leave
		ret	3 * 4			; stdcall calling convention, 3 parameters

;-------------------------------------------------------------------------------

section .data

notascii	db "String passed to reverseASCIIString() is not ASCII", 0
illegalargex	db "java/lang/IllegalArgumentException", 0

%define str	arg1

%define chars	local1

Java_JNITest_reverseASCIIString:
		enter 1 * 4, 0			; 1 local variable

		mov	esi, [jnienv]
		mov	ebx, [esi]		; get the address of the method table

		mov	edi, [str]

		; we only do ascii, so check if the string is ascii

		invokeintf ebx, JNIEnv.GetStringLength, esi, edi
		test	eax, eax
		jnz	short .notempty

		; don't bother - it's an empty string

		mov	eax, [str]
		jmp	.exit

.notempty:
		push	eax

		invokeintf ebx, JNIEnv.GetStringUTFLength, esi, edi

		pop	ecx
		push	eax			; length
		sub	eax, ecx
		jz	short .ascii

                ; not ascii - throw an exception

                invokeintf ebx, JNIEnv.FindClass, esi, dword illegalargex
		invokeintf ebx, JNIEnv.ThrowNew, esi, eax, dword notascii

		pop	ecx			; clean up stack, don't need length anymore
		xor	eax, eax

		jmp	.exit
.ascii:
		; we just reverse the characters in the source buffer. perhaps
		; that this could change some other strings if the string is not
		; copied by the JVM, but this seems to work

		invokeintf ebx, JNIEnv.GetStringUTFChars, esi, edi, byte 0
		mov	[chars], eax

		pop	ecx			; length

                push    esi
                push    edi
                push    ebx

                mov     edi, eax
                lea     esi, [eax+ecx-1]        ; end of string

                mov     ebx, ecx

                shr     ecx, 3
                jz      short .nod

                sub     esi, 3

                cmp     esi, edi
                je      short .done

.loopd:
                mov     eax, [esi]
                mov     edx, [edi]
                bswap   eax
                bswap   edx
                mov     [edi], eax
                mov     [esi], edx
                add     edi, 4
                sub     esi, 4
                dec     ecx
                jnz     short .loopd

                add     esi, 3
.nod:
                and     ebx, 110b
                jz      .done

.loopb:
                mov     al, [esi]
                mov     dl, [edi]
                mov     [esi], dl
                mov     [edi], al
                inc     edi
                dec     esi
                sub     ebx, 2
                jnz     short .loopb

.done:
                pop     ebx
                pop     edi
                pop     esi

		invokeintf ebx, JNIEnv.NewStringUTF, esi, dword [chars]
		push	eax

		invokeintf ebx, JNIEnv.ReleaseStringUTFChars, esi, edi, dword [chars]

		pop	eax

.exit:
		leave
		ret	3 * 4			; stdcall calling convention, 3 parameters

;-------------------------------------------------------------------------------

section .data

sfname	db "staticField", 0
sfsig	db "I", 0

section .code

%define clazz	local1
%define fieldid	local2

Java_JNITest_changeStaticField:
		enter	2 * 4, 0		; 2 local variables

		mov	esi, [jnienv]
		mov	ebx, [esi]		; get the address of the method table

		mov	eax, [this]

		invokeintf ebx, JNIEnv.GetObjectClass, esi, eax
		mov	[clazz], eax
                invokeintf ebx, JNIEnv.GetStaticFieldID, esi, eax, dword sfname, dword sfsig
		mov	[fieldid], eax

		invokeintf ebx, JNIEnv.GetStaticIntField, esi, dword [clazz], eax

		inc	eax			; change the field!

		invokeintf ebx, JNIEnv.SetStaticIntField, esi, dword [clazz], dword [fieldid], eax

		leave
		ret	2 * 4			; stdcall calling convention, 2 parameters

;-------------------------------------------------------------------------------

section .data

ifname	db "instanceField", 0
ifsig	db "I", 0

section .code

%define clazz	local1
%define fieldid	local2

Java_JNITest_changeInstanceField:
		enter	2 * 4, 0		; 2 local variables

		mov	esi, [jnienv]
		mov	ebx, [esi]		; get the address of the method table

		mov	eax, [this]

		invokeintf ebx, JNIEnv.GetObjectClass, esi, eax
		mov	[clazz], eax
                invokeintf ebx, JNIEnv.GetFieldID, esi, eax, dword ifname, dword ifsig
		mov	[fieldid], eax

		invokeintf ebx, JNIEnv.GetIntField, esi, dword [this], eax

		inc	eax			; change the field!

		invokeintf ebx, JNIEnv.SetIntField, esi, dword [this], dword [fieldid], eax

		leave
		ret	2 * 4			; stdcall calling convention, 2 parameters

;-------------------------------------------------------------------------------

Java_JNITest_pi:
		fldpi
		ret	2 * 4

;-------------------------------------------------------------------------------

Java_JNITest_sqrt:
		fld	qword [esp+12]		; note that this argument is 64 bytes,
						; so the next argument would be at
						; [esp+20] (ala arg3)
		fsqrt
		ret	2 * 4 + 1 * 8		; 2 dword args, 1 qword arg

;-------------------------------------------------------------------------------

Java_JNITest_haveCPUID:
		pushf
		pop	eax
		xor	eax, 1000000000000000000000b
		mov	ecx, eax
		push	eax
		popf
		pushf
		pop	eax
		cmp	eax, ecx
		je	short .ok
		xor	eax, eax
		jmp	short .end
.ok:
		xor	eax, eax
		inc	eax
.end:
		ret     2 * 4

;-------------------------------------------------------------------------------

Java_JNITest_vendorID:
		enter	0, 0

		xor	eax, eax
		cpuid
		push	byte 0
		push	ecx
		push	edx
		push	ebx

		push	esp			; bytes
		mov	eax, [ebp+8]
		push	eax			; env
		mov	ecx, [eax]
		call	[ecx+JNIEnv.NewStringUTF]

		leave
		ret	2 * 4

;-------------------------------------------------------------------------------

Java_JNITest_brandString:
		enter	0, 0

		push	byte 0

		mov	eax, 080000004h
		cpuid
		push	edx
		push	ecx
		push	ebx
		push	eax

		mov	eax, 080000003h
		cpuid
		push	edx
		push	ecx
		push	ebx
		push	eax

		mov	eax, 080000002h
		cpuid
		push	edx
		push	ecx
		push	ebx
		push	eax

		push	esp			; bytes
		mov	eax, [ebp+8]
		push	eax			; env
		mov	ecx, [eax]
		call	[ecx+JNIEnv.NewStringUTF]

		leave
		ret	2 * 4