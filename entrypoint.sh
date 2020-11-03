#!/bin/bash -x

CNT=
MNT=

MOUNT_MACHINE_OS_CONTENT() { export MOC=$(buildah --authfile /var/lib/kubelet/config.json  --storage-driver vfs from {{.OSImageURL}}); export MOCMNT=$(buildah --storage-driver vfs mount $MOC); }
UMOUNT_MACHINE_OS_CONTENT() { buildah --storage-driver vfs umount $MOC;  }

FROM() { export CNT=$(buildah --storage-driver vfs from $1); }

MOUNT() { export MNT=$(buildah --storage-driver vfs mount $CNT); }
UMOUNT() { buildah --storage-driver vfs umount $CNT; }

ENV() { buildah config --env $@; }
RUN() { buildah --storage-driver vfs --isolation chroot run --user 0 $CNT -- $@; }
RUNV() { buildah --storage-driver vfs --isolation chroot run --volume /etc/pki/entitlement-host:/etc/pki/entitlement:z --volume ${MOCMNT}:/extensions:z --user 0 $CNT -- $@; }
COPY() { buildah --storage-driver vfs copy $CNT $@; }
COMMIT() { buildah --storage-driver vfs commit $CNT $1; }
ENTRYPOINT() { buildah config --entrypoint $1 $CNT; }
WORKINGDIR() { buildah --storage-driver vfs config --workingdir $1 $CNT; }
PUSH() { buildah --storage-driver vfs push --tls-verify=false --authfile /root/.dockercfg  $@; }


BUILD_OUTPUT_IMAGE=$1
BUILD_DOCKERFILE=$2
BUILD_SOURCE_CONTEXTDIR=$3
OS_IMAGE_URL=$4

