dnl Most functions are initially stolen from gnus.  Thanks for all the fish!

dnl
dnl Execute Lisp code
dnl
AC_DEFUN(AC_EMACS_LISP, [
  elisp="$2"
  if test -z "$3"; then
     AC_MSG_CHECKING(for $1)
  fi

  if test `echo "${EMACS}" | grep xemacs`; then
    EM="${EMACS} -vanilla -batch -eval"
  else
    EM="${EMACS} --no-site-file -batch -eval"
  fi

  AC_CACHE_VAL(EMACS_cv_SYS_$1,[
    OUTPUT=./conftest-$$
    echo ${EM} "(let ((x ${elisp})) (write-region (if (stringp x) (princ x) (prin1-to-string x)) nil \"${OUTPUT}\"))" >& AC_FD_CC 2>&1
    ${EM} "(let ((x ${elisp})) (write-region (if (stringp x) (princ x 'ignore) (prin1-to-string x)) nil \"${OUTPUT}\"nil 5))" >& AC_FD_CC 2>&1
    if test ! -e "${OUTPUT}"; then
      AC_MSG_RESULT()
      AC_MSG_ERROR([calling ${EMACS}])
    fi
    retval=`cat ${OUTPUT}`
    echo "=> ${retval}" >& AC_FD_CC 2>&1
    rm -f ${OUTPUT}
    EMACS_cv_SYS_$1=$retval
  ])
  $1=${EMACS_cv_SYS_$1}
  if test -z "$3"; then
     AC_MSG_RESULT($$1)
  fi
])

