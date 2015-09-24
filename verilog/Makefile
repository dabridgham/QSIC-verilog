ICOPTS = -DSIM -WALL
SIMOPTS = -N
INCLUDES = qsic.vh
FILES = tb_qbus.v qdrv.v areg.v areg_block.v

ALL: tb_qbus.check

tb_qbus.check: $(INCLUDES) $(FILES)
	iverilog -tnull $(ICOPTS) $(FILES)

test: test.qbus

test.qbus: tb_qbus.vvp
	./tb_qbus.vvp $(SIMOPTS)

tb_qbus.vvp: Makefile $(INCLUDES) $(FILES)
	iverilog $(ICOPTS) -o tb_qbus.vvp $(FILES)


.SUFFIXES: .v .check

# Test compile to check for error
.v.check:
	iverilog -tnull $(ICOPTS) $<
