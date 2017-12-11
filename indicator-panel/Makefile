PDFS = inlay-qbus.pdf inlay-rk11.pdf inlay-rp11.pdf inlay-rp11-d-1.pdf inlay-rp11-d-2.pdf 

all: $(PDFS)
push: all
	rsync --verbose --progress $(PDFS) server:pdp10/qsic

.SUFFIXES: .svg .pdf

.svg.pdf:
	inkscape -A $@ $<
