PREFIX ?= $(HOME)/.local

install:
	mkdir -p $(PREFIX)/bin
	install -m 755 branx $(PREFIX)/bin/branx

test:
	bash test/test_clone.sh

uninstall:
	rm -f $(PREFIX)/bin/branx

.PHONY: install test uninstall
