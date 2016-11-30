{
    if (!SUF){
	SUF = "-T";
    }
}

NF > 1 {
    if (OTHERFIELD == 0){
	printf("%s%s", $1, SUF);
	for (k=2; k <= NF; k++){
	    printf(" %s",$k);
	}
	printf("\n"); 
    } else {
	printf("%s", $1);
	for (k=2; k <= NF; k++){
	    printf(" %s%s",$k,SUF);
	}
	printf("\n");
    }
}


