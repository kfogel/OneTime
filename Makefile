# Makefile for OTP.

all: check

check:
	@check.sh

clean:
	@rm -f otp.otp otp.decoded *~
