################################################
########                               #########     
########          AUTO PPA TEST        #########   
########                               #########      
################################################

## Setting Working Directory According to Country ##
## Simply change the country name on the first and third lines below to the country you want a PPA for. The Script will do ther rest. ##

Country <- "Kenya"
setwd('C:/Users/Tim/Google Drive/projects/Linksbridge/repository/PPA-Automation/engine/Country Test Data')
setwd("./Kenya")

############################################# NO USER INPUT BEYOND THIS POINT #################################################################

######################
##   Load Packages  ##
######################

library(XLConnect)
library(stringr)
library(plyr) 
library(stringdist)
library(survey)
library(foreign)
library(tools)
library(dplyr)
library(tidyr)


###########################
##   Read in User Input  ##
###########################

# Country.Inputs <- "Philippines Data Inputs for PPA Automation ALL RAW.xlsx"
Country.Inputs <- paste(Country, "Data Inputs for PPA Automation.xlsx")
Metadata <- readWorksheetFromFile(Country.Inputs, sheet = "Subnational", header = TRUE)
Level.Mapping <- readWorksheetFromFile(Country.Inputs, sheet = "Facility Sector & Level Mapping", header = TRUE)
Subnational.Mapping <- readWorksheetFromFile(Country.Inputs, sheet = "Region Mapping", header = TRUE)

# "Univeral" Data Read-In Function for Different File Types Applicable to the PPA

read.PPA <- function (data){
  if (!is.na(data))
  {
    if (file_ext(data) == "dta" || file_ext(data) == "DTA"){
      dta.read.attempt.1 <- try(read.dta(data, convert.factors = TRUE))
      if (class(dta.read.attempt.1) == "data.frame"){
        read.dta(data, convert.factors = TRUE)
      } else {
        read.dta(data, convert.factors = FALSE)
      }
    } else {
      read.csv(data, header = TRUE)
    } 
  }
}

# Defining Data Sources by Pathway Data Point
rownames(Metadata) <- Metadata$Pathway.Data.Point

N.Facility.Data.Source <- Metadata['Number of Facilities', 'Data.Source']
N.Facility.Data.Source.Dots <- gsub(" ", ".", N.Facility.Data.Source)
N.Facility.Data <- read.PPA(N.Facility.Data.Source)

Care.Seeking.Data.Source <- Metadata['Care Seeking', 'Data.Source']
Care.Seeking.Data.Source.Dots <- gsub(" ", ".", Care.Seeking.Data.Source)
Care.Seeking.Data <- read.PPA(Care.Seeking.Data.Source)

Dx.Data.Source <- Metadata['Diagnostic Availability 1', 'Data.Source']
Dx.Data.Source.Dots <- gsub(" ", ".", Dx.Data.Source)
Dx.Data <- read.PPA(Dx.Data.Source)

Tx.Data.Source <- Metadata['Treatment Availability 1', 'Data.Source']
Tx.Data.Source.Dots <- gsub(" ", ".", Tx.Data.Source)
Tx.Data <- read.PPA(Tx.Data.Source)


###############################
##   Prep Data for Analysis  ##
###############################

# convernting NAs in the above datasources to ""
Metadata[is.na(Metadata)] <- "" 
Level.Mapping[is.na(Level.Mapping)] <- ""
Subnational.Mapping[is.na(Subnational.Mapping)] <- ""

# Adding a column to Level.Mapping concatenating Sector and Type
Level.Mapping$Sector.Type <- paste(Level.Mapping$Health.Facility.Sector, Level.Mapping$Health.Facility.Type)
Level.Mapping$Sector.Level <- paste(Level.Mapping$PPA.Sector, Level.Mapping$PPA.Level)
trim <- function (x) gsub("^\\s+|\\s+$", "", x) #removes leading and trailing white spaces
Level.Mapping$Sector.Type <- trim(Level.Mapping$Sector.Type)


#########################################
##   Define Data Analysis Functions    ##
#########################################

#Subsets raw data IF the metadata points to a subset column(s) 

subset.1 <- function (Pathway.Data, Pathway.Data.Point) {
  Subset.Column.Name <- Metadata[Pathway.Data.Point, 'Subset.Column.Name']
  Subset.Column.Name <- gsub(" ", ".", Subset.Column.Name)
  Subset.Column <- Pathway.Data[, Subset.Column.Name]
  Subset.Values <- Metadata[Pathway.Data.Point, 'Subset.Values']
  Subset.Values <- unlist(str_split(Subset.Values, ","))
  Subset.Values <- gsub(" ", "", Subset.Values)
  if (Subset.Values == "notna") {
    Subset.Pathway.Data <- Pathway.Data[!is.na(Subset.Column), ]
    Subset.Pathway.Data  
  } else {
    Subset.Pathway.Data <- Pathway.Data[Subset.Column == Subset.Values & !is.na(Subset.Column), ]
    Subset.Pathway.Data  
  }
}

