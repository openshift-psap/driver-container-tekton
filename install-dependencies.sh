#!/bin/bash -x
    
set -e 

UNAME=$(uname -r)

echo "Enabling RHOCP and EUS RPM repos..."
yum config-manager --set-enabled rhocp-{{.ClusterVersionMajorMinor}}-for-rhel-8-x86_64-rpms || true
if ! yum makecache  --releasever={{.OperatingSystemDecimal}}; then 
  yum config-manager --set-disabled rhocp-{{.ClusterVersionMajorMinor}}-for-rhel-8-x86_64-rpms 
fi 

yum config-manager --set-enabled rhel-8-for-x86_64-baseos-eus-rpms || true
if ! yum makecache  --releasever={{.OperatingSystemDecimal}}; then 
  yum config-manager --set-disabled rhel-8-for-x86_64-baseos-eus-rpms
fi 

# First update the base container to latest versions of everything
yum update -y --releasever={{.OperatingSystemDecimal}}

# Additional packages that are mandatory for driver-containers
rpm -e --nodeps elfutils-libelf # Remove it for a valid libelf and libelf-devel combination, sometimes libelf is newer than devel
yum -y --releasever={{.OperatingSystemDecimal}} --setopt=install_weak_deps=False --best install elfutils-libelf elfutils-libelf-devel kmod binutils --allowerasing

# Try to enable EUS and try to install kernel-devel and kernel-headers RPMs
if yum -y --releasever={{.OperatingSystemDecimal}} --setopt=install_weak_deps=False --best install \
  kernel-devel-${UNAME} kernel-headers-${UNAME} kernel-core-${UNAME} kernel-modules-${UNAME} \
  kernel-modules-extra-${UNAME}
then
  echo "EUS - kernel-devel kernel-headers kernel-core kernel-modules kernel-modules-extra installed"
  exit 0
fi

# If EUS fails get kernel-devel and kernel-headers from machine-os-content
echo "EUS and/or rhocp-{{.ClusterVersionMajorMinor}} FAILED - installing from machine-os-content"

KERNEL_DEVEL=$(find /extensions -name kernel-devel-${UNAME}.rpm -exec ls {} \; | tail -n1)
KERNEL_HEADERS=$(find /extensions -name kernel-headers-${UNAME}.rpm -exec ls {} \; | tail -n1) 
KERNEL_CORE=$(find /extensions -name kernel-core-${UNAME}.rpm -exec ls {} \; | tail -n1)
KERNEL_MODULES=$(find /extensions -name kernel-modules-${UNAME}.rpm -exec ls {} \; | tail -n1)
KERNEL_MODULES_EXTRA=$(find /extensions -name kernel-modules-extra-${UNAME}.rpm -exec ls {} \; | tail -n1)
   
# On a 4.5 cluster we only have a subset of these available
# If they are empty yum will fail anyway, so I do not see the purpose of checking ! -z ...
# [ ! -z $KERNEL_DEVEL ]
# [ ! -z $KERNEL_HEADERS ]
# [ ! -z $KERNEL_CORE ]
# [ ! -z $KERNEL_MODULES ]
# [ ! -z $KERNEL_MODULES_EXTRA ]

# Installation order is important leave this as is 
yum -y --releasever={{.OperatingSystemDecimal}} --setopt=install_weak_deps=False --best install $KERNEL_CORE 
yum -y --releasever={{.OperatingSystemDecimal}} --setopt=install_weak_deps=False --best install $KERNEL_DEVEL
yum -y --releasever={{.OperatingSystemDecimal}} --setopt=install_weak_deps=False --best install $KERNEL_HEADERS
yum -y --releasever={{.OperatingSystemDecimal}} --setopt=install_weak_deps=False --best install $KERNEL_MODULES
yum -y --releasever={{.OperatingSystemDecimal}} --setopt=install_weak_deps=False --best install $KERNEL_MODULES_EXTRA  

# Install realtime kernel TODO
ls /extensions/kernel-rt*

