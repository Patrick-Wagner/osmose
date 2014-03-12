# $Id: thermal.mod 1847 2009-11-05 08:45:17Z bolliger $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Exchangers Network design
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Adapted from FMarechal.

# this version is developed to calculate the heat exchanger network design based on the results of the heat exchanger network synthesis
# the goal is to minimize the total length of the connections, minimum distance between connections are considered
# the data come from the previous HEN calculation

# Global sets
# ----------------------------------------------

# set of streams in the system 
set HD_StreamsOfLayer;

# set of heat exchangers
set HD_HeatExchangers; 

# Number of heat exchangers
param HD_HX_N := card(HD_HeatExchangers);


# Global Layout
# ----------------------------------------------
param HD_XScale;
param HD_YScale;
param HD_XPitch;
param HD_YPitch;


# Streams
# ----------------------------------------------

# Inlet and outlet temperature of streams
param HD_S_Tin  {i in HD_StreamsOfLayer} > 0;
param HD_S_Tout {i in HD_StreamsOfLayer} > 0;


# Set of hot and cold streams
set HD_S_Hot :=  {i in HD_StreamsOfLayer : HD_S_Tin[i] > HD_S_Tout[i] }; 
set HD_S_Cold := {i in HD_StreamsOfLayer : HD_S_Tin[i] < HD_S_Tout[i] }; 


# Heat exchangers
# ----------------------------------------------

# average temperature of the heat exchanger
param HD_HX_Tmean{HD_HeatExchangers};

# Hot and cold streams for each heat exchanger
param HD_HX_HS{e in HD_HeatExchangers} symbolic within HD_S_Hot;  # hot stream of the heat exchanger e
param HD_HX_CS{e in HD_HeatExchangers} symbolic within HD_S_Cold; # cold stream of the heat exchanger e

# Connections between heat exchangers
# ----------------------------------------------

# Heat exchangers connected to stream s
set HD_Connections {s in HD_StreamsOfLayer} := {e in HD_HeatExchangers : HD_HX_HS[e] == s or HD_HX_CS[e]== s} ;

# Number of connections for each stream
param HD_CN_N {s in HD_StreamsOfLayer}:= card(HD_Connections[s]);

# Streams having at least one connection
set HD_Streams := {s in HD_StreamsOfLayer : HD_CN_N[s]>0};

# Set of hot and cold streams with connections
set HD_S_HS := {s in HD_S_Hot  : s in HD_Streams}; 
set HD_S_CS := {s in HD_S_Cold : s in HD_Streams}; 

# Number of active streams
param HD_S_N := card(HD_Streams);

# Direct connection from inlet of stream i to exchanger ee
param HD_CN_se_mcpr { i in HD_Streams, j in HD_Connections[i]} >= 0 ; 

# Direct connection from exchangers to stream output
param HD_CN_es_mcpr { i in HD_Streams, j in HD_Connections[i]} >= 0 ; 

# Connections between exchangers (hot and cold part)
param HD_CN_hee_mcpr{ e in HD_HeatExchangers, ec in HD_Connections[HD_HX_HS[e]] : ec <> e}  default 0;
param HD_CN_cee_mcpr{ e in HD_HeatExchangers, ec in HD_Connections[HD_HX_CS[e]]: ec <> e} default 0;


# Coordinates
# ----------------------------------------------

# Streams
var HD_S_Xpos		{HD_Streams} >=0 <= HD_XScale, := Uniform(0,HD_XScale); # X coordinate of the stream
var HD_S_Ypos_down	{HD_Streams} >=0 <= HD_YScale := 0;			# Y coordinate of the lower temperature of the stream
var HD_S_Ypos_up	{HD_Streams} >=0 <= HD_YScale, := HD_YScale; # Y coordinate of the upper temperature of the stream

var HD_S_lane_Xpos      {HD_Streams} >=0 <= HD_XScale; # lane assigned to this stream. The lane contains all exchangers connected to the stream.
param HD_S_lane_width  {s in HD_Streams} := (HD_CN_N[s]-1)*HD_XPitch; # Width of the lane

# Heat exchangers
var HD_HX_Ypos_up	{HD_HeatExchangers} 		>= 0 <= HD_YScale  := Uniform(0,HD_YScale); # up connector of the heat exchanger
var HD_HX_Ypos_down	{e in HD_HeatExchangers} 	= HD_HX_Ypos_up[e]-HD_YPitch ; 		    # lower connector of the heat exchanger
var HD_HX_Xpos_cold	{HD_HeatExchangers} 		>= 0 <= HD_XScale, := Uniform(0,HD_XScale); # X coordinate of the cold stream of the heat exchanger
var HD_HX_Xpos_hot	{HD_HeatExchangers} 		>= 0 <= HD_XScale, := Uniform(0,HD_XScale); # X coordinate of the hot stream of the heat exchanger




