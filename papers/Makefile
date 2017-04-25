IMAGES = grant1.png grant2.png grant3.png grant4.png grant5.png grant6.png qint2.png qint3.png
SRC = bus-arbitration.txt $(IMAGES)

all: bus-arbitration.html
bus-arbitration.html: bus-arbitration.adoc
	asciidoc bus-arbitration.adoc

# the asciidoctor pdf backend doesn't handle footnotes or overlines correctly
bus-arbitration.pdf: bus-arbitration.adoc $(IMAGES)
	a2x -f pdf bus-arbitration.adoc


grant1.png: images/grant1.pdf
	pdftoppm -singlefile -png images/grant1.pdf grant1
grant2.png: images/grant2.pdf
	pdftoppm -singlefile -png images/grant2.pdf grant2
grant3.png: images/grant3.pdf
	pdftoppm -singlefile -png images/grant3.pdf grant3
grant4.png: images/grant4.pdf
	pdftoppm -singlefile -png images/grant4.pdf grant4
grant5.png: images/grant5.pdf
	pdftoppm -singlefile -png images/grant5.pdf grant5
grant6.png: images/grant6.pdf
	pdftoppm -singlefile -png images/grant6.pdf grant6
qint2.png: images/qint2.pdf
	pdftoppm -singlefile -png images/qint2.pdf qint2
qint3.png: images/qint3.pdf
	pdftoppm -singlefile -png images/qint3.pdf qint3

install: all
	rsync --progress -t bus-arbitration.* *.png server:public_html/papers/bus-arbitration/
