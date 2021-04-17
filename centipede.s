#####################################################################
#
# CSC258H Winter 2021 Assembly Final Project
# University of Toronto, St. George
#
# Student: Jordan Wong, 1005824761
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the project handout for descriptions of the milestones)
# - Milestone 1/2/3/4 (choose the one the applies)
#
# Which approved additional features have been implemented?
# (See the project handout for the list of additional features)
# 1. Centipede segments turn into mushrooms and break if shot between head and tail
# 2. Blast mushroom 4 times to destroy it
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

.data
	displayAddress:	.word 0x10008000
	backgroundColor: .word 0x000000
	
	bugLocation: .word 943
	bugColor: .word 0x9400d3
	
	centipedeLocation: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
	centipedeDirection: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	numCentipede: .word 10
	centipedeColor: .word 0x7fff00
	
	headColor: .word 0xff4500
	headLocation: .space 40
	numHeads: .word 1
	
	mushroomColor: .word 0xb8860b
	mushroomLocation: .space 400
	numMushrooms: .word 10
	numMushroomHits: .space 400
	
	blasterLocation: .space 64
	numBlaster: .word 0
	
	fleaLocation: .space 16		
	numFlea: .word 0	
	fleaColor: .word 0xffe4b5
	
	gameStart: .word 0
	
	gameOver: .word 0
	
	
.text 
main:
	jal check_keystroke	# check for S keystroke to start game
	
	j main
	
START:
	jal draw_bg
	jal init_mushroom
	addi $t0, $zero, 0
	sw $t0, numBlaster
	sw $t0, numFlea
	
LEVEL_START:
	jal init_cent
	jal init_cent_head

Loop:
	jal clear_centipede
	jal clear_blaster
	jal clear_flea
	jal check_keystroke
	jal update_centipede
	jal update_blasters
	jal cent_dead
	jal spawn_flea
	jal update_flea
	jal disp_centipede
	jal disp_blasters
	jal disp_mushroom
	jal disp_flea
	jal sleep

	j Loop	

Exit:
	addi $t1, $zero, 0
	sw $t1, gameStart
	
	jal GG
	
	j main
	
	li $v0, 10		# terminate the program gracefully
	syscall

# function to initialize Centipede
init_cent:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $t0, $zero, 10
	sw $t0, numCentipede
	la $a1, centipedeLocation
	la $a2, centipedeDirection
	addi $t2, $zero, 0
	addi $t1, $zero, 1
	
	init_cent_loop:
		sw $t1, 0($a2)
	
			
		sw $t2, 0($a1)
	
		addi $a1, $a1, 4
		addi $a2, $a2, 4
		addi $t0, $t0, -1
		addi $t2, $t2, 1
	
		bne $t0, $zero, init_cent_loop
		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to see if centipede is dead, if dead respawns centipede
cent_dead:
	lw $t0, numCentipede
	
	beq $t0, $zero, LEVEL_START
	
	jr $ra


