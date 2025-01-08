.data 0
data:	.word	0x00000001,0x00000002, 0x00000003,0x00000004,0x00000005
hello:  .asciiz "hello"

.text 0
main0000:	
	addi $5, $0, 5
	addi $4, $zero, 256
	add $8, $zero, $zero		# sum function entry
loop:	lw $9, 0($4)		# load data
	add $8, $8, $9		# sums
	addi $5, $5, -1		# counter - 1
	addi $4, $4, 4		# address + 4
	slt $3, $0, $5		# finish?
	bne $3, $0, loop	# finish?
	or $2, $8, $0		# move result to $v0
	sw $2, 0($4)
	j main0000		# return
	syscall

