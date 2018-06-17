FROM ubuntu:17.10

#FROM John Skelly Maker Docker

#installs perl and other dependencies for MAKER
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    nano \
    gcc-5 \
    g++-5 \
    libglib2.0-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#Download and install Perl dependencies
RUN  ["cpanm", "Error", "Error::Simple", "File::Which", "Inline", "Perl::Unsafe::Signals", "Proc::ProcessTable", "URI::Escape", "Bit::Vector", "Inline::C", "forks", "forks::shared", "IO::All", "DBD::SQLite", "IO::Prompt", "Text::Soundex"]

# Install Augustus (requires old compiler)
RUN wget http://bioinf.uni-greifswald.de/augustus/binaries/augustus-3.3.1.tar.gz \
    && tar -xvf augustus*.tar.gz \
    && rm augustus*.tar.gz \
    && cd augustus*/src \
    && make

#Download, extract and remove zip file for exonerate
RUN wget http://ftp.ebi.ac.uk/pub/software/vertebrategenomics/exonerate/exonerate-2.2.0-x86_64.tar.gz \
    && tar -xzf exonerate-2.2.0-x86_64.tar.gz \
    && rm exonerate-2.2.0-x86_64.tar.gz

#Download, extract and remove zip file for ncbi rmblast
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/rmblast/2.2.28/ncbi-rmblastn-2.2.28-x64-linux.tar.gz \
    && tar -xzf ncbi-rmblastn-2.2.28-x64-linux.tar.gz \
    && rm ncbi-rmblastn-2.2.28-x64-linux.tar.gz

#Download, extract and remove zip file for ncbi blast
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.7.1/ncbi-blast-2.7.1+-x64-linux.tar.gz \
    && tar -xzf ncbi-blast-2.7.1+-x64-linux.tar.gz \
    && rm ncbi-blast-2.7.1+-x64-linux.tar.gz \
    && cp -r ncbi-blast-2.7.1+/bin/* ncbi-rmblastn-2.2.28/bin

#Copy trf
COPY trf /RepeatMasker/

#Download and install repeat masker 
RUN wget http://www.repeatmasker.org/RepeatMasker-open-4-0-7.tar.gz \
    && tar -xzf RepeatMasker-open*.tar.gz \
    && rm -f RepeatMasker-open*.tar.gz \
    && cd RepeatMasker \
    && sed -e 's/\/usr\/local\/hmmer/\/usr\/bin/g;' \
        -e 's/\/usr\/local\/rmblast/\/ncbi-rmblastn-2.2.28\/bin/g;' \
        -e 's/DEFAULT_SEARCH_ENGINE = "crossmatch"/DEFAULT_SEARCH_ENGINE = "ncbi"/g;' \
        -e 's/TRF_PRGM = ""/TRF_PRGM = "\/RepeatMasker\/trf"/g;' \
        RepeatMaskerConfig.tmpl > RepeatMaskerConfig.pm

#Copy sequences for RepeatMasker
COPY Libraries /RepeatMasker/Libraries

#Download and instal mpich
RUN wget http://www.mpich.org/static/downloads/3.2.1/mpich-3.2.1.tar.gz \
    && tar -xzf mpich-3.2.1.tar.gz \
    && rm mpich-3.2.1.tar.gz \
    && cd mpich-3.2.1 \
    && ./configure --disable-fortran --enable-sharedlibs \
    && make \
    && make test \
    && make install

#update compiler
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 60 --slave /usr/bin/g++ g++ /usr/bin/g++-5

#Download and install snap
RUN wget --no-check-certificate https://launchpad.net/ubuntu/+archive/primary/+files/snap_2013-11-29.orig.tar.gz \
    && tar -xzf snap_2013-11-29.orig.tar.gz \
    && rm snap_2013-11-29.orig.tar.gz \
    && cd snap \
    && make

#set ZOE environment for snap
ENV ZOE="/snap/Zoe"

#exporting path not working
ENV PATH="$PATH:/exonerate-2.2.0-x86_64/bin:/ncbi-rmblastn-2.2.28/bin:/maker/bin:/RepeatMasker:/snap:/maker/bin:/home/projects/src:"

#Download and install maker
RUN wget http://yandell.topaz.genetics.utah.edu/maker_downloads/EDD0/9498/2D2F/195FF7F5C137C2ADB96B8F1F1EEB/maker-2.31.9.tgz \
    && tar -xzf maker-2.31.9.tgz \
    && rm maker-2.31.9.tgz \
    && cd maker/src \
    && echo y| perl Build.PL \
    && ./Build install

#Copy in control files for maker
#COPY ctl /home/projects/ctl

#Copy in data and ctl for maker
COPY data /home/projects/data
COPY ctl /home/projects/ctl
COPY src /home/projects/src

#Fix perl directory for RepeatMasker
RUN cd /RepeatMasker \
	&& perl -i -0pe 's/^#\!.*perl.*/#\!\/usr\/bin\/env perl/g' \
	RepeatMasker \
    DateRepeats \
    ProcessRepeats \
    RepeatProteinMask \
    DupMasker \
    util/queryRepeatDatabase.pl \
    util/queryTaxonomyDatabase.pl \
    util/rmOutToGFF3.pl \
    util/rmToUCSCTables.pl

#Change embl library format and create blast directories for RepeatMasker
RUN cd RepeatMasker \
#    && util/buildRMLibFromEMBL.pl Libraries/RMRBSeqs.embl > Libraries/RepeatMasker.lib 2>/dev/null \
    && /ncbi-rmblastn-2.2.28/bin/makeblastdb -dbtype nucl -in Libraries/RepeatMasker.lib > /dev/null 2>&1 \
    && /ncbi-rmblastn-2.2.28/bin/makeblastdb -dbtype prot -in Libraries/RepeatPeps.lib > /dev/null 2>&1

