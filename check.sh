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

TEST_PAD_1_ID="6d0031fd04e927feb893aad9478b9e7e213b56e7fc766fdb57f12d3a55fa36e4"
TEST_PAD_1_V1_ID="6af6d0ac17081705cec30833da3cd436a400c429"

TEST_PAD_2_ID="7613667562635a22e62c55aabbb22d7a39bc368a8d2263e611db5caa215cc4cf"
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
  if [ "${1}x" = "XFAILx" ]; then
    THIS_XFAIL="yes"
  elif [ "${1}x" != "x" ]; then
    echo "ERROR: unknown argument '${1}' to check_result()"
  fi

  if [ ${PASSED} = "yes" ]; then
    if [ "${THIS_XFAIL}x" = "yesx" ]; then
      echo "(XPASS): ${THIS_TEST}"
    else
      echo "PASS: ${THIS_TEST}"
    fi
  else
    if [ "${THIS_XFAIL}x" = "yesx" ]; then
      echo "(XFAIL): ${THIS_TEST}"
    else
      echo "FAIL: ${THIS_TEST}"
    fi
    # Print an extra blank line separating this "FAIL" line from the
    # tests that come after it, so any already-printed errors related
    # to this failure are visually grouped together with it.
    echo ""
  fi

  unset THIS_XFAIL # Is this how to do local scope portably in shell?
}

# TODO: You'd think this function would be named 'reset_test_area' and
# would just do something like this:
# 
#   cd ..
#   rm -rf test-tmp
#   mkdir test-tmp
#   cd test-tmp
# 
# But apparently we've got some inter-test dependencies, because if
# you try that, lots of tests fail.  None of this means the test suite
# is invalid, of course: it's testing what we think it's testing, it's
# just not designed as well as it could be, and that should be fixed.
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
echo '   A failing test will show "ERROR" details first -- which may span'
echo '   multiple lines and be very noisy -- followed by a "FAIL" line'
echo '   giving a brief description of that test.  If a test is currently'
echo '   expected to fail, for example due to a known bug not yet fixed, '
echo '   then its description starts with "(XFAIL)".'
echo ''
echo "   Note that some tests may take a while; don't be alarmed"
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
  echo ""
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
  echo ""
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
    echo ""
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
if ! grep -q "InnerFormat: unknown inner format version" err.out
then
  echo ""
  echo "ERROR: did not see expected error on failed decryption"
  cat err.out
  PASSED="no"
fi

if [ -f tmp-plaintext-b-1 ]
then
  echo ""
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
if ! grep -q "<length>12846</length>" dot-onetime/pad-records; then
  echo ""
  echo "ERROR: Pad usage length is not 12846 after encryption iteration 1."
  cat dot-onetime/pad-records
  PASSED="no"
fi

../../onetime -C dot-onetime -e -p ../test-pad-1 \
              -o tmp-ciphertext-b-2.onetime ../test-plaintext-b
if ! grep -q "<length>25023</length>" dot-onetime/pad-records; then
  echo ""
  echo "ERROR: Pad usage length is not 25023 after encryption iteration 2."
  cat dot-onetime/pad-records
  PASSED="no"
fi

../../onetime -C dot-onetime -e -p ../test-pad-1 \
              -o tmp-ciphertext-b-3.onetime ../test-plaintext-b
if ! grep -q "<length>37273</length>" dot-onetime/pad-records; then
  echo ""
  echo "ERROR: Pad usage length is not 37273 after encryption iteration 3."
  cat dot-onetime/pad-records
  PASSED="no"
fi

../../onetime -C dot-onetime -d -p ../test-pad-1 \
              -o tmp-plaintext-b-1 tmp-ciphertext-b-1.onetime
if ! grep -q "<length>37273</length>" dot-onetime/pad-records; then
  cat dot-onetime/pad-records
  if grep -q "<length>12846</length>" dot-onetime/pad-records; then
    # Note that as long as everything is working, this case will not
    # be triggered in normal test suite runs even if the length that
    # *would* indicate the return of this bug has changed from 12523
    # to something else due to normal development progress.  So if
    # we're inside the larger failure already, check carefully to see
    # whether we should actually be in this case and were just
    # expecting the wrong number.
    echo ""
    echo "ERROR: 'Decryption wrongly shrinks pad usage' bug is back."
  else
    echo ""
    echo "ERROR: Pad usage length is not 37273 after decryption 1, but don't know why."
  fi
  PASSED="no"
