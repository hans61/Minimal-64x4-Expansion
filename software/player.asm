; this guide uses http://www.rjhcoding.com/avrc-sd-interface-1.php
; 
; 
#org 0x2000
start:
    MIB 0xfe,0xffff                  ; SP initialize
main:
    JPS _Clear
    LDI 10 JAS delay_ms              ; give card time to power up
    MIZ 1,_YPos MIZ 5,_XPos          ; status bar
    JPS _Print "SD init...", 0
    JPS SD_init
    CPI 0x00
    BEQ next1
    MIZ 1,_YPos MIZ 5,_XPos
    JPS _Print "Error initializaing SD CARD", 0
returnError:
    JPS _Print 10, "ANY KEY ", 0
    JPS _WaitInput
    JPS _Clear
    JPA _Prompt
next1:
    JPS fat32_init
    BCC initsuccess
fat32error:
    LDB fat32_errorstage JAS _PrintHex
    MIZ 1,_YPos MIZ 5,_XPos         ; status bar
    JPS _Print " FAT32 Error", 0
    JPA returnError

initsuccess:                        ; successful initialization of the SD card
    ; Open root directory
    MIZ 1,_YPos MIZ 5,_XPos         ; status bar
    JPS _Print "Open Root                 ", 0
    JPS fat32_openroot
test00:
    JPS readDirList
    ; here list finished reading
    JPS _Clear  

test01:
    MIZ 1,_YPos MIZ 5,_XPos
    JPS _Print "Volume: ", 0
    JPS printVolumeLabel
    JPS SilenceAllChannels
    CLB PtrE CLB Off
    JPS printFrame
    JPS printListe
    
test03: 
    MIZ 3,_YPos ABZ PtrE,_YPos MIZ 4,_XPos LDI ">" JAS _PrintChar   ; Set pointer to entry PtrE (0..)

test04:
    JPS _WaitInput  ; input loop
    STB Key
    CPI "Q"
    BEQ quit
    CPI "q"
    BEQ quit
    CPI 10          ; CR
    BEQ tCR
    CPI 0xe1        ; UP only works on connected keyboard not TeraTerm
    BEQ tUP
    CPI 0xe2        ; DOWN only works on connected keyboard not TeraTerm
    BEQ tDOWN
    CPI 0x09        ; TAB
    BEQ tDOWN
    CPI "v"         ; display for debugging
    BEQ tView
    
    JPA test04
tUP:
    LDB PtrE        ; <=n-1
    CPI 0x00        ; PtrE points to the top entry
    BEQ tUP1
    MIZ 3,_YPos ABZ PtrE,_YPos MIZ 4,_XPos LDI " " JAS _PrintChar   ; delete marker
    DEB PtrE        ; pointer up
    JPA test03
tUP1:
    LDB Off
    CPI 0x00
    BEQ test04
    DEB Off         ; Reduce offset
    JPS printListe  ; now rewrite list
    JPA test04
tDOWN:
    MIZ 3,_YPos ABZ PtrE,_YPos MIZ 4,_XPos LDI " " JAS _PrintChar   ; delete marker
    ;LDB entries        ; 1..n
    ;CPB PtrE       ; 0..n-1
    LDB PtrE        ; <=n-1
    CPI <_LINES-1
    BEQ tDOWN1      ; end of ad reached
    INC
    CPB entries     ; n
    BEQ test05      ; End of the list has been reached
    INB PtrE
    JPA test03
test05:
    LDB Key
    CPI 0xe2
    BEQ test03
    CLB PtrE        ; on 1st entry
    CLB Off
    JPS printListe  ; now rewrite list
    JPA test03
tDOWN1:
    LDB PtrE
    ADB Off
    INC
    CPB entries     ; n
    BEQ test05      ; End of the list has been reached
    INB Off
    JPS printListe  ; now rewrite list
    JPA test03
tCR:
    ; Calculate address in buffer
    MBZ PtrE, Z1
    LDB Off         ; consider offset
    AD.Z Z1
    CLZ Z1+1
    LLV Z1 LLV Z1 LLV Z1 LLV Z1 LLV Z1 ; 5x slide left (*32)
    AIV <list_buffer,Z1
    AIZ >list_buffer,Z1+1
    MVV Z1,zp_sd_address
    AIV 11,Z1               ; 0+11
    LDT Z1
    ANI 0x10
    CPI 0x00
    BEQ isFile              ; it is not a directory
    ; directory
    AIV 9,Z1                ; 11+9=20
    LDT Z1 CPI 0x00
    BNE tCR1
    INV Z1 LDT Z1 CPI 0x00
    BNE tCR1
    AIV 5,Z1                ; 21+5=26
    LDT Z1 CPI 0x00
    BNE tCR1
    INV Z1 LDT Z1 CPI 0x00
    BNE tCR1
    ; it is the root directory
    JPS fat32_openroot
    JPA test00
tCR1:
    ; any other directory
    JPS fat32_opendirent
    JPA test00


; debug code    
tView:
    MIZ 26,_YPos MIZ 0,_XPos
    MBZ PtrE,Z1 CLZ Z1+1
    LDB Off
    PHS JAS _PrintHex LDI " " JAS _PrintChar PLS
    AD.Z Z1
    LLV Z1 LLV Z1 LLV Z1 LLV Z1 LLV Z1
    AIV <list_buffer,Z1 AIZ >list_buffer,Z1+1
    MIZ 32,Z0
tV:
    LDT Z1 JAS _PrintHex
    INV Z1 DEZ Z0
    BEQ test03
    CIZ 32-11,Z0
    BEQ tV1
    CIZ 32-12,Z0
    BEQ tV1
    CIZ 32-20,Z0
    BEQ tV1
    CIZ 32-22,Z0
    BEQ tV1
    CIZ 32-26,Z0
    BEQ tV1
    CIZ 32-28,Z0
    BEQ tV1
    JPA tV
tV1:
    LDI " " JAS _PrintChar
    JPA tV
; debug code end
    
isFile:
    MIZ 28,_YPos MIZ 5,_XPos    ; status bar
    DEV Z1 LDT Z1 CPI "C"
    BNE noVGC
    DEV Z1 LDT Z1 CPI "G"
    BNE noVGC
    DEV Z1 LDT Z1 CPI "V"
    BNE noVGC

    JPS _Print "Play: ", 0
    ; Calculate address in buffer
    MBZ PtrE,Z1
    LDB Off AD.Z Z1
    CLZ Z1+1
    LLV Z1 LLV Z1 LLV Z1 LLV Z1 LLV Z1 ; 5x shift left (*32)
    AIV <list_buffer,Z1
    AIZ >list_buffer,Z1+1
    ;MIZ 26,_YPos MIZ 5,_XPos
    ;LDZ Z1+1 JAS _PrintHex
    ;LDZ Z1 JAS _PrintHex
    MVV Z1,zp_h_address
    MVV Z1,zp_sd_address
    ;JPS _WaitInput 
    JPS printFileName
    ;JPS _WaitInput 
    JPS fat32_opendirent
    JPA songLoop

