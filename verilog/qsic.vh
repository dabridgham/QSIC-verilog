//	-*- mode: Verilog; fill-column: 96 -*-
//
// Common definitions for the Verilog in QSIC
//
// Copyright 2015 - 2020 Noel Chiappa and David Bridgham
//

// Board Type in the Config
`define TYPE_USIC 2'd0
`define TYPE_QSIC 2'd1

`define CONF_VERSION 4'd0	// We're on Version 0 of the configuration
`define CONF_REG_ADDR_BASE 13'o17720	// The bus address of the conf registers (two registers)

// Controller Types
`define CTR_IP 5'd0		// Indicator Panels
`define CTR_RK 5'd1		// RK11-F
`define CTR_RP 5'd2		// RP11-D
`define CTR_EN 5'd3		// Enable+
`define CTR_I1010 5'd4		// Interlan 1010
// Storage Device Types
`define SD_SD 5'd0		// Secure Digital Card
`define SD_RAM 5'd1		// RAM Disk
`define SD_USB 5'd3		// USB Device

// Interrupt Priorities
`define INTP_4 2'd0
`define INTP_5 2'd1
`define INTP_6 2'd2
`define INTP_7 2'd3

// Storage Devices in the Load Table
`define PACK_SD0 3'o0
`define PACK_SD1 3'o1
`define PACK_RAMDISK 3'o2
`define PACK_USB0 3'o3
`define PACK_USB1 3'o4
`define PACK_USB2 3'o5
`define PACK_USB3 3'o6
`define PACK_USB4 3'o7

