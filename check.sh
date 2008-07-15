#!/bin/sh

cd tests

# Because OneTime itself is sensitive to version control, we create
# a fresh test directory every time.  For now, we don't test the
# version control functionality, just encoding and decoding.
rm -rf test-tmp
mkdir test-tmp
cp -a dot-onetime test-tmp
rm -rf test-tmp/dot-onetime/.svn
cd test-tmp

############################################################################
###  Option-parsing tests.                                               ###
############################################################################

###
# In the tests of the various option parsing methods, "e.N" is
# encrypted text and "d.N" is decrypted text.
###

# mode 1
../../onetime --config=dot-onetime -e -p ../random-data-2 -o e.1 ../test-msg
../../onetime --config=dot-onetime -d -p ../random-data-2 -o d.1 e.1

# mode 2
../../onetime --config=dot-onetime -e -p ../random-data-2 ../test-msg
mv ../test-msg.onetime e.2.onetime
../../onetime --config=dot-onetime -d -p ../random-data-2 e.2.onetime
mv e.2 d.2

# mode 3
../../onetime --config=dot-onetime -e -p ../random-data-2 -o - ../test-msg > e.3
../../onetime --config=dot-onetime -d -p ../random-data-2 -o - e.3 > d.3

# mode 4
../../onetime --config=dot-onetime -e -p ../random-data-2 < ../test-msg > e.4
../../onetime --config=dot-onetime -d -p ../random-data-2 < e.4 > d.4

# mode 5
../../onetime --config=dot-onetime -e -p ../random-data-2 -o e.5 < ../test-msg
../../onetime --config=dot-onetime -d -p ../random-data-2 -o d.5 < e.5

PASSED="yes"
for n in 1 2 3 4 5; do
  if cmp ../test-msg d.${n}; then
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

# Print the (string) first argument, then display all pad lengths.
# NOTE: Deactivated by default.  Change 'false' to 'true' to turn on.
function show_lengths()
{
   if false; then
     echo ${1}
     grep "/length" dot-onetime/pad-records
     echo ""
   fi
}

show_lengths "Before any encoding or decoding:"

# Encode
../../onetime --config=dot-onetime -e -p ../random-data-1  \
         < ../test-msg > test-msg.onetime

show_lengths "After encoding:"

# Decode twice, to make sure the pad can reconsume safely.
../../onetime --config=dot-onetime -d -p ../random-data-1  \
         < test-msg.onetime > test-msg.decoded-1

show_lengths "After decoding once:"

../../onetime --config=dot-onetime -d -p ../random-data-1  \
         < test-msg.onetime > test-msg.decoded-2

show_lengths "After decoding again:"

# Encode again with the same pad
../../onetime --config=dot-onetime -e -p ../random-data-1  \
         < ../test-msg > test-msg.onetime

show_lengths "After encoding again:"

# Decode only once this time.
../../onetime --config=dot-onetime -d -p ../random-data-1  \
         < test-msg.onetime > test-msg.decoded-3

show_lengths "After decoding:"

if cmp ../test-msg test-msg.decoded-1; then
  echo "Functionality tests passed."
else
  echo "Error: functionality tests failed, something went wrong."
fi


############################################################################
###  All tests finished.  Remove the test area.                          ###
############################################################################

cd ../..
rm -rf tests/test-tmp
