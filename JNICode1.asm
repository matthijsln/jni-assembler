section .code
;-------------------------------------------------------------------------------
global		_DLLMain
_DLLMain:
		xor	eax, eax
		inc	eax
		ret	0ch
;-------------------------------------------------------------------------------
global          Java_JNITest1_inc
Java_JNITest1_inc:
		mov	eax, [esp+12]
		inc	eax
		ret	3 * 4

