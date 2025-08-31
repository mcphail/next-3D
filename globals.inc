; ******************************************************************************************************************************
;
;	Assembler Includes
;
; ******************************************************************************************************************************

    	MACRO BREAK
		DB $fd,00
	ENDM

	START_16K_BANK = 9
	START_8K_BANK = (START_16K_BANK * 2)

	MMU_REGISTER_0 = 0x50
	MMU_REGISTER_1 = 0x51
	MMU_REGISTER_2 = 0x52
	MMU_REGISTER_3 = 0x53
	MMU_REGISTER_4 = 0x54
	MMU_REGISTER_5 = 0x55
	MMU_REGISTER_6 = 0x56
	MMU_REGISTER_7 = 0x57

        ; ports
        defc Z80DMAPORT  		= 107				; DMA port
        defc SpriteRegPort		= 0x57
        defc SpriteShapePort 		= 0x5b

	; half row 1
        defc VK_CAPS	=	0
        defc VK_Z	=	1
        defc VK_X	=	2
        defc VK_C	=	3
        defc VK_V	=	4
	; half row 2
        defc VK_A	=	5
        defc VK_S	=	6
        defc VK_D	=	7
        defc VK_F	=	8
        defc VK_G	=	9
	; half row 3
        defc VK_Q	=	10
        defc VK_W	=	11
        defc VK_E	=	12
        defc VK_R	=	13
        defc VK_T	=	14
	; half row 4
        defc VK_1	=	15
        defc VK_2	=	16
        defc VK_3	=	17
        defc VK_4	=	18
        defc VK_5	=	19

	; half row 5
        defc VK_0	=	20
        defc VK_9	=	21
        defc VK_8	=	22
        defc VK_7	=	23
        defc VK_6	=	24
	; half row 6
        defc VK_P	=	25
        defc VK_O	=	26
        defc VK_I	=	27
        defc VK_U	=	28
        defc VK_Y	=	29

	; half row 7
        defc VK_ENTER	=	30
        defc VK_L	=	31
        defc VK_K	=	32
        defc VK_J	=	33
        defc VK_H	=	34
	; half row 8
        defc VK_SPACE	=	35
        defc VK_SYM	=	36
        defc VK_M	=	37
        defc VK_N	=	38
        defc VK_B	=	39
