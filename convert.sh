java -cp saxon9he.jar  net.sf.saxon.Query  -q:rif2spin.xqy -s:"$1"  > temp.ttl
 arq --query=echo.sq --data=temp.ttl

