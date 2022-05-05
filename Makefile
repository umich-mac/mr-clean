UserHomeDirManagement.pkg: HomeDirReaper.sh homedir.defaults edu.umich.lsa.iss.HomeDirReaper.plist
	mkdir -p tmp
	mkdir -p tmp/usr/local/bin
	mkdir -p tmp/Library/LaunchAgents
	mkdir -p tmp/private/etc
	cp HomeDirReaper.sh tmp/usr/local/bin
	cp homedir.defaults tmp/private/etc
	cp edu.umich.lsa.iss.HomeDirReaper.plist tmp/Library/LaunchAgents
	/usr/bin/pkgbuild \
		--root tmp \
		--identifier edu.umich.izzy.pkg.UserHomeDirManagement \
		--install-location / \
		--version `date +'%Y.%m.%d'` \
		UserHomeDirManagement.pkg
	
clean:
	rm -rf tmp/*
	rm -f UserHomeDirManagement.pkg
