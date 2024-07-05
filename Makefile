# Install project dependencies.
deps:
	bash scripts/install_deps.sh

# Create archives of files necessary to run the server and
# client standalone.
archives: deps
	bash scripts/archive_deps.sh

# Create executable files for end users.
executables: deps
	bash scripts/make_executables.sh

# Create installer for end user.
installer: archives executables
	bash scripts/make_installer.sh

# Process moby.
moby: deps
	bash scripts/moby.sh

# Process ipa-dict.
ipa-dict: deps
	bash scripts/ipa-dict.sh

# Process oxford.
oxford: deps
	bash scripts/oxford.sh

# Process roget 21st century.
roget21: deps
	bash scripts/roget_21st_century.sh

# Process roget international.
roget_international: deps
	bash scripts/roget_international_6E.sh

# Process roget new american.
roget_new_american: deps
	bash scripts/roget_new_american.sh

# Process wiktionary.
wiktionary: deps
	bash scripts/wiktionary.sh

# Process all datasets.
process_raw: moby ipa-dict oxford roget_international roget21 roget_new_american wiktionary
	echo done

#deps:
	#python, make_db
