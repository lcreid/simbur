EXECUTABLES=full-backup incremental-backup
BINDIR=/usr/local/lib/simbur

executables: ${EXECUTABLES}

install: install_executables config

install_executables: executables ${BINDIR}
	cp ${EXECUTABLES} ${BINDIR}

${BINDIR}:
	mkdir -p $@

config: /etc/simbur config_files

/etc/simbur:
	mkdir -p $@

config_files: /etc/simbur/exclude.conf /etc/simbur/client.conf

/etc/simbur/exclude.conf: exclude.conf
	cp $? $@

/etc/simbur/client.conf: client.conf
	cp $? $@

