/* File: dblib_stubs.c

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3 or
   later as published by the Free Software Foundation.  See the file
   LICENCE for more details.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. */

/* Binding to the DB-Library part of freetds.
   See http://www.freetds.org/userguide/samplecode.htm */

#include <sybfront.h> /* sqlfront.h always comes first */
#include <sybdb.h>

#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/custom.h>
/* libsybdb.a or libsybdb.so  */


value ocaml_dbinit(value unit)
{
  CAMLparam0();
  if (dbinit() == FAIL) {
    failwith("FreeTDS.Dblib: cannot initialize DB-lib!");
  }
  CAMLreturn(Val_unit);
}

/* dberrhandle(err_handler); */
/* dbmsghandle(msg_handler); */


#define DBPROCESS_VAL(v) (* (DBPROCESS **) Data_custom_val(v))
#define DBPROCESS_ALLOC()                                       \
  alloc_custom(&dbprocess_ops, sizeof(DBPROCESS *), 1, 30)

static int dbprocess_compare(value v1, value v2)
{
  /* Compare pointers */
  if (DBPROCESS_VAL(v1) < DBPROCESS_VAL(v2)) return(-1);
  else if (DBPROCESS_VAL(v1) > DBPROCESS_VAL(v2)) return(1);
  else return(0);
}

static long dbprocess_hash(value v)
{
  /* The pointer will do a good hash and respect compare v1 v2 = 0 ==>
     hash(v1) = hash(v2) */
  return(DBPROCESS_VAL(v));
}

static struct custom_operations dbprocess_ops = {
  "freetds/dbprocess", /* identifier for serialization and deserialization */
  custom_finalize_default, /* one must call dbclose */
  &dbprocess_compare,
  &dbprocess_hash,
  custom_serialize_default,
  custom_deserialize_default
};


value ocaml_freetds_dbopen(value vuser, value vpasswd, value vserver)
{
  CAMLparam3(vuser, vpasswd, vserver);
  CAMLlocal1(vdbproc);
  LOGINREC *login;
  DBPROCESS *dbproc;

  if ((login = dblogin()) == NULL) {
    failwith("FreeTDS.Dblib.dbopen: cannot allocate the login structure");
  }
  DBSETLUSER(login, String_val(vuser));
  DBSETLPWD(login, String_val(vpasswd));
  if ((dbproc = dbopen(login, String_val(vserver))) == NULL) {
    /* free login ? */
    failwith("FreeTDS.Dblib.dbopen: unable to connect to the database");
  }
  vdbproc = DBPROCESS_ALLOC();
  DBPROCESS_VAL(vdbproc) = dbproc;
  CAMLreturn(vdbproc);
}

value ocaml_freetds_dbclose(value vdbproc)
{
  CAMLparam1(vdbproc);
  dbclose(DBPROCESS_VAL(vdbproc));
  CAMLreturn(Val_unit);
}

value ocaml_freetds_dbuse(value vdbproc, value vdbname)
{
  CAMLparam2(vdbproc, vdbname);
  if (dbuse(DBPROCESS_VAL(vdbproc), String_val(vdbname)) == FAIL) {
    failwith("FreeTDS.Dblib.dbuse: unable to use the given database");
  }
  CAMLreturn(Val_unit);
}

value ocaml_freetds_dbsqlexec(value vdbproc, value vsql)
{
  CAMLparam2(vdbproc, vsql);
  
  if (dbcmd(DBPROCESS_VAL(vdbproc), String_val(vsql)) == FAIL) {
    failwith("FreeTDS.Dblib.dbsqlexec: cannot allocate memory to hold "
             "the SQL query");
  }
  /* Sending the query to the server resets the command buffer. */
  if (dbsqlexec(dbproc) == FAIL) {
    failwith("FreeTDS.Dblib.dbsqlexec: the SQL query is invalid (most likely) "
             "or there is a connection problem");
  }
  CAMLreturn(Val_unit);
}
