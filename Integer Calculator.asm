TITLE String Primitives and Macros    (Proj6_casinid.asm)

; Author: Derek Casini
; Last Modified: 3/17/2024
; OSU email address: casinid@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 3/17/2024
; Description: A program that asks the user for ASKSIZE numbers
; then prints them out, then finds and prints the sum and average

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays an inputted string
;
; Preconditions: None
;
; Receives:
; prompt = address of what to print
;
; returns: Nothing
; ---------------------------------------------------------------------------------

mDisplayString MACRO prompt
	PUSH	EDX
	MOV		EDX, prompt
	CALL	WriteString
	POP		EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Gets a string from the user
;
; Preconditions: None
;
; Receives:
; prompt = address of prompt for user input
;
; returns: input = address of where to save inputted number
; ---------------------------------------------------------------------------------

mGetString MACRO prompt, input
	PUSH	EDX
	PUSH	EAX
	PUSH	ECX

	mDisplayString    prompt
	MOV		EDX, input
	MOV		ECX, MAXSIZE
	CALL	ReadString

	POP		ECX
	POP		EAX
	POP		EDX
ENDM

MAXSIZE = 12
ASKSIZE = 10

.data
	intro1		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures", 0
	intro2		BYTE	"Written by: Derek Casini", 0
	intro3		BYTE	"Please provide 10 signed decimal integers.", 0
	intro4		BYTE	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value. ", 0
	error		BYTE	"ERROR: You did not enter an signed number or your number was too big.", 0
	tryAgain	BYTE	"Please try again: ", 0
	prompt		BYTE	"Please enter an signed number: ", 0
	youEntered	BYTE	"You entered the following numbers: ", 0
	sumPrompt	BYTE	"The sum of these numbers is: ", 0
	avgPrompt	BYTE	"The truncated average is: ", 0
	thanks		BYTE	"Thanks for playing!", 0
	numbers		SDWORD	ASKSIZE DUP(?)
	space		BYTE	", ", 0
	sum			SDWORD	0
	avg			SDWORD  0

.code

; ---------------------------------------------------------------------------------
; Name: main
;
; Asks the user for a string of numbers, prints them out, finds the sum of those,
; numbers aswell as the average, then prints those out
;
; Preconditions: None
;
; Postconditions: None
;
; Receives: None
;
; Returns: None
; ---------------------------------------------------------------------------------

main PROC
	PUSH	OFFSET intro4
	PUSH	OFFSET intro3
	PUSH	OFFSET intro2
	PUSH	OFFSET intro1
	CALL	Introduction

	PUSH	OFFSET space
	PUSH	OFFSET youEntered
	PUSH	OFFSET tryAgain
	PUSH	OFFSET error
	PUSH	OFFSET prompt
	PUSH	OFFSET numbers
	CALL	GetAndPrintNums

	LEA		EAX, sum
	PUSH	EAX
	PUSH	OFFSET numbers
	CALL	FindSum

	LEA		EBX, avg
	PUSH	EBX
	PUSH	sum
	CALL	FindAvg

	PUSH	OFFSET avgPrompt
	PUSH	OFFSET sumPrompt
	PUSH	avg
	PUSH	sum
	CALL	PrintSumAndAvg

	mDisplayString	OFFSET thanks
	Invoke ExitProcess, 0
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Asks the user for a string of numbers, checks to make sure what was inputted
; is a number and within MAXSIZE, then converts the number from ASCII to decimal
;
; Preconditions: None
;
; Postconditions: Changes the value of the current spot in numbers
;
; Receives: 
;		[EBP + 20] = address of current spot in numbers
;		[EBP + 16] = address of tryAgain
;		[EBP + 12] = address of error
;		[EBP + 8]  = address of prompt
;
; Returns: [EBP + 20] = value converted from ASCII to integer
; ---------------------------------------------------------------------------------

ReadVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	SUB		ESP, MAXSIZE				; Make room on stack for a buffer
	; Save used registers
	PUSH	EAX
	PUSH	EBX
    PUSH    ECX
    PUSH    EDX
    PUSH    EDI
    PUSH    ESI
	; Get string version of input from user
	LEA		ESI, [EBP - MAXSIZE]		; Point ESI to the start of the buffer
	MOV		EAX, [EBP + 8]

	mGetString    EAX, ESI
	; Set up conversion
_setup:
	XOR		EBX, EBX			
	XOR		EDX, EDX
	XOR		EDI, EDI
	XOR		ECX, ECX
	XOR		EAX, EAX
	CLD
_start:
	LODSB
	; End at null terminator
	CMP		AL, 0
	JE		_end
	; Check first character for a sign
	CMP		ECX, 0						
	JNE		_testAndConvert
	INC		ECX
	CMP		AL, '-'
	JE		_negative
	CMP		AL, '+'
	JE		_start
