all: no-skip-ink.crx chromium-no-skip-ink_1.0_all.deb

no-skip-ink.crx: no-skip-ink/*
	rm -f no-skip-ink.crx no-skip-ink.pem
	chromium --pack-extension=no-skip-ink
	rm -f no-skip-ink.pem

chromium-no-skip-ink_1.0_all.deb: no-skip-ink/* control
	equivs-build control
