# Makefile for OTP.

all: check

test: check
check:
	@./check.sh

install:
	@cp -v onetime /usr/bin/
	@chmod a+x /usr/bin/onetime

uninstall:
	@rm -v /usr/bin/onetime

distclean: clean
clean:
	@rm -f index.html test-msg.* *~

www:
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
