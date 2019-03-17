#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors

. $CCTK_HOME/lib/make/bash_utils.sh

################################################################################
# Search
################################################################################

# Take care of requests to build the library in any case
LIBJPEG_DIR_INPUT=$LIBJPEG_DIR
if [ "$(echo "${LIBJPEG_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]; then
    LIBJPEG_BUILD=yes
    LIBJPEG_DIR=
else
    LIBJPEG_BUILD=
fi

# Try to find the library if build isn't explicitly requested
if [ -z "${LIBJPEG_BUILD}" ]; then
    find_lib LIBJPEG jpeg 1 1.0 "jpeg" "jpeglib.h" "${LIBJPEG_DIR_INPUT}"
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

    # check for required tools. Do this here so that we don't require them when
    # using the system library
    if [ x$TAR = x ] ; then
      echo 'BEGIN ERROR'
      echo 'Could not find tar command. Please make sure that (gnu) tar is present'
      echo 'and that the TAR variable is set to its location.'
      echo 'END ERROR'
      exit 1
    fi
    #if [ x$PATCH = x ] ; then
    #  echo 'BEGIN ERROR'
    #  echo 'Could not find patch command. Please make sure that (gnu) tar is present'
    #  echo 'and that the PATCH variable is set to its location.'
    #  echo 'END ERROR'
    #  exit 1
    #fi

    # Set locations
    THORN=libjpeg
    NAME=jpeg-8c
    SRCDIR="$(dirname $0)"
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
        ${TAR?} xzf ${SRCDIR}/dist/${NAME}.tar.gz

        echo "libjpeg: Configuring..."
        cd ${NAME}
        # we force libdir so that it does not switch between lib and lib64 on
        # some archs which is annoying since we use it later on
        ./configure --prefix=${LIBJPEG_DIR} --enable-shared=no --libdir=${LIBJPEG_DIR}/lib
        
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

        # Set options
        LIBJPEG_INC_DIRS="${LIBJPEG_DIR}/include"
        LIBJPEG_LIB_DIRS="${LIBJPEG_DIR}/lib"
        LIBJPEG_LIBS='jpeg'
    fi
    
fi



################################################################################
# Configure Cactus
################################################################################

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "LIBJPEG_DIR      = ${LIBJPEG_DIR}"
echo "LIBJPEG_INC_DIRS = ${LIBJPEG_INC_DIRS}"
echo "LIBJPEG_LIB_DIRS = ${LIBJPEG_LIB_DIRS}"
echo "LIBJPEG_LIBS     = ${LIBJPEG_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(LIBJPEG_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(LIBJPEG_LIB_DIRS)'
echo 'LIBRARY           $(LIBJPEG_LIBS)'
