# Base image used for downloading/extracting the main binary and library dependencies.
FROM	debian:stable-slim AS builder
ARG	DEBIAN_FRONTEND="noninteractive"

# Install required packages and i386 libraries.
# The package netbase is installed for grabbing the /etc/services file.
RUN	dpkg --add-architecture i386	\
	&& apt-get update	\
	&& apt-get install -y --no-install-recommends	\
		libc6:i386	\
		libstdc++6:i386	\
		libgcc-8-dev:i386	\
		ca-certificates	\
		curl	\
		netbase	\
	&& rm -rf /var/lib/apt/lists/*

# Primary download URL for the XLink Kai Engine.
# Version 7.4.35 was released Mar 24, 2020 and is current as of Apr 3, 2020.
ARG	Download_URL="https://cdn.teamxlink.co.uk/binary/kaiEngine-7.4.35-534304365.headless.el6.i686.tar.gz"

# Download, extract and mark as executable.
RUN	curl "${Download_URL}" | tar zxv	\
	&& mv -iv kaiEngine-* /kaiEngine	\
	&& chmod +x kaiEngine/kaiengine


# Build from scratch for smallest possible secure build.
FROM	scratch

# Copy required libraries from the builder target.
# Most of the libraries below can be found using ldd on the executable.
# However in practice, 3 additional libraries are also required for the executable to run:
# /lib/i386-linux-gnu/libnss_dns.so.2
# /lib/i386-linux-gnu/libnss_files.so.2
# /lib/i386-linux-gnu/libresolv.so.2
COPY	--from=builder	\
		/lib/ld-linux.so.2	\
		/lib/i386-linux-gnu/libc.so.6	\
		/lib/i386-linux-gnu/libdl.so.2	\
		/lib/i386-linux-gnu/libgcc_s.so.1	\
		/lib/i386-linux-gnu/libm.so.6	\
		/lib/i386-linux-gnu/libnss_dns.so.2	\
		/lib/i386-linux-gnu/libnss_files.so.2	\
		/lib/i386-linux-gnu/libpthread.so.0	\
		/lib/i386-linux-gnu/libresolv.so.2	\
		/lib/i386-linux-gnu/librt.so.1	\
		/usr/lib/i386-linux-gnu/libstdc++.so.6	\
		/lib/

# Copy services file into image.
COPY	--from=builder /etc/services /etc/

# Copy the files downloaded/extracted from the builder target.
COPY	--from=builder /kaiEngine/ /bin/

# Set the working directory.
# This is now set to the original configuration directory, as the new version (7.4.35) of kaiEngine now stores it's config files to the working directory.
WORKDIR	/root/.xlink/

# Expose the default port used by this program.
EXPOSE	34522/tcp

# Location where configuration files will be read/saved.
VOLUME	["/root/.xlink/"]

# Set the executable as the entrypoint.
ENTRYPOINT	["/bin/kaiengine"]

# Set the Stop Signal to SIGINT to safely stop the process.
STOPSIGNAL	SIGINT

