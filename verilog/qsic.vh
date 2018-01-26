//	-*- mode: Verilog; fill-column: 96 -*-
//
// Common definitions for the Verilog in QSIC
//
// Copyright 2015, 2018 Noel Chiappa and David Bridgham
//

// Interrupt Priorities
`define INTP_4 2'd0
`define INTP_5 2'd1
`define INTP_6 2'd2
`define INTP_7 2'd3

// Addresses on the microcontroller bus
//
// The pattern for disk devices is:
// N = interrupt line
// M = N*4
//   read-only registers
// ??_CMD M
// ??_DA_LOW M+1
// ??_DA_HI M+2
//   write-only registers
// ??_ADDR M
// ??_INT M+1
// ??_STAT M+2
//   read/write register
// ??_FIFO M+3

// Devices (N)
`define uDEV_QSIC 0
`define uDEV_RK 1

// Registers for each device
`define DEV_CMD 0		// R
`define DEV_DA_LOW 1		// R
`define DEV_DA_HI 2		// R
`define DEV_ADDR 0		// W
`define DEV_INT 1		// W
`define DEV_STAT 2		// W
`define DEV_FIFO 3		// R/W

// Device Mode (high two bits of DEV_INT
`define MODE_DISABLED 2'o0
`define MODE_Q22 2'o1
`define MODE_Q18 2'o2
`define MODE_Q16 2'o3

