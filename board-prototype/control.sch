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
LIBS:proto-cache
EELAYER 25 0
EELAYER END
$Descr USLetter 8500 11000 portrait
encoding utf-8
Sheet 3 4
Title "Bus Control"
Date "2016-02-12"
Rev "0.3"
Comp "Vintage Computer Engineering"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L +5V #PWR095
U 1 1 56BE84AB
P 2400 2100
F 0 "#PWR095" H 2400 1950 50  0001 C CNN
F 1 "+5V" H 2400 2240 50  0000 C CNN
F 2 "" H 2400 2100 60  0000 C CNN
F 3 "" H 2400 2100 60  0000 C CNN
	1    2400 2100
	-1   0    0    -1  
$EndComp
$Comp
L +3.3V #PWR096
U 1 1 56BE84B1
P 2050 2100
F 0 "#PWR096" H 2050 1950 50  0001 C CNN
F 1 "+3.3V" H 2050 2240 50  0000 C CNN
F 2 "" H 2050 2100 60  0000 C CNN
F 3 "" H 2050 2100 60  0000 C CNN
	1    2050 2100
	-1   0    0    -1  
$EndComp
$Comp
L +5V #PWR097
U 1 1 56BE84BE
P 2400 4300
F 0 "#PWR097" H 2400 4150 50  0001 C CNN
F 1 "+5V" H 2400 4440 50  0000 C CNN
F 2 "" H 2400 4300 60  0000 C CNN
F 3 "" H 2400 4300 60  0000 C CNN
	1    2400 4300
	-1   0    0    -1  
$EndComp
$Comp
L +3.3V #PWR098
U 1 1 56BE84C4
P 2050 4300
F 0 "#PWR098" H 2050 4150 50  0001 C CNN
F 1 "+3.3V" H 2050 4440 50  0000 C CNN
F 2 "" H 2050 4300 60  0000 C CNN
F 3 "" H 2050 4300 60  0000 C CNN
	1    2050 4300
	-1   0    0    -1  
$EndComp
$Comp
L +5V #PWR099
U 1 1 56BE84D0
P 5750 2100
F 0 "#PWR099" H 5750 1950 50  0001 C CNN
F 1 "+5V" H 5750 2240 50  0000 C CNN
F 2 "" H 5750 2100 60  0000 C CNN
F 3 "" H 5750 2100 60  0000 C CNN
	1    5750 2100
	1    0    0    -1  
$EndComp
$Comp
L +3.3V #PWR0100
U 1 1 56BE84D6
P 6100 2100
F 0 "#PWR0100" H 6100 1950 50  0001 C CNN
F 1 "+3.3V" H 6100 2240 50  0000 C CNN
F 2 "" H 6100 2100 60  0000 C CNN
F 3 "" H 6100 2100 60  0000 C CNN
	1    6100 2100
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR0101
U 1 1 56BE84E9
P 5750 4300
F 0 "#PWR0101" H 5750 4150 50  0001 C CNN
F 1 "+5V" H 5750 4440 50  0000 C CNN
F 2 "" H 5750 4300 60  0000 C CNN
F 3 "" H 5750 4300 60  0000 C CNN
	1    5750 4300
	1    0    0    -1  
$EndComp
$Comp
L +3.3V #PWR0102
U 1 1 56BE84EF
P 6100 4300
F 0 "#PWR0102" H 6100 4150 50  0001 C CNN
F 1 "+3.3V" H 6100 4440 50  0000 C CNN
F 2 "" H 6100 4300 60  0000 C CNN
F 3 "" H 6100 4300 60  0000 C CNN
	1    6100 4300
	1    0    0    -1  
$EndComp
NoConn ~ 5350 8600
NoConn ~ 5350 8500
NoConn ~ 5350 8400
NoConn ~ 5350 8300
NoConn ~ 6550 8300
NoConn ~ 6550 8400
NoConn ~ 6550 8500
NoConn ~ 6550 8600
$Comp
L GND #PWR0103
U 1 1 56BE8504
P 6550 8950
F 0 "#PWR0103" H 6550 8700 50  0001 C CNN
F 1 "GND" H 6550 8800 50  0001 C CNN
F 2 "" H 6550 8950 60  0000 C CNN
F 3 "" H 6550 8950 60  0000 C CNN
	1    6550 8950
	1    0    0    -1  
