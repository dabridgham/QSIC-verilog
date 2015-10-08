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
$Comp
L QBus B101
U 1 1 560C3E74
P 15600 3600
F 0 "B101" H 15025 3400 60  0000 C CNN
F 1 "QBus" H 15025 3175 60  0000 C CNN
F 2 "myMods.pretty:Qbus-double" H 15600 3600 60  0001 C CNN
F 3 "" H 15600 3600 60  0000 C CNN
	1    15600 3600
	1    0    0    -1  
$EndComp
Text GLabel 14150 5050 0    60   Input ~ 0
BSACK
Text GLabel 14150 4850 0    60   Input ~ 0
BDMGI
Text GLabel 14150 4950 0    60   Input ~ 0
BDMGO
$Sheet
S 11550 3900 900  2350
U 560E637A
F0 "drivers" 60
F1 "drivers.sch" 60
$EndSheet
Text GLabel 14150 1500 0    60   Input ~ 0
BDAL0
Text GLabel 14150 1600 0    60   Input ~ 0
BDAL1
Text GLabel 14150 1700 0    60   Input ~ 0
BDAL2
Text GLabel 14150 1800 0    60   Input ~ 0
BDAL3
Text GLabel 14150 1900 0    60   Input ~ 0
BDAL4
Text GLabel 14150 2000 0    60   Input ~ 0
BDAL5
Text GLabel 14150 2100 0    60   Input ~ 0
BDAL6
Text GLabel 14150 2200 0    60   Input ~ 0
BDAL7
Text GLabel 14150 2300 0    60   Input ~ 0
BDAL8
Text GLabel 14150 2400 0    60   Input ~ 0
BDAL9
Text GLabel 14150 2500 0    60   Input ~ 0
BDAL10
Text GLabel 14150 2600 0    60   Input ~ 0
BDAL11
Text GLabel 14150 2700 0    60   Input ~ 0
BDAL12
Text GLabel 14150 2800 0    60   Input ~ 0
BDAL13
Text GLabel 14150 2900 0    60   Input ~ 0
BDAL14
Text GLabel 14150 3000 0    60   Input ~ 0
BDAL15
Text GLabel 14150 3100 0    60   Input ~ 0
BDAL16
Text GLabel 14150 3200 0    60   Input ~ 0
BDAL17
Text GLabel 14150 3300 0    60   Input ~ 0
BDAL18
Text GLabel 14150 3400 0    60   Input ~ 0
BDAL19
Text GLabel 14150 3500 0    60   Input ~ 0
BDAL20
Text GLabel 14150 3600 0    60   Input ~ 0
BDAL21
Text GLabel 14150 3750 0    60   Input ~ 0
BBS7
Text GLabel 14150 3850 0    60   Input ~ 0
BSYNC
Text GLabel 14150 3950 0    60   Input ~ 0
BDIN
Text GLabel 14150 4150 0    60   Input ~ 0
BRPLY
Text GLabel 14150 4250 0    60   Input ~ 0
BWTBT
Text GLabel 14150 4350 0    60   Input ~ 0
BREF
Text GLabel 14150 4500 0    60   Input ~ 0
BHALT
Text GLabel 14150 4600 0    60   Input ~ 0
BINIT
Text GLabel 14150 4750 0    60   Input ~ 0
BDMR
Text GLabel 14150 5200 0    60   Input ~ 0
BIRQ4
Text GLabel 14150 5300 0    60   Input ~ 0
BIRQ5
Text GLabel 14150 5400 0    60   Input ~ 0
BIRQ6
Text GLabel 14150 5500 0    60   Input ~ 0
BIRQ7
Text GLabel 14150 5600 0    60   Input ~ 0
BIAKI
Text GLabel 14150 5700 0    60   Input ~ 0
BIAKO
Text GLabel 14150 5800 0    60   Input ~ 0
BEVNT
Text GLabel 15800 3350 2    60   Input ~ 0
BPOK
Text GLabel 15800 3450 2    60   Input ~ 0
BDCOK
Wire Notes Line
	13550 1750 13550 5100
