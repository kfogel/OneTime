#!/bin/sh

cd tests

../otp --config=dot-otp --offset=0 -e random-data-1  \
       < test-msg > test-msg.otp
../otp --config=dot-otp --offset=0 -d random-data-1  \
       < test-msg.otp > test-msg.decoded

if cmp test-msg test-msg.decoded; then
  echo "All tests passed."
else
  echo "Error: tests failed, something went wrong."
fi
