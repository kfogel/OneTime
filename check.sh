#!/bin/sh

cd tests

../otp --config=dot-otp -e random-data-1 0 < test-msg > test-msg.otp
../otp --config=dot-otp -d  random-data-1 0 < test-msg.otp > test-msg.decoded

if cmp test-msg test-msg.decoded; then
  echo "All tests passed."
else
  echo "Error: tests failed, something went wrong."
fi
