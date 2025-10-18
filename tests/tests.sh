#!/bin/sh

#WITH_PERL_COVERAGE=1; export WITH_PERL_COVERAGE

sh_main()
{
  sh_init "$@"

  retval=0

  cd "$apppath/../"

  if [ "$WITH_PERL_COVERAGE" != '' ]; then
    if [ "$WITH_PERL_COVERAGE_OWNER" = '' ]; then
      WITH_PERL_COVERAGE_OWNER=$$; export WITH_PERL_COVERAGE_OWNER

      which cover 1>/dev/null 2>&1
      bUnavailableCover=$?;
      if [ $bUnavailableCover -ne 0 ]; then
        echo "$0: warn: \"cover\" command not found: \$WITH_PERL_COVERAGE: ignore" 1>&2
        unset WITH_PERL_COVERAGE
        unset WITH_PERL_COVERAGE_OWNER
      else
        cover -delete
      fi
    fi
  fi

  for fi in *; do
    if ! is_it_executable_file "$fi"; then
      continue
    fi
    bname="`basename \"$fi\"`"
    tname="tests/$bname.test.pl"
    if ! is_it_executable_file "$tname"; then
      continue
    fi
    #echo "F: $bname"

    "$apppath/prt" -e "$bname: "

    test_log="$tname.log"
    "./$tname" >"$test_log"
    exit_status=$?
    res='PASS'
    if [ $exit_status -ne 0 ]; then
      res='FAIL'
      retval=`expr "$retval" '+' '1'`
    fi
    echo "$res: exit_status=$exit_status"
  done

  if [ "$WITH_PERL_COVERAGE" != '' ]; then
    if [ "$WITH_PERL_COVERAGE_OWNER" = "$$" ]; then
      cover
    fi
  fi

  return $retval
}

## script setup
sh_init()
{
    di_work="`pwd`"
    appname="`basename \"$0\"`"
    di_tmp="`dirname  \"$0\"`"
    cd "$di_tmp/"; apppath="`pwd`"; cd "$di_work/"
    unset di_tmp
    version=`grep '$[R]evision' "$apppath/$appname" | \
        sed 's/^.*$R/R/' | sed 's/ *\$$//'`
}

is_it_executable_file()
{
    #echo "Check: $1"
    if [ ! -f "$1" ]; then
      return 1
    fi
    if [ ! -r "$1" ]; then
      return 1
    fi
    if [ ! -x "$1" ]; then
      return 1
    fi
    return 0
}

sh_main "$@"
exit $?
