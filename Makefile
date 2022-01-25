
PROG=confman
PREFIX=/usr/local
#CPPFLAGS=-I src -x assembler-with-cpp -P -w

all: ${PROG}

clean:
	rm -rf build/

${PROG}:
	mkdir -p $(shell pwd)/build
	awk -f src/glue.awk src/main.sh > $(shell pwd)/build/confman
	chmod +x $(shell pwd)/build/confman

install: ${PROG}
	install -m 755 build/confman ${PREFIX}/bin
