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
TARGET_OS?=$(shell "uname")

.SECONDEXPANSION:

EXECUTABLES=simbur-full simbur-incremental simburd simbur-enroll-client
MAN1FILES=${EXECUTABLES:%=%.1}
MAN5FILES=simbur-client.conf.5

INSTALLED_EXECUTABLES=${EXECUTABLES:%=${bindir}/%}
INSTALLED_MANPAGES=${MAN1FILES:%=${man1dir}/%.gz} ${MAN5FILES:%=${man5dir}/%.gz}
INSTALLED_CONFIG_FILES=${SIMBUR_CONF_DIR}/exclude.conf \
${SIMBUR_CONF_DIR}/simbur-client.conf

SOURCES=*.sh *.1 *.5 *.conf *.plist makefile

ifeq (Darwin, ${TARGET_OS})
	INIT_DIR=${DESTDIR}/Library/LaunchDaemons
	INSTALLED_CONFIG_FILES+=$(INIT_DIR)/ca.jadesystems.simburd.plist
	LOGROTATE_DIR=${sysconfdir}/newsyslog.d
	INSTALLED_CONFIG_FILES+=${LOGROTATE_DIR}/simbur-client-newsyslog.conf
else ifeq (Linux, ${TARGET_OS})
	INIT_DIR=${sysconfdir}/init
	INSTALLED_CONFIG_FILES+=$(INIT_DIR)/simburd.conf
	LOGROTATE_DIR=${sysconfdir}/logrotate.d
	INSTALLED_CONFIG_FILES+=${LOGROTATE_DIR}/simbur-client-logrotate.conf
else
	$(error "Operating system " ${TARGET_OS} " not supported."
endif

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


############
#
# .deb for Mint, Ubuntu, maybe Debian
#
############

debian: simbur-client.deb

simbur-client.deb: ${SOURCES} debian/DEBIAN/* simburd.conf
	make DESTDIR=debian install
	-rm debian/DEBIAN/*~
	fakeroot dpkg-deb --build debian
	mv debian.deb simbur-client.deb

%.gz : %
	gzip --best --to-stdout $? >$@

############
#
# A tar file for Mac, peor es nada
#
############
LAUNCHD_DIR=${DESTDIR}/Library/LaunchDaemons

mac: simbur-client.tar.gz

simbur-client.tar.gz: ${SOURCES} ca.jadesystems.simburd.plist
	make DESTDIR=osx TARGET_OS=Darwin install
	cd osx; tar -c -z --owner=root --group=root -f ../$@ ./*

%.plist : %
	cp $? $@
	chmod 600 $@

############
#
# Miscellaneous
#
############

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

