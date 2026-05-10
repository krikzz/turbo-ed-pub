
.segment "BNK00"

VDC_REG     = $100
VDC_REG_MRW = $02

cval        = $0120 
clr_row:
.word cval, cval, cval, cval, cval, cval, cval, cval
.word cval, cval, cval, cval, cval, cval, cval, cval
.word cval, cval, cval, cval, cval, cval, cval, cval
.word cval, cval, cval, cval, cval, cval, cval, cval

.export _g_clean_plan
_g_clean_plan:
    ldx #28
    lda #VDC_REG_MRW
    sta VDC_REG
@1:
    tia clr_row, 2,  64
    tia clr_row, 2,  64
  
    dex
    bne @1
    rts

.export _sys_set_bank
.import _sys_bank
_sys_set_bank:
    lda _sys_bank
    tam #4
    rts

.export _font
_font:
.incbin "font.bin"
nop
