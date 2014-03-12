
printf {c in C,sh in Hot[c]} : "HotExergy \t %s \t %f \n", sh,(sum {k in K[c]} (Qihk[c,sh,k]*(1-Tamb[c]*log(Tu[c,k]/Tl[c,k])/(Tu[c,k]-Tl[c,k]))))
>/Users/hubert/Documents/EPFL/EDF/Arcelor/osmose/OSMOSE_temp/EnergyIntegration/xrj.out;
printf {c in C,sc in Cold[c]} : "ColdExergy \t %s \t %f \n", sc,( sum {k in K[c]}( Qjck[c,sc,k]*(1-Tamb[c]*log(Tu[c,k]/Tl[c,k])/(Tu[c,k]-Tl[c,k])) )) > /Users/hubert/Documents/EPFL/EDF/Arcelor/osmose/OSMOSE_temp/EnergyIntegration/xrj.out;

 printf {c in C} : "ExergyGiven(Hot) \t %f \n", ExergyGiven[c] > /Users/hubert/Documents/EPFL/EDF/Arcelor/osmose/OSMOSE_temp/EnergyIntegration/xrj.out;
 printf {c in C} : "ExergyReceived(Cold) \t %f \n", ExergyReceived[c] > /Users/hubert/Documents/EPFL/EDF/Arcelor/osmose/OSMOSE_temp/EnergyIntegration/xrj.out; 
