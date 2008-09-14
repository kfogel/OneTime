#!/bin/sh

VER=`../onetime --version | cut -f 3 -d " "`

rm -rf onetime-*.* onetime_*.*.orig.tar.gz

mv ../onetime-${VER}.tar.gz ./onetime_${VER}.orig.tar.gz
tar zxvf onetime_${VER}.orig.tar.gz
cp -a debian onetime-${VER}/
rm -rf onetime-${VER}/debian/.svn

(cd onetime-${VER}/; dpkg-buildpackage -rfakeroot)

rm -rf output/*

if [ -f onetime_${VER}-1.diff.gz ]; then
  mv onetime_${VER}-1.diff.gz output;
fi

if [ -f onetime_${VER}-1.dsc ]; then
  mv onetime_${VER}-1.dsc output;
fi

if [ -f onetime_${VER}-1_i386.changes ]; then
  mv onetime_${VER}-1_i386.changes output;
fi

if [ -f onetime_${VER}-1_i386.deb ]; then
  mv onetime_${VER}-1_i386.deb output;
fi

if [ -f onetime_${VER}-1.tar.gz ]; then
  mv onetime_${VER}-1.tar.gz output;
fi

if [ -f onetime_${VER}.orig.tar.gz ]; then
  mv onetime_${VER}.orig.tar.gz output;
fi

echo ""
echo "Done.  Package files placed in debian/output/:"
echo ""
ls -l output/
echo ""
