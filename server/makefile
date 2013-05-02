# See: http://www.gnu.org/software/make/manual/make.html#Makefile-Conventions
prefix = ${DESTDIR}/usr
bindir=$(prefix)/bin
datarootdir = $(prefix)/share
docdir=$(datarootdir)/doc
mandir=$(datarootdir)/man
man1dir=$(mandir)/man1
man5dir=$(mandir)/man5
sysconfdir=${DESTDIR}/etc/simbur
sudoersdir=${DESTDIR}/etc/sudoers.d

.SECONDEXPANSION:

EXECUTABLES = simbur-server enroll-host finish-backup prune-backups start-incremental
MAN1FILES=simbur-server.1
MAN5FILES=simbur-server.conf.5

INSTALLED_EXECUTABLES=${EXECUTABLES:%=${bindir}/%}
INSTALLED_MANPAGES=${MAN1FILES:%=${man1dir}/%.gz} ${MAN5FILES:%=${man5dir}/%.gz}
INSTALLED_CONFIG_FILES=${sysconfdir}/simbur-server.conf 
INSTALLED_SUDOERS_FILES=${sudoersdir}/simbur-server-sudo

SOURCES=*.sh *.1 *.5 *.conf *-sudo makefile

all: ${EXECUTABLES}

install: installdirs \
${INSTALLED_EXECUTABLES} \
${INSTALLED_MANPAGES} \
${INSTALLED_CONFIG_FILES} \
${INSTALLED_SUDOERS_FILES}

uninstall: 
	-rm ${INSTALLED_EXECUTABLES} ${INSTALLED_MANPAGES} ${INSTALLED_CONFIG_FILES}

${INSTALLED_EXECUTABLES} \
${INSTALLED_MANPAGES} \
${INSTALLED_CONFIG_FILES}: $$(@F)
	cp $? $@

${sudoersdir}/simbur-server-sudo: simbur-server-sudo
	-rm -f $@
	cp $? $@ 
	chmod 440 $@

debian: simbur-server.deb

simbur-server.deb: ${SOURCES} debian/DEBIAN/*
	make DESTDIR=debian install
	-rm debian/DEBIAN/*~
	fakeroot dpkg-deb --build debian
	mv debian.deb simbur-server.deb

%.gz : %
	gzip --best --to-stdout $? >$@

debug:
	echo "'${man5dir}'"

clean:
	rm $(EXECUTABLES) ${MAN1FILES:%=%.gz} ${MAN5FILES:%=%.gz} *~

distclean: clean
	-rm ${INSTALLED_CONFIG_FILES} ${INSTALLED_SUDOERS_FILES}

installdirs: ${bindir} ${sysconfdir} ${man1dir} ${man5dir} ${docdir} ${sudoersdir}

${bindir} ${sysconfdir} ${man1dir} ${man5dir} ${docdir} ${sudoersdir}:
	mkdir -p $@
