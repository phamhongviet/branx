PREFIX ?= $(HOME)/.local

install:
	mkdir -p $(PREFIX)/bin
	install -m 755 branx $(PREFIX)/bin/branx

uninstall:
	rm -f $(PREFIX)/bin/branx

.PHONY: install uninstall
