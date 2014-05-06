PREFIX = /usr/local/bin

.PHONY: all
all: test

GOOGLE_CALENDAR_SOURCE_FILE = GoogleCalendar.py
GOOGLE_CALENDAR_SOURCE_PATH = $(CURDIR)/$(GOOGLE_CALENDAR_SOURCE_FILE)
GOOGLE_CALENDAR_TARGET_FILE = export_$(basename $(GOOGLE_CALENDAR_SOURCE_FILE))
GOOGLE_CALENDAR_TARGET_PATH = $(PREFIX)/$(GOOGLE_CALENDAR_TARGET_FILE)
$(GOOGLE_CALENDAR_TARGET_PATH): $(GOOGLE_CALENDAR_SOURCE_PATH)
	cp $(GOOGLE_CALENDAR_SOURCE_PATH) $(GOOGLE_CALENDAR_TARGET_PATH)

LIBRARYTHING_SOURCE_FILE = LibraryThing.sh
LIBRARYTHING_SOURCE_PATH = $(CURDIR)/$(LIBRARYTHING_SOURCE_FILE)
LIBRARYTHING_TARGET_FILE = export_$(basename $(LIBRARYTHING_SOURCE_FILE))
LIBRARYTHING_TARGET_PATH = $(PREFIX)/$(LIBRARYTHING_TARGET_FILE)
$(LIBRARYTHING_TARGET_PATH): $(LIBRARYTHING_SOURCE_PATH)
	cp $(LIBRARYTHING_SOURCE_PATH) $(LIBRARYTHING_TARGET_PATH)

WORDPRESS_COM_SOURCE_FILE = WordPress.com.sh
WORDPRESS_COM_SOURCE_PATH = $(CURDIR)/$(WORDPRESS_COM_SOURCE_FILE)
WORDPRESS_COM_TARGET_FILE = export_$(basename $(WORDPRESS_COM_SOURCE_FILE))
WORDPRESS_COM_TARGET_PATH = $(PREFIX)/$(WORDPRESS_COM_TARGET_FILE)
$(WORDPRESS_COM_TARGET_PATH): $(WORDPRESS_COM_SOURCE_PATH)
	cp $(WORDPRESS_COM_SOURCE_PATH) $(WORDPRESS_COM_TARGET_PATH)

PEP8_OPTIONS = --max-line-length=120

test: posix-shell-test-syntax
	make python-pep8

# Static targets
.PHONY: crontab-warning
crontab-warning:
	@echo "WARNING: BACK UP YOUR CRONTAB FIRST!"

.PHONY: install-google-calendar uninstall-google-calendar
install-google-calendar: $(GOOGLE_CALENDAR_TARGET_PATH)

uninstall-google-calendar:
	rm -f $(GOOGLE_CALENDAR_TARGET_PATH)

.PHONY: install-crontab-google-calendar
install-crontab-google-calendar: crontab-warning $(GOOGLE_CALENDAR_TARGET_PATH)
	@while [ -z "$$GOOGLE_USER" ]; do \
		read -r -p "Google user name: " GOOGLE_USER;\
	done && \
	while [ -z "$$GOOGLE_PASSWORD" ]; do \
		read -r -p "Google password: " GOOGLE_PASSWORD; \
	done && \
	while [ -z "$$GOOGLE_CALENDAR_BACKUP_PATH" ]; do \
		read -r -p "Google Calendar backup directory path: " GOOGLE_CALENDAR_BACKUP_PATH; \
	done && \
	( \
		CRONTAB_NOHEADER=Y crontab -l || true; \
		printf '%s' \
			'@midnight ' \
			'"$(GOOGLE_CALENDAR_TARGET_PATH)" ' \
			"\"$$GOOGLE_USER\" " \
			"\"$$GOOGLE_PASSWORD\" " \
			"\"$$GOOGLE_CALENDAR_BACKUP_PATH\""; \
		printf '\n') | crontab -

.PHONY: install-librarything uninstall-librarything
install-librarything: $(LIBRARYTHING_TARGET_PATH)

uninstall-librarything:
	rm -f $(LIBRARYTHING_TARGET_PATH)

.PHONY: install-crontab-librarything
install-crontab-librarything: crontab-warning $(LIBRARYTHING_TARGET_PATH)
	@while [ -z "$$LIBRARYTHING_USER" ]; do \
		read -r -p "LibraryThing user name: " LIBRARYTHING_USER;\
	done && \
	while [ -z "$$LIBRARYTHING_PASSWORD" ]; do \
		read -r -p "LibraryThing password: " LIBRARYTHING_PASSWORD; \
	done && \
	while [ -z "$$LIBRARYTHING_BACKUP_PATH" ]; do \
		read -r -p "LibraryThing backup path: " LIBRARYTHING_BACKUP_PATH; \
	done && \
	( \
		CRONTAB_NOHEADER=Y crontab -l || true; \
		printf '%s' \
			'@midnight ' \
			'"$(LIBRARYTHING_TARGET_PATH)" ' \
			"\"$$LIBRARYTHING_USER\" " \
			"\"$$LIBRARYTHING_PASSWORD\" " \
			"\"$$LIBRARYTHING_BACKUP_PATH\""; \
		printf '\n') | crontab -

.PHONY: install-wordpress-com uninstall-wordpress-com
install-wordpress-com: $(WORDPRESS_COM_TARGET_PATH)

uninstall-wordpress-com:
	rm -f $(WORDPRESS_COM_TARGET_PATH)

.PHONY: install-crontab-wordpress-com
install-crontab-wordpress-com: crontab-warning $(WORDPRESS_COM_TARGET_PATH)
	@while [ -z "$$WORDPRESS_COM_USER" ]; do \
		read -r -p "wordpress.com user name: " WORDPRESS_COM_USER;\
	done && \
	while [ -z "$$WORDPRESS_COM_PASSWORD" ]; do \
		read -r -p "wordpress.com password: " WORDPRESS_COM_PASSWORD; \
	done && \
	while [ -z "$$WORDPRESS_COM_DOMAIN" ]; do \
		read -r -p "wordpress.com sub-domain name: " WORDPRESS_COM_DOMAIN; \
	done && \
	while [ -z "$$WORDPRESS_COM_BACKUP_PATH" ]; do \
		read -r -p "wordpress.com backup path: " WORDPRESS_COM_BACKUP_PATH; \
	done && \
	( \
		CRONTAB_NOHEADER=Y crontab -l || true; \
		printf '%s' \
			'@midnight ' \
			'"$(WORDPRESS_COM_TARGET_PATH)" ' \
			"\"$$WORDPRESS_COM_USER\" " \
			"\"$$WORDPRESS_COM_PASSWORD\" " \
			"\"$$WORDPRESS_COM_DOMAIN\" " \
			"\"$$WORDPRESS_COM_BACKUP_PATH\""; \
		printf '\n') | crontab -

.PHONY: install
install: \
	install-google-calendar \
	install-librarything \
	install-wordpress-com
	pip2 install --requirement requirements.txt

.PHONY: uninstall
uninstall: \
	uninstall-google-calendar \
	uninstall-librarything \
	uninstall-wordpress-com

install-crontab: \
	install-crontab-google-calendar \
	install-crontab-librarything \
	install-crontab-wordpress-com

include make-includes/posix-shell.mk
include make-includes/python.mk
include make-includes/variables.mk
