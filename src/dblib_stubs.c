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

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/custom.h>


value ocaml_freetds_dbinit(value unit)
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
  return((long) DBPROCESS_VAL(v));
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
  if (dbsqlexec(DBPROCESS_VAL(vdbproc)) == FAIL) {
    failwith("FreeTDS.Dblib.sqlexec: the SQL query is invalid, the results "
             "of the previous query were not completely read,...");
  }
  CAMLreturn(Val_unit);
}

value ocaml_freetds_dbresults(value vdbproc)
{
  CAMLparam1(vdbproc);
  RETCODE erc;
  if ((erc = dbresults(DBPROCESS_VAL(vdbproc))) == FAIL) {
    failwith("FreeTDS.Dblib.results: query was not processed successfully "
             "by the server");
  }
  CAMLreturn(Val_bool(erc == SUCCEED));
}

value ocaml_freetds_numcols(value vdbproc)
{
  /* noalloc */
  return(Val_int(dbnumcols(DBPROCESS_VAL(vdbproc))));
}

value ocaml_freetds_dbcolname(value vdbproc, value vc)
{
  CAMLparam2(vdbproc, vc);
  CAMLlocal1(vname);
  char *name;
  name = dbcolname(DBPROCESS_VAL(vdbproc), Int_val(vc));
  if (name == NULL)
    invalid_argument("FreeTDS.Dblib.colname: column number out of range");
  vname = caml_copy_string(name);
  /* free(name); */ /* Doing it says "invalid pointer". */
  CAMLreturn(vname);
}

value ocaml_freetds_dbcoltype(value vdbproc, value vc)
{
  CAMLparam2(vdbproc, vc);
  /* Keep in sync with "type col_type" on the Caml side. */
  switch (dbcoltype(DBPROCESS_VAL(vdbproc), Int_val(vc))) {
  case SYBCHAR:    CAMLreturn(Val_int(0));
  case SYBVARCHAR: CAMLreturn(Val_int(1));
  case SYBINTN: CAMLreturn(Val_int(2));
  case SYBINT1: CAMLreturn(Val_int(3));
  case SYBINT2: CAMLreturn(Val_int(4));
  case SYBINT4: CAMLreturn(Val_int(5));
  case SYBINT8: CAMLreturn(Val_int(6));
  case SYBFLT8: CAMLreturn(Val_int(7));
  case SYBFLTN: CAMLreturn(Val_int(8));
  case SYBNUMERIC: CAMLreturn(Val_int(9));
  case SYBDECIMAL: CAMLreturn(Val_int(10));
  case SYBDATETIME: CAMLreturn(Val_int(11));
  case SYBDATETIME4: CAMLreturn(Val_int(12));
  case SYBDATETIMN: CAMLreturn(Val_int(13));
  case SYBBIT: CAMLreturn(Val_int(14));
  case SYBTEXT: CAMLreturn(Val_int(15));
  case SYBIMAGE: CAMLreturn(Val_int(16));
  case SYBMONEY4: CAMLreturn(Val_int(17));
  case SYBMONEY: CAMLreturn(Val_int(18));
  case SYBMONEYN: CAMLreturn(Val_int(19));
  case SYBREAL: CAMLreturn(Val_int(20));
  case SYBBINARY: CAMLreturn(Val_int(21));
  case SYBVARBINARY: CAMLreturn(Val_int(22));
  }
  failwith("Freetds.Dblib.coltype: unknown column type");
}

value ocaml_freetds_dbcancel(value vdbproc)
{
  CAMLparam1(vdbproc);
  dbcancel(DBPROCESS_VAL(vdbproc));
  CAMLreturn(Val_unit);
}

value ocaml_freetds_dbcanquery(value vdbproc)
{
  CAMLparam1(vdbproc);
  dbcanquery(DBPROCESS_VAL(vdbproc));
  CAMLreturn(Val_unit);
}

typedef struct {
  DBPROCESS *conn; /* hold the connection to avoid mistakes */
  int numcols;
  int *ty;  /* array of the types into which the col data is converted */
  int *is_null; /* -1 => NULL */
  void **data; /* array of pointers to data for each column */
} bound_columns;

#define BOUND_VAL(v) (* (bound_columns *) Data_custom_val(v))
#define BOUND_ALLOC()                                               \
  alloc_custom(&bound_columns_ops, sizeof(bound_columns), 1, 30)

