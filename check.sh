#!/bin/sh

TEST_PAD_1_ID="978f54bb57aa14de9597a21f107f34255ce28be3"
TEST_PAD_1_V1_ID="6af6d0ac17081705cec30833da3cd436a400c429"

TEST_PAD_2_ID="6788fea7a6fe5fd200dcbd09df586bc9239b2614"
TEST_PAD_2_V1_ID="de61f169bce003a1189b3e6ebb8ddfc0ef007ac2"

# See start_new_test() and check_result() for what these do.
THIS_TEST="(no test name initialized yet)"
PASSED="(uninitialized)"

cd tests
rm -rf test-tmp
mkdir test-tmp
cd test-tmp

start_new_test()
{
  THIS_TEST="${1}"
  PASSED="yes"  # see check_result()
  reset_config
}

check_result()
{
  if [ ${PASSED} = "yes" ]; then
    echo "PASS: ${THIS_TEST}"
  else
    echo "FAIL: ${THIS_TEST}"
  fi
}

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

start_new_test "option parsing"

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

for n in 1 2 3 4 5; do
  if cmp ../test-plaintext-a d.${n}; then
    true
  else
    PASSED="no"
  fi
done

check_result

############################################################################
###  Functionality tests.                                                ###
############################################################################

########################################################################
start_new_test "decryption should not shrink pad usage"

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
../../onetime -C dot-onetime -e -p ../test-pad-1 \
              -o tmp-ciphertext-b-1.onetime ../test-plaintext-b
if ! grep -q "<length>12154</length>" dot-onetime/pad-records; then
  echo "ERROR: Pad usage length incorrect after encryption iteration 1."
  cat dot-onetime/pad-records
  PASSED="no"
fi

../../onetime -C dot-onetime -e -p ../test-pad-1 \
              -o tmp-ciphertext-b-2.onetime ../test-plaintext-b
if ! grep -q "<length>24203</length>" dot-onetime/pad-records; then
  echo "ERROR: Pad usage length incorrect after encryption iteration 2."
  cat dot-onetime/pad-records
  PASSED="no"
fi

../../onetime -C dot-onetime -e -p ../test-pad-1 \
              -o tmp-ciphertext-b-3.onetime ../test-plaintext-b
if ! grep -q "<length>36252</length>" dot-onetime/pad-records; then
  echo "ERROR: Pad usage length incorrect after encryption iteration 3."
  cat dot-onetime/pad-records
  PASSED="no"
fi

../../onetime -C dot-onetime -d -p ../test-pad-1 \
              -o tmp-plaintext-b-1 tmp-ciphertext-b-1.onetime
if ! grep -q "<length>36252</length>" dot-onetime/pad-records; then
  cat dot-onetime/pad-records
  if grep -q "<length>12154</length>" dot-onetime/pad-records; then
    echo "ERROR: 'Decryption wrongly shrinks pad usage' bug is back."
  else
    echo "ERROR: Usage length wrong after decryption 1, but don't know why."
  fi
  PASSED="no"
fi

if ! cmp tmp-plaintext-b-1 ../test-plaintext-b; then
  echo "ERROR: Decryption failed to produce correct plaintext."
  PASSED="no"
fi

check_result

########################################################################
start_new_test "test reconsumption via repeated encoding and decoding"

# Debugging helper function.  Deactivated by default -- change 'false'
# to 'true' to turn this on.
# Print the (string) first argument, then display all pad lengths.
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
         < ../test-plaintext-a > tmp-ciphertext-a.onetime
maybe_show_lengths "After encoding:"
# Decode twice, to make sure the pad can reconsume safely.
../../onetime --config=dot-onetime -d -p ../test-pad-1  \
         < tmp-ciphertext-a.onetime > tmp-plaintext-a.decoded-1
maybe_show_lengths "After decoding once:"
if ! cmp ../test-plaintext-a tmp-plaintext-a.decoded-1; then
  echo "ERROR: tmp-plaintext-a.decoded-1 does not match test-plaintext-a input."
  PASSED="no"
fi
../../onetime --config=dot-onetime -d -p ../test-pad-1  \
         < tmp-ciphertext-a.onetime > tmp-plaintext-a.decoded-2
maybe_show_lengths "After decoding again:"
if ! cmp ../test-plaintext-a tmp-plaintext-a.decoded-2; then
  echo "ERROR: tmp-plaintext-a.decoded-2 does not match test-plaintext-a input."
  PASSED="no"
fi
# Encode again with the same pad
../../onetime --config=dot-onetime -e -p ../test-pad-1  \
         < ../test-plaintext-a > tmp-ciphertext-a.onetime
