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
LIBS:grant5-cache
EELAYER 25 0
EELAYER END
$Descr User 9300 4000
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
P 4900 1100
F 0 "U?" H 5050 1400 50  0001 C CNN
F 1 "Arbiter" H 5050 1100 50  0000 C CNN
F 2 "" H 4900 1100 50  0000 C CNN
F 3 "" H 4900 1100 50  0000 C CNN
	1    4900 1100
	1    0    0    -1  
$EndComp
Text GLabel 900  1750 0    60   Input ~ 0
RDMGI
Text GLabel 1150 900  0    60   Input ~ 0
bus_request
Text GLabel 850  3000 0    60   Input ~ 0
RINIT
Text GLabel 1250 3200 0    60   Input ~ 0
cycle_finished
Wire Wire Line
	2800 3100 4900 3100
Wire Wire Line
	4900 3100 6200 3100
Wire Wire Line
	4900 3100 4900 1650
$Comp
L 74LS08 U?
U 1 1 583F30C7
P 7500 1650
F 0 "U?" H 7500 1700 50  0001 C CNN
F 1 "74LS08" H 7500 1600 50  0001 C CNN
F 2 "" H 7500 1650 50  0000 C CNN
F 3 "" H 7500 1650 50  0000 C CNN
	1    7500 1650
	1    0    0    -1  
$EndComp
Wire Wire Line
	4300 900  1150 900 
Wire Wire Line
	850  3000 1600 3000
Wire Wire Line
	1250 3200 1600 3200
Text GLabel 8200 1650 2    60   Output ~ 0
TDMGO
Wire Wire Line
	8200 1650 8100 1650
$Comp
L 74HC02 U?
U 1 1 583F32EF
P 2200 3100
F 0 "U?" H 2200 3150 50  0001 C CNN
F 1 "74HC02" H 2250 3050 50  0001 C CNN
F 2 "" H 2200 3100 50  0000 C CNN
F 3 "" H 2200 3100 50  0000 C CNN
	1    2200 3100
	1    0    0    -1  
$EndComp
Text GLabel 7800 900  2    60   Output ~ 0
won_arbitration
$Comp
L 74HC74 U?
U 1 1 583F47C8
P 1600 1950
F 0 "U?" H 1750 2250 50  0001 C CNN
F 1 "delay" H 1750 1950 50  0000 C CNN
F 2 "" H 1600 1950 50  0000 C CNN
F 3 "" H 1600 1950 50  0000 C CNN
	1    1600 1950
	1    0    0    -1  
$EndComp
Wire Wire Line
	2300 2600 2300 1950
Wire Wire Line
	800  2600 1000 2600
Wire Wire Line
	1000 2600 2300 2600
Wire Wire Line
	2300 2600 3600 2600
Wire Wire Line
	1000 1950 1000 2600
Connection ~ 1000 2600
Text GLabel 800  2600 0    60   Input ~ 0
CLK
Wire Wire Line
	900  1750 950  1750
Wire Wire Line
	950  1750 1000 1750
Wire Wire Line
	2200 1750 2300 1750
Wire Wire Line
	950  1750 950  1100
Wire Wire Line
	950  1100 4300 1100
Connection ~ 950  1750
Wire Wire Line
	6800 1300 6800 1550
Wire Wire Line
	6800 1550 6900 1550
$Comp
L 74HC74 U?
U 1 1 584098E5
P 6200 1100
F 0 "U?" H 6350 1400 50  0001 C CNN
F 1 "Latch" H 6350 1100 50  0000 C CNN
F 2 "" H 6200 1100 50  0000 C CNN
F 3 "" H 6200 1100 50  0000 C CNN
	1    6200 1100
	1    0    0    -1  
$EndComp
Wire Wire Line
	5600 900  5500 900 
Wire Wire Line
	6200 3100 6200 1650
Connection ~ 4900 3100
Wire Wire Line
	3500 1750 3550 1750
Wire Wire Line
	3550 1750 3600 1750
Wire Wire Line
	3550 1750 3550 1600
Wire Wire Line
	3550 1600 5600 1600
Wire Wire Line
	5600 1600 5600 1100
Connection ~ 3550 1750
Wire Wire Line
	3600 2600 3600 1950
Connection ~ 2300 2600
Wire Wire Line
	7800 900  6800 900 
Wire Wire Line
	4800 1750 6900 1750
$Comp
L 74HC74 U?
U 1 1 58FE05E9
P 2900 1950
F 0 "U?" H 3050 2250 50  0001 C CNN
F 1 "delay" H 3050 1950 50  0000 C CNN
F 2 "" H 2900 1950 50  0000 C CNN
F 3 "" H 2900 1950 50  0000 C CNN
	1    2900 1950
	1    0    0    -1  
$EndComp
$Comp
L 74HC74 U?
U 1 1 58FE05F4
P 4200 1950
F 0 "U?" H 4350 2250 50  0001 C CNN
F 1 "delay" H 4350 1950 50  0000 C CNN
F 2 "" H 4200 1950 50  0000 C CNN
F 3 "" H 4200 1950 50  0000 C CNN
	1    4200 1950
	1    0    0    -1  
$EndComp
$EndSCHEMATC
