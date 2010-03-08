(* File: dblib.ml

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


external dbinit : unit -> unit = "ocaml_freetds_dbinit"

let () = dbinit()
  (* One must call this function before trying to use db-lib in any
     way.  Allocates various internal structures and reads
     locales.conf (if any) to determine the default date format.  *)

type dbprocess

external connect : user:string -> passwd:string -> server:string -> dbprocess
  = "ocaml_freetds_dbopen"

external close : dbprocess -> unit = "ocaml_freetds_dbclose"

external use : dbprocess -> string -> unit = "ocaml_freetds_dbuse"

external sqlexec : dbprocess -> string -> unit = "ocaml_freetds_dbsqlexec"

external cancel :  dbprocess -> unit = "ocaml_freetds_dbcancel"
external canquery :  dbprocess -> unit = "ocaml_freetds_dbcanquery"

external results : dbprocess -> bool = "ocaml_freetds_dbresults"

external numcols : dbprocess -> int = "ocaml_freetds_numcols" "noalloc"
    (** Return number of regular columns in a result set.  *)

external colname : dbprocess -> int -> string = "ocaml_freetds_dbcolname"

(* See /usr/include/sybdb.h *)

type col_type =
  | SYBCHAR (* 0 *) | SYBVARCHAR (* 1 *)
  | SYBINTN (* 2 *) | SYBINT1 (* 3 *) | SYBINT2 (* 4 *)
  | SYBINT4 (* 5 *) | SYBINT8 (* 6 *)
  | SYBFLT8 (* 7 *) | SYBFLTN (* 8 *)
  | SYBNUMERIC (* 9 *)
  | SYBDECIMAL (* 10 *)
  | SYBDATETIME (* 11 *) | SYBDATETIME4 (* 12 *) | SYBDATETIMN (* 13 *)
  | SYBBIT (* 14 *)
  | SYBTEXT (* 15 *)
  | SYBIMAGE (* 16 *)
  | SYBMONEY4 (* 17 *) | SYBMONEY (* 18 *) | SYBMONEYN (* 19 *)
  | SYBREAL (* 20 *)
  | SYBBINARY (* 21 *) | SYBVARBINARY (* 22 *)

let string_of_col_type = function
  | SYBCHAR -> "CHAR"
  | SYBVARCHAR -> "VARCHAR"
  | SYBINTN -> "INT"    | SYBINT1 -> "INT1" | SYBINT2 -> "INT2"
  | SYBINT4 -> "INT4"   | SYBINT8 -> "INT8"
  | SYBFLT8 -> "FLOAT8" | SYBFLTN -> "FLOAT"
  | SYBREAL -> "REAL"
  | SYBBIT -> "BIT"
  | SYBTEXT -> "TEXT"
  | SYBIMAGE -> "IMAGE"
  | SYBMONEY4 -> "MONEY4" | SYBMONEY -> "MONEY" | SYBMONEYN -> "MONEY"
  | SYBDATETIME -> "DATETIME"
  | SYBDATETIME4 -> "DATETIME4" | SYBDATETIMN -> "DATETIME"
  | SYBBINARY -> "BINARY" | SYBVARBINARY -> "VARBINARY"
  | SYBNUMERIC -> "NUMERIC"
  | SYBDECIMAL -> "DECIMAL"
;;
external coltype : dbprocess -> int -> col_type = "ocaml_freetds_dbcoltype"

(* See /usr/include/sybdb.h, CHARBIND ... *)
type data =
  | NULL
  | STRING of string                    (* tag = 0 *)
  | TINY of int
  | SMALL of int
  | INT of int
  | INT32 of int32
  | INT64 of string (* FIXME: do better *)
  | FLOAT of float                      (* tag = 6 *)
  | DATETIME of string (* FIXME: do better *)
  | MONEY of float
  | BIT of bool
  | BINARY of string                    (* tag = 10 *)
  | NUMERIC of string (* FIXME: do better *)
  | DECIMAL of string (* FIXME: do better *)

external nextrow : dbprocess -> data list = "ocaml_freetds_dbnextrow"
