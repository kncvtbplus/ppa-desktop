#####################################################################
########                                                    #########     
########          AUTO PPA SCRIPT TO CONNECT WITH UI        #########   
########                                                    #########      
#####################################################################


###########################
##   Initialize Objects  ##
###########################


###########################
##   Test Section Only   ##
###########################
# This section is only to test revisions to R script 
# Leave this section commented out when integrating with UI

#Country <- "Kenya"
#setwd('C:/Dropbox (Linksbridge)/Linksbridge/2018/Projects/TB/Current Projects/201801_PPA Automation/Country Test Data')
#setwd('C:/mine/projects/Linksbridge/engine/Country Test Data')
#setwd("./Kenya")
#Country.Inputs <- paste(Country, "UI.xlsx")
# Metadata <- readWorksheetFromFile(Country.Inputs, sheet = "Subnational", header = TRUE)
# rownames(Metadata) <- Metadata$Pathway.Data.Point
# Level.Mapping <- readWorksheetFromFile(Country.Inputs, sheet = "Facility Sector & Level Mapping", header = TRUE)
# Subnational.Mapping <- readWorksheetFromFile(Country.Inputs, sheet = "Region Mapping", header = TRUE)



######################
##   Load Packages  ##
######################

library(XLConnect) #Ok to not read in commented packages? They are only for reading in data, but JavaScript is doing that
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

# "Univeral" Data Read-In Function for Different File Types Applicable to the PPA
# JavaScript does this now, right? Do we remove some or all of this section?

read.PPA <- function(data)
{
  switch (
    toupper(file_ext(data)),
    "DTA"=
    {
      read.dta(data, convert.factors = FALSE)
    },
    "CSV"=
    {
      read.csv(data, stringsAsFactors = FALSE, header = TRUE)
    },
    {
      stop("Unsupported data source file extension: ",  toupper(file_ext(data)))
    }
  )
}

# Defining Data Sources by Pathway Data Point

N.Facility.Data.Source <- Metadata['N.Facilities', 'Data.Source']
N.Facility.Data.Source.Dots <- gsub(" ", ".", N.Facility.Data.Source)
N.Facility.Variable.Column.Name <- Metadata['N.Facilities', 'Variable.Column.Name']
if (N.Facility.Data.Source != "" && N.Facility.Variable.Column.Name != "")
{
  N.Facility.Data <- read.PPA(N.Facility.Data.Source)
}

Care.Seeking.Data.Source <- Metadata['Care.Seeking', 'Data.Source']
Care.Seeking.Data.Source.Dots <- gsub(" ", ".", Care.Seeking.Data.Source)
Care.Seeking.Variable.Column.Name <- Metadata['Care.Seeking', 'Variable.Column.Name']
if (Care.Seeking.Data.Source != ""  && Care.Seeking.Variable.Column.Name != "")
{
  Care.Seeking.Data <- read.PPA(Care.Seeking.Data.Source)
}

Dx.Data.Source <- Metadata['Dx.Availability.1', 'Data.Source']
Dx.Data.Source.Dots <- gsub(" ", ".", Dx.Data.Source)
Dx.Variable.Column.Name <- Metadata['Dx.Availability.1', 'Variable.Column.Name']
if (Dx.Data.Source != "" && Dx.Variable.Column.Name != "")
{
  Dx.Data <- read.PPA(Dx.Data.Source)
}

Tx.Data.Source <- Metadata['Tx.Availability.1', 'Data.Source']
Tx.Data.Source.Dots <- gsub(" ", ".", Tx.Data.Source)
Tx.Variable.Column.Name <- Metadata['Tx.Availability.1', 'Variable.Column.Name']
if (Tx.Data.Source != "" && Tx.Variable.Column.Name != "")
{
  Tx.Data <- read.PPA(Tx.Data.Source)
}


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

# Subsets data by subset columns 
subset.raw <- function(Pathway.Data, Pathway.Data.Point)
{
  # initialize subset data with original data
  Subset.Pathway.Data <- Pathway.Data
  
  # get subset columns
  Pathway.Data.Point.Subset.Columns <- Subset.Columns[[Pathway.Data.Point]]
  
  # subset by subset columns
  for (Subset.Column in Pathway.Data.Point.Subset.Columns)
  {
    Subset.Column.Name <- Subset.Column[["Column.Name"]]
    Subset.Values <- Subset.Column[["Column.Values"]]
    Subset.Pathway.Data <- Subset.Pathway.Data[Subset.Pathway.Data[[Subset.Column.Name]] %in% Subset.Values, ]
    
  }
  
  # return subset data
  Subset.Pathway.Data
  
}

