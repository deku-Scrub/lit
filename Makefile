deps:
	bash scripts/package_deps.sh

dbdump:
	bash scripts/dump_db.sh

executables:
	bash scripts/make_executables.sh

release: deps dbdump executables
	bash scripts/commit_release.sh

reqs:
	bash scripts/server_prereqs.sh
