jsonnet:
	docker build -t tmp-builder-$@ .
	rm -f $@.cid
	docker run --cidfile $@.cid tmp-builder-$@
	docker cp "$$(cat $@.cid):/dist/." ./
	docker rm "$$(cat $@.cid)" && rm -f $@.cid

clean:
	rm -rf *.deb
