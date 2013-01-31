OCaml FreeTDS Binding
=====================

See the INSTALL file for requirements and build instructions.

License
-------

ocaml-freetds is distributed under the terms of the GNU Lesser
Public License, version 2.1 See the file COPYING.LIB for details


Feature Summary
---------------

- Direct binding to the ct-lib interface
- Dbi_freetds module (not in this tarball) included with ocamldbi 


Known Bugs And Limitations
--------------------------

- Some data types, such as datetimes, are returned as strings,
  because I haven't had time to write a good binding for them yet.

- It would be nice to bind the dblib interface as well, and maybe
  even have the DBI module be able to use either, because I understand
  they have slightly different features

Examples
--------

In the examples subdirectory is a simple SQL dispatcher script written against
the Ct module, and also one for the Dbi_freetds module.

