# CS 21 LAB 1 -- S2 AY 2021-2022
# Jaimielle Kyle C. Calderon -- 03/01/2022
# 202005499_4.asm -- Sudoku Solver (4x4 grid)

# java -jar Mars45.jar sm nc 202005499_4.asm < test.txt

.eqv S 4

.macro do_syscall(%n)
	li 	$v0, %n
	syscall
.end_macro

.macro input_line(%buffer)
	la 	$a0, %buffer		# Store here
	li 	$a1, 6
	do_syscall(8)			# Read string input		
.end_macro

.macro convert_int(%n)
	lb 	$t0, buffer1(%n)	
	subu	$t0, $t0, 48		# Subtract 48 from ASCII value to convert to int digit
	sb	$t0, buffer1(%n)	# Store the int
.end_macro

.macro printgrid(%n)
	lb	$a0, buffer1(%n)
	do_syscall(1)			# Print int
.end_macro

.text
main:
	input_line(buffer1)	
	input_line(buffer2)
	input_line(buffer3)	
	input_line(buffer4)
		
	li 	$s0, 0			# int i = 0
convert:
	li 	$t1, 16			# Max i val for the loop 
	beq 	$s0, $t1, mcont		# Exit for loop when i == 16
	convert_int($s0)		# Convert ascii value to actual int digit
	addi	$s0, $s0, 1		# i++
	j convert	
mcont:	
	li $a0, 0 
	li $a1, 0
	move $s0, $a0
	move $s1, $a1			# Copying the values
	jal solver			# Call the solver
	
	li $s0, 0 			# int i = 0
print:					# This loop will print each line of the solved grid
	beq 	$s0, 4, exit
	li 	$s1,0
print1: 
	beq 	$s1, 4, cprint
	mul	$t0, $s0, 4
	add	$t0, $t0, $s1
	printgrid($t0)
	addi $s1,$s1,1
	j print1
cprint:
	la $a0, enter
	do_syscall(4)
	addi $s0,$s0,1
	j print
exit:	
	do_syscall(10)
	
checker:
	# $a0: r, $a1: c, $a2: x, $v0: retval (0 or 1)
	#####preamble######
	subu $sp, $sp, 20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	#####preamble######
csquare:	
	li 	$t0, 2			# Max i value for the loop (and inner loop)	
	li 	$s0, 0			# int i = 0
	
	rem	$t2, $a0, 2		# r%2
	subu	$t2, $a0, $t2		# r - (r%2)
	
	rem	$t3, $a1, 2		# c%2
	subu	$t3, $a1, $t3		# c - (c%2)
csquare1:	
	# Check square
	beq 	$s0, 2, crow		# Exit for loop when i == 2
	li	$s1, 0			# int j = 0
csquare2: # Inner loop
	beq	$s1, 2, ccsquare1
	
	add	$t6, $s0, $t2		# i + (r - r%2) : row
	add	$t7, $s1, $t3		# j + (c - c%2) : column	
	
	mul	$t4, $t6, S
	add	$t4, $t4, $t7		# index of Grid[i+ (r - r%2)][j+(c - c%2)]
	lb	$t1, buffer1($t4)	# $t1 = Grid[i+ (r - r%2)][j+(c - c%2)]
	beq 	$t1, $a2, ccont0	# if (Grid[i+ (r - r%2)][j+(c - c%2)] == x) return 0
	addi 	$s1, $s1, 1
	j csquare2
ccsquare1:	
	addi	$s0, $s0, 1		# i++
	j csquare1
crow:
	li 	$t0, S			# Max i value for the loop 
	li 	$s0, 0			# int i = 0
crow1:	
	# Check row
	beq 	$s0, $t0, ccol		# Exit for loop when i == S
	mul	$t2, $a0, S
	add	$t2, $t2, $s0		# 4*r + i : index of Grid[r][i]
	lb	$t1, buffer1($t2)	# $t1 = Grid[r][i]
	beq 	$t1, $a2, ccont0	# if (Grid[r][i] == x) return 0
	addi	$s0, $s0, 1		# i++
	j crow1
ccol:
	li 	$t0, S			# Max i value for the loop
	li 	$s0, 0			# int i = 0