$EndComp
$Comp
L +3.3V #PWR0104
U 1 1 56BE850A
P 6100 7650
F 0 "#PWR0104" H 6100 7500 50  0001 C CNN
F 1 "+3.3V" H 6100 7790 50  0000 C CNN
F 2 "" H 6100 7650 60  0000 C CNN
F 3 "" H 6100 7650 60  0000 C CNN
	1    6100 7650
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR0105
U 1 1 56BE8510
P 5750 7650
F 0 "#PWR0105" H 5750 7500 50  0001 C CNN
F 1 "+5V" H 5750 7790 50  0000 C CNN
F 2 "" H 5750 7650 60  0000 C CNN
F 3 "" H 5750 7650 60  0000 C CNN
	1    5750 7650
	1    0    0    -1  
$EndComp
NoConn ~ 4850 6350
NoConn ~ 4150 6850
Text GLabel 1650 2750 0    60   Input ~ 0
TSYNC
Text GLabel 1650 2850 0    60   Input ~ 0
TDIN
Text GLabel 1650 2550 0    60   Input ~ 0
TDOUT
Text GLabel 1650 2650 0    60   Input ~ 0
TRPLY
Text GLabel 1650 4750 0    60   Input ~ 0
TREF
Text GLabel 1650 4650 0    60   Input ~ 0
TDMR
Text GLabel 1650 5050 0    60   Input ~ 0
TDMGO
Text GLabel 1650 4950 0    60   Input ~ 0
TSACK
Text GLabel 1650 2950 0    60   Input ~ 0
TIRQ4
Text GLabel 1650 2350 0    60   Input ~ 0
TIRQ5
Text GLabel 1650 2450 0    60   Input ~ 0
TIRQ6
Text GLabel 1650 5150 0    60   Input ~ 0
TIRQ7
Text GLabel 6550 2750 2    60   Output ~ 0
RSYNC
Text GLabel 6550 2850 2    60   Output ~ 0
RDIN
Text GLabel 6550 2550 2    60   Output ~ 0
RDOUT
Text GLabel 6550 2650 2    60   Output ~ 0
RRPLY
Text GLabel 6550 4750 2    60   Output ~ 0
RREF
Text GLabel 6550 8100 2    60   Output ~ 0
RDCOK
Text GLabel 6550 4650 2    60   Output ~ 0
RDMR
Text GLabel 6550 7900 2    60   Output ~ 0
RSACK
Text GLabel 6550 2950 2    60   Output ~ 0
RIRQ4
Text GLabel 6550 2350 2    60   Output ~ 0
RIRQ5
Text GLabel 6550 2450 2    60   Output ~ 0
RIRQ6
Text GLabel 6550 8000 2    60   Output ~ 0
RIRQ7
Text GLabel 6550 8200 2    60   Output ~ 0
RPOK
Text GLabel 6550 5250 2    60   Output ~ 0
RINIT
Text GLabel 6550 4850 2    60   Output ~ 0
RDMGI
Text GLabel 6550 3050 2    60   Output ~ 0
RIAKI
Text GLabel 1650 4550 0    60   Input ~ 0
TIAKO
NoConn ~ 5350 5150
$Comp
L DS8641-LR U201
U 1 1 56BE854E
P 4150 1450
F 0 "U201" H 4550 2200 60  0000 C CNN
F 1 "DS8641-LR" H 3900 2200 60  0000 C CNN
F 2 "Sockets_DIP:DIP-16__300" H 3625 1975 60  0001 C CNN
F 3 "" H 3625 1975 60  0000 C CNN
	1    4150 1450
	1    0    0    -1  
$EndComp
$Comp
L DS8641-LR U202
U 1 1 56BE8555
P 4150 3050
F 0 "U202" H 4550 3800 60  0000 C CNN
F 1 "DS8641-LR" H 3900 3800 60  0000 C CNN
F 2 "Sockets_DIP:DIP-16__300" H 3625 3575 60  0001 C CNN
F 3 "" H 3625 3575 60  0000 C CNN
	1    4150 3050
	1    0    0    -1  
$EndComp
$Comp
L DS8641-LR U203
U 1 1 56BE855C
P 4150 4850
F 0 "U203" H 4550 5600 60  0000 C CNN
F 1 "DS8641-LR" H 3900 5600 60  0000 C CNN
F 2 "Sockets_DIP:DIP-16__300" H 3625 5375 60  0001 C CNN
F 3 "" H 3625 5375 60  0000 C CNN
	1    4150 4850
	1    0    0    -1  
