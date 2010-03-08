AC_INIT(freetds, 0.3, christophe.troestler@umons.ac.be)

AC_MSG_RESULT([configuring $PACKAGE_STRING])

# OCaml
########################################################################

AC_PROG_OCAML
if test "$OCAMLC" = "no"; then
  AC_MSG_ERROR([You must install the OCaml compiler])
fi

AC_PROG_FINDLIB
if test "$OCAMLFIND" = "no"; then
  AC_MSG_ERROR([You must install OCaml findlib (the ocamlfind command)])
fi

AC_CHECK_OCAML_WORD_SIZE

DESTDIR=`$OCAMLFIND printconf destdir | sed -e 's|\\\\|/|g'`
AC_SUBST(DESTDIR)

AC_CHECK_LIB(sybdb, dbopen)
AC_CHECK_LIB(ct, ct_init)

# substitutions to perform
AC_SUBST(PACKAGE_NAME)
AC_SUBST(PACKAGE_VERSION)
AC_SUBST(CPPFLAGS)
AC_SUBST(LIBS)

# Finally create the Makefile and samples (read only to avoid changing
# them by mistake)
AC_CONFIG_FILES([Makefile.ocaml],[chmod a-w Makefile.ocaml])
AC_CONFIG_FILES([src/META])
AC_CONFIG_FILES([Makefile], [chmod a-w Makefile])
AC_CONFIG_FILES([src/Makefile], [chmod a-w src/Makefile])
AC_OUTPUT
