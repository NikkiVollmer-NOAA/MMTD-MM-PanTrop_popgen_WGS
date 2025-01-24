#tim ran the code below from his end to transfer the WGS folders, on at a time, to SEDNA. I had to give him my SEDNA pswd. Giles made me a folder
#on /scratch2 to put it all. Started around 1230pm on 1/17/25

rsync -av --progress /mnt/d/MMMGLTransfer/241129_NOA015_PanTrop_WGS/ nvollmer@161.55.52.157:/scratch2/nvollmer/241129_NOA015_PanTrop_WGS/

#UPDATED 1/21/25: using rsync was taking a very long time (est was something like 40 days) so tried to get data directly from AWS while on SEDNA

#first checked to make sure I could see the folders on AWS, had to run through the setup doc that seqmatic sent first then could run the following

module load tools/aws/2.11.9

aws s3 ls --profile wasabi --endpoint-url=https://s3.wasabisys.com s3://seqmatic-data-releases/nicole_vollmer/

#once i verified I could connect to aws ok, it was time to start teh transfer, so I navigated to my nvollmer folder in scratch2 and opened a screen for each folder but doing the following for each

screen

module load tools/aws/2.11.9

aws s3 sync --profile wasabi --endpoint-url=https://s3.wasabisys.com s3://seqmatic-data-releases/nicole_vollmer/241129_NOA015_PanTrop_WGS /scratch2/nvollmer/241129_NOA015_PanTrop_WGS/

#hit control + A and then D to get me out of the screen, and then repeat for each folder below.

aws s3 sync --profile wasabi --endpoint-url=https://s3.wasabisys.com s3://seqmatic-data-releases/nicole_vollmer/241129_NOA016_PanTrop_WGS /scratch2/nvollmer/241129_NOA016_PanTrop_WGS/

aws s3 sync --profile wasabi --endpoint-url=https://s3.wasabisys.com s3://seqmatic-data-releases/nicole_vollmer/250103_NOA015_RERUN_PanTrop_WGS /scratch2/nvollmer/250103_NOA015_RERUN_PanTrop_WGS/

aws s3 sync --profile wasabi --endpoint-url=https://s3.wasabisys.com s3://seqmatic-data-releases/nicole_vollmer/250103_NOA016_RERUN_PanTrop_WGS /scratch2/nvollmer/250103_NOA016_RERUN_PanTrop_WGS/

aws s3 sync --profile wasabi --endpoint-url=https://s3.wasabisys.com s3://seqmatic-data-releases/nicole_vollmer/250115_NOA016_PanTrop_WGS_8Satt149-152 /scratch2/nvollmer/250103_NOA016_RERUN_PanTrop_WGS/

#if you want to copy a single file from AWS from inside a folder use the cp rather then sync command and add the file name to the destination
aws s3 cp --profile wasabi --endpoint-url=https://s3.wasabisys.com s3://seqmatic-data-releases/nicole_vollmer/250103_NOA015_RERUN_PanTrop_WGS/1Satt006_S63_L002_R2_001.fastq.gz /scratch2/nvollmer/250103_NOA015_RERUN_PanTrop_WGS/1Satt006_S63_L002_R2_001.fastq.gz

#OR the better way is to just rerun the sync command for the entire folder to make sure no files were missed. Running sync skips files names that are the same and only downloads ones that aren't in the destination



#for each screen will get a # like 2169555

#to see the screens active
screen -ls
 
#to get back into a screen need the number above 
screen -r 2169555

#to shut down a screen need the number above 
kill 2169555 
 
 if aws is not a complete download will it say something

#to look at size of a folder 
du -sh

#a good ls command to show list,time,human readable,reverse order [newest at bottom]
ls -lthr