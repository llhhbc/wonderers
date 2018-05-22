

find content -type f -name "*.md" | while read line
do
  echo "import:"$line
  loadhugomd --infile=$line
done


