#!/bin/sh

cd tests

rm -rf test-tmp
mkdir test-tmp
cd test-tmp

# Because OneTime itself is sensitive to version control, we create
# a fresh test directory every time.  For now, we're not testing the
# version control functionality, just the encoding and decoding.
reset_config()
{
   for name in dot-onetime v1-dot-onetime; do
     rm -rf ${name}
     cp -a ../${name} ./${name}
     rm -rf ${name}/.svn
   done
}

############################################################################
###  Option-parsing tests.                                               ###
############################################################################

###
# In the tests of the various option parsing methods, "e.N" is
# encrypted text and "d.N" is decrypted text.
###

reset_config

# mode 1
../../onetime -C dot-onetime -e -p ../test-pad-2 -o e.1 ../test-plaintext-a
../../onetime -C dot-onetime -d -p ../test-pad-2 -o d.1 e.1

# mode 2
../../onetime -C dot-onetime -e -p ../test-pad-2 ../test-plaintext-a
mv ../test-plaintext-a.onetime e.2.onetime
../../onetime -C dot-onetime -d -p ../test-pad-2 e.2.onetime
mv e.2 d.2

# mode 3
../../onetime -C dot-onetime -e -p ../test-pad-2 -o - ../test-plaintext-a > e.3
../../onetime -C dot-onetime -d -p ../test-pad-2 -o - e.3 > d.3

# mode 4
../../onetime -C dot-onetime -e -p ../test-pad-2 < ../test-plaintext-a > e.4
../../onetime -C dot-onetime -d -p ../test-pad-2 < e.4 > d.4

# mode 5
../../onetime -C dot-onetime -e -p ../test-pad-2 -o e.5 < ../test-plaintext-a
../../onetime -C dot-onetime -d -p ../test-pad-2 -o d.5 < e.5

PASSED="yes"
for n in 1 2 3 4 5; do
  if cmp ../test-plaintext-a d.${n}; then
    true
  else
    echo "Error: option-parsing tests failed, something went wrong."
    PASSED="no"
  fi
done

if [ ${PASSED} = "yes" ]; then
  echo "Option-parsing tests passed."
fi

############################################################################
###  Functionality tests.                                                ###
############################################################################

########################################################################
## Regression test for "Decryption wrongly shrinks pad usage."
#
# User sent in a report:
#
#   $ onetime.py -e -p onetimepad.dat test1.txt
#     ==> pad-records says used length now 27340
#   $ onetime.py -e -p onetimepad.dat test2.txt
#     ==> pad-records says used length now 54680
#   $ onetime.py -e -p onetimepad.dat test3.txt
#     ==> pad-records says used length now 82020
#
#   (Now watch what happens on decryption...)
#
#   $ onetime.py -d -p onetimepad.dat test1.txt.onetime
#     ==> pad-records says length reverted to 27340!

reset_config

../../onetime -C dot-onetime -e -p ../test-pad-1 \
              -o test-ciphertext-b-1.onetime ../test-plaintext-b
if ! grep -q "<length>12154</length>" dot-onetime/pad-records; then
  echo "ERROR: Pad usage length incorrect after encryption iteration 1."
  cat dot-onetime/pad-records
  exit 1
fi

../../onetime -C dot-onetime -e -p ../test-pad-1 \
              -o test-ciphertext-b-2.onetime ../test-plaintext-b
if ! grep -q "<length>24203</length>" dot-onetime/pad-records; then
  echo "ERROR: Pad usage length incorrect after encryption iteration 2."
  cat dot-onetime/pad-records
  exit 1
fi

../../onetime -C dot-onetime -e -p ../test-pad-1 \
              -o test-ciphertext-b-3.onetime ../test-plaintext-b
if ! grep -q "<length>36252</length>" dot-onetime/pad-records; then
  echo "ERROR: Pad usage length incorrect after encryption iteration 3."
  cat dot-onetime/pad-records
  exit 1
fi

../../onetime -C dot-onetime -d -p ../test-pad-1 \
              -o test-plaintext-b-1 test-ciphertext-b-1.onetime
if ! grep -q "<length>36252</length>" dot-onetime/pad-records; then
  cat dot-onetime/pad-records
  if grep -q "<length>12154</length>" dot-onetime/pad-records; then
    echo "ERROR: 'Decryption wrongly shrinks pad usage' bug is back."
  else
    echo "ERROR: Usage length wrong after decryption 1, but don't know why."
  fi
  exit 1
fi

if ! cmp test-plaintext-b-1 ../test-plaintext-b; then
  echo "ERROR: Decryption failed to produce correct plaintext."
  exit 1
fi

########################################################################
## Test reconsumption, via repeated encoding and decoding.

reset_config

