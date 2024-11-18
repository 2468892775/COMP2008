.data
	str1: .space 100
	str2: .space 100
.text
MAIN:
	lui a0, 0x10010
	addi a1,x0,100
	addi a7,x0,8
	ecall
	
	addi a0,a0,100
	addi a1,x0,100
	addi a7,x0,8
	ecall
	
	lui s2,0x10010	

	#lb t4 100(s2)
	addi a1,x0,0
	addi a2,x0,0
	jal ra,calc1 #计算母串长度
	addi s4,s4,-1
	addi s3,s2,100
	jal ra,calc2 #计算子串长度
	addi s5,s5,-1
	jal ra,FUN
	addi a7,x0,10
	ecall
	
calc1:
	addi sp,sp,-4
	sw s2,0(sp)
	jal x0,calc_loop1
calc_loop1:
	lbu a3,0(s2)
	beq a3,x0,calc_done1
	addi a1,a1,1
	addi s2,s2,1
	beq x0,x0,calc_loop1
calc_done1:
	addi s4,a1,0
	lw s2,0(sp)
	addi sp,sp,4
	jalr x0,0(ra)
calc2:
	addi sp,sp,-4
	sw s3,0(sp)
	jal x0,calc_loop2
calc_loop2:
	lbu a4,0(s3)
	beq a4,x0,calc_done2
	addi a2,a2,1
	addi s3,s3,1
	beq x0,x0,calc_loop2
calc_done2:
	addi s5,a2,0
	lw s3,0(sp)
	addi sp,sp,4
	jalr x0,0(ra)
	
FUN:
	addi sp,sp,-20
	sw s6,16(sp) #len2-1
	sw s5,12(sp) #len2
	sw s4,8(sp) #len1 
	sw s3,4(sp) #pat
	sw s2,0(sp) #str
	addi a0,x0,-1 #pos=-1
	add a6,a0,x0 #-1
	add a1,x0,x0 #i=0
	jal x0,loop1.0
loop1.0:
	bge a1,s4,EXIT #i >= len1
	add a2,x0,x0 #j=0
	jal x0,loop2.0
loop1.1:
	bne a0,a6,match #pos != -1
	addi a1,a1,1
	beq x0,x0,loop1.0
loop2.0:
	bge a2,s5,EXIT #j>=len2
	add a3,a1,a2 #i+j
	add a4,s2,a3 #str[i+j]
	add a5,s3,a2 #pat[j]
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
match:
	addi a7,zero,1
	ecall
	add t5,a0,x0# 暂存pos
	addi a0,x0,32#空格
	addi a7,zero,11
	ecall 
	add a0,t5,x0 #还原
	add a6,a0,x0 #重置pos
	addi a1,a1,1 # i++
	ble a1,s4,loop1.0 # i<= len1
	jal x0,EXIT
EXIT:
	lw s2,0(sp)
	lw s3,4(sp)
	lw s4,8(sp)
	lw s5,12(sp)
	lw s6,16(sp)
	addi sp,sp,20
	jalr x0,0(ra)
	

	

	
