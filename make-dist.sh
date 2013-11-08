#!/bin/sh

TMP_DIR=dist-$$

mkdir ${TMP_DIR}
cd ${TMP_DIR}

# Until 2.0 is done, we're rolling 1.x releases.
git clone -q -b 1.x .. .

# Make a .tar.gz.
git archive --format="tar.gz" -9                              \
  --prefix="onetime-`./onetime --version | cut -f 3 -d " "`/" \
  -o onetime-`./onetime --version | cut -f 3 -d " "`.tar.gz   \
  1.x

# Make a .zip.
git archive --format="zip" -9                                 \
  --prefix="onetime-`./onetime --version | cut -f 3 -d " "`/" \
  -o onetime-`./onetime --version | cut -f 3 -d " "`.zip      \
  1.x

for name in tar.gz zip; do
  mv onetime-`./onetime --version | cut -f 3 -d " "`.${name} ..
done

cp ./onetime ../onetime-`./onetime --version | cut -f 3 -d " "`

cd ..
rm -rf ${TMP_DIR}
