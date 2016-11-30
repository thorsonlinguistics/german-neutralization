BEGIN {FS=" ";}
{
    word1 = $1;
    word2 = word1;
    if ($0 ~ /^[^ ]+ +t /){
	v1 = $0;
	sub(/ /,"t ",v1);
	word2 = word2 "t";
	v2 = v1;
	sub(/ t /," d ",v1);
	sub(/ /,"  ",$0);
	if (map){
	    printf("%s\t%s\n",word1,word2)
	} else {
	    printf("%s\n",$0);
	    printf("%s\n",v1);
	    printf("%s\n",v2);
	}
    }
    else if ($0 ~ /^[^ ]+ +k /){
	v1 = $0;
	sub(/ /,"k ",v1);
	word2 = word2 "k";
	v2 = v1;
	sub(/ k /," g ",v1);
	sub(/ /,"  ",$0);
	if (map){
	    printf("%s\t%s\n",word1,word2)
	} else {
	    printf("%s\n",$0);
	    printf("%s\n",v1);
	    printf("%s\n",v2);
	}
    }
    else if ($0 ~ /^[^ ]+ +p /){
	v1 = $0;
	sub(/ /,"p ",v1);
	word2 = word2 "p";
	v2 = v1;
	sub(/ p /," b ",v1);
	sub(/ /,"  ",$0);
	if (map){
	    printf("%s\t%s\n",word1,word2)
	} else {
	    printf("%s\n",$0);
	    printf("%s\n",v1);
	    printf("%s\n",v2);
	}
    }
    else if ($0 ~ /^[^ ]+ +d /){
	v1 = $0;
	sub(/ /,"d ",v1);
	word2 = word2 "d";
	v2 = v1;
	sub(/ d /," t ",v1);
	sub(/ /,"  ",$0);
	if (map){
	    printf("%s\t%s\n",word1,word2)
	} else {
	    printf("%s\n",$0);
	    printf("%s\n",v2);
	    printf("%s\n",v1);
	}
    }
    else if ($0 ~ /^[^ ]+ +g /){
	v1 = $0;
	sub(/ /,"g ",v1);
	word2 = word2 "g";
	v2 = v1;
	sub(/ g /," k ",v1);
	sub(/ /,"  ",$0);
	if (map){
	    printf("%s\t%s\n",word1,word2)
	} else {
	    printf("%s\n",$0);
	    printf("%s\n",v2);
	    printf("%s\n",v1);
	}
    }
    else if ($0 ~ /^[^ ]+ +b /){
	v1 = $0;
	sub(/ /,"b ",v1);
	word2 = word2 "b";
	v2 = v1;
	sub(/ b /," p ",v1);
	sub(/ /,"  ",$0);
	if (map){
	    printf("%s\t%s\n",word1,word2)
	} else {
	    printf("%s\n",$0);
	    printf("%s\n",v2);
	    printf("%s\n",v1);
	}
    }
    else {
	sub(/ /,"  ",$0);
	if (map){
	    printf("%s\t%s\n",word1,word2)
	} else {
	    printf("%s\n",$0); 

	}
    }
}
