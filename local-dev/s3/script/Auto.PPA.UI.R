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
#setwd('C:/Dropbox/KNCV/2018/Projects/TB/Current Projects/201801_PPA Automation/Country Test Data')  # legacy example path
#setwd('C:/mine/projects/PPA-Desktop/engine/Country Test Data')  # legacy example path
#setwd("./Kenya")
#Country.Inputs <- paste(Country, "UI.xlsx")
# Metadata <- readWorksheetFromFile(Country.Inputs, sheet = "Subnational", header = TRUE)
# rownames(Metadata) <- Metadata$Pathway.Data.Point
# Level.Mapping <- readWorksheetFromFile(Country.Inputs, sheet = "Facility Sector & Level Mapping", header = TRUE)
# Subnational.Mapping <- readWorksheetFromFile(Country.Inputs, sheet = "Region Mapping", header = TRUE)

######################
##   Load Packages  ##
######################

#library(XLConnect) #Ok to not read in commented packages? They are only for reading in data, but JavaScript is doing that
#library(stringr)
library(plyr)
#library(stringdist)
#library(survey)
library(foreign)
library(tools)
library(dplyr)
#library(tidyr)
library("xlsx")


###########################
##   Read in User Input  ##
###########################

# "Universal" Data Read-In Function for Different File Types Applicable to the PPA

