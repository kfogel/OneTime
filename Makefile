# Makefile for OTP.

all: check

run:
	@(cd tests; \
          ../otp --debug --config=dot-otp -e random-data-1 0 < test-msg)

check:
	@check.sh

clean:
	@rm -f test-msg.otp test-msg.decoded *~
