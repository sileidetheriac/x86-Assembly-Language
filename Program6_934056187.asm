TITLE Portfolio Assignment 6     (Program6_934056187.asm)

; Author: Sileide De Freitas Theriac
; Last Modified: 03/12/2020
; OSU email address: defreits@oregonstate.edu
; Course number/section: CS 271/400
; Project Number: Proj 6                Due Date: 03/15/2020
; Description: Program prompts user for 10 signed integers, reads them as strings, then converts them into numeric form.
;	The numbers must fit inside a 32-bit register. User's input must be validated. Only valid numbers are kept.
;	Then, program calculates the sum and the average, rounded down to the nearest integer.
;	Last, program converts all numbers back to strings and displays all valid numbers, the sum and average as strings.
;	Implementation note: Parameters are passed on the system stack.
;						 When a macro is "called", the complete code is substituted
;						 for the macro name, and the macro parameters are replaced 
;						 with the actual arguments passed by address to the macros in the macro "call".
;	Note: Program makes use of macro example from Lecture 26: Introduction to Macros.
;		  Program makes use of ReadInt algorithm pseudo-code from Lecture 23: Lower-Level Programming.
;		  Program makes partial use of reverse string code from demo6.asm

INCLUDE Irvine32.inc

ARRAYSIZE = 10											;Constant for size of array = 10 numbers will be requested.
MAXSIZE = 100											;To be used inside macro for length of string.

getString	MACRO   prompt, input, size					;Macro to prompt user for 10 integers and read them as strings.
	push	ecx
	push	edx
	mov		edx, prompt									
	call	WriteString
	mov		edx, input
	mov		ecx, size
	call	ReadString		
	pop		edx
	pop		ecx
ENDM

displayString MACRO line_to_display						;Macro to display strings throughout the program.
	push	edx
	mov		edx, line_to_display
	call	WriteString
	pop		edx
ENDM


.data

intro_1			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures ",0							;Introduce Title.
intro_2			BYTE	"Written by: Sileide De Freitas Theriac ",0													;Introduce programmer.
intro_3			BYTE	"Please provide 10 signed decimal integers. ",0												;Inital program introduction.
intro_4			BYTE	"Each number needs to be small enough to fit inside a 32 bit register. ",0					;Inital program introduction.
intro_5			BYTE	"After you have finished inputting the raw numbers I will display a list ",0				;Inital program introduction.
intro_6			BYTE	"of the integers, their sum, and their average value.",0									;Inital program introduction.
prompt			BYTE	"Please enter an signed number: ",0															;Prompts user for a signed number.
user_input		BYTE	MAXSIZE DUP(?)																				;Signed number to be entered by user as string.
array_num		SDWORD	ARRAYSIZE DUP(?)																			;To store valid numbers.
LoopCounter		DWORD	?																							;To keep track of loops.
LoopCounter1	DWORD	?																							;To keep track of loops.
value_x			DWORD	?																							;To store converted ASCII values.
error_Msg		BYTE	"ERROR: You did not enter a signed number or your number was too big. ",0					;Error message for invalid inputs.
prompt2			BYTE	"Please try again: ",0																		;Prompts user for a new input.
list_msg		BYTE	"You entered the following numbers: ",0														;To display all numbers as strings.
space			BYTE	", ",0																						;To add a comma between numbers.
sumtxt			BYTE	"The sum of these numbers is: ",0															;To display result of sum.
avrtxt			BYTE	"The rounded average is: ",0																;To display result of average.
sumtotal		SDWORD	?																							;To store integer value of sum.
avrtotal		SDWORD	?																							;To store integer value of average.
str_sum			BYTE	MAXSIZE DUP(?)																				;To store sum as string.
str_avr			BYTE	MAXSIZE DUP(?)																				;To store average as string.
allnums_str		BYTE	MAXSIZE DUP(?)																				;To store all numbers as string.
temp_val		BYTE	MAXSIZE DUP(?)																				;Temp variable to store temporary values in program.
temp_counter	DWORD	?																							;Temp variable to store temporary values in program.
hold_sum		SDWORD	?																							;To keep track of the correct result of sum.
byebye_msg		BYTE	"Thanks for playing! ",0																	;Farewell message.