# function to display Centipede
disp_centipede:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a3, numCentipede	 # load a3 with number of Centipede
	la $a1, centipedeLocation # load the address of the array into $a1
	la $a2, headLocation 	# loads address of head location into a0

	arr_loop:	#iterate over the loops elements to draw each body in the centipede
		lw $t1, 0($a1)		 # load a word from the centipedeLocation array into $t1

		lw $t2, displayAddress  # $t2 stores the base address for display
		lw $t3, centipedeColor	# $t3 stores the centipede Color
	
		sll $t4, $t1, 2		# $t4 is the bias of the old body location in memory (offset*4)
		add $t4, $t2, $t4	# $t4 is the address of the old bug location
		sw $t3, 0($t4)		# draw the centipede
	
		addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
		addi $a3, $a3, -1	 # decrement $a3 by 1
		bne $a3, $zero, arr_loop
	
		lw $a3, numHeads	# loads number of heads
	head_loop:
		lw $t1, 0($a2)		# t1 -> head location
		lw $t5, headColor	
	
		sll $t4, $t1, 2
		add $t4, $t2, $t4
		sw $t5, 0($t4) 		# draw centipede head
	
		addi $a2, $a2, 4
		addi $a3, $a3, -1
		bne $a3, $zero, head_loop
	
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

	
# function that moves centipede
# uses a1, a2, a3, t0, t1, t2, t3, t4, t5, t7, t8, t9, s0
update_centipede:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $a1, centipedeLocation	# stores address for centipedeLocation
	la $a2, centipedeDirection	# stores address for centipedeDirection
	lw $a3, numCentipede		# loads a3 with num Centipede
	
	centipede_loop:
		la $t8, headLocation		# stores address for HeadLocation
		lw $t0, displayAddress
		lw $t1, centipedeColor
	
		lw $t2, 0($a1)			# t2 -> centipede location
		lw $t3, 0($a2)			# t3 -> centipede direction
	
		lw $t7, numHeads
		addi $s0, $zero, 0		# resets s0
	
	check_heads_loop:
		lw $t9, 0($t8)		# t9 -> head location
	
		bne $t2, $t9, NEXT_HEAD_CHECK
		addi $s0, $zero, 1	# stores 1 in s0
		j HEAD_CHECK_DONE
	
	NEXT_HEAD_CHECK:
		addi $t8, $t8, 4
		addi $t7, $t7, -1
		bne $t7, $zero, check_heads_loop
	
	HEAD_CHECK_DONE:

		addi $t4, $zero, 1
	
		beq $t3, $t4, RIGHT	# checks if direction is to the right
		addi $t2, $t2, -1	# moves centipede to the left
		j END
	RIGHT:
		addi $t2, $t2, 1	# moves centipede to the right
	END:	
		addi $sp, $sp, -4
		sw $t3, 0($sp)		# pushes direction onto stack
	
		addi $sp, $sp, -4
		sw $t2, 0($sp)		# pushes new location onto stack
	
		jal check_cent_collision	
	
		lw $t2, 0($sp)		# gets location back from stack
		addi $sp, $sp, 4
	
		bne $v1, 1, NO_COLLISION	# checks if there was a collision
		lw $t2, 0($a1)		# gets original location of centipede
		addi $t5, $zero, 960
		bge $t2, $t5, BOTTOM
		addi $t2, $t2, 32	# moves the centipede down one level
		j FLIP
	
	BOTTOM:
		addi $t2, $t2, -32 	# moves cent up one level
	
	FLIP:
		addi $t4, $zero, -1
		lw $t3, 0($a2)		# gets direction of centipede
		mult $t3, $t4		# flips direction of centipede
		mflo $t3		# stores new direction in t3
	
		sw $t3, 0($a2)		# stores new direction into array
	
	NO_COLLISION:
		sw $t2, 0($a1)		# stores new centipede location
	
		addi $t7, $zero, 1
		bne $s0, $t7, NEXT_CENT
		sw $t2, 0($t8)
	
	NEXT_CENT:	
		addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
		addi $a2, $a2, 4
		addi $a3, $a3, -1	 # decrement $a3 by 1
		bne $a3, $zero, centipede_loop
	

	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4	 	
	jr $ra


# function to check two pixels for collision
# rewrites a0, t2, t3, t4, t5, v1
check_cent_collision:
	lw $a0, 0($sp)		# gets pixel off stack
	addi $sp, $sp, 4
	
	lw $t5, 0($sp)		# gets direction off stack
	addi $sp, $sp, 4
	
	la $t2, mushroomLocation	# gets mushroom locations
	
	lw $t3, numMushrooms		# gets num mushrooms
	
	addi $v1, $zero, 0		# resets value of v1 to 0
	
	#check if centipede collides with bug
	lw $t9, bugLocation
	bne $t9, $a0, check_collision_loop_mushroom
	j Exit
	
	check_collision_loop_mushroom:		# checks for collisions against mushrooms
		lw $t4, 0($t2)		# gets mushroom location
	
		bne $t4, $a0, END_MUSHROOM_LOOP

	#mushroom collision	
		addi $v1, $zero, 1	# stores 1 in v1
		j RETURN
	
	END_MUSHROOM_LOOP:
		addi $t2, $t2, 4	# gets next mushroom in array
		addi $t3, $t3, -1 	# decrement t3 by 1
		bne $t3, $zero, check_collision_loop_mushroom
	
	#check centipede hit edge of screen	
		addi $t4, $zero, 32
	
		div $a0, $t4		# divides location by 32
		mfhi $t3		# stores remainder in t3
		
		addi $t2, $zero, 1 	# stores left direction
	
		bne $t3, $zero, LEFT_EDGE	# checks if location is on right edge of screen and if cent is  moving right
		bne $t5, $t2, LEFT_EDGE

	#left edge
		addi $v1, $zero, 1
		j RETURN

	LEFT_EDGE:
		addi $t2, $zero, 31		# checks if location is on left edge of screen and if cent is moving left
		bne $t3, $t2, RETURN
		addi $t2, $zero, -1
		bne $t5, $t2, RETURN
	
		addi $v1, $zero, 1	# stores 1 in v1

	RETURN:
		addi $sp, $sp, -4
		sw $a0, 0($sp)		# stores pixel back on stack
		jr $ra