# Objective function
# ----------------------------------------------
minimize HD_Total_length :
# se, hot
sum {hs in HD_S_Hot, cn in HD_Connections[hs] : hs in HD_Streams and HD_CN_se_mcpr[hs,cn] > 0} (
		  sqrt(0.0001 + (HD_S_Xpos[hs]-HD_HX_Xpos_hot[cn])**2 + (HD_S_Ypos_up[hs]-HD_HX_Ypos_up[cn])**2)
)
# hee, hot
+ sum{e in HD_HeatExchangers, ec in HD_Connections[HD_HX_HS[e]] : ec <> e and HD_CN_hee_mcpr[e, ec] > 0} (
		  sqrt(0.0001 + (HD_HX_Xpos_hot[e]-HD_HX_Xpos_hot[ec])**2 + (HD_HX_Ypos_down[e]-HD_HX_Ypos_up[ec])**2)
)
# es, hot
+ sum {hs in HD_S_Hot, cn in HD_Connections[hs] : hs in HD_Streams and HD_CN_es_mcpr[hs,cn] > 0} (
		  sqrt(0.0001 + (HD_S_Xpos[hs]-HD_HX_Xpos_hot[cn])**2 + (HD_S_Ypos_down[hs]-HD_HX_Ypos_down[cn])**2)
)
# se, cold
+ sum {cs in HD_S_Cold, cn in HD_Connections[cs] : cs in HD_Streams and HD_CN_se_mcpr[cs,cn] > 0} (
		  sqrt(0.0001 + (HD_S_Xpos[cs]-HD_HX_Xpos_cold[cn])**2 + (HD_S_Ypos_down[cs]-HD_HX_Ypos_down[cn])**2)
)
# cee, cold
+ sum{e in HD_HeatExchangers, ec in HD_Connections[HD_HX_CS[e]] : ec <> e and HD_CN_cee_mcpr[e, ec] > 0} (
		  sqrt(0.0001 + (HD_HX_Xpos_cold[e]-HD_HX_Xpos_cold[ec])**2 + (HD_HX_Ypos_up[e]-HD_HX_Ypos_down[ec])**2)
)
# es, cold
+ sum {cs in HD_S_Cold, cn in HD_Connections[cs] : cs in HD_Streams and HD_CN_es_mcpr[cs,cn] > 0} (
		  sqrt(0.0001 + (HD_S_Xpos[cs]-HD_HX_Xpos_cold[cn])**2 + (HD_S_Ypos_up[cs]-HD_HX_Ypos_up[cn])**2)
)
;



# Problem constraints
# ---------------------------------------------

# Streams X-position sorting by output temperature
subject to HD_S_Xpos_hot{s1 in HD_S_HS} :
	HD_S_lane_Xpos[s1] >= sum{s2 in HD_S_HS : HD_S_Tout[s1] < HD_S_Tout[s2]} (HD_S_lane_width[s2] + HD_XPitch);

subject to HD_S_Xpos_cold{s1 in HD_S_CS} :
	HD_S_lane_Xpos[s1] >= sum{hs in HD_S_HS} (HD_S_lane_width[hs] + HD_XPitch) + sum{s2 in HD_S_CS : HD_S_Tout[s1] < HD_S_Tout[s2]} (HD_S_lane_width[s2] + HD_XPitch);

# Two streams cannot have the same X position
subject to HD_S_Xpos_MinDist_hot{s1 in HD_S_HS, s2 in HD_S_HS : HD_S_Tout[s1] = HD_S_Tout[s2]} :
	abs(HD_S_lane_Xpos[s1] - HD_S_lane_Xpos[s2]) >= HD_XPitch;

subject to HD_S_Xpos_MinDist_cold{s1 in HD_S_CS, s2 in HD_S_CS : HD_S_Tout[s1] = HD_S_Tout[s2]} :
	abs(HD_S_lane_Xpos[s1] - HD_S_lane_Xpos[s2]) >= HD_XPitch;

subject to HD_S_Xpos_MinDist {s in HD_Streams, as in HD_Streams : s <> as } :
	abs(HD_S_lane_Xpos[s] - HD_S_lane_Xpos[as]) >= HD_XPitch + min(HD_S_lane_width[s], HD_S_lane_width[as]);

