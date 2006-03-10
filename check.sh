#!/bin/sh

cd tests

svn revert dot-otp/pad-records

# Print the (string) first argument, then display all pad lengths.
# NOTE: Deactivated by default.  Change 'false' to 'true' to turn on.
function show_lengths()
{
   if false; then
     echo ${1}
     grep "/length" dot-otp/pad-records
     echo ""
   fi
}

show_lengths "Before any encoding or decoding:"

# Encode
../otp --config=dot-otp -e random-data-1  \
       < test-msg > test-msg.otp

show_lengths "After encoding:"

# Decode twice, to make sure the pad can reconsume safely.
../otp --config=dot-otp -d random-data-1  \
       < test-msg.otp > test-msg.decoded-1

show_lengths "After decoding once:"

../otp --config=dot-otp -d random-data-1  \
       < test-msg.otp > test-msg.decoded-2

show_lengths "After decoding again:"

# Encode again with the same pad
../otp --config=dot-otp -e random-data-1  \
       < test-msg > test-msg.otp

show_lengths "After encoding again:"

# Decode only once this time.
../otp --config=dot-otp -d random-data-1  \
       < test-msg.otp > test-msg.decoded-3

show_lengths "After decoding:"

if cmp test-msg test-msg.decoded-1; then
  echo "All tests passed."
else
  echo "Error: tests failed, something went wrong."
fi

# Revert here too, in case about to commit.
svn revert dot-otp/pad-records
