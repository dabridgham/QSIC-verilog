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
LIBS:qint3-cache
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
P 2750 2200
F 0 "U?" H 2900 2500 50  0001 C CNN
F 1 "Arbiter" H 2900 2200 50  0000 C CNN
F 2 "" H 2750 2200 50  0000 C CNN
F 3 "" H 2750 2200 50  0000 C CNN
	1    2750 2200
	1    0    0    -1  
$EndComp
Text GLabel 700  3100 0    60   Input ~ 0
RIAKI
Text GLabel 700  2800 0    60   Input ~ 0
RINIT
Wire Wire Line
	2750 2800 2750 2750
Wire Wire Line
	700  2800 900  2800
Wire Wire Line
	900  2800 1500 2800
Text GLabel 5250 2900 2    60   Output ~ 0
TIAKO
Wire Wire Line
	5250 2900 4900 2900
Wire Wire Line
	700  3100 3500 3100
Wire Wire Line
	3500 3100 3700 3100
Wire Wire Line
	2150 2200 700  2200
Wire Wire Line
	3350 2000 3500 2000
Text GLabel 700  2200 0    60   Input ~ 0
RDIN
$Comp
L 74HC04 U?
U 1 1 584046D4
P 1950 2800
F 0 "U?" H 2100 2900 50  0001 C CNN
F 1 "74HC04" H 2150 2700 50  0001 C CNN
F 2 "" H 1950 2800 50  0000 C CNN
F 3 "" H 1950 2800 50  0000 C CNN
	1    1950 2800
	1    0    0    -1  
$EndComp
Wire Wire Line
	2400 2800 2750 2800
$Comp
L 74HC74 U?
U 1 1 58FA4A3C
P 2200 750
F 0 "U?" H 2350 1050 50  0001 C CNN
F 1 "Request" H 2300 750 50  0000 C CNN
F 2 "" H 2200 750 50  0000 C CNN
F 3 "" H 2200 750 50  0000 C CNN
	1    2200 750 
	1    0    0    -1  
$EndComp
$Comp
L 7402 U?
U 1 1 58FA4A5D
P 1600 1300
F 0 "U?" H 1600 1350 50  0001 C CNN
F 1 "7402" H 1650 1250 50  0001 C CNN
F 2 "" H 1600 1300 50  0000 C CNN
F 3 "" H 1600 1300 50  0000 C CNN
	1    1600 1300
	1    0    0    -1  
$EndComp
Text GLabel 4900 2000 2    60   Output ~ 0
assert_vector
Wire Wire Line
	4700 2000 4800 2000
Wire Wire Line
	4800 2000 4900 2000
Text GLabel 1250 750  0    60   Input ~ 0
interrupt_request
Wire Wire Line
	1250 750  1600 750 
Wire Wire Line
	1000 1400 1000 1600
Wire Wire Line
	1000 1600 4800 1600
Wire Wire Line
	1000 1200 900  1200
Wire Wire Line
	900  1200 900  2800
Connection ~ 900  2800
Wire Wire Line
	4800 1600 4800 2000
Connection ~ 4800 2000
$Comp
L VDD #PWR?
U 1 1 58FA500E
P 1600 550
F 0 "#PWR?" H 1600 400 50  0001 C CNN
F 1 "VDD" H 1600 700 50  0000 C CNN
F 2 "" H 1600 550 50  0000 C CNN
F 3 "" H 1600 550 50  0000 C CNN
	1    1600 550 
	1    0    0    -1  
$EndComp
Text GLabel 5250 550  2    60   Output ~ 0
TIRQn
$Comp
L 74HC74 U?
U 1 1 58FA5480
P 4100 2200
F 0 "U?" H 4250 2500 50  0001 C CNN
F 1 "Latch" H 4250 2200 50  0000 C CNN
F 2 "" H 4100 2200 50  0000 C CNN
F 3 "" H 4100 2200 50  0000 C CNN
	1    4100 2200
	1    0    0    -1  
$EndComp
Wire Wire Line
	3500 3100 3500 2200
Text GLabel 3000 3700 0    60   Input ~ 0
finished
Wire Wire Line
	2100 2000 2100 1450
Wire Wire Line
	2100 1450 2900 1450
Wire Wire Line
	2900 1450 2900 550 
Wire Wire Line
	2800 550  2900 550 
Wire Wire Line
	2900 550  5250 550 
Connection ~ 2900 550 
Wire Wire Line
	2100 2000 2150 2000
Wire Wire Line
	3500 2200 3500 2200
Connection ~ 3500 3100
Wire Wire Line
	4100 2750 3150 2750
Wire Wire Line
	3150 2750 3150 3700
Wire Wire Line
	3000 3700 3150 3700
Wire Wire Line
	3150 3700 4300 3700
Wire Wire Line
	4300 3700 4300 3650
Connection ~ 3150 3700
Wire Wire Line
	3350 2400 3400 2400
Wire Wire Line
	3400 2400 3400 2900
Wire Wire Line
	3400 2900 3700 2900
$Comp
L 74HC74 U?
U 1 1 58FE044A
P 4300 3100
F 0 "U?" H 4450 3400 50  0001 C CNN
F 1 "Latch" H 4450 3100 50  0000 C CNN
F 2 "" H 4300 3100 50  0000 C CNN
F 3 "" H 4300 3100 50  0000 C CNN
	1    4300 3100
	1    0    0    -1  
$EndComp
$EndSCHEMATC
