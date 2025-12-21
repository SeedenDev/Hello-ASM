.intel_syntax noprefix

.section .bss
	inputBuffer: .skip 256
	consumeBuffer: .skip 1

.section .data
//NASM syntax
// STDIN: equ 0
// msg:	db "Hello World!\n"
// asklen: equ $ - ask
// inputbuf times inputlen db '_'
//(GNU style= inputbuf: .fill inputlen, 1, '_')

// PRINTED STRINGS
askMsg: .asciz "Your input: "
askMsgLen = . - askMsg

answerMsg: .asciz "You said:\n"
answerMsgLen = . - answerMsg

errorMsg: .asciz "Error: input is empty\n"
errorMsgLen = . - errorMsg

inputBufferLen = 256

// GLOBAL CONSTANTS
STDIN = 0
STDOUT = 1
STDERR = 2

EXIT_SUCCESS = 0
EXIT_FAILURE = 1

SYSREAD = 0x00
SYSWRITE = 0x01
SYSEXIT = 0x3c

// \n
NEWLINE = 0xa

// PROGRAM "LOGIC" START
.section .text
.global _start
_start:
	// default exit code
	mov r8, EXIT_SUCCESS

	// Print the message asking for input
	mov rax, SYSWRITE
	mov rdi, STDOUT
	lea rsi, askMsg
	mov rdx, askMsgLen
	syscall

	// Get the user input
	mov rax, SYSREAD
	mov rdi, STDIN
	lea rsi, inputBuffer
	mov rdx, inputBufferLen
	syscall

	// return value of SYSREAD is put in register rax
	// it represents the size in byte of the input
	// if it is only a '\n' (0xa) it means that the user didn't enter anything
	// then we return an error
	cmpb [inputBuffer], 0xa
	je error
	// else, let's put in on the stack to get it back later on the program
	push rax
	// and before continuing we consume all characters beyond the input buffer size limit
	call consumeExtraInput

	// Print the answer message
	mov rax, SYSWRITE
	mov rdi, STDOUT
	lea rsi, answerMsg
	mov rdx, answerMsgLen
	syscall

	// Print the user input
	mov rax, SYSWRITE
	mov rdi, STDOUT
	lea rsi, inputBuffer
	//TODO add rsi, 0xa (add a newline)
	// Get back the user input size in byte from the stack
	// and put it in the rdx register for SYSWRITE
	pop rdx
	syscall
	
	// end the program here
	jmp end

// Read byte a byte to clear the extra (consume the input)
consumeOneByte:
	// Consume one byte from the input
    mov rax, SYSREAD
    mov rdi, STDIN
    lea rsi, consumeBuffer
    mov rdx, 1
    syscall
    
	// check if it is '\n' (=user pressed enter to send the input=end)
    cmpb [consumeBuffer], 0xa
	// if not consume one more, and if true go naturally to "consumeExtraInput" 
	// in which rax will be 1 ==> calling return and going back to the main program
    jne consumeOneByte

consumeExtraInput:
	cmp rax, inputBufferLen
	je consumeOneByte
	ret

error:
	mov rax, SYSWRITE
	mov rdi, STDERR
	lea rsi, errorMsg
	mov rdx, errorMsgLen
	syscall
	// set the exit code to EXIT_FAILURE
	mov r8, EXIT_FAILURE

end:
	mov rax, SYSEXIT
	mov rdi, r8
	syscall