noVGC:
    JPS _Print "File is ", 0
    ; Calculate address in buffer
    MBZ PtrE,Z1
    LDB Off AD.Z Z1
    CLZ Z1+1
    LLV Z1 LLV Z1 LLV Z1 LLV Z1 LLV Z1 ; 5x shift left (*32)
    AIV <list_buffer,Z1
    AIZ >list_buffer,Z1+1
    MVV Z1,zp_h_address
    JPS printFileName
    ;JPS _WaitInput 
    JPA test03
; ######################## Sound #########################
songLoop:   
    JPS fat32_file_readbyte
    BCC songL1
EOF:
    ;JPS _Print "End of File", 10, 0
    JPS SilenceAllChannels
    JPA start
songL1: 
    STZ counter
songL2: 
    LDZ counter
    CPI 0xff
    BEQ finish
dataLoop:
    LDZ counter
    CPI 0x00
    BEQ noData
    DEZ counter
    JPS fat32_file_readbyte
    BCS EOF
    JAS wrSN76489
    JPA dataLoop
noData:
    JPS wait20ms    ; 50Hz = 20ms
    JPA songLoop
finish:
    JPS SilenceAllChannels
    JPA start
quit:
    JPS _Clear
    JPA _Start



Attr: 0x00
PtrE: 0x00
Off: 0x00
Key: 0x00

printFrame:
    MIZ 0,_YPos MIZ 2,_XPos
    LDI '/' JAS _PrintChar MIZ 26,Z3
printF1:
    LDI '-' JAS _PrintChar DEZ Z3 BNE printF1
    LDI '\' JAS _PrintChar
    INZ _YPos MIZ 2,_XPos
    LDI '|' JAS _PrintChar MIZ 29,_XPos LDI '|' JAS _PrintChar 
    INZ _YPos MIZ 2,_XPos
    JPS _Print "|-- NAME ----------- SIZE -|", 0
    MIZ <_LINES,Z3
printF2:
    INZ _YPos MIZ 2,_XPos
    LDI '|' JAS _PrintChar MIZ 29,_XPos LDI '|' JAS _PrintChar 
    DEZ Z3 BNE printF2
    INZ _YPos MIZ 2,_XPos
    LDI '|' JAS _PrintChar MIZ 26,Z3
printF3:
    LDI '-' JAS _PrintChar DEZ Z3 BNE printF3
    LDI '|' JAS _PrintChar
    INZ _YPos MIZ 2,_XPos
    LDI '|' JAS _PrintChar MIZ 29,_XPos LDI '|' JAS _PrintChar 
    INZ _YPos MIZ 2,_XPos
    LDI '\' JAS _PrintChar MIZ 26,Z3
printF4:
    LDI '-' JAS _PrintChar DEZ Z3 BNE printF4
    LDI '/' JAS _PrintChar
    RTS
    
printListe:
    MIW list_buffer,dir_ptr         ; dir_ptr pointer to list start
    MBZ Off,Z3
prList1:
    CIZ 0x00,Z3
    BEQ prList2
    AIW 32,dir_ptr
    DEZ Z3
    JPA prList1
prList2:
    LDB entries
    CPI <_LINES
    BMI prList3                     ; less than 25 entries in the list
    MIZ <_LINES,Z3
    JPA prList4
prList3:
    MBZ entries,Z3                  ; Z3 is number of entries in the list
prList4:
    MIZ 3, _YPos                    ; List starts at 4th screen line
prList5:
    MWV dir_ptr,zp_h_address
    MIZ 5, _XPos
    JPS printEntrie
    INZ _YPos
    ; LDI 10 JAS _PrintChar
    AIW 32,dir_ptr
    DEZ Z3
    BNE prList5
    RTS
printFileName:
    ; zp_h_address is pointer to record
    MIZ 8,Z0
    MIZ 13,Z1
prEn01:
    LDT zp_h_address                ; A = *(*zp_h_address)
    PHS INV zp_h_address PLS
    CPI 0x20                        ; is space
    BEQ prEn02
    JAS _PrintChar
    DEZ Z1                          ; subtract one character from the tab
prEn02:
    DEZ Z0
    BNE prEn01
    MIZ 3,Z0
    LDT zp_h_address
    CPI 0x20                        ; is space
    BEQ prEn03
    ; Punkt einfügen
    LDI 0x2e JAS _PrintChar DEZ Z1
prEn03:
    LDT zp_h_address                ; A = *(*zp_h_address)
    PHS INV zp_h_address PLS
    CPI 0x20                        ; is space
    BEQ prEn04
    JAS _PrintChar DEZ Z1
prEn04:
    DEZ Z0
    BNE prEn03
prEn05:
    LDI 0x20 JAS _PrintChar
    DEZ Z1
    BNE prEn05
    RTS
printEntrie:
    JPS printFileName
    LDI 0x20 JAS _PrintChar
    LDT zp_h_address                ; attribut
    ANI 0x10                        ; dir
    CPI 0x00
    BEQ prEn06
    JPS _Print "   <DIR>",0
    RTS
prEn06:
    ; Output file length in bytes
    AIV 20,zp_h_address
    LDT zp_h_address JAS _PrintHex
    DEV zp_h_address
    LDT zp_h_address JAS _PrintHex
    DEV zp_h_address
    LDT zp_h_address JAS _PrintHex
    DEV zp_h_address
    LDT zp_h_address JAS _PrintHex
    RTS
    
readDirList:
    CLB entries                     ; Number of list entries is 0
    MIW list_buffer,dir_ptr         ; pointer to target memory
    ;MIW    0x3800,dir_ptr              ; pointer to target memory 
iDL01:                              ; read entry
    JPS fat32_readdirent
    BCC iDL02                       ; next entry    
    RTS
iDL02:
    MVV zp_sd_address,zp_h_address  ; zp_h_address = zp_sd_address (Word)
    AIV 11,zp_h_address             ; zp_h_address = zp_h_address + 11
    LDT zp_h_address                ; A = *(*zp_h_address)
    STB Attr                        ; Attr = *(*zp_h_address)
    MVV zp_sd_address,zp_h_address  ; zp_h_address = zp_sd_address (Word)
    LDB Attr
    ANI 0x08                        ; Volume-Label = bit 3
    CPI 0x00
    BNE saveVolumeLabel
    LDB Attr
    ANI 0x04                        ; System = bit 2
    CPI 0x00
    BNE iDL01
    MIZ 32,Z0                       ; Z0 = Length DIR entry
    INB entries                     ; new entry added
