
dist_bin_SCRIPTS = fill hello.pl hello.sh

EXTRA_DIST = LICENSE docs/CATALOG.md docs/devel_step_0.dot docs/devel_step_0_1.dot docs/devel_step_1_1.dot docs/devel_step_1_2.dot docs/devel_step_1_3.dot docs/devel_step_1_4.dot docs/README_dir_struct.dot docs/devel_step_0.svg docs/devel_step_0_1.svg docs/devel_step_1_1.svg docs/devel_step_1_2.svg docs/devel_step_1_3.svg docs/devel_step_1_4.svg docs/README_dir_struct.svg docs/fill.md docs/hello.pl.md docs/hello.sh.md docs/gen_autotools_acam.pl.md docs/GenAutotoolsAcAm_UserFile.pm.md docs/create_CATALOG.sh.md tools/gen_autotools_acam.pl tools/GenAutotoolsAcAm_UserFile.pm tools/create_CATALOG.sh

SUBDIRS = tests

docs/CATALOG.md: $(dist_bin_SCRIPTS) tools/gen_autotools_acam.pl tools/GenAutotoolsAcAm_UserFile.pm tools/create_CATALOG.sh
	$(builddir)/tools/create_CATALOG.sh docs/CATALOG.md $^

.PHONY: catalog
catalog: docs/CATALOG.md ;

docs/%.svg: docs/%.dot
	dot -Kdot -Tsvg $< -o $@

dist-hook: catalog ;
