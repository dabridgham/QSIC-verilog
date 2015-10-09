EESchema Schematic File Version 2
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:myLib
LIBS:qsic-cache
EELAYER 25 0
EELAYER END
$Descr USLedger 17000 11000
encoding utf-8
Sheet 1 2
Title "QSIC"
Date "2015-10-01"
Rev "0.1"
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Sheet
S 11550 3900 900  2350
U 560E637A
F0 "drivers" 60
F1 "drivers.sch" 60
$EndSheet
$Comp
L PWR_FLAG #FLG01
U 1 1 56137D79
P 15350 6350
F 0 "#FLG01" H 15350 6445 50  0001 C CNN
F 1 "PWR_FLAG" H 15350 6530 50  0000 C CNN
F 2 "" H 15350 6350 60  0000 C CNN
F 3 "" H 15350 6350 60  0000 C CNN
	1    15350 6350
	1    0    0    -1  
$EndComp
$Comp
L PWR_FLAG #FLG02
U 1 1 56137D87
P 15800 6350
F 0 "#FLG02" H 15800 6445 50  0001 C CNN
F 1 "PWR_FLAG" H 15800 6530 50  0000 C CNN
F 2 "" H 15800 6350 60  0000 C CNN
F 3 "" H 15800 6350 60  0000 C CNN
	1    15800 6350
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR03
U 1 1 56137DA4
P 15350 6350
F 0 "#PWR03" H 15350 6200 50  0001 C CNN
F 1 "+5V" H 15350 6490 50  0000 C CNN
F 2 "" H 15350 6350 60  0000 C CNN
F 3 "" H 15350 6350 60  0000 C CNN
	1    15350 6350
	-1   0    0    1   
$EndComp
$Comp
L GND #PWR04
U 1 1 56137DB2
P 15800 6350
F 0 "#PWR04" H 15800 6100 50  0001 C CNN
F 1 "GND" H 15800 6200 50  0000 C CNN
F 2 "" H 15800 6350 60  0000 C CNN
F 3 "" H 15800 6350 60  0000 C CNN
	1    15800 6350
	1    0    0    -1  
$EndComp
$EndSCHEMATC
