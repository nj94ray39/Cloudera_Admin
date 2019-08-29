For Namenode in Non-HA, fsimage and edits will be stored on active NameNode and Standby NameNode. The recommendation is to backup the fsimageand editson a regular basis.

For Namenodein HA: Since the fsimage and edits will typically be stored on both NameNode servers and the edits will also be stored within the Journal Quorum which is typically threeservers, the general recommendation is to only focus on backing up the fsimage on a regular basis. Under the worst condition where all fivecopies of the edits files are lost, the fsimage could be up to an hour old since checkpointing should occur every hour.

The recommended process to backup is:

1. (NamenodeNon-HA and HA) Use the following command and it will automatically determine the active NameNode and retrieve the current fsimage and place it in the backup_dir defined.

hdfs dfsadmin -fetchImage backup_dir

Note:Do not use the http://<namenode>:50070/getimage?getimage=1&txid=latest -This is considered an internal API callsubject to change without notice and should only be run against the active NameNode.

2. (NamenodeNon-HA only), Roll Edit logsso this ends the current edit log segment and starts a new one.

hdfs dfsadmin -rollEdits

3. (NamenodeNon-HA only), Copy the Edit logsto the backup_dir

cp <namenode_data_dir>/current/edits_0* backup_dir

4. (NamenodeNon-HA and HA) Make a single backup of the VERSION file. This does not need to be backed up regularly as it does not change, but it is important since it contains the clusterID along with other details.

If the NameNode servers were to suddenly die and a new one needs to be created, the general restore process is listed below.

General Restore Process

1. Add the new host to the cluster.

2. Add the NameNode role to the host.

3. If it does not already exist, create the appropriate directory path for the NameNode host'sdfs.namenode.name.dirvalue (e.g./dfs/nn/current), also ensuring that the permissions are set correctly (owned entirely by "hdfs:hdfs"with parent directory permissions as700).

4. Copy theVERSIONand latestfsimagefile to the "current" directory.

(ForNamenode in Non-HA, restore the edits file also.)

5. Runmd5sum fsimage > fsimage.md5to create themd5file for thefsimage. This could have also been done when thefsimagefile was originally backed up if you prefer.

Note: If the hostname is going to be different than the server it is replacing, then you will also need to re-initialize the ZooKeeper znode for Automatic Failover. This process is outlined inChanging the NameService Name in Cloudera Manager.

6. Start the NameNode process.

Upon startup, the NameNode process will read thefsimagefile and commit it to memory. If the journal nodes are up and running still and there are edits files present, any edits newer than the fsimage will also be applied.
