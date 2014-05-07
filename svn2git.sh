#!/bin/bash

URL=svn://myrepo.ru/svnrepo/Projects/MainProject/source/trunk
USERS_FILE=svn-authors

SVN_USER=user
SVN_PASSWORD=password

START_REVISION=1

declare -A externals
EXT_URL=""
count=0
START_DATE=`date`
echo -e "\e[32mStarted at $START_DATE\e[0m"

for ext in `svn propget svn:externals $URL --username $SVN_USER --password $SVN_PASSWORD`; do
    if [[ $EXT_URL == "" ]]; then
	    EXT_URL=$ext
	else
		externals[$ext]=$EXT_URL
		count=$((count + 1))
		EXT_URL=""
#		echo debug: external = $ext, count = $count
	fi
done

echo -e "\e[32mFound $count externals\e[0m"

echo -e "\e[33m############################################################\e[0m"
echo -e "\e[32mNow exporting main repository\e[0m"

URL_MAIN=${URL/\/trunk/}
#echo $URL_MAIN
git svn clone -r$START_REVISION:HEAD --authors-file=svn-authors --trunk=trunk --username $SVN_USER --no-metadata $URL_MAIN trunk

echo -e "\e[33m############################################################\e[0m"
echo -e "\e[32mNow, main repository exported into trunk folder\e[0m"
echo -e "\e[32mExporting externals\e[0m"

for key in "${!externals[@]}"
do
	#EXT_REPO_URL=${externals[$key]}
	EXT_REPO_URL=`echo ${externals[$key]} | sed -e "s/\(.*\)\/$key/\1/g"`
    echo -e "\e[32mexporting $key repo from url $EXT_REPO_URL\e[0m"
    
    git svn clone -r$START_REVISION:HEAD --authors-file=svn-authors --trunk=$key --username $SVN_USER --no-metadata ${EXT_REPO_URL} $key
done

echo -e "\e[33m############################################################\e[0m"
echo -e "\e[32mnow merging external repositories in main\e[0m"

cd trunk

# first method
for key in "${!externals[@]}"
do
	echo -e "\e[32mmerging repo $key into main...\e[0m"
	git subtree add -P $key ../$key master
done

# second method
# for key in "${!externals[@]}"
# do
# 	echo -e "\e[32mmerging repo $key into main...\e[0m"
# 	git remote add -f $key /usr/devel/Export/$key
# 	git merge -s ours --no-commit $key/master
# 	git read-tree --prefix=$key -u $key/master
# 	git commit -m "Merged commit for $key repository"
# done

END_DATE=`date`
echo -e "\e[32mStarted at $START_DATE, finished at $END_DATE\e[0m"

echo -e "\e[32mDone!\e[0m"