.code
main PROC

	push  OFFSET intro_1
	push  OFFSET intro_2
	push  OFFSET intro_3
	push  OFFSET intro_4
	push  OFFSET intro_5
	push  OFFSET intro_6
	call  introduction

	
	push  OFFSET prompt2	
	push  OFFSET error_Msg	
	push  value_x			
	push  OFFSET prompt		
	push  OFFSET user_input	
	push  OFFSET array_num	
	push  LoopCounter		
	push  MAXSIZE			
	call  readVal
	
	
	push  LoopCounter1		
	push  OFFSET allnums_str  
	push  OFFSET list_msg	
	push  OFFSET space		
	push  hold_sum			
	push  OFFSET str_avr    
	push  temp_counter		
	push  OFFSET temp_val	
	push  value_x			
	push  OFFSET str_sum	
	push  OFFSET avrtxt		
	push  avrtotal			
	push  sumtotal			
	push  ARRAYSIZE         
	push  OFFSET array_num  
	push  OFFSET sumtxt		
	call  writeVal


	push  OFFSET byebye_msg
	call farewell

	exit															; exit to operating system
main ENDP

;Procedure to introduce the program.
;receives: addresses of parameters on the system stack.
;returns: None
;preconditions: None
;registers changed: edx
introduction PROC
	push	ebp
	mov		ebp, esp

	displayString [ebp + 28]										;"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures "
	call	CrLf

	displayString [ebp + 24]										;"Written by: Sileide De Freitas Theriac "	
	call	CrLf
	call	CrLf

	displayString [ebp + 20]										;"Please provide 10 signed decimal integers. "	
	displayString [ebp + 16]										;"Each number needs to be small enough to fit inside a 32 bit register. "
	displayString [ebp + 12]										;"After you have finished inputting the raw numbers I will display a list "
	displayString [ebp + 8]											;"of the integers, their sum, and their average value."
	call	CrLf
	call	CrLf

	pop		ebp   
	ret		24
introduction ENDP


;Procedure to prompt user for 10 numbers by invoking the getString macro, and read them as string. 
;	Then, validates them and convert the strings to numbers.
;receives: addresses of parameters on the system stack and user's input.
;returns: None
;preconditions: Numbers must fit in 32 bit register, be negative or positive. Non-digits inputs are discarded.
;registers changed: eax, ebx, ecx, edx, edi, esi, al

readVal PROC
	push	ebp
	mov		ebp, esp
	mov		edi, [ebp+16]											;Destination = array_num

start:
	mov		edx, [ebp+28]											;To reset the value_x after each number is converted.
	mov		edx, 0
	mov		[ebp+28], edx

	mov		ebx, [ebp+12]											;LoopCounter - To keep track of loops.
	inc		ebx
	mov		[ebp+12], ebx
	   	 
	getString	[ebp+24], [ebp+20], [ebp+8]							;Invoke Macro passing the address of prompt, user input and the input size.

validate:				
	mov		esi, [ebp+20]											;user_input is the source.
	
	mov		ecx, eax												;Set the loop counter to the size of string
	cld																;Direction flag forward.
	lodsb															;Byte by byte.
	cmp		al, 45													;Is first character the - sign?
	je		neg_number												;If yes, then begin conversion to integer.						
	cmp		al, 43													;Is first character the + sign?
	je		pos_number												;If yes, then begin conversion to integer.
	cmp		al, 47													;Is first character a number?
	jbe		ErrorMsg												;If not a number, discard and prompt user for new input.
	cmp		al, 57													;Is first character a number?
	jbe		str_to_number											;If yes, then begin conversion to integer.
	jmp		ErrorMsg												;If not a number, discard and prompt user for new input.

pos_number:
	dec ecx															;If first char was a sign, move to next character.

loop1:	
	lodsb
	cmp		ecx, 0
	je		fill_array												;When entire string has been converted and validated, store it.
	cmp		al, 47													;Is character a number?
	jbe		ErrorMsg												;If not a number, discard and prompt user for new input.
	cmp		al, 57													;Is character a number?
	jbe		str_to_number											;If yes, then continue conversion to integer.
	jmp		ErrorMsg												;If not a number, discard and prompt user for new input.