# function to clear old Centipede
clear_centipede:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a3, numCentipede	# load numCentipede
	la $a1, centipedeLocation # load the address of the array into $a1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t6, backgroundColor  #$t6 stores background Color

	clear_cent_loop:	#iterate over the loops elements to erase each old centipede body
		lw $t1, 0($a1)		 # load a word from the centipedeLocation array into $t1
		
		sll $t4, $t1, 2		# $t4 is the bias of the old body location in memory (offset*4)
		add $t4, $t2, $t4	# $t4 is the address of the old bug location
		sw $t6, 0($t4)		# erase the centipede
	
		addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
		addi $a3, $a3, -1	 # decrement $a3 by 1
		bne $a3, $zero, clear_cent_loop
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# initialize cent head
init_cent_head:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $a1, headLocation
	addi $t1, $zero, 9	# puts 1 head at beginning location
	
	sw $t1, 0($a1)		# stores head position into array
	
	addi $t1, $zero, 1
	sw $t1, numHeads
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# removes one centipede body and corresponding value in direction
# uses, a2, t0, t1, t3, t4, t6, t7, t8
kill_centipede:
	la $t8, centipedeDirection	# loads address of centipedeDirection -> t8
	lw $t7, numCentipede		# numCentipede -> t7
	
	# gets to index of centipedeDirection that matches the centipede body
	MATCH_CENT_DIRECTION:
		beq $t7, $t0, MATCHED
		
		addi $t8, $t8, 4	# gets next direction
		addi $t7, $t7, -1	# decrements t7
		
		j MATCH_CENT_DIRECTION
		
	MATCHED:
		addi $sp, $sp, -4
		sw $t8, 0($sp)		# stores pointer to centipede direction
		
	addi $t6, $zero, 1
	beq $t0, $t6, DECREASE_NUM_CENT	# if the centipede killed is the head, just decrement numCentipede
	 
	DELETE_CENTIPEDE:
		add $t1, $zero, $a2	# stores current location in array -> t1
		addi $a2, $a2, 4	# gets next centipede
		addi $t0, $t0, -1 	# decrements t0
	
		lw $t3, 0($a2)		# gets the location of next centipede
		sw $t3, 0($t1)		# stores next location in current location, erasing current location and shrinking array
		
		add $t7, $zero, $t8	# stores current location of centipede directino array -> t7
		addi $t8, $t8, 4	# gets next direction
		
		lw $t6, 0($t8)		# gets direction of next centipede
		sw $t6, 0($t7)		# stores next direction in current direction
		
		addi $t4, $zero, 1
	
		bne $t0, $t4, DELETE_CENTIPEDE
	
	DECREASE_NUM_CENT:
		lw $t0, numCentipede
		addi $t0, $t0, -1 	# decrement num centipede by 1
		sw $t0, numCentipede	# store new value in numCentiped

	jr $ra

########################################################################################## Mushroom code ############################################################################
# function that displays mushrooms
disp_mushroom:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t6, displayAddress		# stores base address of display
	la $a2, mushroomLocation	# loads address of mushrooms
	lw $a3, numMushrooms		# loads a3 with num mushrooms
	lw $t1, mushroomColor		# stores mushroom color in $t1
	
	mush_loop:
		lw $t2, 0($a2)			# loads mushroom location into $t2
	
		sll $t2, $t2, 2			# shifts $t5 by 2 
		add $t2, $t2, $t6		# gets address of mushroom location
		sw $t1, 0($t2)			# draws mushroom
	
		addi $a2, $a2, 4	# increment a2 by one to get next element
		addi $a3, $a3, -1	 # decrement $a3 by 1
		bne $a3, $zero, mush_loop
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
	
init_mushroom:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $a2, mushroomLocation	# loads address of mushrooms
	lw $a3, numMushrooms		# loads a3 with num Mushrooms
	la $t9, numMushroomHits		# loads address of mushroomHits
	
	mush_init_loop:
		jal get_mushroom_height		
		blez $a0, mush_init_loop	# if mushroom height is on first row, get new value
		
		add $t3, $a0, $zero		# stores height in $t3
	
		addi $t5, $zero, 32
		mult $t3, $t5
		mflo $t3			# stores height for bitarray
	
		jal get_random_width
		add $t4, $a0, $zero		# stores width in $t4
	
		add $t5, $t3, $t4		# gets bit location of mushroom
		sw $t5, 0($a2)			# stores new location in array
		sw $zero, 0($t9)		# stores 0 in mushroomHits 
	
		addi $a2, $a2, 4	# increment a2 by one to get next element
		addi $t9, $t9, 4	# go to next location of mushroomHits
		addi $a3, $a3, -1	 # decrement $a3 by 1
		bne $a3, $zero, mush_init_loop
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
	
######################################################################################################## keyboard input ####################################################

# function to detect any keystroke
check_keystroke:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to get the input key
get_keyboard_input:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0	#default case
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	beq $t2, 0x78, respond_to_x
	beq $t2, 0x73, respond_to_s
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t9, gameStart
	addi $t8, $zero, 0
	
	beq $t9, $t8, SKIP
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t3, backgroundColor	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# erase bug from old location
	
	beq $t1, 928, skip_movement # prevent the bug from getting out of the canvas
	addi $t1, $t1, -1	# move the bug one location to the right

