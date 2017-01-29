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
Sheet 4 4
Title "FPGA Interface"
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L +5V #PWR0127
U 1 1 56BE91DF
P 3400 1400
F 0 "#PWR0127" H 3400 1250 50  0001 C CNN
F 1 "+5V" H 3400 1540 50  0000 C CNN
F 2 "" H 3400 1400 60  0000 C CNN
F 3 "" H 3400 1400 60  0000 C CNN
	1    3400 1400
	0    1    -1   0   
$EndComp
$Comp
L +5V #PWR0128
U 1 1 56BE91E5
P 2800 1400
F 0 "#PWR0128" H 2800 1250 50  0001 C CNN
F 1 "+5V" H 2800 1540 50  0000 C CNN
F 2 "" H 2800 1400 60  0000 C CNN
F 3 "" H 2800 1400 60  0000 C CNN
	1    2800 1400
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR0129
U 1 1 56BE91EB
P 2800 1500
F 0 "#PWR0129" H 2800 1250 50  0001 C CNN
F 1 "GND" H 2800 1350 50  0001 C CNN
F 2 "" H 2800 1500 60  0000 C CNN
F 3 "" H 2800 1500 60  0000 C CNN
	1    2800 1500
	0    1    1    0   
$EndComp
$Comp
L GND #PWR0130
U 1 1 56BE91F1
P 4350 1500
F 0 "#PWR0130" H 4350 1250 50  0001 C CNN
F 1 "GND" H 4350 1350 50  0001 C CNN
F 2 "" H 4350 1500 60  0000 C CNN
F 3 "" H 4350 1500 60  0000 C CNN
	1    4350 1500
	0    1    1    0   
$EndComp
$Comp
L GND #PWR0131
U 1 1 56BE91F7
P 3400 1500
F 0 "#PWR0131" H 3400 1250 50  0001 C CNN
F 1 "GND" H 3400 1350 50  0001 C CNN
F 2 "" H 3400 1500 60  0000 C CNN
F 3 "" H 3400 1500 60  0000 C CNN
	1    3400 1500
	0    -1   1    0   
$EndComp
$Comp
L GND #PWR0132
U 1 1 56BE91FD
P 4950 1500
F 0 "#PWR0132" H 4950 1250 50  0001 C CNN
F 1 "GND" H 4950 1350 50  0001 C CNN
F 2 "" H 4950 1500 60  0000 C CNN
F 3 "" H 4950 1500 60  0000 C CNN
	1    4950 1500
	0    -1   1    0   
$EndComp
$Comp
L GND #PWR0133
U 1 1 56BE9203
P 3400 2900
F 0 "#PWR0133" H 3400 2650 50  0001 C CNN
F 1 "GND" H 3400 2750 50  0001 C CNN
F 2 "" H 3400 2900 60  0000 C CNN
F 3 "" H 3400 2900 60  0000 C CNN
	1    3400 2900
	0    -1   1    0   
$EndComp
$Comp
L GND #PWR0134
U 1 1 56BE9209
P 2800 2900
F 0 "#PWR0134" H 2800 2650 50  0001 C CNN
F 1 "GND" H 2800 2750 50  0001 C CNN
F 2 "" H 2800 2900 60  0000 C CNN
F 3 "" H 2800 2900 60  0000 C CNN
	1    2800 2900
	0    1    1    0   
$EndComp
$Comp
L GND #PWR0135
U 1 1 56BE9215
P 4350 3000
F 0 "#PWR0135" H 4350 2750 50  0001 C CNN
F 1 "GND" H 4350 2850 50  0001 C CNN
F 2 "" H 4350 3000 60  0000 C CNN
F 3 "" H 4350 3000 60  0000 C CNN
	1    4350 3000
	0    1    1    0   
$EndComp
$Comp
L GND #PWR0136
U 1 1 56BE921B
P 3400 4500
F 0 "#PWR0136" H 3400 4250 50  0001 C CNN
F 1 "GND" H 3400 4350 50  0001 C CNN
F 2 "" H 3400 4500 60  0000 C CNN
F 3 "" H 3400 4500 60  0000 C CNN
	1    3400 4500
	0    -1   1    0   
