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
LIBS:qint2-cache
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
P 3050 2450
F 0 "U?" H 3200 2750 50  0001 C CNN
F 1 "Arbiter" H 3200 2450 50  0000 C CNN
F 2 "" H 3050 2450 50  0000 C CNN
F 3 "" H 3050 2450 50  0000 C CNN
	1    3050 2450
	1    0    0    -1  
$EndComp
Text GLabel 350  3250 0    60   Input ~ 0
RIAKI
Text GLabel 350  3050 0    60   Input ~ 0
RINIT
Wire Wire Line
	3050 3050 3050 3000
$Comp
L 74LS08 U?
U 1 1 583F30C7
P 4400 3150
F 0 "U?" H 4400 3200 50  0001 C CNN
F 1 "74LS08" H 4400 3100 50  0001 C CNN
F 2 "" H 4400 3150 50  0000 C CNN
F 3 "" H 4400 3150 50  0000 C CNN
	1    4400 3150
	1    0    0    -1  
$EndComp
Wire Wire Line
	350  3050 450  3050
Wire Wire Line
	450  3050 1800 3050
Text GLabel 5400 3150 2    60   Output ~ 0
TIAKO
Wire Wire Line
	5400 3150 5000 3150
Wire Wire Line
	350  3250 3750 3250
Wire Wire Line
	3750 3250 3800 3250
Wire Wire Line
	3650 2650 3650 3050
Wire Wire Line
	2450 2450 350  2450
Wire Wire Line
	3650 2250 3800 2250
Text GLabel 350  2450 0    60   Input ~ 0
RDIN
$Comp
L 74HC04 U?
U 1 1 584046D4
P 2250 3050
F 0 "U?" H 2400 3150 50  0001 C CNN
F 1 "74HC04" H 2450 2950 50  0001 C CNN
F 2 "" H 2250 3050 50  0000 C CNN
F 3 "" H 2250 3050 50  0000 C CNN
	1    2250 3050
	1    0    0    -1  
$EndComp
Wire Wire Line
	2700 3050 3050 3050
$Comp
L 74HC74 U?
U 1 1 58FA4A3C
P 1750 1000
F 0 "U?" H 1900 1300 50  0001 C CNN
F 1 "Request" H 1850 1000 50  0000 C CNN
F 2 "" H 1750 1000 50  0000 C CNN
F 3 "" H 1750 1000 50  0000 C CNN
	1    1750 1000
	1    0    0    -1  
$EndComp
$Comp
L 7402 U?
U 1 1 58FA4A5D
P 1150 1550
F 0 "U?" H 1150 1600 50  0001 C CNN
F 1 "7402" H 1200 1500 50  0001 C CNN
F 2 "" H 1150 1550 50  0000 C CNN
F 3 "" H 1150 1550 50  0000 C CNN
	1    1150 1550
	1    0    0    -1  
$EndComp
Text GLabel 5100 2350 2    60   Output ~ 0
assert_vector
$Comp
L 74LS08 U?
U 1 1 58FA4ADC
P 4400 2350
F 0 "U?" H 4400 2400 50  0001 C CNN
F 1 "74LS08" H 4400 2300 50  0001 C CNN
F 2 "" H 4400 2350 50  0000 C CNN
F 3 "" H 4400 2350 50  0000 C CNN
	1    4400 2350
	1    0    0    -1  
$EndComp
Wire Wire Line
	3800 2450 3750 2450
Wire Wire Line
	3750 2450 3750 3250
Connection ~ 3750 3250
Wire Wire Line
	3650 3050 3800 3050
Wire Wire Line
	5000 2350 5050 2350
Wire Wire Line
	5050 2350 5100 2350
Text GLabel 900  1000 0    60   Input ~ 0
interrupt_request
Wire Wire Line
	900  1000 1150 1000
Wire Wire Line
	1750 1550 1750 1550
Wire Wire Line
	550  1650 550  1850
Wire Wire Line
	2350 800  2450 800 
Wire Wire Line
	550  1450 450  1450
Wire Wire Line
	450  1450 450  3050
Connection ~ 450  3050
Wire Wire Line
	2450 800  2450 1050
Wire Wire Line
	2450 1050 2450 2250
Wire Wire Line
	5050 1850 5050 2350
Connection ~ 5050 2350
$Comp
L VDD #PWR?
U 1 1 58FA500E
P 1150 800
F 0 "#PWR?" H 1150 650 50  0001 C CNN
F 1 "VDD" H 1150 950 50  0000 C CNN
F 2 "" H 1150 800 50  0000 C CNN
F 3 "" H 1150 800 50  0000 C CNN
	1    1150 800 
	1    0    0    -1  
$EndComp
Text GLabel 5450 1050 2    60   Output ~ 0
TIRQn
Wire Wire Line
	5450 1050 2450 1050
Connection ~ 2450 1050
Wire Wire Line
	2600 1850 5050 1850
Wire Wire Line
	550  1850 2600 1850
$EndSCHEMATC
