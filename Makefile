# Makefile for OTP.

all: check

test: check
check:
	@./check.sh

install:
	@install -m755 onetime $(DESTDIR)/usr/bin/

uninstall:
	@rm -v $(DESTDIR)/usr/bin/onetime

distclean: clean
clean:
	@rm -rf index.html test-msg.* *~ onetime-*.* onetime-*.tar.gz

dist:
	@rm -rf onetime-`onetime --version | cut -f 3 -d " "`
	@rm -f onetime-`onetime --version | cut -f 3 -d " "`.tar.gz
	@svn export -q . onetime-`onetime --version | cut -f 3 -d " "`
	@rm -rf onetime-`onetime --version | cut -f 3 -d " "`/debian
	@tar zcvf onetime-`onetime --version | cut -f 3 -d " "`.tar.gz \
                  onetime-`onetime --version | cut -f 3 -d " "`

www: dist
	@./onetime --intro > intro.tmp
	@./onetime --help  > help.tmp
	@# Escape and indent the --intro and --help output.
	@sed -e 's/\&/\&amp;/g' < intro.tmp > intro.tmp.tmp
	@mv intro.tmp.tmp intro.tmp
	@sed -e 's/</\&lt;/g' < intro.tmp > intro.tmp.tmp
	@mv intro.tmp.tmp intro.tmp
	@sed -e 's/>/\&gt;/g' < intro.tmp > intro.tmp.tmp
	@mv intro.tmp.tmp intro.tmp
	@sed -e 's/^\(.*\)/   \1/g' < intro.tmp > intro.tmp.tmp
	@mv intro.tmp.tmp intro.tmp
	@sed -e 's/\&/\&amp;/g' < help.tmp > help.tmp.tmp
	@mv help.tmp.tmp help.tmp
	@sed -e 's/</\&lt;/g' < help.tmp > help.tmp.tmp
	@mv help.tmp.tmp help.tmp
	@sed -e 's/>/\&gt;/g' < help.tmp > help.tmp.tmp
	@mv help.tmp.tmp help.tmp
	@sed -e 's/^\(.*\)/   \1/g' < help.tmp > help.tmp.tmp
	@mv help.tmp.tmp help.tmp
	@cat index.html-top     \
             intro.tmp          \
             index.html-middle  \
             help.tmp           \
             index.html-bottom  \
           > index.html
	@# Substitute in the latest version number.
	@./onetime --version > version.tmp
	@sed -e "s/ONETIMEVERSION/`cat version.tmp`/g" \
           < index.html > index.html.tmp
	@# Make the GPG link live.
	@mv index.html.tmp index.html
	@sed -e 's/GPG,/<a href="http:\/\/www.gnupg.org\/">GPG<\/a>,/g' \
           < index.html > index.html.tmp
	@mv index.html.tmp index.html
	@# Make the Wikipedia link live.
	@sed -e 's/ http:\/\/en.wikipedia.org\/wiki\/One-time_pad / <a href="http:\/\/en.wikipedia.org\/wiki\/One-time_pad">http:\/\/en.wikipedia.org\/wiki\/One-time_pad<\/a> /g' \
           < index.html > index.html.tmp
	@mv index.html.tmp index.html
	@# Make the SVN and CVS links live.
	@sed -e 's/Subversion or CVS,/<a href="http:\/\/subversion.tigris.org\/">Subversion<\/a> or <a href="http:\/\/www.nongnu.org\/cvs\/">CVS<\/a>,/g' \
           < index.html > index.html.tmp
	@mv index.html.tmp index.html
	@rm intro.tmp help.tmp version.tmp

deb: dist
	@tar zxvf onetime-`onetime --version | cut -f 3 -d " "`.tar.gz
	@cp -a debian/debian onetime-`onetime --version | cut -f 3 -d " "`/
	@rm -rf onetime-`onetime --version | cut -f 3 -d " "`/debian/.svn
	@(cd onetime-`onetime --version | cut -f 3 -d " "`/; \
          dpkg-buildpackage -rfakeroot)
	@rm -rf debian/output/*
	@if                                                                   \
         [ -f onetime_`onetime --version | cut -f 3 -d " "`-1.diff.gz ];      \
         then                                                                 \
         mv onetime_`onetime --version | cut -f 3 -d " "`-1.diff.gz           \
            debian/output; fi
	@if                                                                   \
         [ -f onetime_`onetime --version | cut -f 3 -d " "`-1.dsc ];          \
         then                                                                 \
         mv onetime_`onetime --version | cut -f 3 -d " "`-1.dsc               \
            debian/output; fi
	@if                                                                   \
         [ -f onetime_`onetime --version | cut -f 3 -d " "`-1_i386.changes ]; \
         then                                                                 \
         mv onetime_`onetime --version | cut -f 3 -d " "`-1_i386.changes      \
            debian/output; fi
	@if                                                                   \
         [ -f onetime_`onetime --version | cut -f 3 -d " "`-1_i386.deb ];     \
         then                                                                 \
         mv onetime_`onetime --version | cut -f 3 -d " "`-1_i386.deb          \
            debian/output; fi
	@if                                                                   \
         [ -f onetime_`onetime --version | cut -f 3 -d " "`-1.tar.gz ];       \
         then                                                                 \
         mv onetime_`onetime --version | cut -f 3 -d " "`-1.tar.gz            \
            debian/output; fi
	@echo ""
	@echo "Done.  Package files placed in debian/output/:"
	@echo ""
	@ls -l debian/output/
	@echo ""
