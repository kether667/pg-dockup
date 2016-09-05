#!/bin/bash
export PATH=$PATH:/usr/bin:/usr/local/bin:/bin
# Get timestamp
: ${BACKUP_SUFFIX:=.$(date +"%Y-%m-%d-%H-%M-%S")}
readonly tarball=$BACKUP_NAME$BACKUP_SUFFIX.tar.gz

readonly DOW=$(date +%A)
readonly PATHS_TO_BACKUP=/tmp/$BACKUP_NAME-$DOW

# Clean destination path
rm -rf $PATHS_TO_BACKUP

# Run backup
pg_dump --format=directory --file=$PATHS_TO_BACKUP $PG_DUMP_OPTIONS --dbname=$PG_CONNECTION_STRING

# Create a gzip compressed tarball with the volume(s)
tar czf $tarball -C /tmp $BACKUP_TAR_OPTION $PATHS_TO_BACKUP

# Create bucket, if it doesn't already exist
BUCKET_EXIST=$(aws s3 ls | grep $S3_BUCKET_NAME | wc -l)
if [ $BUCKET_EXIST -eq 0 ];
then
  aws s3 mb s3://$S3_BUCKET_NAME
fi

# Upload the backup to S3 with timestamp
aws s3 --region $AWS_DEFAULT_REGION cp $tarball s3://$S3_BUCKET_NAME/$tarball

# Clean up
rm $tarball
