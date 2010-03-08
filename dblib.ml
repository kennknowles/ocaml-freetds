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


external dbinit : unit -> unit = "ocaml_dbinit"

let () = dbinit()
  (* One must call this function before trying to use db-lib in any
     way.  Allocates various internal structures and reads
     locales.conf (if any) to determine the default date format.  *)

type dbprocess
external dbopen : user:string -> passwd:string -> server:string -> dbprocess
  = "ocaml_freetds_dbopen"

external dbclose : dbprocess -> unit = "ocaml_freetds_dbclose"

external dbuse : dbprocess -> string -> unit = "ocaml_freetds_dbuse"

external dbsqlexec : dbprocess -> string -> unit = "ocaml_freetds_dbsqlexec"

