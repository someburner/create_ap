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
### Install Source locations
SRC_SCRIPT_DIR=script
SRC_SCRIPT_MAIN=$(SRC_SCRIPT_DIR)/create_ap_test
SRC_SCRIPT_INCLUDES=$(SRC_SCRIPT_DIR)/inc

### Install Destinations
DST_SCRIPT_PARENT=/usr/share
# /usr/share/create_ap <-- 755
DST_SCRIPT_DIR=$(DST_SCRIPT_PARENT)/create_ap
# /usr/share/create_ap/inc <-- 755
DST_SCRIPT_INC_DIR=$(DST_SCRIPT_DIR)/inc

install_scripts:
	echo "installing includes..."
	install -Ddm755 $(SRC_SCRIPT_INCLUDES) $(DST_SCRIPT_INC_DIR)
	install -Dm755 $(SRC_SCRIPT_INCLUDES)/* $(DST_SCRIPT_INC_DIR)/
	echo "installing main script..."
	echo "Done!"

# install -Dm755 $(SRC_SCRIPT_MAIN) $(DESTDIR)$(BINDIR)/create_ap
#########
# install -Dm644 create_ap.conf $(DESTDIR)/etc/create_ap.conf
# [ ! -d /lib/systemd/system ] || install -Dm644 create_ap.service $(DESTDIR)$(PREFIX)/lib/systemd/system/create_ap.service
# install -Dm644 bash_completion $(DESTDIR)$(PREFIX)/share/bash-completion/completions/create_ap
# install -Dm644 README.md $(DESTDIR)$(PREFIX)/share/doc/create_ap/README.md

uninstall_scripts:
	echo "Removing includes..."
	rm -rf $(DST_SCRIPT_INC_DIR)
	rmdir $(DST_SCRIPT_DIR)
	echo "Done!"
#########
# rm -f $(DESTDIR)$(BINDIR)/create_ap
# rm -f $(DESTDIR)/etc/create_ap.conf
# [ ! -f /lib/systemd/system/create_ap.service ] || rm -f $(DESTDIR)$(PREFIX)/lib/systemd/system/create_ap.service
# rm -f $(DESTDIR)$(PREFIX)/share/bash-completion/completions/create_ap
# rm -f $(DESTDIR)$(PREFIX)/share/doc/create_ap/README.md
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
