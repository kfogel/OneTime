#!/bin/sh

# Get the exact 1.x or 2.x version number of OneTime.
# Takes one argument: the major version number ("1" or "2").

MAJOR_VERSION="__unset__"
if [ "${1}X" = "X" ]; then
  echo 'Major version number argument required ("1" or "2").'
  exit 1
elif [ "${1}X" = "1X" ]; then
  MAJOR_VERSION="1"
elif [ "${1}X" = "2X" ]; then
  MAJOR_VERSION="2"
else
  echo "Unrecognized major version number: '${1}'"
  exit 1
fi

TMP_DIR=ver-$$
mkdir ${TMP_DIR}
cd ${TMP_DIR}

BRANCH_NAME="master"
if [ "${MAJOR_VERSION}" = "1" ]; then
  BRANCH_NAME="1.x"
fi

git clone -q -b ${BRANCH_NAME} .. .
./onetime --version | cut -f 3 -d " "

cd ..
rm -rf ${TMP_DIR}
