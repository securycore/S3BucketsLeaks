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

* -b bucketname ;
* -p profileName (to perform the requests with an authenticated account) (optionnal).
    
#### Recon :

* -a (to run all recon options) (optionnal) ;
* -l (to check if everyone can list the bucket content) (optionnal) ;
* -w (to check if everyone can upload/delete the bucket content) (optionnal) ;
* --aclb (to check if everyone can read the bucket ACL) (optionnal) ; 
* -r (to check if files listed with -l are readable) (optionnal, can be very consuming, you should use -d (see exploitation) to select intersting files only) ;
* --aclo (to check if everyone can read the objects ACL) (optionnal, idem).
    
#### Exploitation :
    
* -d filepath1,filepath2... (to download a file from the bucket) ;
* -u filepath1,filepath2... (to upload a file in the bucket) ;
* --rm filepath1,filepath2... (to remove a file in the bucket).
        
## Improvemts

* Remove test: allow to quit ;
* Check if it is possible to write ACL on bucket and objetcts (put-bucket-acl & put-object-acl);
* Allow to select keylist to read only intersting files.
