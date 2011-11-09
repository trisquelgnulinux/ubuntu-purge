for i in $(ls -1 dists)
do
reprepro list $i $1
done