iDL03:
    ; MZB zp_h_address,dir_ptr
    LDT zp_h_address                ; A = source
    STR dir_ptr                     ; target = A
    INV zp_h_address                ; Increase source by one
    INW dir_ptr                     ; Increase the target by one
    DEZ Z0
    BEQ iDL01                       ; finished copying 32 bytes
    JPA iDL03
saveVolumeLabel:
    ; debug
    ; JPS _Print "Save Volume-Label", 10, 0
    MIZ 11,Z0                       ; Z0 = Length DIR entry
    MIW strVolumeLabel,sav2+1
sav1:
    LDT zp_h_address                ; A = source
sav2:
    STB 0x4800
    INV zp_h_address                ; Increase source by one
    INW sav2+1                      ; Increase the target by one
    DEZ Z0
    BNE sav1
    JPA iDL01
; ################################## Subroutines ###################################
; ----------------------------------------------
delay_ms:
    PHS             ; 8
    JPS wait1ms
    PLS             ; 6
    DEC             ; 3
    BNE delay_ms    ; 4/3
    RTS             ; 
    
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
    
wait1ms: MIZ 194,regA   ; 4 (*0,125µS=0,5µS)            -> (0,5+999,25+2,625)µS | 195~1002,375 194~997,25µS
w1ms: NOP NOP DEZ regA BNE w1ms ; (32+5+4[3]) * 195 = 7994 = 999,25µS
    RTS                     ; 10 (+11 für JSR) = 2,625µS
; ----------------------------------------------
wait20ms:
    JPS waitVsync   ; 16,67ms
    ; JPS waitVsync ; 16,67ms
    ; JPS waitVsync ; 16,67ms
    JPS wait1ms
    JPS wait1ms
    ;JPS wait1ms
    RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; write A to SN76489
wrSN76489:
    STB sn76489
    MIB 0x02,hc173  ; CLB rwLow
    NOP NOP NOP NOP ; (NOP = 2µS) the SN764898 requires 8µs at 4Mhz (16µs at 2Mhz)
    MIB 0x00,hc173  ; CLB rwHigh
    RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SilenceAllChannels:
    LDI 0x9f JAS wrSN76489
    LDI 0xbf JAS wrSN76489
    LDI 0xdf JAS wrSN76489
    LDI 0xff JAS wrSN76489
    RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cs1on:
    MIB 0xff,spi NOP
    MIB <_CS_ON,hc173
    MIB 0xff,spi NOP
    RTS
cs1off:
    MIB 0xff,spi NOP
    MIB <_CS_OFF,hc173
    MIB 0xff,spi NOP
    RTS
; ----------------------------------------------
; Put SD card into SPI mode
SD_powerUpSeq:
    ;MIB 0x01,hc173 NOP    ; make sure card is deselected
    MIB <_CS_OFF,hc173
    LDI 1 JAS delay_ms  ; give SD card time to power up
    MIZ 10, Z0          ; send 80 clock cycles to synchronize (8 bits times 10)
SD_power1:
    MIB 0xff,spi NOP
    DEZ Z0
    BNE SD_power1
    MIB <_CS_ON,hc173      ; select SD card
    MIB 0xff,spi NOP
    RTS


; ----------------------------------------------
; |             Begin Init FAT32               |
; ----------------------------------------------
fat32_init:
    ; Initialize module - read MBR etc., search for partition,
    ; and set up variables for navigation in the file system

    ; Read MBR and extract relevant information

    CLB fat32_errorstage

    ; Read the MBR and extract relevant information (Sector 0)
    CLQ zp_sd_currentsector+0           ; Clear fast long, read sector = 0 (zp_sd_currentsector = [0..31]) 4 byte
    MIV fat32_readbuffer, zp_sd_address ; (zp_sd_address) = fat32_readbuffer = 0x3000
    JPS sd_readsector

    INB fat32_errorstage                ; stage 1 = boot sector signature check -> CMD17 error

    ; signature check
    LDB fat32_readbuffer+510            ; Boot sector signature 55
    CPI 0x55
    BNE fail
    LDB fat32_readbuffer+511            ; Boot sector signature aa
    CPI 0xaa
    BNE fail

    INB fat32_errorstage                ; stage 2 = finding partition -> signature error

    ; Find a FAT32 partition
    MIZ 0,RegX                         ; RegX = 0
    LZB RegX,fat32_readbuffer+0x1c2    ; A = *(addr + *Z), fat32_readbuffer+0x1c2 = Begin der Partitionstabelle (4 x 16 Byte) + 4 = Byte Type
    CPI 12                             ; check of FAT32 (FAT32 ist 0x0B und 0x0C)
    BEQ foundpart
    MIZ 16,RegX
    LZB RegX,fat32_readbuffer+0x1c2
    CPI 12                             ; check of FAT32
    BEQ foundpart
    MIZ 32,RegX
    LZB RegX,fat32_readbuffer+0x1c2
    CPI 12                             ; check of FAT32
    BEQ foundpart
    MIZ 48,RegX
    LZB RegX,fat32_readbuffer+0x1c2
    CPI 12                             ; check of FAT32
    BEQ foundpart
fail:
    JPA error
foundpart:

    ; Read the FAT32 BPB -> LBA Beginn -> "Volume ID" first sector of the partition
    ; RegX offset partition 0..3
    LZB RegX,fat32_readbuffer+0x1c6
    STZ zp_sd_currentsector+0
    LZB RegX,fat32_readbuffer+0x1c7
    STZ zp_sd_currentsector+1
    LZB RegX,fat32_readbuffer+0x1c8
    STZ zp_sd_currentsector+2
    LZB RegX,fat32_readbuffer+0x1c9
    STZ zp_sd_currentsector+3
    ; zp_sd_currentsector is the first sector of the partition

    MIV fat32_readbuffer, zp_sd_address
    JPS sd_readsector           ; read the first sector of the partition

    INB fat32_errorstage        ; stage 3 = BPB signature check LBA begin -> "Volume ID"

    LDB fat32_readbuffer+510    ; Boot sector signature 55
    CPI 0x55
    BNE fail
    LDB fat32_readbuffer+511    ; Boot sector signature aa
    CPI 0xaa
    BNE fail

    INB fat32_errorstage        ; stage 4 = RootEntCnt check

    LDB fat32_readbuffer+17     ; RootEntCnt should be 0 for FAT32
    ORB fat32_readbuffer+18
    CPI 0x00
    BNE fail

    INB fat32_errorstage        ; stage 5 = TotSec16 check

    LDB fat32_readbuffer+19     ; TotSec16 should be 0 for FAT32
    ORB fat32_readbuffer+20
    CPI 0x00
    BNE fail

    INB fat32_errorstage        ; stage 6 = SectorsPerCluster check

    ; Check bytes per filesystem sector, it should be 512 for any SD card that supports FAT32
    LDB fat32_readbuffer+11
    CPI 0x00
    BNE fail
    LDB fat32_readbuffer+12     ; high byte is 2 (512), 4, 8, or 16
    CPI 0x02
    BNE fail

    ; Calculate the starting sector of the FAT
    LDZ zp_sd_currentsector
    ADB fat32_readbuffer+14     ; reserved sectors lo
    STB fat32_fatstart
    STB fat32_datastart
    LDB zp_sd_currentsector+1
    ACB fat32_readbuffer+15     ; reserved sectors hi
    STB fat32_fatstart+1
    STB fat32_datastart+1
    LDB zp_sd_currentsector+2
    ACI 0x00
    STB fat32_fatstart+2
    STB fat32_datastart+2
    LDB zp_sd_currentsector+3
    ACI 0x00
    STB fat32_fatstart+3
    STB fat32_datastart+3
    ; fat32_fatstart = start sector of the 1st FAT

    ; Calculate the starting sector of the data area
    LDB fat32_readbuffer+16 STZ Z0  ; number of FATs (Z0) = number of FATs