fi

if ! cmp tmp-plaintext-b-1 ../test-plaintext-b; then
  echo ""
  echo "ERROR: Decryption failed to produce correct plaintext."
  PASSED="no"
fi

check_result

########################################################################
start_new_test "decryption should record same pad usage as encryption"

# If Alice encrypts, resulting in pad usage range R for that pad, then
# if Bob decrypts starting from the same pad record state that Alice
# had started with, the Bob's post-decryption pad record state should
# be exactly the same as Alice's post-encryption pad record state.

cp -a dot-onetime e-dot-onetime  # separate encryption copy
cp -a dot-onetime d-dot-onetime  # separate decryption copy

../../onetime -C e-dot-onetime -e -p ../test-pad-1 \
              -o tmp-ciphertext-b-1 ../test-plaintext-b

../../onetime -C d-dot-onetime -d -p ../test-pad-1 \
              -o tmp-plaintext-b-1 tmp-ciphertext-b-1

if ! grep -q "<length>12846</length>" e-dot-onetime/pad-records; then
  grep "<length>" e-dot-onetime/pad-records
  echo ""
  echo "ERROR: expected pad usage length of 12846 for encryption"
  PASSED="no"
fi

if ! grep -q "<length>12846</length>" d-dot-onetime/pad-records; then
  if grep -q "<length>12265</length>" d-dot-onetime/pad-records; then
    # Note that as long as everything is working, this case will not
    # be triggered in normal test suite runs even if the length that
    # *would* indicate the return of this bug has changed from 12265
    # to something else due to normal development progress.  So if
    # we're inside the larger failure already, check carefully to see
    # whether we should actually be in this case and were just
    # expecting the wrong number.
    echo ""
    echo "ERROR: tail fuzz authn isn't being counted in pad usage record"
  else
    grep "<length>" d-dot-onetime/pad-records
    echo ""
    echo "ERROR: pad usage length is not 12846 after decryption, for some new reason"
  fi
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
  echo ""
  echo "ERROR: tmp-plaintext-a.decoded-1 does not match test-plaintext-a input."
  PASSED="no"
fi
../../onetime --config=dot-onetime -d -p ../test-pad-1  \
         < tmp-ciphertext-a.onetime > tmp-plaintext-a.decoded-2
maybe_show_lengths "After decoding again:"
if ! cmp ../test-plaintext-a tmp-plaintext-a.decoded-2; then
  echo ""
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
  echo ""
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
  echo ""
  echo "ERROR: tmp-plaintext-a.decoded-1 (pad test-pad-2) does not match test-plaintext-a input."
  PASSED="no"
fi
../../onetime --config=dot-onetime -d -p ../test-pad-2  \
         < tmp-ciphertext-a.onetime > tmp-plaintext-a.decoded-2
maybe_show_lengths "After decoding again:"
if ! cmp ../test-plaintext-a tmp-plaintext-a.decoded-2; then
  echo ""
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
  echo ""
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
  echo ""
  echo "ERROR: --show-id -p test-pad-1 failed to display ID"
  PASSED="no"
fi
if ! ../../onetime --config=blank-dot-onetime --show-id -p ../test-pad-1 \
             | grep -q "  ${TEST_PAD_1_V1_ID}"
then
  echo ""
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
   echo ""
   echo "ERROR: new ciphertext is bigger than v1 encryption of same plaintext"
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
  echo ""
  echo "ERROR: tmp-plaintext-a does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-a

if ! grep -q "<id>${TEST_PAD_1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input failed to upgrade pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input removed 0 offset from pad-records"
  PASSED="no"
fi

if ! grep -q "<length>15</length></used>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input affected length 15 in pad-records"
  PASSED="no"
fi

if [ `grep -c "</length></used>" v1-dot-onetime/pad-records` -gt 1 ]
then
  echo ""
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
  echo ""
  echo "ERROR: tmp-plaintext-a does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-a

if ! grep -q "<id>${TEST_PAD_1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input failed to upgrade pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input removed 0 offset from pad-records"
  PASSED="no"
fi

if grep -q "<length>15</length></used>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input left length 15 still in pad-records"
  PASSED="no"
fi

if ! grep -q "<length>30</length></used>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input failed to put length 30 in pad-records"
  PASSED="no"
fi

