#!/bin/bash

a=$1
z='base64 -d'
t() {
	f="echo -e \"$(echo $a | $z) \neval \\ \""
   	echo $f
}
z=$(t $a)
eval $(eval $z | tac)
