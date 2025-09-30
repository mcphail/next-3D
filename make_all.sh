#!/bin/bash

make $1
for dir in demos/*/
do
	pushd ${dir} > /dev/null
	make $1
	popd > /dev/null
done