if [ `grep -c "</length></used>" v1-dot-onetime/pad-records` -gt 1 ]
then
  echo ""
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
  echo ""
  echo "ERROR: tmp-plaintext-a does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-a
rm tmp-ciphertext-a-1

if ! grep -q "<id>${TEST_PAD_1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input failed to upgrade pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input removed 0 offset from pad-records"
  PASSED="no"
fi

if ! grep -q "<length>588</length></used>" v1-dot-onetime/pad-records
then
  echo ""
  cat v1-dot-onetime/pad-records
  echo "ERROR: decoding v2 input affected length 588 in pad-records"
  PASSED="no"
fi

if [ `grep -c "</length></used>" v1-dot-onetime/pad-records` -gt 1 ]
then
  echo ""
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
  echo ""
  echo "ERROR: tmp-plaintext-a does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-a
rm tmp-ciphertext-a-1

if ! grep -q "<id>${TEST_PAD_1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input failed to upgrade pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input removed 0 offset from pad-records"
  PASSED="no"
fi

if ! grep -q "<length>588</length></used>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input failed to use length 588 in pad-records"
  cat v1-dot-onetime/pad-records
  PASSED="no"
fi

if [ `grep -c "</length></used>" v1-dot-onetime/pad-records` -gt 1 ]
then
  echo ""
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
  echo ""
  echo "ERROR: tmp-plaintext-a does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-a
rm tmp-ciphertext-a-1

if ! grep -q "<id>${TEST_PAD_1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input failed to upgrade pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input removed 0 offset from pad-records"
  PASSED="no"
fi

if ! grep -q "<length>15</length></used>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input removed length 15 from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>32</offset>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input failed to add offset 32 to pad-records"
  PASSED="no"
fi

if ! grep -q "<length>556</length></used>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v2 input failed to add length 556 to pad-records"
  cat v1-dot-onetime/pad-records
  PASSED="no"
fi

if [ `grep -c "</length></used>" v1-dot-onetime/pad-records` -gt 2 ]
then
  echo ""
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
  echo ""
  echo "ERROR: tmp-plaintext-b does not match original plaintext."
  PASSED="no"
fi
rm tmp-plaintext-b

if ! grep -q "<id>${TEST_PAD_2_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input failed to insert pad ID into pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_2_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input somehow inserted v1 pad ID into pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input removed 0 offset from pad-records"
  PASSED="no"
fi

# Expect the new length on the 10th line, which is in the second pad entry.
# But first test to make sure it's there at all; otherwise grep -n outputs
# nothing and the conditional gets harder to write.
if ! grep -q "<length>45541</length></used>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: decoding v1 input failed to insert new 45541 record"
  PASSED="no"
elif grep -q "<length>45541</length></used>" v1-dot-onetime/pad-records && \
     [ `grep -n "<length>45541</length></used>" v1-dot-onetime/pad-records \
        | cut -d ":" -f 1` -ne 10 ]
then
  echo ""
  echo "ERROR: decoding v1 input mis-inserted new 45541 record into pad-records"
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
  echo ""
  echo "ERROR: encoding failed to upgrade v1 pad ID in pad-records"
  PASSED="no"
fi

if grep -q "<id>${TEST_PAD_1_V1_ID}</id>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: encoding failed to remove v1 pad ID from pad-records"
  PASSED="no"
fi

if ! grep -q "<used><offset>0</offset>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: encoding removed 0 offset from v1 entry in pad-records"
  PASSED="no"
fi

# Expect the new offset on the 6th line, in second range of first entry.
# But first test to make sure it's there at all; otherwise grep -n outputs
# nothing and the conditional gets harder to write.
if ! grep -q "<used><offset>32</offset>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: encoding failed to insert new offset 32 into pad-records"
  PASSED="no"
elif grep -q "<used><offset>32</offset>" v1-dot-onetime/pad-records && \
     [ `grep -n "<used><offset>32</offset>" v1-dot-onetime/pad-records \
        | cut -d ":" -f 1` -ne 6 ]
then
  echo ""
  echo "ERROR: encoding mis-inserted new offset into pad-records"
  PASSED="no"
fi

# Expect the new length on the 7th line, in second range of first entry.
if ! grep -q "<length>12552</length></used>" v1-dot-onetime/pad-records
then
  echo ""
  echo "ERROR: failed to insert new length 12552 into pad-records"
  cat v1-dot-onetime/pad-records
  PASSED="no"