ccol1:	
	# Check column
	beq 	$s0, $t0, ccont1	# Exit for loop when i == S
	mul	$t2, $s0, 4
	add	$t2, $t2, $a1		# 4*i + c : index of Grid[i][c] 
	lb	$t1, buffer1($t2)	# $t1 = Grid[i][c]
	beq 	$t1, $a2, ccont0	# if (Grid[i][c] == x) return 0
	addi	$s0, $s0, 1		# i++
	j ccol1
ccont0:
	li $v0, 0			# Return 0
	j checker_end
ccont1:
	li $v0, 1			# Return 1
	j checker_end
checker_end:
	#####end######
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addu $sp, $sp, 20
	#####end######
	jr $ra
	
	
solver:
	# $a0: r, $a1: c
	#####preamble######
	subu $sp, $sp, 20
	sw $ra, 0($sp)
	sw $s0, 4($sp)			# Save $a0 
	sw $s1, 8($sp)			# Save $a1 
	sw $s2, 12($sp)			# Save x
	#####preamble######
	
	seq 	$t0, $a0, 3		# r == S-1
	seq	$t1, $a1, S		# c == S
	and	$t0, $t0, $t1		# r == S-1 && c == S
	beq	$t0, 1, solver_bc1	# if (r == S-1 && c == S) return 1
	
	bne  	$a1, S, csolver		# if c == S go to next row
	li	$a1, 0			# c = 0
	addi	$a0, $a0, 1		# r = r+1
	sw $a0, 4($sp)			# Save $a0 
	sw $a1, 8($sp)			# Save $a1 				
csolver:
	mul	$t0, $a0, 4	
	add 	$t0, $t0, $a1		# 4*r + c : index of Grid[r][c]
	lb	$t1, buffer1($t0)	# $t1 = Grid[r][c]
	
	beq	$t1, 0, csolver1
	addi	$a1, $a1, 1		# c + 1
	move 	$s0, $a0		# copy r
	move	$s1, $a1		# copy c
	jal solver
	lw 	$a0, 4($sp)		# restore r
	lw	$a1, 8($sp)		# restore c
	beq	$v0, 1, solver_bc1
	beq	$v0, 0, solver_bc0
csolver1:		
	li	$s2, 1			# $s2 : int x = 1
solverloop:
	beq 	$s2, 5 , solver_bc0	# Exit loop when x>S
ifvalid:
	move 	$s0, $a0		# copy r
	move	$s1, $a1		# copy c
	move	$a2, $s2		# $a2 : x
	jal checker
	move 	$a0, $s0		# restore r
	move	$a1, $s1		# restore c
	#s2 still contains x
	bne	$v0, 1, elsenotvalid	# if (Checker(Grid,r,c,x)!=1) go to Grid[r][c] = 0;
ifinner:
	mul	$t0, $a0, 4	
	add 	$t0, $t0, $a1		# 4*r + c : index of Grid[r][c]
	move	$t1, $s2		# $t1 = x
	sb	$t1, buffer1($t0)	# $t1 = Grid[r][c] = x
	
	addi	$a1, $a1, 1		# c + 1
	move 	$s0, $a0		# copy r
	move	$s1, $a1		# copy c
	jal solver
	lw 	$a0, 4($sp)		# restore r
	lw	$a1, 8($sp)		# restore c
	#$s2 still contains x
	#if (Solver(Grid,r,c+1)==1) return 1;
	beq	$v0, 1, solver_bc1	# if (Solver(Grid,r,c+1)==1) return 1
elseinner:
	mul	$t0, $a0, 4	
	add 	$t0, $t0, $a1		# 4*r + c : index of Grid[r][c]
	li	$t1, 0			# $t1 = 0
	sb	$t1, buffer1($t0)	# $t1 = Grid[r][c] = 0 
	j solverloopcont
elsenotvalid:

	mul	$t0, $a0, 4	
	add 	$t0, $t0, $a1		# 4*r + c : index of Grid[r][c]
	li	$t1, 0			# $t1 = 0
	sb	$t1, buffer1($t0)	# $t1 = Grid[r][c] = 0 
	j solverloopcont
solverloopcont:	
	addi	$s2, $s2, 1		# x++
	j solverloop
solver_bc0:
	li	$v0, 0			# Return 0
	j solve_end
solver_bc1:
	li	$v0, 1
	j solve_end			# Return 1
solve_end:
	#####end######
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addu $sp, $sp, 20
	#####end######
	jr $ra
	


.data
buffer1: .space S
buffer2: .space S
buffer3: .space S
buffer4: .space S
newlinebuffer:.space 4
enter: 		.asciiz "\n"