subset.2 <- function (Pathway.Data, Pathway.Data.Point) {
  Subset.Column.Name <- Metadata[Pathway.Data.Point, 'Subset.Column.Name']
  Subset.Column.Name <- gsub(" ", ".", Subset.Column.Name)
  Subset.Values <- Metadata[Pathway.Data.Point, 'Subset.Values']
  Subset.Values <- unlist(str_split(Subset.Values, ","))
  Subset.Values <- gsub(" ", "", Subset.Values)
  Subset.Column <- Pathway.Data[, Subset.Column.Name]
  
  Subset.Column.Name.2 <- Metadata[Pathway.Data.Point, 'Subset.Column.Name.2']
  Subset.Column.Name.2 <- gsub(" ", ".", Subset.Column.Name.2)
  Subset.Values.2 <- Metadata[Pathway.Data.Point, 'Subset.Values.2']
  Subset.Values.2 <- unlist(str_split(Subset.Values.2, ","))
  Subset.Values.2 <- gsub(" ", "", Subset.Values.2)
  Subset.Column.2 <- Pathway.Data[, Subset.Column.Name.2]
  
  if (any(Subset.Values == "notna" & Subset.Values.2 == "notna")) {
    Subset.Pathway.Data <- Pathway.Data[!is.na(Subset.Column) & !is.na(Subset.Column.2), ]
    Subset.Pathway.Data  
  } else if (any(Subset.Values == "notna" & Subset.Values.2 != "notna")) {
    Subset.Pathway.Data <- Pathway.Data[Subset.Column == Subset.Values.2 & !is.na(Subset.Column), ]
    Subset.Pathway.Data  
  } else if (any(Subset.Values != "notna" & Subset.Values.2 == "notna")) {
    Subset.Pathway.Data <- Pathway.Data[Subset.Column == Subset.Values & !is.na(Subset.Column.2), ]
    Subset.Pathway.Data  
  } else {
    Subset.Pathway.Data <- Pathway.Data[Subset.Column == Subset.Values & !is.na(Subset.Column) 
                                        & Subset.Column.2 == Subset.Values.2 & !is.na(Subset.Column.2), ]
  }
  Subset.Pathway.Data
}

subset.raw <- function (Pathway.Data, Pathway.Data.Point){
  Subset.Column.Name <- Metadata[Pathway.Data.Point, 'Subset.Column.Name']
  Subset.Column.Name.2 <- Metadata[Pathway.Data.Point, 'Subset.Column.Name.2']
  if (Subset.Column.Name == "") {
    Pathway.Data
  } else if (Subset.Column.Name.2 == "" & Subset.Column.Name != ""){
    Subset.Pathway.Data <- subset.1(Pathway.Data, Pathway.Data.Point)
    Subset.Pathway.Data
  } else {
    Sub.Subset.Pathway.Data <- subset.2(Pathway.Data, Pathway.Data.Point)
  }
}


#Adds a column to the data sources combining sector and type

sector.type.adder <- function (Pathway.Data, Pathway.Data.Point){
  Pathway.Data.Sector.Column.Name <- Metadata[Pathway.Data.Point, 'Facility.Sector.Column.Name']
  Pathway.Data.Sector.Column.Name <- str_replace_all(Pathway.Data.Sector.Column.Name, "[ ()/,]", ".")
  
  Pathway.Data.Type.Column.Name <- Metadata[Pathway.Data.Point, 'Facility.Type.Column.Name']
  Pathway.Data.Type.Column.Name <- str_replace_all(Pathway.Data.Type.Column.Name, "[ ()/,]", ".")
  
  if (Pathway.Data.Sector.Column.Name == ""){
    Pathway.Data$Sector.Type <- Pathway.Data[, Pathway.Data.Type.Column.Name]  
  } else if (Pathway.Data.Type.Column.Name == ""){
    Pathway.Data$Sector.Type <- Pathway.Data[, Pathway.Data.Sector.Column.Name]    
  } else {
    Pathway.Data$Sector.Type <- paste(Pathway.Data[, Pathway.Data.Sector.Column.Name], Pathway.Data[, Pathway.Data.Type.Column.Name])
  }
  Pathway.Data
}