Wire Notes Line
	13550 5100 12600 5100
Wire Wire Line
	15800 4300 15900 4300
Wire Wire Line
	15900 4300 15900 5000
Wire Wire Line
	15800 4900 15900 4900
Connection ~ 15900 4900
Wire Wire Line
	15800 4800 15900 4800
Connection ~ 15900 4800
Wire Wire Line
	15800 4700 15900 4700
Connection ~ 15900 4700
Wire Wire Line
	15800 4600 15900 4600
Connection ~ 15900 4600
Wire Wire Line
	15800 4500 15900 4500
Connection ~ 15900 4500
Wire Wire Line
	15800 4400 15900 4400
Connection ~ 15900 4400
$Comp
L GND #PWR01
U 1 1 56137AAE
P 15900 5000
F 0 "#PWR01" H 15900 4750 50  0001 C CNN
F 1 "GND" H 15900 4850 50  0000 C CNN
F 2 "" H 15900 5000 60  0000 C CNN
F 3 "" H 15900 5000 60  0000 C CNN
	1    15900 5000
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR02
U 1 1 56137AC5
P 15900 4000
F 0 "#PWR02" H 15900 3850 50  0001 C CNN
F 1 "+5V" H 15900 4140 50  0000 C CNN
F 2 "" H 15900 4000 60  0000 C CNN
F 3 "" H 15900 4000 60  0000 C CNN
	1    15900 4000
	0    1    1    0   
$EndComp
Wire Wire Line
	15800 4000 15900 4000
Wire Wire Line
	15800 4100 15900 4100
Wire Wire Line
	15900 4000 15900 4200
Wire Wire Line
	15900 4200 15800 4200
Connection ~ 15900 4100
$Comp
L PWR_FLAG #FLG03
U 1 1 56137D79
P 15350 6350
F 0 "#FLG03" H 15350 6445 50  0001 C CNN
F 1 "PWR_FLAG" H 15350 6530 50  0000 C CNN
F 2 "" H 15350 6350 60  0000 C CNN
F 3 "" H 15350 6350 60  0000 C CNN
	1    15350 6350
	1    0    0    -1  
$EndComp
$Comp
L PWR_FLAG #FLG04
U 1 1 56137D87
P 15800 6350
F 0 "#FLG04" H 15800 6445 50  0001 C CNN
F 1 "PWR_FLAG" H 15800 6530 50  0000 C CNN
F 2 "" H 15800 6350 60  0000 C CNN
F 3 "" H 15800 6350 60  0000 C CNN
	1    15800 6350
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR05
U 1 1 56137DA4
P 15350 6350
F 0 "#PWR05" H 15350 6200 50  0001 C CNN
F 1 "+5V" H 15350 6490 50  0000 C CNN
F 2 "" H 15350 6350 60  0000 C CNN
F 3 "" H 15350 6350 60  0000 C CNN
	1    15350 6350
	-1   0    0    1   
$EndComp
$Comp
L GND #PWR06
U 1 1 56137DB2
P 15800 6350
F 0 "#PWR06" H 15800 6100 50  0001 C CNN
F 1 "GND" H 15800 6200 50  0000 C CNN
F 2 "" H 15800 6350 60  0000 C CNN
F 3 "" H 15800 6350 60  0000 C CNN
	1    15800 6350
	1    0    0    -1  
$EndComp
Text GLabel 14150 4050 0    60   Input ~ 0
BDOUT
NoConn ~ 15800 3600
NoConn ~ 15800 3700
NoConn ~ 15800 3800
NoConn ~ 15800 3900
NoConn ~ 15800 3250
NoConn ~ 15800 3150
NoConn ~ 15800 3050
NoConn ~ 15800 2950
NoConn ~ 15800 2850
NoConn ~ 15800 2300
NoConn ~ 15800 2200
NoConn ~ 15800 2100
NoConn ~ 15800 2000
NoConn ~ 15800 1900
NoConn ~ 15800 1800
$EndSCHEMATC
