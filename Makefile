
PROG=confman
PREFIX=/usr/local
SHELLCHECK_OPTS=--exclude SC2181,SC2034,SC2010
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

shellcheck: ${PROG}
	docker run \
		-v "$(shell pwd)/src:/tmp/confman/src:ro" \
		shellcheck sh -c 'shellcheck ${SHELLCHECK_OPTS} --shell bash /tmp/confman/src/*.sh'
