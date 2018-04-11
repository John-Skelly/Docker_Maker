FROM ubuntu:17.10

#FROM robsyme/repeatmasker-onbuild

#installs perl dependencies for MAKER
RUN apt-get update && apt-get install -y \
    build-essential \
    cpanminus \
    libfile-nfslock-perl \
    libperlio-gzip-perl \
    libtest-deep-perl \
    libtest-utf8-perl \
    libbio-perl-perl \
    hmmer \
    wget \
    libboost-iostreams-dev \
    zlib1g-dev \
    libgsl-dev \
    libsqlite3-dev \
    libboost-graph-dev \
    libsuitesparse-dev \
    liblpsolve55-dev \
    bamtools \
    libbamtools-dev \
    nano

RUN  ["cpanm", "Error", "Error::Simple", "File::Which", "Inline", "Perl::Unsafe::Signals", "Proc::ProcessTable", "URI::Escape", "Bit::Vector", "Inline::C", "forks", "forks::shared", "IO::All", "DBD::SQLite", "IO::Prompt"]

# Install Augustus
RUN wget http://bioinf.uni-greifswald.de/augustus/binaries/augustus.current.tar.gz \
    && tar -xvf augustus*.tar.gz \
    && rm augustus*.tar.gz \
    && cd augustus \
    && echo "COMPGENEPRED = true" >> common.mk \
    && make \
    && make install

ENV AUGUSTUS_CONFIG_PATH="/usr/local/augustus/config"

#download, extract and remove zip file for SNAP
RUN wget http://snap.cs.berkeley.edu/downloads/snap-0.15.4-linux.tar.gz \
    && tar -xzf snap-0.15.4-linux.tar.gz \
    && rm snap-0.15.4-linux.tar.gz

ENV ZOE="snap-0.15.4-linux/Zoe"

#download, extract and remove zip file for exonerate
RUN wget http://ftp.ebi.ac.uk/pub/software/vertebrategenomics/exonerate/exonerate-2.2.0-x86_64.tar.gz \
    && tar -xzf exonerate-2.2.0-x86_64.tar.gz \
    && rm exonerate-2.2.0-x86_64.tar.gz

#download, extract and remove zip file for ncbi rmblast
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/rmblast/2.2.28/ncbi-rmblastn-2.2.28-x64-linux.tar.gz \
    && tar -xzf ncbi-rmblastn-2.2.28-x64-linux.tar.gz \
    && rm ncbi-rmblastn-2.2.28-x64-linux.tar.gz

#Download, extract and remove zip file for ncbi blast
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.7.1/ncbi-blast-2.7.1+-x64-linux.tar.gz \
    && tar -xzf ncbi-blast-2.7.1+-x64-linux.tar.gz \
    && rm ncbi-blast-2.7.1+-x64-linux.tar.gz \
    && cp -r ncbi-blast-2.7.1+/bin/* ncbi-rmblastn-2.2.28/bin

#Download and move trf
COPY trf /RepeatMasker/

#Download and install repeat masker 
RUN wget http://www.repeatmasker.org/RepeatMasker-open-4-0-7.tar.gz \
    && tar -xzf RepeatMasker-open*.tar.gz \
	&& rm -f RepeatMasker-open*.tar.gz #\
#	&& perl -0p -e 's/\/usr\/local\/hmmer/\/usr\/bin/g;' \
#	-e 's/\/usr\/local\/rmblast/\/ncbi-rmblastn-2.2.28\/bin/g;' \
#    -e 's/DEFAULT_SEARCH_ENGINE = "crossmatch"/DEFAULT_SEARCH_ENGINE = "ncbi"/g;' \
#    -e 's/TRF_PRGM = ""/TRF_PRGM = "\/RepeatMasker\/trf"/g;' RepeatMasker/RepeatMaskerConfig.tmpl > RepeatMasker/RepeatMaskerConfig.pm

#Copy sequences for repeat masker
COPY RepBaseRepeatMaskerEdition-20170127 /RepeatMasker/

#RepeatMaskerConfig.pm patch
COPY RepeatMaskerConfig.pm /RepeatMasker/
RUN chmod +x /RepeatMasker/RepeatMaskerConfig.pm

#Download and instal mpich
RUN wget http://www.mpich.org/static/downloads/3.2.1/mpich-3.2.1.tar.gz \
    && tar -xzf mpich-3.2.1.tar.gz \
    && rm mpich-3.2.1.tar.gz \
    && cd mpich-3.2.1 \
    && ./configure --disable-fortran \
    && make \
    && make test \
    && make install

#exporting path not working
ENV PATH="$PATH:/exonerate-2.2.0-x86_64/bin:/snap-0.15.4-linux:/ncbi-blast-2.7.1+/bin:/ncbi-rmblastn-2.2.28/bin:/maker/bin:/RepeatMasker:/snap-0.15.4-linux:/maker/bin:"

RUN wget http://yandell.topaz.genetics.utah.edu/maker_downloads/EDD0/9498/2D2F/195FF7F5C137C2ADB96B8F1F1EEB/maker-2.31.9.tgz \
    && tar -xzf maker-2.31.9.tgz \
    && rm maker-2.31.9.tgz \
    && cd maker/src \
    && echo y| perl Build.PL \
    && ./Build install

Run mkdir /home/projects

Run mkdir /cifs