skip_movement:
	sw $t1, 0($t0)		# save the bug location

	lw $t3, bugColor	# $t3 stores the bug color
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the first (top-left) unit.
	
	
SKIP:
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of k key
respond_to_k:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t9, gameStart
	addi $t8, $zero, 0
	
	beq $t9, $t8, SKIP2
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the block with black
	
	beq $t1, 959, skip_movement2 #prevent the bug from getting out of the canvas
	addi $t1, $t1, 1	# move the bug one location to the right

skip_movement2:
	sw $t1, 0($t0)		# save the bug location

	lw $t3, bugColor	# $t3 stores the bug color 
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the bug
	
	
SKIP2:
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_x:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t9, numBlaster
	addi $t8, $zero, 16	# max number of blasters + 1
	
	beq $t9, $t8, FULL	# if numBlasters is already maxed, do nothing
	
	addi $t9, $t9, 1	# adds 1 blaster to the array
	sw $t9, numBlaster
	
	la $t0, bugLocation 	# loads address of bugLocation
	lw $t1, 0($t0)		# t1 -> bug location
	
	addi $t1, $t1, -32	# moves location up one row
	
	la $t4, blasterLocation # loads address of blasterLocation
	
	addi $t8, $zero, 1	# stores 1 in t8
	
	END_OF_ARRAY:
		beq $t9, $t8, NEW_BLASTER	# if num blasters = 1 then store the new blaster
		addi $t4, $t4, 4	# increments $t4 to next space
		addi $t9, $t9, -1
		j END_OF_ARRAY
	
	NEW_BLASTER:	
		sw $t1, 0($t4)		# stores the new blaster location in the array
	
	FULL:	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_s:
	lw $ra, 0($sp) 		# removes get_keyboard_input return address
	addi $sp, $sp, 4
	
	lw $ra, 0($sp)		# removes check_input return address
	addi $sp, $sp, 4
	
	addi $t9, $zero, 1
	sw $t9, gameStart

	j START

############################################################################################## Blaster Logic ########################################################################

# Displays all blaster shots
disp_blasters:
	addi $sp, $sp, -4	# stores $ra
	sw $ra, 0($sp)
	
	lw $a3, numBlaster	# loads number of blasters
	la $a1, blasterLocation # load the address of the array into $a1
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0xFFFFFF	# stores white in t3

	disp_blaster_loop:

		beq $a3, $zero, done_disp_blaster 	
	
		lw $t1, 0($a1)		 # load a word from the blasterLocation array into $t1
		sll $t4, $t1, 2		# $t4 is the bias of the old blaster location in memory (offset*4)
		add $t4, $t2, $t4	# $t4 is the address of the old blaster location
		sw $t3, 0($t4)		# draw the blaster
	
		addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
		addi $a3, $a3, -1	 # decrement $a3 by 1
		j disp_blaster_loop	
	
	done_disp_blaster:
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# updates blaster locations
update_blasters:
	addi $sp, $sp, -4	# stores $ra
	sw $ra, 0($sp)
	
	lw $a3, numBlaster	# loads number of blasters
	la $a1, blasterLocation # load the address of the array into $a1
	
	beq $a3, $zero, RETURN_UPDATE_BLASTERS
	
	blasters_loop:
		lw $t1, 0($a1) 		# loads one blaster location into t1
		addi $t2, $t1, -32	# moves blaster up one row
		
		addi $sp, $sp, -4
		sw $a3, 0($sp)		# stores current num Blaster onto stack
		
		addi $sp, $sp, -4
		sw $a1, 0($sp)		# stores current index of array on stack
	
		addi $sp, $sp, -4	
		sw $t2, 0($sp)		# stores new blaster location on stack
	
		jal check_blaster_collision
	
		lw $t2, 0($sp)		# gets new blaster location back from stack
		addi $sp, $sp, 4
		
		lw $a1, 0($sp)
		addi $sp, $sp, 4	# gets curr index of array back from stack
		
		lw $a3, 0($sp)		# gets num Blaster back from stack
		addi $sp, $sp, 4
	
		beq $v0, $zero, next_blaster
		
		
	delete_blaster:
			add $t1, $zero, $a1	# stores current location in array -> t1
			addi $a1, $a1, 4	# gets next blaster
			addi $a3, $a3, -1 	# decrements a3
	
			lw $t3, 0($a1)		# gets the location of next blaster
			sw $t3, 0($t1)		# stores next location in current location, erasing current location and shrinking array
			
			bne $a3, $zero, delete_blaster
	
			dec_numBlaster:
				lw $a3, numBlaster
				addi $a3, $a3, -1 	# decrement num blaster by 1
				sw $a3, numBlaster	# store new value in numBlaster
	
				j RETURN_UPDATE_BLASTERS
	
	
	next_blaster:
		sw $t2, 0($a1)
		addi $a1, $a1, 4	# gets next element in blasterLocation
		addi $a3, $a3, -1	# decrements numBlasters
	
		bne $a3, $zero, blasters_loop

	RETURN_UPDATE_BLASTERS:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
	
	