skipfatsloop:
    LDB fat32_datastart
    ADB fat32_readbuffer+36     ; fatsize 0
    STB fat32_datastart
    LDB fat32_datastart+1
    ACB fat32_readbuffer+37     ; fatsize 1
    STB fat32_datastart+1
    LDB fat32_datastart+2
    ACB fat32_readbuffer+38     ; fatsize 2
    STB fat32_datastart+2
    LDB fat32_datastart+3
    ACB fat32_readbuffer+39     ; fatsize 3
    STB fat32_datastart+3
    DEZ Z0
    BNE skipfatsloop
    ; fat32_datastart = Pointer to start of the data area (cluster 2)

    ; Sectors-per-cluster is a power of two from 1 to 128
    LDB fat32_readbuffer+13
    STB fat32_sectorspercluster

    ; Remember the root cluster
    LDB fat32_readbuffer+44
    STB fat32_rootcluster
    LDB fat32_readbuffer+45
    STB fat32_rootcluster+1
    LDB fat32_readbuffer+46
    STB fat32_rootcluster+2
    LDB fat32_readbuffer+47
    STB fat32_rootcluster+3
    ; fat32_rootcluster = First data cluster (usually 0x00000002)

    CLC
    RTS

error:
    SEC
    RTS
; ----------------------------------------------
; *             End Init FAT32                 *
; ----------------------------------------------
; ----------------------------------------------
printBuffer:
    MIV fat32_readbuffer,zp_sd_address
    JPA print256
printBuffer2:
    MIV buffer2, zp_sd_address
print256:
    ;MIV 0x0080, Z1
    LDB fat32_bytesremaining STZ Z1
    LDB fat32_bytesremaining+1 STZ Z1+1
p256a:
    LDT zp_sd_address
    JAS _PrintHex
    INV zp_sd_address
    DEV Z1
    BNE p256a
    CZZ Z1, Z1+1
    BNE p256a
    JPS _Print 10, 0                        ; Print nl
    RTS
; ----------------------------------------------
; |             Begin Seekcluster              |
; ----------------------------------------------
fat32_seekcluster:
    ; Gets ready to read fat32_nextcluster, and advances it according to the FAT
    ; FAT sector = (cluster*4) / 512 = (cluster*2) / 256
    LDB fat32_nextcluster
    LL1
    LDB fat32_nextcluster+1
    RL1
    STB zp_sd_currentsector
    LDB fat32_nextcluster+2
    RL1
    STB zp_sd_currentsector+1
    LDB fat32_nextcluster+3
    RL1
    STB zp_sd_currentsector+2
    ; note: cluster numbers never have the top bit set, so no carry can occur

    ; Add FAT starting sector zp_sd_currentsector = zp_sd_currentsector + fat32_fatstart
    LDZ zp_sd_currentsector
    ADB fat32_fatstart
    STZ zp_sd_currentsector
    LDZ zp_sd_currentsector+1
    ACB fat32_fatstart+1
    STZ zp_sd_currentsector+1
    LDZ zp_sd_currentsector+2
    ACB fat32_fatstart+2
    STZ zp_sd_currentsector+2
    LDI 0x00
    ACB fat32_fatstart+3
    STZ zp_sd_currentsector+3

    ; Target buffer
    MIV fat32_readbuffer, zp_sd_address
    ; Read the sector from the FAT
    JPS sd_readsector

    ; Before using this FAT data, set currentsector ready to read the cluster itself
    ; We need to multiply the cluster number minus two by the number of sectors per
    ; cluster, then add the data region start sector

    ; Subtract two from cluster number
    LDB fat32_nextcluster
    SUI 0x02                        ; Sub immediate from A: A = A - imm
    STZ zp_sd_currentsector
    LDB fat32_nextcluster+1
    SCI 0x00                        ; Sub imm from A with C: A = A - imm - 1 + C
    STZ zp_sd_currentsector+1
    LDB fat32_nextcluster+2
    SCI 0x00
    STZ zp_sd_currentsector+2
    LDB fat32_nextcluster+3
    SCI 0x00
    STZ zp_sd_currentsector+3

    ; Multiply by sectors-per-cluster which is a power of two between 1 and 128
    LDB fat32_sectorspercluster
spcshiftloop:
    LR1
    BCS spcshiftloopdone
    PHS
    LLZ zp_sd_currentsector
    RLZ zp_sd_currentsector+1
    RLZ zp_sd_currentsector+2
    RLZ zp_sd_currentsector+3
    PLS
    JPA spcshiftloop

