%include "includes/io.inc"

extern getAST
extern freeAST

section .bss
    ; At this address it's stored the root of the tree
    root: resd 1
   
section .data
    array times 1000 dq 0	; array used for storing the expression
    contor: dd 0 		; iterator variable used to traverse 'array'
section .text

;;-------------------------------------------------------
; check if the received argument is operand or operator
; the result is passed through the edx register (contains 1-> operand, 0-> operator)
check_if_operator: 
    push ebp
    mov ebp, esp
    
    xor edx, edx
    mov ebx, [ebp+8] 
    cmp ebx, "+"
    je operatorul
    cmp ebx, "-"
    je operatorul
    cmp ebx, "/"
    je operatorul
    cmp ebx, "*"
    je operatorul
operandul:
    mov edx, 0x01 		; received an operand as a parameter
    leave 
    ret    
operatorul:
    mov edx, dword 0x00 	; received an operator as a parameter
    leave 
    ret
    
;;;;;------------------------------------------------------   
preordine:
    push ebp
    mov ebp, esp
    xor edx, edx
    mov esi, 10
    lea eax, [ebp+8] 		; the argument received on call - the root of the tree
    mov eax, [eax]
    test eax, eax
    jne afisare
    jmp exit_preordine
    xor edi, edi
afisare:
    xor edi, edi
    mov eax, [ebp+8]
    mov eax, [eax] 
atoi:
     movzx ebx, byte [eax] 	; put in ebx one by one the characters in the string
     ; go through the string byte by byte, check if reached the end of the string
     cmp ebx, 0x00  		; reached end of string
     je out_conversie
     cmp ebx, '-'   		; negative number or minus operator
     je atribuie_negativ
     ; edx will also be used in check_if_operator -> save it on stack
     push edx 	     		; save on stack edx = result on conversion
     push dword ebx
     call check_if_operator
     add esp,4
     ; the result is stored in edx
     cmp edx, 0x01   		; operand
     pop edx
     je continua_parcurgerea
     jne char_operator
atribuie_negativ:    		; put in edi 255 -> mark as negative number
     push eax
     mov eax, [eax]  		; check if '-' marks negative number or is operator
     cmp eax, '-'	
     je char_operator
     pop eax
     mov edi, 255
     inc eax
     jmp atoi
continua_parcurgerea:
    inc eax
    sub ebx, 48   		; the character retained in ebx is 'converted' to integer
    push eax
    mov eax, edx
    mul esi 	  		; multiply by 10 the current result
    add eax, ebx  		; add the current figure to the result (din ebx)
    mov edx, eax  		; retain result in edx
    pop eax
    jmp atoi ; resumes operations until an invalid character (or string terminator) is encountered
out_conversie: 
    cmp edi, 255
    je numar_negativ  		; first character was '-' -> negative number
    jne finally_outt
numar_negativ:
    neg edx 			; negate the obtained result
    mov eax, edx
    jmp finally_outt
char_operator:  
    mov edx, ebx
finally_outt:  			; add to 'array' the operator/operand
    mov ecx, dword [contor]
    mov [array+ecx*4], edx 	; edx retains result of conversion
    add dword [contor],1
    ; recursive call for left subtree
    lea eax, [ebp+8]
    mov eax, [eax]
    mov eax, [eax+4]
    push eax
    call preordine
    sub esp,4
    ; recursive call for right subtree
    lea eax, [ebp+8]
    mov eax, [eax]
    mov eax, [eax+8]
    mov [esp], eax
    call preordine
    sub esp,4
exit_preordine:
    leave 
    ret    
    
; go through the expression and memorize the final result in eax
evaluare_expresie:
    push ebp
    mov ebp, esp
    xor edx, edx
    xor eax, eax 
    mov ecx, [contor]
calcul_expresie:
    ; move through array in inverse order, from right to left
    mov eax, [array+4*(ecx-1)]
    ; eax contains element from array
    mov ebx, eax
    push eax 
    call check_if_operator
    add esp, 4
    mov eax, ebx
    cmp edx, 0x01 		; edx contains 1 --> eax is operand
    je operand
    jne operator
operand: 			; if current element is operand, then put on stack
    push eax
    jmp efect_calcul
operator: 
    ; get 2 operands from stack
    pop esi
    pop edi
    ; choose operation based on current operator
    ; then put the result on stack
    cmp eax, "+"
    je suma
    cmp eax, "-"
    je diferenta
    cmp eax, "/"
    je impartire
    cmp eax, "*"
    je produs  
suma:
    add esi, edi
    push esi
    jmp efect_calcul
diferenta:
    sub esi,edi
    push esi
    jmp efect_calcul
impartire:
    mov ebx, eax  		; save in 'ebx' the value of 'eax'
    xor edx, edx
    mov eax, esi
cu_idiv:
    cdq 			; extension of sign in edx:eax
    idiv edi 
    jmp stiva
stiva:
    push eax 			; put on stack the quotient of division
    mov eax, ebx 		; get back the value of eax saved in ebx
    jmp efect_calcul
produs: 
    mov ebx, eax
    mov eax, edi
    imul esi
    push eax 			; put result of multiplication on stack   
    mov eax, ebx   
efect_calcul:
    cmp ecx, 1  		; check if first array element is reached
    je exit_calcul
    dec ecx
    jmp calcul_expresie                                                                
exit_calcul:
    pop eax 			; result is the last number pushed to stack
    PRINT_DEC 4, eax
    leave
    ret                    
;--------------------------------------------------------    
global main
main:
    mov ebp, esp
    push ebp
    mov ebp, esp
    
    ; read tree
    call getAST ; result in eax
    mov [root], eax
 
;--------------------------------------------------------
 
    push dword [root]
    call preordine 		; recursive function in which the tree is stored in an array
    add esp, 4
  
;--------------------------------------------------------  

    ; use stack to evaluate expresion
    call evaluare_expresie
   
exit:  
    ; free tree memory
    push dword [root]
    call freeAST
    
    xor eax, eax
    leave
    ret