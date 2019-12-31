#!/bin/bash

# repo_list.txt に記載された GitHub レポジトリが存在しない場合、
# Github からダウンロードし、GTAGS と HTAGS を回す

set -euo pipefail


CURRENT_DIR=`pwd`

REPOSITORY_LIST="repo_list.txt"
GIT_REPOSITORY_DIR="${CURRENT_DIR}/git"
GLOBALRC="${CURRENT_DIR}/.globalrc"
TEMPFILE="${CURRENT_DIR}/tmpfile"
INDEXFILE_ORG="${CURRENT_DIR}/index_org.html"
INDEXFILE="${CURRENT_DIR}/git/index.html"
INDEXCSSFILE_ORG="${CURRENT_DIR}/index_style.css"
INDEXCSSFILE="${CURRENT_DIR}/git/index_style.css"
CSSFILE="${CURRENT_DIR}/style.css"

GLOBAL_BIN_ORG="/usr/local/Cellar/global/6.6.3/bin/global"
GLOBAL_BIN_REPLACE="/usr/bin/global"

if [ ! -e ${REPOSITORY_LIST} ]
then
    echo ${REPOSITORY_LIST}" is not found."
    exit 1
fi

if [ -e ${GLOBALRC} ]
then
    GTAGS_ADDITIONAL_OPTION="--gtagsconf ${GLOBALRC}"
else
    echo ${GLOBALRC} " is not found."
    GTAGS_ADDITIONAL_OPTION=""
fi


echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />' > ${TEMPFILE}

link_replace_str=""

for i in `cat ${REPOSITORY_LIST}`
do
    echo "================================"
    repo_name=`echo $i |awk -F '/' '{print $2}'|sed -e 's/.git//g'`
    link_replace_str=${link_replace_str}'<li><a href="./'${repo_name}'_gtags/HTML">'${repo_name}'</a></li>'
    if [ ! -d ${GIT_REPOSITORY_DIR}/${repo_name}_gtags ]
    then
        mkdir -p ${GIT_REPOSITORY_DIR}/${repo_name}_gtags
    fi

    cd ${GIT_REPOSITORY_DIR}/${repo_name}_gtags

    echo ${repo_name}

    if [ ! -d ${repo_name} ]
    then
	echo "Cloning " ${repo_name} "..."
        git clone ${i}
    fi

    # Master へのチェックアウトと最新化
    cd ${repo_name}
    echo "Checkout master branch..."
    git checkout master
    echo "Git pull..."
    git pull -f

    cd ../


    echo "Run GTAGS..."
    # GTAGS の実行
    gtags ${GTAGS_ADDITIONAL_OPTION}

    echo "Run HTAGS..."
    # HTAGS の実行
    htags -asnFof  --auto-completion --item-order csfd --html-header ${TEMPFILE} ${GTAGS_ADDITIONAL_OPTION}



    cd ${GIT_REPOSITORY_DIR}/

    # Global 実行ファイルのリプレイス
    sed -i "" -e "s#${GLOBAL_BIN_ORG}#${GLOBAL_BIN_REPLACE}#g"  ${GIT_REPOSITORY_DIR}/${repo_name}_gtags/HTML/cgi-bin/global.cgi
    sed -i "" -e "s#${GLOBAL_BIN_ORG}#${GLOBAL_BIN_REPLACE}#g" ${GIT_REPOSITORY_DIR}/${repo_name}_gtags/HTML/cgi-bin/completion.cgi

    cp ${CSSFILE}  ${GIT_REPOSITORY_DIR}/${repo_name}_gtags/HTML/
done

cp ${INDEXFILE_ORG} ${INDEXFILE}
cp ${INDEXCSSFILE_ORG} ${INDEXCSSFILE}
sed -i "" -e "s#__REPLACE_CONTENTS__#${link_replace_str}#g" ${INDEXFILE}

rm ${TEMPFILE}