$EndComp
$Comp
L GND #PWR0137
U 1 1 56BE9227
P 4350 4500
F 0 "#PWR0137" H 4350 4250 50  0001 C CNN
F 1 "GND" H 4350 4350 50  0001 C CNN
F 2 "" H 4350 4500 60  0000 C CNN
F 3 "" H 4350 4500 60  0000 C CNN
	1    4350 4500
	0    1    1    0   
$EndComp
$Comp
L CONN_ZTEX_AB P1
U 1 1 56BE923A
P 3050 2950
F 0 "P1" H 3150 4600 50  0000 L CNN
F 1 "AB" H 3050 4600 50  0000 R CNN
F 2 "Pin_Headers:Pin_Header_Straight_2x32" H 3050 2550 60  0001 C CNN
F 3 "" H 3050 2550 60  0000 C CNN
	1    3050 2950
	1    0    0    -1  
$EndComp
$Comp
L CONN_ZTEX_CD P2
U 1 1 56BE9241
P 4600 2950
F 0 "P2" H 4700 4600 50  0000 L CNN
F 1 "CD" H 4600 4600 50  0000 R CNN
F 2 "Pin_Headers:Pin_Header_Straight_2x32" H 4600 2550 60  0001 C CNN
F 3 "" H 4600 2550 60  0000 C CNN
	1    4600 2950
	1    0    0    -1  
$EndComp
Text GLabel 4950 3600 2    60   Output ~ 0
TSYNC
Text GLabel 4950 3700 2    60   Output ~ 0
TDIN
Text GLabel 4950 3800 2    60   Output ~ 0
TDOUT
Text GLabel 4950 3900 2    60   Output ~ 0
TRPLY
Text GLabel 4950 4000 2    60   Output ~ 0
TREF
Text GLabel 4950 4100 2    60   Output ~ 0
TDMR
Text GLabel 4950 4300 2    60   Output ~ 0
TDMGO
Text GLabel 4950 4200 2    60   Output ~ 0
TIAKO
Text GLabel 4950 1600 2    60   Output ~ 0
TSACK
Text GLabel 4950 1700 2    60   Output ~ 0
TIRQ4
Text GLabel 4950 1800 2    60   Output ~ 0
TIRQ5
Text GLabel 4950 1900 2    60   Output ~ 0
TIRQ6
Text GLabel 4950 2000 2    60   Output ~ 0
TIRQ7
Text GLabel 3400 2500 2    60   Input ~ 0
RSYNC
Text GLabel 4350 1600 0    60   Input ~ 0
RDIN
Text GLabel 4350 1700 0    60   Input ~ 0
RDOUT
Text GLabel 4350 1800 0    60   Input ~ 0
RRPLY
Text GLabel 4350 1900 0    60   Input ~ 0
RREF
Text GLabel 4350 2000 0    60   Input ~ 0
RDMR
Text GLabel 4350 2600 0    60   Input ~ 0
RSACK
Text GLabel 4350 2100 0    60   Input ~ 0
RIRQ4
Text GLabel 4350 2200 0    60   Input ~ 0
RIRQ5
Text GLabel 4350 2300 0    60   Input ~ 0
RIRQ6
Text GLabel 4350 2400 0    60   Input ~ 0
RIRQ7
Text GLabel 4350 3200 0    60   Input ~ 0
RINIT
Text GLabel 4350 3700 0    60   Input ~ 0
RDCOK
Text GLabel 4350 3600 0    60   Input ~ 0
RPOK
Text GLabel 4350 3800 0    60   Input ~ 0
RDMGI
Text GLabel 4350 3900 0    60   Input ~ 0
RIAKI
NoConn ~ 2800 2800
NoConn ~ 3400 2800
NoConn ~ 2800 3000
NoConn ~ 3400 3000
NoConn ~ 2800 4400
NoConn ~ 3400 4400
NoConn ~ 2800 4500
NoConn ~ 2350 3200
NoConn ~ 4350 3300
NoConn ~ 2350 3500
NoConn ~ 4350 3400
NoConn ~ 2800 3800
NoConn ~ 2400 1900
NoConn ~ 4950 2100
NoConn ~ 4950 2200
NoConn ~ 4350 2500
NoConn ~ 4950 2700
NoConn ~ 4350 2800
NoConn ~ 4350 2900
NoConn ~ 4950 2900
NoConn ~ 4350 3100
NoConn ~ 4950 3100
NoConn ~ 4950 3200
NoConn ~ 4950 3300
NoConn ~ 4950 3400
NoConn ~ 4950 3500
NoConn ~ 4350 3500
NoConn ~ 4350 4400
NoConn ~ 4950 4400
Text Notes 3300 1200 0    60   ~ 12
ZTEX 2.13 FPGA Module Connector
Wire Notes Line
	5700 1050 5700 4650
