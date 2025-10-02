# Change Log

## [Unreleased]
### Changed
- xxx

## [0.2.1] - 2025-10-02
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
