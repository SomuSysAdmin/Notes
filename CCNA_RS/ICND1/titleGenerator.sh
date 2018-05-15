#!/bin/bash
## To get file names
ls | sed -E "s|Module ([[:digit:]]+) (.*)|\\\\input\{\"Mod\1/\1. \2.tex\"\}|g" | head -n 6 | tail -n 5
## To insert part-headers into the files
ls | sed -E "s|Module ([[:digit:]]+) (.*)|echo -e \"\\\\part\{\2\}\" > \"Mod\1/\1. \2.tex\"|g" | head -n 6 | tail -n 5
## To insert chapter headers into the files
chpd=$(pwd | sed -E "s|.*/(.*)|\1|g" | sed -E "s|Module ([[:digit:]]+) (.*)|Mod\1/\1\. \2\.tex|g")
mno=$(echo $chpd | sed -E "s|Mod([[:digit:]]+)/.*|\1|g");
ls | sed -nE "s|Lesson ([[:digit:]]+) (.*)|echo \"\\\\chapter\{\2\}\" > \"Mod$mno/chapters/$mno\.\1\. \2\.tex\"\necho \"\\\\input{\\\\\"Mod$mno/chapters/$mno\.\1\. \2\.tex\\\\\"}\" >> \"$chpd\"|pg"
## To insert chapter headers into the files
pd=$(pwd | sed -E "s|.*/(.*)|\1|g" | sed -E "s|Module ([[:digit:]]+) (.*)|Mod\1/\1\. \2\.tex|g"); ls | sed -nE "s|Lesson ([[:digit:]]+) (.*)|echo \"\\\\chapter\{\2\}\" >> \"$pd\"|pg"