dnl
dnl Checks the Emacs flavor in use.  Result for `EMACS' is the program to run.
dnl `EMACS_INFO' is the target the info file is generated for; will be either
dnl `emacs', or `xemacs'.
dnl
AC_DEFUN(AC_EMACS_INFO, [

  dnl Apparently, if you run a shell window in Emacs, it sets the EMACS
  dnl environment variable to 't'.  Lets undo the damage.
  if test "x${EMACS}" = "x" -o "x${EMACS}" = "xt"; then
     EMACS=emacs
  fi

  dnl Check parameter.
  AC_ARG_WITH(
    xemacs,
    [[  --with-xemacs[=PROG]    use XEmacs to build [PROG=xemacs]]],
    [ if test "${withval}" = "yes"; then EMACS=xemacs; else EMACS=${withval}; fi ])
  AC_ARG_WITH(
    emacs,
    [[  --with-emacs[=PROG]     use Emacs to build [PROG=emacs]]],
    [ if test "${withval}" = "yes"; then EMACS=emacs; else EMACS=${withval}; fi ])

  dnl Check program availability.
  if test -z $EMACS; then
    AC_CHECK_PROGS([EMACS], [emacs xemacs], [no])
    if test "${EMACS}" = no; then
      AC_MSG_ERROR([emacs not found])
    fi
  else
    AC_CHECK_PROG([EMACS_test_emacs], [$EMACS], [yes], [no], [$PATH:/])
    if test "${EMACS_test_emacs}" = no; then
      AC_MSG_ERROR([$EMACS not found])
    fi
  fi

  dnl Check flavor.
  AC_MSG_CHECKING([for $EMACS flavor])
  AC_EMACS_LISP(
    xemacsp,
    (if (featurep 'xemacs) \"yes\" \"no\"),
    "noecho")
  if test "${EMACS_cv_SYS_xemacsp}" = "yes"; then
     EMACS_INFO=xemacs
  else
     EMACS_INFO=emacs
  fi
  AC_MSG_RESULT($EMACS_INFO)
  AC_SUBST(EMACS_INFO)
])

dnl
dnl Checks whether a package provided via the contrib directory should
dnl be made available via a link. First parameter is a provided function
dnl from the package in question, which is the second parameter.
dnl If the first parameter is empty, just the package is looked for.
dnl If the third parmeter is not zero, the package is optional.
dnl Function and package names must encode "-" with "_".
dnl
AC_DEFUN(AC_CONTRIB_FILES, [

  function=`echo $1 | tr _ -`
  library=`echo $2 | tr _ -`
  AC_MSG_CHECKING([for $library])

  dnl Old links must be removed anyway.
  if test -h lisp/$library; then rm -f lisp/$library; fi

  dnl Check whether contrib packages could be used.
  AC_ARG_WITH(
    contrib,
    [  --with-contrib          use contributed packages],
    [ if test "${withval}" = "yes"; then USE_CONTRIB=yes; fi ])

  dnl Check whether Lisp function does exist.
  if test -z "$1"; then
    EMACS_cv_SYS_$1="nil"
  else
    AC_EMACS_LISP($1, (progn (load \"$library\" t) (fboundp '$function)), "noecho")
  fi

  dnl Create the link.
  if test "${EMACS_cv_SYS_$1}" = "nil"; then
    if test "${USE_CONTRIB}" = "yes"; then
      if test -e contrib/$library; then
        TRAMP_CONTRIB_FILES="$library $TRAMP_CONTRIB_FILES"
        ln -s ../contrib/$library lisp/$library
dnl	AC_CONFIG_LINKS(lisp/$library:contrib/$library)
        AC_MSG_RESULT(linked to contrib directory)
      elif test -z "$3"; then
        AC_MSG_RESULT(not found)
        AC_MSG_ERROR(Could not find package $library in contrib directory)
      else
        AC_MSG_RESULT(not found)
      fi
    elif test -z "$3"; then
      AC_MSG_RESULT(not found)
      AC_MSG_ERROR(Use --with-contrib for implementation supplied with Tramp)
    else
      AC_MSG_RESULT(skipped)
    fi
  else
    AC_MSG_RESULT(ok)
  fi
])

dnl
dnl Checks whether Tramp is prepared for (X)Emacs package.  This case,
dnl the installation chapter is not part of the manual.  Necessary for
dnl maintainers only.
dnl
AC_DEFUN(AC_EMACS_INSTALL, [

  INSTALL_CHAPTER=yes

  dnl Check parameter.
  AC_MSG_CHECKING([for installation chapter])
  AC_ARG_WITH(
    packaging,
    [  --with-packaging        installation chapter not needed in manual],
    [ if test "${withval}" = "yes"; then INSTALL_CHAPTER=no; fi ])

  AC_MSG_RESULT($INSTALL_CHAPTER)
  AC_SUBST(INSTALL_CHAPTER)
])

dnl
dnl Enables japanese manual.  Per default, it is disabled.
dnl
AC_DEFUN(AC_JA_MANUAL, [

  JA_MANUAL=no

  dnl Check parameter.
  AC_MSG_CHECKING([for japanese manual])
  AC_ARG_WITH(
    japanese-manual,
    [  --with-japanese-manual  create japanese manual],
    [ if test "${withval}" = "yes"; then JA_MANUAL=yes; fi ])

  AC_MSG_RESULT($JA_MANUAL)
  AC_SUBST(JA_MANUAL)
])

dnl
dnl Return install target for Lisp files.
dnl
AC_DEFUN(AC_PATH_LISPDIR, [

  dnl Check prefix.
  AC_MSG_CHECKING([prefix ])

  prefix_default=$ac_default_prefix
  if test "${prefix}" = NONE; then
     prefix=$prefix_default
  fi

  AC_MSG_RESULT([$prefix])

  dnl Check datadir.
  AC_MSG_CHECKING([datadir])

  if test "$EMACS_INFO" = "xemacs"; then
     datadir_default="\${prefix}/lib"
  else
     datadir_default="\${prefix}/share"
  fi

  if test "${datadir}" = "\${prefix}/share"; then
     datadir=$datadir_default
  fi

  dnl Expand $datarootdir.
  datadir=$(echo ${datadir} | sed -e "s#[$][{]datarootdir[}]#$datarootdir#")

  AC_MSG_RESULT([$datadir])

  dnl Check lispdir.
  AC_ARG_WITH(
    lispdir,
    [[  --with-lispdir=DIR      where to install lisp files
                          [DATADIR/emacs/site-lisp] or
                          [DATADIR/xemacs/site-lisp]]],
    lispdir=${withval})
  dnl Alternative approach.
dnl  m4_divert_once(HELP_BEGIN, [], [])
dnl  m4_divert_once(HELP_BEGIN,
dnl    AC_HELP_STRING(
dnl      [  lispdir=DIR],
dnl      [where to install lisp files
dnl       [[DATADIR/emacs/site-lisp]] or
dnl       [[DATADIR/xemacs/site-lisp]]]))
  AC_MSG_CHECKING([lispdir])

  lispdir_default="\${datadir}/${EMACS_INFO}/site-lisp"

  : ${lispdir:=$lispdir_default}

  dnl Expand $lispdir_default for trampinst.texi.  We need to apply it
  dnl several times, because $prefix, $datarootdir and $datadir need
  dnl to be expanded in an unknown order.
  lispdir_default=$(eval eval eval echo ${lispdir_default})

  AC_MSG_RESULT($lispdir)
])

dnl
dnl This is a bit on the "evil hack" side of things.  It is so we can
dnl have a different default infodir for XEmacs.  A user can still specify
dnl someplace else with '--infodir=DIR'.
dnl
AC_DEFUN(AC_PATH_INFODIR, [

  dnl Check infodir.
  AC_MSG_CHECKING([infodir])

  dnl Check default places.
  if test "$EMACS_INFO" = "xemacs"; then
     infodir_default="\${datadir}/xemacs/info"
  else
     infodir_default="\${datadir}/info"
  fi

  dnl If default directory doesn't exist, derive from $prefix.
  dnl ${prefix} and ${datadir} must be expanded for test.
  if ! test -d $(eval eval eval echo ${infodir_default})
  then
     infodir_default="\${prefix}/info"
  fi

  dnl If default directory doesn't exist, derive from $prefix_default.
  dnl ${prefix} and ${datadir} must be expanded for test.
  if ! test -d $(eval eval eval echo ${infodir_default})
  then
     infodir_default="\${prefix_default}/info"
  fi

  dnl Set it if necessary.
  if test "${infodir}" = "\${prefix}/info"; then
     infodir=$infodir_default
  fi

  dnl Expand $datarootdir.
  infodir=$(echo ${infodir} | sed -e "s#[$][{]datarootdir[}]#$datarootdir#")

  dnl Expand $infodir_default for trampinst.texi.  We need to apply it
  dnl several times, because $prefix, $datarootdir and $datadir need
  dnl to be expanded in an unknown order.
  infodir_default=$(eval eval eval echo ${infodir_default})

  AC_MSG_RESULT([$infodir])
])

dnl
dnl Check whether a function exists in a library.
dnl All '_' characters in the first argument are converted to '-'.
dnl
AC_DEFUN(AC_EMACS_CHECK_LIB, [
  if test -z "$3"; then
     AC_MSG_CHECKING(for $2 in $1)
  fi
  library=`echo $1 | tr _ -`
  AC_EMACS_LISP(
    $1,
    (progn
      (fmakunbound '$2)
      (condition-case nil
          (progn (require '$library) (fboundp '$2))
        (error (prog1 nil (message \"$library not found\"))))),
    "noecho")
  if test "${EMACS_cv_SYS_$1}" = "nil"; then
     EMACS_cv_SYS_$1=no
  fi
  if test "${EMACS_cv_SYS_$1}" = "t"; then
     EMACS_cv_SYS_$1=yes
  fi
  HAVE_$1=${EMACS_cv_SYS_$1}
  AC_SUBST(HAVE_$1)
  if test -z "$3"; then
     AC_MSG_RESULT($HAVE_$1)
  fi
])