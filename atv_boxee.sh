bxserver=frontrow@appletv.local
bxstage=/Volumes/Newcastle/Stage/
bxtv=/Volumes/Newcastle/TV/

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

function bxssh() {
  ssh $bxserver $@
}

function bxstage() {
  scp "$1" $bxserver:$bxstage
}

function bx()
{
  if [ -z "$1" ]
  then
    bxssh
    return 0
  fi

  if [ ! -f $1 ]
  then
    echo "File not found '$1'"
    return 2
  fi

  local original=$(basename "$1")
  local ext=${original##*.}
  local name=${original%.*}

  # remove symbols
  name=`echo "$name" | sed "s/[.,_-]/ /g"`

  # turn off case sensitivity
  shopt -q nocasematch
  local case=$?
  shopt -s nocasematch

  # find season and episode
  [[ "$name" =~ (.*)s([0-9]{2})e([0-9]{2})(.*) ]] ||
  [[ "$name" =~ (.*)([0-9]{2})x([0-9]{2})(.*) ]] ||
  { echo Unable to determine season and episode; return 3; }

  local show=${BASH_REMATCH[1]}
  local season=${BASH_REMATCH[2]}
  local episode=${BASH_REMATCH[3]}
  local title=${BASH_REMATCH[4]}

  # strip everything after HDTV from title
  title=${title%hdtv*}

  # remove trailing spaces
  show=`echo $show | sed s/\ *$//`
  title=`echo $title | sed s/\ *$//`

  # capitalise the first letter of each word
  show=$(camelcase $show)
  title=$(camelcase $title)

  local newName="${show} - ${season}x${episode}"

  if [ -n "$title" ]
  then
    newName="$newName - $title"
  fi

  local destination="${bxtv}${show}/Season ${season}/${newName}.${ext}"
  echo "$original   =>   $destination"

  # escape spaces (why so many \'s ?)
  destination=`echo $destination | sed s/\ /\\\\\\\\\ /g`

  scp "$1" $bxserver:"$destination"

  # turn case sensitivity back on
  if [ $case == 1 ]
  then
    shopt -u nocasematch
  fi

  return 0

}