elif grep -q "<length>12552</length></used>" v1-dot-onetime/pad-records && \
     [ `grep -n "<length>12552</length></used>" v1-dot-onetime/pad-records \
        | cut -d ":" -f 1` -ne 7 ]
then
  echo ""
  echo "ERROR: encoding mis-inserted new length 12552 into pad-records"
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
  echo ""
  echo "ERROR: decoder failed to detect trailing garbage in input stream"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "tampered head fuzz is detected, but decryption succeeds"
# This is actually a questionable "feature", really more an artifact
# of where the head fuzz digest is located in the stream than of
# deliberate UX design.  Do we really want decryption to succeed if
# the head fuzz digest failed?  But to do otherwise, we'd need to put
# the digest before the message text section.

## Encrypt message
../../onetime --test-mode \
         --config=blank-dot-onetime -e -p ../test-pad-1  \
         -o tmp-ciphertext-b-1 < ../test-plaintext-b 2>err.out
../zap tmp-ciphertext-b-1 284 ? 71
../../onetime --config=blank-dot-onetime -d -p ../test-pad-1 \
    -o tmp-plaintext-b-1 < tmp-ciphertext-b-1 2>err.out
if ! grep -q "DigestMismatch: digest mismatch:" err.out || \
   ! grep -q "  computed: 6be52f46065d00c652e54f8770d6bf072115ffd2a1e4f3bb95bd3a49ba83161d" err.out || \
   ! grep -q "  received: d3d8a00fa588756733de1cf9f39a76ff58157d6e203c448b91d4a7b8e780f6fd" err.out
then
  echo ""
  echo "ERROR: did not see expected DigestMismatch error from tampered head fuzz"
  cat err.out
  PASSED="no"
fi

if ! cmp ../test-plaintext-b tmp-plaintext-b-1
then
  echo ""
  echo "ERROR: decryption unexpectedly failed when head fuzz tampered with"
  head tmp-plaintext-b-1
  echo "[...etc...]"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "tampering with ciphertext causes bzip decoder error"
## Encrypt message
# exit 1
../../onetime --config=blank-dot-onetime -e -p ../test-pad-1  \
         -o tmp-ciphertext-b-1 < ../test-plaintext-b 2>err.out
# In the base64-encoded ciphertext file, position 8563 is 'd' (100).
../zap tmp-ciphertext-b-1 8563 100 101
# exit 1
../../onetime --config=blank-dot-onetime -d -p ../test-pad-1 \
    < tmp-ciphertext-b-1 2>err.out
if ! grep -q "IOError: invalid data stream" err.out
then
  echo ""
  echo "ERROR: did not see expected IOerror from bzip decoder"
  cat err.out
  PASSED="no"
fi

check_result

########################################################################
start_new_test "basic encryption/decryption with all-nulls plaintext"

## There was no actual regression that motivated this test.  It's just
## that head and tail fuzz are both raw pad, i.e., null bytes
## encrypted against pad, so out of a sense of dutiful paranoia we
## should make sure that decryptions aren't accidentally looking like
## they're succeeding just because in some weird environment maybe
## the programs we use to check the output stop on the first null byte. 
## Also, it's just good practice in general to verify that a tool that
## is supposed to work transparently with binary data works with large
## all-nulls input -- if there's any problem handling binary data,
## that input is likely to stimulate it.

../../onetime --config=blank-dot-onetime -e -p ../test-pad-1 \
         -o tmp-ciphertext-all-nulls ../all-nulls
../../onetime --config=blank-dot-onetime -d -p ../test-pad-1 \
         -o tmp-plaintext-all-nulls tmp-ciphertext-all-nulls

if ! cmp tmp-plaintext-all-nulls ../all-nulls
then
  echo ""
  echo "ERROR: decrypted all-nulls plaintext does not match original"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "tampering with tail fuzz should have no effect"
## Encrypt message
../../onetime --config=blank-dot-onetime -e -p ../test-pad-1  \
         -o tmp-ciphertext-b-1 < ../test-plaintext-b 2>err.out
../zap tmp-ciphertext-b-1 17110 ? 52
../../onetime --config=blank-dot-onetime -d -p ../test-pad-1 \
    -o tmp-plaintext-b-1 < tmp-ciphertext-b-1 2>err.out
if grep -q "FuzzMismatch" err.out
then
  echo ""
  echo "ERROR: saw unexpected FuzzMismatch error on tampered tail fuzz"
  cat err.out
  PASSED="no"
