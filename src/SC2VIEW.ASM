
;*** SC2 Picture Viewer v.0.91 for MSX

;*** Use ZASM to assemble it

LF	equ	0ah
CR	equ	0dh
BDOS	equ	00005h
CALSLT	equ	0001Ch
FCB	equ	0005ch
MNROM	equ	0FCC1h
BUFTOP	equ	08000h

progStart	equ	0100h

	org	progStart

	jp	MAIN

MesVer:
	db	CR,LF,"SC2 Picture Viewer",CR,LF
	db	" v.0.91 by GDX",CR,LF,CR,LF,24h
ErrMes:
	db	"File reading error !",CR,LF,CR,LF
	db	"Usage: SC2VIEW filename.ext",CR,LF,24h
Completed:
	db	"Completed.",CR,LF,24h

MAIN:
	ld	de,MesVer
	ld	c,9
	call	BDOS			; Print MesVer message

PreFCB:
	ld	bc,24			; Prepare the FCB
	ld	de,FCB+13
	ld	hl,FCB+12
	ld	(hl),b
	ldir				; Initialize the second half with zero

	ld	c,0fh
	ld	de,FCB
	call	BDOS			; Open file
	ld	hl,1
	ld	(FCB+14),hl		; Record size = 1 byte
	or	a
	ld	de,ErrMes		; DE = Error message address
	jp	nz,Done

	ld	c,1ah
	ld	de,BUFTOP
	call	BDOS			; Set disk transfer address (buffer start)

	ld	c,27h
	ld	de,FCB
	ld	hl,04007h		; Number of records to read
	call	BDOS			; Read picture file
RAM2VRAM:
	or	a
	ld	bc,7
	sbc	hl,bc
	ld	(PictureSize),hl	; Store Picture size

	ld	a,(0F3E9h)	; Text color
	ld	(TextColor),a
	ld	a,(0F3EAh)	; Back color
	ld	(BackColor),a
	ld	a,(0F3EBh)	; Border color
	ld	(BorderColor),a

	xor	a
	ld	(0F3E9h),a	; Hide cursor
	ld	(0F3EAh),a	; Back color = 0
	ld	(0F3EBh),a	; Border color = 0
	ld	a,2
	ld	(0FCAFH),a
	ld	iy,(MNROM-1)
	ld	ix,005Fh
	call	CALSLT		; SCREEN 2 mode

	ld	iy,(MNROM-1)
	ld	ix,0072h
	call	CALSLT		; Initialize SCREEN 2 mode

	ld	hl,(PictureSize)
	ld	b,h
	ld	c,l		; BC = Picture size
	ld	hl,04000h
	or	a
	sbc	hl,bc
	ld	b,h
	ld	c,l		; BC = size of unused aera in VRAM
	push	bc
	ld	hl,(PictureSize)
	ld	b,h
	ld	c,l		; BC = Picture size
	ld	hl,BUFTOP+7
	add	hl,bc		; hl = pointer to unused aera in VRAM
	ld	(hl),0
	ld	d,h
	ld	e,l
	inc	de
	pop	bc
	inc	bc
	ldir			; Erase unused aera in VRAM
		
	ld	hl,BUFTOP+7
	ld	de,0
	ld	bc,04000h
	ld	iy,(MNROM-1)
	ld	ix,005Ch
	call	CALSLT		; Transfert Ram to Vram

WaitSpaceKey:
	ld	iy,(MNROM-1)
	ld	ix,00D8h
	call	CALSLT		; Test space key
	or	a
	jr	z,WaitSpaceKey
WaitNotSpaceKey:
	ld	iy,(MNROM-1)
	ld	ix,00D8h
	call	CALSLT		; Test space key
	or	a
	jr	nz,WaitNotSpaceKey

	ld	hl,(0F3F8h)
	ld	(0F3FAh),hl	; Kill keyboard buffer
	ld	(hl),0

	ld	a,(TextColor)
	ld	(0F3E9h),a	; Restore text color
	ld	a,(BackColor)
	ld	(0F3EAh),a	; Restore back color
	ld	a,(BorderColor)
	ld	(0F3EBh),a	; Restore border color

	ld	iy,(MNROM-1)
	ld	ix,006Ch
	call	CALSLT		; back to text mode
	
	ld	de,Completed
Done:
	ld	c,9
	call	BDOS		; Print back message
	
	rst	0		; back to MSX-DOS
PictureSize:
	dw	0
TextColor:
	db	0
BackColor:
	db	0
BorderColor:
	db	0
Cur_dir_buff:
	ds	64
