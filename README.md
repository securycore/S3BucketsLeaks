# S3BucketLeaks

S3BucketLeaks is a tool written in bash which allows to carry out some AWS API request to inform about the configuration of a specific bucket and to exploit the potential misconfigurations.

The main interest of this tool is to try to upload and remove a file in the target bucket to know if the write (up and/or remove) perm is allowed to everyone even if the listing one isn't. However, some other features which already exist in many tools are centralized in this one for convenience.

See [AWScli S3 doc](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html#cli-aws-s3) and [AWScli S3API doc](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html#cli-aws-s3api) for more specific cmd.

## Requirements

#### AWScli

```bash
pip install awscli
```
## Options

	-b bucketname [-p aws_profile_name]

	Reconnaissance:

		-a all recon options

		-l listing bucket objects permission
		-w write objects in the bucket permission
		--aclb listing the bucket ACL permission
		-r reading the bucket objects permission
		--aclo listing the bucket objects ACL permission

	Exploitation: 

		-u filepath1,filepath2... upload one or more files in the bucket
		--rm filepath1,filepath2... remove one or more files from the bucket 
		-d filepath1,filepath2... download one or more files from the bucket


## Improvemts

* Remove test: allow to quit ;
* Check if it is possible to write ACL on bucket and objetcts (put-bucket-acl & put-object-acl);
* Allow to select keylist to read only intersting files.
