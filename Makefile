# Makefile for OTP.

all: check

run:
	@(cd tests; \
        ../onetime --debug --offset=0 --config=dot-onetime -e random-data-1 < test-msg)

check:
	@./check.sh

clean:
	@rm -f test-msg.onetime test-msg.decoded *~

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
