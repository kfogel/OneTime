#!/bin/sh

TMP_DIR=dist-$$

# We're still rolling 1.x releases for a while
for branch in master 1.x; do
  mkdir ${TMP_DIR}
  cd ${TMP_DIR}

  git clone -q -b ${branch} .. .

  # Make a .tar.gz.
  git archive --format="tar.gz" -9                              \
    --prefix="onetime-`./onetime --version | cut -f 3 -d " "`/" \
    -o onetime-`./onetime --version | cut -f 3 -d " "`.tar.gz   \
    ${branch}

  # Make a .zip.
  git archive --format="zip" -9                                 \
    --prefix="onetime-`./onetime --version | cut -f 3 -d " "`/" \
    -o onetime-`./onetime --version | cut -f 3 -d " "`.zip      \
    ${branch}

  for name in tar.gz zip; do
    mv onetime-`./onetime --version | cut -f 3 -d " "`.${name} ..
  done

  cp ./onetime ../onetime-`./onetime --version | cut -f 3 -d " "`

  cd ..
  rm -rf ${TMP_DIR}
done

# For now we're providing links to previous beta versions.
for tag in 2.0-beta2 2.0-beta; do
  git show ${tag}:onetime > onetime-${tag}
  chmod a+x onetime-${tag}
done    
