EXECUTABLES = enroll-host finish-backup prune-backups start-incremental
BINDIR = /usr/local/lib/simbur

executables: ${EXECUTABLES}

install: install_executables /etc/simbur/server.conf /etc/sudoers.d/simbur-server

install_executables: executables ${BINDIR}
	cp ${EXECUTABLES} ${BINDIR}
	
${BINDIR}:
	mkdir -p $@

/etc/simbur/server.conf: server.conf
	mkdir -p /etc/simbur
	cp $? $@ 

/etc/sudoers.d/simbur-server: simbur-server
	cp $? $@ 
	chmod 440 $@

