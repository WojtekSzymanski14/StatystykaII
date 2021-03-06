##Kod s�u��cy do wygenerowania �rodowiska tempEnvir

load("~/temp/smallLogs.rda")
cdata <- smallLogs[, 1:3]
rm(smallLogs)
gc()

#wczytanie danych

##funkcje pomocnicze

#funkcja tworzy ramk� danych, w k�rej kolejne wiersze to przej�cia mi�dzy kolejnymi eksponatami. Dodatkowo P to pocz�tek zwiedzania a K to koniec.
ToPairTable <- function(x) {
  df <- data.frame(c("P", x), c(x, "K"))
  colnames(df) <- c("s1", "s2")
  return(df)
}

#wprowadzenie wsp�rz�dnych eksponat�w
stationMapX <- c(538, 547, 659, 660, 625, 733, 885, 1093, 765, 1007, 1050, 790, 998, 829, 1235, 733, 930, 1075, 1085, 1579, 1479, 1338, 1498, 1698, 1602, 1684, 1475, 1250, 1251, 1675, 1361, 1500, 1581, 1634, 1272, 1022, 1065, 1059, 1216, 1528, 1581, 1541, 1286, 1467, 1623, 1488, 1891, 1834, 1744, 1041, 931, 656, 1531, 1605, 1614, 1512, 1157, 1325, 1459)
stationMapY <- 2181-c(505, 593, 374, 519, 618, 355, 516, 646, 549, 583, 380, 310, 454, 360, 441, 602, 602, 503, 374, 648, 516, 650, 534, 553, 474, 1163, 1380, 889, 957, 688, 947, 1602, 1316, 1578, 1473, 1310, 1033, 1386, 980, 695, 1182, 1055, 1244, 1184, 1038, 1428, 773, 351, 365, 681, 308, 441, 909, 1480, 695, 1423, 1515, 423, 580)
#zamiana wsp�rz�dnych eksponat�w na ramk� danych
exhibitsCoordinates <- data.frame(stationMapX, stationMapY)
colnames(exhibitsCoordinates) <- c("x", "y")
rownames(exhibitsCoordinates) <- stations

palBlue <- choose_palette()
palGreen <- choose_palette()
palRed <- choose_palette()

cdata <- cdata[cdata$visitor != -1, ]
stations <- sort(unique(cdata$station))
stations <- as.character(stations)
cdata$visitor <- as.numeric(cdata$visitor)
cdata$station <- as.factor(cdata$station)
cdata$date <- as.numeric(cdata$date)
gc()


##Kontynuacja w�a�ciwego kodu
#Utworzenie listy transakcji. Ka�da transakcja to pojedynczy go�� za� jego "zakupy" to odwiedzone przez niego eksponaty.

visitorList <- split(cdata, cdata$visitor)
visitorList <- lapply(visitorList, function(x) x[order(x$date), ])
itemSets <- lapply(visitorList, function(x) x$station)
rm(visitorList, cdata)
itemSets <- lapply(itemSets, as.vector)
itemSets <- lapply(itemSets, unique)
gc()

#Wybieramy tylko d�ugie �cie�ki. Za d�ug� �cie�k� przyj��em tak�, kt�rej d�ugo�� to co najmniej 7.
isLong <- sapply(itemSets, function(x) length(x) >= 7)
longItemSets <- itemSets[isLong]

#Utworzenie macierzy kontyngencji przej��. Pierwszy atrybut to pierwszy eksponat z przej�cia mi�dzy eksponatami, drugi atrybut to drugi eksponat na �cie�ce
movesFrequency <- lapply(longItemSets, ToPairTable)
movesFrequencyDF <- do.call("rbind", movesFrequency)
freqTable <- table(movesFrequencyDF)

save.image(file = "tempEnvir.Rdata")