$EndComp
$Comp
L DS8641-LR U204
U 1 1 56BE8563
P 4150 6450
F 0 "U204" H 4550 7200 60  0000 C CNN
F 1 "DS8641-LR" H 3900 7200 60  0000 C CNN
F 2 "Sockets_DIP:DIP-16__300" H 3625 6975 60  0001 C CNN
F 3 "" H 3625 6975 60  0000 C CNN
	1    4150 6450
	1    0    0    -1  
$EndComp
$Comp
L DS8641-LR U205
U 1 1 56BE856A
P 4150 8200
F 0 "U205" H 4550 8950 60  0000 C CNN
F 1 "DS8641-LR" H 3900 8950 60  0000 C CNN
F 2 "Sockets_DIP:DIP-16__300" H 3625 8725 60  0001 C CNN
F 3 "" H 3625 8725 60  0000 C CNN
	1    4150 8200
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0106
U 1 1 56BE8571
P 3300 8150
F 0 "#PWR0106" H 3300 7900 50  0001 C CNN
F 1 "GND" H 3300 8000 50  0001 C CNN
F 2 "" H 3300 8150 60  0000 C CNN
F 3 "" H 3300 8150 60  0000 C CNN
	1    3300 8150
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0107
U 1 1 56BE8577
P 3450 7700
F 0 "#PWR0107" H 3450 7450 50  0001 C CNN
F 1 "GND" H 3450 7550 50  0000 C CNN
F 2 "" H 3450 7700 60  0000 C CNN
F 3 "" H 3450 7700 60  0000 C CNN
	1    3450 7700
	1    0    0    -1  
$EndComp
NoConn ~ 6550 4950
NoConn ~ 6550 5150
NoConn ~ 5350 4950
NoConn ~ 4850 4550
NoConn ~ 5350 4550
NoConn ~ 6550 4550
Wire Wire Line
	6550 3250 6550 3400
Connection ~ 6550 3350
Wire Wire Line
	5850 2100 5750 2100
Wire Wire Line
	6550 5450 6550 5600
Connection ~ 6550 5550
Wire Wire Line
	5850 4300 5750 4300
Wire Wire Line
	6550 8800 6550 8950
Connection ~ 6550 8900
Wire Wire Line
	5750 7650 5850 7650
Wire Wire Line
	2850 3250 2850 3350
Wire Wire Line
	2150 2100 2050 2100
Wire Wire Line
	2150 4300 2050 4300
Wire Wire Line
	2850 5450 2850 5550
Wire Wire Line
	4850 7900 5350 7900
Wire Wire Line
	5350 8000 4850 8000
Wire Wire Line
	4850 8100 5350 8100
Wire Wire Line
	5350 8200 4850 8200
Wire Wire Line
	4850 2750 5350 2750
Wire Wire Line
	5350 2850 4850 2850
Wire Wire Line
	3450 7600 3450 7700
Wire Wire Line
	3450 2550 3450 2450
Wire Wire Line
	3450 4350 3450 4250
Wire Wire Line
	3450 5850 3450 5950
Wire Wire Line
	2850 4750 3450 4750
Wire Wire Line
	2850 4650 3450 4650
Wire Wire Line
	2850 4550 3450 4550
Wire Wire Line
	3450 2950 2850 2950
Wire Wire Line
	2850 2850 3450 2850
Wire Wire Line
	3450 2750 2850 2750
Wire Wire Line
	4850 4850 5350 4850
Wire Wire Line
	5350 4750 4850 4750
Wire Wire Line
	4850 4650 5350 4650
Wire Wire Line
	4850 1450 4950 1450
Wire Wire Line
	4950 1450 4950 2650
Wire Wire Line
	4950 2650 5350 2650
Wire Wire Line
	5350 2550 5050 2550
Wire Wire Line
	5050 2550 5050 1350
Wire Wire Line
	5050 1350 4850 1350
Wire Wire Line
	4850 1250 5150 1250
Wire Wire Line
	5150 1250 5150 2450
Wire Wire Line
	5150 2450 5350 2450
Wire Wire Line
	5350 2350 5250 2350
Wire Wire Line
	5250 2350 5250 1150
Wire Wire Line
	5250 1150 4850 1150
Wire Wire Line
	3450 950  3450 850 