Wire Notes Line
	5700 4650 2300 4650
Wire Notes Line
	5700 1050 2300 1050
Wire Notes Line
	2300 1050 2300 4650
Text GLabel 4350 4000 0    60   Input ~ 0
RHALT
Text GLabel 3750 7000 0    60   Input ~ 0
IPclk
Text GLabel 3750 7250 0    60   Input ~ 0
IPdata
Text GLabel 3750 7500 0    60   Input ~ 0
IPlatch
Text GLabel 4750 6950 2    60   Output ~ 0
IPclk_P
Text GLabel 4750 7050 2    60   Output ~ 0
IPclk_N
Text GLabel 4750 7200 2    60   Output ~ 0
IPdata_P
Text GLabel 4750 7300 2    60   Output ~ 0
IPdata_N
Text GLabel 4750 7450 2    60   Output ~ 0
IPlatch_P
Text GLabel 4750 7550 2    60   Output ~ 0
IPlatch_N
$Comp
L +12V #PWR0138
U 1 1 56BE94C0
P 5750 7150
F 0 "#PWR0138" H 5750 7000 50  0001 C CNN
F 1 "+12V" H 5750 7290 50  0000 C CNN
F 2 "" H 5750 7150 60  0000 C CNN
F 3 "" H 5750 7150 60  0000 C CNN
	1    5750 7150
	1    0    0    -1  
$EndComp
$Comp
L +12V #PWR0139
U 1 1 56BE94C6
P 6350 7150
F 0 "#PWR0139" H 6350 7000 50  0001 C CNN
F 1 "+12V" H 6350 7290 50  0000 C CNN
F 2 "" H 6350 7150 60  0000 C CNN
F 3 "" H 6350 7150 60  0000 C CNN
	1    6350 7150
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR0140
U 1 1 56BE94CC
P 5650 7650
F 0 "#PWR0140" H 5650 7400 50  0001 C CNN
F 1 "GND" H 5650 7500 50  0001 C CNN
F 2 "" H 5650 7650 60  0000 C CNN
F 3 "" H 5650 7650 60  0000 C CNN
	1    5650 7650
	-1   0    0    -1  
$EndComp
$Comp
L GND #PWR0141
U 1 1 56BE94D2
P 6450 7650
F 0 "#PWR0141" H 6450 7400 50  0001 C CNN
F 1 "GND" H 6450 7500 50  0001 C CNN
F 2 "" H 6450 7650 60  0000 C CNN
F 3 "" H 6450 7650 60  0000 C CNN
	1    6450 7650
	-1   0    0    -1  
$EndComp
Text Notes 3850 5900 0    60   ~ 12
Indicator Panel
Text GLabel 5800 6300 0    60   Input ~ 0
IPclk_P
Text GLabel 6300 6300 2    60   Input ~ 0
IPclk_N
Text GLabel 5800 6100 0    60   Input ~ 0
IPdata_P
Text GLabel 6300 6100 2    60   Input ~ 0
IPdata_N
Text GLabel 5800 6000 0    60   Input ~ 0
IPlatch_P
Text GLabel 6300 6000 2    60   Input ~ 0
IPlatch_N
NoConn ~ 5800 6200
NoConn ~ 6300 6200
Wire Wire Line
	5650 7300 5650 7650
Wire Wire Line
	5650 7600 5800 7600
Wire Wire Line
	5800 7300 5650 7300
