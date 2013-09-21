#!/bin/sh

# Test suite for OneTime.
#
# How to write a new test:
#
#   1) start_new_test "some descriptive test string"
#
#   2) Do stuff.  Your cwd is a temporary directory, tests/test-tmp/,
#      and it already has its own tmp config directories in place, e.g.,
#      "tests/test-tmp/dot-onetime" and others (see reset_config for
#      the full list).  So a typical invocation will look like this:
#      "../../onetime --config=dot-onetime -e -p ../test-pad-1 etc etc"
#
#      (All the permanent test data lives in tests/, so you'll use
#      arguments like "../test-plaintext-b" and ../test-pad-1" a lot.)
#
#   3) If a tested condition fails, echo "ERROR: describe how & why",
#      then set PASSED="no".
#
#   4) At the end of the test, call check_result.
#
# Note on why tests should *always* pass a config dir explicitly:
#
# Even when passing -n (--no-trace), you should always specify one of
# the test config directories explicitly (use "blank-dot-onetime" for
# a no-op config dir).  Otherwise, if you happen to have some of the
# test pads recorded in your own ~/.onetime/pad-records (as can
# accidentally happen if you've been doing OneTime development and
# failed to pass '--config' every time you manually tested), you could
# write a test here that either inadvertently depends on something in
# your ~/.onetime/pad-records or is inadvertently sensitive to the
# ~/.onetime/pad-records of other people who have played around with
# the test pads and accidentally affected their ~/.onetime/pad-records.
# Either way, your test would not be portable.  Even when an invocation
# couldn't possibly depend on nor affect any values in pad-records
# (e.g., it just runs --show-id or something), you should still pass
# "--config=blank-dot-onetime", because otherwise someone running the
# test who doesn't currently have a ~/.onetime directory will suddenly
# have one afterwards, which would be bad behavior for a test suite.

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
   for name in dot-onetime v1-dot-onetime blank-dot-onetime; do
     rm -rf ${name}
     cp -a ../${name} ./${name}
     rm -rf ${name}/.svn
   done
}

########################################################################
###               Explain the test suite's output.                   ###
########################################################################

echo ''
echo '   Each passing test is indicated by exactly one "PASS" line'
echo '   that includes a brief description of the test.'
echo ''
echo '   Failing tests will show error details first -- which may span'
echo '   multiple lines and be very noisy -- followed by a "FAIL" line'
echo '   that also includes a brief description of the test.  If the'
echo '   test is currently expected to fail, for example a known bug'
echo '   not yet fixed, that description will start with "(XFAIL)".'
echo ''
echo "   Note that some tests may take a while.  Don't be alarmed"
echo "   if a minute or two goes by without output."
echo ''

########################################################################
start_new_test "basic encryption, decryption"
../../onetime --config=blank-dot-onetime -e -p ../test-pad-1 \
         -o tmp-ciphertext-b-1 ../test-plaintext-b
../../onetime --config=blank-dot-onetime -d -p ../test-pad-1 \
         -o tmp-plaintext-b tmp-ciphertext-b-1

if ! cmp tmp-plaintext-b ../test-plaintext-b
then
  echo "ERROR: decrypted plaintext does not match original plaintext"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "encryption, decryption of large plaintext"
# Assemble a pad and plaintext so large that not only are they many
# times larger than our 8k chunk size, but they're larger than the
# Python bzip2 compressor's maximum possible buffer.  Experiments
# indicate that range(0, 2) would be enough here, but let's use 5.
for ignored in `python -c "for i in range(0, 5): print i"`; do
  cat ../test-pad-1 >> large-pad
  cat ../test-pad-2 >> large-plaintext
done

../../onetime --config=blank-dot-onetime -e -p large-pad \
         -o tmp-large-ciphertext large-plaintext
../../onetime --config=blank-dot-onetime -d -p large-pad \
         -o tmp-large-plaintext tmp-large-ciphertext

if ! cmp tmp-large-plaintext large-plaintext
then
  echo "ERROR: decrypted large plaintext does not match original plaintext"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "option parsing"

###
# In the tests of the various option parsing methods, "e.N" is
# encrypted text and "d.N" is decrypted text.
###

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
    echo "ERROR: one or more of the usage modes failed"
    PASSED="no"
  fi
