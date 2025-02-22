library(tidyverse)
library(readxl)
library(pheatmap)


path="/rds/general/project/hda_students_data/live/Group1"
setwd(path)
dataframe <- readRDS('TDS_final_group_1/result_data/step0/combined_data.rds')
colnames(dataframe) <- trimws(colnames(dataframe))


IntakesNum <- c("cooked vegetable in take","salad/raw vege intake", "dried fruit intake", "fresh fruit intake", "bread intake",
                "cereal intake","tea intake","coffee intake(per day)","water intake")
IntakesCat <- c("beef intake","pork intake","lamb/mutton intake","processed meat intake(per day)","cheese intake",
                "poultry intake","oily fish intake","non-oily fish intake")
TypesCat <- c("never eat eggs dairy wheat sugar","spread type","milk type used","bread type","cereal type","coffee type",
              "salt added to food","variation in diet","smoking status")


for (var in IntakesNum){
  dataframe[var] <- as.numeric(ifelse(dataframe[var] == 'Less than one',"0.5",
                                      ifelse(dataframe[var] == 'Do not know',NA,
                                             ifelse(dataframe[var] == 'Prefer not to answer',NA,dataframe[[var]]))))}

for (var in IntakesCat){
  dataframe[var] <- as.numeric(ifelse(dataframe[var] == 'Never', "0",
                                      ifelse(dataframe[var] == 'Less than once a week',"0.5",
                                             ifelse(dataframe[var] == 'Once a week',"1",
                                                    ifelse(dataframe[var] == '2-4 times a week',"3",
                                                           ifelse(dataframe[var] == '5-6 times a week',"5.5",
                                                                  ifelse(dataframe[var] == 'Once or more daily',"7", NA)))))))}
for (var in TypesCat){
  dataframe[var] <- as.factor(dataframe[[var]])}


#dataframe <- dataframe[complete.cases(dataframe[IntakesNum]),]
#dataframe <- dataframe[complete.cases(dataframe[IntakesCat]),]

par(mar = c(8, 4.1, 4.1, 2.1))
data <- dataframe[,c(1:7)]
colnames(data) <- gsub(" ", "", colnames(data), fixed = TRUE)

data['BMI']<-dataframe[['BMI']]
data["age"] <- dataframe[["age"]]
data["ethnic_background"] <- dataframe[["ethnic baackground"]]
data["sex"] <- dataframe[["sex"]]
data["qualification"] <- dataframe[["qualification"]]
data["alcohol_intake_frequency"]<- dataframe[["alcohol intake frequency"]]
data["Smoking"] <- dataframe[["smoking status"]]

data["Vegetable_Intake"] <- dataframe[["cooked vegetable in take"]] + dataframe[["salad/raw vege intake"]]
data["Fruit_Intake"] <- dataframe[["dried fruit intake"]] + dataframe[["fresh fruit intake"]]
data["Oily_Fish_Intake"] <- dataframe[["oily fish intake"]] 
data["non_oily_Fish_Intake"]<-dataframe[["non-oily fish intake"]]
data["RedMeat_Intake"] <- dataframe[["beef intake"]] + dataframe[["pork intake"]] + dataframe[["lamb/mutton intake"]] 
data["ProcessedMeat_Intake"] <- dataframe[["processed meat intake(per day)"]]
data["WhiteMeat_Intake"]<- dataframe[["poultry intake"]]
data["EDWS"] <- dataframe[["never eat eggs,dairy,wheat,sugar"]]
data["Bread_Intake"] <- dataframe[["bread intake"]]
data["Cheese_Intake"] <- dataframe[["cheese intake"]]
data["Cereal_Intake"] <- dataframe[["cereal intake"]]
data["Tea_Intake"] <- dataframe[["tea intake"]]
data["Coffee_Intake"] <- dataframe[["coffee intake(per day)"]]
data["Water_Intake"] <- dataframe[["water intake"]]
data["Milk_Type"] <- dataframe[["milk type used"]]
data["Spread_Type"] <- dataframe[["spread type"]]
data["Bread_Type"] <- dataframe[["bread type"]]
data["Cereal_Type"] <- dataframe[["cereal type"]]
data["Coffee_Type"] <- dataframe[["coffee type"]]
data["SaltAdded"] <- dataframe[["salt added to food"]]
data["DietVariation"] <- dataframe[["variation in diet"]]
data['sugar']<-dataframe[['total sugar']]#so many missing values