str_to_number:
	push    ecx
	mov		edx, eax
	sub		edx, 48													;Subtract ASCII value by 48.
	mov		ecx, edx
	mov		eax, 10
	mov		ebx, [ebp+28]											;Multiply 10 by value_x, which starts at zero.	
	mul		ebx
	jo		ErrorMsg1												;Check if number fits in a 32 bit register.
	add		eax, ecx												;Adds both results from above.
	jo		ErrorMsg1												;Check if number fits in a 32 bit register.
	mov		[ebp+28], eax											;If valid number, store it in value_x.
	mov		eax, 0													;Reset eax.
	pop		ecx		
	loop	loop1													;Check each character again until end of string.
	jmp		loop1

neg_number:															;Section for negative inputs.
	lodsb
	cmp		ecx, 0													;Move to next charcter and check if end has been reached.
	je		convert_neg1
	dec		ecx														;Length is decrement by one due to sign.
	cmp		ecx, 0														
	je		convert_neg1											;Convert character if end has been reached.	
	cmp		al, 47													;Is character a number?
	jbe		ErrorMsg												;If not a number, discard and prompt user for new input.
	cmp		al, 57													;Is character a number?
	jbe		convert_neg												;If yes, then continue conversion to integer.
	jmp		ErrorMsg												;If not a number, discard and prompt user for new input.
	

convert_neg:														;Section to convert negative inputs.
	push    ecx
	mov		edx, eax
	sub		edx, 48													;Subtract ASCII value by 48.
	mov		ecx, edx
	mov		eax, 10
	mov		ebx, [ebp+28]														
	mul		ebx														;Multiply 10 by value_x, which starts at zero.
	jo		ErrorMsg1												;Check if number fits in a 32 bit register.
	add		eax, ecx												;Adds both results from above.
	jo		ErrorMsg1												;Check if number fits in a 32 bit register.
	mov		[ebp+28], eax											;If valid number, store it in value_x.
	mov		eax, 0													;Reset eax.
	pop		ecx		
	jmp		neg_number												;Check each character again until end of string.

convert_neg1:
	mov		eax, [ebp+28]											;When all string has been converted to a number
	neg		eax														;Make it a negative number.
	mov		[ebp+28], eax
	jmp		fill_array												;Then store it in array.
	
	
fill_array:	
	mov		eax, [ebp+28]											;Store value in array.
	mov		[edi], eax														
	add		edi, 4													;Next value will be in next position inside array.
	mov		ebx, 0
	jmp		theEnd

ErrorMsg:															;Error msg will display for large numbers, or invalid inputs.
	or		eax, 0													;clear overflow flag.
	mov		eax, 0		
	mov		edx, [ebp+28]											;Reset the value_x.
	mov		edx, 0
	mov		[ebp+28], edx
	mov		ebx, 0
	displayString  [ebp+32]											;"ERROR: You did not enter a signed number or your number was too big. "
	call	CrLf
	getString	[ebp+36], [ebp+20], [ebp+8]							;Prompt user for a new input.
	jmp		validate												;Go back to beginning.

ErrorMsg1:															;Extra label just so ecx can be popped.
	or		eax, 0													;clear overflow flag.
	mov		eax, 0		
	mov		edx, [ebp+28]											;Reset the value_x.
	mov		edx, 0
	mov		[ebp+28], edx
	mov		ebx, 0
	pop		ecx														;Keeping the stack aligned.
	displayString  [ebp+32]											;"ERROR: You did not enter a signed number or your number was too big. "
	call	CrLf
	getString	[ebp+36], [ebp+20], [ebp+8]							;Prompt user for a new input.
	jmp		validate												;Go back to beginning.

theEnd:
	mov		ebx, [ebp+12]											;LoopCounter - Check if we have 10 numbers.
	cmp		ebx, 10
	jl		start													;Not 10 yet? Back to the top.

	pop		ebp   
	ret		32
readVal ENDP

;Procedure to convert numeric values to a string of digits, and invoke the displayString
;	macro to produce the output.
;receives: addresses of parameters on the system stack.
;returns: Converts numbers to strings and displays the results as strings.
;preconditions: Numbers must be converted back to string.
;registers changed: eax, ebx, ecx, edx, edi, esi, al

