(* File: dblib.mli

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3 or
   later as published by the Free Software Foundation, with the special
   exception on linking described in the file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. *)


(** Low level binding to the DB-lib part of freetds.  These bindings
    mimic the C API and therefore some functions must be used in the
    right order.  Use OCamlDBI with the freetds driver for an easier
    interaction with such databases. *)

type dbprocess
  (** Value that contains all information needed by [Freetds.Dblib] to
      manage communications with the server.  *)

external connect : user:string -> passwd:string -> server:string -> dbprocess
  = "ocaml_freetds_dbopen"
    (** Open a connection to the given database server.
        @raise Failure if the connection to the database could not be
        established. *)

external close : dbprocess -> unit = "ocaml_freetds_dbclose"
    (** [dbclose conn] close the connection [conn] to the server. *)

external use : dbprocess -> string -> unit = "ocaml_freetds_dbuse"
    (** [dbuse conn name] change the current database to [name].
        @raise Failure if the database cannot be used. *)

external sqlexec : dbprocess -> string -> unit = "ocaml_freetds_dbsqlexec"
  (** Send the SQL command to the server and wait for an answer.
      @raise Failure if the SQL query is incorrect or another problem
      occurs.

      {b Warning}: There is one absolutely crucial, inflexible, unalterable
      requirement: the application must process all rows produced by the
      query. Before the [dbprocess] can be used for another query, the
      application must either fetch all rows, or cancel the results and
      receive an acknowledgement from the server. *)

external cancel :  dbprocess -> unit = "ocaml_freetds_dbcancel"
    (** Cancel the current command batch.  *)

external canquery :  dbprocess -> unit = "ocaml_freetds_dbcanquery"
    (** Cancel the query currently being retrieved, (retriving and)
        discarding all pending rows. *)

external results : dbprocess -> bool = "ocaml_freetds_dbresults"
    (** [results conn] returns [true] if some results are available
        and [false] if the query produced no results.  There may be
        several results if COMPUTE clauses are used.
        One MUST CALL this function before trying to retrieve any rows.

        @raise Failure if the query was not processed successfully by the
        server. *)

external numcols : dbprocess -> int = "ocaml_freetds_numcols" "noalloc"
    (** Return number of regular columns in a result set.  *)

external colname : dbprocess -> int -> string = "ocaml_freetds_dbcolname"
    (** [colname conn c] returns the name of a regular result
        column [c].  The first column has number 1.
        @raise Invalid_argument if the column is not in range.  *)

type col_type =
  | SYBCHAR | SYBVARCHAR
  | SYBINTN | SYBINT1 | SYBINT2 | SYBINT4 | SYBINT8
  | SYBFLT8 | SYBFLTN
  | SYBNUMERIC
  | SYBDECIMAL
  | SYBDATETIME | SYBDATETIME4  | SYBDATETIMN
  | SYBBIT
  | SYBTEXT
  | SYBIMAGE
  | SYBMONEY4 | SYBMONEY | SYBMONEYN
  | SYBREAL
  | SYBBINARY | SYBVARBINARY

val string_of_col_type : col_type -> string
  (** Returns a string description of the column type. *)

external coltype : dbprocess -> int -> col_type = "ocaml_freetds_dbcoltype"
  (** Get the datatype of a regular result set column.  *)
