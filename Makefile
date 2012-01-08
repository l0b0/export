PREFIX = /usr/local/bin

DELICIOUS_SOURCE_FILE = Delicious.sh
DELICIOUS_SOURCE_PATH = $(CURDIR)/$(DELICIOUS_SOURCE_FILE)
DELICIOUS_TARGET_FILE = export_$(basename $(DELICIOUS_SOURCE_FILE))
DELICIOUS_TARGET_PATH = $(PREFIX)/$(DELICIOUS_TARGET_FILE)
$(DELICIOUS_TARGET_PATH): $(DELICIOUS_SOURCE_PATH)
	cp $(DELICIOUS_SOURCE_PATH) $(DELICIOUS_TARGET_PATH)

GOOGLE_AUTH_SOURCE_FILE = GoogleAuth.sh
GOOGLE_AUTH_SOURCE_PATH = $(CURDIR)/$(GOOGLE_AUTH_SOURCE_FILE)
GOOGLE_AUTH_TARGET_FILE = $(basename $(GOOGLE_AUTH_SOURCE_FILE))
GOOGLE_AUTH_TARGET_PATH = $(PREFIX)/$(GOOGLE_AUTH_TARGET_FILE)
$(GOOGLE_AUTH_TARGET_PATH): $(GOOGLE_AUTH_SOURCE_PATH)
	cp $(GOOGLE_AUTH_SOURCE_PATH) $(GOOGLE_AUTH_TARGET_PATH)

GOOGLE_CALENDAR_SOURCE_FILE = GoogleCalendar.sh
GOOGLE_CALENDAR_SOURCE_PATH = $(CURDIR)/$(GOOGLE_CALENDAR_SOURCE_FILE)
GOOGLE_CALENDAR_TARGET_FILE = export_$(basename $(GOOGLE_CALENDAR_SOURCE_FILE))
GOOGLE_CALENDAR_TARGET_PATH = $(PREFIX)/$(GOOGLE_CALENDAR_TARGET_FILE)
$(GOOGLE_CALENDAR_TARGET_PATH): $(GOOGLE_CALENDAR_SOURCE_PATH) $(GOOGLE_AUTH_TARGET_PATH)
	cp $(GOOGLE_CALENDAR_SOURCE_PATH) $(GOOGLE_CALENDAR_TARGET_PATH)

GOOGLE_READER_SOURCE_FILE = GoogleReader.sh
GOOGLE_READER_SOURCE_PATH = $(CURDIR)/$(GOOGLE_READER_SOURCE_FILE)
GOOGLE_READER_TARGET_FILE = export_$(basename $(GOOGLE_READER_SOURCE_FILE))
GOOGLE_READER_TARGET_PATH = $(PREFIX)/$(GOOGLE_READER_TARGET_FILE)
$(GOOGLE_READER_TARGET_PATH): $(GOOGLE_READER_SOURCE_PATH) $(GOOGLE_AUTH_TARGET_PATH)
	cp $(GOOGLE_READER_SOURCE_PATH) $(GOOGLE_READER_TARGET_PATH)

LAST_FM_SOURCE_FILE = last.fm.pl
LAST_FM_SOURCE_PATH = $(CURDIR)/$(LAST_FM_SOURCE_FILE)
LAST_FM_TARGET_FILE = export_$(basename $(LAST_FM_SOURCE_FILE))
LAST_FM_TARGET_PATH = $(PREFIX)/$(LAST_FM_TARGET_FILE)
$(LAST_FM_TARGET_PATH): $(LAST_FM_SOURCE_PATH)
	cp $(LAST_FM_SOURCE_PATH) $(LAST_FM_TARGET_PATH)

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

# Static targets
.PHONY: install-delicious uninstall-delicious
install-delicious: $(DELICIOUS_TARGET_PATH)
uninstall-delicious:
	rm -f $(DELICIOUS_TARGET_PATH)

.PHONY: crontab-warning
crontab-warning:
	@echo "WARNING: BACK UP YOUR CRONTAB FIRST!"