# checks if blaster collided with any object
# uses: a1, a2, a3, t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, v0
check_blaster_collision:
	lw $t2, 0($sp)		# gets new blaster location off stack
	addi $sp, $sp, 4
	
	addi $sp, $sp, -4
	sw $t2, 0($sp)		# stores new blaster location back on stack
	
	addi $sp, $sp, -4	# stores $ra
	sw $ra, 0($sp)

	la $t8, centipedeDirection	# load address of centipedeDirection -> t8
	la $a1, headLocation		# load address of head locations -> a1
	la $a2, centipedeLocation	# load address of centipede location -> a2
	la $a3, mushroomLocation 	# load address of mushroom location -> a3
	
	addi $v0, $zero, 0		# default case	-> no collisions
	
	lw $t0, numMushrooms		# loads numMushrooms -> t0
	la $t9, numMushroomHits		# loads array for mushroom hits -> t9
	
############################## checks if blaster hit mushroom
	
	check_blaster_mushroom_collision:
		lw $t1, 0($a3)		# loads location of mushroom
		
		bne $t1, $t2, ITERATE_MUSHROOM_LOOP

	# mushroom collision	
		addi $v0, $zero, 1	# returns 1 to show collision with mushroom
		
		lw $t7, 0($t9)		# loads num times this mushroom has been hit
		addi $t7, $t7, 1	# add 1 to num times this mushroom has been hit
		
		addi $t6, $zero, 4	# t6 = 4
		
		beq $t7, $t6, DELETE_MUSHROOM
		
		sw $t7, 0($t9)		# store updated times mushroom has been hit in array
		
		j RETURN_CHECK_BLASTER_COLLISION
		
	DELETE_MUSHROOM:
		lw $t6, displayAddress
		lw $t7, backgroundColor
		sll $t1, $t1, 2			# shifts $t1 by 2 
		add $t1, $t1, $t6		# gets address of mushroom location
		sw $t7, 0($t1)			# erases mushroom
		
	DELETE_MUSHROOM_LOOP:	
		add $t1, $zero, $a3	# stores current location in mushroom array -> t1
		add $t3, $zero, $t9	# stores current location in mushroomHit array -> t3
		addi $a3, $a3, 4	# gets next mushroom
		addi $t9, $t9, 4	# gets next mushroomHit
			
		addi $t0, $t0, -1 	# decrements numMushrooms
	
		lw $t4, 0($a3)		# gets the location of next mushroom
		sw $t4, 0($t1)		# stores next location in current location, erasing current location and shrinking array
		lw $t4, 0($t9)		# gets next mushroomHit
		sw $t4, 0($t3)		# stores next mushroomHit in current index, erasing current value and shrinking array
			
		bne $t0, $zero, DELETE_MUSHROOM_LOOP
	
		dec_numMushrooms:
			lw $t0, numMushrooms
			addi $t0, $t0, -1 	# decrement numMushrooms by 1
			sw $t0, numMushrooms	# store new value in numMushrooms
	
			j RETURN_CHECK_BLASTER_COLLISION
	
	ITERATE_MUSHROOM_LOOP:
		addi $a3, $a3, 4	# gets next mushroom in array
		addi $t9, $t9, 4	# gets next index in mushroomHits
		addi $t0, $t0, -1 	# decrement numMushrooms by 1
		bne $t0, $zero, check_blaster_mushroom_collision
	
###################### checks if blaster hits flea		
				
	lw $t0, numFlea			# loads numFlea -> t0
	la $t9, fleaLocation		# loads fleaLocation -> t9
	
	beq $t0, $zero, NO_FLEA_COLLISION
	
	check_blaster_flea_collision:
		lw $t1, 0($t9)		# loads location of flea
		
		beq $t1, $t2, FLEA_COLLISION
		addi $t2, $t2, -32
		bne $t1, $t2, ITERATE_BLASTER_FLEA_LOOP
		
		addi $t2, $t2, 32
		
		
	FLEA_COLLISION:
		addi $v0, $zero, 1	# returns 1 to show collision with mushroom
		
	BLASTER_DELETE_FLEA_LOOP:
		addi $t1, $zero, 1
		beq $t0, $t1, dec_numFlea	# if it hit the last flea, then just decrement numFlea
	
		add $t1, $zero, $t9	# stores current location in flea array -> t1
		addi $t9, $t9, 4	# gets next Flea
			
		addi $t0, $t0, -1 	# decrements numMushrooms
	
		lw $t4, 0($t9)		# gets the location of next flea
		sw $t4, 0($t1)		# stores next location in current location, erasing current location and shrinking array
			
		j BLASTER_DELETE_FLEA_LOOP
	
		dec_numFlea:
			lw $t0, numFlea
			addi $t0, $t0, -1 	# decrement numFlea by 1
			sw $t0, numFlea	# store new value in numMushrooms
	
			j RETURN_CHECK_BLASTER_COLLISION
	
	ITERATE_BLASTER_FLEA_LOOP:
		addi $t9, $t9, 4	# gets next flea
		addi $t0, $t0, -1 	# decrement numFlea by 1
		bne $t0, $zero, check_blaster_flea_collision
		
	NO_FLEA_COLLISION:	
	