Wire Wire Line
	6450 7600 6300 7600
Wire Wire Line
	6450 7300 6450 7650
Wire Wire Line
	6300 7300 6450 7300
Wire Wire Line
	6350 7150 6350 7500
Wire Wire Line
	6350 7400 6300 7400
Wire Wire Line
	6350 7500 6300 7500
Wire Wire Line
	5800 7400 5750 7400
Wire Wire Line
	5750 7150 5750 7500
Wire Wire Line
	5750 7500 5800 7500
Wire Notes Line
	3300 8300 6900 8300
Wire Notes Line
	6900 8300 6900 5550
Wire Notes Line
	6900 5550 3300 5550
Wire Notes Line
	3300 5550 3300 8300
$Comp
L CONN_02X16 P103
U 1 1 56BF62BD
P 1950 7000
F 0 "P103" H 1950 7850 50  0000 C CNN
F 1 "Logic Analyzer" V 1950 7000 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Straight_2x16" H 1950 5900 50  0001 C CNN
F 3 "" H 1950 5900 50  0000 C CNN
	1    1950 7000
	1    0    0    -1  
$EndComp
$Comp
L MAX3033E U401
U 1 1 56CCED40
P 3950 6800
F 0 "U401" H 4500 7050 60  0000 C CNN
F 1 "MAX3033E" H 4050 7050 60  0000 C CNN
F 2 "Housings_SOIC:SOIC-16_3.9x9.9mm_Pitch1.27mm" H 3950 6800 60  0001 C CNN
F 3 "" H 3950 6800 60  0000 C CNN
	1    3950 6800
	1    0    0    -1  
$EndComp
Wire Wire Line
	3650 6800 3750 6800
Wire Wire Line
	3650 6600 3650 6800
Wire Wire Line
	3750 6700 3650 6700
Connection ~ 3650 6700
$Comp
L +3V3 #PWR0142
U 1 1 56CCF177
P 3650 6600
F 0 "#PWR0142" H 3650 6450 50  0001 C CNN
F 1 "+3V3" H 3650 6740 50  0000 C CNN
F 2 "" H 3650 6600 50  0000 C CNN
F 3 "" H 3650 6600 50  0000 C CNN
	1    3650 6600
	1    0    0    -1  
$EndComp
$Comp
L CONN_02X04 P102
U 1 1 56CCF1EB
P 6050 7450
F 0 "P102" H 6050 7700 50  0000 C CNN
F 1 "Power" H 6050 7200 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Angled_2x04" H 6050 6250 60  0001 C CNN
F 3 "" H 6050 6250 60  0000 C CNN
	1    6050 7450
	1    0    0    -1  
$EndComp
$Comp
L CONN_02X05 P101
U 1 1 56CCF25D
P 6050 6200
F 0 "P101" H 6050 6500 50  0000 C CNN
F 1 "Data" H 6050 5900 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Angled_2x05" H 6050 5000 60  0001 C CNN
F 3 "" H 6050 5000 60  0000 C CNN
	1    6050 6200
	1    0    0    -1  
$EndComp
Connection ~ 5750 7400
Connection ~ 6350 7400
Connection ~ 5650 7600
Connection ~ 6450 7600
Text GLabel 5800 6400 0    60   Input ~ 0
IPblank_P
Text GLabel 6300 6400 2    60   Input ~ 0
IPblank_N
Text GLabel 3750 7750 0    60   Input ~ 0
~IPblank
Text GLabel 4750 7700 2    60   Output ~ 0
IPblank_P
Text GLabel 4750 7800 2    60   Output ~ 0
IPblank_N
$Comp
L GND #PWR0143
U 1 1 56CE3906
P 4950 3000
F 0 "#PWR0143" H 4950 2750 50  0001 C CNN
F 1 "GND" H 4950 2850 50  0001 C CNN
F 2 "" H 4950 3000 60  0000 C CNN
F 3 "" H 4950 3000 60  0000 C CNN
	1    4950 3000
	0    -1   1    0   