done

check_result

########################################################################
start_new_test "failed decryption should give an error and create no output"
../../onetime --config=blank-dot-onetime -e -p ../test-pad-1  \
         -o tmp-ciphertext-b-1 < ../test-plaintext-b
../../onetime --config=blank-dot-onetime -d -p ../test-pad-2  \
         -o tmp-plaintext-b-1 tmp-ciphertext-b-1 2>err.out
if ! grep -q "DecodingError: unable to decode (wrong pad?)" err.out
then
  echo "ERROR: did not see expected error on failed decryption"
  PASSED="no"
fi

if [ -f tmp-plaintext-b-1 ]
then
  echo "ERROR: output file left still created on failed decryption"
  PASSED="no"
fi

check_result

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
start_new_test "make sure '--show-id' shows everything it should"

#####
## Check that both v2 and v1 pad IDs are displayed with --show-id.
if ! ../../onetime --config=blank-dot-onetime --show-id -p ../test-pad-1 \
             | grep -q ${TEST_PAD_1_ID}
then
  echo "ERROR: --show-id -p test-pad-1 failed to display ID"
  PASSED="no"
fi
if ! ../../onetime --config=blank-dot-onetime --show-id -p ../test-pad-1 \
             | grep -q "  ${TEST_PAD_1_V1_ID}"
then
  echo "ERROR: --show-id -p test-pad-1 failed to display v2 ID"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "same plaintext should encrypt smaller with v2+ than with v1"

## Encrypt message, compare against same message encrypted with v1.
## Result: the more recent ciphertext should be noticeably smaller.

../../onetime -n --config=blank-dot-onetime -e -p ../test-pad-1 \
        -o test-ciphertext-b-1 ../test-plaintext-b
BYTES_NOW=`wc -c test-ciphertext-b-1 | cut -d " " -f1`
BYTES_V1=`wc -c ../test-v1-ciphertext-b-1 | cut -d " " -f1`
if [ ${BYTES_NOW} -ge ${BYTES_V1} ]
then
   echo "ERROR: new crypttext is bigger than v1 encryption of same plaintext"
   PASSED="no"
fi

check_result


########################################################################
start_new_test "decode v1 msg, where v1 entry has range already used"

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

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input removed 0 offset from pad-records"
  PASSED="no"
fi

if ! grep -q "<length>15</length></used>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input affected length 15 in pad-records"
  PASSED="no"
fi

if [ `grep -c "</length></used>" v1-dot-onetime/pad-records` -gt 1 ]
then
  echo "ERROR: decoding v1 input inserted spurious length into pad-records"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "decode v1 msg, where v1 entry has range not already used"

## Receive v1 msg M, have v1 pad-records file with pad entry for M's
## pad, but this stretch of pad not marked as used.
## Result: upgraded pad ID, stretch marked as used.
../../onetime --config=v1-dot-onetime -d -p ../test-pad-1  \
         < ../test-v1-ciphertext-offset-15-a-1 > tmp-plaintext-a
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

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input removed 0 offset from pad-records"
  PASSED="no"
fi

if grep -q "<length>15</length></used>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input left length 15 still in pad-records"
  PASSED="no"
fi

if ! grep -q "<length>30</length></used>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input failed to put length 30 in pad-records"
  PASSED="no"
fi

if [ `grep -c "</length></used>" v1-dot-onetime/pad-records` -gt 1 ]
then
  echo "ERROR: decoding v1 input inserted spurious length into pad-records"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "decode v2 msg, where v1 entry has range already used"

## Receive v2 msg M, have v1 pad-records file with pad entry for M's
## pad and that stretch of pad already marked as used.
## Result: upgraded pad ID, everything else stays same.

# Create the ciphertext, leaving no trace (this is test prep only).
../../onetime -n --config=blank-dot-onetime -e -p ../test-pad-1 \
         < ../test-plaintext-a > tmp-ciphertext-a-1

# Manually tweak the v1 pad-records file to claim that range is
# already used, since otherwise it's a bit tough (using v2 onetime) to
# get that result, given that v2 would automatically upgrade the
# record's ID along with the range, and the whole point here is that
# we want to test that the ID can get upgraded without the range being
# affected.
sed -e 's|<length>15</length></used>|<length>512</length></used>|' \
    < v1-dot-onetime/pad-records > v1-dot-onetime/TMP-pad-records