fi

if ! cmp ../test-plaintext-b tmp-plaintext-b-1
then
  echo ""
  echo "ERROR: decryption failed when tail fuzz tampered with"
  cat tmp-plaintext-b-1
  PASSED="no"
fi

check_result

########################################################################
start_new_test "basic encryption/decryption with zero-length tail fuzz"

## If the head-fuzz or tail-fuzz source bytes are all zeros,
## everything should still work fine.  There was briefly a bug where
## we assumed that tail-fuzz always had non-zero length, but that's
## fixed now and this is the regression test for it.  Note that no one
## would ever use an all-nulls pad in practice, of course; it's just a
## convenient way to guarantee that the fuzz lengths are zero.

../../onetime --config=blank-dot-onetime -e -p ../all-nulls \
         -o tmp-ciphertext-a-1 ../test-plaintext-a
../../onetime --config=blank-dot-onetime -d -p ../all-nulls \
         -o tmp-plaintext-a tmp-ciphertext-a-1 2>err.out

if grep -q "FuzzMismatch: some source tail fuzz left over" err.out
then
  echo ""
  echo "ERROR: unable to handle zero-length tail fuzz"
  cat err.out
  PASSED="no"
fi

if ! cmp tmp-plaintext-a ../test-plaintext-a
then
  echo ""
  echo "ERROR: unexpected decryption failure with all-nulls pad"
  PASSED="no"
fi

check_result

########################################################################
start_new_test "tampering with message digest causes authentication error"
## Encrypt message
../../onetime --test-mode \
         --config=blank-dot-onetime -e -p ../test-pad-1  \
         -o tmp-ciphertext-a-1 < ../test-plaintext-a 2>err.out
# In the base64-encoded ciphertext file, position 626 is 'e' (101).
../zap tmp-ciphertext-a-1 626 101 102 # tweaking 'e' to 'f'
../../onetime --config=blank-dot-onetime -d -p ../test-pad-1 \
    -o tmp-plaintext-a-1 < tmp-ciphertext-a-1 2>err.out
if ! grep -q "DigestMismatch: digest mismatch:" err.out || \
   ! grep -q "  computed: ec6478d952bf3b13bd43dc2dd689d789e5fb9f408138fb71672ff2194038b913" err.out || \
   ! grep -q "  received: ec6478d952bf3b13bd43dc2dd689d788e5fb9f408138fb71672ff2194038b913" err.out
   # here is where they differ ------------------------> ^   
then
  echo ""
  echo "ERROR: did not see expected DigestMismatch error (30c7cd...)"
  cat err.out
  PASSED="no"
fi

if ! cmp ../test-plaintext-a tmp-plaintext-a-1
then
  echo ""
  echo "ERROR: decryption failed when digest tampered with"
  cat tmp-plaintext-a-1
  echo ""
  PASSED="no"
fi

check_result

########################################################################
start_new_test "tampering with head fuzz causes authentication error"
## Encrypt message
../../onetime --test-mode \
         --config=blank-dot-onetime -e -p ../test-pad-1  \
         -o tmp-ciphertext-a-1 < ../test-plaintext-a 2>err.out
# In the base64-encoded ciphertext file, position 221 is 'p' ().
../zap tmp-ciphertext-a-1 221 112 113  # tweak 'p' to 'q'
../../onetime --config=blank-dot-onetime -d -p ../test-pad-1 \
    -o tmp-plaintext-a-1 < tmp-ciphertext-a-1 2>err.out
if ! grep -q "DigestMismatch: digest mismatch:" err.out || \
   ! grep -q "  computed: fdaa87d94780a35bd6c891e23ec4c1b10b6aa9d52f55684984dc4111f1a30c1b" err.out || \
   ! grep -q "  received: ec6478d952bf3b13bd43dc2dd689d789e5fb9f408138fb71672ff2194038b913" err.out
then
  echo ""
  echo "ERROR: did not see expected DigestMismatch error (fdaa87d vs ec6478d)"
  cat err.out
  PASSED="no"
fi

if ! cmp ../test-plaintext-a tmp-plaintext-a-1
then
  echo ""
  echo "ERROR: decryption failed when head fuzz tampered with"
  cat tmp-plaintext-a-1
  echo ""
  PASSED="no"
fi

check_result

############################################################################
###  All tests finished.  Leave the test area in place for inspection.   ###
############################################################################

cd ../..