spcshiftloopdone:
    ; Add the data region start sector
    LDZ zp_sd_currentsector
    ADB fat32_datastart
    STZ zp_sd_currentsector
    LDZ zp_sd_currentsector+1
    ACB fat32_datastart+1
    STZ zp_sd_currentsector+1
    LDZ zp_sd_currentsector+2
    ACB fat32_datastart+2
    STZ zp_sd_currentsector+2
    LDZ zp_sd_currentsector+3
    ACB fat32_datastart+3
    STZ zp_sd_currentsector+3

    ; That's now ready for later code to read this sector in - tell it how many consecutive
    ; sectors it can now read
    LDB fat32_sectorspercluster
    STB fat32_pendingsectors

    ; Now go back to looking up the next cluster in the chain
    ; Find the offset to this cluster's entry in the FAT sector we loaded earlier

    ; Offset = (cluster*4) & 511 = (cluster & 127) * 4
    LDB fat32_nextcluster
    ANI 0x7f
    LL2
    STZ RegY                     ; Y = low byte of offset

    ; Add the potentially carried bit to the high byte of the address
    ; Carry von LL2
    LDZ zp_sd_address+1
    ACI 0x00
    STZ zp_sd_address+1

    ; Copy out the next cluster in the chain for later use
    MVV zp_sd_address,zp_h_address
    AZV RegY,zp_h_address                   ;
    LDT zp_h_address
    STB fat32_nextcluster

    ;INZ RegY
    ;MVV zp_sd_address,zp_h_address
    ;AZV RegY,zp_h_address                  ;
    INV zp_h_address
    LDT zp_h_address
    STB fat32_nextcluster+1

    INV zp_h_address
    LDT zp_h_address
    STB fat32_nextcluster+2

    INV zp_h_address
    LDT zp_h_address
    ANI 0x0f
    STB fat32_nextcluster+3

    ; See if it's the end of the chain
    ORI 0xf0
    ANB fat32_nextcluster+2
    ANB fat32_nextcluster+1
    CPI 0xff
    BNE notendofchain
    LDB fat32_nextcluster
    CPI 0xf8
    BCC notendofchain

    ; It's the end of the chain, set the top bits so that we can tell this later on
    STB fat32_nextcluster+3
notendofchain:
    RTS
; ----------------------------------------------
; |              End Seekcluster               |
; ----------------------------------------------
; ----------------------------------------------
; |           Begin Readnextsector             |
; ----------------------------------------------
fat32_readnextsector:
    ; Reads the next sector from a cluster chain into the buffer at fat32_address.
    ;
    ; Advances the current sector ready for the next read and looks up the next cluster
    ; in the chain when necessary.
    ;
    ; On return, carry is clear if data was read, or set if the cluster chain has ended.

    ; Maybe there are pending sectors in the current cluster

    LDB fat32_pendingsectors
    CPI 0x00
    BNE readsector

    ; No pending sectors, check for end of cluster chain
    LDB fat32_nextcluster+3
    CPI 0x00
    BMI endofchain

    ; Prepare to read the next cluster
    JPS fat32_seekcluster

readsector:
    DEB fat32_pendingsectors
    ; Set up target address
    MWV fat32_address,zp_sd_address     ; (zp_sd_address) = (fat32_address)
    ; Read the sector
    JPS sd_readsector
    ; Advance to next sector
    INQ zp_sd_currentsector
sectorincrementdone:
    ; Success - clear carry and return
    CLC
    RTS

endofchain:
    ; End of chain - set carry and return
    SEC
    RTS
; ----------------------------------------------
; |             End Readnextsector             |
; ----------------------------------------------
; ----------------------------------------------
; |               Begin Openroot               |
; ----------------------------------------------
fat32_openroot:
    ; Prepare to read the root directory

    LDB fat32_rootcluster
    STB fat32_nextcluster
    LDB fat32_rootcluster+1
    STB fat32_nextcluster+1
    LDB fat32_rootcluster+2
    STB fat32_nextcluster+2
    LDB fat32_rootcluster+3
    STB fat32_nextcluster+3

    JPS fat32_seekcluster

    ; Set the pointer to a large value so we always read a sector the first time through
    MIZ 0xff,zp_sd_address+1 ; mark as sector buffer empty (at the end)

    RTS
; ----------------------------------------------
; |                End Openroot                |
; ----------------------------------------------
; ----------------------------------------------
; |              Begin Opendirent              |
; ----------------------------------------------
fat32_opendirent:
    ; Prepare to read from a file or directory based on a dirent
    ;
    ; Point zp_sd_address at the dirent

    ; Seek to first cluster
    MVV zp_sd_address,zp_h_address
    AIV 20,zp_h_address                 ; zp_sd_address+20
    LDT zp_h_address
    STB fat32_nextcluster+2
    INV zp_h_address
    LDT zp_h_address
    STB fat32_nextcluster+3

    AIV 5,zp_h_address                  ; zp_sd_address+26
    LDT zp_h_address
    STB fat32_nextcluster
    INV zp_h_address
    LDT zp_h_address
    STB fat32_nextcluster+1

    ; Remember file size in bytes remaining zp_sd_address+28
    INV zp_h_address
    LDT zp_h_address
    STB fat32_bytesremaining+0
    INV zp_h_address
    LDT zp_h_address
    STB fat32_bytesremaining+1
    INV zp_h_address
    LDT zp_h_address
    STB fat32_bytesremaining+2
    INV zp_h_address
    LDT zp_h_address
    STB fat32_bytesremaining+3

    ; Begin Debug
    ;JPS _Print "File Size:",0
    ;LDB fat32_bytesremaining+3 JAS _PrintHex
    ;LDB fat32_bytesremaining+2 JAS _PrintHex
    ;LDB fat32_bytesremaining+1 JAS _PrintHex
    ;LDB fat32_bytesremaining+0 JAS _PrintHex
    ;JPS _Print 10,0
    ;JPS _WaitInput
    ; End Debug

    JPS fat32_seekcluster

    ; Set the pointer to a large value so we always read a sector the first time through
    MIZ 0xff,zp_sd_address+1

    RTS
; ----------------------------------------------
; |               End Opendirent               |
; ----------------------------------------------
; ----------------------------------------------
; |              Begin Readdirent              |
; ----------------------------------------------
fat32_readdirent:
    ; Read a directory entry from the open directory
    ;
    ; On exit the carry is set if there were no more directory entries.
    ;
    ; Otherwise, A is set to the file''s attribute byte and
    ; zp_sd_address points at the returned directory entry.
    ; LFNs and empty entries are ignored automatically.

    ; Increment pointer by 32 to point to next entry
    ; clc zp_sd_address = zp_sd_address + 32
    LDZ zp_sd_address           ; A = (zp_sd_address)
    ADI 32                      ; A = A + 32
    STZ zp_sd_address           ; (zp_sd_address) = A
    LDZ zp_sd_address+1         ; A = (zp_sd_address+1)
    ACI 0                       ; A = A + 0 + C
    STZ zp_sd_address+1         ; (zp_sd_address+1) = A

    ; If it''s not at the end of the buffer, we have data already
    CPI 0x32                    ; CPI >(fat32_readbuffer+0x0200) -> 0x3000+0x0200=0x3200  #org 0x3000 fat32_readbuffer: ; 512
    BCC gotdata                 ; noch Daten im Puffer

    ; Read another sector
    MIW fat32_readbuffer,fat32_address   ; word(fat32_address) = fat32_readbuffer

    JPS fat32_readnextsector
    BCC gotdata

endofdirectory:
    SEC
    RTS

