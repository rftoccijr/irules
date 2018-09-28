# using data groups to do pool selection by uri or host and dynamic TLS as well as maintenance pages ##

## Requirements:
   ###datagroup with formatting for uri or pool
   example: 
       "/pool1" := "/Common/pool1",
       "/pool2" := "/Common/pool2",
   ###Rename
       find and replace rulename with your irulename
   ###Create ifiles
       create ifile objects to support maintenance page objects
   ###Pool members
       default SSL/TLS ports 80/443 are accounted for, if you need non standard ports extend the LB::server port check.
   