#Adds a column to the data sources mapping the sector.type to the appropriate PPA Sector and Level
sector.level.mapper <- function (Pathway.Data, Pathway.Data.Source){
  Level.Mapping.Pathway.Data <- subset(Level.Mapping, (Level.Mapping$Data.Source == Pathway.Data.Source))
  Sector.Pathway.Data <- Level.Mapping.Pathway.Data$Health.Facility.Sector
  Type.Pathway.Data <- Level.Mapping.Pathway.Data$Health.Facility.Type
  PPA.Sector.Pathway.Data <- Level.Mapping.Pathway.Data$PPA.Sector
  PPA.Level.Pathway.Data <- Level.Mapping.Pathway.Data$PPA.Level
  Sector.Type.Pathway.Data <- Level.Mapping.Pathway.Data$Sector.Type
  Sector.Level.Pathway.Data <- Level.Mapping.Pathway.Data$Sector.Level
  Pathway.Data$Sector.Level <- mapvalues(Pathway.Data$Sector.Type, from = Sector.Type.Pathway.Data, to = Sector.Level.Pathway.Data)
  Pathway.Data
}

#Adds a column to the data sources mapping the subnational unit names from the data source to the master subnational unit names
subnational.adder <- function (Pathway.Data, Pathway.Data.Point, Pathway.Data.Source.Dots) {
  Pathway.Data.Subnational.Column.Name <- Metadata[Pathway.Data.Point, 'Aggregation.Column.Name']
  Pathway.Data.Subnational.Column.Name <- gsub(" ", ".", Pathway.Data.Subnational.Column.Name)
  Pathway.Data.Subnational.Vector <- as.vector(Pathway.Data[, Pathway.Data.Subnational.Column.Name])
  Subnational.Names.Pathway.Data <- Subnational.Mapping[, Pathway.Data.Source.Dots]
  Subnational.Names.Master <- Subnational.Mapping[, 'Master.Region.Name']
  Pathway.Data$Subnational <- mapvalues(Pathway.Data.Subnational.Vector, from = Subnational.Names.Pathway.Data, to = Subnational.Names.Master)
  Pathway.Data
}

# Summarizes raw data by count (n) for subnational unit and sector/level#
summarize.raw.n <- function (Pathway.Data, Pathway.Data.Point) {
  Weight.Column.Name <- Metadata[Pathway.Data.Point, 'Weight.Column.Name']
  Weight.Column.Name <- gsub(" ", ".", Weight.Column.Name)
  Weight.Multipier <- Metadata[Pathway.Data.Point, 'Weight.Multiplier']
  
  if (Weight.Column.Name == ""){
    Pathway.Data <- ddply(Pathway.Data, .(Subnational, Sector.Level), summarize, "Pathway.Data.Point" = length(Sector.Level))
    Pathway.Data <- Pathway.Data[order(Pathway.Data$Subnational, Pathway.Data$Sector.Level), ]
  } else {
    Weight.Column <- Pathway.Data[ , Weight.Column.Name]
    Pathway.Data$PPA.Weight <- Weight.Column * Weight.Multiplier
    Pathway.Data <- ddply(Pathway.Data, .(Subnational, Sector.Level), summarize, "Pathway.Data.Point" = sum(PPA.Weight))
    Pathway.Data <- Pathway.Data[order(Pathway.Data$Subnational, Pathway.Data$Sector.Level), ]
  }
  Pathway.Data
}


# Summarizes raw careseeking data by the proportion of patients that seek care at a given sector/level
summarize.raw.prop.cs <- function (Pathway.Data, Pathway.Data.Point) {
  Pathway.Data <- summarize.raw.n(Pathway.Data)
  N.By.Sub <- ddply(Pathway.Data, .(Subnational), summarize, "N.By.Sub" = sum(Pathway.Data.Point))
  Pathway.Data$N.By.Sub <- mapvalues(Pathway.Data$Subnational, N.By.Sub$Subnational, N.By.Sub$N.By.Sub)
  Pathway.Data$Proportion <- as.numeric(Pathway.Data$Pathway.Data.Point)/as.numeric(Pathway.Data$N.By.Sub)
  Pathway.Data$Pathway.Data.Point <- NULL
  Pathway.Data$N.By.Sub <- NULL
  Pathway.Data
}

# Summarizes raw service availability data. For each sector/level, counts the number of facilities with a given service availale (numerator)
# Then calculates this a as a proportion of all facilities at that sector/level (denominator). 

summarize.raw.n.service.availability <- function (Services.Data, Pathway.Data.Point) {
  Variable.Column.Name <- Metadata[Pathway.Data.Point, 'Variable.Column.Name']
  Variable.Column.Name <gsub("", ".", Variable.Column.Name)
  Values <- Metadata[Pathway.Data.Point, 'Values.to.Count']
  Values <- unlist(str_split(Values, ","))
  Values <- gsub(" ", "", Values)
  Variable.Column <- Services.Data[, Variable.Column.Name]
  Values.to.Count <- Services.Data[Variable.Column == Values, ]
  Values.to.Count <- summarize.raw.n(Values.to.Count)
  colnames(Values.to.Count)[colnames(Values.to.Count) == "Pathway.Data.Point"] <- "Numerator"
  Values.to.Count
}