gotdata:
    ; Check first character
    LDT zp_sd_address                     ; A = *(zp_sd_address)
    CPI 0x00                              ; 0x00 identifier for end directory
    ; End of directory => abort
    BEQ endofdirectory

    ; Empty entry => start again
    CPI 0xe5
    BEQ fat32_readdirent

    ; Check attributes
    MVV zp_sd_address,zp_h_address
    AIV 11,zp_h_address                   ; 0..10 = 11 character filename, 11 = Flag
    LDT zp_h_address                      ; lda (zp_sd_address),y y=11
    ANI 0x3f                              ; Attribute 0x00111111 bit 6 & 7 unused
    CPI 0x0f                              ; LFN => start again
    BEQ fat32_readdirent

    ; Yield this result
    CLC
    RTS
; ----------------------------------------------
; |               End Readdirent               |
; ----------------------------------------------

; ----------------------------------------------
; |              Begin Finddirent              |
; ----------------------------------------------
fat32_finddirent:
    ; Finds a particular directory entry.  X,Y point to the 11-character filename to seek.
    ; The directory should already be open for iteration.

    ; Form ZP pointer to user''s filename
    LDZ RegX STB fat32_filenamepointer      ;stx fat32_filenamepointer
    LDZ RegY STB fat32_filenamepointer+1    ;sty fat32_filenamepointer+1
    ; Iterate until name is found or end of directory
direntloop:
    JPS fat32_readdirent
    BCC comparenameloop1
    RTS                                                 ; with carry set
comparenameloop1:
    MZB zp_sd_address+0,comparenameloop+1 MZB zp_sd_address+1,comparenameloop+2
    MBB fat32_filenamepointer+0,comparenameloop+3 MBB fat32_filenamepointer+1,comparenameloop+4
    MIZ 10,RegY
comparenameloop:
    CBB 0x8000,0x9000
    BNE direntloop
    INW comparenameloop+1   INW comparenameloop+3
    DEZ RegY                                            ;dey
    BPL comparenameloop
    ; Found it
    CLC
    RTS
; ----------------------------------------------
; |               End Finddirent               |
; ----------------------------------------------
; ----------------------------------------------
; |            Begin File read Byte            |
; ----------------------------------------------
fat32_file_readbyte:
    ; Read a byte from an open file
    ; The byte is returned in A with C clear; or if end-of-file was reached, C is set instead

    ; Is there any data to read at all?
    LDB fat32_bytesremaining
    ORB fat32_bytesremaining+1
    ORB fat32_bytesremaining+2
    ORB fat32_bytesremaining+3
    CPI 0x00
    BEQ rts1C

    ; Decrement the remaining byte count fat32_bytesremaining--
    DEW fat32_bytesremaining
    LDB fat32_bytesremaining
    ORB fat32_bytesremaining+1
    CPI 0x00
    BNE continue
    LDB fat32_bytesremaining+2
    ORB fat32_bytesremaining+3
    BEQ continue
    DEW fat32_bytesremaining+2
continue:
    ; Need to read a new sector?
    LDZ zp_sd_address+1 ;lda zp_sd_address+1
    CPI 0x32            ;cmp #>(fat32_readbuffer+$200) CPI >(fat32_readbuffer+0x0200) -> #org 0x3000 fat32_readbuffer:   ; 512
    BCC gotdata1

    ; Read another sector
    MIW fat32_readbuffer,fat32_address
    JPS fat32_readnextsector
    BCS rts1C                 ; this shouldn't happen

gotdata1:
    LDT zp_sd_address
    PHS INV zp_sd_address PLS
    CLC
    RTS
rts1C:
    SEC
    RTS
; ----------------------------------------------
; |             End File read Byte             |
; ----------------------------------------------
; ----------------------------------------------
; |              Begin File read               |
; ----------------------------------------------
fat32_file_read:
    ; Read a whole file into memory.  It's assumed the file has just been opened
    ; and no data has been read yet.
    ;
    ; Also we read whole sectors, so data in the target region beyond the end of the
    ; file may get overwritten, up to the next 512-byte boundary.
    ;
    ; And we don't properly support 64k+ files, as it's unnecessary complication given
    ; the 6502's small address space

    ; Round the size up to the next whole sector
    LDB fat32_bytesremaining
    CPI 1                           ;cmp #1                      ; set carry if bottom 8 bits not zero
    LDB fat32_bytesremaining+1
    ACI 0                           ;adc #0                      ; add carry, if any
    LR1                             ;lsr                         ; divide by 2
    ACI 0                           ;adc #0                      ; round up
    ; No data?
    BEQ done

    ; Store sector count - not a byte count any more
    STB sectorCNT
    ; Read entire sectors to the user-supplied buffer
wholesectorreadloop:
    ; Read a sector to fat32_address
    JPS fat32_readnextsector
    ; Advance fat32_address by 512 bytes
    INB fat32_address+1
    INB fat32_address+1
    DEB sectorCNT       ; note - actually stores sectors remaining
    BNE wholesectorreadloop
done:
    RTS