Wire Wire Line
	3450 1150 2950 1150
Wire Wire Line
	2950 1150 2950 2350
Wire Wire Line
	2950 2350 2850 2350
Wire Wire Line
	2850 2450 3050 2450
Wire Wire Line
	3050 2450 3050 1250
Wire Wire Line
	3050 1250 3450 1250
Wire Wire Line
	3450 1350 3150 1350
Wire Wire Line
	3150 1350 3150 2550
Wire Wire Line
	3150 2550 2850 2550
Wire Wire Line
	2850 2650 3250 2650
Wire Wire Line
	3250 2650 3250 1450
Wire Wire Line
	3250 1450 3450 1450
Wire Wire Line
	5350 5250 5200 5250
Wire Wire Line
	5200 5250 5200 6450
Wire Wire Line
	5200 6450 4850 6450
Wire Wire Line
	4850 2950 5350 2950
Wire Wire Line
	4850 3050 5350 3050
Wire Wire Line
	2850 5050 3300 5050
Wire Wire Line
	3450 6350 3400 6350
Connection ~ 3400 6350
Wire Wire Line
	3400 6450 3450 6450
Connection ~ 3400 6450
Wire Wire Line
	3200 4950 2850 4950
NoConn ~ 4850 6150
Text GLabel 6550 5050 2    60   Output ~ 0
RHALT
Wire Wire Line
	4850 6250 5050 6250
Wire Wire Line
	5050 6250 5050 5050
Wire Wire Line
	5050 5050 5350 5050
Wire Wire Line
	3300 5050 3300 6150
Wire Wire Line
	3300 6150 3450 6150
Wire Wire Line
	3450 6250 3400 6250
Wire Wire Line
	3400 6250 3400 6500
$Comp
L +5V #PWR0108
U 1 1 56BE8D9E
P 2250 8950
F 0 "#PWR0108" H 2250 8800 50  0001 C CNN
F 1 "+5V" H 2250 9090 50  0000 C CNN
F 2 "" H 2250 8950 60  0000 C CNN
F 3 "" H 2250 8950 60  0000 C CNN
	1    2250 8950
	1    0    0    -1  
$EndComp
$Comp
L R R105
U 1 1 56BE8DAA
P 2250 9100
F 0 "R105" V 2330 9100 50  0000 C CNN
F 1 "330Ω" V 2250 9100 50  0000 C CNN
F 2 "Resistors_SMD:R_0805" V 2180 9100 30  0001 C CNN
F 3 "" H 2250 9100 30  0000 C CNN
	1    2250 9100
	1    0    0    -1  
$EndComp
$Comp
L R R106
U 1 1 56BE8DB1
P 2250 9500
F 0 "R106" V 2330 9500 50  0000 C CNN
F 1 "680Ω" V 2250 9500 50  0000 C CNN
F 2 "Resistors_SMD:R_0805" V 2180 9500 30  0001 C CNN
F 3 "" H 2250 9500 30  0000 C CNN
	1    2250 9500
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR0109
U 1 1 56BE8DB8
P 2850 8950
F 0 "#PWR0109" H 2850 8800 50  0001 C CNN
F 1 "+5V" H 2850 9090 50  0000 C CNN
F 2 "" H 2850 8950 60  0000 C CNN
F 3 "" H 2850 8950 60  0000 C CNN
	1    2850 8950
	1    0    0    -1  
$EndComp
$Comp
L R R107
U 1 1 56BE8DC4
P 2850 9100
F 0 "R107" V 2930 9100 50  0000 C CNN
F 1 "330Ω" V 2850 9100 50  0000 C CNN
F 2 "Resistors_SMD:R_0805" V 2780 9100 30  0001 C CNN
F 3 "" H 2850 9100 30  0000 C CNN
	1    2850 9100
	1    0    0    -1  
