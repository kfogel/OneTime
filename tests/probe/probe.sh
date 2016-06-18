#!/bin/sh

# Permute every byte of a OneTime encrypted message through all
# possible values, and see what results we get.  At least some of
# those results should be message digest integrity errors.
#
# Suggested usage: './probe.sh > probe.out 2>&1'

for posn in `python -c "for i in range(195,1050): print i"`; do
  cp input.onetime this-try.onetime
  for newval in `python -c "for i in range(0,256): print i"`; do
    ../zap this-try.onetime ${posn} ? ${newval}
    echo ""
    echo "####################################################"
    echo "Trying ${newval} at position ${posn}:"
    # Actually, on one iteration ${newval} will be the same as
    # whatever value is already at ${posn}, but that just means the
    # message will decrypt perfectly, which is fine.
    ../../onetime -n -d -p ../test-pad-1 this-try.onetime
  done
done
