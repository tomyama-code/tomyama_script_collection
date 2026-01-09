# Change Log

## [Unreleased]
### Added
- xxx

### Changed
- xxx

## [0.2.50] - 2026-01-1x
### Change
- Code cleanup. Behavior remains the same.
  - c       [1.04.113]
  - cl      [1.02.031]
  - fill    [1.01.006]
  - holiday [1.01.005]
  - mark    [1.02.005]
- cl.holiday [2026.1]: Added Japanese holiday data from 1949 to 1954.

## [0.2.49] - 2026-01-09
### Added
- c [1.04.111]: Add a function.
  - geo_azimuth( A_LAT, A_LON, B_LAT, B_LON ). alias: gazm().
  - g_dist_m_and_azimuth( A_LAT, A_LON, B_LAT, B_LON ). alias: gd_m_azm().
  - g_dist_km_and_azimuth( A_LAT, A_LON, B_LAT, B_LON ). alias: gd_km_azm().

### Change
- c [1.04.112]: Rename the function.
  - slope_deg() -> angle_deg()

## [0.2.48] - 2026-01-08
### Added
- Add a script.
  - `cl` [1.02.028]: Simple clock script
  - `holiday` [1.01.004]: Displaying holiday data in the pager

### Changed
- Edit documentation (POD, Markdown).
  - `c` [1.04.110]
  - `fill` [1.01.005]
  - `mark` [1.02.004]

## [0.2.47] - 2025-12-29
### Changed
- `c` [1.04.106]: Edit the POD.
- `c` [1.04.105]: paper_size(): Changed so that the area is not output since it can be calculated.
- `c` [1.04.104]: Add an alias to an existing function.
  - l2e() -> local2epoch()
  - g2e() -> gmt2epoch()
  - e2l() -> epoch2local()
  - e2g() -> epoch2gmt()
- `c` [1.04.103]: waitEnter(): The auto flash setting is now written back at the end.

## [0.2.46] - 2025-12-28
### Changed
- `c` [1.04.102]: timer(): Changed to ring a bell when it reaches or passes through 0.
- `c` [1.04.101]: timer(): Fixed the reference time when specifying seconds to be accurate to less than a second.

## [0.2.45] - 2025-12-27
### Added
- `c` [1.04.100]: Add a function.
  - timer( I<SECOND> ).
    If you specify a value less than 31536000 (365 days x 86400 seconds) for I<SECOND>,
    the countdown will begin and end when it reaches zero.
    If you specify a value greater than this,
    it will be recognized as an epoch second,
    and the countdown or countup will begin with that date and time as zero.
    In this case, the countup will continue without stopping at zero.
    In either mode, press Enter to end.

## [0.2.44] - 2025-12-26
### Changed
- `c` [1.04.099]: Argument specifications changed.
  - stopwatch()          <= stopwatch( B_PRINT )
  - bpm( COUNT, SECOND ) <= bpm( B_PRINT, COUNT )
  - bpm15()              <= bpm15( B_PRINT )
  - bpm30()              <= bpm30( B_PRINT )
  - tachymeter( SECOND ) <= tachymeter( B_PRINT )
- `c` [1.04.098]: FormulaLexer: GetFormula(), GetHere(): Minor output corrections.
  - after : "c: evaluator: info: sqrt( pow( 2, 100 ) + pow( 2100 )"
            "c: evaluator: info:                       ^^^^ HERE"
  - before: "c: evaluator: info: sqrt( pow( 2 , 100 ) + pow( 2100 )"
            "c: evaluator: info:                        ^^^^ HERE"

## [0.2.43] - 2025-12-25
### Added
- `c` [1.04.092]: Add a function.
  - mul_growth( START, FACTOR, LENGTH ).
    Starting from START, we multiply the value by FACTOR and add it to the sequence.
    Returns the sequence of numbers starting at START and of size LENGTH.
    LENGTH is an integer greater than or equal to 1.

### Changed
- `c` [1.04.097]: Changed to handle multiple numbers.
  - is_leap( I<YEAR1> [,.. ] ).
  - is_prime( I<NUM1> [,.. ] ).
- `c` [1.04.092]: The length specification for functions that return sequences has been unified to LENGTH.
  - linspace( START, END, LENGTH [, DECIMAL_PLACES] ).
    LENGTH is an integer greater than or equal to 2.
  - linstep( START, STEP, LENGTH ).
    LENGTH is an integer greater than or equal to 1.
  - gen_fibo_seq( A, B, LENGTH ).
    LENGTH is an integer greater than or equal to 2.

## [0.2.42] - 2025-12-24
### Added
- `c` [1.04.088]: Add a function.
  - exp2( N1 [,.. ] ). Returns the base 2 raised to the power N.
  - log2( N1 [,.. ] ). Returns the common logarithm to the base 2.
  - exp10( N1 [,.. ] ). Returns the base 10 raised to the power N.

### Changed
- `c` [1.04.088]: Changed to handle multiple numbers.
  - exp( N1 [,.. ] ). Returns e (the natural logarithm base) to the power of N.