sectorCNT: 0x00
; ----------------------------------------------
; |                End File read               |
; ----------------------------------------------
; ----------------------------------------------
; |           Begin writeSingleBlock           |
; ----------------------------------------------
; Input: zp_sd_currentsector = Sectornumber
;        zp_sd_address = Pointer to 512 byte data buffer
; Return:
; token = 0x00 - busy timeout
; token = 0x05 - data accepted
; token = 0xFF - response timeout
;SD_writeSingleBlock:
;
;    MIB 0xff,token                      ; token = 0xff
;    MIB 0xff,spi NOP                    ; enable /CS sd card
;    LDI 0x01 STB hc173
;    MIB 0xff,spi NOP
;
;    JPS SD_CMD24                        ; send CMD24
;    JPS SD_readRes1                     ; read result
;    CPI 0x00
;    BNE SD_writeSingleBlockE            ; no result end
;
;    MIB 0xfe,spi NOP                    ; send start token
;
;    MIV 512, Z1                         ; read 512 byte block
;SD_writeSingleBlock3:
;    LDT zp_sd_address STB spi NOP ;LDB spi
;    INV zp_sd_address DEV Z1
;    BNE SD_writeSingleBlock3
;    CZZ Z1, Z1+1
;    BNE SD_writeSingleBlock3
;    ; fertig block schreiben
;
;    ; wait for a response (timeout = 250ms)
;    MIV 45455, Z1                       ; SD_MAX_READ_ATTEMPTS 250ms -> 250 / 0,0055 = 45455
;SD_writeSingleBlock1:
;    MIB 0xff,spi NOP LDB spi            ; 6 + 16 + 5 = 27 (52)
;    CPI 0xff                            ; 3
;    BNE SD_writeSingleBlock2            ; 4/3 -> 3 (Answer is there)
;    DEV Z1                              ; 7
;    BNE SD_writeSingleBlock1            ; 4/3 -> 4 + 7 + 3 + 3 + 27 = 44 * 0,125µs = 5,5 µs
;    CZZ Z1, Z1+1
;    BNE SD_writeSingleBlock1
;    ; time exceeded
;    LDI 0xff STB buffer+0
;    JPA SD_writeSingleBlockE
;
;SD_writeSingleBlock2:
;    ANI 0x1f CPI 0x05                   ; if data accepted
;    STB token
;    BNE SD_writeSingleBlockE            ; no
;
;    ; wait for a response (timeout = 250ms), data accepted wait for write to finish
;    MIV 45455, Z1                       ; SD_MAX_READ_ATTEMPTS 250ms -> 250 / 0,0055 = 45455
;SD_writeSingleBlock4:
;    MIB 0xff,spi NOP LDB spi            ; 6 + 16 + 5 = 27
;    CPI 0x00                            ; 3
;    BNE SD_writeSingleBlock5            ; 4/3 -> 3 (Answer is there)
;    DEV Z1                              ; 7
;    BNE SD_writeSingleBlock4            ; 4/3 -> 4 + 7 + 3 + 3 + 27 = 44 * 0,125µs = 5,5 µs
;    CZZ Z1, Z1+1
;    BNE SD_writeSingleBlock4
;    LDI 0x00 STB token                  ; busy timeout
;    JPA SD_writeSingleBlockE
;SD_writeSingleBlock5:
;SD_writeSingleBlockE:
;    PHS
;    MIB 0xff,spi NOP
;    LDI 0x00 STB hc173
;    MIB 0xff,spi NOP
;    PLS
;
;    RTS
; ----------------------------------------------
; |            End writeSingleBlock            |
; ----------------------------------------------

; ----------------------------------------------
; |              Begin Readsector              |
; ----------------------------------------------
; Input: zp_sd_currentsector = Sectornumber
;        zp_sd_address = Pointer to 512 byte data buffer
; Return:
; token = 0xFE - Successful read
; token = 0x0X - Data error
; token = 0xFF - timeout

sd_readsector:
    ;; debug ####
    ;JPS _Print "Read Sector: ",0
    ;LDZ zp_sd_currentsector+3 JAS _PrintHex
    ;LDZ zp_sd_currentsector+2 JAS _PrintHex
    ;LDZ zp_sd_currentsector+1 JAS _PrintHex
    ;LDZ zp_sd_currentsector+0 JAS _PrintHex
    ;;JPS _WaitInput
    ;JPS _Print 10,0
    ;; debug end

    MIB 0xff,token                      ; token = 0xff
    JPS cs1on
    JPS SD_CMD17                        ; send CMD17
    JPS SD_readRes1                     ; read result
    CPI 0xff
    BEQ SD_readSingleBlockErr1          ; no result end
    ; wait maximum 100ms for data start
    MIV 18182, Z1                       ; SD_MAX_READ_ATTEMPTS 100ms -> 100 / 0,0055 = 18182
SD_readSingleBlock1:
    MIB 0xff,spi NOP LDB spi            ; 6 + 16 + 5 = 27
    CPI 0xff                            ; 3
    BNE SD_readSingleBlock2             ; 4/3 -> 3 (Answer is there)
    DEV Z1                              ; 7
    BNE SD_readSingleBlock1             ; 4/3 4 + 7 + 3 + 3 + 27 = 44 * 0,125µs = 5,5 µs
    CZZ Z1, Z1+1
    BNE SD_readSingleBlock1
    LDI 0xff STB buffer+0
    JPA SD_readSingleBlockE

SD_readSingleBlock2:
    CPI 0xfe                            ; 0xfe for data start
    BNE SD_readSingleBlockE
    STB token
    MIV 512, Z1                         ; read 512 byte block
    MVV zp_sd_address,save
SD_readSingleBlock3:
    MIB 0xff,spi NOP LDB spi
    STT zp_sd_address
    INV zp_sd_address DEV Z1
    BNE SD_readSingleBlock3
    CZZ Z1, Z1+1
    BNE SD_readSingleBlock3
    MVV save,zp_sd_address

    MIB 0xff,spi NOP                    ; read 16-bit CRC
    LDB spi STB crc16+1
    MIB 0xff,spi NOP
    LDB spi STB crc16+0

    LDB buffer+0                        ; return value
SD_readSingleBlockE:
    PHS JPS cs1off PLS
    RTS
SD_readSingleBlockErr1:
    PHS JAS _PrintHex JPS _Print " CMD17 Error", 10, 0 PLS
    JPA SD_readSingleBlockE
; ----------------------------------------------
; |                End Readsector              |
; ----------------------------------------------
; ----------------------------------------------
; |           Begin Init SPI SD Card           |
; ----------------------------------------------
SD_init:
    JPS SD_powerUpSeq

    MIZ 10,Z2
SD_init1:
    JPS SD_goIdleState              ; CMD0
    LDB buffer+0 CPI 0x01
    BEQ SD_init2
    DEZ Z2
    BNE SD_init1
SD_Err:
    LDI 1                           ; SD_ERROR
    RTS
SD_init2:
    JPS SD_sendIfCond               ; CMD8
    LDB buffer+0 CPI 0x01
    BNE SD_Err
    LDB buffer+4 CPI 0xaa
    BNE SD_Err

    MIZ 100,Z2                      ; attempt to initialize card
SD_init3:
    JPS SD_sendApp                  ; CMD55
    LDB buffer+0 ANI 0xfe CPI 0x00  ; 0x00 or 0x01 is successful
    BNE SD_init4
    JPS SD_sendOpCond               ; ACMD41
SD_init4:
    LDI 10 JAS delay_ms             ; wait 10ms
    LDB buffer+0 CPI 0x00
    BEQ SD_init5
    DEZ Z2
    BNE SD_init3                    ; Next try
    JPA SD_Err
SD_init5:
    JPS SD_readOCR                  ; CMD58
    LDB buffer+1 ANI 0x80 CPI 0x00
    BEQ SD_Err
    LDI 0x00                        ; sd card successfully initialized
    RTS
; ----------------------------------------------
; |            End Init SPI SD Card            |
; ----------------------------------------------
; ----------------------------------------------
SD_readRes1:
    MIZ 8, Z0
SD_read1:
    MIB 0xff,spi NOP LDB spi
    CPI 0xff
    BNE SD_read2
    DEZ Z0
    BNE SD_read1
    LDI 0xff
SD_read2:
    STB buffer+0
    RTS
