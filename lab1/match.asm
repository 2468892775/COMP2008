.data
    str1: .string "206532021220513" #str1:   .string "1qab9a0bcabcds13"
    str2: .string "0221" #str2:   .string "bcds"
.text
MAIN:
	lui s2 0x10010
	addi s3,s2,17
	addi s4,x0,16
	addi s5,x0,4
	jal ra,FUN
	ori a7,zero,1
	ecall
	addi a7,x0,10
	ecall
	
	
FUN:
	addi sp,sp,-20
	sw s6,16(sp) #len2-1
	sw s5,12(sp) #len2
	sw s4,8(sp) #len1 
	sw s3,4(sp) #pat
	sw s2,0(sp)
	addi a0,x0,-1 #pos=-1
	add a6,a0,x0 #-1
	add a1,x0,x0 #i=0
	jal x0,loop1.0
loop1.0:
	bge a1,s4,EXIT #i >= len1
	add a2,x0,x0 #j=0
	jal x0,loop2.0
loop1.1:
	bne a0,a6,EXIT #pos != -1
	addi a1,a1,1
	beq x0,x0,loop1.0
loop2.0:
	bge a2,s5,EXIT #j>=len2
	add a3,a1,a2 #i+j
	add a4,s2,a3 #str
	add a5,s3,a2 #pat
	lb t0,0(a4)
	lb t1,0(a5)
	bne t0,t1,loop1.1 #str[i+j]!=pattern[j]
	addi s6,s5,-1
	beq a2,s6,loop2.1 #j==len2-1
	addi a2,a2,1
	beq x0,x0,loop2.0
loop2.1:
	add a0,a1,x0 #pos = i
	jal x0,loop1.1
EXIT:
	lw s2,0(sp)
	lw s3,4(sp)
	lw s4,8(sp)
	lw s5,12(sp)
	lw s6,16(sp)
	addi sp,sp,20
	jalr x0,0(ra)
	

	

	
