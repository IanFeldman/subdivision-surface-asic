#!/bin/bash
WC=$(ls | grep *.sv | wc -l)
if [ $WC = "1" ] 
then 
    echo $1 `ls | grep *.sv | cut -d. -f1`
fi