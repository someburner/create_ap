PREFIX=/usr
MANDIR=$(PREFIX)/share/man
BINDIR=$(PREFIX)/bin

all:
	@echo "Run 'make install' for installation."
	@echo "Run 'make uninstall' for uninstallation."

# CONF_INIT ?=create_ap
CONF_INIT ?=create_ap_test


show_nat:
	iptables -t nat -L --line-numbers -n

################################################################################
### By default this will create the following directories:
### 755 /usr/share/create_ap
### 755 /usr/share/create_ap/inc
### --------------------------------------------------------------
### contents of script/inc/*.sh will be copied into the latter.
### --------------------------------------------------------------
### Install Source locations
SRC_SCRIPT_MAIN=script/create_ap_test
SRC_SCRIPT_INCLUDES=script/inc

### Install Destinations
DST_SCRIPT_PARENT=/usr/share
DST_INC_PARENT=$(DST_SCRIPT_PARENT)/create_ap
DST_SCRIPT_INC_DIR=$(DST_INC_PARENT)/inc

install_scripts:
	echo "installing includes..."
	install -Ddm755 $(SRC_SCRIPT_INCLUDES) $(DST_SCRIPT_INC_DIR)
	install -Dm755 $(SRC_SCRIPT_INCLUDES)/* $(DST_SCRIPT_INC_DIR)/
	echo "installing main script..."
	install -Dm755 $(SRC_SCRIPT_MAIN) $(DESTDIR)$(BINDIR)/create_ap
	install -Dm644 create_ap.conf $(DESTDIR)/etc/create_ap.conf
	[ ! -d /lib/systemd/system ] || install -Dm644 create_ap.service $(DESTDIR)$(PREFIX)/lib/systemd/system/create_ap.service
	install -Dm644 bash_completion $(DESTDIR)$(PREFIX)/share/bash-completion/completions/create_ap
	install -Dm644 README.md $(DESTDIR)$(PREFIX)/share/doc/create_ap/README.md
	echo "Done!"

uninstall_scripts:
	echo "Removing includes..."
	rm -rf $(DST_SCRIPT_INC_DIR)
	rmdir $(DST_INC_PARENT)
	echo "Removing program..."
	rm -f $(DESTDIR)$(BINDIR)/create_ap
	rm -f $(DESTDIR)/etc/create_ap.conf
	[ ! -f /lib/systemd/system/create_ap.service ] || rm -f $(DESTDIR)$(PREFIX)/lib/systemd/system/create_ap.service
	rm -f $(DESTDIR)$(PREFIX)/share/bash-completion/completions/create_ap
	rm -f $(DESTDIR)$(PREFIX)/share/doc/create_ap/README.md
	echo "Done!"
################################################################################


################################################################################
install_test:
	install -Dm755 $(CONF_INIT) $(DESTDIR)$(BINDIR)/create_ap
	install -Dm644 create_ap.conf $(DESTDIR)/etc/create_ap.conf
	[ ! -d /lib/systemd/system ] || install -Dm644 create_ap.service $(DESTDIR)$(PREFIX)/lib/systemd/system/create_ap.service
	install -Dm644 bash_completion $(DESTDIR)$(PREFIX)/share/bash-completion/completions/create_ap
	install -Dm644 README.md $(DESTDIR)$(PREFIX)/share/doc/create_ap/README.md

uninstall_test:
	rm -f $(DESTDIR)$(BINDIR)/create_ap
	rm -f $(DESTDIR)/etc/create_ap.conf
	[ ! -f /lib/systemd/system/create_ap.service ] || rm -f $(DESTDIR)$(PREFIX)/lib/systemd/system/create_ap.service
	rm -f $(DESTDIR)$(PREFIX)/share/bash-completion/completions/create_ap
	rm -f $(DESTDIR)$(PREFIX)/share/doc/create_ap/README.md
################################################################################



################################################################################
install:
	install -Dm755 create_ap $(DESTDIR)$(BINDIR)/create_ap
	install -Dm644 create_ap.conf $(DESTDIR)/etc/create_ap.conf
	[ ! -d /lib/systemd/system ] || install -Dm644 create_ap.service $(DESTDIR)$(PREFIX)/lib/systemd/system/create_ap.service
	install -Dm644 bash_completion $(DESTDIR)$(PREFIX)/share/bash-completion/completions/create_ap
	install -Dm644 README.md $(DESTDIR)$(PREFIX)/share/doc/create_ap/README.md

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/create_ap
	rm -f $(DESTDIR)/etc/create_ap.conf
	[ ! -f /lib/systemd/system/create_ap.service ] || rm -f $(DESTDIR)$(PREFIX)/lib/systemd/system/create_ap.service
	rm -f $(DESTDIR)$(PREFIX)/share/bash-completion/completions/create_ap
	rm -f $(DESTDIR)$(PREFIX)/share/doc/create_ap/README.md
################################################################################

#### EOF