writeVal PROC
	push	ebp
	mov		ebp, esp	

;Add all numbers to get the total sum.	

	mov		edi, [ebp+12]											;array filled with integers.
	mov		ecx, [ebp+16]											;set loop to size of array.
	dec		ecx	

loop1:
	add		eax, [edi]												;Get current number.
	add		[ebp+20], eax											;Total goes into SumTotal
	add		edi, 4													;Move to next number and add with current.
	loop	loop1

	mov		[ebp+20], eax											;Saves the total inside SumTotal
	mov		[ebp+52], eax											;Saves the total sum to use with average.

	push	eax
	push	edx
	push	ebx
	push	ecx
	mov		eax, [ebp+20]											;Get total of sum and prepare for conversion into a string.

counter_start:														;Lets see how many digits this number has.
	cdq
	mov		ebx, 10													;Divide number by 10.
	idiv	ebx
	cmp		eax, 0													;Lets see how many times the loop takes to reach zero.
	jnz		inc_counter												;Add one to counter each time.
	mov		ecx, [ebp+44]												
	inc		ecx														;Now we have the exact length of number.
	mov		[ebp+44], ecx
	pop		ecx
	pop		ebx
	pop		edx
	pop		eax
	mov		eax, [ebp+20]											;Making sure the sum is correctly in eax.
	cmp		eax, 0													;Is the number positive or negative?
	jl		inc_counter_neg											;If negative, lets treat in a different way.
	jge		num_to_str

inc_counter:
	mov		ecx, [ebp+44]											;Counting digits and storing amount in a temp counter.
	inc		ecx		
	mov		[ebp+44], ecx
	jmp		counter_start

inc_counter_neg:
	mov		ecx, [ebp+44]											;If negative, we need an extra space for the sign.
	inc		ecx		
	mov		[ebp+44], ecx
	jmp		num_to_str_neg

num_to_str:															;Now, lets convert into a string.
	mov		edi, [ebp+40]											;Lets temporarily store the string here.		
	mov		eax, [ebp+20]											;Sumtotal as integer.
	jmp		sumtostr

num_to_str_neg:														;Converting a negative number into a string.
	mov		edi, [ebp+40]											;Lets temporarily store the string here.
	mov		eax, [ebp+20]											;Sumtotal as integer
	mov		ebx, -1
	imul	ebx														;Convert into a positive number first.
	mov		[ebp+20], eax
	mov		eax, [ebp+20]											;Store the sumtotal as a positive integer.
	jmp		sumtostr_neg

sumtostr:															;Bringing number back to string.
	mov		edx, 0
	cdq
	mov		ebx, 10											
	idiv	ebx														;Divide number by 10.
	add		edx, 48													;Add 48 to remainder.
	mov		[ebp+36], eax											;Keeps track of value of x.
	mov		eax, edx												;ASCII value.
	cld	
	stosb															;Store ASCII value in temporary location.
	mov		eax, [ebp+36]											;See if division has reached zero.
	cmp		eax, 0
	je		show_str
	jmp		sumtostr												;If not, repeat until whole number has been converted to string.

show_str:	
	mov		ecx, [ebp+44]											;We have the amount of digits, so we store them one by one.
	mov		esi, [ebp+40]											;String is reversed, so lets fix it.
	add		esi, ecx
	dec		esi
	mov		edi, [ebp+32]											;The correct string will be stored here, total sum as string.	
	jmp		reverse

sumtostr_neg:														;If the result was negative, we convert here.
	mov		edx, 0
	cdq
	mov		ebx, 10									
	idiv	ebx														;Divide number by 10.
	add		edx, 48													;Add 48 to remainder.
	mov		[ebp+36], eax											;Keeps track of value of x.
	mov		eax, edx												;ASCII value.
	cld	
	stosb															;Store ASCII value in temporary location.
	mov		eax, [ebp+36]											;Check if division has reached zero.
	cmp		eax, 0
	je		show_str_neg												
	jmp		sumtostr_neg											;If not, repeat until whole number has been converted to string.

