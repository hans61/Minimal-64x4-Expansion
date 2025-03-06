#org 0x2000
start:
    LDI 159 JAS wrSN76489   ; OFF TONE 1 0x9f
    LDI 191 JAS wrSN76489   ; OFF TONE 2 0xbf
    LDI 223 JAS wrSN76489   ; OFF TONE 3 0xdf
    LDI 255 JAS wrSN76489   ; TURN OFF NOISE 0xff

    LDI 0 STB cs1sn
    JPS waitBlink
    LDI 3 STB cs1sn
    JPS waitBlink
    LDI 0 STB cs1sn
    JPS waitBlink
    LDI 3 STB cs1sn
    JPS waitBlink
    LDI 0 STB cs1sn
    JPS waitBlink
    LDI 3 STB cs1sn
    JPS waitBlink
    LDI 0 STB cs1sn

	;JPA _Prompt   ; for testing
    RTS

waitBlink:
    JPS waitVsync
    JPS waitVsync
    JPS waitVsync
    JPS waitVsync
    JPS waitVsync
    JPS waitVsync
    JPS waitVsync
    JPS waitVsync
    JPS waitVsync
    JPS waitVsync
    RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
waitVsync:
    LDB vsync
    ANI 0x40
    CPI 0x00
    BEQ waitVsync   ; wait until high
vsync1:
    LDB vsync
    ANI 0x40
    CPI 0x00
    BNE vsync1
    RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; write A to SN76489
wrSN76489:
    STB sn76489
    MIB 0x02,cs1sn  ; CLB rwLow
    NOP NOP NOP NOP ; (NOP = 2µS) the SN764898 requires 8µs at 4Mhz (16µs at 2Mhz)
    MIB 0x00,cs1sn  ; CLB rwHigh
    RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#mute

#org 0xfee0 sn76489: ; SN76489 data port (4HC574)
#org 0xfee1 vsync:   ; 4HC574 input Kempston, bit6 = vsync
#org 0xfee2 cs1sn:   ; bit 0 = 1 -> /CS = 0 | bit 0 = 0 -> /CS = 1, bit0 = sd-card bit1 = sn76489
#org 0xfee3 spi:     ; address for reading and writing the spi shift register, writing starts the beat

#org 0xf000 _Start:
#org 0xf003 _Prompt:
#org 0xf006 _MemMove:
#org 0xf009 _Random:
#org 0xf00c _ScanPS2:
#org 0xf00f _ResetPS2:
#org 0xf012 _ReadInput:
#org 0xf015 _WaitInput:
#org 0xf018 _ReadLine:
#org 0xf01b _SkipSpace:
#org 0xf01e _ReadHex:
#org 0xf021 _SerialWait:
#org 0xf024 _SerialPrint:
#org 0xf027 _FindFile:
#org 0xf02a _LoadFile:
#org 0xf02d _SaveFile:
#org 0xf030 _ClearVRAM:
#org 0xf033 _Clear:
#org 0xf036 _ClearRow:
#org 0xf039 _ScrollUp:
#org 0xf03c _ScrollDn:
#org 0xf03f _Char:
#org 0xf042 _PrintChar:
#org 0xf045 _Print:
#org 0xf048 _PrintHex:
#org 0xf04b _Pixel:
#org 0xf04e _Line:
#org 0xf051 _Rect:
#org 0x00c0 _XPos:
#org 0x00c1 _YPos:
#org 0x00c2 _RandomState:
#org 0x00c6 _ReadNum:
#org 0x00c9 _ReadPtr:
#org 0x00cd _ReadBuffer: