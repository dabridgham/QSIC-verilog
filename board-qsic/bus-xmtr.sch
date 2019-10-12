EESchema Schematic File Version 4
LIBS:qsic-cache
EELAYER 30 0
EELAYER END
$Descr A 11000 8500
encoding utf-8
Sheet 45 12
Title "Bus Transmitter and Level Converter"
Date "2019-09-30"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L myLib:74LVC8T245-units U5018
U 4 1 5DC34533
P 4300 3500
AR Path="/5DCB8CA6/5DCBEAC7/5DC0E33E/5DC34533" Ref="U5018"  Part="2" 
AR Path="/5DCB8CA6/5DCBEAC7/5DF09657/5DC34533" Ref="U5017"  Part="4" 
F 0 "U5017" H 4250 3069 60  0000 C CNN
F 1 "74LVC8T245-units" H 4250 2963 60  0000 C CNN
F 2 "Package_SO:SSOP-24_5.3x8.2mm_P0.65mm" H 4750 5400 60  0001 C CNN
F 3 "http://www.ti.com/lit/ds/symlink/sn74lvc8t245.pdf" H 4250 2857 60  0001 C CNN
	4    4300 3500
	1    0    0    -1  
$EndComp
$Comp
L myLib:DS8641-units U5008
U 2 1 5DC36147
P 6450 3500
AR Path="/5DCB8CA6/5DCBEAC7/5DC0E33E/5DC36147" Ref="U5008"  Part="2" 
AR Path="/5DCB8CA6/5DCBEAC7/5DF09657/5DC36147" Ref="U5003"  Part="2" 
F 0 "U5003" H 6450 4343 60  0000 C CNN
F 1 "DS8641-units" H 6450 4237 60  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 5925 3875 60  0001 C CNN
F 3 "http://pccomponents.com/datasheets/NATI-ds8641.pdf" H 6450 4131 60  0001 C CNN
	2    6450 3500
	1    0    0    -1  
$EndComp
Wire Wire Line
	5250 3500 5750 3500
NoConn ~ 7150 3500
Text HLabel 6450 4450 3    60   BiDi ~ 0
B
Wire Wire Line
	6450 4450 6450 4050
Text HLabel 2775 3500 0    60   Input ~ 0
T
Wire Wire Line
	2775 3500 3250 3500
$EndSCHEMATC
