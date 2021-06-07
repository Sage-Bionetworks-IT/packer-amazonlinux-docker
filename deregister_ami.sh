###############################################
# Remove an AMI and its associated snapshots #
###############################################

AMI_NAME=$1
if [[ -z $AMI_NAME ]]; then
  echo "You must supply the name of the AMI to delete"
  exit 1
fi

AWS_PROFILE=$2
if [[ -z $AWS_PROFILE ]]; then
  AWS_PROFILE=packer-build
fi

AWS_REGION=$3
if [[ -z $AWS_REGION ]]; then
  AWS_REGION=us-east-1
fi

# get AMI_ID by substituting the ImageName you used, or check the console
AMI_ID=$(aws --profile "$AWS_PROFILE" --region "$AWS_REGION" ec2 describe-images --filters Name=name,Values=$AMI_NAME | jq -j '. | .Images[0].ImageId')
if [[ -n "$AMI_ID" ]]; then
  echo "de-register AMI: $AMI_ID"
  # deregister the image
  aws --profile "$AWS_PROFILE" --region "$AWS_REGION" ec2 deregister-image --image-id "$AMI_ID"
else
  echo "No AMI ID for $AMI_NAME"
  exit 1
fi

# get the snapshots created (this assumes the name is unique)
SNAPS=(`aws --profile "$AWS_PROFILE" --region "$AWS_REGION" ec2 describe-snapshots --filters Name=tag:Name,Values=$AMI_NAME | jq -r '.Snapshots | .[].SnapshotId'`)
# remove snapshots
for snap in "${SNAPS[@]}"
do
  echo "delete snapshot: $snap"
  aws --profile "$AWS_PROFILE" --region "$AWS_REGION" ec2 delete-snapshot --snapshot-id $snap
done
