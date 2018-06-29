open Freetds
open OUnit2
open Printf

let string_of_string s = s

let string_of_list f l =
  List.map f l
  |> String.concat ", "

let string_of_row r = string_of_list Dblib.string_of_data r

let get_params () =
  [ "USER" ; "PASSWORD" ; "SERVER" ; "DATABASE" ]
  |> List.map (fun suffix ->
      let env_var = sprintf "MSSQL_TEST_%s" suffix in
      try
        Some (Sys.getenv env_var)
      with Not_found ->
        None)
  |> function
  | [ Some user ; Some password ; Some server ; Some database ] ->
    Some (user, password, server, database)
  | _ ->
    None

let with_conn (user, password, server, database) f =
  let conn = Dblib.connect ~user ~password server in
  Dblib.use conn database;
  try
    let res = f conn in
    Dblib.close conn;
    res
  with e ->
    Dblib.close conn;
    raise e

let test_connect ((_, _, _, database) as params) _ =
  with_conn params (fun conn ->
      Dblib.name conn
      |> assert_equal ~printer:string_of_string database)

let test_bad_login (user, password, server, database) _ =
  (* this test is mostly just verifying that we don't crash if the error handler
     is called by dbopen *)
  let user = user ^ "invalid" in
  let params = (user, password, server, database) in
  let expect_msg =
      sprintf "Error on line 1: Login failed for user '%s'." user in
  assert_raises (Dblib.Error (Dblib.FATAL, expect_msg)) (fun () ->
      with_conn params (fun _ ->
          ()))

let test_basic_query params _ =
  with_conn params (fun conn ->
      Dblib.sqlexec conn "SELECT CAST(1 AS INT) AS test";
      Dblib.results conn
      |> assert_bool "query has results";
      Dblib.numcols conn
      |> assert_equal ~printer:string_of_int 1;
      Dblib.colname conn 1
      |> assert_equal ~printer:string_of_string "test";
      Dblib.coltype conn 1
      |> assert_equal ~printer:Dblib.string_of_col_type Dblib.SYBINT4;
      (try
         ignore(Dblib.coltype conn 2);
         assert_failure "Dblib.coltype should signal '2' is not a valid column"
       with Dblib.Error(Dblib.PROGRAM, _) -> ()
          | e -> assert_failure("Dblib.coltype should raise Error(PROGRAM, _) \
                                 instead of " ^ Printexc.to_string e));
      (try
         ignore(Dblib.colname conn 2);
         assert_failure "Dblib.colname should signal '2' is not a valid column"
       with Dblib.Error(Dblib.PROGRAM, _) -> ()
          | e -> assert_failure("Dblib.colname should raise Error(PROGRAM, _) \
                                 instead of " ^ Printexc.to_string e));
      Dblib.nextrow conn
      |> assert_equal ~printer:(string_of_list Dblib.string_of_data)
        [ Dblib.INT 1 ];
      assert_raises Not_found (fun () -> Dblib.nextrow conn);
      Dblib.results conn
      |> assert_equal ~printer:string_of_bool false;
      Dblib.count conn
      |> assert_equal ~printer:string_of_int 1)

let test_empty_strings params _ =
  with_conn params (fun conn ->
      (* Cast empty string to various types since conversions are different for
         each *)
      Dblib.sqlexec conn
        {|
          SELECT CAST('' AS VARCHAR(10)) AS vc,
                 CAST('' AS TEXT) AS txt,
                 CAST('' AS VARBINARY(10)) AS vb,
                 CAST(NULL AS VARCHAR(1)) AS nvc,
                 CAST(NULL AS TEXT) AS ntxt,
                 CAST(NULL AS VARBINARY(10)) AS nvb
        |};
      Dblib.results conn
      |> assert_bool "query has results";
      let cols = [ 1 ; 2 ; 3 ; 4 ; 5 ; 6 ] in
      cols
      |> List.map (Dblib.colname conn)
      |> assert_equal ~printer:(string_of_list string_of_string)
        [ "vc" ; "txt" ; "vb" ; "nvc" ; "ntxt" ; "nvb" ];
      cols
      |> List.map (Dblib.coltype conn)
      |> assert_equal ~printer:(string_of_list Dblib.string_of_col_type)
        Dblib.([SYBCHAR ; SYBTEXT; SYBBINARY; SYBCHAR; SYBTEXT; SYBBINARY]);
      Dblib.nextrow conn
      |> assert_equal ~printer:string_of_row
        Dblib.([STRING ""; STRING ""; BINARY ""; NULL; NULL; NULL]))

