bxserver=frontrow@appletv.local
bxvolume="MyVolume"
bxpath="~"
bxpassword=""

bxstagedir="Stage"
bxtvdir="TV"
bxshowdir="\${show}/Season \${season}"
bxshowfile="\${show} - \${season}x\${episode} - \${title}"

bxroot="/Volumes/\${bxvolume}"
bxstage="\${bxroot}/\${bxstagedir}"
bxtv="\${bxroot}/\${bxtvdir}"
bxshow="\${bxtv}/\${bxshowdir}/"
bxshowpath="\${bxshow}/\${bxshowfile}"

function camelcase() {
  local word
  local result

  for i in $*
  do
    word=`echo "${i:0:1}" | tr a-z A-Z`${i:1}
    
    if [ -n "$result" ]
    then 
      result="$result "
    fi

    result=${result}${word}
  done

  echo $result
}

# recursive evaluation
function evalr() {

  if [[ "$*" =~ "\$" ]]
  then
    local result=$(eval echo "$*")

    if [ "$result" == "$*" ]
    then
      echo "$*"
      return 0
    else
      evalr "$result"
    fi
  else
    echo "$*"
    return 0
  fi
}

function bxconnect() {
  local cmd=$1
  local destination=$2
  shift
  shift

  if [ "$bxpassword" == "" ]
  then
    stty -echo
    read -p "Please enter your password: " bxpassword
    echo
    stty echo
    if [ "$bxpassword" == "" ]
    then
      return 0
    fi
  fi

  expect $bxpath/password.expect "$cmd" "$bxpassword" "$destination" $@

  local error=$?

  # invalid password
  if [ "$error" == "1" ]
  then
    bxpassword=""
  fi
}

function bxssh() {
  bxconnect ssh $bxserver $@
}

function bxstage() {
  local destination=$(evalr $bxstage)
  echo
  echo "$1   =>   $destination"
  echo
  bxconnect scp $bxserver:$destination "$1"
}

function bxtvshow()
{
  export original=
  export ext=
  export name=
  export show=
  export season=
  export episode=
  export title=

  if [ ! -f "$1" ]
  then
    echo "File not found '$1'"
    return 2
  fi

  original=$(basename "$1")
  ext=${original##*.}
  name=${original%.*}

  # remove symbols
  name=$(echo "$name" | sed -e "s/[.,_-]/ /g" -e "s/\\[/ /g" -e "s/\\]/ /g")

  # turn off case sensitivity
  shopt -q nocasematch
  local case=$?
  shopt -s nocasematch

  # find season and episode
  [[ "$name" =~ (.*)s([0-9]{2})e([0-9]{2})(.*) ]] ||
  [[ "$name" =~ (.*)([0-9]{2})x([0-9]{2})(.*) ]] ||
  {
    return 3
  }

  # turn case sensitivity back on
  if [ $case == 1 ]
  then
    shopt -u nocasematch
  fi  

  show=${BASH_REMATCH[1]}
  season=${BASH_REMATCH[2]}
  episode=${BASH_REMATCH[3]}
  title=${BASH_REMATCH[4]}

  # strip everything after HDTV from title
  title=${title%[Hh][Dd][Tt][Vv]*}

  # remove trailing spaces
  show=$(echo $show | sed s/\ *$//)
  title=$(echo $title | sed s/\ *$//)
}

function bx()
{
  local original
  local ext
  local name
  local show
  local season
  local episode
  local title
  local auto

  if [ "$1" == "-auto" ]
  then
    auto=true
    shift
  fi

  if [ -z "$1" ]
  then
    bxssh
    return 0
  fi

  bxtvshow "$1"
  local error=$?

  local answer
  if [ "$error" == "3" ]
  then
    echo
    echo Unable to determine season and episode
    if [ $auto ]
    then
      return 3
    fi

    read -p "Do you wish to stage this file [yn]? " answer
    if [ "$answer" == "y" ]
    then
      bxstage "$1"
      return
    else
      return 3
    fi
  fi

  if [ "$error" != "0" ]
  then
    return $error
  fi

  if [ -z "$auto" ]
  then
    if [ -z "$title" ]
    then
      echo
      read -p "Enter a title (optional): " title
    else
      echo
      read -p "Change title? \"${title}\" (y/n): " answer
      if [ "$answer" == "y" ]
      then
        read -p "Enter a new title: " title
      fi
    fi
  fi

  # capitalise the first letter of each word
  show=$(camelcase $show)
  title=$(camelcase $title)

  local destination="$(evalr $bxshowpath)"

  # remove trailing spaces/symbols
  destination=$(echo $destination | sed s/[-\ .,_]*$//)

  destination=$destination.$ext
  echo
  echo "Copying \"$original\"  =>  \"$destination\""

  # escape spaces
  destination=$(echo $destination | sed s/\ /\\\\\ /g)

  echo
  bxconnect scp $bxserver:"$destination" "$1"

  return 0

}

function bxmd()
{
  local original
  local ext
  local name
  local show
  local season
  local episode
  local title

  bxtvshow "$1"
  local error=$?

  if [ "$error" == "3" ]
  then
    echo
    echo Unable to determine season and episode
    return 3
  fi

  if [ "$error" != "0" ]
  then
    return $error
  fi

  local destination="$(evalr $bxshow)"

  echo
  echo Creating directory \"$destination\" on $bxserver
  echo

  ssh $bxserver mkdir -pv \"$destination\" | tr '\n' '\0' | xargs -0 -n 1 echo creating

  bx "$1"
}

function bxls()
{
  local original
  local ext
  local name
  local show
  local season
  local episode
  local title

  bxtvshow "$1"
  local error=$?

  if [ "$error" == "3" ]
  then
    echo
    echo Unable to determine season and episode
    return 3
  fi

  if [ "$error" != "0" ]
  then
    return $error
  fi

  local destination="$(evalr $bxshow)"

  echo
  echo Looking in	 \"$destination\" on $bxserver
  echo

  ssh $bxserver ls -al \"$destination\"

  echo
  local answer
  read -p "Copy file [yn]? " answer
  if [ "$answer" == "y" ]
  then
    bx "$1"
  fi
}

