#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors

if [ -z "${LIBJPEG_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "LIBJPEG selected, but LIBJPEG_DIR not set. Checking some places..."
    echo "END MESSAGE"
    
    FILES="include/jpeglib.h"
    DIRS="/usr /usr/local ${HOME}"
    for dir in $DIRS; do
        LIBJPEG_DIR="$dir"
        for file in $FILES; do
            if [ ! -r "$dir/$file" ]; then
                unset LIBJPEG_DIR
                break
            fi
        done
        if [ -n "$LIBJPEG_DIR" ]; then
            break
        fi
    done
    
    if [ -z "$LIBJPEG_DIR" ]; then
        echo "BEGIN MESSAGE"
        echo "LIBJPEG not found"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Found LIBJPEG in ${LIBJPEG_DIR}"
        echo "END MESSAGE"
    fi
fi


################################################################################
# Build
################################################################################

if [ -z "${LIBJPEG_DIR}"                                                \
     -o "$(echo "${LIBJPEG_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]
then
    echo "BEGIN MESSAGE"
    echo "Building libjpeg..."
    echo "END MESSAGE"

    # Set locations
    THORN=libjpeg
    NAME=jpeg-8c
    SRCDIR=$(dirname $0)
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${LIBJPEG_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing libjpeg into ${LIBJPEG_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${LIBJPEG_INSTALL_DIR}
    fi
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    LIBJPEG_DIR=${INSTALL_DIR}
    
    if [ -e ${DONE_FILE} -a ${DONE_FILE} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a ${DONE_FILE} -nt ${SRCDIR}/configure.sh ]
    then
        echo "BEGIN MESSAGE"
        echo "libjpeg has already been built; doing nothing"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Building libjpeg library"
        echo "END MESSAGE"
        
        # Build in a subshell
        (
        exec >&2                # Redirect stdout to stderr
        if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
            set -x              # Output commands
        fi
        set -e                  # Abort on errors
        cd ${SCRATCH_BUILD}
        
        # Set up environment
        unset LIBS
        if echo '' ${ARFLAGS} | grep 64 > /dev/null 2>&1; then
            export OBJECT_MODE=64
        fi
        
        echo "libjpeg: Preparing directory structure..."
        mkdir build external done 2> /dev/null || true
        rm -rf ${BUILD_DIR} ${INSTALL_DIR}
        mkdir ${BUILD_DIR} ${INSTALL_DIR}

        echo "libjpeg: Unpacking archive..."
        pushd ${BUILD_DIR}
        ${TAR} xzf ${SRCDIR}/dist/${NAME}.tar.gz

        echo "libjpeg: Configuring..."
        cd ${NAME}
        ./configure --prefix=${LIBJPEG_DIR}
        
        echo "libjpeg: Building..."
        ${MAKE}
        
        echo "libjpeg: Installing..."
        ${MAKE} install
        popd
        
        echo "libjpeg: Cleaning up..."
        rm -rf ${BUILD_DIR}

        date > ${DONE_FILE}
        echo "libjpeg: Done."
        
        )
        
        if (( $? )); then
            echo 'BEGIN ERROR'
            echo 'Error while building libjpeg. Aborting.'
            echo 'END ERROR'
            exit 1
        fi
    fi
    
fi



################################################################################
# Configure Cactus
################################################################################

# Set options
if [ "${LIBJPEG_DIR}" = '/usr' -o "${LIBJPEG_DIR}" = '/usr/local' ]; then
    LIBJPEG_INC_DIRS=''
    LIBJPEG_LIB_DIRS=''
else
    LIBJPEG_INC_DIRS="${LIBJPEG_DIR}/include"
    LIBJPEG_LIB_DIRS="${LIBJPEG_DIR}/lib"
fi
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
