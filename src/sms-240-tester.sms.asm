;==============================================================
; WLA-DX banking setup
;==============================================================
.memorymap
defaultslot 2
slotsize $4000
slot 0 $0000
slot 1 $4000
slot 2 $8000
.endme

.rombankmap
bankstotal 2
banksize $4000
banks 2
.endro

;==============================================================
; SDSC tag and SMS rom header
;==============================================================
.sdsctag 1.00,"Extended video modes tester","Demonstrates usage of extended-height video modes","Maxim"

.bank 0 slot 0
.org $0000
.section "Boot section" force
  di              ; disable interrupts
  im 1            ; Interrupt mode 1
  jp main         ; jump to main program
.ends

.section "aPLib" free
.define aPLibToVRAM
.include "aPLib_decompressor_(fast).asm"
.ends

.org $0066
.section "Pause button handler" force
  ; Do nothing
  retn
.ends

.section "Main program" free
main:
  ld sp, $dff0

-:
  ; Mode 4, 192 lines #########################################
  
  ; Initialise VDP
  call DefaultInitialiseVDP
  call ClearVRAM

  call NoSprites ; they mess things up

  ; Load palette
  ld hl,$c000                     ; palette index 0 write address
  call VRAMToHL
  ld hl,palette192        
  ld bc,_sizeof_palette192
  call WriteToVRAM

  ; Load tiles
  ld de,$4000
  ld hl,tiles192
  call aPLib_decompress

  ; Load tilemap (direct to VRAM)
  ld hl,tilemap192
  ld de,$3800 | $4000
  call aPLib_decompress

  ; Turn screen on (192 mode)
  ld a,$c4
  out ($bf),a
  ld a,$81
  out ($bf),a

  call WaitForButton

  ; Turn screen off
  ld a,$84
  out ($bf),a
  ld a,$81
  out ($bf),a

  ; Mode 4, 224 lines #########################################

  ; Load palette
  ld hl,$c000                     ; palette index 0 write address
  call VRAMToHL
  ld hl,palette224        
  ld bc,_sizeof_palette224
  call WriteToVRAM

  ; Load tiles
  ld de,$4000
  ld hl,tiles224
  call aPLib_decompress

  ; Load tilemap (direct to VRAM)
  ld hl,tilemap224
  ld de,$3700 | $4000
  call aPLib_decompress

  ; Turn screen on (224 mode)
  ld a,%00000110
  out ($bf),a
  ld a,$80
  out ($bf),a
  ld a,%11010000 ; screen on, 224 mode
  out ($bf),a
  ld a,$81
  out ($bf),a

  call WaitForButton

  ; Turn screen off
  ld a,$84
  out ($bf),a
  ld a,$81
  out ($bf),a

  ; Mode 4, 240 lines #########################################

  ; Load palette
  ld hl,$c000                     ; palette index 0 write address
  call VRAMToHL
  ld hl,palette240        
  ld bc,_sizeof_palette240
  call WriteToVRAM

  ; Load tiles
  ld de,$4000
  ld hl,tiles240
  call aPLib_decompress

  ; Load tilemap (direct to VRAM)
  ld hl,tilemap240
  ld de,$3700 | $4000
  call aPLib_decompress

  ; Turn screen on (240 mode)
  ld a,%00000110
  out ($bf),a
  ld a,$80
  out ($bf),a
  ld a,%11001000 ; screen on, 240 mode
  out ($bf),a
  ld a,$81
  out ($bf),a

  call WaitForButton

  ; Turn screen off
  ld a,$84
  out ($bf),a
  ld a,$81
  out ($bf),a

  jp -
.ends

;==============================================================
; Data
;==============================================================
.section "192 data" superfree
  tiles192:
  .incbin "192.tiles.aplib"
  tilemap192:
  .incbin "192.tilemap.aplib"
  palette192:
  .incbin "192.palette.bin"
.ends
.section "224 data" superfree
  tiles224:
  .incbin "224.tiles.aplib"
  tilemap224:
  .incbin "224.tilemap.aplib"
  palette224:
  .incbin "224.palette.bin"
.ends
.section "240 data" superfree
  tiles240:
  .incbin "240.tiles.aplib"
  tilemap240:
  .incbin "240.tilemap.aplib"
  palette240:
  .incbin "240.palette.bin"
.ends

