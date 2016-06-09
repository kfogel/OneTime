#!/bin/sh

for posn in `python -c "for i in range(195,1050): print i"`; do
  cp input.onetime try-${posn}.onetime
  ../zap try-${posn}.onetime ${posn} ? 65
  echo "Trying posn ${posn}:"
  ../../onetime -n -d -p ../test-pad-1 try-${posn}.onetime
done
