library(data.table)
library(scatterD3)
# 
# vse = fread("full1.csv")
# vse = rbind(vse,fread("full2.csv"))
# vse[,mean(util-rand)/mean(best-rand),by=list(method,chooser)]
# 
# vse[chooser=="honBallot",mean(util-rand)/mean(best-rand),by=list(method,chooser)]
# 
# ovse = fread("lowDks2.csv")
# ovse[,mean(util-rand)/mean(best-rand),by=list(method,chooser)]
# 
# ovse[chooser %in% c("honBallot","Oss.hon_strat.","Prob.strat50_hon50."),mean(util-rand)/mean(best-rand),by=list(method,chooser)]
# 
# mvse = fread("media413.csv")
# mvse = rbind(mvse,fread("media41.csv"), fill=T)
# mvse[,mean(util-rand)/mean(best-rand),by=list(method,chooser)]
# 
# mvse[chooser %in% c("honBallot","Oss.hon_strat.","Prob.strat50_hon50."),mean(util-rand)/mean(best-rand),by=list(method,chooser)]
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# fvse = fread("fuzzy5.csv")
# fvse[,mean(util-rand)/mean(best-rand),by=list(method,chooser)]
# 
# fvse = fread("wtf1.csv")
# 
# fvse = rbind(fvse,fread("wtf2.csv"))

fvse = fread("candnumbertest1.csv")
numVoters = mean(fvse[,numVoters])
vses = fvse[method != "ApprovalPoll",list(VSE=mean((r1WinnerUtil - meanCandidateUtil) / 
                      (magicBestUtil - meanCandidateUtil))),by=.(method,backgroundStrat)]
dcast(vses, method ~ backgroundStrat)
vses

fromhons = fvse[backgroundStrat=="honBallot",
     list(
       vse=mean((r1WinnerUtil - meanCandidateUtil) / (magicBestUtil - meanCandidateUtil)),
       fgMatters=mean(fgUtilDiff != 0),
       VSEDiff=mean((totalUtil - r1WinnerUtil) / (magicBestUtil - meanCandidateUtil)),
       #margStrategicRegret=mean(margStrategicRegret),
       pivotalUtilDiff=mean(pivotalUtilDiff),
       deciderUtilDiffSum=mean(deciderUtilDiffSum),
       avgStrategicRegret=mean((avgStrategicRegret) / (magicBestUtil - meanCandidateUtil) / numVoters),
       fgHelpedUtilDiff=mean((fgHelpedUtilDiff) / (magicBestUtil - meanCandidateUtil) / numVoters),
       fgHarmedUtilDiff=mean((fgHarmedUtilDiff) / (magicBestUtil - meanCandidateUtil) / numVoters)
     ),
     by=.(method,backgroundStrat, fgStrat, fgArgs, fgTargets)]
fromhons

fromawares = fvse[((backgroundStrat=="vaBallot"  & method != "Minimax") | (backgroundStrat=="honBallot" &method == "Minimax")), #& !fgStrat %in% c("", "vaBallot"),
     list(
       vse=mean((r1WinnerUtil - meanCandidateUtil) / (magicBestUtil - meanCandidateUtil)),
       fgMatters=mean(fgUtilDiff != 0),
       VSEDiff=mean((totalUtil - r1WinnerUtil) / (magicBestUtil - meanCandidateUtil)),
       #margStrategicRegret=mean(margStrategicRegret),
       firstDeciderUtilDiff=mean(firstDeciderUtilDiff),
       deciderUtilDiffSum=mean(deciderUtilDiffSum),
       avgStrategicRegret=mean(avgStrategicRegret / (magicBestUtil - meanCandidateUtil) / numVoters),
       fgHelpedUtilDiff=mean(fgHelpedUtilDiff  / (magicBestUtil - meanCandidateUtil) / numVoters),
       fgHarmedUtilDiff=mean(fgHarmedUtilDiff / (magicBestUtil - meanCandidateUtil) / numVoters)),
     by=.(method,backgroundStrat, fgStrat, fgArgs, fgTargets)]
fromawares

fromall = fvse[method !="ApprovalPoll",
                list(
                  vse=mean((r1WinnerUtil - meanCandidateUtil) / (magicBestUtil - meanCandidateUtil)),
                  fgMatters=mean(fgUtilDiff != 0),
                  VSEDiff=mean((totalUtil - r1WinnerUtil) / (magicBestUtil - meanCandidateUtil)),
                  #margStrategicRegret=mean(margStrategicRegret),
                  firstDeciderUtilDiff=mean(firstDeciderUtilDiff),
                  deciderUtilDiffSum=mean(deciderUtilDiffSum),
                  avgStrategicRegret=mean((avgStrategicRegret) / (magicBestUtil - meanCandidateUtil) / numVoters),
                  fgHelpedUtilDiff=mean((fgHelpedUtilDiff) / (magicBestUtil - meanCandidateUtil) / numVoters),
                  fgHarmedUtilDiff=mean((fgHarmedUtilDiff) / (magicBestUtil - meanCandidateUtil) / numVoters)
                ),
                by=.(method,backgroundStrat, bgArgs, fgStrat, fgArgs, fgTargets)]
fromall

besttargets = function(grouped) {
  grouped[,target:=fgTargets[order(-avgStrategicRegret)[1]], by=.(method,backgroundStrat, fgStrat, fgArgs)]
#  justBest = grouped[target,,]
  chosen = grouped[grouped[, .I[avgStrategicRegret == max(avgStrategicRegret)], by = .(method,backgroundStrat, fgStrat, fgArgs)]$V1]
}
bestfromawares = besttargets(fromawares)
bestfromawares