## [0.2.41] - 2025-12-23
### Added
- `c` [1.04.086]: Add a function.
  - log10( N1 [,.. ] ). Returns the common logarithm to the base 10.

### Changed
- `c` [1.04.086]: Changed to handle multiple numbers.
  - log( N1 [,.. ] ). Returns the natural logarithm (base e) of N.
  - sqrt( N1 [,.. ] ). Return the positive square root of N.
                       Works only for non-negative operands.

## [0.2.40] - 2025-12-22
### Changed
- `c` [1.04.083]: Changed to handle multiple numbers.
  - abs( N1 [,.. ] ). Returns the absolute value of its argument.
  - int( N1 [,.. ] ). Returns the integer portion of N.
  - floor( N1 [,.. ] ).
    Returning the largest integer value less than or equal to the numerical argument.
  - ceil( N1 [,.. ] ).
    Returning the smallest integer value greater than or equal to the given numerical argument.

## [0.2.39] - 2025-12-21
### Added
- `c` [1.04.079]: Add a function.
  - add_each( NUMBER1,.. , OFFSET ). Add each number.
  - mul_each( NUMBER1,.. , FACTOR ). Multiply each number.

### Changed
- `c` [1.04.080]: Changed to handle multiple numbers.
  - rounddown( NUMBER1 [,..], DECIMAL_PLACES ).
    Returns the value of NUMBER1
  - round( NUMBER1 [,..], DECIMAL_PLACES ).
    Returns the value of NUMBER1 rounded to DECIMAL_PLACES.
  - roundup( NUMBER1 [,..], DECIMAL_PLACES ).
    Returns the value of NUMBER1 rounded up to DECIMAL_PLACES.

## [0.2.36] - 2025-12-17
### Added
- `c` [1.04.072]: Add a function.
  - paper_size( SIZE [, TYPE ] ).
    Returns the following information in this order:
    length of short side, length of long side (in mm), area (in mm2).
    SIZE is a positive integer.
    If TYPE is omitted or 0 is specified, it will be A size.
    If TYPE is specified, it will be B size.
  - gen_fibo_seq( A, B, COUNT ).
    Generates the Generalized Fibonacci Sequence.
    COUNT is a positive integer.
    Returns an array starting at A and B, with size COUNT + 2.
  - slice( NUMBER1,.., OFFSET, LENGTH ).
    Extracts elements specified by OFFSET and LENGTH from a set.

### Changed
- `c` [1.04.073]: Edit the POD.
- `c` [1.04.068]: The fourth argument of linspace() has been changed from ROUND(Bool) to DECIMAL_PLACES.

## [0.2.35] - 2025-12-15
### Added
- `c` [1.04.065]: Add a function.
  - laptimer( LAPS ). alias: lt().
  - stopwatch( B_PRINT ). alias: sw().
  - bpm( B_PRINT, COUNT )
  - bpm15( B_PRINT )
  - bpm30( B_PRINT )
  - tachymeter( B_PRINT )
  - telemeter( SECOND )
  - telemeter_m( SECOND )
  - telemeter_km( SECOND )

### Changed
- `c` [1.04.066]: rename: pct() -> percentage(). pct() is an alias for percentage().

## [0.2.34] - 2025-12-14
### Added
- `c` [1.04.064]: Add a function.
  - exp( N ). Returns e (the natural logarithm base) to the power of N. [Perl Native]
  - age_of_moon( Y, m, d ). Simple calculation of the age of the moon. Maximum deviation of about 2 days.
  - nCr( N, R ). N Choose R. A combination of R items selected from N items. N and R are positive integers.
  - is_leap( YEAR ). Leap year test: Returns 1 if YEAR is a leap year, 0 otherwise.

## [0.2.33] - 2025-12-12
### Added
- `c` [1.04.059]: Add a function.
  - dms2dms( <DEG>, <MIN>, <SEC> [, <DEG>, <MIN>, <SEC> ..] ) -> ( <DEG>, <MIN>, <SEC> [, <DEG>, <MIN>, <SEC> ..] ).

### Changed
- `c` [1.04.060]: Slightly corrected the notation of POD.

## [0.2.32] - 2025-12-11
### Changed
- `c` [1.04.057]: The arguments of dms2deg() have been made variable so that they can be processed together.
- `c` [1.04.056]: The arguments of rad2deg() and deg2dms() have been made variable so that they can be processed together.
- `c` [1.04.054]: When it is judged as "Could not interpret", the user-defined value is also output.
- `c` [1.04.053]: Added -u, --user-defined option to help display and POD.

## [0.2.31] - 2025-12-10
### Added
- Added "--version" option.
  - `fill` [1.01.002]
  - `mark` [1.02.002]

### Changed
- `c` [1.04.052]: The latitude and longitude format conversion section has been enhanced.
- `c` [1.04.051]: "TIME", which indicates the current time, was difficult to understand, so it was changed to use "NOW".
- Added "--version" option to help display and POD.
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
