#!/bin/bash

# S3BucketsLeaks
# Zweisamkeit
# 03/06/2018
# Version 1

# Is AWS installed?

command -v aws 2>/dev/null 1>&2
if [ $? -eq 1 ]
then
	 echo "awscli is required. Please install it using the following command: pip install awscli. Aborting"
	exit 1;
fi

# Some declarations

## Colors

red='\033[0;31m'
orange='\033[0;33m'
green='\033[0;32m'
blue='\033[0;34m'
nc='\033[0m'

# Welcome

echo -e "\n"
echo -e "\t${red}##################################${nc}"
echo -e "\t${red}#${nc}         S3BucketsLeaks         ${red}#${nc}"
echo -e "\t${red}#${nc}          Zweisamkeit           ${red}#${nc}"
echo -e "\t${red}#${nc}           Version 1            ${red}#${nc}"
echo -e "\t${red}##################################${nc}"
echo -e "\n"

# Parsing arguments

scriptname=$0

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
	-h|--help)
	echo -e "Usage: $scriptname -b bucketname [-p profile_name]\n\tRecon: [-a (all recon options) -l (list perm) -w (write perm) --aclb (list Bucket ACL perm) -r (read objetcs perm) --aclo (list objects ACL perm)]\n\tExploit: [ -u filepath1,filepath2... (upload) --rm filepath1,filepath2... (remove) -d filepath1,filepath2... (download)"
	exit 1
	;;
	-b|--bucket)
	bucket="$2"
	shift
	shift
	;;
	-p|--profile)
	set_profile=true
	profile="$2"
	shift
	shift
	;;
	-a|--all)
	all_perm=true
	shift
	;;
	-l|--list)
	list_perm=true
	shift
	;;
	-w|--write)
	write_perm=true
	shift
	;;
	--aclb)
	list_aclb=true
	shift
	;;
	-r)
	read_perm=true
	shift
	;;
	--aclo)
	list_aclo=true
	shift
	;;
	-u|--upload)
	upload=true
	filespaths_upload=$(echo "$2" | tr ',' '\n')
	shift
	shift
	;;
	--rm|--remove)
	remove=true
	filespaths_remove=$(echo "$2" | tr ',' '\n')
	shift
	shift
	;;
	-d|--download)
	download=true
	filespaths_download=$(echo "$2" | tr ',' '\n')
	shift
	shift
	;;
	
esac
done

if [ "$bucket" = "" ]
then
	echo "Please specify a bucket name (--help for help)"
        exit 1
fi

# Discovering the region

region=$(nslookup $bucket.s3.amazonaws.com | grep Name | cut -d '-' -f 2,3,4)

# Profile or not profile

if [ "$set_profile" = "true" ]
then

	profile_parameter="--profile $profile"
	user="$profile"

else

	profile_parameter="--no-sign-request"
	user="everyone"
fi

# Output repository

output_path=./${bucket}_AWSBucketLeakToolKit

mkdir -p $output_path

# RECON

# ALL : permet de lancer toutes les fonctionnalités de reconnaissance

if [ "$all_perm" = "true" ]
then

	list_perm=true
	write_perm=true
	list_aclb=true
	read_perm=true
	list_aclo=true

fi

# List files

