

dist_bin_SCRIPTS = fill hello.pl hello.sh

EXTRA_DIST = ChangeLog.md LICENSE README.md docs/CATALOG.md docs/fill.md docs/hello.pl.md docs/hello.sh.md docs/gen_autotools_acam.pl.md docs/GenAutotoolsAcAm_UserFile.pm.md docs/create_CATALOG.sh.md docs/README_dir_struct.dot docs/README_dir_struct.svg tools/gen_autotools_acam.pl tools/GenAutotoolsAcAm_UserFile.pm tools/create_CATALOG.sh

SUBDIRS = tests

docs/CATALOG.md: $(dist_bin_SCRIPTS) tools/gen_autotools_acam.pl tools/GenAutotoolsAcAm_UserFile.pm tools/create_CATALOG.sh
	$(builddir)/tools/create_CATALOG.sh docs/CATALOG.md $^

.PHONY: catalog
catalog: docs/CATALOG.md ;

dist-hook: catalog ;