# Print the (string) first argument, then display all pad lengths.
# NOTE: Deactivated by default.  Change 'false' to 'true' to turn on.
maybe_show_lengths()
{
   if false; then
     echo ${1}
     grep "/length" dot-onetime/pad-records
     echo ""
   fi
}

# Encode
../../onetime --config=dot-onetime -e -p ../test-pad-1  \
         < ../test-plaintext-a > test-ciphertext-a.onetime
maybe_show_lengths "After encoding:"
# Decode twice, to make sure the pad can reconsume safely.
../../onetime --config=dot-onetime -d -p ../test-pad-1  \
         < test-ciphertext-a.onetime > test-plaintext-a.decoded-1
maybe_show_lengths "After decoding once:"
if ! cmp ../test-plaintext-a test-plaintext-a.decoded-1; then
  echo "ERROR: test-plaintext-a.decoded-1 does not match test-plaintext-a input."
  exit 1
fi
../../onetime --config=dot-onetime -d -p ../test-pad-1  \
         < test-ciphertext-a.onetime > test-plaintext-a.decoded-2
maybe_show_lengths "After decoding again:"
if ! cmp ../test-plaintext-a test-plaintext-a.decoded-2; then
  echo "ERROR: test-plaintext-a.decoded-2 does not match test-plaintext-a input."
  exit 1
fi
# Encode again with the same pad
../../onetime --config=dot-onetime -e -p ../test-pad-1  \
         < ../test-plaintext-a > test-ciphertext-a.onetime
maybe_show_lengths "After encoding again:"
# Decode only once this time.
../../onetime --config=dot-onetime -d -p ../test-pad-1  \
         < test-ciphertext-a.onetime > test-plaintext-a.decoded-3
maybe_show_lengths "After decoding:"
if ! cmp ../test-plaintext-a test-plaintext-a.decoded-3; then
  echo "ERROR: test-plaintext-a.decoded-3 does not match test-plaintext-a input."
  exit 1
fi

# Now do the entire thing again with the other pad.
# Encode
../../onetime --config=dot-onetime -e -p ../test-pad-2  \
         < ../test-plaintext-a > test-ciphertext-a.onetime
maybe_show_lengths "After encoding:"
# Decode twice, to make sure the pad can reconsume safely.
../../onetime --config=dot-onetime -d -p ../test-pad-2  \
         < test-ciphertext-a.onetime > test-plaintext-a.decoded-1
maybe_show_lengths "After decoding once:"
if ! cmp ../test-plaintext-a test-plaintext-a.decoded-1; then
  echo "ERROR: test-plaintext-a.decoded-1 (pad test-pad-2) does not match test-plaintext-a input."
  exit 1
fi
../../onetime --config=dot-onetime -d -p ../test-pad-2  \
         < test-ciphertext-a.onetime > test-plaintext-a.decoded-2
maybe_show_lengths "After decoding again:"
if ! cmp ../test-plaintext-a test-plaintext-a.decoded-2; then
  echo "ERROR: test-plaintext-a.decoded-2 (pad test-pad-2) does not match test-plaintext-a input."
  exit 1
fi
# Encode again with the same pad
../../onetime --config=dot-onetime -e -p ../test-pad-2  \
         < ../test-plaintext-a > test-ciphertext-a.onetime
maybe_show_lengths "After encoding again:"
# Decode only once this time.
../../onetime --config=dot-onetime -d -p ../test-pad-2  \
         < test-ciphertext-a.onetime > test-plaintext-a.decoded-3
maybe_show_lengths "After decoding:"
if ! cmp ../test-plaintext-a test-plaintext-a.decoded-3; then
  echo "ERROR: test-plaintext-a.decoded-3 (pad test-pad-2) does not match test-plaintext-a input."
  exit 1
fi

########################################################################
## Test 2.x <- 1.x compatibility features.

reset_config
## Receive v1 msg M, have v1 pad-records file with pad entry for M's
## pad and that stretch of pad already marked as used.
## Result: upgraded pad ID, everything else stays same.

reset_config
## Receive v1 msg M, have v1 pad-records file with pad entry for M's
## pad, but this stretch of pad not marked as used.
## Result: upgraded pad ID, stretch marked as used.

reset_config
## Receive v2 msg M, have v1 pad-records file with pad entry for M's
## pad and that stretch of pad already marked as used.
## Result: upgraded pad ID, everything else stays same.

reset_config
## Receive v2 msg M, have v1 pad-records file with pad entry for M's
## pad, but this stretch of pad not marked as used.
## Result: upgraded pad ID, stretch marked as used.

reset_config
## Receive v1 msg M, have no entry in pad-records file for M's pad.
## Result: new v2 entry

reset_config
## Encrypt message, have v1 pad-records file with entry for pad used.
## Result: pad entry should be upgraded, with stretch marked as used.

echo "Functionality tests passed."

############################################################################
###  All tests finished.  Leave the test area in place for inspection.   ###
############################################################################

cd ../..
