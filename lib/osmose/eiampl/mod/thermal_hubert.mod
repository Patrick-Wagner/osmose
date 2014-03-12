
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade Layer
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


## Filtering Layers and selecting only layers of type "HeatCascade"
set HeatCascades :=  {l in LayersOfType["HeatCascade"]} within Layers; 


set HC_TempIntervals{HeatCascades} ordered; #Set of temperature intervals of each heat cascade

# param Tamb{l in HeatCascades} default 298.00001;

# Temperature intervals
param HC_TI_tl{l in HeatCascades, k in HC_TempIntervals[l]};
param HC_TI_tu{l in HeatCascades, k in HC_TempIntervals[l]};

# Thermal streams specification
param HC_Tin{l in HeatCascades, s in StreamsOfLayer[l]}; 
param HC_Tout{l in HeatCascades, s in StreamsOfLayer[l]}; 
param HC_Hin{l in HeatCascades, s in StreamsOfLayer[l]}; 
param HC_Hout{l in HeatCascades, s in StreamsOfLayer[l]}; 


# EI units specification
param Fmin{u in Units} default 0; 
param Fmax{u in Units} default 0; 
param Cost1{u in Units} default 0; 
param Cost2{u in Units} default 0; 
param Cinv1{u in Units} default 0; 
param Cinv2{u in Units} default 0; 


# Forbidden connections
# param conn_forbidden{s1 in Streams, s2 in Streams} default 0;

# Hot streams
set HC_Hot {l in HeatCascades}  within Streams :=
	{s in StreamsOfLayer[l] : HC_Hout[l,s]<=HC_Hin[l,s]};

# Cold streams
set HC_Cold {l in HeatCascades} within Streams :=
	{s in StreamsOfLayer[l] : HC_Hout[l,s]>=HC_Hin[l,s]};

# Hot Streams in interval k
# set HC_Hk{l in HeatCascades, k in HC_TempIntervals[l]} within Streams := 
#	{s in HC_Hot[l] : HC_Hout[l,s]<=HC_Hin[l,s] and HC_Tout[l,s]<=HC_TI_tl[l,k] and HC_Tin[l,s]>=HC_TI_tu[l,k]}
#;

# Cold Streams in interval k
# set HC_Ck{l in HeatCascades, k in HC_TempIntervals[l]} within Streams := 
#	{s in HC_Cold[l] : HC_Hout[l,s]>=HC_Hin[l,s] and HC_Tin[l,s]<=HC_TI_tl[l,k] and HC_Tout[l,s]>=HC_TI_tu[l,k]}
#;

# Non connected streams
# set Pij{l in HeatCascades} :=
#	{si in HC_Hot[l],sj in HC_Cold[l] : conn_forbidden[si,sj]+conn_forbidden[sj,si] >= 1};
	
# Hot stream with at least one forbidden connection
# set HP{l in HeatCascades} :=
#	{si in HC_Hot[l] : sum{sj in HC_Cold[l]} (conn_forbidden[si,sj]+conn_forbidden[sj,si]) >= 1};

# Cold stream with at least one forbidden connection
# set CP{l in HeatCascades} :=
#	{si in HC_Cold[l] : sum{sj in HC_Hot[l]} (conn_forbidden[si,sj]+conn_forbidden[sj,si]) >= 1};

# Heat available in hot streams in temperature interval k
var HC_Qihk{l in HeatCascades, si in HC_Hot[l], k in HC_TempIntervals[l]};
subject to HC_cstrHeatExchangeHot{l in HeatCascades, si in HC_Hot[l], k in HC_TempIntervals[l]} :			   
	HC_Qihk[l,si,k] = if( HC_Tin[l,si]>=HC_TI_tu[l,k] )
				   then ( sum{ui in UnitsOfStream[si]} (Units_Mult[ui]*(HC_TI_tu[l,k]-
				    	if(HC_Tout[l,si]<=HC_TI_tl[l,k]) 
				    		 then HC_TI_tl[l,k] 
				    		 else HC_Tout[l,si]
				     	)/(HC_Tin[l,si]-HC_Tout[l,si])*(HC_Hout[l,si]-HC_Hin[l,si])))
				   
				   else (0);
				   
