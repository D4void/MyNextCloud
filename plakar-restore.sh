#!/bin/bash
# Script to restore a plakar snapshot to a directory
# 
# Ref
# https://plakar.io/
# https://github.com/D4void/plakarbackup.git


PLAKAR=/usr//bin/plakar

# Parameter verification
if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "Usage: $0 <repository_name> <restore_to_directory> <snapshot_id>"
    echo ""
    echo "Expected parameters:"
    echo "  First parameter:  Repository name"
    echo "  Second parameter: Directory path where to restore the snapshot"
    echo "  Third parameter:  Snapshot ID to restore"
    exit 1
fi

REPONAME=$1
RESTORETODIR=$2
SNAPSHOTID=$3

# Check that the destination directory exists
if [[ ! -d "$RESTORETODIR" ]]; then
    echo "Error: Directory ${RESTORETODIR} doesn't exist!"
    exit 1
fi

# Create a temporary directory for restoration
RESTORE_TMP_DIR="${RESTORETODIR}/plakar_restore_$(date +%Y%m%d_%H%M%S)"
mkdir -p "${RESTORE_TMP_DIR}"

$PLAKAR at "@${REPONAME}" ls

read -p "Are you sure you want to restore snapshot ID ${SNAPSHOTID} from repository ${REPONAME} to directory ${RESTORE_TMP_DIR} ? " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
    $PLAKAR at "@${REPONAME}" restore -to ${RESTORE_TMP_DIR} $SNAPSHOTID
    echo ""
    echo "Snapshot restored to: ${RESTORE_TMP_DIR}"
fi