if [ "$list_perm" = "true" ]
then

	echo -e "\nTrying to list the bucket files..."

	list=$(aws s3 ls s3://$bucket/ --recursive --human-readable --region $region $profile_parameter 2>/dev/null)

	if [ "$?" -eq 0 ]
	then
		echo -e "\n\t${green}The bucket $bucket is listable by $user.${nc}"
		list_path=$output_path/${bucket}_list.txt
		echo "$list" > $list_path
		echo -e "\n\t${blue}Bucket list location: $list_path${nc}" 
	else
		echo -e "\n\t${red}The bucket $bucket is unlistable by $user.${nc}"
	fi
fi

# Write perm

if [ "$write_perm" = "true" ]
then

	# Creating a file test to upload

	path=/tmp/
	filename=$(date | md5sum | cut -d ' ' -f 1).txt
	filepath=$path$filename
	touch $filepath # TODO: manage error

	echo -e "\nTrying to upload and to remove a file..."

	# Try to upload a file
	
	aws s3 cp $filepath s3://$bucket/ --region $region $profile_parameter 2>/dev/null 1>&2
	

	if [ $? -eq 0 ]
	then
		up=true
	else
		up=false
	fi
	
	# Try to remove a file
	# If the upload succeed, try to remove the uploaded file. Else, ask for a known filename.
	
	if [ "$up" ]
	then
		filepath2=$filename
	else
		read -p "Please enter the name of a file of the bucket: " filepath2
	fi
	
	aws s3 rm s3://$bucket/$filepath2 --region $region $profile_parameter 2>/dev/null 1>&2
	
	if [ $? -eq 0 ]
	then
	        rem=true
	else
	        rem=false
	fi
	
	# Results
	
	if [ "$up" = "true" -a "$rem" = "true" ]
	then
		echo -e "\n\t${green}The bucket $bucket is fully writable by $user.${nc}"
	
	elif [ "$up" = "true" -a "$rem" = "false" ]
	then
		echo -e "\n\t${orange}The bucket $bucket is partially writable by $user: only upload is authorized${nc}"
	
	elif [ "$up" = "false" -a "$rem" = "true" ]
	then
		echo -e "\n\t${orange}The bucket $bucket is partially writable by $user: only remove is authorized${nc}"
	else
		echo -e "\n\t${red}The bucket $bucket isn't writable by $user.${nc}"
	fi
	
	# Clean
	
	rm $filepath

fi

# List ACL

if [ "$list_aclb" = "true" ]
then

	echo -e "\nTrying to list the bucket ACL..."

	aclb_list=$(aws s3api get-bucket-acl --bucket $bucket --region $region $profile_parameter 2>/dev/null)

	if [ "$?" -eq 0 ]
	then
		echo -e "\n\t${green}ACL successfully obtained.${nc}"
		aclb_path=$output_path/${bucket}_ACL.txt
		echo "$aclb_list" > $aclb_path
		echo -e "\n\t${blue}ACL list location: $aclb_path${nc}"
	else
		echo -e "\n\t${red}The ACL access is restricted.${nc}"
	fi
fi

# Read Files

if [ "$read_perm" = "true" ]
then

	echo -e "\nTrying to read the bucket objects..."

	list_path=$output_path/${bucket}_list.txt
	if [ -f "$list_path" ]
	then

		tmp_output=$output_path/tmp/

		mkdir -p $tmp_output

		read_list=$output_path/${bucket}_read.txt

		echo "" > $read_list


		while read line
		do

			filename=$(echo $line | awk '{print $NF}') # seul le dernier champs de la ligne correspond au nom du fichier

			aws s3 cp s3://$bucket/$filename $tmp_output --region $region $profile_parameter 2>/dev/null 1>&2

	                if [ "$?" -eq 0 ]
        	        then
                	        echo -e "\n\t${green}File $filename is readable by $user${nc}" >> $read_list
                	else
                        	echo -e "\n\t${red}File $filename isn't readable by everone.${nc}" >> $read_list
                	fi
		done < $list_path

		rm -rf $tmp_output

		echo -e "\n\t${green}Read permissions successfully obtained.${nc}"
                echo -e "\n\t${blue}Read file location: $read_list${nc}"

			
	else

		echo -e "\n\t${red}Can't check reading permissions because the list of the objects is not available (try -l option).${nc}"

	fi

fi

# List Objects ACL perm

if [ "$list_aclo" = "true" ]
then

        echo -e "\nTrying to list the objects ACL..."

        list_path=$output_path/${bucket}_list.txt
        if [ -f "$list_path" ]
        then

                aclo_list=$output_path/${bucket}_objects_ACL.txt

                echo "" > $aclo_list


                while read line
                do

                        filename=$(echo $line | awk '{print $NF}') # seul le dernier champs de la ligne correspond au nom du fichier

                        aclo=$(aws s3api get-object-acl --bucket $bucket --key $filename --region $region $profile_parameter 2>/dev/null)

                        if [ "$?" -eq 0 ]
                        then
                                echo -e "\n\t${green}$filename ACL is listable by $user${nc}\n" >> $aclo_list
				echo "$aclo" >> $aclo_list
                        else
                                echo -e "\n\t${red}File $filename isn't readable by everone.${nc}\n" >> $aclo_list
                        fi

                done < $list_path

                echo -e "\n\t${green}ACL objects list permissions successfully obtained.${nc}"
                echo -e "\n\t${blue}ACL objects file location: $aclo_list${nc}"


        else

                echo -e "\n\t${red}Can't check ACL objects list permissions because the list of the objects is not available (try -l option).${nc}"

        fi

fi


### EXPLOITATION ###

# Upload

if [ "$upload" = "true" ]
then

	for filepath_upload in $filespaths_upload
	do

		echo -e "\nTrying to upload the file $filepath_upload..."

		aws s3 cp $filepath_upload s3://$bucket/ --region $region $profile_parameter 2>/dev/null 1>&2

		if [ "$?" -eq 0 ]
        	then
                	echo -e "\n\t${green}File successfully uploaded.${nc}"
			echo -e "\n\t${blue}Path: s3://$bucket/$filepath_upload. ${nc}"
        	else
                	echo -e "\n\t${red}Error: the file was not uploaded.${nc}"
        	fi
	done
fi

# Remove

if [ "$remove" = "true" ]
then

	for filepath_upload in $filespaths_remove
	do
        
		echo -e "\nTrying to remove the file $filepath_upload..."

        	aws s3 rm s3://$bucket/$filepath_remove --region $region $profile_parameter 2>/dev/null 1>&2

        	if [ "$?" -eq 0 ]
        	then
                	echo -e "\n\t${green}File $filepath_remove successfully removed!${nc}"
        	else
                	echo -e "\n\t${red}Error: the file was not removed...${nc}"
        	fi
	done
fi

# Download file

if [ "$download" = "true" ]
then

	for filepath_download in $filespaths_download
	do

		echo -e "\nTrying to download the file $filepath_download..."
	
		aws s3 cp s3://$bucket/$filepath_download $output_path --region $region $profile_parameter 2>/dev/null 1>&2
	
		if [ "$?" -eq 0 ]
		then
			echo -e "\n\t${green}File successfully downloaded.${nc}"
			echo -e "\n\t${blue}tFile location: $output_path/$filepath_download. ${nc}"
		else
			echo -e "\n\t${red}Error: the file was not downloaded.${nc}"
		fi
	done
fi

# Exit

echo -e "\n"

exit 0;
