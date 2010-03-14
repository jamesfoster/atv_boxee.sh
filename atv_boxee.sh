bxserver=frontrow@appletv.local

bxstagedir="Stage"
bxtvdir="TV"
bxshowdir="\${show}/Season \${season}"
bxshowfile="\${show} - \${season}x\${episode} - \${title}"

bxroot="/Volumes/\${bxvolume}"
bxstage="\${bxroot}/\${bxstagedir}"
bxtv="\${bxroot}/\${bxtvdir}"
bxshowpath="\${bxtv}/\${bxshowdir}/\${bxshowfile}"

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

function bxssh() {
  ssh $bxserver $@
}

function bxstage() {
  echo
  scp "$1" $bxserver:$bxstage
}

function bx()
{
  if [ -z "$1" ]
  then
    bxssh
    return 0
  fi

  if [ ! -f "$1" ]
  then
    echo "File not found '$1'"
    return 2
  fi

  local original=$(basename "$1")
  local ext=${original##*.}
  local name=${original%.*}

  # remove symbols
  name=$(echo "$name" | sed "s/[.,_-]/ /g")

  # turn off case sensitivity
  shopt -q nocasematch
  local case=$?
  shopt -s nocasematch

  # find season and episode
  [[ "$name" =~ (.*)s([0-9]{2})e([0-9]{2})(.*) ]] ||
  [[ "$name" =~ (.*)([0-9]{2})x([0-9]{2})(.*) ]] ||
  {
    echo
    echo Unable to determine season and episode
    read -p "Do you wish to stage this file [yn]? " answer
    if [ "$answer" == "y" ]
    then
      bxstage "$1"
      return
    else
      return 3
    fi
  }

  local show=${BASH_REMATCH[1]}
  local season=${BASH_REMATCH[2]}
  local episode=${BASH_REMATCH[3]}
  local title=${BASH_REMATCH[4]}

  # strip everything after HDTV from title
  title=${title%[Hh][Dd][Tt][Vv]*}

  # remove trailing spaces
  show=$(echo $show | sed s/\ *$//)
  title=$(echo $title | sed s/\ *$//)

  if [ -z "$title" ]
  then
    echo
    read -p "Enter a title (optional): " title
  fi

  # capitalise the first letter of each word
  show=$(camelcase $show)
  title=$(camelcase $title)

  local destination="$(evalr $bxshowpath)"

  # remove trailing spaces/symbols
  destination=$(echo $destination | sed s/[-\ .,_]*$//)

  destination=$destination.$ext
  echo
  echo "$original   =>   $destination"

  # escape spaces
  destination=$(echo $destination | sed s/\ /\\\\\ /g)

  echo
  scp "$1" $bxserver:"$destination"

  # turn case sensitivity back on
  if [ $case == 1 ]
  then
    shopt -u nocasematch
  fi

  return 0

}
