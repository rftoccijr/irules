# using data groups to do pool selection by uri or host and dynamic TLS as well as maintenance pages ##

## Requirements:
   - 1. datagroup with formatting for uri or pool
```
example: 
 "/pool1" := "/Common/pool1",
 "/pool2" := "/Common/pool2",
```
   - 2. Rename
     - find and replace rulename with your irulename
   - 3. Create ifiles
     - Create ifile objects to support maintenance page objects
   - 4. Pool members
     - default SSL/TLS ports 80/443 are accounted for, if you need non standard ports extend the LB::server port check.
