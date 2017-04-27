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
LIBS:grant4-cache
EELAYER 25 0
EELAYER END
$Descr User 6500 4000
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
P 3600 1050
F 0 "U?" H 3750 1350 50  0001 C CNN
F 1 "Arbiter" H 3750 1050 50  0000 C CNN
F 2 "" H 3600 1050 50  0000 C CNN
F 3 "" H 3600 1050 50  0000 C CNN
	1    3600 1050
	1    0    0    -1  
$EndComp
Text GLabel 800  1550 0    60   Input ~ 0
RDMGI
Text GLabel 1050 850  0    60   Input ~ 0
bus_request
Text GLabel 750  2650 0    60   Input ~ 0
RINIT
Text GLabel 1150 2850 0    60   Input ~ 0
cycle_finished
Wire Wire Line
	2700 2750 3600 2750
Wire Wire Line
	3600 2750 3600 1600
$Comp
L 74LS08 U?
U 1 1 583F30C7
P 4900 1450
F 0 "U?" H 4900 1500 50  0001 C CNN
F 1 "74LS08" H 4900 1400 50  0001 C CNN
F 2 "" H 4900 1450 50  0000 C CNN
F 3 "" H 4900 1450 50  0000 C CNN
	1    4900 1450
	1    0    0    -1  
$EndComp
Wire Wire Line
	3000 850  1050 850 
Wire Wire Line
	750  2650 1500 2650
Wire Wire Line
	1150 2850 1500 2850
Text GLabel 5600 1450 2    60   Output ~ 0
TDMGO
Wire Wire Line
	5600 1450 5500 1450
Wire Wire Line
	4200 1250 4300 1250
Wire Wire Line
	4300 1250 4300 1350
$Comp
L 74HC02 U?
U 1 1 583F32EF
P 2100 2750
F 0 "U?" H 2100 2800 50  0001 C CNN
F 1 "74HC02" H 2150 2700 50  0001 C CNN
F 2 "" H 2100 2750 50  0000 C CNN
F 3 "" H 2100 2750 50  0000 C CNN
	1    2100 2750
	1    0    0    -1  
$EndComp
Text GLabel 5250 850  2    60   Output ~ 0
won_arbitration
Wire Wire Line
	5250 850  4200 850 
$Comp
L 74HC74 U?
U 1 1 583F4794
P 2800 1750
F 0 "U?" H 2950 2050 50  0001 C CNN
F 1 "delay" H 2950 1750 50  0000 C CNN
F 2 "" H 2800 1750 50  0000 C CNN
F 3 "" H 2800 1750 50  0000 C CNN
	1    2800 1750
	1    0    0    -1  
$EndComp
$Comp
L 74HC74 U?
U 1 1 583F47C8
P 1500 1750
F 0 "U?" H 1650 2050 50  0001 C CNN
F 1 "delay" H 1650 1750 50  0000 C CNN
F 2 "" H 1500 1750 50  0000 C CNN
F 3 "" H 1500 1750 50  0000 C CNN
	1    1500 1750
	1    0    0    -1  
$EndComp
Wire Wire Line
	2200 2400 2200 1750
Wire Wire Line
	700  2400 900  2400
Wire Wire Line
	900  2400 2200 2400
Wire Wire Line
	900  1750 900  2400
Connection ~ 900  2400
Text GLabel 700  2400 0    60   Input ~ 0
CLK
Wire Wire Line
	800  1550 850  1550
Wire Wire Line
	850  1550 900  1550
Wire Wire Line
	2100 1550 2200 1550
Wire Wire Line
	3400 1550 4300 1550
Wire Wire Line
	850  1550 850  1050
Wire Wire Line
	850  1050 3000 1050
Connection ~ 850  1550
$EndSCHEMATC
