
PROG=confman
PREFIX=/usr/local
#CPPFLAGS=-I src -x assembler-with-cpp -P -w

all: ${PROG}

clean:
	rm -rf build/

${PROG}:
	mkdir -p build
	awk \
		-v includedir="$(shell pwd)/src" \
		-f src/glue.awk src/main.sh > build/confman.i
	make strip

strip:
	grep -v '^ *\#' build/confman.i > build/confman

install: ${PROG}
	install -m 755 build/confman ${PREFIX}/bin