show_str_neg:	
	mov		al, 45													;Number was negative, so we need to add the "-" sign on string.
	cld	
	stosb	
	mov		ecx, [ebp+44]											;We have the amount of digits, so we store them one by one.
	mov		esi, [ebp+40]											;String is reversed, so lets fix it.
	add		esi, ecx
	dec		esi
	mov		edi, [ebp+32]											;The correct string will be stored here, total sum as string.

reverse:															;Fixing the string.
	std
	lodsb
	cld
	stosb
	loop	reverse
	mov		al, 0													;When done, add the null byte at the end.
	std	
	stosb
	
;Calculation and conversion of the average result begins here.

average_section:
	mov		ecx, 0
	mov		[ebp+44], ecx											;Restarting the counter.

	mov		edx, 0	
	mov		eax, [ebp+52]											;Value saved as total of sum.	
	cdq
	mov		ebx, 10													
	idiv	ebx														;We divide total sum by 10.
	cmp		edx, 1
	jge		rounddown												;Round down to the nearest integer.
	mov		[ebp+24], eax											;Result stored in avrtotal as integer.
	jmp		avr_str

rounddown:
	mov		edx, 0
	mov		[ebp+24], eax											;Rounded down result stored in avrtotal as integer.
	
avr_str:															;Prepare to convert average into string.
	push	eax
	push	edx
	push	ebx
	push	ecx
	mov		eax, [ebp+24]											;Result stored in avrtotal as integer.

counter_start1:														;Lets see how many digits this number has.
	cdq
	mov		ebx, 10
	idiv	ebx														;We will divide it by 10 
	cmp		eax, 0													;and see how many times it takes to reach zero.
	jnz		inc_counter1
	mov		ecx, [ebp+44]											;Add one to counter each time.
	inc		ecx
	mov		[ebp+44], ecx											;Now we have the exact length of number.
	pop		ecx
	pop		ebx
	pop		edx
	pop		eax
	mov		eax, [ebp+24]											;Making sure the result is correctly in eax.
	cmp		eax, 0													;Is the number positive or negative?
	jl		inc_counter_neg1										;If negative, lets treat in a different way.
	jge		num_to_str1

inc_counter1:
	mov		ecx, [ebp+44]											;Counting digits and storing amount in a temp counter.
	inc		ecx
	mov		[ebp+44], ecx
	jmp		counter_start1

inc_counter_neg1:
	mov		ecx, [ebp+44]											;If negative, we need an extra space for the sign.
	inc		ecx		
	mov		[ebp+44], ecx
	jmp		num_to_str_neg1

num_to_str1:														;Now, lets convert into a string.
	mov		edi, 0													;Resetting registers to not mix up with previous values.
	mov		esi, 0
	mov		edi, [ebp+40]											;Lets temporarily store the string here.
	mov		eax, [ebp+24]											;Average as integer.
	jmp		avrtostr1

num_to_str_neg1:													;Converting a negative number into a string.
	mov		edi, [ebp+40]											;Lets temporarily store the string here.
	mov		eax, [ebp+24]											;Average as integer.
	mov		ebx, -1
	imul	ebx														;Convert into a positive number first.
	mov		[ebp+24], eax
	mov		eax, [ebp+24]											;Store the average as a positive integer.
	jmp		avrtostr_neg1

avrtostr1:															;Bringing number back to string.
	mov		edx, 0
	cdq
	mov		ebx, 10													;Divide number by 10.
	idiv	ebx
	add		edx, 48													;Add 48 to remainder.
	mov		[ebp+36], eax											;Keeps track of value of x.
	mov		eax, edx												;ASCII value.
	cld		
	stosb															;Store ASCII value in temporary location.
	mov		eax, [ebp+36]												
	cmp		eax, 0													;See if division has reached zero.
	je		show_str1
	jmp		avrtostr1												;If not, repeat until whole number has been converted to string.
show_str1:
	mov		ecx, [ebp+44]											;We have the amount of digits, so we store them one by one.
	mov		esi, [ebp+40]											;String is reversed, so lets fix it.
	add		esi, ecx
	dec		esi
	mov		edi, [ebp+48]											;The correct string will be stored here, average as string.
	jmp		reverse1

