PDFS = inlay-qbus.pdf inlay-qbus-2.pdf inlay-rk11.pdf inlay-rp11.pdf inlay-rp11-d-1.pdf inlay-rp11-d-2.pdf  inlay-rk11-f.pdf

all: $(PDFS)
push: all
	rsync --verbose --progress $(PDFS) server:pdp10/qsic

inlay-qbus-2-poster.ps: inlay-qbus-2.ps
	poster -m letter -s 1 -o $@ $<

inlay-rp11-d-2-poster.ps: inlay-rp11-d-2.ps
	poster -m letter -s 1 -o $@ $<

inlay-rk11-f-poster.ps: inlay-rk11-f.ps
	poster -m letter -s 1 -o $@ $<

.SUFFIXES: .svg .pdf .ps

.svg.pdf:
	inkscape -A $@ $<

.pdf.ps:
	pdf2ps $< $@