.slot 0
;==============================================================
; Set up VDP registers (default values)
;==============================================================
; Call DefaultInitialiseVDP to set up VDP to default values.
; Also defines NameTableAddress, SpriteTableAddress and SpriteSet
; which can be used after this code in the source file.
; To change the values used, copy and paste the modified data
; and code into the main source. Data is commented to help.
;==============================================================
.section "Initialise VDP to defaults" free
DefaultInitialiseVDP:
    push hl
    push bc
        ld hl,_Data
        ld b,_sizeof__Data
        ld c,$bf
        otir
    pop bc
    pop hl
    ret

.define SpriteSet           0       ; 0 for sprites to use tiles 0-255, 1 for 256+
.define NameTableAddress    $3800   ; must be a multiple of $1000 + $700; usually $3700; fills $800 bytes (unstretched)
.define SpriteTableAddress  $3f00   ; must be a multiple of $100; usually $3f00; fills $100 bytes

_Data:
    .db %00000100,$80
    ;    |||||||`- Disable sync
    ;    ||||||`-- Enable extra height modes
    ;    |||||`--- SMS mode instead of SG
    ;    ||||`---- Shift sprites left 8 pixels
    ;    |||`----- Enable line interrupts
    ;    ||`------ Blank leftmost column for scrolling
    ;    |`------- Fix top 2 rows during horizontal scrolling
    ;    `-------- Fix right 8 columns during vertical scrolling
    .db %10000000,$81
    ;     ||||||`- Zoomed sprites -> 16x16 pixels
    ;     |||||`-- Doubled sprites -> 2 tiles per sprite, 8x16
    ;     ||||`--- Mega Drive mode 5 - leave at 0
    ;     |||`---- 30 row/240 line mode
    ;     ||`----- 28 row/224 line mode
    ;     |`------ Enable VBlank interrupts
    ;     `------- Enable display
    .db (NameTableAddress>>10) |%11110001,$82
    .db (SpriteTableAddress>>7)|%10000001,$85
    .db (SpriteSet<<2)         |%11111011,$86
    .db $f|$f0,$87
    ;    `-------- Border palette colour (sprite palette)
    .db $00,$88
    ;    ``------- Horizontal scroll
    .db $00,$89
    ;    ``------- Vertical scroll
    .db $ff,$8a
    ;    ``------- Line interrupt spacing ($ff to disable)
.ends

;==============================================================
; Clear VRAM
;==============================================================
; Sets all of VRAM to zero
;==============================================================
.section "Clear VRAM" free
ClearVRAM:
  push af
  push hl
    ld hl,$4000
    call VRAMToHL
    ; Output 16KB of zeroes
    ld hl, $4000    ; Counter for 16KB of VRAM
  -:xor a
    out ($be),a ; Output to VRAM address, which is auto-incremented after each write
    dec hl
    ld a,h
    or l
    jp nz,-
    ld hl,$c000
    call VRAMToHL
    ; Set palette to black
    ld b,32
    xor a
  -:out ($be),a ; Output to CRAM address, which is auto-incremented after each write
    djnz -
  pop hl
  pop af
  ret
.ends

;==============================================================
; VRAM to HL
;==============================================================
; Sets VRAM write address to hl
;==============================================================
.section "VRAM to HL" free
VRAMToHL:
  push af
    ld a,l
    out ($bf),a
    ld a,h
    out ($bf),a
  pop af
  ret
.ends

;==============================================================
; VRAM writer
;==============================================================
; Writes BC bytes from HL to VRAM
; Clobbers HL, BC, A
;==============================================================
.section "Raw VRAM writer" free
WriteToVRAM:
-:ld a,(hl)
  out ($be),a
  inc hl
  dec bc
  ld a,c
  or b
  jp nz,-
  ret
.ends

;==============================================================
; Sprite disabler
;==============================================================
; Sets sprite 1 to y=208
; Clobbers HL, A
;==============================================================
.section "No sprites" free
NoSprites:
  ld hl,SpriteTableAddress | $4000
  call VRAMToHL
  ld b,64
  ld a,-9
-:out ($be),a
  djnz -
  ret
.ends

;==============================================================
; Wait for button press
;==============================================================
; Clobbers A
; Not very efficient, I'm aiming for simplicity here
;==============================================================
.section "Wait for button press" free
WaitForButton:
-:in a,$dc ; get input
  cpl      ; invert bits
  or a     ; test bits
  jr nz,-  ; wait for no button press
-:in a,$dc ; get input
  cpl      ; invert bits
  or a     ; see if any are set
  jr z,-
  ret
.ends
