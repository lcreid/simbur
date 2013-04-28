EXECUTABLES=full-backup incremental-backup simburd enroll-client
BINDIR=/usr/local/lib/simbur
MANFILES=${EXECUTABLES:%=%.1}

.SECONDEXPANSION:

executables: ${EXECUTABLES}

INSTALLED_EXECUTABLES=${EXECUTABLES:%=${BINDIR}/%}

install: ${BINDIR} ${INSTALLED_EXECUTABLES} config

${INSTALLED_EXECUTABLES}: $$(@F)
	cp $? ${BINDIR}

${BINDIR}:
	mkdir -p $@

CONFIG_FILES=/etc/simbur/exclude.conf /etc/simbur/client.conf

config: /etc/simbur ${CONFIG_FILES}

/etc/simbur:
	mkdir -p $@

${CONFIG_FILES}: $$(@F)
	cp $? $@

DEBIAN_CONFIG_FILES=debian/etc/simbur/exclude.conf debian/etc/simbur/client.conf
DEBIAN_EXECUTABLES=debian/usr/local/lib/simbur/full-backup \
	debian/usr/local/lib/simbur/incremental-backup \
	debian/usr/local/lib/simbur/simburd \
	debian/usr/local/lib/simbur/enroll-client
DEBIAN_DIRECTORIES=debian/etc/simbur \
debian/usr/local/lib/simbur \
debian/usr/share/man/man1 \
debian/usr/share/man/man5 


DEBIAN_MANFILES_GZIPPED=${MANFILES:%=debian/usr/share/man/man1/%.gz} \
debian/usr/share/man/man5/client.conf.5.gz

DEBIAN_MANFILES=${DEBIAN_MANFILES_GZIPPED} 
#DEBIAN_DOC_DIRECTORY=debian/usr/share/doc/simbur
#DEBIAN_DOCFILES=${DEBIAN_DOC_DIRECTORY}/copyright

debian: simbur-client.deb

simbur-client.deb: ${DEBIAN_DIRECTORIES} \
${DEBIAN_EXECUTABLES} \
${DEBIAN_CONFIG_FILES} \
${DEBIAN_MANFILES} 
	fakeroot dpkg-deb --build debian
	mv debian.deb simbur-client.deb

${DEBIAN_DIRECTORIES}:  
	mkdir -p $@

${DEBIAN_CONFIG_FILES} ${DEBIAN_EXECUTABLES}: $$(@F)
	cp $? $@

${DEBIAN_MANFILES_GZIPPED}: $$(@F)
	cp $? $@

%.gz : %
	gzip --best --to-stdout $? >$@

# ${DEBIAN_DOCFILES}: $$(@F)
	# cp $? $@

debug:
	echo "'${DEBIAN_MANFILES_GZIPPED}'"