read.PPA <- function(data)
{
  switch (toupper(file_ext(data)),
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

# Safe wrapper that gives a clearer error message if the file does not exist
read.PPA.safe <- function(data)
{
  if (!file.exists(data)) {
    stop(paste("Data file not found at path:", data))
  }
  read.PPA(data)
}

# Defining Data Sources by Pathway Data Point

# Dx.Data.Source <- Metadata['Dx.Availability.1', 'Data.Source']
# Dx.Data.Source.Dots <- gsub(" ", ".", Dx.Data.Source)
# Dx.Variable.Column.Name <- Metadata['Dx.Availability.1', 'Variable.Column.Name']
# if (Dx.Data.Source != "" && Dx.Variable.Column.Name != "")
# {
#   Dx.Data <- read.PPA(Dx.Data.Source)
# }
# 
# Tx.Data.Source <- Metadata['Tx.Availability.1', 'Data.Source']
# Tx.Data.Source.Dots <- gsub(" ", ".", Tx.Data.Source)
# Tx.Variable.Column.Name <- Metadata['Tx.Availability.1', 'Variable.Column.Name']
# if (Tx.Data.Source != "" && Tx.Variable.Column.Name != "")
# {
#   Tx.Data <- read.PPA(Tx.Data.Source)
# }


###############################
##   Prep Data for Analysis  ##
###############################

# convernting NAs in the above datasources to ""
#Metadata[is.na(Metadata)] <- "" 
#Level.Mapping[is.na(Level.Mapping)] <- ""
#Subnational.Mapping[is.na(Subnational.Mapping)] <- ""

# Adding a column to Level.Mapping concatenating Sector and Type
#Level.Mapping$Sector.Type <- paste(Level.Mapping$Health.Facility.Sector, Level.Mapping$Health.Facility.Type)
#Level.Mapping$Sector.Level <- paste(Level.Mapping$PPA.Sector, Level.Mapping$PPA.Level)
#trim <- function (x) gsub("^\\s+|\\s+$", "", x) #removes leading and trailing white spaces
#Level.Mapping$Sector.Type <- trim(Level.Mapping$Sector.Type)


#########################################
##   Define Data Analysis Functions    ##
#########################################

# Subsets data by subset columns 
subset.raw <- function(Pathway.Data, Pathway.Data.Point)
{
  # get Metadata variables
  Subset.Columns <- Metadata[[Pathway.Data.Point]][["Subset.Columns"]]
  
  # initialize subset data with original data
  Subset.Pathway.Data <- Pathway.Data
  
  # subset by subset columns
  for (Subset.Column in Subset.Columns)
  {
    Subset.Column.Name <- Subset.Column[["Column.Name"]]
    Subset.Column.Values <- Subset.Column[["Column.Values"]]
    Subset.Pathway.Data <- Subset.Pathway.Data[Subset.Pathway.Data[[Subset.Column.Name]] %in% Subset.Column.Values, ]
    
  }
  
  return(Subset.Pathway.Data)
  
}

#Adds a column to the data sources mapping the subnational unit names from the data source to the master subnational unit names
subnational.adder <- function (Pathway.Data, Pathway.Data.Point)
{
  if (Subnational) {
    
    # get Metadata variables
    Subnational.Mapping <- Metadata[[Pathway.Data.Point]][["Subnational.Mapping"]]
    Subnational.Mapping.Column.Name <- Subnational.Mapping[["Column.Name"]]
    Subnational.Mapping.Table <- Subnational.Mapping[["Mapping.Table"]]
    
    # merge data with mapping
    Pathway.Data <- merge(Pathway.Data, Subnational.Mapping.Table, by.x = c(Subnational.Mapping.Column.Name), by.y = c("Data.Source.Value"))
    
  } else {
    
    # add Subnational column; when there are no rows we still create an
    # empty character column to avoid data.frame replacement errors
    if (nrow(Pathway.Data) == 0) {
      Pathway.Data[["Subnational"]] <- character(0)
    } else {
      Pathway.Data[["Subnational"]] <- "National"
    }
    
  }
  
  return(Pathway.Data)
  
}

#Adds a column to the data sources combining sector and type
sector.type.adder <- function (Pathway.Data, Pathway.Data.Point)
{
  # get Metadata variables
  Level.Mapping <- Metadata[[Pathway.Data.Point]][["Level.Mapping"]]
  Level.Mapping.Column.Names <- Level.Mapping[["Column.Names"]]
  Level.Mapping.Table <- Level.Mapping[["Mapping.Table"]]
  
  # merge data with mapping
  Pathway.Data <- merge(Pathway.Data, Level.Mapping.Table, by = Level.Mapping.Column.Names)
  
  return(Pathway.Data)
  
}

# Summarizes raw data by count (n) for subnational unit and sector/level#
summarize.raw.n <- function (Pathway.Data, Pathway.Data.Point)
{
  # When there are no rows after subsetting/filtering, treat this as zero
  # volume for the given metric instead of a hard error. This allows output
  # generation to continue and visualize gaps in the data.
  if (nrow(Pathway.Data) == 0) {
    Pathway.Data <- unique(Master.Data[, c("Subnational", "PPA.Sector", "PPA.Level")])
    Pathway.Data[[Pathway.Data.Point]] <- 0
    return(Pathway.Data)
  }
  
  # determine or add weight column
  if ("Weight.Column.Name" %in% names(Metadata[[Pathway.Data.Point]])) {
    
    Weight.Column.Name <- make.names(Metadata[[Pathway.Data.Point]][["Weight.Column.Name"]])
    
  } else {
    
    Weight.Column.Name <- "Weight.Column"
    Pathway.Data[[Weight.Column.Name]] <- 1
    
  }
  
  # determine or set weight multiplier
  if ("Weight.Multiplier" %in% names(Metadata[[Pathway.Data.Point]])) {
    
    Weight.Multiplier <- Metadata[[Pathway.Data.Point]][["Weight.Multiplier"]]
    
  } else {
    
    Weight.Multiplier <- 1
    
  }
  
  # add final weight column
  Pathway.Data[["PPA.Weight"]] <- Pathway.Data[[Weight.Column.Name]] * Weight.Multiplier
  
  # group and summarize
  Pathway.Data <- ddply(Pathway.Data, c("Subnational", "PPA.Sector", "PPA.Level"), summarize, "Pathway.Data.Point" = sum(PPA.Weight))
  
  # rename column
  names(Pathway.Data)[names(Pathway.Data) == "Pathway.Data.Point"] <- Pathway.Data.Point
  
  return(Pathway.Data)
  
}

# Aggregates care seekers by subnational unit
summarize.care.seekers <- function(Pathway.Data, Pathway.Data.Point)
{
  if (nrow(Pathway.Data) == 0) {
    # zero care seekers for this metric; propagate as zeros
    Empty <- unique(Master.Data[, c("Subnational")])
    Empty[["N.By.Sub"]] <- 0
    return(Empty)
  }
  
  # summarize by "Subnational", "PPA.Sector", "PPA.Level" 
  Pathway.Data <- summarize.raw.n(Pathway.Data, Pathway.Data.Point)
  
  # rename Pathway.Data.Point column to "Pathway.Data.Point"
  names(Pathway.Data)[names(Pathway.Data) == Pathway.Data.Point] <- "Pathway.Data.Point"
  
  # summarize by "Subnational"
  N.By.Sub <- ddply(Pathway.Data, c("Subnational"), summarize, "N.By.Sub" = sum(Pathway.Data.Point))
  
  return(N.By.Sub)
  
}

# Summarizes raw careseeking data by the proportion of patients that seek care at a given sector/level
summarize.raw.prop.cs <- function (Pathway.Data, Pathway.Data.Point)
{
  if (nrow(Pathway.Data) == 0) {
    # zero care seeking proportion across all sector/levels
    Empty <- unique(Master.Data[, c("Subnational", "PPA.Sector", "PPA.Level")])
    Empty[[Pathway.Data.Point]] <- 0
    return(Empty)
  }
  
  # summarize by "Subnational", "PPA.Sector", "PPA.Level" 
  Pathway.Data <- summarize.raw.n(Pathway.Data, Pathway.Data.Point)
  
  # rename Pathway.Data.Point column to "Pathway.Data.Point"
  names(Pathway.Data)[names(Pathway.Data) == Pathway.Data.Point] <- "Pathway.Data.Point"
  
  # summarize by "Subnational"
  N.By.Sub <- ddply(Pathway.Data, c("Subnational"), summarize, "N.By.Sub" = sum(Pathway.Data.Point))
  
  # add N.By.Sub data to Pathway.Data
  Pathway.Data <- merge(Pathway.Data, N.By.Sub, by = "Subnational", all.x = TRUE)
  
  # calculate proportion
  Pathway.Data[["Proportion"]] <- Pathway.Data[["Pathway.Data.Point"]] / Pathway.Data[["N.By.Sub"]]
  
  # clear table and rename columns and join Care.Seekers.N column
  Pathway.Data[["Pathway.Data.Point"]] <- NULL
  Pathway.Data[["N.By.Sub"]] <- NULL
  names(Pathway.Data)[names(Pathway.Data) == "Proportion"] <- Pathway.Data.Point
  
  return(Pathway.Data)
  
}

# Summarizes raw service availability data. For each sector/level, counts the number of facilities with a given service availale (numerator)
# Then calculates this a as a proportion of all facilities at that sector/level (denominator). 
summarize.raw.n.service.availability <- function (Services.Data, Pathway.Data.Point) {
  
  if (nrow(Services.Data) == 0) {
    # No facility rows at all for this availability metric. Treat this as
    # zero availability across all sectors/levels instead of a hard error
    # so that output generation and visualisation can continue.
    Services.Data.Result <- unique(Master.Data[, c("Subnational", "PPA.Sector", "PPA.Level", "N.Facilities")])
    Services.Data.Result[["Numerator"]] <- 0
    Services.Data.Result[["Ratio"]] <- 0
    Services.Data.Result[["N.Facilities"]] <- NULL
    Services.Data.Result[["Numerator"]] <- NULL
    names(Services.Data.Result)[names(Services.Data.Result) == "Ratio"] <- Pathway.Data.Point
    return(Services.Data.Result)
  }
  
  # get Metadata variables
  Variable.Column.Name <- make.names(Metadata[[Pathway.Data.Point]][["Count.Values"]][["Column.Name"]])
  Values <- Metadata[[Pathway.Data.Point]][["Count.Values"]][["Column.Values"]]
  Variable.Column <- Services.Data[, Variable.Column.Name]
  
  #  # denominator
  #  Services.Data.Denominator <- summarize.raw.n(Services.Data, Pathway.Data.Point)
  #  colnames(Services.Data.Denominator)[colnames(Services.Data.Denominator) == Pathway.Data.Point] <- "Denominator"
  
  # numerator
  Values.to.Count <- Services.Data[Variable.Column %in% Values, ]
  
  # When no facilities match the availability filter, treat this as zero
  # availability rather than a hard error. This is common in early or
  # partial datasets and should not prevent output generation.
  if (nrow(Values.to.Count) == 0) {
    
    Values.to.Count <- unique(Master.Data[, c("Subnational", "PPA.Sector", "PPA.Level")])
    Values.to.Count[["Numerator"]] <- 0
    
  } else {
    
    Values.to.Count <- summarize.raw.n(Values.to.Count, Pathway.Data.Point)
    colnames(Values.to.Count)[colnames(Values.to.Count) == Pathway.Data.Point] <- "Numerator"
    
  }
  
  # merge
  Services.Data.Result <- merge(Master.Data[,c("Subnational", "PPA.Sector", "PPA.Level", "N.Facilities")], Values.to.Count, by = c("Subnational", "PPA.Sector", "PPA.Level"), all.x = TRUE)
  Services.Data.Result[["Numerator"]][is.na(Services.Data.Result[["Numerator"]])] <- 0
  
  # calcualte ratio
  Services.Data.Result[["Ratio"]] <- Services.Data.Result[["Numerator"]] / Services.Data.Result[["N.Facilities"]]
  
  # clear table and rename columns
  Services.Data.Result[["N.Facilities"]] <- NULL
  Services.Data.Result[["Numerator"]] <- NULL
  names(Services.Data.Result)[names(Services.Data.Result) == "Ratio"] <- Pathway.Data.Point
  
  return(Services.Data.Result)
  
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

master.join <- function(Pathway.Data, Pathway.Data.Point)
{
  Master.Data <<- merge(Master.Data, Pathway.Data, by = c("Subnational", "PPA.Sector", "PPA.Level"), all.x = TRUE)
  
  return(Master.Data)
  
}

rename.metric.column <- function(oldName, newName)
{
  colnames(Master.Data)[colnames(Master.Data) == oldName] <<- newName
  
}

generateAccessColumnName <- function(name)
{
  paste(name, ".Access", sep = "")
  
}

insert.access.column <- function(metric)
{
  careSeekingColumnName = "Care.Seeking"
  availabilityColumnName <- metric
  accessColumnName <- generateAccessColumnName(metric)
  
  Master.Data[[accessColumnName]] <<- (Master.Data[[careSeekingColumnName]] * Master.Data[[availabilityColumnName]])
  
}

### verify mandatory variables

if (!("Care.Seeking" %in% names(Metadata))) {
  
  stop("Care.Seeking variable is not set")
  
}

if (!("Dx.Availability.1" %in% names(Metadata)) && !("Tx.Availability.1" %in% names(Metadata))) {
  
  stop("Neigher Dx.Availability.1 nor Tx.Availability.1 variables are set")
  
}

### replace all potential column names with syntaxically correct values

for(metric in names(Metadata))
{
  if ("Pathway.Data.Point" %in% names(Metadata[[metric]]))
  {
    Metadata[[metric]][["Pathway.Data.Point"]] <- make.names(Metadata[[metric]][["Pathway.Data.Point"]])
    
  }
  
  if ("Pathway.Data.Point.Availability" %in% names(Metadata[[metric]]))
  {
    Metadata[[metric]][["Pathway.Data.Point.Availability"]] <- make.names(Metadata[[metric]][["Pathway.Data.Point.Availability"]])
    
  }
  
  if ("Pathway.Data.Point.Access" %in% names(Metadata[[metric]]))
  {
    Metadata[[metric]][["Pathway.Data.Point.Access"]] <- make.names(Metadata[[metric]][["Pathway.Data.Point.Access"]])
    
  }
  
}


##################
## N.Facilities ##
##################

if ("N.Facilities" %in% names(Metadata)) {
  
  N.Facilities.Data.Source <- Metadata[["N.Facilities"]][["Data.Source"]]
  N.Facilities.Variable.Column.Name <- Metadata[["N.Facilities"]][["Count.Values"]][["Column.Name"]]
  
  if (N.Facilities.Data.Source != "") {
    
    N.Facilities.Data <- read.PPA.safe(N.Facilities.Data.Source)
    N.Facilities.Data <- subset.raw(N.Facilities.Data, "N.Facilities")
    N.Facilities.Data <- subnational.adder(N.Facilities.Data, "N.Facilities")
    N.Facilities.Data <- sector.type.adder(N.Facilities.Data, "N.Facilities")
    N.Facilities.Data <- summarize.raw.n(N.Facilities.Data, "N.Facilities")
    Master.Data <- master.join(N.Facilities.Data, "N.Facilities")
    Master.Data[["N.Facilities"]][is.na(Master.Data[["N.Facilities"]])] <- 0
    
  }
  
}


##################
## Care Seeking ##
##################

if ("Care.Seeking" %in% names(Metadata)) {
  
  Care.Seeking.Data.Source <- Metadata[["Care.Seeking"]][["Data.Source"]]
  Care.Seeking.Variable.Column.Name <- Metadata[["Care.Seeking"]][["Count.Values"]][["Column.Name"]]
  
  if (Care.Seeking.Data.Source != "") {
    
    Care.Seeking.Data <- read.PPA.safe(Care.Seeking.Data.Source)
    Care.Seeking.Data <- subset.raw(Care.Seeking.Data, "Care.Seeking")
    Care.Seeking.Data <- subnational.adder(Care.Seeking.Data, "Care.Seeking")
    Care.Seeking.Data <- sector.type.adder(Care.Seeking.Data, "Care.Seeking")
    
    # calculate total number of care seekers weighted aggregated by subnational unit
    N.By.Sub <- summarize.care.seekers(Care.Seeking.Data, "Care.Seeking")
    N.By.Sub[,"N.By.Sub"] <- round(N.By.Sub[,"N.By.Sub"])
    
    # calculate care seeking data
    Care.Seeking.Data <- summarize.raw.prop.cs(Care.Seeking.Data, "Care.Seeking")
    Master.Data <- master.join(Care.Seeking.Data, "Care.Seeking")
    Master.Data[["Care.Seeking"]][is.na(Master.Data[["Care.Seeking"]])] <- 0
    
  }
  
}


####################
## Availabilities ##
####################

for (Availability in c("Dx.Availability.1", "Dx.Availability.2", "Dx.Availability.3", "Dx.Availability.4", "Tx.Availability.1", "Tx.Availability.2", "Tx.Availability.3", "Tx.Availability.4"))
{
  if (Availability %in% names(Metadata)) {
    
    Availability.Data.Source <- Metadata[[Availability]][["Data.Source"]]
    Availability.Variable.Column.Name <- Metadata[[Availability]][["Count.Values"]][["Column.Name"]]
    
    if (Availability.Data.Source != "" && Availability.Variable.Column.Name != "") {
      
      Availability.Data <- read.PPA.safe(Availability.Data.Source)
      Availability.Data <- subset.raw(Availability.Data, Availability)
      Availability.Data <- subnational.adder(Availability.Data, Availability)
      Availability.Data <- sector.type.adder(Availability.Data, Availability)
      Availability.Data <- summarize.raw.n.service.availability(Availability.Data, Availability)
      
      # test availability is not greater than 1
      
      Availability.Data.Error <- Availability.Data[!is.na(Availability.Data[,Availability]) & Availability.Data[,Availability] > 1,]
      if (nrow(Availability.Data.Error) >= 1) {
        stop(paste("The number of facilities with", Availability, "service in", paste(Availability.Data.Error[,"PPA.Sector"], Availability.Data.Error[,"PPA.Level"], sep="/"), "is greater than the total number of health facilities at the same health sector/level(s). Service availability cannot be greater than 100%."))
      }
      
      Master.Data <- master.join(Availability.Data, Availability)
      Master.Data[[Availability]][is.na(Master.Data[[Availability]])] <- 0
      
      # insert access column
      insert.access.column(Availability)
      
    }
    
  }
  
}

# rename columns
rename.metric.column("N.Facilities", Metadata[["N.Facilities"]][["Pathway.Data.Point"]])
rename.metric.column("Care.Seeking", Metadata[["Care.Seeking"]][["Pathway.Data.Point"]])
for (Availability in c("Dx.Availability.1", "Dx.Availability.2", "Dx.Availability.3", "Dx.Availability.4", "Tx.Availability.1", "Tx.Availability.2", "Tx.Availability.3", "Tx.Availability.4"))
{
  if (Availability %in% names(Metadata))
  {
    rename.metric.column(Availability, Metadata[[Availability]][["Pathway.Data.Point.Availability"]])
    rename.metric.column(generateAccessColumnName(Availability), Metadata[[Availability]][["Pathway.Data.Point.Access"]])
    
  }
  
}

#########################
## Put It All Together ##
#########################

# rename column to Subnational.Unit
names(Master.Data)[names(Master.Data) == 'Subnational'] <- 'Subnational.Unit'

# replace NA values with 0
Master.Data[is.na(Master.Data)] <- 0

# write output
write.xlsx2(Master.Data, outputFilePath, sheetName = "output", col.names = TRUE, row.names = FALSE, append = FALSE)

# write input data
InputData <- data.frame(unlist(Metadata))
write.xlsx2(InputData, outputFilePath, sheetName = "input", col.names = FALSE, row.names = TRUE, append = TRUE)

###
### PPA Desktop automated ggplot2 visualizations
###

## Libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(cowplot)
# extrafont is not used in the container; rely on default fonts
# library(extrafont)
# font_import() run once!
# loadfonts()

## Data
#cameroon <- read_csv("data/Cameroon National Master PPA for Eric v2.csv")
#cameroon_regional <- read_csv("data/Cameroon Regional Master PPA for Eric.csv")
#kenya <- read_csv("data/Kenya Master PPA for Eric.csv")
#phillipines <- read_csv("data/Philippines Master PPA for Eric.csv")

## Configuration
mydata <- PPA.Name
#data <- get(mydata)
data <- Master.Data
aggregation <- unique(unlist(data[,1])) # "National" etc...

## Pre-processing
names(data)[2:5] <- c("Sector_Sector", "Level_Level", "N.Facilities_Number.of.Facilities", "Care.Seeking_Care.Seeking")

## Clean up the data
data_clean <- data %>%
  mutate(Level_Level = tools::toTitleCase(as.character(Level_Level)),
         Sector_Sector = tools::toTitleCase(as.character(Sector_Sector))) %>%
  mutate(Level_Level = gsub("Level ", "", Level_Level)) %>%
  mutate_at(vars(Level_Level, Sector_Sector), funs(factor)) %>%
  mutate(Sector_Level = interaction(Sector_Sector, Level_Level, sep = " Level ")) %>%
  arrange(desc(Sector_Sector), Level_Level) %>%
  mutate(Sector_Level = factor(Sector_Level, levels = unique(Sector_Level))) %>%
  mutate_at(vars(5:(ncol(.) - 1)), function(.) ifelse(grepl("%", .), as.numeric(gsub("%", "", .)) / 100, .))
data_clean[is.na(data_clean)] <- 0

## Map colors to levels and sectors
col_mapping <- data.frame(
  `Level` =  c(0:4, "Other"),
  `Informal Private` = c("#fabdb3", "#e05859", "#c4272f", "#87070d", "#5b0005", "#400004"),
  `Private` = c("#bbddef", "#a2c5e1", "#6686b0", "#366694", "#13375d", "#0D2640"),
  `Public` = c("#eed8ad", "#e5b784", "#d4934c", "#b86f3e", "#884424", "#402011"),
  `Other` = c("#f7f7f7", "#d9d9d9", "#bdbdbd", "#969696", "#636363", "#252525")
  , check.names = FALSE) %>%
  gather(key = Sector, value = Color, 2:ncol(.)) %>%
  mutate_all(funs(as.character))

## Store an "average" color aggregated across levels
col_mapping_avg <- col_mapping %>%
  filter(Level == 2)

# plot variables initialization
p1 <- p2 <- p3 <- p4 <- p5 <- p6 <- NULL

## Loop over all unique aggregation levels
## Loop over all unique aggregation levels
for (agg in aggregation) {
  
  cat("Processing Aggregation Level", agg, "for", mydata, "\n")
  
  ## Aggregate the cleaned data
  data_agg <- data_clean %>%
    filter_at(vars(one_of(names(data)[1])), any_vars(. == agg)) %>%
    select(-1) %>% # Remove aggregation column now
    group_by(Sector_Level, Sector_Sector, Level_Level) %>%
    summarise_all(funs(sum)) %>%
    ungroup() %>%
    mutate(Sector_Level_Numeric = as.numeric(Sector_Level) - 0.5) %>%
    group_by(Sector_Sector) %>%
    mutate(Col_Level = as.character(ifelse(Level_Level == "Other", max(as.numeric(as.character(Level_Level)), na.rm = TRUE) + 1, as.numeric(as.character(Level_Level))))) %>%
    ungroup() %>%
    left_join(col_mapping , by = c("Sector_Sector" = "Sector", "Col_Level" = "Level")) %>%
    
    # old version
    #    mutate(Nfaclabel = ifelse(Sector_Sector == "Informal Private", "Unknown", N.Facilities_Number.of.Facilities),
    #           Sector_Numeric = 1:nrow(.)) %>%
    # [PA-327] changes
    mutate(Nfaclabel = ifelse(Sector_Sector == "Informal Private" | Level_Level == "0", "Unknown", N.Facilities_Number.of.Facilities),
           Sector_Numeric = 1:nrow(.)) %>%
    
    group_by(Sector_Sector) %>%
    mutate(Sector_Numeric = Sector_Numeric[1]) %>%
    ungroup()
  
  #  final_dir <- file.path("final_charts", mydata)
  #  if (!file.exists(final_dir)) dir.create(final_dir, recursive = TRUE)
  
  ##
  ## Number of Health Facilities by Sector/Level
  ##
  
  ## Produce Plot
  p1 <- ggplot(data = data_agg, aes(x = Sector_Level_Numeric, y = N.Facilities_Number.of.Facilities)) +
    geom_text(aes(label = Nfaclabel), y = 1, family = "DIN Pro", size = 5, hjust = "inward") +
    geom_bar(aes(y = 0), stat = "identity", width = 0.8) +
    geom_vline(xintercept = unique(data_agg$Sector_Numeric)[-which.min(unique(data_agg$Sector_Numeric))] - 1, colour = "grey70", size = 0.25) +
    #geom_rect(inherit.aes = FALSE, data = filter(data_agg, RectColor), aes(xmin = Sector_Level_Numeric - 0.5, xmax = Sector_Level_Numeric + 0.5,
    #                                                  ymin = -Inf, ymax = Inf), alpha = 0.2) +
    coord_flip() +
    scale_y_continuous(limits = c(0, 1)) +
    scale_x_continuous(labels = as.character(data_agg$Sector_Level),
                       breaks = data_agg$Sector_Level_Numeric,
                       minor_breaks = data_agg$Sector_Level_Numeric - 0.5,
                       expand = c(0, 0.1)) +
    theme_minimal(10) +
    theme(
      plot.title = element_text(hjust = 1, size = 12, face = "bold"),
      panel.border = element_rect(colour = "grey70", fill = NA, size = 0.5),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_line(size = 0.25, colour = "grey70", linetype = "dashed"),
      axis.line = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_text(size = 12),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      plot.margin = unit(c(0.5, 0, 2.2, 0.5), "cm"),
      text = element_text(family = "DIN Pro")
    ) +
    labs(
      title = "Number of Health Facilities\n"
    ) +
    ylab("")
  
  ##
  ## Care Seeking
  ##
  
  ## Produce Plot
  legend_rows <- ceiling(length(unique(data_agg$Sector_Level)) / 3)
  
  p2 <- ggplot(data = data_agg, aes(x = Sector_Level_Numeric, y = Care.Seeking_Care.Seeking, fill = Sector_Level)) +
    geom_bar(stat = "identity", width = 0.8) +
    geom_text(aes(label = scales::percent(Care.Seeking_Care.Seeking, accuracy = 1)), size = 5, hjust = -0.1, family = "DIN Pro") +
    coord_flip() +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    scale_x_continuous(breaks = unique(data_agg$Sector_Numeric)[-which.min(unique(data_agg$Sector_Numeric))] - 1, 
                       minor_breaks = seq_along(data_agg$Sector_Level_Numeric[-1]),
                       expand = c(0, 0.1)) +
    scale_fill_manual("Sector/Level", values = data_agg$Color) +
    theme_minimal(10) +
    theme(
      plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
      panel.border = element_rect(colour = "grey70", fill = NA, size = 0.5),
      axis.line = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank(),
      panel.grid.major.y = element_line(size = 0.25, colour = "grey70"),
      panel.grid.minor.y = element_line(size = 0.25, colour = "grey70", linetype = "dashed"),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      legend.title = element_text(face = "bold"),
      legend.text = element_text(size = 10),
      legend.justification = "center",
      legend.position = c(0, -.08),
      legend.key.size = unit(0.4, "cm"),
      plot.margin = unit(c(0.5, 0.5, 2.19, 0.5), "cm"),
      text = element_text(family = "DIN Pro")
    ) +
    guides(
      fill = guide_legend(nrow = legend_rows, title.position = "left")
    ) +
    labs(
      # old code
      #title = "Initial Care Seeking Patterns\n"
      # [PA-330] changes
      title = paste("Initial Care Seeking Patterns\n", "N (Weighted) =", N.By.Sub[N.By.Sub[,"Subnational"] == agg, "N.By.Sub"])
    ) +
    ylab("")
  
  ##
  ## Diagnostic Availability
  ##
  if (length(grep("^Diagnostic\\.[0-9]\\.Availability", names(data_agg))) >= 1)
  {
    diagnostic_data <- data_agg %>%
      select(Sector_Level:Level_Level, matches("^Diagnostic\\.[0-9]\\.Availability")) %>%
      gather(key = Diagnostic, value = Availability, 4:ncol(.)) %>%
      mutate(Diagnostic = gsub("^Diagnostic\\.[0-9]\\.Availability_(.*)$", "\\1", Diagnostic)) %>%
      arrange(Sector_Level) %>%
      mutate(Diagnostic_Value = seq(0.5 / length(unique(Diagnostic)), nrow(.) / length(unique(Diagnostic)), by = 1 / length(unique(Diagnostic))),
             LabelPos = (Availability >= .7))
    
    ## Select font
    fsize <- pmin(5, round(100 / nrow(diagnostic_data)))
    
    ## Produce Plot
    p3 <- ggplot(data = diagnostic_data, aes(x = Diagnostic_Value, y = Availability, colour = Sector_Level, fill = Sector_Level)) +
      geom_point(aes(shape = Diagnostic), size = fsize) +
      geom_text(data = filter(diagnostic_data, !LabelPos), aes(label = scales::percent(Availability, accuracy = 1)), size = fsize, hjust = -0.4, colour = "black", family = "DIN Pro") +
      geom_text(data = filter(diagnostic_data, LabelPos), aes(label = scales::percent(Availability, accuracy = 1)), size = fsize, hjust = 1.25, colour = "black", family = "DIN Pro") +    
      scale_shape_manual(values = c(21, 22, 23, 4)) +
      coord_flip() +
      scale_y_continuous(limits = c(0, 1.1)) +
      scale_x_continuous(limits = c(0.1, max(diagnostic_data$Diagnostic_Value) + diff(diagnostic_data$Diagnostic_Value)[1] / 2 - 0.1),
                         breaks = c(0, data_agg$Sector_Numeric - 1, nrow(data_agg)), 
                         minor_breaks = c(0, seq_along(data_agg$Sector_Level_Numeric)),
                         expand = c(0, 0.1)) +
      scale_colour_manual(values = data_agg$Color, guide = FALSE) +
      scale_fill_manual(values = data_agg$Color, guide = FALSE) +
      theme_minimal(10) +
      theme(
        plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
        plot.subtitle = element_text(hjust = 0),
        panel.border = element_rect(colour = "grey70", fill = NA, size = 0.5),
        panel.grid.major.y = element_line(size = 0.25, colour = "grey70"),
        panel.grid.minor.y = element_line(size = 0.25, colour = "grey70", linetype = "dashed"),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        legend.title = element_text(face = "bold"),
        legend.text = element_text(size = 10),
        legend.justification = "center",
        legend.position = c(0.5, -0.08),
        plot.margin = unit(c(0.5, 0.5, 2.19, 0.5), "cm"),
        text = element_text(family = "DIN Pro")
      ) +
      labs(
        title = "Coverage of Diagnostic Services\namong Health Facilities"
      ) +
      ylab("") +
      guides(
        shape = guide_legend(nrow = min(2, length(unique(diagnostic_data$Diagnostic))), title.position = "left")
      )
    
  }
  
  ##
  ## Diagnostic Access
  ##
  if (length(grep("^Diagnostic\\.[0-9]\\.Access", names(data_agg))) >= 1)
  {
    access_data <- data_agg %>%
      select(Sector_Level:Level_Level, matches("^Diagnostic\\.[0-9]\\.Access")) %>%
      group_by(Sector_Sector) %>%
      summarise_at(vars(matches("^Diagnostic\\.[0-9]\\.Access")), funs(sum)) %>%
      gather(key = Diagnostic, value = Access, 2:ncol(.)) %>%
      group_by(Sector_Sector) %>%
      summarise(MaxAccess = max(Access)) %>%
      mutate(MaxAccess = replace_na(MaxAccess, 0))
    
    p4 <- ggplot(data = access_data, aes(x = 1, y = MaxAccess, fill = Sector_Sector)) +
      geom_bar(stat = "identity") +
      geom_text(inherit.aes = FALSE, data = access_data %>% summarise(MaxAccess = sum(MaxAccess)), 
                aes(x = 1, y = MaxAccess, label = scales::percent(MaxAccess, accuracy = 1)), size = 5, vjust = -0.4, fontface = "bold", family = "DIN Pro") +
      scale_y_continuous(labels = function(.) scales::percent(., accuracy = 1), limits = c(0, 1), expand = c(0, 0)) +
      scale_fill_manual("Sector", values = col_mapping_avg$Color[match(access_data$Sector_Sector, col_mapping_avg$Sector)]) +
      theme_minimal(10) +
      theme(
        plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
        plot.subtitle = element_text(hjust = 0),
        panel.border = element_rect(colour = "grey70", fill = NA, size = 0.5),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        legend.title = element_text(face = "bold"),
        legend.key.size = unit(0.4, "cm"),
        legend.text = element_text(size = 10),
        legend.position = c(0.5, -0.08),
        legend.justification = "center",
        panel.grid = element_blank(),
        plot.margin = unit(c(0.5, 0.5, 2.19, 0.5), "cm"),
        text = element_text(family = "DIN Pro")
      ) +
      labs(
        title = "Access to Diagnostic Services\nat First Visit"
      ) +
      guides(
        fill = guide_legend(nrow = 3, title.position = "left")
      )
    
    if (length(access_data$MaxAccess[access_data$MaxAccess > 0]) > 1 && all(access_data$MaxAccess[access_data$MaxAccess > 0] >= .1)) p4 <- p4 + 
      geom_text(data = access_data %>% filter(MaxAccess > 0), 
                aes(label = scales::percent(MaxAccess, accuracy = 1)), position = position_stack(vjust = .5), size = 5, colour = "white", family = "DIN Pro")
    
  }
  
  ##
  ## Treatment Availability
  ##
  if (length(grep("^Treatment\\.[0-9]\\.Availability", names(data_agg))) >= 1)
  {
    trt_data <- data_agg %>%
      select(Sector_Level:Level_Level, matches("^Treatment\\.[0-9]\\.Availability")) %>%
      gather(key = Treatment, value = Availability, 4:ncol(.)) %>%
      mutate(Treatment = gsub("^Treatment\\.[0-9]\\.Availability_(.*)$", "\\1", Treatment)) %>%
      arrange(Sector_Level) %>%
      mutate(Treatment_Value = seq(0.5 / length(unique(Treatment)), nrow(.) / length(unique(Treatment)), by = 1 / length(unique(Treatment))),
             LabelPos = (Availability >= .7))
    
    ## Select font
    fsize <- pmin(5, round(100 / nrow(trt_data)))
    
    ## Produce Plot
    p5 <- ggplot(data = trt_data, aes(x = Treatment_Value, y = Availability, colour = Sector_Level, fill = Sector_Level)) +
      geom_point(aes(shape = Treatment), size = fsize) +
      geom_text(data = filter(trt_data, !LabelPos), aes(label = scales::percent(Availability, accuracy = 1)), size = fsize, hjust = -0.4, colour = "black", family = "DIN Pro") +
      geom_text(data = filter(trt_data, LabelPos), aes(label = scales::percent(Availability, accuracy = 1)), size = fsize, hjust = 1.25, colour = "black", family = "DIN Pro") +    
      scale_shape_manual(values = c(21, 22, 23, 4)) +
      coord_flip() +
      scale_y_continuous(limits = c(0, 1.1)) +
      scale_x_continuous(limits = c(0.1, max(trt_data$Treatment_Value) + diff(trt_data$Treatment_Value)[1] / 2 - 0.1),
                         breaks = c(0, data_agg$Sector_Numeric - 1, nrow(data_agg)), 
                         minor_breaks = c(0, seq_along(data_agg$Sector_Level_Numeric)),
                         expand = c(0, 0.1)) +
      scale_colour_manual(values = data_agg$Color, guide = FALSE) +
      scale_fill_manual(values = data_agg$Color, guide = FALSE) +
      theme_minimal(10) +
      theme(
        plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
        plot.subtitle = element_text(hjust = 0),
        panel.border = element_rect(colour = "grey70", fill = NA, size = 0.5),
        panel.grid.major.y = element_line(size = 0.25, colour = "grey70"),
        panel.grid.minor.y = element_line(size = 0.25, colour = "grey70", linetype = "dashed"),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        legend.title = element_text(face = "bold"),
        legend.text = element_text(size = 10),
        legend.justification = "center",
        legend.position = c(0.5, -0.08),
        plot.margin = unit(c(0.5, 0.5, 2.19, 0.5), "cm"),
        text = element_text(family = "DIN Pro")
      ) +
      labs(
        title = "Coverage of Treatment Services\namong Health Facilities"
      ) +
      ylab("") +
      guides(
        shape = guide_legend(nrow = min(2, length(unique(trt_data$Treatment))), title.position = "left")
      )
    
  }
  
  ##
  ## Treatment Access
  ##
  if (length(grep("^Treatment\\.[0-9]\\.Access", names(data_agg))) >= 1)
  {
    trt_access_data <- data_agg %>%
      select(Sector_Level:Level_Level, matches("^Treatment\\.[0-9]\\.Access")) %>%
      group_by(Sector_Sector) %>%
      summarise_at(vars(matches("^Treatment\\.[0-9]\\.Access")), funs(sum)) %>%
      gather(key = Treatment, value = Access, 2:ncol(.)) %>%
      group_by(Sector_Sector) %>%
      summarise(MaxAccess = max(Access)) %>%
      mutate(MaxAccess = replace_na(MaxAccess, 0))
    
    data_sub <- filter(trt_access_data, MaxAccess > 0.05)
    
    p6 <- ggplot(data = trt_access_data, aes(x = 1, y = MaxAccess, fill = Sector_Sector)) +
      geom_bar(stat = "identity") +
      geom_text(inherit.aes = FALSE, data = trt_access_data %>% summarise(MaxAccess = sum(MaxAccess)), 
                aes(x = 1, y = MaxAccess, label = scales::percent(MaxAccess, accuracy = 1)), size = 5, vjust = -0.4, fontface = "bold", family = "DIN Pro") +
      scale_y_continuous(labels = function(.) scales::percent(., accuracy = 1), limits = c(0, 1), expand = c(0, 0)) +
      scale_fill_manual(values = col_mapping_avg$Color[match(access_data$Sector_Sector, col_mapping_avg$Sector)], guide = FALSE) +
      theme_minimal(10) +
      theme(
        plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
        plot.subtitle = element_text(hjust = 0),
        plot.caption = element_text(size = 10, vjust = -19),
        panel.border = element_rect(colour = "grey70", fill = NA, size = 0.5),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid = element_blank(),
        plot.margin = unit(c(0.5, 1.5, 0.5, 0.5), "cm"),
        text = element_text(family = "DIN Pro")
      ) +
      labs(
        title = "Access to Treatment Services\nat First Visit",
        caption = paste0(tools::toTitleCase(gsub("_", " ", mydata)), ": ", agg)
      )
    
    if (length(trt_access_data$MaxAccess[trt_access_data$MaxAccess > 0]) > 1 && all(trt_access_data$MaxAccess[trt_access_data$MaxAccess > 0] >= .1)) p6 <- p6 + 
      geom_text(data = trt_access_data %>% filter(MaxAccess > 0), 
                aes(label = scales::percent(MaxAccess, accuracy = 1)), position = position_stack(vjust = .5), size = 5, colour = "white", family = "DIN Pro")
    
  }
  
  ##
  ## Final Plot Grid
  ##
  final_plots <- plot_grid(p1, p2, p3, p4, p5, p6, align = "h", ncol = 6, axis = "l",
                           rel_widths = c(.175, .2, .2, .1, .2, .125))
  
  ## Write it out (only if a file path is defined for this aggregation level)
  if (!is.null(chartFilePaths[[agg]]) && nzchar(chartFilePaths[[agg]])) {
    ggsave(final_plots, filename = chartFilePaths[[agg]], dpi = 300, height = 8, width = 18)
  }
}