##Analiza
#tworzenie mapy CNK
myPic <- raster("C:/Users/Dariusz/Downloads/regeneracja2.png")
plot(myPic, useRaster=T, col = paste("gray", c(0,100)))
Plevel <- round(10*as.vector(freqTable["P", ]/max(freqTable["P", ])))
for(i in 1:10) {
  points(as.vector(exhibitsCoordinates$x)[Plevel == i], as.vector(exhibitsCoordinates$y)[Plevel == i], col=palGreen(10)[11-i], pch = 24)
}
Klevel <- round(10*as.vector(freqTable[ , "K"]/max(freqTable[, "K"])))
for(i in 1:10) {
  points(as.vector(exhibitsCoordinates$x)[Klevel == i], as.vector(exhibitsCoordinates$y)[Klevel == i], col=palRed(10)[11-i], pch = 25)
}
Slevel <- round(10*freqTable[1:59,1:59]/quantile(freqTable[1:59,1:59], .98))
Slevel[Slevel > 10] <- 10
for(i in 1:59) {
  for(j in 1:59){
    if(Slevel[i,j] > 2)
      segments(x0 = exhibitsCoordinates[i, 1], y0 = exhibitsCoordinates[i, 2], x1 = exhibitsCoordinates[j, 1], y1 = exhibitsCoordinates[j, 2], col = palBlue(10)[11-Slevel[i,j]], alpha = 0.5)
  }
}
rm(isLong, movesFrequency, movesFrequencyDF, freqTable, myPic, Plevel, Klevel, Slevel)
gc()

#badanie regu� asocjacyjnych ograniczonych do podzbior�w zbioru wszystkich eksponat�w
library(arules)
library(arulesViz)

#�cie�ka 1
path1 <- lapply(longItemSets, function(x) intersect(x, c("cnk12", "cnk16", "cnk18", "cnk20", "cnk21", "cnk24", "cnk78a")))
nonempty <- sapply(path1, function(x) length(x) > 0)
path1 <- path1[nonempty]
minSupp <- 0.01
minConf <- 0.6
setRules <- apriori(path1, parameter = list(support = minSupp, confidence = minConf, maxlen = 59, target = "rules"))
setRules1 <- subset(setRules, subset = lhs %ain% c("cnk16", "cnk78a") & lift > 1.7)
plot(setRules1, method = "graph")
setRules2 <- subset(setRules, subset = lhs %ain% c("cnk16", "cnk24") & lift > 1.7)
plot(setRules2, method = "graph")

#�cie�ka 2
path2 <- lapply(longItemSets, function(x) intersect(x, c("cnk18", "cnk24", "cnk37", "cnk38", "cnk48")))
nonempty <- sapply(path2, function(x) length(x) > 0)
path2 <- path2[nonempty]
minSupp <- 0.004
minConf <- 0.4
setRules <- apriori(path2, parameter = list(support = minSupp, confidence = minConf, maxlen = 59, target = "rules"))
setRules1 <- subset(setRules, subset = lift > 1)
plot(setRules1, method = "graph")

#�cie�ka 3
path3 <- lapply(longItemSets, function(x) intersect(x, c("cnk22", "cnk39", "cnk49", "cnk60", "cnk72")))
nonempty <- sapply(path3, function(x) length(x) > 0)
path3 <- path3[nonempty]
minSupp <- 0.004
minConf <- 0.4
setRules <- apriori(path3, parameter = list(support = minSupp, confidence = minConf, maxlen = 59, target = "rules"))
setRules1 <- subset(setRules, subset = lhs %ain% c("cnk49", "cnk60"))
plot(setRules1, method = "graph")

#�cie�ka 4
path4 <- lapply(longItemSets, function(x) intersect(x, c("cnk46a", "cnk46b", "cnk47", "cnk75")))
nonempty <- sapply(path4, function(x) length(x) > 0)
path4 <- path4[nonempty]
minSupp <- 0.004
minConf <- 0.5
setRules <- apriori(path3, parameter = list(support = minSupp, confidence = minConf, maxlen = 59, target = "rules"))
plot(setRules, method = "graph")

