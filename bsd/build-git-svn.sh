#!/usr/bin/env bash
# Installs git and git-svn into your home directory (in ~/.local).
# After installation please put ~/.local/bin into your PATH.

set -e -x

PREFIX=$HOME/.local          # installation directory
BUILD_DIR=$HOME/.build-dir   # source tarballs and builds will be here

export PATH=$PREFIX/bin:$PATH
export LIBRARY_PATH=$PREFIX/lib
export LD_LIBRARY_PATH=$PREFIX/lib
export CPATH=$PREFIX/include
export CC=gcc
export CXX=g++
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath=$PREFIX/lib"

function has () {
  which $1 >/dev/null 2>/dev/null
}

function download () {
  local pkg=$(basename "$1")

  if [ -e "$pkg" ]; then
    return 0
  fi

  for attempt in 1 2 3 4 5; do
    rm -f "$pkg" "$pkg.tmp"
    if has curl; then
      curl -L -o "$pkg.tmp" "$1" || continue
    elif has wget; then
      wget -O "$pkg.tmp" "$1" || continue
    else
      fetch -o "$pkg.tmp" "$1" || continue
    fi
    mv -f "$pkg.tmp" "$pkg"
    return 0
  done

  echo "Failed to download $1"
  return 1
}

function was_installed () {
  fgrep -x "$1" $PREFIX/installed >/dev/null 2>&1 && return 0
  return 1
}

function mark_installed () {
  echo "$1" >>$PREFIX/installed
}

function simplebuild () {
  local url="$1"
  local pkg=`basename "$url" | sed -e 's/[.]tar[.]gz$//' | sed -e 's/[.]tar[.]bz2$//'`
  if was_installed $pkg; then
    return 0
  fi
  if [ "$url" != $(basename "$url") ]; then
    download "$url"
  fi
  rm -rf "$pkg"
  tar xf `basename $url`
  cd $pkg
  ./configure --prefix=$PREFIX --disable-nls $CONF
  make -j 5
  make install
  cd ..
  rm -rf $pkg
  mark_installed $pkg
}

#rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

mkdir -p $PREFIX
if [ ! -e $PREFIX/share ]; then
  mkdir -p $PREFIX/share $PREFIX/man $PREFIX/lib/perl
  ln -s ../man $PREFIX/share/man
  ln -s ../lib/perl $PREFIX/share/perl
fi

# prefer gnu tools instead of bsd's
if [ `uname` = "FreeBSD" ]; then
  for tool in make m4 seq; do
    if has g$tool; then
      if [ ! -e $PREFIX/bin/$tool ]; then
        mkdir -p $PREFIX/bin
        ln -s `which g$tool || true` $PREFIX/bin/$tool
      fi
    fi
  done

  if ! has gmake; then
    simplebuild http://ftp.gnu.org/gnu/make/make-3.82.tar.bz2
  fi

  hash make
fi

if ! was_installed openssl-0.9.8q; then
  download http://www.openssl.org/source/openssl-0.9.8q.tar.gz
  rm -rf openssl-0.9.8q
  tar xf openssl-0.9.8q.tar.gz
  cd openssl-0.9.8q
  ./config --openssldir=$PREFIX/etc/ssl --prefix=$PREFIX no-shared
  make
  make install
  rm -rf $PREFIX/etc
  make clean
  ./config --openssldir=$PREFIX/etc/ssl --prefix=$PREFIX shared
  make
  make install
  cd ..
  rm -rf openssl-0.9.8q
  rm -rf $PREFIX/etc/ssl/man
  mark_installed openssl-0.9.8q
fi

# TODO: zlib, berkeley db, perl with dev libs
# but they seem to have been installed on dev machines

simplebuild http://surfnet.dl.sourceforge.net/sourceforge/expat/expat-2.0.1.tar.gz

CONF="--enable-static --enable-shared --with-openssl=$PREFIX" \
simplebuild http://curl.haxx.se/download/curl-7.21.3.tar.bz2