$EndComp
$Comp
L R R108
U 1 1 56BE8DCB
P 2850 9500
F 0 "R108" V 2930 9500 50  0000 C CNN
F 1 "680Ω" V 2850 9500 50  0000 C CNN
F 2 "Resistors_SMD:R_0805" V 2780 9500 30  0001 C CNN
F 3 "" H 2850 9500 30  0000 C CNN
	1    2850 9500
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR0110
U 1 1 56BE8DD2
P 1100 8950
F 0 "#PWR0110" H 1100 8800 50  0001 C CNN
F 1 "+5V" H 1100 9090 50  0000 C CNN
F 2 "" H 1100 8950 60  0000 C CNN
F 3 "" H 1100 8950 60  0000 C CNN
	1    1100 8950
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0111
U 1 1 56BE8DD8
P 1100 9650
F 0 "#PWR0111" H 1100 9400 50  0001 C CNN
F 1 "GND" H 1100 9500 50  0001 C CNN
F 2 "" H 1100 9650 60  0000 C CNN
F 3 "" H 1100 9650 60  0000 C CNN
	1    1100 9650
	1    0    0    -1  
$EndComp
$Comp
L R R101
U 1 1 56BE8DDE
P 1100 9100
F 0 "R101" V 1180 9100 50  0000 C CNN
F 1 "330Ω" V 1100 9100 50  0000 C CNN
F 2 "Resistors_SMD:R_0805" V 1030 9100 30  0001 C CNN
F 3 "" H 1100 9100 30  0000 C CNN
	1    1100 9100
	1    0    0    -1  
$EndComp
$Comp
L R R102
U 1 1 56BE8DE5
P 1100 9500
F 0 "R102" V 1180 9500 50  0000 C CNN
F 1 "680Ω" V 1100 9500 50  0000 C CNN
F 2 "Resistors_SMD:R_0805" V 1030 9500 30  0001 C CNN
F 3 "" H 1100 9500 30  0000 C CNN
	1    1100 9500
	1    0    0    -1  
$EndComp
$Comp
L +5V #PWR0112
U 1 1 56BE8DED
P 1700 8950
F 0 "#PWR0112" H 1700 8800 50  0001 C CNN
F 1 "+5V" H 1700 9090 50  0000 C CNN
F 2 "" H 1700 8950 60  0000 C CNN
F 3 "" H 1700 8950 60  0000 C CNN
	1    1700 8950
	1    0    0    -1  
$EndComp
$Comp
L R R103
U 1 1 56BE8DF9
P 1700 9100
F 0 "R103" V 1780 9100 50  0000 C CNN
F 1 "330Ω" V 1700 9100 50  0000 C CNN
F 2 "Resistors_SMD:R_0805" V 1630 9100 30  0001 C CNN
F 3 "" H 1700 9100 30  0000 C CNN
	1    1700 9100
	1    0    0    -1  
$EndComp
$Comp
L R R104
U 1 1 56BE8E00
P 1700 9500
F 0 "R104" V 1780 9500 50  0000 C CNN
F 1 "680Ω" V 1700 9500 50  0000 C CNN
F 2 "Resistors_SMD:R_0805" V 1630 9500 30  0001 C CNN
F 3 "" H 1700 9500 30  0000 C CNN
	1    1700 9500
	1    0    0    -1  
$EndComp
Wire Wire Line
	2250 9250 2250 9350
Wire Wire Line
	2250 9300 2300 9300
Connection ~ 2250 9300
Wire Wire Line
	2850 9250 2850 9350
Wire Wire Line
	2850 9300 2900 9300
Connection ~ 2850 9300
Wire Wire Line
	1100 9250 1100 9350
Wire Wire Line
	1100 9300 1150 9300
Connection ~ 1100 9300
Wire Wire Line
	1700 9250 1700 9350
Wire Wire Line
	1700 9300 1750 9300
