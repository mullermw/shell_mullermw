#/bin/bash

# Copy the files tracked by this project from the current user's home directory to the project directory.

if [ ! -d "$SHELL_MULLERMW_HOME" ]; then
    echo '$SHELL_MULLERMW_HOME must be set to a valid directory'
    exit 1;
fi 

#protype home directory
HOME_PROTO=$SHELL_MULLERMW_HOME/home

cp ~/.profile $HOME_PROTO
cp ~/.bashrc $HOME_PROTO

exit 0;