#################################### checks if blaster hit centipede	
	
	lw $t0, numCentipede 		# stores num centipede in -> t0
	
	check_blaster_cent_collision:
		lw $t1, 0($a2)			# gets location of centipede
	
		bne $t2, $t1, end_check_blaster_cent_collision
		
		addi $v0, $zero, 1		# returns 1 to show collision with centipede
		
		la $a3, mushroomLocation	# reset address of mushroom Location
		lw $t7, numMushrooms		# loads numMushrooms -> t0
		la $t9, numMushroomHits		# loads array for mushroom hits -> t9
		
	ADD_MUSHROOM:
		beq $t7, $zero, BLASTER_COLLIDE
		
		addi $a3, $a3, 4		# gets next location in array
		addi $t9, $t9, 4		# gets next location in array
		addi $t7, $t7, -1		# decrements numMushrooms
		
		j ADD_MUSHROOM
		
	BLASTER_COLLIDE:
		lw $t7, numMushrooms
		addi $t7, $t7, 1
		sw $t7, numMushrooms		# adds 1 to numMushrooms and stores it
		sw $t2, 0($a3)			# stores blaster location into mushroomLocation
		sw $zero, 0($t9)		# stores 0 for new mushroom Hits
		
	
		addi $sp, $sp, -4
		sw $t0, 0($sp)			# stores curr num index of array on stack
		
		addi $sp, $sp, -4
		sw $a2, 0($sp)			# stores a2 on stack
	
		jal kill_centipede
		
		lw $t8, 0($sp)
		addi $sp, $sp, 4		# gets pointer to centipedeDirection
	
		lw $a2, 0($sp)
		addi $sp, $sp, 4		# gets a2 back from stack
		
		lw $t0, 0($sp)
		addi $sp, $sp, 4		# gets t0 back from stack
		
		
		lw $t9, numHeads		# loads numHeads
		
	check_hit_head:
		lw $t1, 0($a1)			# loads location of head into t1
		
		beq $t1, $t2, DELETE_HEAD_LOOP
		
		addi $t9, $t9, -1
		addi $a1, $a1, 4
		beq $t9, $zero, MISSED_HEAD
		
		j check_hit_head
		
		
	MISSED_HEAD:
		lw $t7, numCentipede		# numCentipede -> t7
		addi $t7, $t7, 1
			
		beq $t0, $t7, RETURN_CHECK_BLASTER_COLLISION	# if blaster hit last centipede body then don't add new head
		
		j ADD_HEAD
		
	DELETE_HEAD_LOOP:
		addi $t5, $zero, 1
		beq $t9, $t5, dec_numHeads
		
		add $t1, $zero, $a1	# stores current location in head array -> t1
		addi $a1, $a1, 4	# gets next head
			
		addi $t9, $t9, -1 	# decrements numHeads
	
		lw $t4, 0($a1)		# gets the location of next head
		sw $t4, 0($t1)		# stores next location in current location, erasing current location and shrinking array
			
		j DELETE_HEAD_LOOP
	
		dec_numHeads:
			lw $t9, numHeads
			addi $t9, $t9, -1		# decreases numHeads
			sw $t9, numHeads

		
	lw $t7, numCentipede		# numCentipede -> t7
	addi $t7, $t7, 1
			
	beq $t0, $t7, RETURN_CHECK_BLASTER_COLLISION	# if blaster hit last centipede body then don't add new head
	
	addi $a2, $a2, -4		
	lw $t1, 0($a2)			# gets previous centipede body location
	
	lw $t9, numHeads	
	la $a1, headLocation
	
	CHECK_IF_ALREADY_HEAD:
		beq $t9, $zero, NOT_HEAD
		lw $t5, 0($a1)		# gets head location
		beq $t5, $t1, RETURN_CHECK_BLASTER_COLLISION	# if the previous centipede body is already a head, don't add a new one
		
		addi $a1, $a1, 4	# gets next  head
		addi $t9, $t9, -1	# decrements numHeads
		
		j CHECK_IF_ALREADY_HEAD
		
	NOT_HEAD:
		addi $a2, $a2, 4
		
	ADD_HEAD:
		addi $a2, $a2, -4		
		lw $t1, 0($a2)			# gets previous centipede body location
		
		lw $t9, numHeads		# resets numHeads value
		addi $t9, $t9, 1		# adds one more head
		sw $t9, numHeads
		
		
		sw $t1, 0($a1)			# stores that as new head
		
		j RETURN_CHECK_BLASTER_COLLISION
		
	
	end_check_blaster_cent_collision:
		addi $a2, $a2, 4		# gets next centipede
		addi $t0, $t0, -1		# decrements num centipedes
		bne $t0, $zero, check_blaster_cent_collision
		
	check_blaster_edge:
		addi $t2, $t2, 32		# gets original blaster location
		addi $t1, $zero, 31
		bge $t2, $t1, RETURN_CHECK_BLASTER_COLLISION	# if location of blaster is > 31 (not in first row) skip
		
		addi $v0, $zero, 1		# returns 1 to show blaster is off the screen

	RETURN_CHECK_BLASTER_COLLISION:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
	
		jr $ra
		
