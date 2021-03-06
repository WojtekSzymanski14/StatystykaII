# Grupa Lis, Paluszy�ska, Prucnal: Przekszta�cenia danych
setwd("~/UW/Statystyka_II/Projekt1")
load("C:/Users/Ja/Documents/UW/Statystyka_II/Projekt1/smallLogs.rda")

# str(smallLogs)
# table(as.numeric(smallLogs$station))
# levels(smallLogs$station)
smallLogs$station <- droplevels(smallLogs$station)
# length(unique(smallLogs$visitor))
smallLogs$visitor <- as.numeric(smallLogs$visitor)

# Wybieramy tylko wyj�cia
leaving <- subset(smallLogs, type == "Leaving")
leaving$month <- format(leaving$date, "%m")
leaving <- subset(leaving, month == "01")
# table(leaving$month)
# levels(leaving$station)
# str(leaving)
leaving <- leaving[order(leaving$visitor, leaving$date),]
leaving <- subset(leaving, visitor != -1)

# Oznaczam powtarzaj�ce si� (jedna za drug�) wizyty w danej maszynie danego visitora
leaving$delete <- 0
for(i in 2:nrow(leaving)){
    if((leaving$station[i] == leaving$station[i-1]) && (leaving$visitor[i] == leaving$visitor[i-1])){
        leaving$delete[i] <- 1
        print(i)
    }
}
write.csv(leaving, file="faza2_leaving_raw.csv")  

# Usuwam powtarzaj�ce si� wiersze
table(leaving$delete)
data <- subset(leaving, delete == 0)
write.csv(data, file="faza2_leaving.csv")
data$visitor <- as.factor(data$visitor)
data <- data[, 1:3]

# Tworzenie zmiennej przej�cia w zbiorze
data$przejscie <- NA
data$skad <- NA
data$usun <- 1
for(i in 2:nrow(data)){
    if(data$visitor[i] == data$visitor[i-1]){
        data$przejscie[i] <- paste0(data$station[i-1], paste0("->", data$station[i]))
        data$skad[i] <- paste0(data$station[i-1])
        data$usun[i] <- 0
        print(i)
    }
}
data <- subset(data, usun == 0)
data <- data[,-5]
write.csv(data, file="faza2_data.csv")

# Tworzenie macierzy przej�� (w ka�dej kolumnie kolejne przej�cia dla danego visitora)
r <- max(table(data$visitor))
c <- length(unique(data$visitor))
przejscia <- data.frame(matrix(NA, nrow = r, ncol = c))
nazwy <- paste0("v", unique(data$visitor))
head(nazwy)
colnames(przejscia) <- nazwy
data$visitor <- droplevels(data$visitor)

# Do wyci�gania ostatniego przej�cia
ostatni <- rep(NA, times=length(unique(data$visitor)))

# P�tla tworzy macierz przej��
for(i in 1:length(levels(data$visitor))){
    x <- data[data$visitor==levels(data$visitor)[i], 4]
    przejscia[1:length(x),i] <- x
    ostatni[i] <- x[length(x)]
    print(i)
}
write.csv(przejscia, file="faza2_przejscia.csv")
write.csv(ostatni, file="faza2_ostatni.csv")

# Tworzenie macierzy zliczaj�cej przej�cia (wychodzi zero-jedynkowa)
etykiety <- unique(data$przejscie)
c <- length(unique(data$visitor))
nazwy <- paste0("v", unique(data$visitor))
licznik <- matrix(NA, nrow = length(etykiety), ncol = c)
colnames(licznik) <- nazwy
rownames(licznik) <- etykiety

for(i in 1:ncol(licznik)){
    licznik[,i] <- as.matrix(table(factor(rownames(as.matrix(table(przejscia[,i]))), levels = as.factor(etykiety))))
    print(i)
}
write.csv(licznik, file="faza2_liczby_przejsc.csv")

# Badanie pod�cie�ek d�ugo�ci 4 eksponaty (tego nie ma w knitrze)
temp1 <- as.data.frame(table(data$przejscie))
tail(temp1[order(temp1$Freq),], n=20) # najcz�stsze przej�cia

# dla kilku najcz�stszych przej�� (w naszym przypadku dla 8) poni�sz� metod� wy�oni��my przej�cia poprzedzaj�ce,
# oraz nast�puj�ce po najcz�stszych wybranych na pocz�tku: (ten kod wyznacza najbardziej popularne 
# pod�cie�ki nast�puj�ce po 19a->19b, dla innych modyfikowa�y�my go odpowiednio)
cnk19a<-subset(data,przejscie=="cnk19a->cnk19b")$visitor
cnk19a_19b <-subset(data,visitor%in%cnk19a)
table(subset(cnk19a_19b,skad=="cnk19b")$station)
table(subset(cnk19a_19b,station=="cnk19a")$skad)

nr <- subset(cnk19a_19b, przejscie=="cnk06->cnk19a")$visitor
cnk06_19 <- subset(cnk19a_19b, visitor %in% nr)
table(subset(cnk06_19,skad=="cnk19b")$station)