# Define colums names
Names <- colnames(data[,15:35])
data$LungCancer <- as.factor(data$LungCancer)

# Data characteristic plots

#Numeric variables
data.numeric <- na.omit(data[,c(8:33)]) %>%
  select_if(is.numeric) %>%
  gather(key = "variable", value = "value")


ggplot(data.numeric, aes(value)) +
  geom_density() +
  facet_wrap(~variable,scales = "free")+theme_clean()
dev.copy(device=png,'TDS_final_group_1/result_graph/step1/numeric_density.png')

dev.off()

ggplot(data, aes(x=sugar)) +
  geom_density(aes(col=LungCancer)) 
dev.copy(device=png,'TDS_final_group_1/result_graph/step1/sugar.png')

dev.off()




#Categorical variables

data.factor<- data[Names] %>%
  select_if(is.factor) 

lapply(colnames(data.factor), function(var){barplot(table(data.factor[var]),main =var,las=2 )
  a=paste0("TDS_final_group_1/result_graph/step1/",var)
  dev.copy(device=png, paste0(a,'.png'))
  dev.off()})



# Univariate Regressions without smoking
pval=lapply(Names,
            function(var) {
              res.logist1 <- glm(LungCancer ~ age_of_recruitement + ethnic_background + sex + qualification + alcohol_intake_frequency+BMI + Smoking, data = (data %>% drop_na(var)), family = binomial)
              formula2    <- as.formula(paste("LungCancer ~ age_of_recruitement + ethnic_background + sex + qualification + alcohol_intake_frequency + Smoking +BMI+", var))
              res.logist2 <- glm(formula2, data = data, family = binomial)
              pval=c(anova(res.logist1,res.logist2,test="Chisq")$'Pr(>Chi)'[2])
              names(pval)='pval'
              return(pval)})


pval=data.frame((pval))
pval=data.frame(t(pval))
rownames(pval)=Names
saveRDS(pval,"result_data/step_1/pval.rds")
par(mar=c(10,4,2,2))
plot(-log10(pval$pval),xaxt="n",xlab='',pch=16,lwd=2,ylab = '-ln(pvalue)',col=ifelse(pval$pval<=0.05/22,'black','skyblue'),ylim =c(0,-log(0.05/20)+10),type="h",
     main="p values for all nutrition variables")
abline(h=-log10(0.05/22),lty=2)
axis(1,labels=rownames(pval),at=c(1:22),las=2,)


dev.copy(device=png,'TDS_final_group_1/result_graph/step1/univariate_manhattenplot.png')

dev.off()




# Multivariate Regressions without smoking
formula    <- as.formula(paste("LungCancer ~", paste(Names, collapse=" + ")))
res.logist <- glm(formula, data = data[,c(1:35)], family = binomial)
print(summary(res.logist))

# Multivariate Regressions with smoking
formula    <- as.formula(paste("LungCancer ~ Smoking +", paste(Names, collapse=" + ")))
res.logist <- glm(formula, data = data, family = binomial)
print(summary(res.logist))

#significant smoking
#significant oily fish,processed meat, cheese,cereal,tea, coffee,water,salt


#Correlation Matrix
par(mar = c(5.1, 4.1, 4.1, 2.1))
a<-data[Names[]] %>%select_if(is.numeric)
a=data.frame(a)
a=drop_na(a)
mycor = cor(a,method = 'spearman')
saveRDS(mycor,"tds_final_group_1/result_data/nutrients_corr.rds")
pheatmap(mycor,cluster_rows = FALSE, cluster_cols = FALSE, border = NA,
         breaks = seq(-1, 1, length.out = 100))
dev.copy(png,'TDS_final_group_1/result_graph/step1/nutrition_correlation_map.png')
dev.off()
