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

#library(XLConnect) #Ok to not read in commented packages? They are only for reading in data, but JavaScript is doing that
#library(stringr)
library(plyr)
#library(stringdist)
#library(survey)
library(foreign)
library(tools)
library(dplyr)
#library(tidyr)
library(openxlsx)


###########################
##   Read in User Input  ##
###########################

# "Univeral" Data Read-In Function for Different File Types Applicable to the PPA

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
          "XLS"=,
          "XLSX"=
          {
            as.data.frame(readxl::read_excel(data))
          },
          {
            stop("Unsupported data source file extension: ",  toupper(file_ext(data)))
          }
  )
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
    
    # add Subnational column with all empty string values
    Pathway.Data[["Subnational"]] <- "National"
    
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
  if (nrow(Pathway.Data) == 0) {
    
    stop(paste(Pathway.Data.Point, ": data subsetting and filtering resulted in zero row data set."))
    
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
    
    stop(paste(Pathway.Data.Point, ": data subsetting and filtering resulted in zero row data set."))
    
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
    
    stop(paste(Pathway.Data.Point, ": data subsetting and filtering resulted in zero row data set."))
    
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
    
    stop(paste(Pathway.Data.Point, ": data subsetting and filtering resulted in zero row data set."))
    
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
  Values.to.Count <- summarize.raw.n(Values.to.Count, Pathway.Data.Point)
  colnames(Values.to.Count)[colnames(Values.to.Count) == Pathway.Data.Point] <- "Numerator"
  
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
    
    N.Facilities.Data <- read.PPA(N.Facilities.Data.Source)
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
    
    Care.Seeking.Data <- read.PPA(Care.Seeking.Data.Source)
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
      
      Availability.Data <- read.PPA(Availability.Data.Source)
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

# write output with number formatting so values below 1 don't show as "0"
wb <- openxlsx::createWorkbook()
openxlsx::addWorksheet(wb, "output")
openxlsx::writeData(wb, "output", Master.Data, colNames = TRUE, rowNames = FALSE)

numCols <- which(sapply(Master.Data, is.numeric))
if (length(numCols) > 0) {
  numStyle <- openxlsx::createStyle(numFmt = "0.0")
  for (col in numCols) {
    openxlsx::addStyle(wb, "output", numStyle,
                       rows = 2:(nrow(Master.Data) + 1), cols = col,
                       gridExpand = TRUE)
  }
}

# write input data
InputData <- data.frame(unlist(Metadata))
openxlsx::addWorksheet(wb, "input")
openxlsx::writeData(wb, "input", InputData, colNames = FALSE, rowNames = TRUE)

openxlsx::saveWorkbook(wb, outputFilePath, overwrite = TRUE)

###
### Linksbridge Automated ggplot2 Visualizations
###

## Libraries
library(tidyverse)
library(cowplot)
library(extrafont)

## Import fonts
# font_import() run once!
loadfonts()

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
ensure_chart_color <- function(colors) {
  vapply(colors, function(color) {
    if (is.na(color) || !nzchar(color)) {
      return("#888888")
    }
    rgb <- col2rgb(color, alpha = FALSE)[, 1]
    luminance <- (0.299 * rgb[1] + 0.587 * rgb[2] + 0.114 * rgb[3]) / 255
    if (luminance > 0.75) {
      rgb <- pmax(round(rgb * 0.50), 0)
      return(rgb(rgb[1], rgb[2], rgb[3], maxColorValue = 255))
    }
    color
  }, character(1), USE.NAMES = FALSE)
}

prettify_label <- function(labels) {
  labels <- gsub("\\.", " ", labels)
  labels <- gsub("_", " ", labels)
  labels <- gsub("\\s+", " ", labels)
  trimws(labels)
}

col_mapping <- data.frame(
  `Level` =  c(0:4, "Other"),
  `Informal Private` = c("#fabdb3", "#e05859", "#c4272f", "#87070d", "#5b0005", "#400004"),
  `Private` = c("#9ec5e8", "#a2c5e1", "#6686b0", "#366694", "#13375d", "#0D2640"),
  `Public` = c("#e5c985", "#e5b784", "#d4934c", "#b86f3e", "#884424", "#402011"),
  `Drug Vendor/Pharmacy` = c("#c49fd4", "#a070b8", "#804898", "#603070", "#401850", "#280838"),
  `Private Not For Profit` = c("#8fd4a8", "#5aad70", "#3d8f55", "#2a7040", "#1a5028", "#103818"),
  `Other` = c("#bdbdbd", "#d9d9d9", "#bdbdbd", "#969696", "#636363", "#252525")
  , check.names = FALSE) %>%
  gather(key = Sector, value = Color, 2:ncol(.)) %>%
  mutate_all(funs(as.character)) %>%
  mutate(Color = ensure_chart_color(Color))

## Store an "average" color aggregated across levels
col_mapping_avg <- col_mapping %>%
  filter(Level == 2)

lookup_sector_color <- function(sectors) {
  ensure_chart_color(col_mapping_avg$Color[match(sectors, col_mapping_avg$Sector)])
}

# plot variables initialization
p1 <- p2 <- p3 <- p4 <- p5 <- p6 <- NULL

## Shared chart layout (cowplot clips legends/captions unless margins are generous)
chart_margin_top <- 0.8
chart_margin_right <- 0.8
chart_margin_bottom <- 5.5
chart_margin_bottom_main <- 0.3
chart_margin_left_labels <- 1.2
chart_margin_left <- 0.8
chart_legend_theme <- theme(
  legend.position = "bottom",
  legend.justification = "center",
  legend.box = "horizontal",
  legend.title = element_text(face = "bold", size = 10, hjust = 0, margin = margin(b = 3)),
  legend.text = element_text(size = 9),
  legend.key.size = unit(0.35, "cm"),
  legend.key.height = unit(0.45, "cm"),
  legend.key.width = unit(0.45, "cm"),
  legend.spacing.y = unit(0.12, "cm"),
  legend.box.margin = margin(t = 0, b = 0)
)
abbreviate_sector <- function(sectors) {
  sectors <- prettify_label(sectors)
  sectors <- gsub("Drug Vendor/Pharmacy", "Drug vendor", sectors, fixed = TRUE)
  sectors <- gsub("Private Not For Profit", "Private NFP", sectors, fixed = TRUE)
  sectors <- gsub("Private not for Profit", "Private NFP", sectors, fixed = TRUE)
  sectors <- gsub("Not For Profit", "NFP", sectors, fixed = TRUE)
  sectors <- gsub("not for Profit", "NFP", sectors, fixed = TRUE)
  sectors
}

manual_legend_grob <- function(title, labels, colors, shapes, ncol = 1) {
  count <- length(labels)
  if (count == 0) {
    return(NULL)
  }

  legend_data <- data.frame(
    Label = labels,
    Color = colors,
    Shape = shapes,
    Column = (seq_len(count) - 1) %% ncol,
    Row = floor((seq_len(count) - 1) / ncol),
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      X = Column * (0.98 / ncol),
      Y = 0.76 - Row * 0.15
    )

  ggplot(legend_data, aes(x = X, y = Y)) +
    annotate("text", x = 0, y = 0.98, label = title, hjust = 0, vjust = 1,
             fontface = "bold", size = 3.5, family = "DIN Pro") +
    geom_point(aes(colour = Color, shape = Shape), size = 4.0) +
    geom_text(aes(x = X + 0.045, label = Label), hjust = 0, vjust = 0.5,
              size = 3.15, family = "DIN Pro") +
    scale_colour_identity() +
    scale_shape_identity() +
    coord_cartesian(xlim = c(-0.01, 1), ylim = c(0, 1), clip = "off") +
    theme_void() +
    theme(plot.margin = margin(0, 4, 0, 4))
}

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
    mutate(Col_Level = as.character(ifelse(Level_Level == "Other", "Other", as.numeric(as.character(Level_Level))))) %>%
    ungroup() %>%
    left_join(col_mapping , by = c("Sector_Sector" = "Sector", "Col_Level" = "Level")) %>%
    mutate(Color = ensure_chart_color(Color)) %>%
    
    # old version
    #    mutate(Nfaclabel = ifelse(Sector_Sector == "Informal Private", "Unknown", N.Facilities_Number.of.Facilities),
    #           Sector_Numeric = 1:nrow(.)) %>%
    mutate(Nfaclabel = ifelse(Sector_Sector == "Informal Private" | N.Facilities_Number.of.Facilities == 0, "Unknown", N.Facilities_Number.of.Facilities),
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
    geom_text(aes(label = Nfaclabel), y = 0.5, family = "DIN Pro", size = 5, hjust = 0.5) +
    geom_bar(aes(y = 0), stat = "identity", width = 0.8) +
    geom_vline(xintercept = unique(data_agg$Sector_Numeric)[-which.min(unique(data_agg$Sector_Numeric))] - 1, colour = "grey70", size = 0.25) +
    #geom_rect(inherit.aes = FALSE, data = filter(data_agg, RectColor), aes(xmin = Sector_Level_Numeric - 0.5, xmax = Sector_Level_Numeric + 0.5,
    #                                                  ymin = -Inf, ymax = Inf), alpha = 0.2) +
    coord_flip() +
    scale_y_continuous(limits = c(0, 1)) +
    scale_x_continuous(labels = abbreviate_sector(as.character(data_agg$Sector_Level)),
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
      axis.text.y = element_text(size = 10, hjust = 1),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      plot.margin = unit(c(chart_margin_top, chart_margin_right, chart_margin_bottom, chart_margin_left_labels), "cm"),
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
  
  p2 <- ggplot(data = data_agg, aes(x = Sector_Level_Numeric, y = Care.Seeking_Care.Seeking, fill = Sector_Level)) +
    geom_bar(stat = "identity", width = 0.8) +
    geom_text(aes(label = scales::percent(Care.Seeking_Care.Seeking, accuracy = 0.1)), size = 5, hjust = -0.1, family = "DIN Pro") +
    coord_flip() +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    scale_x_continuous(breaks = unique(data_agg$Sector_Numeric)[-which.min(unique(data_agg$Sector_Numeric))] - 1, 
                       minor_breaks = seq_along(data_agg$Sector_Level_Numeric[-1]),
                       expand = c(0, 0.1)) +
    scale_fill_manual(
      "Sector/Level",
      values = data_agg$Color,
      labels = abbreviate_sector(as.character(data_agg$Sector_Level))
    ) +
    theme_minimal(10) +
    chart_legend_theme +
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
      plot.margin = unit(c(chart_margin_top, chart_margin_right, chart_margin_bottom, chart_margin_left), "cm"),
      text = element_text(family = "DIN Pro")
    ) +
    guides(
      fill = guide_legend(ncol = 2, byrow = TRUE, title.position = "top")
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
      mutate(Diagnostic = prettify_label(gsub("^Diagnostic\\.[0-9]\\.Availability_(.*)$", "\\1", Diagnostic))) %>%
      arrange(Sector_Level) %>%
      mutate(Diagnostic_Value = seq(0.5 / length(unique(Diagnostic)), nrow(.) / length(unique(Diagnostic)), by = 1 / length(unique(Diagnostic))),
             LabelPos = (Availability >= .7))
    
    ## Select font
    fsize <- pmin(5, round(100 / nrow(diagnostic_data)))
    
    ## Produce Plot
    p3 <- ggplot(data = diagnostic_data, aes(x = Diagnostic_Value, y = Availability, colour = Sector_Level, fill = Sector_Level)) +
      geom_point(aes(shape = Diagnostic), size = fsize) +
      geom_text(data = filter(diagnostic_data, !LabelPos), aes(label = scales::percent(Availability, accuracy = 0.1)), size = fsize, hjust = -0.4, colour = "black", family = "DIN Pro") +
      geom_text(data = filter(diagnostic_data, LabelPos), aes(label = scales::percent(Availability, accuracy = 0.1)), size = fsize, hjust = 1.25, colour = "black", family = "DIN Pro") +    
      scale_shape_manual(values = c(21, 22, 23, 4)) +
      coord_flip(clip = "off") +
      scale_y_continuous(limits = c(0, 1.1)) +
      scale_x_continuous(limits = c(0.1, max(diagnostic_data$Diagnostic_Value) + diff(diagnostic_data$Diagnostic_Value)[1] / 2 - 0.1),
                         breaks = c(0, data_agg$Sector_Numeric - 1, nrow(data_agg)), 
                         minor_breaks = c(0, seq_along(data_agg$Sector_Level_Numeric)),
                         expand = c(0, 0.1)) +
      scale_colour_manual(values = data_agg$Color, guide = FALSE) +
      scale_fill_manual(values = data_agg$Color, guide = FALSE) +
      theme_minimal(10) +
      chart_legend_theme +
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
        plot.margin = unit(c(chart_margin_top, chart_margin_right, chart_margin_bottom, chart_margin_left), "cm"),
        text = element_text(family = "DIN Pro")
      ) +
      labs(
        title = "Coverage of Diagnostic Services\namong Health Facilities"
      ) +
      ylab("") +
      guides(
        shape = guide_legend(
          ncol = min(2, length(unique(diagnostic_data$Diagnostic))),
          byrow = TRUE,
          title.position = "top",
          override.aes = list(fill = "#666666", colour = "#666666", size = 4)
        )
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
                aes(x = 1, y = MaxAccess, label = scales::percent(MaxAccess, accuracy = 0.1)), size = 5, vjust = -0.4, fontface = "bold", family = "DIN Pro") +
      scale_y_continuous(labels = function(.) scales::percent(., accuracy = 0.1), limits = c(0, 1), expand = c(0, 0)) +
      scale_fill_manual(
        "Sector",
        values = setNames(
          lookup_sector_color(unique(access_data$Sector_Sector)),
          unique(access_data$Sector_Sector)
        ),
        labels = setNames(
          abbreviate_sector(unique(access_data$Sector_Sector)),
          unique(access_data$Sector_Sector)
        )
      ) +
      theme_minimal(10) +
      chart_legend_theme +
      theme(
        plot.title = element_text(hjust = 0.5, size = 10, face = "bold", lineheight = 0.95),
        plot.subtitle = element_text(hjust = 0),
        panel.border = element_rect(colour = "grey70", fill = NA, size = 0.5),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid = element_blank(),
        plot.margin = unit(c(chart_margin_top, chart_margin_right, chart_margin_bottom, chart_margin_left), "cm"),
        text = element_text(family = "DIN Pro")
      ) +
      labs(
        title = "Access to Diagnostic\nServices at First\nVisit"
      ) +
      guides(
        fill = guide_legend(ncol = 1, title.position = "top")
      )
    
    if (length(access_data$MaxAccess[access_data$MaxAccess > 0]) > 1 && all(access_data$MaxAccess[access_data$MaxAccess > 0] >= .1)) p4 <- p4 + 
      geom_text(data = access_data %>% filter(MaxAccess > 0), 
                aes(label = scales::percent(MaxAccess, accuracy = 0.1)), position = position_stack(vjust = .5), size = 5, colour = "white", family = "DIN Pro")
    
  }
  
  ##
  ## Treatment Availability
  ##
  if (length(grep("^Treatment\\.[0-9]\\.Availability", names(data_agg))) >= 1)
  {
    trt_data <- data_agg %>%
      select(Sector_Level:Level_Level, matches("^Treatment\\.[0-9]\\.Availability")) %>%
      gather(key = Treatment, value = Availability, 4:ncol(.)) %>%
      mutate(Treatment = prettify_label(gsub("^Treatment\\.[0-9]\\.Availability_(.*)$", "\\1", Treatment))) %>%
      arrange(Sector_Level) %>%
      mutate(Treatment_Value = seq(0.5 / length(unique(Treatment)), nrow(.) / length(unique(Treatment)), by = 1 / length(unique(Treatment))),
             LabelPos = (Availability >= .7))
    
    ## Select font
    fsize <- pmin(5, round(100 / nrow(trt_data)))
    
    ## Produce Plot
    p5 <- ggplot(data = trt_data, aes(x = Treatment_Value, y = Availability, colour = Sector_Level, fill = Sector_Level)) +
      geom_point(aes(shape = Treatment), size = fsize) +
      geom_text(data = filter(trt_data, !LabelPos), aes(label = scales::percent(Availability, accuracy = 0.1)), size = fsize, hjust = -0.4, colour = "black", family = "DIN Pro") +
      geom_text(data = filter(trt_data, LabelPos), aes(label = scales::percent(Availability, accuracy = 0.1)), size = fsize, hjust = 1.25, colour = "black", family = "DIN Pro") +    
      scale_shape_manual(values = c(21, 22, 23, 4)) +
      coord_flip(clip = "off") +
      scale_y_continuous(limits = c(0, 1.1)) +
      scale_x_continuous(limits = c(0.1, max(trt_data$Treatment_Value) + diff(trt_data$Treatment_Value)[1] / 2 - 0.1),
                         breaks = c(0, data_agg$Sector_Numeric - 1, nrow(data_agg)), 
                         minor_breaks = c(0, seq_along(data_agg$Sector_Level_Numeric)),
                         expand = c(0, 0.1)) +
      scale_colour_manual(values = data_agg$Color, guide = FALSE) +
      scale_fill_manual(values = data_agg$Color, guide = FALSE) +
      theme_minimal(10) +
      chart_legend_theme +
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
        plot.margin = unit(c(chart_margin_top, chart_margin_right, chart_margin_bottom, chart_margin_left), "cm"),
        text = element_text(family = "DIN Pro")
      ) +
      labs(
        title = "Coverage of Treatment Services\namong Health Facilities"
      ) +
      ylab("") +
      guides(
        shape = guide_legend(
          ncol = min(2, length(unique(trt_data$Treatment))),
          byrow = TRUE,
          title.position = "top",
          override.aes = list(fill = "#666666", colour = "#666666", size = 4)
        )
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
                aes(x = 1, y = MaxAccess, label = scales::percent(MaxAccess, accuracy = 0.1)), size = 5, vjust = -0.4, fontface = "bold", family = "DIN Pro") +
      scale_y_continuous(labels = function(.) scales::percent(., accuracy = 0.1), limits = c(0, 1), expand = c(0, 0)) +
      scale_fill_manual(values = lookup_sector_color(trt_access_data$Sector_Sector), guide = FALSE) +
      theme_minimal(10) +
      theme(
        plot.title = element_text(hjust = 0.5, size = 10, face = "bold", lineheight = 0.95),
        plot.subtitle = element_text(hjust = 0),
        plot.caption = element_blank(),
        panel.border = element_rect(colour = "grey70", fill = NA, size = 0.5),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid = element_blank(),
        plot.margin = unit(c(chart_margin_top, chart_margin_right, chart_margin_bottom, chart_margin_left), "cm"),
        text = element_text(family = "DIN Pro")
      ) +
      labs(
        title = "Access to Treatment\nServices at First\nVisit"
      )
    
    if (length(trt_access_data$MaxAccess[trt_access_data$MaxAccess > 0]) > 1 && all(trt_access_data$MaxAccess[trt_access_data$MaxAccess > 0] >= .1)) p6 <- p6 + 
      geom_text(data = trt_access_data %>% filter(MaxAccess > 0), 
                aes(label = scales::percent(MaxAccess, accuracy = 0.1)), position = position_stack(vjust = .5), size = 5, colour = "white", family = "DIN Pro")
    
  }
  
  ##
  ## Final Plot Grid
  ##
  rel_widths <- c(.21, .20, .18, .13, .17, .11)

  plot_without_legend <- function(p, left_margin = chart_margin_left) {
    if (is.null(p)) {
      return(NULL)
    }
    p + theme(
      legend.position = "none",
      plot.margin = unit(c(chart_margin_top, chart_margin_right, chart_margin_bottom_main, left_margin), "cm")
    )
  }

  charts_row <- plot_grid(
    plot_without_legend(p1, chart_margin_left_labels),
    plot_without_legend(p2),
    plot_without_legend(p3),
    plot_without_legend(p4),
    plot_without_legend(p5),
    plot_without_legend(p6),
    align = "h", axis = "lb", ncol = 6, rel_widths = rel_widths
  )

  legend_cards_row <- plot_grid(
    NULL,
    manual_legend_grob(
      "Sector/Level",
      abbreviate_sector(as.character(data_agg$Sector_Level)),
      data_agg$Color,
      rep(15, nrow(data_agg)),
      ncol = 2
    ),
    manual_legend_grob(
      "Diagnostic",
      unique(diagnostic_data$Diagnostic),
      rep("#666666", length(unique(diagnostic_data$Diagnostic))),
      c(16, 15, 17, 18)[seq_along(unique(diagnostic_data$Diagnostic))],
      ncol = min(2, length(unique(diagnostic_data$Diagnostic)))
    ),
    manual_legend_grob(
      "Sector",
      abbreviate_sector(unique(access_data$Sector_Sector)),
      lookup_sector_color(unique(access_data$Sector_Sector)),
      rep(15, length(unique(access_data$Sector_Sector))),
      ncol = 1
    ),
    manual_legend_grob(
      "Treatment",
      unique(trt_data$Treatment),
      rep("#666666", length(unique(trt_data$Treatment))),
      c(16, 15, 17, 18)[seq_along(unique(trt_data$Treatment))],
      ncol = min(2, length(unique(trt_data$Treatment)))
    ),
    NULL,
    align = "h", axis = "t", ncol = 6, rel_widths = rel_widths
  )

  footer_row <- ggdraw() +
    draw_label(
      paste0(tools::toTitleCase(gsub("_", " ", mydata)), ": ", agg),
      x = 0.985, y = 0.72, hjust = 1, vjust = 0.5, size = 8
    )

  ## Use fixed rows instead of vertically centering differently-sized legends.
  ## This guarantees a common title baseline and reserves real bottom padding.
  final_plots <- plot_grid(
    charts_row,
    legend_cards_row,
    footer_row,
    NULL,
    ncol = 1,
    rel_heights = c(0.76, 0.19, 0.025, 0.025),
    align = "v",
    axis = "l"
  )
  
  ## Write it out
  #    ggsave(final_plots, filename = file.path(final_dir, paste0(mydata, "_", agg, "_charts.png")), dpi = 300, height = 8, width = 18)
  ggsave(final_plots, filename = chartFilePaths[[agg]], dpi = 300, height = 10, width = 20, bg = "white")
}

