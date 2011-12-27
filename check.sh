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
   rm -rf dot-onetime
   cp -a ../dot-onetime ./dot-onetime
   rm -rf dot-onetime/.svn
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
../../onetime -C dot-onetime -e -p ../random-data-2 -o e.1 ../short-msg
../../onetime -C dot-onetime -d -p ../random-data-2 -o d.1 e.1

# mode 2
../../onetime -C dot-onetime -e -p ../random-data-2 ../short-msg
mv ../short-msg.onetime e.2.onetime
../../onetime -C dot-onetime -d -p ../random-data-2 e.2.onetime
mv e.2 d.2

# mode 3
../../onetime -C dot-onetime -e -p ../random-data-2 -o - ../short-msg > e.3
../../onetime -C dot-onetime -d -p ../random-data-2 -o - e.3 > d.3

# mode 4
../../onetime -C dot-onetime -e -p ../random-data-2 < ../short-msg > e.4
../../onetime -C dot-onetime -d -p ../random-data-2 < e.4 > d.4

# mode 5
../../onetime -C dot-onetime -e -p ../random-data-2 -o e.5 < ../short-msg
../../onetime -C dot-onetime -d -p ../random-data-2 -o d.5 < e.5

PASSED="yes"
for n in 1 2 3 4 5; do
  if cmp ../short-msg d.${n}; then
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

../../onetime -C dot-onetime -e -p ../random-data-1 \
              -o long-msg-1.onetime ../long-msg
if ! grep -q "<length>45646</length>" dot-onetime/pad-records; then
  echo "ERROR: Pad usage length incorrect after encryption iteration 1."
  cat dot-onetime/pad-records
  exit 1
fi

../../onetime -C dot-onetime -e -p ../random-data-1 \
              -o long-msg-2.onetime ../long-msg
if ! grep -q "<length>91187</length>" dot-onetime/pad-records; then
  echo "ERROR: Pad usage length incorrect after encryption iteration 2."
  cat dot-onetime/pad-records
  exit 1
fi

../../onetime -C dot-onetime -e -p ../random-data-1 \
              -o long-msg-3.onetime ../long-msg
if ! grep -q "<length>136728</length>" dot-onetime/pad-records; then
  echo "ERROR: Pad usage length incorrect after encryption iteration 3."
  cat dot-onetime/pad-records
  exit 1
fi

../../onetime -C dot-onetime -d -p ../random-data-1 \
              -o long-msg-1 long-msg-1.onetime
if ! grep -q "<length>136728</length>" dot-onetime/pad-records; then
  cat dot-onetime/pad-records
  if grep -q "<length>45646</length>" dot-onetime/pad-records; then
    echo "ERROR: 'Decryption wrongly shrinks pad usage' bug is back."
  else
    echo "ERROR: Usage length wrong after decryption 1, but don't know why."
  fi
  exit 1
fi

if ! cmp long-msg-1 ../long-msg; then
  echo "ERROR: Decryption failed to produce correct plaintext."
  exit 1
fi

############################################################################
###  All tests finished.  Remove the test area.                          ###
############################################################################

cd ../..
# rm -rf tests/test-tmp
