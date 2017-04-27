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
LIBS:grant6-cache
EELAYER 25 0
EELAYER END
$Descr User 7200 4000
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
P 3800 1100
F 0 "U?" H 3950 1400 50  0001 C CNN
F 1 "Arbiter" H 3950 1100 50  0000 C CNN
F 2 "" H 3800 1100 50  0000 C CNN
F 3 "" H 3800 1100 50  0000 C CNN
	1    3800 1100
	1    0    0    -1  
$EndComp
Text GLabel 900  1750 0    60   Input ~ 0
RDMGI
Text GLabel 1150 900  0    60   Input ~ 0
bus_request
Text GLabel 950  3000 0    60   Input ~ 0
RINIT
Text GLabel 1250 3200 0    60   Input ~ 0
cycle_finished
Wire Wire Line
	2800 3100 3800 3100
Wire Wire Line
	3800 3100 4000 3100
Wire Wire Line
	4000 3100 5250 3100
Wire Wire Line
	3800 3100 3800 1650
Wire Wire Line
	3200 900  1150 900 
Wire Wire Line
	950  3000 1600 3000
Wire Wire Line
	1250 3200 1600 3200
Text GLabel 6200 1900 2    60   Output ~ 0
TDMGO
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
Text GLabel 5850 900  2    60   Output ~ 0
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
	900  2600 1000 2600
Wire Wire Line
	1000 2600 2300 2600
Wire Wire Line
	1000 1950 1000 2600
Connection ~ 1000 2600
Text GLabel 900  2600 0    60   Input ~ 0
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
	950  1100 3200 1100
Connection ~ 950  1750
$Comp
L 74HC74 U?
U 1 1 584098E5
P 5100 1100
F 0 "U?" H 5250 1400 50  0001 C CNN
F 1 "Latch" H 5250 1100 50  0000 C CNN
F 2 "" H 5100 1100 50  0000 C CNN
F 3 "" H 5100 1100 50  0000 C CNN
	1    5100 1100
	1    0    0    -1  
$EndComp
Wire Wire Line
	4500 900  4400 900 
Connection ~ 3800 3100
Wire Wire Line
	4500 1100 4500 1750
Wire Wire Line
	4500 1750 4500 2100
Wire Wire Line
	5850 900  5700 900 
Wire Wire Line
	3500 1750 4500 1750
$Comp
L 74HC74 U?
U 1 1 58FE06A7
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
U 1 1 58FE0A3C
P 5250 2100
F 0 "U?" H 5400 2400 50  0001 C CNN
F 1 "Latch" H 5400 2100 50  0000 C CNN
F 2 "" H 5250 2100 50  0000 C CNN
F 3 "" H 5250 2100 50  0000 C CNN
	1    5250 2100
	1    0    0    -1  
$EndComp
Wire Wire Line
	4500 2100 4650 2100
Connection ~ 4500 1750
Wire Wire Line
	4400 1300 4600 1300
Wire Wire Line
	4600 1300 4600 1900
Wire Wire Line
	4600 1900 4650 1900
Wire Wire Line
	5850 1900 6200 1900
Wire Wire Line
	5100 1650 4000 1650
Wire Wire Line
	4000 1650 4000 3100
Wire Wire Line
	5250 3100 5250 2650
Connection ~ 4000 3100
$EndSCHEMATC