Connection ~ 1700 9300
Text GLabel 3950 3450 3    60   BiDi ~ 0
BSYNC
Text GLabel 4150 5250 3    60   BiDi ~ 0
BREF
Text GLabel 4150 1850 3    60   BiDi ~ 0
BDOUT
Text GLabel 4050 3450 3    60   BiDi ~ 0
BDIN
Text GLabel 4250 1850 3    60   BiDi ~ 0
BRPLY
Text GLabel 4050 6850 3    60   BiDi ~ 0
BHALT
Text GLabel 4250 6850 3    60   BiDi ~ 0
BINIT
Text GLabel 4050 5250 3    60   BiDi ~ 0
BDMR
Text GLabel 4250 5250 3    60   Output ~ 0
BDMGI
Text GLabel 3950 6850 3    60   Input ~ 0
BDMGO
Text GLabel 3950 8600 3    60   BiDi ~ 0
BSACK
Text GLabel 4150 3450 3    60   BiDi ~ 0
BIRQ4
Text GLabel 3950 1850 3    60   BiDi ~ 0
BIRQ5
Text GLabel 4050 1850 3    60   BiDi ~ 0
BIRQ6
Text GLabel 4050 8600 3    60   BiDi ~ 0
BIRQ7
Text GLabel 4250 3450 3    60   Output ~ 0
BIAKI
Text GLabel 3950 5250 3    60   Input ~ 0
BIAKO
Text GLabel 4250 8600 3    60   Output ~ 0
BPOK
Text GLabel 4150 8600 3    60   Output ~ 0
BDCOK
Text GLabel 1150 9300 2    60   Output ~ 0
BDMGI
Text GLabel 1750 9300 2    60   Input ~ 0
BDMGO
Text GLabel 2300 9300 2    60   Output ~ 0
BIAKI
Text GLabel 2900 9300 2    60   Input ~ 0
BIAKO
$Comp
L GND #PWR0113
U 1 1 56CE07FC
P 1700 9650
F 0 "#PWR0113" H 1700 9400 50  0001 C CNN
F 1 "GND" H 1700 9500 50  0001 C CNN
F 2 "" H 1700 9650 60  0000 C CNN
F 3 "" H 1700 9650 60  0000 C CNN
	1    1700 9650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0114
U 1 1 56CE083D
P 2250 9650
F 0 "#PWR0114" H 2250 9400 50  0001 C CNN
F 1 "GND" H 2250 9500 50  0001 C CNN
F 2 "" H 2250 9650 60  0000 C CNN
F 3 "" H 2250 9650 60  0000 C CNN
	1    2250 9650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0115
U 1 1 56CE087E
P 2850 9650
F 0 "#PWR0115" H 2850 9400 50  0001 C CNN
F 1 "GND" H 2850 9500 50  0001 C CNN
F 2 "" H 2850 9650 60  0000 C CNN
F 3 "" H 2850 9650 60  0000 C CNN
	1    2850 9650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0116
U 1 1 56CE0C91
P 3400 6500
F 0 "#PWR0116" H 3400 6250 50  0001 C CNN
F 1 "GND" H 3400 6350 50  0001 C CNN
F 2 "" H 3400 6500 60  0000 C CNN
F 3 "" H 3400 6500 60  0000 C CNN
	1    3400 6500
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0117
U 1 1 56CE0D99
P 3450 5950
F 0 "#PWR0117" H 3450 5700 50  0001 C CNN
F 1 "GND" H 3450 5800 50  0001 C CNN
F 2 "" H 3450 5950 60  0000 C CNN
F 3 "" H 3450 5950 60  0000 C CNN
	1    3450 5950
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0118
U 1 1 56CE0DED
P 2850 5550
F 0 "#PWR0118" H 2850 5300 50  0001 C CNN
F 1 "GND" H 2850 5400 50  0001 C CNN
F 2 "" H 2850 5550 60  0000 C CNN
F 3 "" H 2850 5550 60  0000 C CNN
	1    2850 5550
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0119
U 1 1 56CE0FD0
P 3450 4850
F 0 "#PWR0119" H 3450 4600 50  0001 C CNN
F 1 "GND" H 3450 4700 50  0001 C CNN
F 2 "" H 3450 4850 60  0000 C CNN
F 3 "" H 3450 4850 60  0000 C CNN
	1    3450 4850
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0120
U 1 1 56CE1011
P 3450 4350
F 0 "#PWR0120" H 3450 4100 50  0001 C CNN
F 1 "GND" H 3450 4200 50  0001 C CNN
F 2 "" H 3450 4350 60  0000 C CNN
F 3 "" H 3450 4350 60  0000 C CNN
	1    3450 4350
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0121
U 1 1 56CE10D1
P 6550 5600
F 0 "#PWR0121" H 6550 5350 50  0001 C CNN
F 1 "GND" H 6550 5450 50  0001 C CNN
F 2 "" H 6550 5600 60  0000 C CNN
F 3 "" H 6550 5600 60  0000 C CNN
	1    6550 5600
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0122
U 1 1 56CE11B5
P 6550 3400
F 0 "#PWR0122" H 6550 3150 50  0001 C CNN
F 1 "GND" H 6550 3250 50  0001 C CNN
F 2 "" H 6550 3400 60  0000 C CNN
F 3 "" H 6550 3400 60  0000 C CNN
	1    6550 3400
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0123
U 1 1 56CE1313
P 3450 3050
F 0 "#PWR0123" H 3450 2800 50  0001 C CNN
F 1 "GND" H 3450 2900 50  0001 C CNN
F 2 "" H 3450 3050 60  0000 C CNN
F 3 "" H 3450 3050 60  0000 C CNN
	1    3450 3050
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0124
U 1 1 56CE1354
P 3450 2550
F 0 "#PWR0124" H 3450 2300 50  0001 C CNN
F 1 "GND" H 3450 2400 50  0001 C CNN
F 2 "" H 3450 2550 60  0000 C CNN
F 3 "" H 3450 2550 60  0000 C CNN
	1    3450 2550
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0125
U 1 1 56CE1395
P 2850 3350
F 0 "#PWR0125" H 2850 3100 50  0001 C CNN
F 1 "GND" H 2850 3200 50  0001 C CNN
F 2 "" H 2850 3350 60  0000 C CNN
F 3 "" H 2850 3350 60  0000 C CNN
	1    2850 3350
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0126
U 1 1 56CE151B
P 3450 950
F 0 "#PWR0126" H 3450 700 50  0001 C CNN
F 1 "GND" H 3450 800 50  0001 C CNN
F 2 "" H 3450 950 60  0000 C CNN
F 3 "" H 3450 950 60  0000 C CNN
	1    3450 950 
	1    0    0    -1  