test.subset.raw <- subset.raw(Care.Seeking.Data, "Care.Seeking")

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
  Pathway.Data$Sector.Level <- unlist(mapvalues(Pathway.Data$Sector.Type, from = Sector.Type.Pathway.Data, to = Sector.Level.Pathway.Data, warn_missing = FALSE))
  Pathway.Data
}

#Adds a column to the data sources mapping the subnational unit names from the data source to the master subnational unit names
subnational.adder <- function (Pathway.Data, Pathway.Data.Point, Pathway.Data.Source) {
  Pathway.Data.Subnational.Column.Name <- Metadata[Pathway.Data.Point, 'Aggregation.Column.Name']
  Pathway.Data.Subnational.Column.Name <- gsub(" ", ".", Pathway.Data.Subnational.Column.Name)
  Pathway.Data.Subnational.Vector <- as.vector(Pathway.Data[, Pathway.Data.Subnational.Column.Name])
  Subnational.Names.Pathway.Data <- Subnational.Mapping[[Pathway.Data.Source]]["Data.Source.Value"]
  Subnational.Names.Master <- Subnational.Mapping[[Pathway.Data.Source]]["Master.Value"]
  Pathway.Data$Subnational <- unlist(mapvalues(Pathway.Data.Subnational.Vector, from = Subnational.Names.Pathway.Data, to = Subnational.Names.Master, warn_missing = FALSE))
  Pathway.Data
}

# Summarizes raw data by count (n) for subnational unit and sector/level#
summarize.raw.n <- function (Pathway.Data, Pathway.Data.Point)
{
  if (nrow(Pathway.Data) == 0)
  {
    stop("Data subsetting and filtering resulted in zero row data set.")
  }
  
  Weight.Column.Name <- Metadata[Pathway.Data.Point, 'Weight.Column.Name']
  Weight.Column.Name <- gsub(" ", ".", Weight.Column.Name)
  Weight.Multipier <- Metadata[Pathway.Data.Point, 'Weight.Multiplier']
  
  if (Weight.Column.Name == "")
  {
    Pathway.Data <- ddply(Pathway.Data, .(Subnational, Sector.Level), summarize, "Pathway.Data.Point" = length(Sector.Level))
    Pathway.Data <- Pathway.Data[order(Pathway.Data$Subnational, Pathway.Data$Sector.Level), ]
  }
  else
  {
    Weight.Column <- Pathway.Data[ , Weight.Column.Name]
    Pathway.Data$PPA.Weight <- Weight.Column * Weight.Multiplier
    Pathway.Data <- ddply(Pathway.Data, .(Subnational, Sector.Level), summarize, "Pathway.Data.Point" = sum(PPA.Weight))
    Pathway.Data <- Pathway.Data[order(Pathway.Data$Subnational, Pathway.Data$Sector.Level), ]
  }
  Pathway.Data
}


# Summarizes raw careseeking data by the proportion of patients that seek care at a given sector/level
summarize.raw.prop.cs <- function (Pathway.Data, Pathway.Data.Point)
{
  if (nrow(Pathway.Data) == 0)
  {
    stop("Data subsetting and filtering resulted in zero row data set.")
  }
  
  Pathway.Data <- summarize.raw.n(Pathway.Data, Pathway.Data.Point)
  N.By.Sub <- ddply(Pathway.Data, .(Subnational), summarize, "N.By.Sub" = sum(Pathway.Data.Point))
  Pathway.Data$N.By.Sub <- unlist(mapvalues(Pathway.Data$Subnational, N.By.Sub$Subnational, N.By.Sub$N.By.Sub, warn_missing = FALSE))
  Pathway.Data$Proportion <- as.numeric(Pathway.Data$Pathway.Data.Point)/as.numeric(Pathway.Data$N.By.Sub)
  Pathway.Data$Pathway.Data.Point <- NULL
  Pathway.Data$N.By.Sub <- NULL
  Pathway.Data
}

# Summarizes raw service availability data. For each sector/level, counts the number of facilities with a given service availale (numerator)
# Then calculates this a as a proportion of all facilities at that sector/level (denominator). 

