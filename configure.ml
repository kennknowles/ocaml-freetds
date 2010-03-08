open Conf;;
open Printf;;
open Util;;

let spec =
	(standard_spec @
	[
		param	"freetds-libdir" (String "") ~doc:"Path to the freetds library.", true;
        param   "freetds-incdir" (String "") ~doc:"Path to the freetds include files.", true;
		findlib_check "str", true;
	])
;;

let configuration = configure spec

open AutoMake;;

(* Inform the user of the configuration *)
let _ =
	printf "
----------- Configuration Summary -----------
";
	print_string (summarize_config configuration spec);
	print_string "If the tds paths are blank, its ok.  Just 'make' and 'make install'.\n"

let sources = ["ct_c.c"; "ct.mli"; "ct.ml"]
let c_libflag = match conf_string configuration "freetds-libdir" with "" -> "" | s -> "-L" ^ s
let c_incflag = match conf_string configuration "freetds-incdir" with "" -> "" | s -> "-I" ^ s

let libflag = "" (*match conf_string configuration "freetds-libdir" with "" -> "" | s -> "-L " ^ s*)
let incflag = "" (*match conf_string configuration "freetds-incdir" with "" -> "" | s -> "-I " ^ s*)

let ml_libflag = match conf_string configuration "freetds-libdir" with 
    "" -> "" 
    | s -> sprintf "-dllpath %s -ccopt -L%s" s s

let freetds_top = toplevel "freetds.top" ~dest:`nowhere ~sources
let freetds_cma = library "freetds" ~dest:`findlib ~shared:true ~sources
let freetds_doc = documentation "docs" ~sources
	
(* The makefile generation information *)
let _ = output 
	~package:"ocaml-freetds"

    ~findlib_package:"freetds"

	~version:"0.2"

    ~findlib_installs_opt:false

    ~findlib_installed_files:["ct.cmi"; "ct.mli"]

	~findlibs:["str"]

	~flags:[
		(`ocamldoc, "-I ml -colorize-code -sort -keep-code");
		(`ocamlc, sprintf "-g %s -cclib -lct" ml_libflag);
		(`ocamlopt, sprintf "-cclib %s -lct -ccopt -L." ml_libflag);
		(`ocamlmktop, sprintf "-custom -g %s -cclib -lct" ml_libflag);
        (`cc, sprintf "%s %s -lct" c_incflag c_libflag);
	]

    ~cleaned:["*~"; "*/*~"]

	[
        freetds_cma;
        freetds_doc;
        freetds_top;

    (* In order to use these, just feed the .ml files to the toplevel -
        I have yet to perfect ocamlconf's shared library paths; I don't really
        want to force the executables to have "." in their built in library path *)
	]
;;








