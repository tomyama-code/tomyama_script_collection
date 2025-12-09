# Change Log

## [Unreleased]
### Added
- xxx

### Changed
- xxx

## [0.2.31] - 2025-12-10
### Added
- `fill` [1.01.002]: Added "--version" option.
- `mark` [1.02.002]: Added "--version" option.

### Changed
- `c` [1.04.052]: The latitude and longitude format conversion section has been enhanced.
- `c` [1.04.051]: "TIME", which indicates the current time, was difficult to understand, so it was changed to use "NOW".
- Added --version option to help display and POD.
  - `c` [1.04.049]
  - `fill` [1.01.003]
  - `mark` [1.02.003]

## [0.2.30] - 2025-12-09
### Added
- `c` [1.04.047]: Add a function.
  - slope_deg( X, Y ). Returns the straight line distance from (0,0) to (X,Y).
  - dist_between_points( X1, Y1, X2, Y2 ) or dist_between_points( X1, Y1, Z1, X2, Y2, Z2 ). Returns the straight-line distance from (X1,Y1) to (X2,Y2) or from (X1,Y1,Z1) to (X2,Y2,Z2). alias: dist().
  - midpt_between_points( X1, Y1, X2, Y2 ) or midpt_between_points( X1, Y1, Z1, X2, Y2, Z2 ). Returns the coordinates of the midpoint between (X1,Y1) and (X2,Y2), or (X1,Y1,Z1) and (X2,Y2,Z2). alias: midpt().
  - angle_between_points( X1, Y1, X2, Y2 ) or angle_between_points( X1, Y1, Z1, X2, Y2, Z2 ). Returns the angle (in degrees) from (X1,Y1) to (X2,Y2) or from (X1,Y1,Z1) to (X2,Y2,Z2). alias: angle().

## [0.2.29] - 2025-12-08
### Changed
- `c` [1.04.046]: Added latitude and longitude rules to full-width character to half-width character conversion.
- `tests/tests.sh`: Fixed issue where file sizes were not being linked to coverage results table in other development directories.

## [0.2.28] - 2025-12-06
### Added
- `c` [1.04.044]: Added "--version" option.

### Changed
- `c` [1.04.043]: Updated POD.
- `tests/c.test.pl`: "./c 'get_prime( 32 )|0'": The regular expression for the expected value has been corrected since it can sometimes result in a negative value in a 32-bit environment (Termux).

## [0.2.27] - 2025-12-05
### Changed
- `tests/tests.sh`:
  - Added file size ratio to the coverage measurement result table.
  - Execution time is also output.
  - It is now also output to the file "test_summary.txt".

## [0.2.26] - 2025-12-03
### Added
- `c` [1.04.041]: "-u", "--user-defined": Added options to output values ​​defined in the ".c.rc" file.
- `c` [1.04.039]: Added the ability to use abbreviations (aliases) for some functions.
  - rs() -> ratio_scaling()
  - pf() -> prime_factorize()
  - gd_m() -> geo_distance_m()
  - gd_km() -> geo_distance_km()

### Changed
- `c` [1.04.042]: Added examples of POD usage using abbreviations (alias).
- `c` [1.04.040]: Shortened function name: radius_of_lat_circle() -> radius_of_lat()

## [0.2.25] - 2025-12-01
### Changed
- `c` [1.04.038]:
  - GetToken() of FormulaLexer: Changed error message to be more understandable.
    - Before: 'c: lexer: error: "t": unknown operator.'
    - After : 'c: lexer: error: "tokyo_st_coord, osaka_st_coord )=": Could not interpret.'
  - Change the name of the user-defined file: ".c.constant" -> ".c.rc"
  - Updated POD.

## [0.2.24] - 2025-11-30
### Added
- `c`: prime_factorize(), get_prime(), prod().

## [0.2.23] - 2025-11-28
### Added
- `c`:
  - left shift "<<" and right shift ">>" operators.
  - is_prime(): Primality test function.

## [0.2.22] - 2025-11-27
### Added
- `c`: Added the ability to load .c.constant files, allowing users to define constants.

### Changed
- `c`: "dhms2sec( D, H, M, S )" -> "dhms2sec( D [, H, M, S ] )". Changed so that arguments can be omitted.

### Removed
- `cover_db`: Stopped committing coverage html. Deleted the cover_db directory.

## [0.2.21] - 2025-11-25
### Added
- `c`: ratio_scaling(), dhms2sec(), local2epoch(), gmt2epoch(), epoch2local(), epoch2gmt(), sec2dhms(), time .

## [0.2.18] - 2025-11-24
### Added
- `c`:
  - Instead of hanging OutputFunc on each module instance, now it is inherited whenever possible (using use base qq{OutputFunc};).
  - Added CAppConfig, which stops passing configuration information individually and instead aggregates it at a higher level before passing it.

### Changed
- `c`: Changed the method for determining negative values.

## [0.2.16] - 2025-11-23
### Changed
- `c`:
  - Changed the version output format: "$Revision: 4.20 $" -> "Version 1.04.020".
  - When displaying the results of a set, conversion of hexadecimal numbers, negative values, exponential notation, etc. was not fully supported, so this has been fixed.