_testAndConvert:
	CMP		AL, 48						; Make sure digit >= 0
	JB		_error
	CMP		AL, 57						; Make sure digit <= 9
	JA		_error
	; Convert from ASCII to integer
	SUB		AL, 48
	IMUL	EBX, EBX, 10
	JO		_error
	ADD		EBX, EAX
	JMP		_start
_negative:
	INC		EDI							; Indicate number is negative
	JMP		_start
_end:
	CMP		ECX, 0
	JE		_error
	CMP		EDI, 0
	JE		_finish
	NEG		EBX
	JMP		_finish	
_error:
	mDisplayString    [EBP + 12]
	CALL	CrLf
	LEA		ESI, [EBP - MAXSIZE]		; Point ESI to the start of the buffer
	MOV		EAX, [EBP + 16]

	mGetString    EAX, ESI
	JMP		_setup
_finish:
	MOV		ESI, [EBP + 20]
	MOV		[ESI], EBX

	POP		ESI
	POP		EDI
	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX
	ADD		ESP, MAXSIZE
	POP		EBP
	RET		16
ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts a number to a string of ASCII characters and prints it out
;
; Preconditions: Pushed number to stack
;
; Postconditions: None
;
; Receives: 
;		[EBP + 8]  = value as integer
;
; Returns: none
; ---------------------------------------------------------------------------------

WriteVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	SUB		ESP, MAXSIZE				; Allocate space on the stack for a buffer
	; Save registers
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX
	PUSH	EDI
	PUSH	ESI
	
	MOV		EBX, [EBP + 8]				; Load number
	LEA		EDI, [EBP - MAXSIZE]		; Point EDI to the start of the buffer
	MOV		ECX, 10
	CLD
	; Handle negative sign
	TEST	EBX, EBX
	JNS		_positive
	NEG		EBX
	MOV		AL,	'-'
	STOSB
	MOV		EAX, 0
	PUSH	EAX
	MOV		EAX, EBX
	JMP		_convertToNum
	; Handle positive sign
_positive:
	MOV		AL, '+'
	STOSB
	MOV		EAX, 0
	PUSH	EAX
	MOV		EAX, EBX
_convertToNum:
	XOR		EDX, EDX
	DIV		ECX
	ADD		DL, 48
	PUSH	EDX
	CMP		EAX, 0
	JNZ		_convertToNum
	; Number is currently digit by digit on the stack, need to store into one string
_storeNum:
		POP		EAX
		CMP		EAX, 0
		JZ		_end					; Check for null terminator
		STOSB
	JMP		_storeNum
_end:
	STOSB								; Add null terminator
	LEA		EDI, [EBP - MAXSIZE]
	
	mDisplayString    EDI				; Print string of ASCII characters

	POP     ESI
	POP		EDI
    POP     EDX
    POP     ECX
    POP     EBX
    POP     EAX
	ADD		ESP, MAXSIZE
    POP     EBP
	RET		4
WriteVal ENDP

; ---------------------------------------------------------------------------------
; Name: FindSum
;
; Finds the sum of an array of numbers
;
; Preconditions: Pushed array onto the stack
;
; Postconditions: None
;
; Receives: 
;		[EBP + 8]  = address of numbers
;		[EBP + 12] = address of sum
;
; Returns: [EBP + 12] = sum
; ---------------------------------------------------------------------------------

FindSum	PROC
	PUSH	EBP
	MOV		EBP, ESP

	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	ESI
	PUSH	EDI
	; Setup to iterate through numbers
	MOV		ESI, [EBP + 8]
	MOV		EDI, [EBP + 12]
	XOR		EAX, EAX
	MOV		ECX, ASKSIZE
	; Add each value in numbers to EAX
_iterateArr:
		MOV		EBX, [ESI]
		ADD		EAX, EBX
		ADD		ESI, 4
	LOOP	_iterateArr
_end:
	MOV		[EDI], EAX					; Move the sum into the memory address of the sum global variable

	POP		EDI
	POP		ESI
	POP		ECX
	POP		EBX
	POP		EAX
	POP		EBP
	RET		8
FindSum	ENDP

; ---------------------------------------------------------------------------------
; Name: FindAvg
;
; Finds the average of an array of numbers
;
; Preconditions: Found the sum
;
; Postconditions: None
;
; Receives: 
;		[EBP + 8]  = value of sum
;		[EBP + 12] = address of avg
;
; Returns: [EBP + 12] = average
; ---------------------------------------------------------------------------------