# git: requires expat, curl, openssl
if [ "`uname`" = "FreeBSD" ]; then
  CONF="--with-openssl --with-expat --with-curl" LDFLAGS="$LDFLAGS -static" \
  simplebuild http://www.kernel.org/pub/software/scm/git/git-1.7.3.4.tar.bz2
else
  # for some reason it doesn't build statically on linux
  CONF="--with-openssl --with-expat --with-curl" LDFLAGS="$LDFLAGS" \
  simplebuild http://www.kernel.org/pub/software/scm/git/git-1.7.3.4.tar.bz2
fi

simplebuild http://sourceforge.net/projects/pcre/files/pcre/8.11/pcre-8.11.tar.bz2
rm -rf $PREFIX/share/doc/pcre

CONF="--with-pcre-prefix=$PREFIX" LDFLAGS="$LDFLAGS -lpcre" \
simplebuild http://prdownloads.sourceforge.net/swig/swig-2.0.1.tar.gz  # requires pcre

CONF="--with-ssl=openssl" simplebuild http://www.webdav.org/neon/neon-0.29.5.tar.gz  # requires openssl
rm -rf $PREFIX/share/doc/neon-0.29.5

# subversion
if ! was_installed subversion-1.6.11; then
  download http://subversion.tigris.org/downloads/subversion-1.6.11.tar.bz2
  download http://www.sqlite.org/sqlite-amalgamation-3.6.13.tar.gz
  download http://www.apache.org/dist/apr/apr-1.4.2.tar.bz2
  download http://www.apache.org/dist/apr/apr-util-1.3.10.tar.bz2
  rm -rf subversion-1.6.11
  tar xf subversion-1.6.11.tar.bz2
  cd subversion-1.6.11
  tar xf ../sqlite-amalgamation-3.6.13.tar.gz; mv sqlite-3.6.13 sqlite-amalgamation
  tar xf ../apr-1.4.2.tar.bz2; mv apr-1.4.2 apr
  tar xf ../apr-util-1.3.10.tar.bz2; mv apr-util-1.3.10 apr-util
  ./configure --prefix=$PREFIX --disable-nls --with-ssl -enable-swig-bindings=perl --with-neon=$PREFIX
  make -j 5 all
  make install
  make swig-pl
  cp subversion/bindings/swig/perl/native/Makefile subversion/bindings/swig/perl/native/Makefile.bak
  cat subversion/bindings/swig/perl/native/Makefile.bak |
    sed -e "s@^INSTALL\(.*\) = /usr/local/@INSTALL\1 = $PREFIX/@" |
    sed -e "s@^INSTALL\(.*\) = \$(PERLPREFIX)@INSTALL\1 = $PREFIX/@" |
    sed -e "s@^INSTALL\(.*\) = \$(SITEPREFIX)@INSTALL\1 = $PREFIX/@" |
    sed -e "s@^INSTALL\(.*\) = \$(VENDORPREFIX)@INSTALL\1 = $PREFIX/@" |
    cat >subversion/bindings/swig/perl/native/Makefile
  make install-swig-pl
  cd ..
  rm -rf subversion-1.6.11
  mark_installed subversion-1.6.11
fi

# fix paths in git-svn script, apply performance patch
if ! was_installed git-svn-patch; then
  cd $PREFIX/libexec/git-core
  cp git-svn git-svn.bak
  sed -e 's|^use lib\(.*\)"\([^"]*\)"));$|use lib\1"\2:\2/mach"));|' <git-svn.bak >git-svn
  patch <<"EOF"