# function to clear old blaster locations
clear_blaster:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a3, numBlaster	# load numBlaster
	la $a1, blasterLocation # load the address of the array into $a1
	
	beq $a3, $zero, cleared_blasters
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t6, backgroundColor  #$t6 stores background Color

	clear_blaster_loop:	#iterate over the loops elements to erase each old blaster location
		lw $t1, 0($a1)		 # load a word from the blasterLocation array into $t1
		
		sll $t4, $t1, 2		# $t4 is the bias of the old blaster location in memory (offset*4)
		add $t4, $t2, $t4	# $t4 is the address of the old blaster location
		sw $t6, 0($t4)		# erase the blaster
	
		addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
		addi $a3, $a3, -1	 # decrement $a3 by 1
		bne $a3, $zero, clear_blaster_loop
	
	cleared_blasters:
		# pop a word off the stack and move the stack pointer
		lw $ra, 0($sp)
		addi $sp, $sp, 4
	
		jr $ra
	
	

	
##################################################################################### Flea Logic ##########################################################################################

# function that has 1/20 chance to spawn a flea
spawn_flea:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $a2, fleaLocation 		# loads fleaLocation into a2
	lw $a3, numFlea			# loads numFlea into a3
	
	jal get_random_number
	
	addi $t9, $zero, 3		
	
	bne $a0, $t9, NO_SPAWN
	
	addi $t9, $zero, 4
	beq $a3, $t9, NO_SPAWN		# if max number fleas are already on the board don't spawn
	
	ADD_FLEA:
		beq $a3, $zero, SPAWN_FLEA
		
		addi $a2, $a2, 4		# gets next index in fleaLocation array
		addi $a3, $a3, -1		# decrements numFlea
		
		j ADD_FLEA
	
	SPAWN_FLEA:
		jal get_random_width
		sw $a0, 0($a2) 			# stores a random horizontal position into the fleaLocation array
		
		lw $a3, numFlea			# resets a3
		addi $a3, $a3, 1		# increments numFlea
		sw $a3, numFlea			# stores new value into numFlea

	NO_SPAWN:
		# pop a word off the stack and move the stack pointer
		lw $ra, 0($sp)
		addi $sp, $sp, 4
			
		jr $ra
		
# function to clear old Flea locations
clear_flea:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a3, numFlea	# load numFlea
	la $a1, fleaLocation # load the address of the array into $a1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t6, backgroundColor  #$t6 stores background Color

	clear_flea_loop:	#iterate over the elements to erase each old flea
		beq $a3, $zero, RETURN_CLEAR_FLEA
	
		lw $t1, 0($a1)		 # load a word from the fleaLocation array into $t1
		
		sll $t4, $t1, 2		# $t4 is the bias of the old location in memory (offset*4)
		add $t4, $t2, $t4	# $t4 is the address of the old location
		sw $t6, 0($t4)		# erase the flea
	
		addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
		addi $a3, $a3, -1	 # decrement $a3 by 1
		
		j clear_flea_loop
		
	RETURN_CLEAR_FLEA:
		# pop a word off the stack and move the stack pointer
		lw $ra, 0($sp)
		addi $sp, $sp, 4
	
		jr $ra
		
# function to display all fleas	
disp_flea:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t6, displayAddress		# stores base address of display
	la $a2, fleaLocation		# loads address of fleas
	lw $a3, numFlea			# loads a3 with num flea
	lw $t1, fleaColor		# stores flea color in $t1
	
	disp_flea_loop:
		beq $a3, $zero, RETURN_DISP_FLEA
		
		lw $t2, 0($a2)			# loads flea location into $t2
	
		sll $t2, $t2, 2			# shifts $t2 by 2 
		add $t2, $t2, $t6		# gets address of flea
		sw $t1, 0($t2)			# draws flea
	
		addi $a2, $a2, 4	 # increment a2 by one to get next element
		addi $a3, $a3, -1	 # decrement $a3 by 1
		
		j disp_flea_loop
	
	RETURN_DISP_FLEA:
		# pop a word off the stack and move the stack pointer
		lw $ra, 0($sp)
		addi $sp, $sp, 4
	
		jr $ra
		
