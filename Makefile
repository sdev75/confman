
PACKAGE = confman
PREFIX  ?= /usr/local
VERSION = $(shell cat "$(CURDIR)/VERSION")
SHELLCHECK_OPTS = --exclude SC2181,SC2034,SC2010
#CPPFLAGS=-I src -x assembler-with-cpp -P -w

all: $(PACKAGE)

.PHONY: clean
clean:
	rm -rf build/

$(PACKAGE):
	mkdir -p build
	$(MAKE) -C "$(CURDIR)" VERSION
	awk \
		-v includedir="$(shell pwd)/src" \
		-f src/glue.awk src/main.sh > build/confman.tmp
	sed -e 's|@PREFIX@|$(PREFIX)|' \
			-e 's|@VERSION@|$(VERSION)|' \
			build/confman.tmp > build/confman.i
	$(MAKE) -C "$(CURDIR)" strip

strip:
	head -n 1 build/confman.i > build/confman
	grep -v '^ *\#' build/confman.i >> build/confman

install: $(PACKAGE)
	install -m 755 build/confman "$(PREFIX)/bin"

.PHONY: VERSION
VERSION:
	v=$(VERSION); \
	m=$$(( $${v##*.} + 1 )); \
	echo -n "$${v%.*}.$$m" > "$(CURDIR)/VERSION"

shellcheck: $(PACKAGE)
	docker run \
		-v "$(shell pwd)/src:/tmp/confman/src:ro" \
		shellcheck sh -c 'shellcheck ${SHELLCHECK_OPTS} --shell bash /tmp/confman/src/*.sh'
