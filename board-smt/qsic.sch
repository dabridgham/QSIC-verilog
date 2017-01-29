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
$Descr USLetter 8500 11000 portrait
encoding utf-8
Sheet 1 3
Title "QSIC"
Date "2017-01-19"
Rev "0.1"
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Sheet
S 2300 1800 900  2350
U 560E637A
F0 "Bus Data/Address" 60
F1 "drivers.sch" 60
$EndSheet
$Comp
L PWR_FLAG #FLG01
U 1 1 56137D79
P 2550 9550
F 0 "#FLG01" H 2550 9645 50  0001 C CNN
F 1 "PWR_FLAG" H 2550 9730 50  0000 C CNN
F 2 "" H 2550 9550 60  0000 C CNN
F 3 "" H 2550 9550 60  0000 C CNN
	1    2550 9550
	1    0    0    -1  
$EndComp
$Comp
L PWR_FLAG #FLG02
U 1 1 56137D87
P 3000 9550
F 0 "#FLG02" H 3000 9645 50  0001 C CNN
F 1 "PWR_FLAG" H 3000 9730 50  0000 C CNN
F 2 "" H 3000 9550 60  0000 C CNN
F 3 "" H 3000 9550 60  0000 C CNN
	1    3000 9550
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR03
U 1 1 56137DA4
P 2550 9550
F 0 "#PWR03" H 2550 9400 50  0001 C CNN
F 1 "+5V" H 2550 9690 50  0000 C CNN
F 2 "" H 2550 9550 60  0000 C CNN
F 3 "" H 2550 9550 60  0000 C CNN
	1    2550 9550
	-1   0    0    1   
$EndComp
$Comp
L GND #PWR04
U 1 1 56137DB2
P 3000 9550
F 0 "#PWR04" H 3000 9300 50  0001 C CNN
F 1 "GND" H 3000 9400 50  0000 C CNN
F 2 "" H 3000 9550 60  0000 C CNN
F 3 "" H 3000 9550 60  0000 C CNN
	1    3000 9550
	1    0    0    -1  
$EndComp
Text GLabel 4900 5350 0    60   BiDi ~ 0
BSACK
Text GLabel 4900 5150 0    60   Output ~ 0
BDMGI
Text GLabel 4900 5250 0    60   Input ~ 0
BDMGO
Text GLabel 4900 1800 0    60   BiDi ~ 0
BDAL0
Text GLabel 4900 1900 0    60   BiDi ~ 0
BDAL1
Text GLabel 4900 2000 0    60   BiDi ~ 0
BDAL2
Text GLabel 4900 2100 0    60   BiDi ~ 0
BDAL3
Text GLabel 4900 2200 0    60   BiDi ~ 0
BDAL4
Text GLabel 4900 2300 0    60   BiDi ~ 0
BDAL5
Text GLabel 4900 2400 0    60   BiDi ~ 0
BDAL6
Text GLabel 4900 2500 0    60   BiDi ~ 0
BDAL7
Text GLabel 4900 2600 0    60   BiDi ~ 0
BDAL8
Text GLabel 4900 2700 0    60   BiDi ~ 0
BDAL9
Text GLabel 4900 2800 0    60   BiDi ~ 0
BDAL10
Text GLabel 4900 2900 0    60   BiDi ~ 0
BDAL11
Text GLabel 4900 3000 0    60   BiDi ~ 0
BDAL12
Text GLabel 4900 3100 0    60   BiDi ~ 0
BDAL13
Text GLabel 4900 3200 0    60   BiDi ~ 0
BDAL14
Text GLabel 4900 3300 0    60   BiDi ~ 0
BDAL15
Text GLabel 4900 3400 0    60   BiDi ~ 0
BDAL16
Text GLabel 4900 3500 0    60   BiDi ~ 0
BDAL17
Text GLabel 4900 3600 0    60   BiDi ~ 0
BDAL18
Text GLabel 4900 3700 0    60   BiDi ~ 0
BDAL19
Text GLabel 4900 3800 0    60   BiDi ~ 0
BDAL20
Text GLabel 4900 3900 0    60   BiDi ~ 0
BDAL21
Text GLabel 4900 4050 0    60   BiDi ~ 0
BBS7
Text GLabel 4900 4150 0    60   BiDi ~ 0
BSYNC
Text GLabel 4900 4250 0    60   BiDi ~ 0
BDIN
Text GLabel 4900 4450 0    60   BiDi ~ 0
BRPLY
Text GLabel 4900 4550 0    60   BiDi ~ 0
BWTBT
Text GLabel 4900 4650 0    60   BiDi ~ 0
BREF
Text GLabel 4900 4800 0    60   Output ~ 0
BHALT
Text GLabel 4900 4900 0    60   BiDi ~ 0
BINIT
Text GLabel 4900 5050 0    60   BiDi ~ 0
BDMR
Text GLabel 4900 5500 0    60   BiDi ~ 0
BIRQ4
Text GLabel 4900 5600 0    60   BiDi ~ 0
BIRQ5
Text GLabel 4900 5700 0    60   BiDi ~ 0
BIRQ6
Text GLabel 4900 5800 0    60   BiDi ~ 0
BIRQ7
Text GLabel 4900 5900 0    60   Output ~ 0
BIAKI
Text GLabel 4900 6000 0    60   Input ~ 0
BIAKO
Text GLabel 4900 6100 0    60   Output ~ 0
BEVNT
Text GLabel 6550 3650 2    60   Output ~ 0
BPOK
Text GLabel 6550 3750 2    60   Output ~ 0
BDCOK
Wire Wire Line
	6550 4600 6650 4600