library(ggplot2)
library(ggthemes)
library(dplyr)
library(forcats)
library(scales)

#vse as bars
(ggplot(data = vses, aes(x = VSE, y = method, group = method)) 
  + geom_line(size=3) + xlim(.65,1.00) + theme_gdocs() 
  + theme(axis.title.y=element_blank()) + xlab("% Voter Satisfaction Efficiency (VSE)")) 

#vse as dots
(
vses[!(method=="Minimax" & backgroundStrat=="vaBallot"),] %>% 
    mutate(method = method 
                    %>% fct_reorder(VSE, .fun='mean') 
                    %>% recode(`STAR`="STAR", 
                               `PluralityTop2`="Plurality Top Two", 
                               `Minimax`="Smith/Minimax", 
                               `Irv`="IRV (RCV)", 
                               `ApprovalTop2`="Approval Top Two", 
                               ),
                                  #to=c("STAR", "Plurality/Runoff", "Plurality", "Smith/Minimax", irv="IRV (RCV)", "Approval/Runoff", "Approval")))
           #VSE = VSE * 100
           ) %>%
    ggplot(
          aes(x = VSE, y = as.factor(method), color = backgroundStrat)) 
  + scale_x_continuous(labels=scales::percent_format(accuracy = 1))#, limits=c(.68, 1.0))
    + geom_point(size=3) #+ xlim(.65,1.00) 
  + theme_gdocs() 
    + theme(axis.title.y=element_blank()) + xlab("% Voter Satisfaction Efficiency (VSE)")
    + labs(color="Voter Behavior") + scale_colour_colorblind(labels = c("Honest / Naive", "Viability-aware"))
   # + scale_y_discrete(breaks=c("STAR", "Plurality", "PluralityTop2", "Minimax", "Irv", "ApprovalTop2", "Approval"),
  #                     labels=c("STAR", "Plurality/Runoff", "Plurality", "Smith/Minimax", irv="IRV (RCV)", "Approval/Runoff", "Approval"))
) 

#ASR for viability-aware
(
  fromhons %>% 
    mutate(method = method 
           %>% fct_reorder(avgStrategicRegret, .fun='mean') 
           %>% recode(`STAR`="STAR", 
                      `PluralityTop2`="Plurality Top Two", 
                      `Minimax`="Smith/Minimax", 
                      `Irv`="IRV (RCV)", 
                      `ApprovalTop2`="Approval Top Two", 
           ),
           #to=c("STAR", "Plurality/Runoff", "Plurality", "Smith/Minimax", irv="IRV (RCV)", "Approval/Runoff", "Approval")))
           #VSE = VSE * 100
    ) %>%
    ggplot(
      aes(x = avgStrategicRegret, y = as.factor(method))) 
  + scale_x_continuous(labels=scales::percent_format(accuracy = 1), limits = c(-.0,.38))
  + geom_point(size=3) #+ xlim(.65,1.00) 
  + theme_gdocs() 
  + theme(axis.title.y=element_blank()) + xlab("% Average Strategic Regret (ASR) for not casting a viability-aware ballot")
  #+ labs(color="Voter Behavior") 
  #+ scale_colour_colorblind(labels = c("Honest / Naive", "Viability-aware"))
  # + scale_y_discrete(breaks=c("STAR", "Plurality", "PluralityTop2", "Minimax", "Irv", "ApprovalTop2", "Approval"),
  #                     labels=c("STAR", "Plurality/Runoff", "Plurality", "Smith/Minimax", irv="IRV (RCV)", "Approval/Runoff", "Approval"))
) 


#ASR for targeted strategy
(
  bestfromawares %>% 
    mutate(method = method 
           %>% fct_reorder(avgStrategicRegret, .fun='mean') 
           %>% recode(`STAR`="STAR", 
                      `PluralityTop2`="Plurality Top Two", 
                      `Minimax`="Smith/Minimax", 
                      `Irv`="IRV (RCV)", 
                      `ApprovalTop2`="Approval Top Two", 
           ),
           #to=c("STAR", "Plurality/Runoff", "Plurality", "Smith/Minimax", irv="IRV (RCV)", "Approval/Runoff", "Approval")))
           #VSE = VSE * 100
    ) %>%
    ggplot(
      aes(x = avgStrategicRegret, y = as.factor(method), shape = as.factor(fgStrat), color = fgArgs)) 
  + scale_x_continuous(labels=scales::percent_format(accuracy = 1))
  + geom_point(size=3) #+ xlim(.65,1.00) 
  + theme_gdocs() 
  + theme(axis.title.y=element_blank()) + xlab("% Average Strategic Regret (ASR) for not using targeted strategy")
  + labs(color="Strategy level", shape="Strategy type") 
  + scale_colour_colorblind(labels = c("Honest", "Semi-honest", "Dishonest", "Bullet"))
  + scale_shape(labels = c("Compromise", "Die-hard"))
  # + scale_y_discrete(breaks=c("STAR", "Plurality", "PluralityTop2", "Minimax", "Irv", "ApprovalTop2", "Approval"),
  #                     labels=c("STAR", "Plurality/Runoff", "Plurality", "Smith/Minimax", irv="IRV (RCV)", "Approval/Runoff", "Approval"))
) 

