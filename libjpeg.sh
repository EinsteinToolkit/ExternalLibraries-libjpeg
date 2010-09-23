#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
set -x                          # Output commands
set -e                          # Abort on errors

# Set locations
NAME=jpeg-8b
SRCDIR=$(dirname $0)
INSTALL_DIR=${SCRATCH_BUILD}
LIBJPEG_DIR=${INSTALL_DIR}/${NAME}

# Clean up environment
unset LIBS



################################################################################
# Build
################################################################################

(
    exec >&2                    # Redirect stdout to stderr
    set -x                      # Output commands
    set -e                      # Abort on errors
    cd ${INSTALL_DIR}
    if [ -e done-${NAME} -a done-${NAME} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a done-${NAME} -nt ${SRCDIR}/libjpeg.sh ]
    then
        echo "libjpeg: The enclosed libjpeg library has already been built; doing nothing"
    else
        echo "libjpeg: Building enclosed libjpeg library"
        
        # Should we use gmake or make?
        MAKE=$(gmake --help > /dev/null 2>&1 && echo gmake || echo make)
        
        echo "libjpeg: Unpacking archive..."
        rm -rf build-${NAME}
        mkdir build-${NAME}
        pushd build-${NAME}
        # Should we use gtar or tar?
        TAR=$(gtar --help > /dev/null 2> /dev/null && echo gtar || echo tar)
        ${TAR} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        popd
        
        echo "libjpeg: Configuring..."
        rm -rf ${NAME}
        mkdir ${NAME}
        pushd build-${NAME}/${NAME}
        ./configure --prefix=${LIBJPEG_DIR}
        
        echo "libjpeg: Building..."
        ${MAKE}
        
        echo "libjpeg: Installing..."
        ${MAKE} install
        popd
        
        echo 'done' > done-${NAME}
        echo "libjpeg: Done."
    fi
)

if (( $? )); then
    echo 'BEGIN ERROR'
    echo 'Error while building libjpeg.  Aborting.'
    echo 'END ERROR'
    exit 1
fi



################################################################################
# Configure Cactus
################################################################################

# Set options
LIBJPEG_INC_DIRS="${LIBJPEG_DIR}/include"
LIBJPEG_LIB_DIRS="${LIBJPEG_DIR}/lib"
LIBJPEG_LIBS='jpeg'

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "HAVE_LIBJPEG     = 1"
echo "LIBJPEG_DIR      = ${LIBJPEG_DIR}"
echo "LIBJPEG_INC_DIRS = ${LIBJPEG_INC_DIRS}"
echo "LIBJPEG_LIB_DIRS = ${LIBJPEG_LIB_DIRS}"
echo "LIBJPEG_LIBS     = ${LIBJPEG_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(LIBJPEG_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(LIBJPEG_LIB_DIRS)'
echo 'LIBRARY           $(LIBJPEG_LIBS)'