# fixing first lane position
subject to HD_S_Xpos_hot_min :
	min{s in HD_S_HS} HD_S_lane_Xpos[s] = 0;

# HX X position constrained within stream lane
subject to HD_S_HX_lane_hot_min{s in HD_S_HS, e in HD_Connections[s]} :
	HD_HX_Xpos_hot[e] >= HD_S_lane_Xpos[s];

subject to HD_S_HX_lane_hot_max{s in HD_S_HS, e in HD_Connections[s]} :
	HD_HX_Xpos_hot[e] <= HD_S_lane_Xpos[s] + HD_S_lane_width[s];

subject to HD_S_HX_lane_cold_min{s in HD_S_CS, e in HD_Connections[s]} :
	HD_HX_Xpos_cold[e] >= HD_S_lane_Xpos[s];

subject to HD_S_HX_lane_cold_max{s in HD_S_CS, e in HD_Connections[s]} :
	HD_HX_Xpos_cold[e] <= HD_S_lane_Xpos[s] + HD_S_lane_width[s];

# X position of each stream with respect to its connections
subject to HD_S_Xpos_Hot {s in HD_S_HS} :
	HD_S_Xpos[s] = HD_S_lane_Xpos[s] + HD_S_lane_width[s]/2;

subject to HD_S_Xpos_Cold {s in HD_S_CS} :
	HD_S_Xpos[s] = HD_S_lane_Xpos[s] + HD_S_lane_width[s]/2;

# Fixing X position of exchangers, when only one connections is available
subject to HD_S_HX_Xpos_hot_one{s in HD_S_HS, e in HD_Connections[s] : card{HD_Connections[s]}=1} :
	HD_HX_Xpos_hot[e] = HD_S_lane_Xpos[s];

subject to HD_S_HX_Xpos_cold_one{s in HD_S_CS, e in HD_Connections[s] : card{HD_Connections[s]}=1} :
	HD_HX_Xpos_cold[e] = HD_S_lane_Xpos[s];

# Two exchangers cannot have the same X position
subject to HD_HX_Hot_Xpos_MinDist {s in HD_S_HS , e1 in HD_Connections[s] , e2 in HD_Connections[s] : e1<>e2 } :
	abs(HD_HX_Xpos_hot[e1]-HD_HX_Xpos_hot[e2]) >= HD_XPitch;
	
subject to HD_HX_Cold_Xpos_MinDist {s in HD_S_CS , e1 in HD_Connections[s] , e2 in HD_Connections[s] : e1<>e2 } :
	abs(HD_HX_Xpos_cold[e1]-HD_HX_Xpos_cold[e2]) >= HD_XPitch;

#subject to HD_HX_XMinDist_hot{e1 in HD_HeatExchangers, e2 in HD_HeatExchangers : e1<>e2 } :
#	abs(HD_HX_Xpos_hot[e1] - HD_HX_Xpos_hot[e2]) >= HD_XPitch;

#subject to HD_HX_XMinDist_cold{e1 in HD_HeatExchangers, e2 in HD_HeatExchangers : e1<>e2 } :
#	abs(HD_HX_Xpos_cold[e1] - HD_HX_Xpos_cold[e2]) >= HD_XPitch;
	
# Sorting heat exchangers Y position by mean temperature
subject to HD_HX_Ypos{e in HD_HeatExchangers, ec in HD_HeatExchangers : ec<>e and HD_HX_Tmean[e] > HD_HX_Tmean[ec]} :
	HD_HX_Ypos_up[e] >= HD_HX_Ypos_up[ec] + HD_YPitch;

# Two exchangers cannot have the same Y position
subject to HD_HX_Ypos_MinDist {e in HD_HeatExchangers, ec in HD_HeatExchangers : ec<>e and HD_HX_Tmean[e] = HD_HX_Tmean[ec]} :
	abs(HD_HX_Ypos_up[e]-HD_HX_Ypos_up[ec]) >= HD_YPitch;


# Y position of streams
subject to HD_S_Ypos_up_fix {s in HD_Streams} :
	HD_S_Ypos_up[s] = (max{sx in HD_Connections[s]} HD_HX_Ypos_up[sx]) + HD_YPitch;

subject to HD_S_Ypos_down_fix {s in HD_Streams} :
	HD_S_Ypos_down[s] = (min{sx in HD_Connections[s]} HD_HX_Ypos_down[sx]) - HD_YPitch;

# fixing first stream Y position
subject to HD_S_Ypos_min :
	min{s in HD_Streams} HD_S_Ypos_down[s] = 0;



