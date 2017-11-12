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
LIBS:grant2-cache
EELAYER 25 0
EELAYER END
$Descr User 6000 4000
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L 74HC74 U?
U 1 1 583F2E2D
P 2850 1100
F 0 "U?" H 3000 1400 50  0001 C CNN
F 1 "Arbiter" H 2950 1100 50  0000 C CNN
F 2 "" H 2850 1100 50  0000 C CNN
F 3 "" H 2850 1100 50  0000 C CNN
	1    2850 1100
	1    0    0    -1  
$EndComp
Text GLabel 1450 1600 0    60   Input ~ 0
RIAKI
Text GLabel 1400 900  0    60   Input ~ 0
irql
Text GLabel 1450 1900 0    60   Input ~ 0
RINIT
Wire Wire Line
	2850 1900 2850 1650
$Comp
L 74LS08 U?
U 1 1 583F30C7
P 4150 1500
F 0 "U?" H 4150 1550 50  0001 C CNN
F 1 "74LS08" H 4150 1450 50  0001 C CNN
F 2 "" H 4150 1500 50  0000 C CNN
F 3 "" H 4150 1500 50  0000 C CNN
	1    4150 1500
	1    0    0    -1  
$EndComp
Wire Wire Line
	2250 900  1400 900 
Wire Wire Line
	1450 1900 1750 1900
Text GLabel 4850 1500 2    60   Output ~ 0
TIAKO
Wire Wire Line
	4850 1500 4750 1500
Wire Wire Line
	1450 1600 3550 1600
Wire Wire Line
	3450 1300 3550 1300
Wire Wire Line
	3550 1300 3550 1400
Wire Wire Line
	2250 1100 1450 1100
Text GLabel 4500 900  2    60   Output ~ 0
interrupt_mine
Wire Wire Line
	4500 900  3450 900 
Text GLabel 1450 1100 0    60   Input ~ 0
RDIN
$Comp
L 74HC04 U?
U 1 1 584046D4
P 2200 1900
F 0 "U?" H 2350 2000 50  0001 C CNN
F 1 "74HC04" H 2400 1800 50  0001 C CNN
F 2 "" H 2200 1900 50  0000 C CNN
F 3 "" H 2200 1900 50  0000 C CNN
	1    2200 1900
	1    0    0    -1  
$EndComp
Wire Wire Line
	2650 1900 2850 1900
$EndSCHEMATC