/* Free the (possibly partially instianciated) bound coulon [b] */
#define FREE_BOUND_COLUMNS(b, last_col)          \
  free(b.ty);                                    \
  free(b.is_null);                               \
  for(i = 0; i < last_col; i++) free(b.data[i]); \
  free(b.data)

static void bound_columns_finalize(value v)
{
  int i;
  bound_columns b = BOUND_VAL(v);
  FREE_BOUND_COLUMNS(b, b.numcols);
}

static struct custom_operations bound_columns_ops = {
  "freetds/bound_columns",
  &bound_columns_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/* Reserve some space to hold the data of each column. */
value ocaml_freetds_dbbind(value vdbproc)
{
  CAMLparam1(vdbproc);
  CAMLlocal1(vbound);
  DBPROCESS *dbproc = DBPROCESS_VAL(vdbproc);
  bound_columns b;
  int c, ty, len, i;

#define CHECK_ALLOC(v)                           \
  if (v == NULL) {                               \
    FREE_BOUND_COLUMNS(b, c);                    \
    caml_raise_out_of_memory();                  \
  }

#define BIND(dbproc, c, vartype, varlen)                                \
  CHECK_ALLOC(b.data[c]);                                               \
  if (dbbind(dbproc, c+1, vartype, varlen, b.data[c]) == FAIL           \
      || dbnullbind(dbproc, c+1, &(b.is_null[c])) == FAIL) {                \
    FREE_BOUND_COLUMNS(b, c);                                           \
    failwith("Freetds.Dblib.bind: conversion failed (should not happen). " \
             "Contact the maintainer of the Freetds module.");          \
  }

  b.numcols = dbnumcols(dbproc);
  b.ty = malloc(b.numcols * sizeof(int));
  b.is_null = malloc(b.numcols * sizeof(int));
  b.data = malloc(b.numcols * sizeof(void *));
  if (b.ty == NULL || b.len == NULL || b.data == NULL) {
    FREE_BOUND_COLUMNS(b, 0); /* no col allocated yet */
    caml_raise_out_of_memory();
  }
  for (c = 0; c < b.numcols; c++) {
    switch (ty[c] = dbcoltype(dbproc, c+1)) {
    case SYBCHAR:    /* fall-through */
    case SYBVARCHAR:
    case SYBTEXT:
      /* Use VARYCHARBIND so there is no padding and no terminator \0
         added which is convenient for OCaml as strings can contain '\0'. */
      len = dbcollen(dbproc, c+1); /* max length, in bytes, of the data. */
      b.data[c] = malloc(len);
      BIND(dbproc, c, VARYCHARBIND, len);
      break;
    case SYBIMAGE:
    case SYBBINARY:
    case SYBVARBINARY:
      len = dbcollen(dbproc, c+1);
      b.data[c] = malloc(len);
      BIND(dbproc, c, VARYBINBIND, len);
      break;

    case SYBINT1:
    case SYBINT2:
    case SYBINTN:
    case SYBINT4:
      /* convert to INT but keep the differences in b.ty to qualify them */
      b.data[c] = malloc(sizeof(DBINT));
      BIND(dbproc, c, INTBIND, 1);
      break;
    case SYBINT8:
      /* FIXME: no conversion to int64!! */
      len = + 1; /* terminating \0 */
      b.size[c] = malloc(len);
      BIND(dbproc, c, STRINGBIND, len);
      break;

    case SYBFLT8:
    case SYBFLTN:
    case SYBREAL:
      b.size[c] = malloc(sizeof(DBFLT8));
      BIND(dbproc, c, FLT8BIND, 1);
      break;

    case SYBNUMERIC:
      b.size[c] = malloc(sizeof(DBDECIMAL));
      BIND(dbproc, c, DECIMALBIND, 1);
      break;
    case SYBDECIMAL:
      b.size[c] = malloc(sizeof(DBNUMERIC));
      BIND(dbproc, c, NUMERICBIND, 1);
      break;

    case SYBBIT:
      b.size[c] = malloc(sizeof(DBINT));
      BIND(dbproc, c, INTBIND, 1);
      break;

    case SYBDATETIME:
    case SYBDATETIME4:
    case SYBDATETIMN:
      b.size[c] = malloc(sizeof(DBDATETIME));
      BIND(dbproc, c, DATETIMEBIND, 1);
      break;

    case SYBMONEY4:
    case SYBMONEY:
    case SYBMONEYN:
      /* b.size[c] = malloc(sizeof(DBMONEY)); */
      /* BIND(dbproc, c, MONEYBIND, 1); */
      b.size[c] = malloc(sizeof(DBFLT8));
      BIND(dbproc, c, FLT8BIND, 1);
      break;
    }
  }
  vbound = BOUND_ALLOC();
  BOUND_VAL(vbound) = b;
  CAMLreturn(vbound);

#undef CHECK_ALLOC
#undef BIND
}


value ocaml_freetds_dbnextrow(value vbound)
{
  CAMLparam1(vbound);
  CAMLlocal4(vrow, vdata, , vcstr, vcons);
  bound_columns b = BOUND_VAL(vbound);
  RETCODE erc;
  int c;

/* Taken from the implementation of caml_copy_string */
#derine COPY_STRING(res, s, len_bytes)           \
  res = caml_alloc_string(len);                  \
  memmove(String_val(res), s, len_bytes);
  
#define CONSTRUCTOR(tag, value) \
  vcstr = caml_alloc(1, tag);   \
  Store_field(vcstr, 0, value)
  
  switch (dbnextrow(BOUND_VAL(vbound).conn)) {
  case REG_ROW:
    vrow = Val_int(0); /* empty list [] */
    for (c = b.numcols - 1; c >= 0; c--) {
      if (b.is_null[c] == -1) {
        vdata = Val_int(0); /* constant constructor NULL */
      } else {
        /* FIXME: Keep in sync with the decisions made in
           ocaml_freetds_dbbind */
        switch (ty[c]) {
        case SYBCHAR:    /* fall-through */
        case SYBVARCHAR:
        case SYBTEXT:
          COPY_STRING(vdata, b.data[c], dbdatlen(dbproc, c+1));
          CONSTRUCTOR(0, vdata);
          break;
        case SYBIMAGE:
        case SYBBINARY:
        case SYBVARBINARY:
          COPY_STRING(vdata, b.data[c], dbdatlen(dbproc, c+1));
          CONSTRUCTOR(10, vdata);
          break;
          
        case SYBINT1:
          CONSTRUCTOR(1, Val_int(b.data[c]));
        case SYBINT2:
          CONSTRUCTOR(2, Val_int(b.data[c]));
        case SYBINTN:
        case SYBINT4:
        INT_CONSTUCTOR:
#if OCAML_WORD_SIZE == 32
          if (-1073741824 <= b.data[c] && b.data[c] < 1073741824)
            CONSTRUCTOR(3, Val_int(b.data[c]));
          else /* require more than 31 bits allow for */
            CONSTRUCTOR(4, caml_copy_int32(b.data[c]));
#else
          CONSTRUCTOR(3, Val_int(b.data[c]));
#fi
          break;
        case SYBINT8:
          CONSTRUCTOR(5, copy_string(b.data[c]));
          break;
          
        case SYBFLT8:
        case SYBFLTN:
        case SYBREAL:
          CONSTRUCTOR(6, caml_copy_double(b.data[c]));
          break;
          
        case SYBNUMERIC:
          b.size[c] = malloc(sizeof(DBDECIMAL));
          BIND(dbproc, c, DECIMALBIND, 1);
          break;
        case SYBDECIMAL:
          b.size[c] = malloc(sizeof(DBNUMERIC));
          BIND(dbproc, c, NUMERICBIND, 1);
          break;
          
        case SYBBIT:
          b.size[c] = malloc(sizeof(DBINT));
          BIND(dbproc, c, INTBIND, 1);
          break;
          
        case SYBDATETIME:
        case SYBDATETIME4:
        case SYBDATETIMN:
          b.size[c] = malloc(sizeof(DBDATETIME));
          BIND(dbproc, c, DATETIMEBIND, 1);
          break;
          
        case SYBMONEY4:
        case SYBMONEY:
        case SYBMONEYN:
          b.size[c] = malloc(sizeof(DBMONEY));
          BIND(dbproc, c, MONEYBIND, 1);
          break;
        }
      }
      /* Place the data in front of the list [vrow]. */
      vcons = alloc_tuple(2);
      Store_field(vcons, 0, );
      Store_field(vcons, 1, vrow);
      vrow = vcons;
    }
    CAMLreturn(vrow);
    break;
    
  case NO_MORE_ROWS:
    caml_raise_not_found();
    break;
    
  case FAIL:
    failwith("Freetds.Dblib.nextrow");
    break;
    
  case BUF_FULL:
    failwith("Freetds.Dblib.nextrow: buffer full (report to the developer "
             "of this library)");
    break;
    
  default:
    /* FIXME: compute rows are ignored */
    CAMLreturn(Val_int(0)); /* row = [] */
  }
}