# Heat needed by cold streams in temperature interval k	
var HC_Qjck{l in HeatCascades, sj in HC_Cold[l], k in HC_TempIntervals[l]};
subject to HC_cstrHeatExchangeCold{l in HeatCascades, k in HC_TempIntervals[l], sj in HC_Cold[l]} :			
		HC_Qjck[l,sj,k] = if( HC_Tin[l,sj]<=HC_TI_tl[l,k] )
				   then ( sum{uj in UnitsOfStream[sj]} (Units_Mult[uj]*(
				    	if(HC_Tout[l,sj]>=HC_TI_tu[l,k]) 
				    		 then HC_TI_tu[l,k] 
				    		 else HC_Tout[l,sj]
				     	-HC_TI_tl[l,k])/(HC_Tout[l,sj]-HC_Tin[l,sj])*(HC_Hout[l,sj]-HC_Hin[l,sj])))
				   else (0);

# Heat cascad residu in temperature interval k
var HC_Rk{l in HeatCascades, k in HC_TempIntervals[l]};

# Heat balance in interval k
subject to HeatBlance{l in HeatCascades, k in HC_TempIntervals[l]}:
HC_Rk[l,k] - 
if(k>1) then HC_Rk[l,prev(k)] else 0
= sum { si in HC_Hot[l]} HC_Qihk[l,si,k] - sum { sj in HC_Cold[l]} HC_Qjck[l,sj,k];

# Heat exchange between hot and cold streams
var HC_Qijk{l in HeatCascades,si in HC_Hot[l], sj in HC_Cold[l], k in HC_TempIntervals[l]};
#subject to HC_cstrHeatExchange{l in HeatCascades, k in HC_TempIntervals[l]} :
#	HC_Qihk[l,si,k]=(HC_Rk[l,si,k]-(if(k>1) then HC_Rk[l,si,prev(k)] else 0) + sum{sj in HC_Cold[l]}(HC_Qijk[l,si,sj,k]));
	
# Closing heat cascad
subject to HC_closeFirst{l in HeatCascades} :
	HC_Rk[l,first(HC_TempIntervals[l])]=0;
	
subject to HC_closeLast{l in HeatCascades} :
	HC_Rk[l,last(HC_TempIntervals[l])]=0;
	
# Heat cascad feasability
subject to HC_feasab{l in HeatCascades, k in HC_TempIntervals[l]} :
	HC_Rk[l,k]>=0;

# No heat transfer when connection is forbidden
# subject to cstrHeatExchange7{l in HeatCascades,(si,sj) in Pij[l],k in HC_TempIntervals[l]} :
#	Qijk[l,si,sj,k]=0;

# Heat transfer direction specification
#subject to HC_HeatTransferDirection{l in HeatCascades,si in HC_Hot[l],sj in HC_Cold[l],k in HC_TempIntervals[l]} :
#	HC_Qijk[l,si,sj,k]>=0;

# Heat conservation
#subject to HC_HeatConservation{l in HeatCascades, sj in HC_Cold[l],k in HC_TempIntervals[l]} :
#	sum{si in HC_Hot[l]} HC_Qijk[l,si,sj,k] = HC_Qjck[l,sj,k];
	
# Process streams must exchange to ensure heat cascade fesability. 
# subject to HC_ProcessStreamsExchangeHot{l in HeatCascades, sh in HC_Hot[l], u in UnitsOfStream[sh]:  Units_ForceUse[u]>0} :
# 	sum{k in HC_TempIntervals[l], sc in HC_Cold[l]} HC_Qijk[l,sh,sc,k] > 0;


# Unit sizing constraints
subject to cstrfmax{u in Units} :
Units_Mult[u]<=Units_Use[u]*Fmax[u];

subject to cstrfmin{u in Units} :
Units_Mult[u]>=Units_Use[u]*Fmin[u];

# Unit usage constraint
subject to cstrmandatory{u in Units}:
Units_Use[u]>= if Units_ForceUse[u]=1 then 1 else 0;
