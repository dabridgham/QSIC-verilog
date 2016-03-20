ICOPTS = -DSIM -WALL
SIMOPTS = -N
INCLUDES = qsic.vh
QBUS_FILES = tb_qbus.v qdrv.v qsic-pmo.v switch-register.v rkv11.v qmaster2908.v qinterrupt.v
DMA_FILES = tb_dma.v qdrv.v master.v sim_proc.v
BG_FILES = tb_bg.v bus-grant-mux.v

ALL: tb_qbus.check

tb_qbus.check: $(INCLUDES) $(QBUS_FILES)
	iverilog -tnull $(ICOPTS) $(QBUS_FILES)

tb_dma.check: $(INCLUDES) $(DMA_FILES)
	iverilog -tnull $(ICOPTS) $(DMA_FILES)

tb_bg.check: $(BG_FILES)
	iverilog -tnull $(BG_FILES)

rkv11.check: rkv11.v disk-uc.v qreg.v $(INCLUDES)
	iverilog -tnull rkv11.v disk-uc.v qreg.v $(INCLUDES)

test: test.qbus

test.bg: test_bg.vvp
	./tb_bg.vvp $(SIMOPTS)

test_bg.vvp: Makefile $(BG_FILES)
	iverilog $(ICOPTS) -o tb_bg.vvp $(BG_FILES)

test.qbus: tb_qbus.vvp
	./tb_qbus.vvp $(SIMOPTS)

tb_qbus.vvp: Makefile $(INCLUDES) $(QBUS_FILES)
	iverilog $(ICOPTS) -o tb_qbus.vvp $(QBUS_FILES)



tb-qm8.check: tb-qm8.v qmaster2908.v
	iverilog -tnull $(ICOPTS) tb-qm8.v qmaster2908.v

tb-qm8.vvp: tb-qm8.v qmaster2908.v
	iverilog $(ICOPTS) -o tb-qm8.vvp tb-qm8.v qmaster2908.v

test.qm8: tb-qm8.vvp
	./tb-qm8.vvp $(SIMOPTS)


tb-qint.check: tb-qint.v qinterrupt.v
	iverilog -tnull $(ICOPTS) tb-qint.v qinterrupt.v

tb-qint.vvp: tb-qint.v qinterrupt.v
	iverilog $(ICOPTS) -o tb-qint.vvp tb-qint.v qinterrupt.v

test.qint: tb-qint.vvp
	./tb-qint.vvp $(SIMOPTS)


tb-sd-crc.vvp: Makefile sd-crc.v
	iverilog -DTB_CRC $(ICOPTS) -o tb-sd-crc.vvp sd-crc.v
test.sd-crc: tb-sd-crc.vvp
	./tb-sd-crc.vvp $(SIMOPTS)


sd-cmd.check: Makefile sd-cmd.v sd-crc.v
	iverilog -tnull -DTB_CMD $(ICOPTS) sd-cmd.v sd-crc.v
tb-sd-cmd.vvp: Makefile sd-cmd.v sd-crc.v
	iverilog -DTB_CMD $(ICOPTS) -o tb-sd-crc.vvp sd-cmd.v sd-crc.v
test.sd-cmd: tb-sd-cmd.vvp
	./tb-sd-cmd.vvp $(SIMOPTS)


test.dma: tb_dma.vvp
	./tb_qbus.vvp $(SIMOPTS)

tb_dma.vvp: Makefile $(INCLUDES) $(DMA_FILES)
	iverilog $(ICOPTS) -o tb_qbus.vvp $(DMA_FILES)


.SUFFIXES: .v .check

# Test compile to check for error
.v.check:
	iverilog -tnull $(ICOPTS) $<