; ----------------------------------------------
SD_readRes7:
    JPS SD_readRes1
    LDB buffer+0 ANI 0xfe CPI 0x00
    BNE SD_readRes7a
    MIB 0xff,spi NOP LDB spi STB buffer+1
    MIB 0xff,spi NOP LDB spi STB buffer+2
    MIB 0xff,spi NOP LDB spi STB buffer+3
    MIB 0xff,spi NOP LDB spi STB buffer+4
SD_readRes7a:
    RTS
; ----------------------------------------------
SD_CMD0:
    MIV cmd0,zp_sd_address JPA SD_command
SD_CMD8:
    MIV cmd8,zp_sd_address JPA SD_command
SD_CMD58:
    MIV cmd58,zp_sd_address JPA SD_command
SD_CMD55:
    MIV cmd55,zp_sd_address JPA SD_command
SD_ACMD41:
    MIV ACMD41,zp_sd_address JPA SD_command
SD_CMD16:
    MIV cmd16,zp_sd_address JPA SD_command
; ----------------------------------------------
; *zp_sd_address Command 6 byte (1 byte CMD, 4 byte Argument, 1 byte CRC)
SD_command:
    MIZ 6, Z0
sCMD1:
    LDT zp_sd_address
    STB spi NOP
    INV zp_sd_address
    DEZ Z0
    BNE sCMD1
    RTS
; ----------------------------------------------
SD_CMD17:
    MIB 0x51,spi NOP
    ; Sector Number
    LDZ zp_sd_currentsector+3 STB spi NOP
    LDZ zp_sd_currentsector+2 STB spi NOP
    LDZ zp_sd_currentsector+1 STB spi NOP
    LDZ zp_sd_currentsector+0 STB spi NOP
    MIB 0x01,spi NOP
    RTS
; ----------------------------------------------
SD_CMD24:
    MIB 0x58,spi NOP
    ; Sector Number
    LDB zp_sd_currentsector+3 STB spi NOP
    LDB zp_sd_currentsector+2 STB spi NOP
    LDB zp_sd_currentsector+1 STB spi NOP
    LDB zp_sd_currentsector+0 STB spi NOP
    MIB 0x01,spi NOP
    RTS
; ----------------------------------------------
SD_goIdleState:
    JPS cs1on
    JPS SD_CMD0
    JPS SD_readRes1
    JPS cs1off
    RTS
; ----------------------------------------------
; CMD55 initiates an application-specific command
SD_sendApp:
    JPS cs1on
    JPS SD_CMD55
    JPS SD_readRes1
    JPS cs1off
    RTS
; ----------------------------------------------
; ACMD41 - SD_SEND_OP_COND (send operating condition)
SD_sendOpCond:
    JPS cs1on
    JPS SD_ACMD41
    JPS SD_readRes1
    JPS cs1off
    RTS
; ----------------------------------------------
; CMD58 - read OCR (operation conditions register)
SD_readOCR:
    JPS cs1on
    JPS SD_CMD58
    JPS SD_readRes7
    JPS cs1off
    RTS
; ----------------------------------------------
; CMD8 - SEND_IF_COND (send interface condition)
SD_sendIfCond:
    JPS cs1on
    JPS SD_CMD8
    JPS SD_readRes7
    JPS cs1off
    RTS
; ----------------------------------------------
; buffer for writing and reading commands from the SD card
buffer: 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
token:  0x00
crc16:  0x00, 0x00
; command pattern
; CMD = number | 0x40
; last byte CRC7 | 0x01
cmd0:   0x40, 0x00, 0x00, 0x00, 0x00, 0x95
cmd8:   0x48, 0x00, 0x00, 0x01, 0xaa, 0x87
cmd58:  0x7a, 0x00, 0x00, 0x00, 0x00, 0x75
cmd55:  0x77, 0x00, 0x00, 0x00, 0x00, 0x01
ACMD41: 0x69, 0x40, 0x00, 0x00, 0x00, 0x01
cmd16:  0x50, 0x00, 0x00, 0x02, 0x00, 0x01

fat32_fatstart: 0x00, 0x00, 0x00, 0x00          ; 4 bytes
fat32_datastart: 0x00, 0x00, 0x00, 0x00         ; 4 bytes
fat32_rootcluster: 0x00, 0x00, 0x00, 0x00       ; 4 bytes
fat32_sectorspercluster: 0x00                   ; 1 byte
fat32_pendingsectors: 0x00                      ; 1 byte
fat32_address: 0x00, 0x00                       ; 2 bytes
fat32_nextcluster: 0x00, 0x00, 0x00, 0x00       ; 4 bytes
fat32_errorstage:                               ; only used during initializatio
fat32_filenamepointer:                          ; only used when searching for a file
fat32_bytesremaining: 0x00, 0x00, 0x00, 0x00    ; 4 bytes
entries: 0x00
dir_ptr: 0x00, 0x00

printVolumeLabel:
    JPS _Print
strVolumeLabel:
    "           ", 10, 0
    RTS



#mute
#org 0x3000 sBuf:               ; 512 0x3000..0x31FF
#org 0x3000 fat32_readbuffer:   ; 512
#org 0x3000 fat32_workspace:    ; 512
#org 0x3800 list_buffer:        ; 512/
#org 0x8000 buffer2:
#org 0x8000 dirbuf:

#org 0x0000
regA:   0x00,
regB:   0x00,
save:
RegX:   0x00,
RegY:   0x00,
Z0:     0x00,
Z1:     0x0000,
Z2:     0x00,
Z3:     0x00,
counter:
tmp:    0x00,


zp_sd_address: 0x00, 0x00                       ; 2 bytes
zp_sd_currentsector: 0x00, 0x00, 0x00, 0x00     ; 4 bytes -> CMD17, CMD24
zp_h_address: 0x00, 0x00

#org 0xfee0 sn76489:    ; SN76489 data port (4HC574)
#org 0xfee1 vsync:      ; 4HC574 input Kempston vsync
#org 0xfee2 hc173:      ; bit 0 = 1 -> /CS = 0 | bit 0 = 0 -> /CS = 1
#org 0xfee3 spi:        ; address for reading and writing the spi shift register, writing starts the beat

#org 0x0001 _CS_ON:     ; /CS sd card on
#org 0x0000 _CS_OFF:    ; /CS sd card off
#org 0x0018 _LINES:     ; 25 = 0x19

; MinOS API definitions generated by 'asm os.asm -s_'
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
#org 0xf048 _PrintPtr:
#org 0xf04b _PrintHex:
#org 0xf04e _SetPixel:
#org 0xf051 _Line:
#org 0xf054 _Rect:

#org 0x00c0 _XPos:
#org 0x00c1 _YPos:
#org 0x00c2 _RandomState:
#org 0x00c6 _ReadNum:
#org 0x00c9 _ReadPtr:
#org 0x00cd _ReadBuffer:
