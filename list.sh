for i in $(grep ^Code conf/distributions |cut -d' ' -f2)
do
reprepro list $i $1
done
