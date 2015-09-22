ICOPTS = -DSIM -WALL -pfileline=1
SIMOPTS = -N
INCLUDES = 
FILES = tb_qbus.v intf.v areg.v areg_block.v

ALL: tb_qbus.check

tb_qbus.check: $(FILES)
	iverilog -tnull $(ICOPTS) $(FILES)

test: test.qbus

test.qbus: tb_qbus.vvp
	./tb_qbus.vvp $(SIMOPTS)

tb_qbus.vvp: Makefile $(FILES)
	iverilog $(ICOPTS) -o tb_qbus.vvp $(FILES)


.SUFFIXES: .v .check

# Test compile to check for error
.v.check:
	iverilog -tnull $(ICOPTS) $<