let test_data params _ =
  with_conn params (fun conn ->
      Dblib.sqlexec conn "SELECT \
                          CAST('a' AS VARCHAR(10)) AS vc, \
                          CAST('a' AS CHAR(10)) AS c, \
                          CAST('abc' AS TEXT) AS txt, \
                          CAST(1 AS INT) AS i, \
                          CAST(3.4 AS DOUBLE PRECISION) AS d";
      Dblib.results conn
      |> assert_bool "query has results";
      Dblib.nextrow conn
      |> assert_equal ~printer:string_of_row
           Dblib.([STRING "a"; STRING "a         "; STRING "abc";
                   INT 1; FLOAT 3.4])
    )

let test_insert params _ =
  with_conn params (fun conn ->
      Dblib.sqlexec conn "CREATE TABLE #test(
                          c1 VARCHAR(10) DEFAULT '',
                          c2 VARCHAR(10) DEFAULT '',
                          c3 INT, c4 DOUBLE PRECISION)";
      Dblib.sqlexec conn "INSERT INTO #test VALUES('a', 'β', 3, 4.2)";
      Dblib.count conn |> assert_equal ~printer:string_of_int 1;
      Dblib.sqlexec conn "INSERT INTO #test VALUES('', '', -1, -6.3)";
      Dblib.sqlexec conn "SELECT c1, LEN(c1), RTRIM(c2), c3, c4 FROM #test";
      Dblib.results conn
      |> assert_bool "query has results";
      Dblib.nextrow conn
      |> assert_equal ~printer:string_of_row
           Dblib.([STRING "a"; INT 1; STRING "β"; INT 3; FLOAT 4.2]);
      Dblib.nextrow conn
      |> assert_equal ~printer:string_of_row
           Dblib.([STRING ""; INT 0; STRING ""; INT(-1); FLOAT(-6.3)]);
    )

let test_concurrency params _ =
  let jobs = ref [] in
  for _ = 0 to 50 do
    let result = ref (Error (Failure "result was never set")) in
    let job =
      Thread.create (fun () ->
          result :=
            try
              with_conn params (fun conn ->
                  Dblib.sqlexec conn "SELECT 1, 2, 3";
                  Dblib.results conn
                  |> assert_bool "query has results";
                  Dblib.nextrow conn
                  |> assert_equal ~printer:string_of_row
                    Dblib.([INT 1; INT 2; INT 3]);
                  Dblib.canquery conn;
                  (try
                     ignore(Dblib.coltype conn 4);
                     assert_failure "Dblib.coltype should signal '4' is not a valid column"
                   with
                   | Dblib.Error(Dblib.PROGRAM, _) -> ()
                   | e -> assert_failure("Dblib.coltype should raise Error(PROGRAM, _) \
                                          instead of " ^ Printexc.to_string e));
                  (try
                     Dblib.sqlexec conn "not real sql";
                   with
                   | Dblib.Error(Dblib.FATAL, _) -> ()
                   | e -> assert_failure("Dblib.sqlexec should raise Error(FATAL, _) \
                                          instead of " ^ Printexc.to_string e));
                  Ok ())
            with exn ->
              Printexc.print_backtrace stderr;
              Error exn)
        ()
    in
    jobs := (job, result) :: !jobs
  done;
  List.iter (fun (job, result) ->
      Thread.join job;
      assert_equal (Ok ()) !result) !jobs

let () =
  match get_params () with
  | None ->
     print_endline "Skipping tests since MSSQL_TEST_* environment variables \
                    aren't set"
  | Some params ->
     [ "connect", test_connect
     ; "bad login", test_bad_login
     ; "basic query", test_basic_query
     ; "empty strings", test_empty_strings
     ; "data", test_data
     ; "insert", test_insert
     ; "concurrency", test_concurrency ]
     |> List.map (fun (name, test) -> name >:: test params)
     |> OUnit2.test_list
     |> OUnit2.run_test_tt_main