avrtostr_neg1:														;If the result was negative, we convert here.
	mov		edx, 0
	cdq
	mov		ebx, 10													;Divide number by 10.
	idiv	ebx
	add		edx, 48													;Add 48 to remainder.
	mov		[ebp+36], eax											;Keeps track of value of x.
	mov		eax, edx												;ASCII value.
	cld	
	stosb															;Store ASCII value in temporary location.
	mov		eax, [ebp+36]
	cmp		eax, 0													;Check if division has reached zero.
	je		show_str_neg1
	jmp		avrtostr_neg1											;If not, repeat until whole number has been converted to string.
		
show_str_neg1:	
	mov		al, 45													;Number was negative, so we need to add the "-" sign on string.
	cld	
	stosb																
	mov		ecx, [ebp+44]											;We have the amount of digits, so we store them one by one.
	mov		esi, [ebp+40]											;String is reversed, so lets fix it.
	add		esi, ecx
	dec		esi
	mov		edi, [ebp+48]											;The correct string will be stored here, average as string.

reverse1:															;Fixing the string.
	std
	lodsb
	cld
	stosb
	loop	reverse1
	mov		al, 0													;When done, add the null byte at the end.
	std	
	stosb

;Now, we convert all numbers into strings and display them.

	call	CrLf
	displayString [ebp+60]											;"You entered the following numbers:"
	call	CrLf


	mov		ecx, 0
	mov		[ebp+44], ecx											;Restarting the counter.
	mov		[ebp+36], ecx											;Restarting the value of x.

	mov		ebx, 1
	mov		[ebp+68], ebx											;To keep track of loops.
	mov		ebx, 0
	mov		esi, [ebp+12]											;array of integers.

begin:	
	mov		ecx, 0
	mov		[ebp+44], ecx											;Restarting the counter after each number has been converted.
	mov		[ebp+36], ecx											;Restarting the value of x after each number has been converted.
	mov		eax, 0
	mov		ebx, 0
	mov		ecx, 0													;Clearing all registers.
	mov		edx, 0
	mov		eax, [esi]												;Start with first number in array.
	cmp		eax, 0													;Is the number positive or negative?
	jl		makepositive
	jge		counter_start2

makepositive:														;If negative, lets make it positive to make it easier to count digits.
	mov		eax, [esi]
	mov		ebx, -1													;We multiply by -1 to get a positive number.
	imul	ebx
	mov		ebx, 0

neg_counter:														;Now we count the digits.
	cdq
	mov		ebx, 10													;By dividing by 10 and seeing how many loops it takes to reach zero.
	idiv	ebx
	cmp		eax, 0
	jnz		inc_counter_neg2
	mov		ecx, [ebp+44]											;We keep track of amount of digits in this counter.
	inc		ecx
	mov		[ebp+44], ecx												
	mov		eax, 0
	mov		ebx, 0
	mov		ecx, 0													;Restart registers.
	mov		edx, 0
	jmp		make_space_sign											;Then, we add an extra space for the sign.

inc_counter_neg2:													;At every loop, we add 1 to counter.
	mov		ecx, [ebp+44]
	inc		ecx
	mov		[ebp+44], ecx
	jmp		neg_counter

counter_start2:														;If the number is positive, then we use this section.
	cdq
	mov		ebx, 10													;We count the digits.
	idiv	ebx														;By dividing by 10 and seeing how many loops it takes to reach zero.
	cmp		eax, 0
	jnz		inc_counter2
	mov		ecx, [ebp+44]											;We keep track of amount of digits in this counter.
	inc		ecx
	mov		[ebp+44], ecx
	mov		eax, 0
	mov		ebx, 0
	mov		ecx, 0													;Restart registers.
	mov		edx, 0
	mov		eax, [esi]												;Now, we know the amount of digits.
	jmp		num_to_str2

inc_counter2:														;At every loop, we add 1 to counter.
	mov		ecx, [ebp+44]
	inc		ecx
	mov		[ebp+44], ecx
	jmp		counter_start2

make_space_sign:
	mov		ecx, [ebp+44]											;Adding an extra space for the sign, so add 1 more to counter.
	inc		ecx		
	mov		[ebp+44], ecx
	jmp		num_to_str_neg2

