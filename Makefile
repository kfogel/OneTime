# Makefile for OTP.

all: check

run:
	@(cd tests; \
        ../otp --debug --offset=0 --config=dot-otp -e random-data-1 < test-msg)

check:
	@check.sh

clean:
	@rm -f test-msg.otp test-msg.decoded *~