$EndComp
$Comp
L GND #PWR0144
U 1 1 56CE3926
P 4950 4500
F 0 "#PWR0144" H 4950 4250 50  0001 C CNN
F 1 "GND" H 4950 4350 50  0001 C CNN
F 2 "" H 4950 4500 60  0000 C CNN
F 3 "" H 4950 4500 60  0000 C CNN
	1    4950 4500
	0    -1   1    0   
$EndComp
NoConn ~ 4950 1400
Text GLabel 2800 1600 0    60   Input ~ 0
RDAL0
Text GLabel 2800 1700 0    60   Input ~ 0
RDAL1
Text GLabel 2800 1800 0    60   Input ~ 0
RDAL2
Text GLabel 2800 1900 0    60   Input ~ 0
RDAL3
Text GLabel 2800 2000 0    60   Input ~ 0
RDAL4
Text GLabel 2800 2100 0    60   Input ~ 0
RDAL5
Text GLabel 2800 2200 0    60   Input ~ 0
RDAL6
Text GLabel 2800 2300 0    60   Input ~ 0
RDAL7
Text GLabel 2800 2400 0    60   Input ~ 0
RDAL8
Text GLabel 2800 2500 0    60   Input ~ 0
RDAL9
Text GLabel 2800 2600 0    60   Input ~ 0
RDAL10
Text GLabel 2800 2700 0    60   Input ~ 0
RDAL11
Text GLabel 2800 3100 0    60   Input ~ 0
RDAL12
Text GLabel 2800 3200 0    60   Input ~ 0
RDAL13
Text GLabel 2800 3300 0    60   Input ~ 0
RDAL14
Text GLabel 2800 3400 0    60   Input ~ 0
RDAL15
Text GLabel 2800 3500 0    60   Input ~ 0
RDAL16
Text GLabel 2800 3600 0    60   Input ~ 0
RDAL17
Text GLabel 2800 3700 0    60   Input ~ 0
RDAL18
Text GLabel 2800 3900 0    60   Input ~ 0
RDAL19
Text GLabel 2800 4000 0    60   Input ~ 0
RDAL20
Text GLabel 2800 4100 0    60   Input ~ 0
RDAL21
Text GLabel 3400 1600 2    60   Output ~ 0
TDAL0
Text GLabel 3400 1700 2    60   Output ~ 0
TDAL1
Text GLabel 3400 1800 2    60   Output ~ 0
TDAL2
Text GLabel 3400 1900 2    60   Output ~ 0
TDAL3
Text GLabel 3400 2000 2    60   Output ~ 0
TDAL4
Text GLabel 3400 2100 2    60   Output ~ 0
TDAL5
Text GLabel 3400 2200 2    60   Output ~ 0
TDAL6
Text GLabel 3400 2300 2    60   Output ~ 0
TDAL7
Text GLabel 3400 2400 2    60   Output ~ 0
TDAL8
Text GLabel 3400 2600 2    60   Output ~ 0
TDAL9
Text GLabel 3400 2700 2    60   Output ~ 0
TDAL10
Text GLabel 3400 3100 2    60   Output ~ 0
TDAL11
Text GLabel 3400 3200 2    60   Output ~ 0
TDAL12
Text GLabel 3400 3300 2    60   Output ~ 0
TDAL13
Text GLabel 3400 3400 2    60   Output ~ 0
TDAL14
Text GLabel 3400 3500 2    60   Output ~ 0
TDAL15
Text GLabel 3400 3600 2    60   Output ~ 0
TDAL16
Text GLabel 3400 3700 2    60   Output ~ 0
TDAL17
Text GLabel 3400 3800 2    60   Output ~ 0
TDAL18
Text GLabel 3400 3900 2    60   Output ~ 0
TDAL19
Text GLabel 3400 4000 2    60   Output ~ 0
TDAL20
Text GLabel 3400 4100 2    60   Output ~ 0
TDAL21
Text GLabel 3400 4200 2    60   Output ~ 0
TBS7
Text GLabel 3400 4300 2    60   Output ~ 0
TWTBT
Text GLabel 2800 4200 0    60   Input ~ 0
RBS7
Text GLabel 2800 4300 0    60   Input ~ 0
RWTBT
NoConn ~ 4350 1400
$EndSCHEMATC