## [0.2.15] - 2025-11-22
### Added
- `c`: linstep() .
- `cover_db`: decided to commit the test coverage result file (HTML).

### Changed
- `c`: Fixed so that negative values ​​can be determined even in systems where the minimum numerical unit is 32 bits.
- `tests/tests.sh`: Edited the path of "Database:" in html to be a relative path.

## [0.2.14] - 2025-11-21
### Added
- `c`: geo_distance_km(), geo_distance_m()

### Changed
- `c`: Created GetTerminalWidth() to obtain the terminal width using the stty command or environment variables, while avoiding the need to install the Term::ReadKey::GetTerminalSize() module.
- `GenAutotoolsAcAm_UserFile.pm`: Removed hello.pl, hello.sh.

### Removed
- `hello.pl`, `hello.sh`

## [0.2.12] - 2025-11-20
### Changed
- `c`:
  - Stopped using Term::ReadKey::GetTerminalSize() and decided to format help display at a fixed width. Reason: Term::ReadKey is a non-core module, and some environments require a C compiler to install. We don't want to increase build requirements just for "help formatting."
  - The text formatting process in the --help display is now performed according to the terminal width obtained by Term::ReadKey::GetTerminalSize().
  - Added a list of modules used to POD.

## [0.2.9] - 2025-11-19
### Added
- `c`: first(), deg2dms() .

### Changed
- `c`:
  - Function name change
    - distance_between_points() -> geo_distance()
    - radius_of_latitude_circle() -> radius_of_lat_circle()
    - geocentric_radius() -> geo_radius()
    - dms() -> dms2deg()
  - In addition to VA, the definition of variable arguments has been expanded to include range specification '3-4' and multiple of N '3M'.

## [0.2.7] - 2025-11-18
### Added
- `c`: Added pow_inv() and linspace().

### Changed
- `c`: Now fully supports returning sets. Previously, a warning was displayed when the expression (1, 2 + 1) was input, but now no warning is displayed. Only the result (1, 3) is output to STDOUT.

## [0.2.7] - 2025-11-17
### Added
- `c`: Added qniq() and shuffle() to List::Util, which return a set. This allows handling of functions that return a set.

### Changed
- `c`: Modified deg2rad() and dms2rad() to accept multiple inputs (deg, dms respectively) and produce multiple outputs.

## [0.2.6] - 2025-11-16
### Added
- `c`: Command Line Calculator Script.

## [0.2.5] - 2025-10-18
### Added
- `tests/tests.sh`:

### Changed
- `tests/tests.sh`:
  - Changed to get perl coverage by default.
  - The path displayed in coverage.html is an absolute path and difficult to read, so I changed the execution directory from tests to projecttop.
- `tests/prt`: support -e option.

## [0.2.4] - 2025-10-05
### Changed
- The comment headers of *.ac and *.am files now state that they are automatically generated and the revision of the file they are based on.

## [0.2.3] - 2025-10-04
### Added
- Add distribution script.
  - `mark`: emphasizes part matching a pattern
- The build procedure was scripted.
  - `tools/build_script.sh`: A script that describes the build steps

### Changed
- Change the location of the image.
  - `docs` -> `docs/img`
- If you prepare an image for each script, you can paste it into the document, such as a screen capture.
  - change: `tools/create_CATALOG.sh`
  - Images will also be used in `README.md`.
- I put together a wrapper script for measuring perl coverage using "Devel::Cover".
  - add: `tests/cmd_wrapper`
  - delete: `tests/fill_wrapper.pl`
  - delete: `tests/mark_wrapper.pl`

## [0.2.0] - 2025-10-01
### Added
- Add the first script.
  - `fill`: Generates data row-wise according to a pattern, similar to Excel's AutoFill.

### Changed
- The process of generating svg images from dot files has been changed from using a script to being done by a Makefile.
  - remove: `tools/create_graph.sh`
- Fixed so that the file timestamp is not changed if there are no changes to the file being updated.
  - change: `tools/gen_autotools_acam.pl`
  - change: `tools/create_CATALOG.sh`

## [0.1.0] - 2025-09-29
### Added
- First commit. Just the framework, no scripts yet.
- The committed files are as follows:
  - `ChangeLog.md`
  - `LICENSE`
  - `Makefile.am`
  - `Makefile.in`
  - `README.md`
  - `aclocal.m4`
  - `configure`
  - `configure.ac`
  - `docs/CATALOG.md`
  - `docs/GenAutotoolsAcAm_UserFile.pm.md`
  - `docs/README_dir_struct.dot`
  - `docs/README_dir_struct.svg`
  - `docs/create_CATALOG.sh.md`
  - `docs/create_graph.sh.md`
  - `docs/gen_autotools_acam.pl.md`
  - `docs/hello.pl.md`
  - `docs/hello.sh.md`
  - `docs/index.md`
  - `hello.pl`
  - `hello.sh`
  - `install-sh`
  - `missing`
  - `test-driver`
  - `tests/Makefile.am`
  - `tests/Makefile.in`
  - `tests/hello.pl.test.pl`
  - `tests/hello.sh.test.pl`
  - `tools/GenAutotoolsAcAm_UserFile.pm`
  - `tools/create_CATALOG.sh`
  - `tools/create_graph.sh`
  - `tools/gen_autotools_acam.pl`
