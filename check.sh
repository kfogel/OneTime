#!/bin/sh

cd tests

# Because OTP itself is sensitive to version control, we create
# a fresh test directory every time.  For now, we don't test the
# version control functionality, just encoding and decoding.
rm -rf test-tmp
mkdir test-tmp
cp -a dot-otp test-tmp
rm -rf test-tmp/dot-otp/.svn
cd test-tmp

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
../../otp --config=dot-otp -e -p ../random-data-1  \
         < ../test-msg > test-msg.otp

show_lengths "After encoding:"

# Decode twice, to make sure the pad can reconsume safely.
../../otp --config=dot-otp -d -p ../random-data-1  \
         < test-msg.otp > test-msg.decoded-1

show_lengths "After decoding once:"

../../otp --config=dot-otp -d -p ../random-data-1  \
         < test-msg.otp > test-msg.decoded-2

show_lengths "After decoding again:"

# Encode again with the same pad
../../otp --config=dot-otp -e -p ../random-data-1  \
         < ../test-msg > test-msg.otp

show_lengths "After encoding again:"

# Decode only once this time.
../../otp --config=dot-otp -d -p ../random-data-1  \
         < test-msg.otp > test-msg.decoded-3

show_lengths "After decoding:"

if cmp ../test-msg test-msg.decoded-1; then
  echo "Basic tests passed."
else
  echo "Error: basic tests failed, something went wrong."
fi

###
# Test the various option parsing methods.
# "e.N" is encrypted text, "d.N" is decrypted text.
###

# mode 1
../../otp --config=dot-otp -e -p ../random-data-2 -o e.1 ../test-msg
../../otp --config=dot-otp -d -p ../random-data-2 -o d.1 e.1

# mode 2
../../otp --config=dot-otp -e -p ../random-data-2 ../test-msg
mv ../test-msg.otp e.2.otp
../../otp --config=dot-otp -d -p ../random-data-2 e.2.otp
mv e.2 d.2

# mode 3
../../otp --config=dot-otp -e -p ../random-data-2 -o - ../test-msg > e.3
../../otp --config=dot-otp -d -p ../random-data-2 -o - e.3 > d.3

# mode 4
../../otp --config=dot-otp -e -p ../random-data-2 < ../test-msg > e.4
../../otp --config=dot-otp -d -p ../random-data-2 < e.4 > d.4

# mode 5
../../otp --config=dot-otp -e -p ../random-data-2 -o e.5 < ../test-msg
../../otp --config=dot-otp -d -p ../random-data-2 -o d.5 < e.5

PASSED="yes"
for n in 1 2 3 4 5; do
  if cmp ../test-msg d.${n}; then
    true
  else
    echo "Error: option parsing tests failed, something went wrong."
    PASSED="no"
  fi
done

if [ ${PASSED} = "yes" ]; then
  echo "Option parsing tests passed."
fi
