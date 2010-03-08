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


(** Binding to the DB-lib part of freetds. *)

type dbprocess
  (**  *)

external dbopen : user:string -> passwd:string -> server:string -> dbprocess
  = "ocaml_freetds_dbopen"
    (** Open a connection to the given database server. *)

external dbclose : dbprocess -> unit = "ocaml_freetds_dbclose"
    (** [dbclose conn] close the connection [conn] to the server. *)

external dbuse : dbprocess -> string -> unit = "ocaml_freetds_dbuse"
    (** [dbuse conn name] change the current database to [name]. *)

external dbsqlexec : dbprocess -> string -> unit = "ocaml_freetds_dbsqlexec"
  (** Send the SQL command to the server and wait for an answer.  *)

