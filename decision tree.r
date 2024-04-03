library(quantmod)
library(lubridate)
library(e1071)
library(rpart)
library(rpart.plot)
library(ROCR)
library(fortunes)
options(warn=-1)
a<- c('AAPL','FB','GE','GOOG','GM','IBM','MSFT')
for( i in 1:length(a))
{
  SYM<- a[i]
  print('------------------')
print(paste('Prediciting the output for',SYM,sep=' '))
trainPerc<-0.75
date<- as.Date(Sys.Date() -1)
endDate<- date
d<-as.POSIXlt(endDate)
d$year<- d$year - 2
startDate<- as.Date(d)
STOCK<- getSymbols(
  SYM,
  env=NULL,
  src="yahoo",
  from=startDate,
  to=endDate
)
RSI3<-RSI(Op(STOCK), n=3)
EMA5<-EMA(Op(STOCK),n=5)
EMAcross<-Op(STOCK)-EMA5
MACD<-MACD(Op(STOCK),
           fast=12,
           slow=26,
           signal=9)
MACDsignal<-MACD[,2]
SMI<-SMI(
  Op(STOCK),
  n=13,
  slow=25,
  fast=2,
  signal=9
)
SMI<-SMI[,1]
WPR<-WPR(Cl(STOCK),n=14)
WPR<-WPR[,1]
ADX<-ADX(STOCK,n=14)
ADX<-ADX[,1]
CCI<-CCI(Cl(STOCK),n=14)
CCI<-CCI[,1]
CMO	<-CMO(Cl(STOCK),n=14)
CMO<- CMO[,1]
ROC<-ROC(Cl(STOCK),n=2)
ROC<-ROC[,1]
PriceChange<-Cl(STOCK)- Op(STOCK)
Class<-ifelse(PriceChange > 0,"UP","DOWN")
DataSet<-data.frame(Class,RSI3, EMAcross,MACDsignal,SMI,WPR,ADX,CCI,CMO,ROC)
colnames(DataSet)<-
  c(
    "Class",
    "RSI3",
    "EMAcross",
    "MACDsignal",
    "Stochastic",
    "WPR",
    "ADX",
    "CCI",
    "CMO",
    "ROC"
    )
TrainingSet <- DataSet[1:floor(nrow(DataSet)*trainPerc),]
TestSet<-
  DataSet[(floor(nrow(DataSet)*trainPerc)+1):nrow(DataSet),]
DecisionTree<-
  rpart(
    Class ~ RSI3+EMAcross+WPR+ADX+CMO+CCI+ROC,
                    data = TrainingSet,
                    na.action = na.omit,
                    cp=.001
    )
prp(DecisionTree,type = 2,extra = 8)
fit<-printcp(DecisionTree)
mincp<-fit[which.min(fit[,'xerror']),'CP']
plotcp(DecisionTree, upper = "splits")
PrunedDecisionTree<- prune(DecisionTree,cp=mincp)
t<- prp(PrunedDecisionTree,type=2,extra=8)
confmat<-
  table(
    predict(PrunedDecisionTree,TestSet,type="class"),
    TestSet[,1],
    dnn=list('predicted','actual')
  )
print(confmat)
tryCatch({
acc<-
  (confmat[1,"DOWN"]+confmat[2,"UP"])*100/(confmat[2,"DOWN"]+confmat[1,"UP"]+confmat[1,"DOWN"]+confmat[1,"UP"])
xy<-
  paste('Decision Tree: considering the output for', SYM,sep = ' ')
yz<-
  paste('Accuracy =',
        acc,
        sep = ' ')
out<- paste(xy,yz,sep='\n')
print(out)
write(out,
      file = "out",
      append = TRUE,
      sep = "\n\n")
}, error=function(e){

})
predout<-data.frame(predict(PrunedDecisionTree,TestSet))
predval<-predout['UP']-predout['DOWN']
predclass<-ifelse(predout['UP']>= predout['DOWN'],1,0)
predds<-data.frame(predclass,TestSet$Class)
colnames(predds)<-c("pred","truth")
predds[,2]<-ifelse(predds[,2]=='UP',1,0)
pred<-prediction(predds$pred,predds$truth)
perf=performance(pred,measure = "tpr",x.measure = "fpr")
plot(perf,col=1:10)
auc.perf=performance(pred,measure = 'auc')
rmse.perf=performance(pred,measure = 'rmse')
print(paste('RMSE=', rmse.perf@y.values),sep = ' ')
print(paste('AUC =',auc.perf@y.values),sep = ' ')
abline(a=0,b=1,col="red")
print('------------------------------------------------------------------------------------------------------------')
}




