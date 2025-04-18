# Minimal-64x4-Expansion Software

## initexpansion
Sets the extension to the basic state. Mutes the audio output and lets the two LEDs flash once to indicate initialization.

To ensure that this starts automatically after a reset, a file named "autostart" must be created in the flash memory. The name of the init program must be entered in the autostart file.

## player
An interactive experimental browser for the SD card. An SD card can be browsed. VGC audio files are selected with <ENTER> and played via the SN76489. The remaining files are currently only displayed with their names.

Currently only SD cards of type 2 with FAT32 are supported. Support for type 1 is also planned. FAT12/16 support is not currently planned.

The sd-card.zip file contains some sample VGC files. The contents can be unpacked onto an SD card and then browsed on Minimal using the "player" program. Selecting a VGC file with "Enter" will play it on the SN76489 sound chip.

## timer
Test for a counter hh:mm:ss with the vsync signal.

## SN76489

The SN76489 folder contains some examples for testing the SN76489. The examples are taken from older BASIC programs.

## Joystick

The joystick port can be tested using the "test-joystick" program. I did this with a C64 joystick.

