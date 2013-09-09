#!/bin/bash

function usage
{
    echo "$0 -e environment_name [-u svn_username] [-p svn_password] [-q]"
    exit 1
}

DEBUG=false
QUITE=false

while getopts "du:p:e:q" opt; do
    case $opt in
        d)
            DEBUG=true
            ;;
        u)
            USERNAME=$OPTARG
            ;;
        p)
            PASSWORD=$OPTARG
            ;;
        e)
            ENVIRONMENT=$OPTARG
            ;;
        q)
            QUIET=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done


#
# Test for binaries
#
for bin in "find" "wget" "sed" "rm" "cp"
do
    which $bin 1> /dev/null 2>&1
    ERROR=$?
    if [ $ERROR -eq 1 ]; then
      echo "$0 FATAL!  Unable to locate $bin in the path"
      exit 1
    fi
    if [ $ERROR -eq 127 ]; then
      echo "$0 FATAL!  Unable to locate which in the path"
      exit 1
    fi
done


if [ -z "$ENVIRONMENT" ]; then
  echo "$0 environment not defined with -e environment"
  usage
  exit 1
fi

echo "# ENVIRONMENT=$ENVIRONMENT"

if [ -n "$USERNAME" ]; then
  user_param="--http-user=$USERNAME"
fi

if [ -n "$PASSWORD" ]; then
  passwd_param="--http-passwd=$PASSWORD"
fi

files=`find . -name *.blaster`

for file in $files
do
    echo "# Found template file: $file"

    template=`echo $file | sed "s/blaster$/$ENVIRONMENT.url/"`
    new_file=`echo $file | sed 's/\.blaster$//'`

    echo "# Will create: $new_file"

    if [ ! -e $template ]; then
        echo "# WARNING! Environment template does not exist for enviornment $ENVIRONMENT ($template)"

        template_source=`echo $file | sed "s/blaster$/$ENVIRONMENT/"`

        if [ ! -e $template_source.data ]; then
            echo "# FATAL! $template_source.data does not exist"
            exit 1
        fi

        template=$template_source
    else
        template_source=`head -1 $template`

        echo "# Source for template: $template_source"

        wget -q --no-check-certificate -O ${template}.data $user_param $passwd_param $template_source
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
          echo "# $0 FATAL!  wget failed.  Password problem?"
          exit 1
        fi

        via_wget="yup"

    fi

    echo "# Creating $new_file from $file + ${template}.data..."
    sed -f ${template}.data $file > $new_file

    echo
    echo "#"
    echo "# Rendered $new_file:"
    echo "#"
    if [ ! $QUIET ]; then
        cat $new_file
    fi
    echo

    # Cleanup downloaded file
    if [ "$via_wget" == "yup" ]; then
        rm ${template}.data
    fi
done