.PHONY: install-crontab-delicious
install-crontab-delicious: crontab-warning $(DELICIOUS_TARGET_PATH)
	@while [ -z "$$DELICIOUS_USER" ]; do \
		read -r -p "Delicious user name: " DELICIOUS_USER;\
	done && \
	while [ -z "$$DELICIOUS_PASSWORD" ]; do \
		read -r -p "Delicious password: " DELICIOUS_PASSWORD; \
	done && \
	while [ -z "$$DELICIOUS_BACKUP_PATH" ]; do \
		read -r -p "Delicious backup path: " DELICIOUS_BACKUP_PATH; \
	done && \
	( \
		CRONTAB_NOHEADER=Y crontab -l || true; \
		printf '%s' \
			'@midnight ' \
			'"$(DELICIOUS_TARGET_PATH)" ' \
			"\"$$DELICIOUS_USER\" " \
			"\"$$DELICIOUS_PASSWORD\" " \
			"\"$$DELICIOUS_BACKUP_PATH\""; \
		printf '\n') | crontab -

.PHONY: install-google-calendar uninstall-google-calendar
install-google-calendar: $(GOOGLE_CALENDAR_TARGET_PATH)
	sed -i -e \
		"s/$(GOOGLE_AUTH_SOURCE_FILE)/$(GOOGLE_AUTH_TARGET_FILE)/g" \
		$(GOOGLE_CALENDAR_TARGET_PATH)

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

.PHONY: install-google-reader uninstall-google-reader
install-google-reader: $(GOOGLE_READER_TARGET_PATH)
	sed -i -e \
		"s/$(GOOGLE_AUTH_SOURCE_FILE)/$(GOOGLE_AUTH_TARGET_FILE)/g" \
		$(GOOGLE_READER_TARGET_PATH)

uninstall-google-reader:
	rm -f $(GOOGLE_READER_TARGET_PATH)

.PHONY: install-crontab-google-reader
install-crontab-google-reader: crontab-warning $(GOOGLE_READER_TARGET_PATH)
	@while [ -z "$$GOOGLE_USER" ]; do \
		read -r -p "Google user name: " GOOGLE_USER;\
	done && \
	while [ -z "$$GOOGLE_PASSWORD" ]; do \
		read -r -p "Google password: " GOOGLE_PASSWORD; \
	done && \
	while [ -z "$$GOOGLE_READER_BACKUP_PATH" ]; do \
		read -r -p "Google Reader backup path: " GOOGLE_READER_BACKUP_PATH; \
	done && \
	( \
		CRONTAB_NOHEADER=Y crontab -l || true; \
		printf '%s' \
			'@midnight ' \
			'"$(GOOGLE_READER_TARGET_PATH)" ' \
			"\"$$GOOGLE_USER\" " \
			"\"$$GOOGLE_PASSWORD\" " \
			"\"$$GOOGLE_READER_BACKUP_PATH\""; \
		printf '\n') | crontab -

.PHONY: install-last-fm uninstall-last-fm
install-last-fm: $(LAST_FM_TARGET_PATH)

uninstall-last-fm:
	rm -f $(LAST_FM_TARGET_PATH)

.PHONY: install-crontab-last-fm
install-crontab-last-fm: crontab-warning $(LAST_FM_TARGET_PATH)
	@while [ -z "$$LAST_FM_USER" ]; do \
		read -r -p "last.fm user name: " LAST_FM_USER;\
	done && \
	while [ -z "$$LAST_FM_BACKUP_PATH" ]; do \
		read -r -p "last.fm backup path: " LAST_FM_BACKUP_PATH; \
	done && \
	( \
		CRONTAB_NOHEADER=Y crontab -l || true; \
		printf '%s' \
			'@midnight ' \
			'"$(LAST_FM_TARGET_PATH)" ' \
			"-xmlfile=\"$$LAST_FM_BACKUP_PATH\" " \
			"method=library.getTracks " \
			"user=\"$$LAST_FM_USER\" "; \
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
	install-delicious \
	install-google-calendar \
	install-google-reader \
	install-last-fm \
	install-librarything \
	install-wordpress-com

.PHONY: uninstall
uninstall: \
	uninstall-delicious \
	uninstall-google-calendar \
	uninstall-google-reader \
	uninstall-last-fm \
	uninstall-librarything \
	uninstall-wordpress-com

install-crontab: \
	install-crontab-delicious \
	install-crontab-google-calendar \
	install-crontab-google-reader \
	install-crontab-last-fm \
	install-crontab-librarything \
	install-crontab-wordpress-com

include tools.mk