# function to handle movement of flea
# uses a1, t1, t2, t3, t5, t6, t7, t8, t9
update_flea:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $a1, fleaLocation		# loads address of fleas
	lw $t9, numFlea			# loads num Fleas
	
	lw $t8, bugLocation		# loads bug location
	
	update_flea_loop:
		beq $t9, $zero, RETURN_UPDATE_FLEA
		
		lw $t1, 0($a1)		# loads address of flea
		
	check_flea_edge:
		# checks if the flea hits the bottom of the screen
		addi $t7, $zero, 992	# last row of the display
		
		blt $t1, $t7, NOT_FLEA_EDGE
		
		# delete the flea from the array
		add $t5, $zero, $a1	# stores current pointer to array in t5
		add $t6, $zero, $t9	# stores current numFlea in t6
		
		addi $t7, $zero, 1
	delete_flea_loop:
		beq $t9, $t7, dec_num_flea
		
		add $t2, $zero, $a1	# stores current location of array in t2
		addi $a1, $a1, 4	# gets next element in array
		
		lw $t3, 0($a1)		# gets next value in array
		sw $t3, 0($t2)		# stores next value in current location in array
		
		addi $t9, $t9, -1	# decrements numFlea
		
		j delete_flea_loop
		
				
	dec_num_flea:
		lw $t9, numFlea		# resets numFlea
		addi $t9, $t9, -1	# decrements numFlea
		sw $t9, numFlea		# stores new value
		
		add $t9, $zero, $t6
		add $a1, $zero, $t5
		
		addi $a1, $a1, -4	# goes back one element in the array so that when iterating, it will still check the correct next element instead of skipping one
				
		j ITERATE_UPDATE_FLEA
		
		
	NOT_FLEA_EDGE:
		addi $t1, $t1, 32	# moves flea down one row
		
		bne $t1, $t8, STORE_FLEA
		
		j Exit			# if flea hits bug blaster, end game
		
	STORE_FLEA:
		sw $t1, 0($a1)		# stores new flea location in array
		
	ITERATE_UPDATE_FLEA:
		addi $a1, $a1, 4	# gets next flea
		addi $t9, $t9, -1	# decrements num Flea
		
		j update_flea_loop		
		
	RETURN_UPDATE_FLEA:
		# pop a word off the stack and move the stack pointer
		lw $ra, 0($sp)
		addi $sp, $sp, 4
	
		jr $ra


#######################################################################################################################################################################

delay:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a2, 10000
	addi $a2, $a2, -1
	bgtz $a2, delay
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


# sleep function 
sleep:
	li $v0, 32
	li $a0, 50
	syscall

	jr $ra
	
	
get_random_width:
  	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 31             
  	syscall             # Generate random int (returns in $a0)
  	jr $ra
  	
get_mushroom_height:
 	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 23             
  	syscall             # Generate random int (returns in $a0)
  	jr $ra
  
get_random_number:
	li $v0, 42
	li, $a0, 0
	li $a1, 20
	syscall		    # Generate random int (returns in $a0) 
	jr $ra

draw_bg:
	lw $t0, displayAddress		# Location of current pixel data
	addi $t1, $t0, 4096		# Location of last pixel data. Hard-coded below.
						# 32x32 = 1024 pixels x 4 bytes = 4096.
	lw $t2, backgroundColor			# Colour of the background
	
draw_bg_loop:
	sw $t2, 0($t0)				# Store the colour
	addi $t0, $t0, 4			# Next pixel
	blt $t0, $t1, draw_bg_loop
	
	jr $ra
	
GG:
	# draw g
	lw $t0, displayAddress
	addi $t0, $t0, 1576
	lw $t1, headColor
	sw $t1, 904($t0)
	sw $t1, 900($t0)
	sw $t1, 896($t0)
	sw $t1, 776($t0)
	
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 512($t0)
	sw $t1, 640($t0)
	sw $t1, 644($t0)
	sw $t1, 648($t0)
	#draw g
	sw $t1, 400($t0)
	sw $t1, 528($t0)
	sw $t1, 656($t0)
	sw $t1, 408($t0)
	sw $t1, 404($t0)
	sw $t1, 536($t0)
	sw $t1, 660($t0)
	sw $t1, 664($t0)
	sw $t1, 792($t0)
	sw $t1, 920($t0)
	sw $t1, 916($t0)
	sw $t1, 912($t0)
	#draw !
	sw $t1, 160($t0)
	sw $t1, 288($t0)
	sw $t1, 416($t0)
	sw $t1, 672($t0)
	li $v0, 32 # sleep
	li $a0, 1000
  jr $ra