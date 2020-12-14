# Use busybox for downloading/extracting the XLink Kai Engine
FROM	busybox:latest AS download

# Define our working directory
WORKDIR	/kaiEngine/

# Declare the current downloads page URL and regular expression used to extract the *.debian.x86_64.tar.gz URL from that source code.
ARG	Download_Page="https://www.teamxlink.co.uk/downloads.php"
ARG	Download_RegEx="s|^.*document\.downloadGet\.action *= *\"\(https://cdn\.teamxlink\.co\.uk/binary/kaiEngine-.*\.debian\.x86_64\.tar\.gz\)\".*$|\1|p"
# Check downloads page for most recent Debian x86-64 tar.gz file, then download/extract that package.
RUN	Download_URL="$(wget "${Download_Page}" -O- |sed -n "${Download_RegEx}")"	\
	&& echo "Download URL:  ${Download_URL}"	\
	&& wget "${Download_URL}" -O- |tar zxv --strip-components=1
# The above method should work for future version releases as long as the main source code on "downloads.php" stays consistent.


# Build from scratch for smallest possible secure build.
FROM	scratch

# Copy required libraries directly from the debian:stable-slim image.
# Most of the libraries below can be found using ldd on the executable.
# However in practice, 3 additional libraries are also required for the executable to run:
# /lib/x86_64-linux-gnu/libnss_dns.so.2
# /lib/x86_64-linux-gnu/libnss_files.so.2
# /lib/x86_64-linux-gnu/libresolv.so.2
COPY	--from=debian:stable-slim	\
		/lib64/ld-linux-x86-64.so.2	\
		/lib64/
COPY	--from=debian:stable-slim	\
		/lib/x86_64-linux-gnu/libc.so.6	\
		/lib/x86_64-linux-gnu/libdl.so.2	\
		/lib/x86_64-linux-gnu/libgcc_s.so.1	\
		/lib/x86_64-linux-gnu/libm.so.6	\
		/lib/x86_64-linux-gnu/libnss_dns.so.2	\
		/lib/x86_64-linux-gnu/libnss_files.so.2	\
		/lib/x86_64-linux-gnu/libpthread.so.0	\
		/lib/x86_64-linux-gnu/libresolv.so.2	\
		/lib/x86_64-linux-gnu/librt.so.1	\
		/usr/lib/x86_64-linux-gnu/libstdc++.so.6	\
		/lib/

# Copy custom minimal services file into image.  This file only contains the line read for the HTTP service.
COPY	services /etc/services

# Copy the files downloaded/extracted from the download stage.
COPY	--from=download /kaiEngine/ /kaiEngine/

# Set the working directory.
# This is now set to the original configuration directory, as the new version (7.4.35) of kaiEngine now stores it's config files to the working directory.
WORKDIR	/root/.xlink/

# Location where configuration files will be read/saved.
VOLUME	["/root/.xlink/"]

# Expose the default port used by this program.
EXPOSE	34522/tcp

# Set the executable as the entrypoint.
ENTRYPOINT	["/kaiEngine/kaiengine"]

# Set the Stop Signal to SIGINT to safely stop the process.
STOPSIGNAL	SIGINT