Wire Wire Line
	6650 4600 6650 5300
Wire Wire Line
	6550 5200 6650 5200
Connection ~ 6650 5200
Wire Wire Line
	6550 5100 6650 5100
Connection ~ 6650 5100
Wire Wire Line
	6550 5000 6650 5000
Connection ~ 6650 5000
Wire Wire Line
	6550 4900 6650 4900
Connection ~ 6650 4900
Wire Wire Line
	6550 4800 6650 4800
Connection ~ 6650 4800
Wire Wire Line
	6550 4700 6650 4700
Connection ~ 6650 4700
$Comp
L GND #PWR05
U 1 1 58814E97
P 6650 5300
F 0 "#PWR05" H 6650 5050 50  0001 C CNN
F 1 "GND" H 6650 5150 50  0000 C CNN
F 2 "" H 6650 5300 60  0000 C CNN
F 3 "" H 6650 5300 60  0000 C CNN
	1    6650 5300
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR06
U 1 1 58814E9D
P 6700 4300
F 0 "#PWR06" H 6700 4150 50  0001 C CNN
F 1 "+5V" H 6700 4440 50  0000 C CNN
F 2 "" H 6700 4300 60  0000 C CNN
F 3 "" H 6700 4300 60  0000 C CNN
	1    6700 4300
	0    1    1    0   
$EndComp
Wire Wire Line
	6550 4300 6700 4300
Wire Wire Line
	6550 4400 6650 4400
Wire Wire Line
	6650 4300 6650 4500
Wire Wire Line
	6650 4500 6550 4500
Connection ~ 6650 4400
Text GLabel 4900 4350 0    60   BiDi ~ 0
BDOUT
NoConn ~ 6550 4100
NoConn ~ 6550 4200
NoConn ~ 6550 3550
NoConn ~ 6550 3450
NoConn ~ 6550 3350
NoConn ~ 6550 3250
NoConn ~ 6550 3150
NoConn ~ 6550 2600
NoConn ~ 6550 2500
NoConn ~ 6550 2400
NoConn ~ 6550 2300
NoConn ~ 6550 2200
NoConn ~ 6550 2100
$Comp
L QBUS B101
U 1 1 58814EB8
P 6350 3900
F 0 "B101" H 5775 3700 60  0000 C CNN
F 1 "QBUS" H 5775 3475 60  0000 C CNN
F 2 "myMods.pretty:Qbus-double" H 6350 3750 60  0001 C CNN
F 3 "" H 6350 3750 60  0000 C CNN
	1    6350 3900
	1    0    0    -1  
$EndComp
$Comp
L +12V #PWR07
U 1 1 58814ECD
P 6700 3900
F 0 "#PWR07" H 6700 3750 50  0001 C CNN
F 1 "+12V" H 6700 4040 50  0000 C CNN
F 2 "" H 6700 3900 50  0000 C CNN
F 3 "" H 6700 3900 50  0000 C CNN
	1    6700 3900
	0    1    1    0   
$EndComp
Wire Wire Line
	6550 3900 6700 3900
Wire Wire Line
	6550 4000 6650 4000
Wire Wire Line
	6650 4000 6650 3900
Connection ~ 6650 3900
Connection ~ 6650 4300
$Comp
L PWR_FLAG #FLG08
U 1 1 58814F6A
P 2100 9550
F 0 "#FLG08" H 2100 9645 50  0001 C CNN
F 1 "PWR_FLAG" H 2100 9730 50  0000 C CNN
F 2 "" H 2100 9550 60  0000 C CNN
F 3 "" H 2100 9550 60  0000 C CNN
	1    2100 9550
	1    0    0    -1  
$EndComp
$Comp
L +12V #PWR09
U 1 1 58814F79
P 2100 9550
F 0 "#PWR09" H 2100 9400 50  0001 C CNN
F 1 "+12V" H 2100 9690 50  0000 C CNN
F 2 "" H 2100 9550 50  0000 C CNN
F 3 "" H 2100 9550 50  0000 C CNN
	1    2100 9550
	-1   0    0    1   
$EndComp
$Sheet
S 2400 4850 700  1100
U 58857B5F
F0 "Bus Control" 60
F1 "BusControl.sch" 60
$EndSheet
$EndSCHEMATC
