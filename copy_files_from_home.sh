#/bin/bash

# Copy the files tracked by this project from the current user's home directory to the project directory.

# SET $SOURCE to the PATH TO THIS SCRIPT FILE
# SET $DIR to the PATH TO THE PARENT DIRECTORY OF $SOURCE
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

#protype home directory in this project
HOME_PROTO=$DIR/home

cp ~/.profile $HOME_PROTO
cp ~/.bashrc $HOME_PROTO

exit 0;
