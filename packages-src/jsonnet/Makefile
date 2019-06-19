build:
	docker build -t tmp-jsonnet-build .
	rm -f cid
	docker run --cidfile cid tmp-jsonnet-build
	docker cp "$$(cat cid):/build/jsonnet/output" ./
	mv -f output/*.deb ./
	rm -rf cid output