--- git-svn
+++ git-svn
@@ -3510,6 +3510,7 @@ sub rebuild {
 	my ($self) = @_;
 	my $map_path = $self->map_path;
 	my $partial = (-e $map_path && ! -z $map_path);
+	delete $self->{_rev_map_max_cached};
 	return unless ::verify_ref($self->refname.'^0');
 	if (!$partial && ($self->use_svm_props || $self->no_metadata)) {
 		my $rev_db = $self->rev_db_path;
@@ -3655,6 +3656,7 @@ sub rev_map_set {
 	my ($self, $rev, $commit, $update_ref, $uuid) = @_;
 	defined $commit or die "missing arg3\n";
 	length $commit == 40 or die "arg3 must be a full SHA1 hexsum\n";
+	delete $self->{_rev_map_max_cached};
 	my $db = $self->map_path($uuid);
 	my $db_lock = "$db.lock";
 	my $sig;
@@ -3714,9 +3716,18 @@ sub rev_map_max {
 	my ($self, $want_commit) = @_;
 	$self->rebuild;
 	my ($r, $c) = $self->rev_map_max_norebuild($want_commit);
+	$self->{_rev_map_max_cached} = $r;
 	$want_commit ? ($r, $c) : $r;
 }
 
+sub rev_map_max_cached {
+	my ($self) = @_;
+	if (!defined $self->{_rev_map_max_cached}) {
+		$self->rev_map_max;
+	}
+	$self->{_rev_map_max_cached};
+}
+
 sub rev_map_max_norebuild {
 	my ($self, $want_commit) = @_;
 	my $map_path = $self->map_path;
@@ -3746,6 +3757,7 @@ sub rev_map_max_norebuild {
 		}
 	}
 	close $fh or croak "close: $!";
+	$self->{_rev_map_max_cached} = $r;
 	$want_commit ? ($r, $c) : $r;
 }
 
@@ -5162,11 +5174,15 @@ sub gs_do_switch {
 }
 
 sub longest_common_path {
-	my ($gsv, $globs) = @_;
+	my ($gsv, $globs, $max_rev_needed) = @_;
 	my %common;
 	my $common_max = scalar @$gsv;
 
 	foreach my $gs (@$gsv) {
+		if ($gs->rev_map_max_cached > $max_rev_needed) {
+			$common_max--;
+			next;
+		}
 		my @tmp = split m#/#, $gs->{path};
 		my $p = '';
 		foreach (@tmp) {
@@ -5202,13 +5218,15 @@ sub gs_fetch_loop_common {
 	return if ($base > $head);
 	my $inc = $_log_window_size;
 	my ($min, $max) = ($base, $head < $base + $inc ? $head : $base + $inc);
-	my $longest_path = longest_common_path($gsv, $globs);
 	my $ra_url = $self->{url};
 	my $find_trailing_edge;
+
 	while (1) {
+		my $longest_path = longest_common_path($gsv, $globs, $max);
 		my %revs;
 		my $err;
 		my $err_handler = $SVN::Error::handler;
+		print "Checking $ra_url/$longest_path\@r$min..r$max\r\n";
 		$SVN::Error::handler = sub {
 			($err) = @_;
 			skip_unknown_revs($err);
@@ -5220,9 +5238,7 @@ sub gs_fetch_loop_common {
 		}
 		$self->get_log([$longest_path], $min, $max, 0, 1, 1,
 		               sub { $revs{$_[1]} = _cb(@_) });
-		if ($err) {
-			print "Checked through r$max\r";
-		} else {
+		if (!$err) {
 			$find_trailing_edge = 1;
 		}
 		if ($err and $find_trailing_edge) {
@@ -5254,9 +5270,7 @@ sub gs_fetch_loop_common {
 
 			foreach my $gs ($self->match_globs(\%exists, $paths,
 			                                   $globs, $r)) {
-				if ($gs->rev_map_max >= $r) {
-					next;
-				}
+				next if $gs->rev_map_max_cached >= $r;
 				next unless $gs->match_paths($paths, $r);
 				$gs->{logged_rev_props} = $logged;
 				if (my $last_commit = $gs->last_commit) {
EOF

  cd $BUILD_DIR
  mark_installed git-svn-patch
fi

# git manual
download http://www.kernel.org/pub/software/scm/git/git-manpages-1.7.3.4.tar.bz2
(cd $PREFIX/man && tar xf $BUILD_DIR/git-manpages-1.7.3.4.tar.bz2)

#cd ~; rm -rf $BUILD_DIR
echo "All done. Please put $HOME/.local into your \$PATH and consider cleaning the build directory $BUILD_DIR now."

# vim: noet
