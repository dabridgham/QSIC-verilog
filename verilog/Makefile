ICOPTS = -DSIM -WALL
SIMOPTS = -N
INCLUDES = qsic.vh
QBUS_FILES = tb_qbus.v qdrv.v qsync.v areg.v areg_block.v sreg_block.v sim_memory.v
DMA_FILES = tb_dma.v qdrv.v master.v sim_proc.v

ALL: tb_qbus.check

tb_qbus.check: $(INCLUDES) $(QBUS_FILES)
	iverilog -tnull $(ICOPTS) $(QBUS_FILES)

tb_dma.check: $(INCLUDES) $(DMA_FILES)
	iverilog -tnull $(ICOPTS) $(DMA_FILES)

test: test.dma

test.qbus: tb_qbus.vvp
	./tb_qbus.vvp $(SIMOPTS)

tb_qbus.vvp: Makefile $(INCLUDES) $(QBUS_FILES)
	iverilog $(ICOPTS) -o tb_qbus.vvp $(QBUS_FILES)

test.dma: tb_dma.vvp
	./tb_qbus.vvp $(SIMOPTS)

tb_dma.vvp: Makefile $(INCLUDES) $(DMA_FILES)
	iverilog $(ICOPTS) -o tb_qbus.vvp $(DMA_FILES)


.SUFFIXES: .v .check

# Test compile to check for error
.v.check:
	iverilog -tnull $(ICOPTS) $<
