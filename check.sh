#!/bin/sh

./otp -e random-data 0 < otp > otp.otp
./otp -d  random-data 0 < otp.otp > otp.decoded

if cmp otp otp.decoded; then
  echo "All tests passed."
else
  echo "Error: tests failed, something went wrong."
fi
