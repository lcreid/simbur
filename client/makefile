# See: http://www.gnu.org/software/make/manual/make.html#Makefile-Conventions
prefix = ${DESTDIR}/usr
bindir=$(prefix)/bin
datarootdir = $(prefix)/share
docdir=$(datarootdir)/doc
mandir=$(datarootdir)/man
man1dir=$(mandir)/man1
man5dir=$(mandir)/man5
sysconfdir=${DESTDIR}/etc/simbur

.SECONDEXPANSION:

EXECUTABLES=simbur-full simbur-incremental simburd simbur-enroll-client
MAN1FILES=${EXECUTABLES:%=%.1}
MAN5FILES=simbur-client.conf.5

INSTALLED_EXECUTABLES=${EXECUTABLES:%=${bindir}/%}
INSTALLED_MANPAGES=${MAN1FILES:%=${man1dir}/%.gz} ${MAN5FILES:%=${man5dir}/%.gz}
INSTALLED_CONFIG_FILES=${sysconfdir}/exclude.conf ${sysconfdir}/simbur-client.conf

SOURCES=*.sh *.1 *.5 *.conf makefile

all: ${EXECUTABLES}

install: installdirs ${INSTALLED_EXECUTABLES} ${INSTALLED_MANPAGES} ${INSTALLED_CONFIG_FILES}

uninstall: 
	-rm ${INSTALLED_EXECUTABLES} ${INSTALLED_MANPAGES} ${INSTALLED_CONFIG_FILES}

${INSTALLED_EXECUTABLES} \
${INSTALLED_MANPAGES} \
${INSTALLED_CONFIG_FILES}: $$(@F)
	cp $? $@

config: ${sysconfdir} ${INSTALLED_CONFIG_FILES}

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

installdirs: ${bindir} ${sysconfdir} ${man1dir} ${man5dir} ${docdir}

${bindir} ${sysconfdir} ${man1dir} ${man5dir} ${docdir}:
	mkdir -p $@ 