maybe_show_lengths "After encoding again:"
# Decode only once this time.
../../onetime --config=dot-onetime -d -p ../test-pad-1  \
         < tmp-ciphertext-a.onetime > tmp-plaintext-a.decoded-3
maybe_show_lengths "After decoding:"
if ! cmp ../test-plaintext-a tmp-plaintext-a.decoded-3; then
  echo "ERROR: tmp-plaintext-a.decoded-3 does not match test-plaintext-a input."
  PASSED="no"
fi

# Now do the entire thing again with the other pad.
# Encode
../../onetime --config=dot-onetime -e -p ../test-pad-2  \
         < ../test-plaintext-a > tmp-ciphertext-a.onetime
maybe_show_lengths "After encoding:"
# Decode twice, to make sure the pad can reconsume safely.
../../onetime --config=dot-onetime -d -p ../test-pad-2  \
         < tmp-ciphertext-a.onetime > tmp-plaintext-a.decoded-1
maybe_show_lengths "After decoding once:"
if ! cmp ../test-plaintext-a tmp-plaintext-a.decoded-1; then
  echo "ERROR: tmp-plaintext-a.decoded-1 (pad test-pad-2) does not match test-plaintext-a input."
  PASSED="no"
fi
../../onetime --config=dot-onetime -d -p ../test-pad-2  \
         < tmp-ciphertext-a.onetime > tmp-plaintext-a.decoded-2
maybe_show_lengths "After decoding again:"
if ! cmp ../test-plaintext-a tmp-plaintext-a.decoded-2; then
  echo "ERROR: tmp-plaintext-a.decoded-2 (pad test-pad-2) does not match test-plaintext-a input."
  PASSED="no"
fi
# Encode again with the same pad
../../onetime --config=dot-onetime -e -p ../test-pad-2  \
         < ../test-plaintext-a > tmp-ciphertext-a.onetime
maybe_show_lengths "After encoding again:"
# Decode only once this time.
../../onetime --config=dot-onetime -d -p ../test-pad-2  \
         < tmp-ciphertext-a.onetime > tmp-plaintext-a.decoded-3
maybe_show_lengths "After decoding:"
if ! cmp ../test-plaintext-a tmp-plaintext-a.decoded-3; then
  echo "ERROR: tmp-plaintext-a.decoded-3 (pad test-pad-2) does not match test-plaintext-a input."
  PASSED="no"
fi

check_result

########################################################################
start_new_test "'--show-id' shows everything it should"

#####
## Check that both v2 and v1 pad IDs are displayed with --show-id.
if ! ../../onetime --show-id -p ../test-pad-1 | grep -q ${TEST_PAD_1_ID}
then
  echo "ERROR: --show-id -p test-pad-1 failed to display ID"
  PASSED="no"
fi
if ! ../../onetime --show-id -p ../test-pad-1 | grep -q "  ${TEST_PAD_1_V1_ID}"
then
  echo "ERROR: --show-id -p test-pad-1 failed to display v2 ID"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "decode v1 message where pad range already used"

## Receive v1 msg M, have v1 pad-records file with pad entry for M's
## pad, and that stretch of pad already marked as used.  Decode msg.
## Result: upgraded pad ID, everything else stays same.
../../onetime --config=v1-dot-onetime -d -p ../test-pad-1  \
         < ../test-v1-ciphertext-offset-0-a-1 > tmp-plaintext-a
if ! cmp ../test-plaintext-a tmp-plaintext-a; then
  echo "ERROR: tmp-plaintext-a does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-a

if ! grep -q "<id>${TEST_PAD_1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input failed to upgrade pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

check_result

#####
## Receive v1 msg M, have v1 pad-records file with pad entry for M's
## pad, but this stretch of pad not marked as used.
## Result: upgraded pad ID, stretch marked as used.
reset_config

#####
## Receive v2 msg M, have v1 pad-records file with pad entry for M's
## pad and that stretch of pad already marked as used.
## Result: upgraded pad ID, everything else stays same.
reset_config

#####
## Receive v2 msg M, have v1 pad-records file with pad entry for M's
## pad, but this stretch of pad not marked as used.
## Result: upgraded pad ID, stretch marked as used.
reset_config

#####
## Receive v1 msg M, have no entry in pad-records file for M's pad.
## Result: new v2 entry
reset_config

#####
## Encrypt message, have v1 pad-records file with entry for pad used.
## Result: pad entry should be upgraded, with stretch marked as used.
reset_config

############################################################################
###  All tests finished.  Leave the test area in place for inspection.   ###
############################################################################

cd ../..
