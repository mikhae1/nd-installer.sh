#!/usr/bin/env bash

ROOT_DIR="/tmp/flow"
ND_FRAMEWORK="git+ssh://git@github.com/noodoo/noodoo.git"
ND_ORGS=( "org-deals" "org-documents" "org-models" )
ND_ORGS_BRANCH="master"
ND_SHARED=( "flow" "nd-db" )


main() {
  PRINT 'installing noodoo framework...'
  [ ! -d $ROOT_DIR ] && mkdir -p $ROOT_DIR
  cd $ROOT_DIR
  ([ ! -d $ROOT_DIR/app ] || [ ! -n "$(ls -A $ROOT_DIR/app)" ]) && git clone $ND_FRAMEWORK $ROOT_DIR/app && cd './app' && npm install

  PRINT 'installing organizers...'
  [ ! -d $ROOT_DIR/app/organizers ] && PRINT "can't find organizers folder" 1 && exit -1
  cd $ROOT_DIR/app/organizers
  for module in "${ND_ORGS[@]}"; do
    ARR_SPLIT=(${module//-/ })
    ORG_NAME=${ARR_SPLIT[1]}
    [ ! -n $ORG_NAME ] && ORG_NAME=$module
    [ ! -d $ORG_NAME ] && git clone "git+ssh://git@github.com/noodoo/$module.git" "$ORG_NAME" &&
      cd $ORG_NAME && git checkout $ND_ORGS_BRANCH && npm install && cd ..
  done

  PRINT 'installing shared modules...'
  [ ! -d $ROOT_DIR/shared ] && mkdir $ROOT_DIR/shared
  cd $ROOT_DIR/shared
  for module in "${ND_SHARED[@]}"; do
    [ ! -d $module ] && git clone "git+ssh://git@github.com/noodoo/$module.git" &&
      cd $module && npm link && cd ..
  done

  PRINT 'linking shared modules in noodoo...'
  NPM_LINKER $ROOT_DIR/app

  PRINT 'linking shared modules in organizers...'
  cd $ROOT_DIR/app/organizers
  for f in $(ls -d */); do
    NPM_LINKER $ROOT_DIR/app/organizers/$f && cd ..
  done;

  PRINT 'done!'
}


function PRINT {
  DEF='\033[0;39m'       #  ${DEF}
  DGRAY='\033[1;30m'     #  ${DGRAY}
  LRED='\033[1;31m'      #  ${LRED}
  LCYAN='\033[1;36m'     #  ${LCYAN}
  LGREEN='\033[1;32m'    #  ${LGREEN}
  LYELLOW='\033[1;33m'   #  ${LYELLOW}
  LBLUE='\033[1;34m'     #  ${LBLUE}
  LMAGENTA='\033[1;35m'  #  ${LMAGENTA}
  if [ -z "$2" ]; then
    echo -e "$LCYAN> $1$DEF"
  else
    echo -e "$LRED ERROR: $1$DEF"
  fi
}


function NPM_LINKER {
  cd $1/node_modules
  for dir in $(ls -d *); do
    for module in "${ND_SHARED[@]}"; do
      if [[ $dir == $module ]]; then
        npm link $module
      fi
    done
  done;
}


if [[ $1 == '-h' || $1 == '--help' ]]; then
  echo -e "Usage: $0 [--clean]"
  echo -e "\t--clean \tRemove destination folder first"
  exit
elif [[ $1 == "clean" || $1 == "--clean" ]]; then
  rm -rfv $ROOT_DIR
fi

main "$@"
