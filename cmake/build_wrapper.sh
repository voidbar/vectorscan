#!/bin/sh -e
# This is used for renaming symbols for the fat runtime, don't call directly
# TODO: make this a lot less fragile!
cleanup () {
    rm -f ${SYMSFILE} ${KEEPSYMS}
}

NM="${NM:-nm}"
OBJCOPY="${OBJCOPY:-objcopy}"
OBJDUMP="${OBJDUMP:-objdump}"

PREFIX=$1
KEEPSYMS_IN=$2
shift 2
# $@ contains the actual build command

# Detect MinGW environment
IS_MINGW=0
case "$@" in
    *mingw*) IS_MINGW=1 ;;
esac

# Extract output file - handle both .o and .obj extensions
if [ $IS_MINGW -eq 1 ]; then
    OUT=$(echo "$@" | rev | cut -d ' ' -f 2- | rev | sed 's/.* -o \(.*\.obj\).*/\1/')
else
    OUT=$(echo "$@" | rev | cut -d ' ' -f 2- | rev | sed 's/.* -o \(.*\.o\).*/\1/')
fi

trap cleanup INT QUIT EXIT
SYMSFILE=$(mktemp -p /tmp ${PREFIX}_rename.syms.XXXXX)
KEEPSYMS=$(mktemp -p /tmp keep.syms.XXXXX)

NM_FLAG="-f"
if [ `uname` = "FreeBSD" ]; then
    # for freebsd, we will specify the name,
    # we will leave it work as is in linux
    # also, in BSD, the nm flag -F corresponds to the -f flag in linux.
    NM_FLAG="-F"
fi

cp ${KEEPSYMS_IN} ${KEEPSYMS}

if [ $IS_MINGW -eq 1 ]; then
    # For MinGW, use libcrtdll.a (static C runtime) instead of libc.so
    LIBC_A=$("$@" --print-file-name=libcrtdll.a)
    if [ -f "${LIBC_A}" ]; then
        # Static library - no -D flag needed
        ${NM} ${NM_FLAG} posix -g ${LIBC_A} 2>/dev/null | sed 's/\([^ @]*\).*/^\1$/' >> ${KEEPSYMS} || true
    fi
else
    # find the libc used by gcc (Linux/FreeBSD)
    if [ `uname` = "FreeBSD" ]; then
        LIBC_SO=/lib/libc.so.7
    else
        LIBC_SO=$("$@" --print-file-name=libc.so.6)
    fi
    # get all symbols from libc and turn them into patterns
    ${NM} ${NM_FLAG} posix -g -D ${LIBC_SO} | sed 's/\([^ @]*\).*/^\1$/' >> ${KEEPSYMS}
fi

# build the object
"$@"

# rename the symbols in the object
${NM} ${NM_FLAG} posix -g ${OUT} | cut -f1 -d' ' | grep -v -f ${KEEPSYMS} | sed -e "s/\(.*\)/\1\ ${PREFIX}_\1/" >> ${SYMSFILE}
if test -s ${SYMSFILE}
then
    ${OBJCOPY} --redefine-syms=${SYMSFILE} ${OUT}
fi

# For MinGW: also rename .refptr sections to avoid COMDAT conflicts
if [ $IS_MINGW -eq 1 ]; then
    SECTFILE=$(mktemp -p /tmp ${PREFIX}_sections.XXXXX)

    # Get list of .rdata$.refptr.* sections - use objdump -h to show section headers
    ${OBJDUMP} -h ${OUT} 2>/dev/null | grep '\.rdata\$\.refptr\.' | awk '{print $2}' | while IFS= read -r sect; do
        # Skip mmbit sections (shared lookup tables across all variants)
        case "$sect" in
            *.refptr.mmbit*|*.refptr.hs_*) continue ;;
        esac
        echo "--rename-section=${sect}=${PREFIX}_${sect}" >> ${SECTFILE}
    done 2>/dev/null

    if [ -s "${SECTFILE}" ]; then
        ${OBJCOPY} $(cat ${SECTFILE}) ${OUT} 2>/dev/null || true
    fi
    rm -f "${SECTFILE}" 2>/dev/null || true
fi