$EndComp
$Comp
L 74LVC8T245 U116
U 1 1 580E306F
P 5950 2850
F 0 "U116" H 5900 2850 60  0000 L BNN
F 1 "74LVC8T245" H 5650 2600 60  0000 L TNN
F 2 "Housings_SSOP:TSSOP-24_4.4x7.8mm_Pitch0.65mm" H 5950 2850 60  0001 C CNN
F 3 "" H 5950 2850 60  0000 C CNN
	1    5950 2850
	-1   0    0    -1  
$EndComp
$Comp
L 74LVC8T245 U118
U 1 1 580E30E9
P 5950 5050
F 0 "U118" H 5900 5050 60  0000 L BNN
F 1 "74LVC8T245" H 5650 4800 60  0000 L TNN
F 2 "Housings_SSOP:TSSOP-24_4.4x7.8mm_Pitch0.65mm" H 5950 5050 60  0001 C CNN
F 3 "" H 5950 5050 60  0000 C CNN
	1    5950 5050
	-1   0    0    -1  
$EndComp
$Comp
L 74LVC8T245 U119
U 1 1 580E3161
P 5950 8400
F 0 "U119" H 5900 8400 60  0000 L BNN
F 1 "74LVC8T245" H 5650 8150 60  0000 L TNN
F 2 "Housings_SSOP:TSSOP-24_4.4x7.8mm_Pitch0.65mm" H 5950 8400 60  0001 C CNN
F 3 "" H 5950 8400 60  0000 C CNN
	1    5950 8400
	-1   0    0    -1  
$EndComp
$Comp
L 74LVC8T245 U115
U 1 1 580E31E0
P 2250 2850
F 0 "U115" H 2200 2850 60  0000 L BNN
F 1 "74LVC8T245" H 1950 2600 60  0000 L TNN
F 2 "Housings_SSOP:TSSOP-24_4.4x7.8mm_Pitch0.65mm" H 2250 2850 60  0001 C CNN
F 3 "" H 2250 2850 60  0000 C CNN
	1    2250 2850
	-1   0    0    -1  
$EndComp
$Comp
L 74LVC8T245 U117
U 1 1 580E325A
P 2250 5050
F 0 "U117" H 2200 5050 60  0000 L BNN
F 1 "74LVC8T245" H 1950 4800 60  0000 L TNN
F 2 "Housings_SSOP:TSSOP-24_4.4x7.8mm_Pitch0.65mm" H 2250 5050 60  0001 C CNN
F 3 "" H 2250 5050 60  0000 C CNN
	1    2250 5050
	-1   0    0    -1  
$EndComp
Wire Wire Line
	3450 8100 3450 8200
Wire Wire Line
	3300 8150 3450 8150
Connection ~ 3450 8150
Wire Wire Line
	3200 4950 3200 7900
Wire Wire Line
	3200 7900 3450 7900
Wire Wire Line
	3450 8000 3100 8000
Wire Wire Line
	3100 8000 3100 5150
Wire Wire Line
	3100 5150 2850 5150
$EndSCHEMATC