mv v1-dot-onetime/TMP-pad-records v1-dot-onetime/pad-records

# Decrypt the v2 file, updating the newly range-expanded v1 pad-records.
../../onetime --config=v1-dot-onetime -d -p ../test-pad-1  \
         < tmp-ciphertext-a-1 > tmp-plaintext-a
if ! cmp ../test-plaintext-a tmp-plaintext-a; then
  echo "ERROR: tmp-plaintext-a does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-a
rm tmp-ciphertext-a-1

if ! grep -q "<id>${TEST_PAD_1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input failed to upgrade pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input removed 0 offset from pad-records"
  PASSED="no"
fi

if ! grep -q "<length>512</length></used>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input affected length 512 in pad-records"
  PASSED="no"
fi

if [ `grep -c "</length></used>" v1-dot-onetime/pad-records` -gt 1 ]
then
  echo "ERROR: decoding v2 input inserted spurious length into pad-records"
  PASSED="no"
fi

check_result


########################################################################
start_new_test "decode v2 msg, where v1 entry range needs stretching"

## Receive v2 msg M, have v1 pad-records file with pad entry for M's
## pad, but this stretch of pad not marked as used and starting within
## the highest current used range.
## Result: upgraded pad ID, stretch marked as used.

# Create the ciphertext, leaving no trace (this is test prep only).
../../onetime -n --config=blank-dot-onetime -e -p ../test-pad-1 \
         < ../test-plaintext-a > tmp-ciphertext-a-1

# Manually tweak the v1 pad-records file to put the already-used range
# just above 32, which is the offset where our v2 ciphertext starts
# using the pad.  This gives us a chance to see if the range gets
# stretched and replaced when we decrypt.
sed -e 's|<length>15</length></used>|<length>33</length></used>|' \
    < v1-dot-onetime/pad-records > v1-dot-onetime/TMP-pad-records
mv v1-dot-onetime/TMP-pad-records v1-dot-onetime/pad-records

# Decrypt the v2 file, updating the newly range-expanded v1 pad-records.
../../onetime --config=v1-dot-onetime -d -p ../test-pad-1  \
         < tmp-ciphertext-a-1 > tmp-plaintext-a
if ! cmp ../test-plaintext-a tmp-plaintext-a; then
  echo "ERROR: tmp-plaintext-a does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-a
rm tmp-ciphertext-a-1

if ! grep -q "<id>${TEST_PAD_1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input failed to upgrade pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input removed 0 offset from pad-records"
  PASSED="no"
fi

if ! grep -q "<length>85</length></used>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input failed to use length 85 in pad-records"
  PASSED="no"
fi

if [ `grep -c "</length></used>" v1-dot-onetime/pad-records` -gt 1 ]
then
  echo "ERROR: decoding v2 input inserted spurious length into pad-records"
  PASSED="no"
fi

check_result


########################################################################
start_new_test "decode v2 msg, where v1 entry needs new range"

## Receive v2 msg M, have v1 pad-records file with pad entry for M's
## pad, but this stretch of pad not marked as used and starting
## after the end of the highest current used range.
## Result: upgraded pad ID and new range added.

# Create the ciphertext, leaving no trace (this is test prep only).
../../onetime -n --config=blank-dot-onetime -e -p ../test-pad-1 \
         < ../test-plaintext-a > tmp-ciphertext-a-1

# Decrypt the v2 file, updating the newly range-expanded v1 pad-records.
../../onetime --config=v1-dot-onetime -d -p ../test-pad-1  \
         < tmp-ciphertext-a-1 > tmp-plaintext-a
if ! cmp ../test-plaintext-a tmp-plaintext-a; then
  echo "ERROR: tmp-plaintext-a does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-a
rm tmp-ciphertext-a-1

if ! grep -q "<id>${TEST_PAD_1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input failed to upgrade pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input removed 0 offset from pad-records"
  PASSED="no"
fi

if ! grep -q "<length>15</length></used>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input removed length 15 from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>32</offset>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input failed to add offset 32 to pad-records"
  PASSED="no"
fi

if ! grep -q "<length>53</length></used>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v2 input failed to add length 53 to pad-records"
  PASSED="no"