FindAvg PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX
	PUSH	ESI

	XOR		ECX, ECX
	MOV		EAX, [EBP + 8]
	TEST	EAX, EAX
	JNS		_positive
	NEG		EAX
	INC		ECX
_positive:
	MOV		ESI, [EBP + 12]
	MOV		EBX, ASKSIZE
	XOR		EDX, EDX
	IDIV	EBX
	TEST	ECX, ECX
	JNS		_end
	NEG		EAX
_end:
	MOV		[ESI], EAX

	POP		ESI
	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX
	POP		EBP

	RET		8
FindAvg ENDP

; ---------------------------------------------------------------------------------
; Name: Introduction
;
; Prints out the intro
;
; Preconditions: None
;
; Postconditions: None
;
; Receives: 
;		[EBP + 8]  = address of intro1
;		[EBP + 12] = address of intro2
;		[EBP + 16] = address of intro3
;		[EBP + 20] = address of intro4
;
; Returns: [EBP + 12] = sum
; ---------------------------------------------------------------------------------

Introduction PROC
	PUSH	EBP
	MOV		EBP, ESP

	mDisplayString	[EBP + 8]
	CALL	CrLf
	mDisplayString	[EBP + 12]
	CALL	CrLf
	CALL	CrLf
	mDisplayString	[EBP + 16]
	CALL	CrLf
	mDisplayString	[EBP + 20]
	CALL	CrLf
	CALL	CrLf

	POP		EBP
	RET		16
Introduction ENDP

; ---------------------------------------------------------------------------------
; Name: GetAndPrintNums
;
; Asks the user for ASKSIZE numbers and prints out the inputted numbers
;
; Preconditions: Pushed number to stack
;
; Postconditions: None
;
; Receives: 
;       [EBP + 28] = address of space
;       [EBP + 24] = address of youEntered
;       [EBP + 20] = address of tryAgain
;		[EBP + 16] = address of error
;		[EBP + 12] = address of prompt
;		[EBP + 8]  = address of numbers
;
; Returns: none
; ---------------------------------------------------------------------------------

GetAndPrintNums PROC
	PUSH	EBP
	MOV		EBP, ESP
	; Save used registers
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX
	PUSH	ESI
	PUSH	EDI
	; Setup loop to iterate through numbers array
	MOV		ECX, ASKSIZE
	MOV		EDI, [EBP + 8]
	XOR		EDX, EDX
	; Gets ASKSIZE numbers and stores them in numbers
_loopIn:
		PUSH	EDI
		PUSH	[EBP + 20]
		PUSH	[EBP + 16]
		PUSH	[EBP + 12]
		CALL	ReadVal
		ADD		EDI, 4					; Move to next spot in numbers
	LOOP	_loopIn
	CALL	CrLf
	; Setup loop to iterate through numbers array again
	MOV		EDI, [EBP + 8]
	XOR		EBX, EBX
	MOV		ECX, ASKSIZE - 1
	mDisplayString    [EBP + 24]
	CALL	CrLf
	; Prints all the numbers
_printLoop:
		MOV		EAX, [EDI + EBX*4]
		PUSH	EAX
		CALL	WriteVal
		mDisplayString	  [EBP + 28]
		INC		EBX
	LOOP	_printLoop
	; Prints the last number without ", " at the end
	MOV		EAX, [EDI + EBX*4]
	PUSH	EAX
	CALL	WriteVal
	CALL	CrLf
	CALL	CrLf
	; Restore used registers
	POP		EDI
	POP		ESI
	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX
	POP		EBP
	RET		24
GetAndPrintNums ENDP

; ---------------------------------------------------------------------------------
; Name: PrintSumAndAvg
;
; Prints the sum and average
;
; Preconditions: Sum and average need to be found
;
; Postconditions: None
;
; Receives: 
;       [EBP + 20] = address of avgPrompt
;		[EBP + 16] = address of sumPrompt
;		[EBP + 12] = value of avg
;		[EBP + 8]  = value of sum
;
; Returns: none
; ---------------------------------------------------------------------------------

PrintSumAndAvg PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EAX
	PUSH	EBX
	PUSH	ESI
	PUSH	EDI

	MOV		EAX, [EBP + 8]
	MOV		EBX, [EBP + 12]
	MOV		ESI, [EBP + 16]
	MOV		EDI, [EBP + 20]
	; Print out sum
	mDisplayString		ESI
	PUSH	EAX
	CALL	WriteVal
	CALL	CrLf
	; Print out avg
	mDisplayString		EDI
	PUSH	EBX
	CALL	WriteVal
	CALL	CrLf
	CALL	CrLf
	; Restore used registers
	POP		EDI
	POP		ESI
	POP		EBX
	POP		EAX
	POP		EBP
	RET		16
PrintSumAndAvg ENDP

END main

