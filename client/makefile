# See: http://www.gnu.org/software/make/manual/make.html#Makefile-Conventions
prefix = ${DESTDIR}/usr
bindir=$(prefix)/bin
datarootdir = $(prefix)/share
docdir=$(datarootdir)/doc
mandir=$(datarootdir)/man
man1dir=$(mandir)/man1
man5dir=$(mandir)/man5
sysconfdir=${DESTDIR}/etc
SIMBUR_CONF_DIR=${sysconfdir}/simbur
INIT_DIR=${sysconfdir}/init
LOGROTATE_DIR=${sysconfdir}/logrotate.d

.SECONDEXPANSION:

EXECUTABLES=simbur-full simbur-incremental simburd simbur-enroll-client
MAN1FILES=${EXECUTABLES:%=%.1}
MAN5FILES=simbur-client.conf.5

INSTALLED_EXECUTABLES=${EXECUTABLES:%=${bindir}/%}
INSTALLED_MANPAGES=${MAN1FILES:%=${man1dir}/%.gz} ${MAN5FILES:%=${man5dir}/%.gz}
INSTALLED_CONFIG_FILES=${SIMBUR_CONF_DIR}/exclude.conf \
${SIMBUR_CONF_DIR}/simbur-client.conf \
$(INIT_DIR)/simburd.conf
LOGROTATE_CONFIG_FILE=${LOGROTATE_DIR}/simbur-client-logrotate.conf

SOURCES=*.sh *.1 *.5 *.conf makefile

all: ${EXECUTABLES}

install: installdirs \
${INSTALLED_EXECUTABLES} \
${INSTALLED_MANPAGES} \
${INSTALLED_CONFIG_FILES}

uninstall: 
	-rm ${INSTALLED_EXECUTABLES} ${INSTALLED_MANPAGES} ${INSTALLED_CONFIG_FILES}

${INSTALLED_EXECUTABLES} \
${INSTALLED_MANPAGES} \
${INSTALLED_CONFIG_FILES}: $$(@F)
	cp $? $@

$(INSTALLED_INIT_FILES): 

config: ${SIMBUR_CONF_DIR} ${INSTALLED_CONFIG_FILES}

debian: simbur-client.deb

simbur-client.deb: ${SOURCES} debian/DEBIAN/*
	make DESTDIR=debian install
	-rm debian/DEBIAN/*~
	fakeroot dpkg-deb --build debian
	mv debian.deb simbur-client.deb

%.gz : %
	gzip --best --to-stdout $? >$@

debug:
	echo "'${man5dir}'"

clean:
	rm $(EXECUTABLES) ${MAN1FILES:%=%.gz} ${MAN5FILES:%=%.gz} *~

distclean: clean
	-rm ${INSTALLED_CONFIG_FILES}

installdirs: ${bindir} \
${SIMBUR_CONF_DIR} \
${INIT_DIR} \
${man1dir} \
${man5dir} \
${docdir} \
${LOGROTATE_DIR}

${bindir} ${SIMBUR_CONF_DIR} ${INIT_DIR} ${man1dir} ${man5dir} ${docdir} ${LOGROTATE_DIR}:
	mkdir -p $@ 