summarize.raw.n.service.availability <- function (Services.Data, Pathway.Data.Point) {
  Variable.Column.Name <- Metadata[Pathway.Data.Point, 'Variable.Column.Name']
  Variable.Column.Name <- gsub(" ", ".", Variable.Column.Name)
  Values <- Count.Values[[Pathway.Data.Point]]
  Variable.Column <- Services.Data[, Variable.Column.Name]
  
  # correct way to filter rows
  #Values.to.Count <- Services.Data[Variable.Column == Values, ]
  Values.to.Count <- Services.Data[Variable.Column %in% Values, ]
  
  Values.to.Count <- summarize.raw.n(Values.to.Count, Pathway.Data.Point)
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

if (exists("N.Facility.Data"))
{
  N.Facility.Data <- subset.raw(N.Facility.Data, "N.Facilities")
  N.Facility.Data <- sector.type.adder(N.Facility.Data, "N.Facilities")
  N.Facility.Data <- sector.level.mapper(N.Facility.Data, N.Facility.Data.Source)
  N.Facility.Data <- subnational.adder(N.Facility.Data, "N.Facilities", N.Facility.Data.Source)
  N.Facilities <- summarize.raw.n(N.Facility.Data, "N.Facilities")
  colnames(N.Facilities)[colnames(N.Facilities) == "Pathway.Data.Point"] <- "N.Facilities"
}


##################
## Care Seeking ##
##################

if (exists("Care.Seeking.Data"))
{
  Care.Seeking.Data <- subset.raw(Care.Seeking.Data, "Care.Seeking")
  Care.Seeking.Data <- sector.type.adder(Care.Seeking.Data, "Care.Seeking")
  Care.Seeking.Data <- sector.level.mapper(Care.Seeking.Data, Care.Seeking.Data.Source)
  Care.Seeking.Data <- subnational.adder(Care.Seeking.Data, "Care.Seeking", Care.Seeking.Data.Source)
  Care.Seeking <- summarize.raw.prop.cs(Care.Seeking.Data, "Care.Seeking")
  colnames(Care.Seeking)[colnames(Care.Seeking) == "Proportion"] <- "Care.Seeking"
}


#####################
## Dx Availability ##
#####################

if (exists("Dx.Data"))
{
  Dx.Data <- subset.raw(Dx.Data, "Dx.Availability.1")
  Dx.Data <- sector.type.adder(Dx.Data, "Dx.Availability.1")
  Dx.Data <- sector.level.mapper(Dx.Data, Dx.Data.Source)
  Dx.Data <- subnational.adder(Dx.Data, "Dx.Availability.1", Dx.Data.Source)
  N.Dx <- summarize.raw.n.service.availability(Dx.Data, "Dx.Availability.1")
  Dx <- summarize.prop.service.availability(N.Dx, N.Facilities, "Dx.Availability.1")
  colnames(Dx)[colnames(Dx) == "Proportion"] <- "Dx.Availability"
}


#####################
## Tx Availability ##
#####################

if (exists("Tx.Data"))
{
  Tx.Data <- subset.raw(Tx.Data, "Tx.Availability.1")
  Tx.Data <- sector.type.adder(Tx.Data, "Tx.Availability.1")
  Tx.Data <- sector.level.mapper(Tx.Data, Tx.Data.Source)
  Tx.Data <- subnational.adder(Tx.Data, "Tx.Availability.1", Tx.Data.Source)
  N.Tx <- summarize.raw.n.service.availability(Tx.Data, "Tx.Availability.1")
  Tx <- summarize.prop.service.availability(N.Tx, N.Facilities, "Tx.Availability.1")
  colnames(Tx)[colnames(Tx) == "Proportion"] <- "Tx.Availability"
}


#########################
## Put It All Together ##
#########################

if (exists("Care.Seeking"))
{
  Pathway.DF <- merge(N.Facilities, Care.Seeking, all.x = TRUE, all.y = TRUE)
}
if (exists("Dx"))
{
  Pathway.DF <- merge(Pathway.DF, Dx, all.x = TRUE, all.y = TRUE)
}
if (exists("Tx"))
{
  Pathway.DF <- merge(Pathway.DF, Tx, all.x = TRUE, all.y = TRUE)
}
Pathway.DF[is.na(Pathway.DF)] <- 0

if ("Care.Seeking" %in% colnames(Pathway.DF) && "Dx.Availability" %in% colnames(Pathway.DF))
{
  Pathway.DF$Dx.Access <- Pathway.DF$Care.Seeking * Pathway.DF$Dx.Availability
}
if ("Care.Seeking" %in% colnames(Pathway.DF) && "Tx.Availability" %in% colnames(Pathway.DF))
{
  Pathway.DF$Tx.Access <- Pathway.DF$Care.Seeking * Pathway.DF$Tx.Availability
}

write.csv(Pathway.DF, outputFilePath)