fi

if [ `grep -c "</length></used>" v1-dot-onetime/pad-records` -gt 2 ]
then
  echo "ERROR: decoding v2 input inserted spurious length into pad-records"
  PASSED="no"
fi

check_result


########################################################################
start_new_test "decode v1 msg, where no entry in pad-records at all"

## Receive v1 msg M, have no entry in pad-records file for M's pad.
## Result: new v2 entry
../../onetime --config=v1-dot-onetime -d -p ../test-pad-2  \
         < ../test-v1-ciphertext-b-2 > tmp-plaintext-b
if ! cmp ../test-plaintext-b tmp-plaintext-b; then
  echo "ERROR: tmp-plaintext-b does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-b

if ! grep -q "<id>${TEST_PAD_2_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input failed to insert pad ID into pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_2_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input somehow inserted v1 pad ID into pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input removed 0 offset from pad-records"
  PASSED="no"
fi

# Expect the new length on the 10th line, which is in the second pad entry.
# But first test to make sure it's there at all; otherwise grep -n outputs
# nothing and the conditional gets harder to write.
if ! grep -q "<length>45541</length></used>" v1-dot-onetime/pad-records
then
  echo "ERROR: decoding v1 input failed to insert new record into pad-records"
  PASSED="no"
elif [ `grep -n "<length>45541</length></used>" v1-dot-onetime/pad-records \
        | cut -d ":" -f 1` -ne 10 ]
then
  echo "ERROR: decoding v1 input mis-inserted new record into pad-records"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "encode msg, where v1 pad entry has some range already used"

## Encrypt message, have v1 pad-records file with entry for pad used.
## Result: pad entry should be upgraded, with stretch now marked used.

../../onetime --config=v1-dot-onetime -e -p ../test-pad-1  \
         -o tmp-ciphertext-b-1 < ../test-plaintext-b
# Toss the encryption, as it's not what we're testing here.
rm tmp-ciphertext-b-1

if ! grep -q "<id>${TEST_PAD_1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: encoding failed to upgrade v1 pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo "ERROR: encoding failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo "ERROR: encoding removed 0 offset from v1 entry in pad-records"
  PASSED="no"
fi

# Expect the new offset on the 6th line, in second range of first entry.
# But first test to make sure it's there at all; otherwise grep -n outputs
# nothing and the conditional gets harder to write.
if ! grep -q "<used><offset>32</offset>" v1-dot-onetime/pad-records
then
  echo "ERROR: encoding failed to insert new offset into pad-records"
  PASSED="no"
elif [ `grep -n "<used><offset>32</offset>" v1-dot-onetime/pad-records \
        | cut -d ":" -f 1` -ne 6 ]
then
  echo "ERROR: encoding mis-inserted new offset into pad-records"
  PASSED="no"
fi

# Expect the new length on the 7th line, in second range of first entry.
if ! grep -q "<length>12049</length></used>" v1-dot-onetime/pad-records
then
  echo "ERROR: encoding failed to insert expected new length into pad-records"
  PASSED="no"
elif [ `grep -n "<length>12049</length></used>" v1-dot-onetime/pad-records \
        | cut -d ":" -f 1` -ne 7 ]
then
  echo "ERROR: encoding failed to insert correct new length into pad-records"
  PASSED="no"
fi
check_result


########################################################################
start_new_test "decode msg, erroring because garbage after base64 data"
## Encrypt message
../../onetime --config=blank-dot-onetime -e -p ../test-pad-1  \
         -o tmp-ciphertext-b-1 < ../test-plaintext-b
sed -e 's/-----END OneTime MESSAGE-----/	\n-----END OneTime MESSAGE-----/' \
    < tmp-ciphertext-b-1 > tmp-ciphertext-b-1.damaged
../../onetime --config=blank-dot-onetime -d -p ../test-pad-1  \
         -o tmp-plaintext-b-1 tmp-ciphertext-b-1.damaged 2>err.out
if ! grep -q "DecodingError: unexpected input" err.out
then
  echo "ERROR: decoder failed to detect trailing garbage in input stream"
  PASSED="no"
fi

check_result

############################################################################
###  All tests finished.  Leave the test area in place for inspection.   ###
############################################################################

cd ../..