num_to_str2:														;Now, lets convert into a string.
	mov		edi, 0													;Restart edi.
	mov		edi, [ebp+40]											;Lets temporarily store the string here.
	mov		eax, [esi]												;Current number in list, as negative.
	jmp		list_to_str

num_to_str_neg2:													;Converting a negative number into a string.
	mov		edi, [ebp+40]											;Lets temporarily store the string here.
	mov		eax, [esi]												;Current number in list.
	mov		ebx, -1													;Convert into a positive number.
	imul	ebx
	mov		[esi], eax												;Lets use the positive version.
	mov		eax, [esi]													
	jmp		list_to_str_neg

list_to_str:														;Bringing numbers back to string.
	mov		edx, 0
	cdq
	mov		ebx, 10													;Divide number by 10.
	idiv	ebx
	add		edx, 48													;Add 48 to remainder.
	mov		[ebp+36], eax											;Keeps track of value of x.
	mov		eax, edx												;ASCII value.
	cld	
	stosb															;Store ASCII value in temporary location.
	mov		eax, [ebp+36]
	cmp		eax, 0													;See if division has reached zero.
	je		show_str2
	jmp		list_to_str												;If not, repeat until whole number has been converted to string.

show_str2:
	push	esi	
	mov		ecx, [ebp+44]											;We have the amount of digits, so we store them one by one.
	mov		esi, [ebp+40]											;String is reversed, so lets fix it.
	add		esi, ecx
	dec		esi	
	mov		edi, [ebp+64]											;The correct string will be stored here, user input value as string.
	jmp		reverse2

list_to_str_neg:													;If the number was negative, we convert here.
	mov		edx, 0
	cdq
	mov		ebx, 10													;Divide number by 10.
	idiv	ebx
	add		edx, 48													;Add 48 to remainder.
	mov		[ebp+36], eax											;Keeps track of value of x.
	mov		eax, edx												;ASCII value.
	cld	
	stosb															;Store ASCII value in temporary location.
	mov		eax, [ebp+36]
	cmp		eax, 0													;See if division has reached zero.
	je		show_str_neg2
	jmp		list_to_str_neg											;If not, repeat until whole number has been converted to string.

show_str_neg2:	
	push	esi
	mov		al, 45													;Number was negative, so we need to add the "-" sign on string.
	cld	
	stosb	
	mov		ecx, [ebp+44]											;We have the amount of digits, so we store them one by one.
	mov		esi, [ebp+40]											;String is reversed, so lets fix it.
	add		esi, ecx
	dec		esi
	mov		edi, [ebp+64]											;The correct string will be stored here, user input value as string.

reverse2:
	std
	lodsb
	cld
	stosb
	loop	reverse2
	mov		al, 0													;When done, add the null byte at the end of string.
	std	
	stosb
	pop		esi

	displayString  [ebp+64]											;Display current number as string.
	mov		ebx, [ebp+68]
	cmp		ebx, 10													;No comma after last number.													
	je		skip_comma
	displayString [ebp+56]											;Display comma and space between numbers
	
	
skip_comma:															
	mov		ebx, [ebp+68]
	cmp		ebx, 10													;To keep track of loops.
	je		byebye													;If 10 loops, then we are done.
	inc		ebx														
	mov		[ebp+68], ebx											;If not, increment counter.
	add		esi, 4													;Move to next number in array.
	mov		ecx, 0
	mov		[ebp+44], ecx											;Restarting the counter.
	mov		[ebp+36], ecx											;Restarting value of x.
	jmp		begin
	
	
byebye:																;Now, display sum and average as strings.

	call	CrLf
	displayString  [ebp+8]											;"The sum of these numbers is: "
	displayString  [ebp+32]											;Display total sum as string.
	call	CrLf

	displayString  [ebp+28]											;"The rounded average is: "
	displayString  [ebp+48]											;Display average as string.
	call	CrLf
	call	CrLf

	pop		ebp
	ret		64	
			
writeVal ENDP

;Procedure to end the program.
;receives: address of parameter on the system stack.
;returns: Displays farewell message using displayString macro.
;preconditions: None
;registers changed: edx

farewell PROC
	push	ebp
	mov		ebp, esp

	displayString  [ebp+8]											;"Thanks for playing!"
	call	CrLf

	pop		ebp
	ret
farewell ENDP

END main

