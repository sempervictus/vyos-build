#!/bin/sh
CWD=$(pwd)
KERNEL_SRC=linux

if [ ! -d ${KERNEL_SRC} ]; then
    echo "Linux Kernel source directory does not exists, please 'git clone'"
    exit 1
fi

echo "I: Copy Kernel config (x86_64_vyos_defconfig) to Kernel Source"
cp x86_64_vyos_defconfig ${KERNEL_SRC}/arch/x86/configs

cd ${KERNEL_SRC}

echo "I: clean modified files"
git reset --hard HEAD

KERNEL_VERSION=$(make kernelversion)
KERNEL_SUFFIX=-$(dpkg --print-architecture)-vyos

# VyOS builds added functionality from Kernel Patches - apply 
# them here.
# It's easier to have them here and make use of the upstream
# repository instead of maintaining a full Kernel fork.
# Saving time/resources is essential :-)
PATCH_DIR=${CWD}/patches/kernel
for patch in $(ls ${PATCH_DIR} | grep -v rsbac)
do
    echo "I: Apply Kernel patch: ${PATCH_DIR}/${patch}"
    patch -p1 < ${PATCH_DIR}/${patch}
done

echo "I: make x86_64_vyos_defconfig"
# Select Kernel configuration - currently there is only one
make x86_64_vyos_defconfig

echo "I: Generate environment file containing Kernel variable"
cat << EOF >${CWD}/kernel-vars
#!/bin/sh
export KERNEL_VERSION=${KERNEL_VERSION}
export KERNEL_SUFFIX=${KERNEL_SUFFIX}
export KERNEL_DIR=${CWD}/${KERNEL_SRC}
EOF

echo "I: Build Debian Kernel package"
touch .scmversion
make bindeb-pkg BUILD_TOOLS=1 LOCALVERSION=${KERNEL_SUFFIX} KDEB_PKGVERSION=${KERNEL_VERSION}-1 -j $(getconf _NPROCESSORS_ONLN)

cd $CWD
if [[ $? == 0 ]]; then
    for package in $(ls linux-*.deb)
    do
        ln -sf linux-kernel/$package ..
    done
fi