summarize.prop.service.availability <- function (Service, N.Facilities, Pathway.Data.Point) {
  colnames(N.Facilities)[colnames(N.Facilities) == "N.Facilities"] <- "Denominator"
  Services.DF <- merge(N.Facilities, Service, all.x = TRUE)
  Services.DF[is.na(Services.DF)] <- 0
  Services.DF$Proportion <- as.numeric(Services.DF$Numerator)/as.numeric(Services.DF$Denominator)
  Services.DF$Proportion[Services.DF$Proportion > 1] <- 1
  Services.DF$Numerator <- NULL
  Services.DF$Denominator <- NULL
  Services.DF
}


##################
## N Facilities ##
##################

N.Facility.Data <- subset.raw(N.Facility.Data, "Number of Facilities")
N.Facility.Data <- sector.type.adder(N.Facility.Data, 'Number of Facilities')
N.Facility.Data <- sector.level.mapper(N.Facility.Data, N.Facility.Data.Source)
N.Facility.Data <- subnational.adder(N.Facility.Data, "Number of Facilities", N.Facility.Data.Source.Dots)
N.Facilities <- summarize.raw.n(N.Facility.Data, "Number of Facilities")
colnames(N.Facilities)[colnames(N.Facilities) == "Pathway.Data.Point"] <- "N.Facilities"


##################
## Care Seeking ##
##################

Care.Seeking.Data <- subset.raw(Care.Seeking.Data, "Care Seeking")
Care.Seeking.Data <- sector.type.adder(Care.Seeking.Data, "Care Seeking")
Care.Seeking.Data <- sector.level.mapper(Care.Seeking.Data, Care.Seeking.Data.Source)
Care.Seeking.Data <- subnational.adder(Care.Seeking.Data, "Care Seeking", Care.Seeking.Data.Source.Dots)
Care.Seeking <- summarize.raw.prop.cs(Care.Seeking.Data, "Care Seeking")
colnames(Care.Seeking)[colnames(Care.Seeking) == "Proportion"] <- "Care.Seeking"


#####################
## Dx Availability ##
#####################

Dx.Data <- subset.raw(Dx.Data, "Diagnostic Availability 1")
Dx.Data <- sector.type.adder(Dx.Data, "Diagnostic Availability 1")
Dx.Data <- sector.level.mapper(Dx.Data, Dx.Data.Source)
Dx.Data <- subnational.adder(Dx.Data, "Diagnostic Availability 1", Dx.Data.Source.Dots)
N.Dx <- summarize.raw.n.service.availability(Dx.Data, "Diagnostic Availability 1")
Dx <- summarize.prop.service.availability(N.Dx, N.Facilities, "Diagnostic Availability 1")
colnames(Dx)[colnames(Dx) == "Proportion"] <- "Dx.Availability"


#####################
## Tx Availability ##
#####################

Tx.Data <- subset.raw(Tx.Data, "Treatment Availability 1")
Tx.Data <- sector.type.adder(Tx.Data, "Treatment Availability 1")
Tx.Data <- sector.level.mapper(Tx.Data, Tx.Data.Source)
Tx.Data <- subnational.adder(Tx.Data, "Treatment Availability 1", Tx.Data.Source.Dots)
N.Tx <- summarize.raw.n.service.availability(Tx.Data, "Treatment Availability 1")
Tx <- summarize.prop.service.availability(N.Tx, N.Facilities, "Treatment Availability 1")
colnames(Tx)[colnames(Tx) == "Proportion"] <- "Tx.Availability"


#########################
## Put It All Together ##
#########################

Pathway.DF <- merge(N.Facilities, Care.Seeking, all.x = TRUE, all.y = TRUE)
Pathway.DF <- merge(Pathway.DF, Dx, all.x = TRUE, all.y = TRUE)
Pathway.DF <- merge(Pathway.DF, Tx, all.x = TRUE, all.y = TRUE)
Pathway.DF[is.na(Pathway.DF)] <- 0

Pathway.DF$Dx.Access <- Pathway.DF$Care.Seeking * Pathway.DF$Dx.Availability
Pathway.DF$Tx.Access <- Pathway.DF$Care.Seeking * Pathway.DF$Tx.Availability

write.csv(Pathway.DF, paste(Country, "PPA Master Data.csv"))
